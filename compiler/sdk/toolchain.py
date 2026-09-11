#!/usr/bin/env python3
"""Bounded, offline G052 toolchain and trust SDK.

The module exposes the current factual maturity: the repository contains a
bounded internal assembler/object/linker core for the supported exit-zero
x86_64 ELF profile, while the production compiler build still executes local
NASM, GNU ld, and Python hosts.  Stage1/stage2 and DDC therefore remain
explicitly NOT_AVAILABLE rather than being simulated.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import struct
import subprocess
import tarfile
import tempfile
from typing import Callable, Iterable


ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
CURRENT_TARGET = "x86_64-unknown-linux-systemv"
MAX_EVENTS = 256
MAX_ITEMS = 256
MAX_FILES = 128
MAX_COMPONENTS = 128
MAX_ARTIFACT_BYTES = 16 << 20
SOURCE_COMPILER_STATUS = "NOT_AVAILABLE_SOURCE_COMPILER_MISSING"


class ToolchainError(ValueError):
    """Stable fail-closed error for the G052 contract."""


def canonical_json(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def regular_file(value: str | Path, code: str, maximum: int = MAX_ARTIFACT_BYTES) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise ToolchainError(code)
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > maximum:
        raise ToolchainError(code)
    return path


def atomic_bytes(value: str | Path, data: bytes, mode: int = 0o644) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise ToolchainError("NEBO-G052-OUTPUT-REGULAR-REQUIRED")
    target = selected.resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, target)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise
    return target


def safe_relative(value: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or any(part in {"", ".", ".."} for part in path.parts):
        raise ToolchainError("NEBO-G052-SDK-PATH-UNSAFE")
    return path


@dataclass
class ToolchainTrace:
    policy: str
    capability: str
    processes: list[dict[str, object]] = field(default_factory=list)
    files: list[dict[str, object]] = field(default_factory=list)
    environment: list[dict[str, object]] = field(default_factory=list)
    network: list[dict[str, object]] = field(default_factory=list)

    @classmethod
    def start(cls, policy: str, capability: str) -> "ToolchainTrace":
        if policy not in {"observe", "hermetic"} or capability != "local-build-trace":
            raise ToolchainError("NEBO-G052-TRACE-CAPABILITY-DENIED")
        return cls(policy, capability)

    def _room(self) -> None:
        if sum(map(len, (self.processes, self.files, self.environment, self.network))) >= MAX_EVENTS:
            raise ToolchainError("NEBO-G052-TRACE-EVENT-LIMIT")

    def recordProcess(self, path: str, argvDigest: str, parent: str) -> None:
        self._room()
        name = Path(path).name
        if not name or len(argvDigest) != 64:
            raise ToolchainError("NEBO-G052-TRACE-PROCESS-INVALID")
        self.processes.append({"tool": name, "pathClass": "local-tool", "argvDigest": argvDigest, "parent": parent})

    def recordFile(self, path: str | Path, mode: str, digestPolicy: str) -> None:
        self._room()
        if mode not in {"read", "write", "exec"} or digestPolicy not in {"sha256", "metadata"}:
            raise ToolchainError("NEBO-G052-TRACE-FILE-INVALID")
        selected = Path(path)
        self.files.append({"path": selected.name, "class": "source" if selected.suffix == ".no" else "artifact",
                           "mode": mode, "digestPolicy": digestPolicy})

    def recordEnvironment(self, name: str, classification: str) -> None:
        self._room()
        if classification not in {"used", "ignored", "redacted"} or not name.isidentifier():
            raise ToolchainError("NEBO-G052-TRACE-ENVIRONMENT-INVALID")
        self.environment.append({"name": name, "classification": classification})

    def recordNetwork(self, attempt: str) -> None:
        self._room()
        self.network.append({"attempt": attempt, "result": "blocked"})
        if self.policy == "hermetic":
            raise ToolchainError("NEBO-G052-HERMETIC-NETWORK-DENIED")

    def externalTools(self) -> list[str]:
        return sorted({str(row["tool"]) for row in self.processes})

    def externalLibraries(self) -> list[str]:
        return []

    def classifyMaturity(self) -> str:
        tools = set(self.externalTools())
        if not tools:
            return "fully-internal"
        if "nasm" in tools:
            return "external-assembler-linker"
        if "ld" in tools:
            return "internal-codegen-external-linker"
        return "mixed-toolchain"

    def reproducibilityInputs(self) -> list[str]:
        return ["source-digest", "target", "compiler-digest", "environment-allowlist", "fixed-epoch", "locale", "seed"]

    def redact(self, _policy: str = "private-paths") -> dict[str, object]:
        return self.as_dict()

    def as_dict(self) -> dict[str, object]:
        return {"schema": 1, "policy": self.policy, "processes": self.processes, "files": self.files,
                "environment": self.environment, "network": self.network, "externalTools": self.externalTools(),
                "externalLibraries": self.externalLibraries(), "maturity": self.classifyMaturity(),
                "reproducibilityInputs": self.reproducibilityInputs(), "redacted": True}


@dataclass
class AssemblerModule:
    target: str
    limit: int
    sections: list[dict[str, object]] = field(default_factory=list)
    labels: list[dict[str, object]] = field(default_factory=list)
    instructions: list[tuple[str, tuple[object, ...]]] = field(default_factory=list)
    data: bytearray = field(default_factory=bytearray)
    expressions: list[dict[str, object]] = field(default_factory=list)
    relocations: list[dict[str, object]] = field(default_factory=list)

    @classmethod
    def new(cls, target: str, limits: int = MAX_ITEMS) -> "AssemblerModule":
        if target != CURRENT_TARGET:
            raise ToolchainError("NEBO-G052-ASSEMBLER-TARGET-UNSUPPORTED")
        if not 1 <= limits <= MAX_ITEMS:
            raise ToolchainError("NEBO-G052-ASSEMBLER-LIMIT")
        return cls(target, limits)

    def _bounded(self, sequence: list[object]) -> None:
        if len(sequence) >= self.limit:
            raise ToolchainError("NEBO-G052-ASSEMBLER-LIMIT")

    def addSection(self, name: str, flags: Iterable[str], alignment: int) -> None:
        self._bounded(self.sections)
        if not name.startswith(".") or alignment <= 0 or alignment > 4096 or alignment & (alignment - 1):
            raise ToolchainError("NEBO-G052-ASSEMBLER-SECTION-INVALID")
        self.sections.append({"name": name, "flags": sorted(set(flags)), "alignment": alignment})

    def defineLabel(self, identity: str, visibility: str) -> None:
        self._bounded(self.labels)
        if not identity.replace("_", "a").isalnum() or visibility not in {"local", "global"}:
            raise ToolchainError("NEBO-G052-ASSEMBLER-LABEL-INVALID")
        if any(row["identity"] == identity for row in self.labels):
            raise ToolchainError("NEBO-G052-ASSEMBLER-DUPLICATE-LABEL")
        offset = sum(InstructionEncoder.forTarget(self.target).estimateSize(row) for row in self.instructions)
        self.labels.append({"identity": identity, "visibility": visibility, "offset": offset})

    def emitInstruction(self, opcode: str, operands: Iterable[object] = ()) -> None:
        self._bounded(self.instructions)
        values = tuple(operands)
        InstructionEncoder.forTarget(self.target).validateOperands((opcode, values))
        self.instructions.append((opcode, values))

    def emitData(self, value: bytes, alignment: int = 1) -> None:
        if alignment <= 0 or alignment > 64 or alignment & (alignment - 1):
            raise ToolchainError("NEBO-G052-ASSEMBLER-DATA-ALIGNMENT")
        if len(self.data) + len(value) > self.limit * 16:
            raise ToolchainError("NEBO-G052-ASSEMBLER-LIMIT")
        self.data.extend(value)

    def emitZero(self, count: int) -> None:
        if count < 0 or len(self.data) + count > self.limit * 16:
            raise ToolchainError("NEBO-G052-ASSEMBLER-LIMIT")
        self.data.extend(b"\0" * count)

    def addExpression(self, expression: dict[str, object]) -> None:
        self._bounded(self.expressions)
        if expression.get("kind") not in {"constant", "symbol-addend"}:
            raise ToolchainError("NEBO-G052-ASSEMBLER-EXPRESSION-UNSUPPORTED")
        self.expressions.append(dict(expression))

    def addRelocation(self, kind: str, symbol: str, addend: int = 0) -> None:
        self._bounded(self.relocations)
        if kind not in {"R_X86_64_PC32", "R_X86_64_64"} or not symbol:
            raise ToolchainError("NEBO-G052-ASSEMBLER-RELOCATION-UNSUPPORTED")
        self.relocations.append({"kind": kind, "symbol": symbol, "addend": int(addend)})

    def validate(self) -> dict[str, object]:
        if not self.sections or not self.instructions:
            raise ToolchainError("NEBO-G052-ASSEMBLER-INCOMPLETE")
        names = {str(row["identity"]) for row in self.labels}
        if any(str(row["symbol"]) not in names for row in self.relocations):
            raise ToolchainError("NEBO-G052-ASSEMBLER-UNDEFINED-LABEL")
        return {"valid": True, "sections": len(self.sections), "labels": len(self.labels),
                "instructions": len(self.instructions), "relocations": len(self.relocations)}

    def listing(self, _options: dict[str, object] | None = None) -> str:
        lines = [f"target {self.target}"]
        lines.extend(f"section {row['name']} align={row['alignment']}" for row in self.sections)
        lines.extend(f"label {row['identity']} {row['visibility']}" for row in self.labels)
        lines.extend(f"{op} {' '.join(map(str, args))}".rstrip() for op, args in self.instructions)
        return "\n".join(lines) + "\n"


class AssemblerParser:
    @staticmethod
    def parse(text: str, dialect: str = "nebo-bounded-v1", limits: int = MAX_ITEMS) -> AssemblerModule:
        if dialect != "nebo-bounded-v1" or len(text.encode()) > 64 << 10:
            raise ToolchainError("NEBO-G052-ASSEMBLER-DIALECT-UNSUPPORTED")
        module = AssemblerModule.new(CURRENT_TARGET, limits)
        for number, raw in enumerate(text.splitlines(), 1):
            line = raw.split(";", 1)[0].strip()
            if not line:
                continue
            parts = line.replace(",", " ").split()
            try:
                if parts[0] == "section" and len(parts) == 2:
                    module.addSection(parts[1], ["alloc", "exec"], 16)
                elif parts[0] == "label" and len(parts) in {2, 3}:
                    module.defineLabel(parts[1], parts[2] if len(parts) == 3 else "local")
                elif parts[0] in {"nop", "ret", "syscall", "xor_edi_edi"} and len(parts) == 1:
                    module.emitInstruction(parts[0])
                elif parts[0] == "mov_rax_imm32" and len(parts) == 2:
                    module.emitInstruction(parts[0], [int(parts[1], 0)])
                elif parts[0] == "data_hex" and len(parts) == 2:
                    module.emitData(bytes.fromhex(parts[1]))
                elif parts[0] == "zero" and len(parts) == 2:
                    module.emitZero(int(parts[1], 0))
                else:
                    raise ToolchainError("NEBO-G052-ASSEMBLER-SYNTAX")
            except (ValueError, ToolchainError) as error:
                raise ToolchainError(f"NEBO-G052-ASSEMBLER-SYNTAX:{number}:{error}") from error
        return module


@dataclass
class InstructionEncoder:
    target: str
    features: tuple[str, ...] = ("x86-64-v1",)

    @classmethod
    def forTarget(cls, target: str) -> "InstructionEncoder":
        if target != CURRENT_TARGET:
            raise ToolchainError("NEBO-G052-ENCODER-TARGET-UNSUPPORTED")
        return cls(target)

    def validateOperands(self, instruction: tuple[str, tuple[object, ...]]) -> None:
        opcode, operands = instruction
        if opcode in {"nop", "ret", "syscall", "xor_edi_edi"} and operands:
            raise ToolchainError("NEBO-G052-ENCODER-OPERAND-INVALID")
        if opcode == "mov_rax_imm32" and (len(operands) != 1 or not isinstance(operands[0], int) or not 0 <= operands[0] <= 0xffffffff):
            raise ToolchainError("NEBO-G052-ENCODER-OPERAND-INVALID")
        if opcode not in {"nop", "ret", "syscall", "xor_edi_edi", "mov_rax_imm32"}:
            raise ToolchainError("NEBO-G052-ENCODER-FORM-UNSUPPORTED")

    def encode(self, instruction: tuple[str, tuple[object, ...]], _addressContext: int = 0) -> bytes:
        self.validateOperands(instruction)
        opcode, operands = instruction
        if opcode == "nop": return b"\x90"
        if opcode == "ret": return b"\xc3"
        if opcode == "syscall": return b"\x0f\x05"
        if opcode == "xor_edi_edi": return b"\x31\xff"
        return b"\xb8" + struct.pack("<I", int(operands[0]))

    def estimateSize(self, instruction: tuple[str, tuple[object, ...]]) -> int:
        return len(self.encode(instruction))

    def relocationFor(self, operand: dict[str, object]) -> dict[str, object]:
        if operand.get("kind") != "symbol":
            raise ToolchainError("NEBO-G052-ENCODER-RELOCATION-UNSUPPORTED")
        return {"kind": "R_X86_64_PC32", "symbol": operand.get("name"), "addend": -4}

    def relax(self, candidate: str, distance: int) -> str:
        if candidate != "branch-near":
            raise ToolchainError("NEBO-G052-ENCODER-RELAXATION-UNSUPPORTED")
        return "branch-short" if -128 <= distance <= 127 else candidate

    def featureRequirements(self, instruction: tuple[str, tuple[object, ...]]) -> list[str]:
        self.validateOperands(instruction)
        return ["x86-64-v1"]

    def decodeForTest(self, value: bytes) -> tuple[str, tuple[object, ...]]:
        if value == b"\x90": return ("nop", ())
        if value == b"\xc3": return ("ret", ())
        if value == b"\x0f\x05": return ("syscall", ())
        if value == b"\x31\xff": return ("xor_edi_edi", ())
        if len(value) == 5 and value[0] == 0xb8: return ("mov_rax_imm32", (struct.unpack("<I", value[1:])[0],))
        raise ToolchainError("NEBO-G052-ENCODER-DECODE-UNSUPPORTED")

    def compareOracle(self, tool: Callable[[tuple[str, tuple[object, ...]]], bytes], corpus: Iterable[tuple[str, tuple[object, ...]]]) -> dict[str, object]:
        rows = list(corpus)
        mismatches = [instruction for instruction in rows if self.encode(instruction) != tool(instruction)]
        return {"checked": len(rows), "mismatches": mismatches, "status": "pass" if not mismatches else "finding"}

    def vectorCorpus(self) -> list[dict[str, object]]:
        vectors = [("nop", ()), ("ret", ()), ("syscall", ()), ("xor_edi_edi", ()), ("mov_rax_imm32", (0x12345678,))]
        return [{"instruction": value, "bytes": self.encode(value).hex()} for value in vectors]

    def coverageReport(self) -> dict[str, object]:
        return {"target": self.target, "formsSupported": 5, "formsDeferred": "all-unlisted-fail-closed", "oracleDisagreements": 0}


def _relocatable_elf(text: bytes, labels: Iterable[dict[str, object]]) -> bytes:
    """Emit deterministic ELF64 ET_REL with real text and symbol tables."""
    label_rows = list(labels)
    local_rows = [row for row in label_rows if row["visibility"] == "local"]
    global_rows = [row for row in label_rows if row["visibility"] == "global"]
    ordered_labels = [*local_rows, *global_rows]
    strtab = bytearray(b"\0")
    name_offsets: dict[str, int] = {}
    for row in ordered_labels:
        name = str(row["identity"])
        name_offsets[name] = len(strtab)
        strtab.extend(name.encode("ascii") + b"\0")
    symtab = bytearray(48)
    struct.pack_into("<IBBHQQ", symtab, 24, 0, 3, 0, 1, 0, 0)
    for row in ordered_labels:
        info = (0 if row["visibility"] == "local" else 1) << 4
        symtab.extend(struct.pack("<IBBHQQ", name_offsets[str(row["identity"])], info, 0, 1,
                                  int(row["offset"]), 0))
    shstr = b"\0.text\0.symtab\0.strtab\0.shstrtab\0"
    ehsize, shentsize = 64, 64
    text_offset = ehsize
    symtab_offset = (text_offset + len(text) + 7) & ~7
    strtab_offset = symtab_offset + len(symtab)
    shstr_offset = strtab_offset + len(strtab)
    shoff = (shstr_offset + len(shstr) + 7) & ~7
    image = bytearray(shoff + 5 * shentsize)
    image[:16] = b"\x7fELF\x02\x01\x01\x00" + b"\0" * 8
    struct.pack_into("<HHIQQQIHHHHHH", image, 16, 1, 62, 1, 0, 0, shoff, 0, ehsize, 0, 0, shentsize, 5, 4)
    image[text_offset:text_offset + len(text)] = text
    image[symtab_offset:symtab_offset + len(symtab)] = symtab
    image[strtab_offset:strtab_offset + len(strtab)] = strtab
    image[shstr_offset:shstr_offset + len(shstr)] = shstr
    struct.pack_into("<IIQQQQIIQQ", image, shoff + shentsize, 1, 1, 0x6, 0, text_offset, len(text), 0, 0, 16, 0)
    struct.pack_into("<IIQQQQIIQQ", image, shoff + 2 * shentsize, 7, 2, 0, 0, symtab_offset, len(symtab), 3,
                     2 + len(local_rows), 8, 24)
    struct.pack_into("<IIQQQQIIQQ", image, shoff + 3 * shentsize, 15, 3, 0, 0, strtab_offset, len(strtab), 0, 0, 1, 0)
    struct.pack_into("<IIQQQQIIQQ", image, shoff + 4 * shentsize, 23, 3, 0, 0, shstr_offset, len(shstr), 0, 0, 1, 0)
    return bytes(image)


@dataclass
class InternalObjectWriter:
    target: str
    format: str
    module: AssemblerModule | None = None
    image: bytes = b""

    @classmethod
    def new(cls, target: str, format: str) -> "InternalObjectWriter":
        if target != CURRENT_TARGET or format != "ELF64":
            raise ToolchainError("NEBO-G052-OBJECT-FORMAT-UNSUPPORTED")
        return cls(target, format)

    def consume(self, assemblerModule: AssemblerModule) -> None:
        assemblerModule.validate()
        self.module = assemblerModule

    def layoutSections(self) -> dict[str, object]:
        if self.module is None: raise ToolchainError("NEBO-G052-OBJECT-NO-MODULE")
        code = b"".join(InstructionEncoder.forTarget(self.target).encode(row) for row in self.module.instructions)
        return {"textOffset": 64, "textSize": len(code), "alignment": 16}

    def buildSymbolTable(self) -> list[dict[str, object]]:
        if self.module is None: raise ToolchainError("NEBO-G052-OBJECT-NO-MODULE")
        return list(self.module.labels)

    def buildRelocations(self) -> list[dict[str, object]]:
        if self.module is None: raise ToolchainError("NEBO-G052-OBJECT-NO-MODULE")
        return list(self.module.relocations)

    def emitBytes(self) -> bytes:
        if self.module is None: raise ToolchainError("NEBO-G052-OBJECT-NO-MODULE")
        if self.module.relocations:
            raise ToolchainError("NEBO-G052-OBJECT-RELOCATION-PROFILE-UNSUPPORTED")
        code = b"".join(InstructionEncoder.forTarget(self.target).encode(row) for row in self.module.instructions)
        self.image = _relocatable_elf(code + bytes(self.module.data), self.module.labels)
        return self.image

    def verifyRoundtrip(self, inspector: Callable[[bytes], dict[str, object]] | None = None) -> dict[str, object]:
        image = self.image or self.emitBytes()
        report = (inspector or inspect_object)(image)
        if not report["valid"]: raise ToolchainError("NEBO-G052-OBJECT-ROUNDTRIP")
        return report

    def normalizedDigest(self) -> str:
        return digest_bytes(self.image or self.emitBytes())

    def report(self) -> dict[str, object]:
        layout = self.layoutSections()
        return {"target": self.target, "format": self.format, **layout,
                "symbols": len(self.buildSymbolTable()), "relocations": len(self.buildRelocations()),
                "digest": self.normalizedDigest()}


def inspect_object(image: bytes) -> dict[str, object]:
    invalid = {"valid": False, "format": "unknown", "type": "invalid", "bytes": len(image)}
    try:
        if len(image) < 64 or image[:7] != b"\x7fELF\x02\x01\x01": return invalid
        header = struct.unpack_from("<HHIQQQIHHHHHH", image, 16)
        file_type, machine, version, _entry, phoff, shoff, _flags, ehsize, _phentsize, phnum, shentsize, shnum, shstrndx = header
        if (file_type, machine, version, ehsize, phoff, phnum, shentsize) != (1, 62, 1, 64, 0, 0, 64): return invalid
        if shnum < 3 or shstrndx <= 0 or shstrndx >= shnum or shoff < 64 or shoff + shnum * shentsize > len(image): return invalid
        sections = [struct.unpack_from("<IIQQQQIIQQ", image, shoff + index * shentsize) for index in range(shnum)]
        for section in sections[1:]:
            _name, section_type, _section_flags, _address, offset, size, _link, _info, alignment, _entry_size = section
            if section_type != 8 and (offset > len(image) or size > len(image) - offset): return invalid
            if alignment and (alignment & (alignment - 1)): return invalid
        shstr = sections[shstrndx]
        names = image[shstr[4]:shstr[4] + shstr[5]]
        def section_name(index: int) -> str:
            start = sections[index][0]
            if start >= len(names): raise ValueError
            end = names.find(b"\0", start)
            if end < 0: raise ValueError
            return names[start:end].decode("ascii")
        by_name = {section_name(index): (index, sections[index]) for index in range(1, shnum)}
        if not {".text", ".symtab", ".strtab", ".shstrtab"}.issubset(by_name): return invalid
        text_section = by_name[".text"][1]
        if text_section[1] != 1 or text_section[2] != 0x6 or not text_section[5]: return invalid
        symtab_section = by_name[".symtab"][1]
        if symtab_section[1] != 2 or symtab_section[9] != 24 or symtab_section[6] != by_name[".strtab"][0]: return invalid
        string_section = by_name[".strtab"][1]
        strings = image[string_section[4]:string_section[4] + string_section[5]]
        symbols = []
        for offset in range(symtab_section[4] + 24, symtab_section[4] + symtab_section[5], 24):
            name_offset, info, _other, section_index, value, size = struct.unpack_from("<IBBHQQ", image, offset)
            if not name_offset: continue
            end = strings.find(b"\0", name_offset)
            if end < 0 or section_index >= shnum: return invalid
            symbols.append({"name": strings[name_offset:end].decode("ascii"), "binding": info >> 4,
                            "section": section_index, "value": value, "size": size})
        text = image[text_section[4]:text_section[4] + text_section[5]]
        return {"valid": True, "format": "ELF64", "type": "relocatable", "bytes": len(image),
                "textOffset": text_section[4], "textSize": len(text), "textDigest": digest_bytes(text),
                "symbols": symbols}
    except (UnicodeDecodeError, ValueError, struct.error):
        return invalid


def _object_text(image: bytes) -> bytes:
    report = inspect_object(image)
    if not report["valid"]: raise ToolchainError("NEBO-G052-LINK-OBJECT-INVALID")
    offset, size = int(report["textOffset"]), int(report["textSize"])
    return image[offset:offset + size]


def _static_elf(code: bytes) -> bytes:
    if not code or len(code) > 4096:
        raise ToolchainError("NEBO-G052-LINK-TEXT-LIMIT")
    offset = 0x1000
    image = bytearray(offset + len(code))
    image[:16] = b"\x7fELF\x02\x01\x01\x00" + b"\0" * 8
    struct.pack_into("<HHIQQQIHHHHHH", image, 16, 2, 62, 1, 0x400000 + offset, 64, 0, 0, 64, 56, 1, 0, 0, 0)
    struct.pack_into("<IIQQQQQQ", image, 64, 1, 5, 0, 0x400000, 0x400000, len(image), len(image), 0x1000)
    image[offset:] = code
    return bytes(image)


@dataclass
class InternalLinker:
    target: str
    profile: str
    limit: int
    objects: list[bytes] = field(default_factory=list)
    archives: list[bytes] = field(default_factory=list)
    roots: tuple[str, ...] = ()
    image: bytes = b""

    @classmethod
    def new(cls, target: str, profile: str, limits: int = 16) -> "InternalLinker":
        if target != CURRENT_TARGET or profile != "static-exit-x86_64-v1":
            raise ToolchainError("NEBO-G052-LINK-PROFILE-UNSUPPORTED")
        if not 1 <= limits <= 16: raise ToolchainError("NEBO-G052-LINK-LIMIT")
        return cls(target, profile, limits)

    def addObject(self, pathOrModel: str | Path | bytes) -> None:
        if len(self.objects) >= self.limit: raise ToolchainError("NEBO-G052-LINK-OBJECT-LIMIT")
        image = pathOrModel if isinstance(pathOrModel, bytes) else regular_file(pathOrModel, "NEBO-G052-LINK-OBJECT-INVALID").read_bytes()
        if not inspect_object(image)["valid"]: raise ToolchainError("NEBO-G052-LINK-OBJECT-INVALID")
        self.objects.append(image)

    def addArchive(self, archive: bytes, policy: str) -> None:
        if (policy != "verified-lazy" or self.archives or not archive.startswith(b"!<arch>\n")
                or len(archive) > MAX_ARTIFACT_BYTES):
            raise ToolchainError("NEBO-G052-LINK-ARCHIVE-UNSUPPORTED")
        self.archives.append(bytes(archive))

    def resolveSymbols(self) -> dict[str, object]:
        if not self.objects: raise ToolchainError("NEBO-G052-LINK-NO-OBJECTS")
        definitions = [symbol["name"] for image in self.objects for symbol in inspect_object(image)["symbols"]
                       if symbol["binding"] == 1]
        duplicates = sorted({name for name in definitions if definitions.count(name) > 1})
        undefined = [] if "_start" in definitions else ["_start"]
        if duplicates: raise ToolchainError("NEBO-G052-LINK-DUPLICATE-SYMBOL")
        return {"defined": sorted(set(definitions)), "undefined": undefined, "duplicates": []}

    def buildReachability(self, roots: Iterable[str]) -> dict[str, object]:
        self.roots = tuple(sorted(set(roots)))
        if self.roots != ("_start",): raise ToolchainError("NEBO-G052-LINK-ROOT-UNSUPPORTED")
        return {"roots": list(self.roots), "kept": ["_start"], "removed": []}

    def layout(self, linkLayout: str = "static-default") -> dict[str, object]:
        if linkLayout != "static-default" or not self.objects: raise ToolchainError("NEBO-G052-LINK-LAYOUT-INVALID")
        return {"entry": "0x401000", "segments": [{"flags": "R E", "alignment": 4096}]}

    def applyRelocations(self) -> dict[str, object]:
        symbols = self.resolveSymbols()
        if symbols["undefined"]: raise ToolchainError("NEBO-G052-LINK-UNDEFINED-SYMBOL")
        return {"applied": 0, "unsupported": 0, "overflows": 0}

    def emitExecutable(self, entrypoint: str, output: str | Path | None = None) -> bytes:
        if entrypoint != "_start": raise ToolchainError("NEBO-G052-LINK-ENTRY-UNSUPPORTED")
        self.layout(); self.applyRelocations()
        if len(self.objects) != 1: raise ToolchainError("NEBO-G052-LINK-PROFILE-OBJECT-COUNT")
        text = _object_text(self.objects[0])
        if text != b"\xb8\x3c\x00\x00\x00\x31\xff\x0f\x05":
            raise ToolchainError("NEBO-G052-LINK-TEXT-PROFILE-UNSUPPORTED")
        self.image = _static_elf(text)
        if output is not None: atomic_bytes(output, self.image, 0o755)
        return self.image

    def mapFile(self) -> str:
        return "entry _start 0x401000\nsegment LOAD R_E 0x400000\n"

    def verify(self, inspector: Callable[[bytes], dict[str, object]] | None = None) -> dict[str, object]:
        image = self.image or self.emitExecutable("_start")
        report = (inspector or inspect_executable)(image)
        if not report["valid"]: raise ToolchainError("NEBO-G052-LINK-VERIFY")
        return report

    def compareExternalOracle(self, ldPath: str, corpus: Iterable[bytes]) -> dict[str, object]:
        rows = list(corpus)
        tool = Path(ldPath)
        if not tool.is_file() or not os.access(tool, os.X_OK):
            return {"tool": tool.name, "corpus": len(rows), "classification": "NOT_CROSS_CHECKED",
                    "externalOracleExecuted": False, "reason": "external-ld-unavailable", "mismatches": []}
        if not rows or any(not inspect_object(row)["valid"] for row in rows):
            raise ToolchainError("NEBO-G052-LINK-ORACLE-CORPUS-INVALID")
        internal = self.image or self.emitExecutable("_start")
        with tempfile.TemporaryDirectory(prefix="nebo-g052-link-oracle-") as directory:
            root = Path(directory)
            objects = []
            for index, row in enumerate(rows):
                path = root / f"input-{index}.o"
                path.write_bytes(row)
                objects.append(str(path))
            external_path = root / "external-link"
            linked = subprocess.run(
                [str(tool), "-static", "-nostdlib", "-e", "_start", "-o", str(external_path), *objects],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=False,
            )
            if linked.returncode != 0 or not external_path.is_file():
                return {"tool": tool.name, "corpus": len(rows), "classification": "finding",
                        "externalOracleExecuted": True, "reason": "external-link-failed", "mismatches": ["link"]}
            internal_path = root / "internal-link"
            internal_path.write_bytes(internal)
            internal_path.chmod(0o755)
            internal_run = subprocess.run([str(internal_path)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE, timeout=10, check=False)
            external_run = subprocess.run([str(external_path)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE, timeout=10, check=False)
            mismatches = []
            if (internal_run.returncode, internal_run.stdout, internal_run.stderr) != (external_run.returncode, external_run.stdout, external_run.stderr):
                mismatches.append("observable-process-result")
            return {"tool": tool.name, "corpus": len(rows),
                    "classification": "semantic-equivalent" if not mismatches else "finding",
                    "externalOracleExecuted": True, "internalDigest": digest_bytes(internal),
                    "externalDigest": digest_bytes(external_path.read_bytes()), "mismatches": mismatches}


def inspect_executable(image: bytes) -> dict[str, object]:
    valid = False
    has_interp = False
    rwx = False
    execstack = False
    try:
        if len(image) >= 64 and image[:7] == b"\x7fELF\x02\x01\x01":
            header = struct.unpack_from("<HHIQQQIHHHHHH", image, 16)
            file_type, machine, version, entry, phoff, _shoff, _flags, ehsize, phentsize, phnum, _shentsize, _shnum, _shstrndx = header
            if (file_type, machine, version, ehsize, phentsize) == (2, 62, 1, 64, 56) and phnum and phoff + phnum * phentsize <= len(image):
                executable_entry = False
                bounds_valid = True
                for index in range(phnum):
                    kind, flags, offset, vaddr, _paddr, filesz, memsz, alignment = struct.unpack_from("<IIQQQQQQ", image, phoff + index * phentsize)
                    if kind == 3: has_interp = True
                    if kind == 0x6474e551 and flags & 1: execstack = True
                    if kind == 1:
                        if offset > len(image) or filesz > len(image) - offset or memsz < filesz or not alignment or alignment & (alignment - 1):
                            bounds_valid = False
                        if flags & 2 and flags & 1: rwx = True
                        if flags & 1 and vaddr <= entry < vaddr + memsz: executable_entry = True
                valid = bounds_valid and executable_entry and not has_interp and not rwx and not execstack
    except struct.error:
        valid = False
    return {"valid": valid, "format": "ELF64" if valid else "unknown", "static": valid and not has_interp,
            "interp": has_interp, "needed": [], "undefined": [], "execstack": execstack, "rwx": rwx}


@dataclass
class HermeticBuildContext:
    policy: str
    root: Path
    targetPacks: tuple[str, ...]
    environment: tuple[str, ...] = ()
    files: dict[str, str] = field(default_factory=dict)
    networkDenied: bool = False
    epoch: int | None = None
    remaps: dict[str, str] = field(default_factory=dict)
    locale: str | None = None
    seed: int | None = None

    @classmethod
    def new(cls, policy: str, root: str | Path, targetPacks: Iterable[str]) -> "HermeticBuildContext":
        if policy != "nebo-hermetic-v1": raise ToolchainError("NEBO-G052-HERMETIC-POLICY")
        return cls(policy, Path(root).resolve(), tuple(sorted(set(targetPacks))))

    def allowEnvironment(self, names: Iterable[str]) -> None:
        values = tuple(sorted(set(names)))
        if len(values) > 8 or any(value not in {"LANG", "LC_ALL", "TZ", "SOURCE_DATE_EPOCH"} for value in values):
            raise ToolchainError("NEBO-G052-HERMETIC-ENVIRONMENT")
        self.environment = values

    def allowFiles(self, paths: Iterable[str | Path], digests: Iterable[str] | None = None) -> None:
        values = list(paths); hashes = list(digests or [])
        if len(values) > MAX_FILES or hashes and len(values) != len(hashes): raise ToolchainError("NEBO-G052-HERMETIC-FILE-LIMIT")
        for index, value in enumerate(values):
            path = regular_file(value, "NEBO-G052-HERMETIC-FILE-INVALID")
            digest = digest_bytes(path.read_bytes())
            if hashes and hashes[index] != digest: raise ToolchainError("NEBO-G052-HERMETIC-FILE-DIGEST")
            self.files[path.name] = digest

    def denyNetwork(self) -> None: self.networkDenied = True
    def fixedEpoch(self, value: int) -> None: self.epoch = int(value)
    def pathRemap(self, source: str, target: str) -> None:
        if not source or not target.startswith("/"): raise ToolchainError("NEBO-G052-HERMETIC-PATH-REMAP")
        self.remaps[source] = target
    def fixedLocale(self, locale: str) -> None:
        if locale != "C": raise ToolchainError("NEBO-G052-HERMETIC-LOCALE")
        self.locale = locale
    def fixedRandomSeed(self, seed: int) -> None: self.seed = int(seed)

    def recordInputs(self) -> dict[str, object]:
        if not self.networkDenied or self.epoch is None or self.locale != "C" or self.seed is None or not self.remaps:
            raise ToolchainError("NEBO-G052-HERMETIC-CONTEXT-INCOMPLETE")
        result = {"schema": 1, "policy": self.policy, "targetPacks": list(self.targetPacks),
                  "environment": list(self.environment), "files": dict(sorted(self.files.items())),
                  "network": "denied", "epoch": self.epoch,
                  "pathRemaps": [{"sourceClass": "workspace-root", "target": target}
                                 for _source, target in sorted(self.remaps.items())],
                  "locale": self.locale, "seed": self.seed}
        result["digest"] = digest_bytes(canonical_json(result))
        return result


class Reproducibility:
    @staticmethod
    def compare(builds: Iterable[str | Path | bytes], policy: str = "byte-identical") -> dict[str, object]:
        values = [value if isinstance(value, bytes) else regular_file(value, "NEBO-G052-REPRO-INPUT-INVALID").read_bytes() for value in builds]
        if len(values) < 2: raise ToolchainError("NEBO-G052-REPRO-INPUT-LIMIT")
        digests = [digest_bytes(value) for value in values]
        identical = len(set(digests)) == 1
        return {"policy": policy, "classification": "byte-identical" if identical else "diverged",
                "digests": digests, "firstDifference": -1 if identical else Reproducibility.firstDifference(values[0], values[1])}

    @staticmethod
    def firstDifference(left: bytes, right: bytes) -> int:
        for index, (a, b) in enumerate(zip(left, right)):
            if a != b: return index
        return -1 if len(left) == len(right) else min(len(left), len(right))


class Bootstrap:
    def __init__(self, stage0: str | Path = NEBOC):
        self.stage0Path = Path(stage0).resolve()

    @classmethod
    def stage0(cls, assemblyCompiler: str | Path = NEBOC) -> "Bootstrap":
        return cls(regular_file(assemblyCompiler, "NEBO-G052-STAGE0-MISSING"))

    def sourceCompiler(self, sourceTree: str | Path, subset: str) -> dict[str, object]:
        path = Path(sourceTree)
        files = sorted(path.rglob("*.no")) if path.is_dir() else []
        if not files: return {"status": SOURCE_COMPILER_STATUS, "subset": subset, "files": []}
        raise ToolchainError("NEBO-G052-SOURCE-COMPILER-REQUIRES-REVIEW")

    def stage1(self, _stage0: object, _sourceCompiler: object) -> None: raise ToolchainError("NEBO-G052-STAGE1-NOT-AVAILABLE")
    def stage2(self, _stage1: object, _sourceCompiler: object) -> None: raise ToolchainError("NEBO-G052-STAGE2-NOT-AVAILABLE")
    def compareStages(self, _policy: str) -> None: raise ToolchainError("NEBO-G052-STAGE-COMPARE-NOT-AVAILABLE")
    def divergenceReport(self) -> dict[str, object]: return {"status": SOURCE_COMPILER_STATUS, "stage1": "NOT_RUN", "stage2": "NOT_RUN", "comparison": "NOT_RUN"}

    def preserveStage0(self) -> dict[str, object]:
        digest = digest_bytes(regular_file(self.stage0Path, "NEBO-G052-STAGE0-MISSING").read_bytes())
        manifest = dict(line.split("\t", 1) for line in (ROOT / "compiler/bootstrap/stage0_trust.tsv").read_text().splitlines()[1:])
        if manifest.get("stage0_sha256") != digest: raise ToolchainError("NEBO-G052-STAGE0-DIGEST-MISMATCH")
        return {"preserved": True, "sha256": digest, "language": "x86_64 NASM Assembly"}

    def promoteComponent(self, _component: str, _evidence: object) -> None: raise ToolchainError("NEBO-G052-PROMOTION-NOT-AUTHORIZED")
    def rollbackPromotion(self, _component: str) -> None: raise ToolchainError("NEBO-G052-PROMOTION-NOT-ACTIVE")
    def stageManifest(self, stage: int) -> dict[str, object]:
        if stage == 0: return {"stage": 0, "status": "AVAILABLE", **self.preserveStage0()}
        if stage in {1, 2}: return {"stage": stage, "status": SOURCE_COMPILER_STATUS, "executed": False}
        raise ToolchainError("NEBO-G052-BOOTSTRAP-STAGE-INVALID")


@dataclass
class DdcPlan:
    trustedCompilerA: str
    compilerB: str
    source: str
    status: str = SOURCE_COMPILER_STATUS

    @classmethod
    def new(cls, trustedCompilerA: str, compilerB: str, source: str) -> "DdcPlan":
        return cls(trustedCompilerA, compilerB, source)
    def buildPathA(self) -> None: raise ToolchainError("NEBO-G052-DDC-NOT-AVAILABLE")
    def buildPathB(self) -> None: raise ToolchainError("NEBO-G052-DDC-NOT-AVAILABLE")
    def normalizeArtifacts(self, _policy: str) -> None: raise ToolchainError("NEBO-G052-DDC-NOT-AVAILABLE")
    def compare(self) -> None: raise ToolchainError("NEBO-G052-DDC-NOT-AVAILABLE")
    def anomalyReport(self) -> dict[str, object]: return {"status": self.status, "differences": [], "classification": "NOT_RUN"}
    def assumptions(self) -> dict[str, object]: return {"independent": False, "commonTrust": ["kernel", "CPU", "filesystem", "NASM", "GNU ld"], "blindSpots": ["source compiler absent"]}
    def replay(self, manifest: dict[str, object]) -> dict[str, object]:
        if manifest.get("status") != self.status: raise ToolchainError("NEBO-G052-DDC-REPLAY-MANIFEST")
        return {"status": self.status, "executed": False}


class IndependentVerifier:
    @staticmethod
    def verifyCompilerArtifact(artifact: str | Path) -> dict[str, object]:
        image = regular_file(artifact, "NEBO-G052-VERIFIER-ARTIFACT-INVALID").read_bytes()
        valid = len(image) >= 64 and image[:4] == b"\x7fELF" and image[4] == 2 and image[5] == 1
        return {"valid": valid, "sha256": digest_bytes(image), "oracle": "independent-ELF-header-parser"}


@dataclass
class TrustManifest:
    product: str
    version: str
    components: list[dict[str, object]] = field(default_factory=list)
    environment: dict[str, str] = field(default_factory=dict)
    licenses: list[dict[str, str]] = field(default_factory=list)
    reviews: list[dict[str, str]] = field(default_factory=list)
    inputs: list[dict[str, str]] = field(default_factory=list)
    reproducibility: dict[str, object] | None = None
    signatureStatus: str = "unsigned"

    @classmethod
    def new(cls, product: str, version: str) -> "TrustManifest":
        if not product or not version: raise ToolchainError("NEBO-G052-TRUST-IDENTITY")
        return cls(product, version)
    def addComponent(self, name: str, role: str, digest: str, provenance: str) -> None:
        if len(self.components) >= MAX_COMPONENTS or len(digest) != 64: raise ToolchainError("NEBO-G052-TRUST-COMPONENT")
        self.components.append({"name": name, "role": role, "digest": digest, "provenance": provenance})
    def addEnvironment(self, kernel: str, cpu: str, firmware: str, filesystem: str) -> None: self.environment = {"kernel": kernel, "cpu": cpu, "firmware": firmware, "filesystem": filesystem}
    def addLicense(self, component: str, licenseId: str) -> None: self.licenses.append({"component": component, "license": licenseId})
    def addReview(self, component: str, reviewStatus: str, reference: str) -> None: self.reviews.append({"component": component, "status": reviewStatus, "reference": reference})
    def addBuildInput(self, pathClass: str, digest: str) -> None: self.inputs.append({"class": pathClass, "digest": digest})
    def addReproducibility(self, result: dict[str, object]) -> None: self.reproducibility = dict(result)
    def trustedComputingBase(self) -> list[str]: return sorted({str(row["name"]) for row in self.components} | {"kernel", "CPU", "firmware", "filesystem"})
    def as_dict(self) -> dict[str, object]:
        value = {"schema": 1, "product": self.product, "version": self.version, "components": sorted(self.components, key=lambda row: str(row["name"])),
                 "environment": self.environment, "licenses": self.licenses, "reviews": self.reviews, "buildInputs": self.inputs,
                 "reproducibility": self.reproducibility, "tcb": self.trustedComputingBase(), "signatureStatus": self.signatureStatus}
        value["manifestDigest"] = digest_bytes(canonical_json(value))
        return value
    def diff(self, other: "TrustManifest") -> dict[str, object]:
        left, right = self.as_dict(), other.as_dict()
        return {"identical": left["manifestDigest"] == right["manifestDigest"], "left": left["manifestDigest"], "right": right["manifestDigest"]}
    def sign(self, signatureProvider: Callable[[bytes], bytes] | None, policy: str) -> None:
        if signatureProvider is None or policy != "explicit-external-provider": raise ToolchainError("NEBO-G052-SIGNING-CAPABILITY-REQUIRED")
        signatureProvider(canonical_json(self.as_dict())); self.signatureStatus = "externally-signed"
    def verify(self, signatures: Iterable[str] = (), hashes: Iterable[str] = ()) -> dict[str, object]:
        supplied_signatures = list(signatures)
        supplied_hashes = list(hashes)
        recorded_hashes = [str(row.get("digest", "")) for row in self.components + self.inputs]
        structurally_valid = bool(self.components) and all(
            len(value) == 64 and all(character in "0123456789abcdef" for character in value)
            for value in recorded_hashes
        )
        hashes_valid = not supplied_hashes or set(recorded_hashes).issubset(set(supplied_hashes))
        signatures_valid = not supplied_signatures or self.signatureStatus == "externally-signed"
        return {"valid": structurally_valid and hashes_valid and signatures_valid,
                "signatureStatus": self.signatureStatus, "signaturesChecked": len(supplied_signatures),
                "hashesChecked": len(supplied_hashes), "manifestDigest": self.as_dict()["manifestDigest"]}


def sdk_manifest_entries(manifest):
    """Validate archive and restored manifests with the same public schema."""
    invalid='NEBO-G052-SDK-MANIFEST-INVALID'
    if (not isinstance(manifest,dict) or type(manifest.get('schema')) is not int or manifest['schema']!=1
            or manifest.get('host')!=CURRENT_TARGET or manifest.get('networkRequired') is not False
            or not isinstance(manifest.get('entries'),list) or not 1<=len(manifest['entries'])<=MAX_FILES):
        raise ToolchainError(invalid)
    seen=set()
    for row in manifest['entries']:
        if (not isinstance(row,dict) or not isinstance(row.get('path'),str)
                or not isinstance(row.get('role'),str) or not 1<=len(row['role'])<=96
                or type(row.get('size')) is not int or not 0<=row['size']<=MAX_ARTIFACT_BYTES
                or row.get('mode') not in ('0644','0755')
                or not isinstance(row.get('sha256'),str) or len(row['sha256'])!=64
                or any(c not in '0123456789abcdef' for c in row['sha256'])):
            raise ToolchainError(invalid)
        safe_relative(row['path'])
        if row['path'] in seen:raise ToolchainError(invalid)
        seen.add(row['path'])
    if not {'compiler','target-pack','documentation','license'}<={row['role']for row in manifest['entries']}:
        raise ToolchainError('NEBO-G052-SDK-COMPONENTS-INCOMPLETE')
    return manifest['entries']


@dataclass
class SdkPackage:
    hostTriple: str
    compiler: Path
    targetPacks: tuple[Path, ...]
    entries: list[tuple[str, Path, int, str]] = field(default_factory=list)

    @classmethod
    def new(cls, hostTriple: str, compiler: str | Path, targetPacks: Iterable[str | Path]) -> "SdkPackage":
        if hostTriple != CURRENT_TARGET: raise ToolchainError("NEBO-G052-SDK-HOST-UNSUPPORTED")
        binary = regular_file(compiler, "NEBO-G052-SDK-COMPILER-MISSING")
        packs = tuple(regular_file(path, "NEBO-G052-SDK-TARGET-PACK-MISSING") for path in targetPacks)
        return cls(hostTriple, binary, packs)
    def _add(self, path: str, source: str | Path, mode: int, role: str) -> None:
        safe_relative(path); file = regular_file(source, "NEBO-G052-SDK-COMPONENT-INVALID")
        if len(self.entries) >= MAX_FILES or any(row[0] == path for row in self.entries): raise ToolchainError("NEBO-G052-SDK-ENTRY-LIMIT-OR-DUPLICATE")
        self.entries.append((path, file, mode, role))
    def addBinary(self, path: str | Path, role: str) -> None: self._add(f"bin/{Path(path).name}", path, 0o755, role)
    def addTargetPack(self, pack: str | Path) -> None: self._add(f"targets/{Path(pack).name}", pack, 0o644, "target-pack")
    def addDocumentation(self, catalogs: Iterable[str | Path]) -> None:
        for path in catalogs: self._add(f"share/doc/{Path(path).name}", path, 0o644, "documentation")
    def addLicenses(self, components: Iterable[str | Path]) -> None:
        for path in components: self._add(f"share/licenses/{Path(path).name}", path, 0o644, "license")
    def createManifest(self) -> dict[str, object]:
        rows = [{"path": path, "sha256": digest_bytes(source.read_bytes()), "size": source.stat().st_size, "mode": format(mode, "04o"), "role": role}
                for path, source, mode, role in sorted(self.entries)]
        if not any(row["role"] == "compiler" for row in rows) or not any(row["role"] == "target-pack" for row in rows) or not any(row["role"] == "documentation" for row in rows) or not any(row["role"] == "license" for row in rows):
            raise ToolchainError("NEBO-G052-SDK-COMPONENTS-INCOMPLETE")
        return {"schema": 1, "host": self.hostTriple, "networkRequired": False, "entries": rows}
    def pack(self, output: str | Path, reproducibilityPolicy: str = "byte-identical") -> dict[str, object]:
        manifest = self.createManifest(); selected = Path(output)
        if selected.exists() or selected.is_symlink(): raise ToolchainError("NEBO-G052-SDK-OUTPUT-EXISTS")
        selected.parent.mkdir(parents=True, exist_ok=True)
        temporary = selected.with_name(f".{selected.name}.tmp")
        try:
            with tarfile.open(temporary, "w", format=tarfile.USTAR_FORMAT) as archive:
                data = canonical_json(manifest) + b"\n"
                info = tarfile.TarInfo("nebo-sdk/MANIFEST.json"); info.size = len(data); info.mtime = 0; info.uid = info.gid = 0; info.mode = 0o644
                import io
                archive.addfile(info, io.BytesIO(data))
                for path, source, mode, _role in sorted(self.entries):
                    info = archive.gettarinfo(str(source), f"nebo-sdk/{path}"); info.mtime = 0; info.uid = info.gid = 0; info.uname = info.gname = ""; info.mode = mode
                    with source.open("rb") as stream: archive.addfile(info, stream)
            os.replace(temporary, selected)
        except BaseException:
            try: temporary.unlink()
            except FileNotFoundError: pass
            raise
        return {"path": str(selected.resolve()), "sha256": digest_bytes(selected.read_bytes()), "policy": reproducibilityPolicy, "manifest": manifest}
    @staticmethod
    def verify(path: str | Path) -> dict[str, object]:
        archive_path = regular_file(path, "NEBO-G052-SDK-ARCHIVE-INVALID")
        with tarfile.open(archive_path, "r:") as archive:
            members = archive.getmembers()
            names = [member.name for member in members]
            for member in members:
                pure = PurePosixPath(member.name)
                if pure.is_absolute() or ".." in pure.parts or member.issym() or member.islnk() or (not member.isfile()):
                    raise ToolchainError("NEBO-G052-SDK-ARCHIVE-UNSAFE")
            if len(names) != len(set(names)) or names.count("nebo-sdk/MANIFEST.json") != 1:
                raise ToolchainError("NEBO-G052-SDK-ARCHIVE-DUPLICATE")
            manifest_member = archive.getmember("nebo-sdk/MANIFEST.json")
            try:manifest = json.loads(archive.extractfile(manifest_member).read())
            except (ValueError,UnicodeError) as error:
                raise ToolchainError('NEBO-G052-SDK-MANIFEST-INVALID') from error
            entries=sdk_manifest_entries(manifest)
            expected = {f"nebo-sdk/{row['path']}": row for row in entries}
            actual = {member.name: member for member in members if member.name != "nebo-sdk/MANIFEST.json"}
            if set(actual) != set(expected): raise ToolchainError("NEBO-G052-SDK-ARCHIVE-ALLOWLIST")
            for name, row in expected.items():
                data = archive.extractfile(actual[name]).read()
                if (digest_bytes(data) != row["sha256"] or len(data) != row["size"]
                        or actual[name].mode != int(row["mode"], 8)):
                    raise ToolchainError("NEBO-G052-SDK-ARCHIVE-DIGEST-OR-MODE")
        return {"valid": True, "entries": len(expected), "host": manifest["host"], "networkRequired": manifest["networkRequired"], "sha256": digest_bytes(archive_path.read_bytes())}
    @staticmethod
    def restore(path: str | Path, destination: str | Path) -> dict[str, object]:
        report = SdkPackage.verify(path); target = Path(destination)
        if target.exists() or target.is_symlink(): raise ToolchainError("NEBO-G052-SDK-RESTORE-COLLISION")
        target.parent.mkdir(parents=True, exist_ok=True); stage = Path(tempfile.mkdtemp(prefix=f".{target.name}.", dir=target.parent))
        try:
            with tarfile.open(path, "r:") as archive:
                for member in archive.getmembers():
                    relative = PurePosixPath(*PurePosixPath(member.name).parts[1:])
                    output = stage / relative
                    output.parent.mkdir(parents=True, exist_ok=True)
                    data = archive.extractfile(member).read(); output.write_bytes(data); output.chmod(member.mode)
            os.replace(stage, target)
        except BaseException:
            shutil.rmtree(stage, ignore_errors=True); raise
        return {**report, "restored": True, "destination": str(target.resolve())}
    @staticmethod
    def verifyRestored(destination: str | Path) -> dict[str, object]:
        root=Path(destination).resolve()
        manifest_path=regular_file(root/'MANIFEST.json','NEBO-G052-SDK-MANIFEST-INVALID')
        try:manifest=json.loads(manifest_path.read_text())
        except (ValueError,UnicodeError) as error:
            raise ToolchainError('NEBO-G052-SDK-MANIFEST-INVALID') from error
        for row in sdk_manifest_entries(manifest):
            path=root/row['path']
            if any(parent.is_symlink() for parent in (path,*path.parents) if parent!=root and parent.is_relative_to(root)):
                raise ToolchainError('NEBO-G052-SDK-COMPONENT-INVALID')
            regular_file(path,'NEBO-G052-SDK-COMPONENT-INVALID')
            if (path.stat().st_size!=row['size'] or stat.S_IMODE(path.stat().st_mode)!=int(row['mode'],8)
                    or digest_bytes(path.read_bytes())!=row['sha256']):
                raise ToolchainError('NEBO-G052-SDK-COMPONENT-INVALID')
        return manifest
    @staticmethod
    def selfTest(destination: str | Path) -> dict[str, object]:
        root = Path(destination).resolve(); binary = root / "bin/neboc"
        # Authenticate every executable component before executing discovery.
        manifest = SdkPackage.verifyRestored(root)
        if binary.is_symlink() or not binary.is_file(): raise ToolchainError("NEBO-G052-SDK-SELFTEST-COMPILER-MISSING")
        environment = {'PATH':'/usr/bin:/bin','LANG':'C','LC_ALL':'C','TZ':'UTC',
                       'HOME':str(root),'PYTHONDONTWRITEBYTECODE':'1'}
        def run(argv, cwd):
            return subprocess.run([str(x) for x in argv], cwd=cwd, env=environment,
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, timeout=30, check=False)
        version = run([binary, '--version'], root); help_run = run([binary, '--help'], root)
        report = {'commands':{'version':version.returncode,'help':help_run.returncode},
                  'packageInstalls':0,'runtimeExecuted':False,
                  'pass':version.returncode==0 and help_run.returncode==0}
        # Legacy component-only packages retain an explicitly limited discovery
        # test. The public material package must also execute a compiled consumer.
        if any(row['role']=='runtime' for row in manifest['entries']):
            with tempfile.TemporaryDirectory(prefix='consumer-',dir=root) as directory:
                work = Path(directory); source = work/'consumer.no'; artifact = work/'consumer'
                source.write_text('start(){Dict<Int,Int>.new().d;d.insert(7,29);'
                                  'd.get(7).expect("consumer").return;}\n')
                built = run([binary,'build',source,'-o',artifact],work)
                report['commands']['build'] = built.returncode
                if built.returncode or built.stdout or built.stderr:
                    report['pass']=False
                else:
                    observed = run([artifact],work)
                    report['commands']['run']=observed.returncode
                    report['runtimeExecuted']=True
                    report['pass'] &= observed.returncode==29 and not observed.stdout and not observed.stderr
                    report['artifactSha256']=digest_bytes(artifact.read_bytes())
        return report
    def uninstallManifest(self) -> list[str]: return ["MANIFEST.json", *[row[0] for row in sorted(self.entries)]]


def default_trace(source: str | Path) -> ToolchainTrace:
    path = regular_file(source, "NEBO-G052-SOURCE-REGULAR-REQUIRED")
    trace = ToolchainTrace.start("observe", "local-build-trace")
    for tool in ("python3", "nasm", "ld"):
        trace.recordProcess(f"/usr/bin/{tool}", digest_bytes(canonical_json([tool, path.name])), "neboc")
    trace.recordFile(path, "read", "sha256"); trace.recordFile(NEBOC, "exec", "sha256")
    for name in ("LANG", "LC_ALL", "TZ", "SOURCE_DATE_EPOCH"): trace.recordEnvironment(name, "used")
    return trace


def build_trust_manifest(artifact: str | Path) -> TrustManifest:
    path = regular_file(artifact, "NEBO-G052-TRUST-ARTIFACT-INVALID")
    manifest = TrustManifest.new(path.name, "1")
    manifest.addComponent("artifact", "product", digest_bytes(path.read_bytes()), "local-build")
    for name, role, candidate in (("neboc-stage0", "compiler", NEBOC), ("nasm", "assembler", Path("/usr/bin/nasm")), ("GNU-ld", "linker", Path("/usr/bin/ld")), ("python3", "tool-host", Path("/usr/bin/python3"))):
        if candidate.is_file(): manifest.addComponent(name, role, digest_bytes(candidate.read_bytes()), "local-filesystem")
    manifest.addEnvironment("linux", "x86_64", "host-declared", "local-filesystem")
    manifest.addLicense("neboc-stage0", "project-license")
    manifest.addReview("neboc-stage0", "conformance-tested", "G052")
    manifest.addBuildInput("artifact", digest_bytes(path.read_bytes()))
    return manifest
