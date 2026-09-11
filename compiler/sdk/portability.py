#!/usr/bin/env python3
"""Bounded, offline public SDK for G051 target portability.

The SDK deliberately distinguishes descriptors from implemented backends.
Only the live x86_64 Linux/System-V tuple is runnable; aarch64 and wasm32 are
registered as contract-only targets until their code generator and runtime
evidence exist.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import platform as host_platform
import re
import resource
import shutil
import socket
import struct
import subprocess
import tempfile
import threading
import time
from typing import Any, Iterable
from compiler.sdk.version_identity import CLI


ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
MAX_TARGETS = 16
MAX_PACK_BYTES = 1 << 20
MAX_PACK_FILES = 64
MAX_SOURCE_BYTES = 1 << 20
MAX_SECTIONS = 32
MAX_SYMBOLS = 128
MAX_RELOCATIONS = 256
MAX_ARTIFACT_BYTES = 1 << 30
CURRENT_TRIPLE = "x86_64-unknown-linux-systemv"


class PortabilityError(ValueError):
    """Stable fail-closed error for the G051 contract."""


def _bounded(value: int, low: int, high: int, code: str) -> int:
    if not low <= value <= high:
        raise PortabilityError(code)
    return value


def _regular(path: str | Path, code: str, maximum: int = MAX_ARTIFACT_BYTES) -> Path:
    selected = Path(path)
    if selected.is_symlink():
        raise PortabilityError(code)
    resolved = selected.resolve()
    if not resolved.is_file() or resolved.stat().st_size > maximum:
        raise PortabilityError(code)
    return resolved


def _atomic_bytes(path: str | Path, data: bytes, mode: int = 0o644) -> Path:
    selected = Path(path)
    if selected.is_symlink():
        raise PortabilityError("NEBO-G051-OUTPUT-REGULAR-REQUIRED")
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


def _canonical_json(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")


@dataclass(frozen=True)
class TargetTriple:
    arch: str
    vendor: str
    os: str
    env: str
    deprecatedAlias: str | None = None

    _ALIASES = {"amd64": "x86_64", "arm64": "aarch64", "unknown": "unknown"}
    _ARCH = {"x86_64": 64, "aarch64": 64, "wasm32": 32}
    _OS = {"linux", "wasi"}
    _ENV = {"systemv", "wasm"}

    @classmethod
    def parse(cls, text: str) -> "TargetTriple":
        if not isinstance(text, str) or len(text) > 128:
            raise PortabilityError("NEBO-G051-TRIPLE-INVALID")
        parts = text.strip().lower().split("-")
        if len(parts) != 4 or any(not re.fullmatch(r"[a-z0-9_]+", part) for part in parts):
            raise PortabilityError("NEBO-G051-TRIPLE-INVALID")
        original_arch = parts[0]
        arch = cls._ALIASES.get(original_arch, original_arch)
        if arch not in cls._ARCH or parts[2] not in cls._OS or parts[3] not in cls._ENV:
            raise PortabilityError("NEBO-G051-TARGET-UNSUPPORTED")
        if (parts[2], parts[3]) not in {("linux", "systemv"), ("wasi", "wasm")}:
            raise PortabilityError("NEBO-G051-TRIPLE-INCOMPATIBLE")
        if arch == "wasm32" and (parts[2], parts[3]) != ("wasi", "wasm"):
            raise PortabilityError("NEBO-G051-TRIPLE-INCOMPATIBLE")
        if arch != "wasm32" and (parts[2], parts[3]) != ("linux", "systemv"):
            raise PortabilityError("NEBO-G051-TRIPLE-INCOMPATIBLE")
        return cls(arch, parts[1] or "unknown", parts[2], parts[3],
                   original_arch if original_arch != arch else None)

    def normalize(self) -> str:
        return f"{self.arch}-{self.vendor or 'unknown'}-{self.os}-{self.env}"

    def architecture(self) -> dict[str, object]:
        return {"name": self.arch, "wordBits": self._ARCH[self.arch]}

    def operatingSystem(self) -> str:
        return self.os

    def environment(self) -> str:
        return self.env

    def compatibility(self, other: "TargetTriple") -> str:
        if self.normalize() == other.normalize():
            return "exact"
        if (self.arch, self.os, self.env) == (other.arch, other.os, other.env):
            return "abi-compatible"
        if self.arch == other.arch and self.object_family() == other.object_family():
            return "object-compatible"
        if self.arch in self._ARCH and other.arch in self._ARCH:
            return "source-only"
        return "incompatible"

    def object_family(self) -> str:
        return "wasm" if self.arch == "wasm32" else "elf64"


class BuildTriple:
    @staticmethod
    def current() -> TargetTriple:
        return TargetTriple.parse(CURRENT_TRIPLE)


class HostTriple:
    @staticmethod
    def current() -> TargetTriple:
        if host_platform.system().lower() != "linux" or host_platform.machine().lower() not in {"x86_64", "amd64"}:
            raise PortabilityError("NEBO-G051-HOST-UNSUPPORTED")
        return TargetTriple.parse(CURRENT_TRIPLE)


@dataclass
class CompilationContext:
    build: TargetTriple
    host: TargetTriple
    target: TargetTriple
    compiler: str
    options: dict[str, object]
    targetPacks: tuple[str, ...]

    @classmethod
    def new(cls, build: TargetTriple, host: TargetTriple, target: TargetTriple,
            compiler: str = CLI, options: dict[str, object] | None = None,
            targetPacks: Iterable[str] = ()) -> "CompilationContext":
        if not all(isinstance(item, TargetTriple) for item in (build, host, target)):
            raise PortabilityError("NEBO-G051-CONTEXT-TRIPLE-REQUIRED")
        packs = tuple(targetPacks)
        if len(packs) > MAX_TARGETS:
            raise PortabilityError("NEBO-G051-CONTEXT-PACK-LIMIT")
        return cls(build, host, target, compiler, dict(options or {}), packs)

    def manifest(self) -> dict[str, object]:
        return {"schema": 1, "build": self.build.normalize(), "host": self.host.normalize(),
                "target": self.target.normalize(), "compiler": self.compiler,
                "options": dict(sorted(self.options.items())), "targetPacks": list(self.targetPacks)}


@dataclass(frozen=True)
class TargetDescriptor:
    triple: TargetTriple
    layout: dict[str, object]
    calling: dict[str, object]
    object_format: str
    executable_format: str
    syscall_model: str
    baseline: tuple[str, ...]
    optional: tuple[str, ...]
    capability_set: tuple[str, ...]
    maturity: str
    backendImplemented: bool
    runtimeImplemented: bool
    packDigest: str

    def dataLayout(self) -> dict[str, object]: return dict(self.layout)
    def callingConvention(self) -> dict[str, object]: return dict(self.calling)
    def objectFormat(self) -> str: return self.object_format
    def executableFormat(self) -> str: return self.executable_format
    def syscallModel(self) -> str: return self.syscall_model
    def cpuBaseline(self) -> list[str]: return list(self.baseline)
    def optionalFeatures(self) -> list[str]: return list(self.optional)
    def capabilities(self) -> list[str]: return list(self.capability_set)

    def validateFeatureSet(self, requested: Iterable[str]) -> dict[str, object]:
        features = set(requested)
        allowed = set(self.baseline) | set(self.optional)
        unknown = sorted(features - allowed)
        if unknown:
            raise PortabilityError("NEBO-G051-FEATURE-UNSUPPORTED:" + ",".join(unknown))
        return {"target": self.triple.normalize(), "requested": sorted(features), "valid": True}

    def report(self) -> dict[str, object]:
        return {"triple": self.triple.normalize(), "dataLayout": self.dataLayout(),
                "callingConvention": self.callingConvention(), "objectFormat": self.object_format,
                "executableFormat": self.executable_format, "syscallModel": self.syscall_model,
                "cpuBaseline": self.cpuBaseline(), "optionalFeatures": self.optionalFeatures(),
                "capabilities": self.capabilities(), "maturity": self.maturity,
                "backendImplemented": self.backendImplemented, "runtimeImplemented": self.runtimeImplemented,
                "packDigest": self.packDigest}


def _descriptor(text: str, *, maturity: str, backend: bool, runtime: bool,
                capabilities: tuple[str, ...], object_format: str = "ELF64") -> TargetDescriptor:
    triple = TargetTriple.parse(text)
    word = triple.architecture()["wordBits"]
    layout = {"endian": "little", "pointerBits": word, "integerBits": [8, 16, 32, 64],
              "floatBits": [32, 64], "stackAlignment": 16, "aggregateAlignment": 16}
    calling = ({"name": "System-V-x86_64", "parameterRegisters": ["rdi", "rsi", "rdx", "rcx", "r8", "r9"],
                "returnRegisters": ["rax", "rdx"], "stackAlignment": 16, "redZoneBytes": 128,
                "unwind": "not-implemented"} if triple.arch == "x86_64" else
               {"name": "descriptor-only", "parameterRegisters": [], "returnRegisters": [],
                "stackAlignment": 16, "redZoneBytes": 0, "unwind": "not-implemented"})
    baseline = ("x86-64", "sse2") if triple.arch == "x86_64" else (("wasm-mvp",) if triple.arch == "wasm32" else ("armv8-a",))
    optional = ("avx2",) if triple.arch == "x86_64" else ()
    payload = {"triple": triple.normalize(), "maturity": maturity, "backend": backend,
               "runtime": runtime, "capabilities": capabilities}
    return TargetDescriptor(triple, layout, calling, object_format,
                            "static-ELF64" if object_format == "ELF64" else object_format,
                            "linux-x86_64-raw-syscall" if runtime else "none",
                            baseline, optional, capabilities, maturity, backend, runtime,
                            hashlib.sha256(_canonical_json(payload)).hexdigest())


class TargetRegistry:
    def __init__(self, descriptors: Iterable[TargetDescriptor]):
        values = list(descriptors)
        if not 1 <= len(values) <= MAX_TARGETS:
            raise PortabilityError("NEBO-G051-TARGET-REGISTRY-LIMIT")
        self._items = {item.triple.normalize(): item for item in values}
        if len(self._items) != len(values):
            raise PortabilityError("NEBO-G051-TARGET-DUPLICATE")

    @classmethod
    def builtins(cls) -> "TargetRegistry":
        return cls([
            _descriptor(CURRENT_TRIPLE, maturity="hardware", backend=True, runtime=True,
                        capabilities=("filesystem", "network", "process", "time", "random", "threads")),
            _descriptor("aarch64-unknown-linux-systemv", maturity="contract", backend=False, runtime=False,
                        capabilities=()),
            _descriptor("wasm32-unknown-wasi-wasm", maturity="contract", backend=False, runtime=False,
                        capabilities=(), object_format="Wasm"),
        ])

    @classmethod
    def load(cls, packs: Iterable[str | Path | dict[str, object]], policy: str = "offline") -> "TargetRegistry":
        if policy != "offline":
            raise PortabilityError("NEBO-G051-NETWORK-POLICY")
        descriptors: list[TargetDescriptor] = []
        for pack in packs:
            value = pack
            if not isinstance(value, dict):
                path = _regular(value, "NEBO-G051-TARGET-PACK-REGULAR-REQUIRED", MAX_PACK_BYTES)
                value = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(value, dict) or value.get("schema") != 1:
                raise PortabilityError("NEBO-G051-TARGET-PACK-SCHEMA")
            triple = TargetTriple.parse(str(value.get("triple", "")))
            if triple.normalize() == CURRENT_TRIPLE:
                descriptors.append(TargetRegistry.builtins().get(triple))
            else:
                descriptors.append(_descriptor(triple.normalize(), maturity="contract", backend=False,
                                               runtime=False, capabilities=(),
                                               object_format="Wasm" if triple.arch == "wasm32" else "ELF64"))
        return cls(descriptors)

    def get(self, triple: str | TargetTriple) -> TargetDescriptor:
        key = triple.normalize() if isinstance(triple, TargetTriple) else TargetTriple.parse(triple).normalize()
        try:
            return self._items[key]
        except KeyError as error:
            raise PortabilityError("NEBO-G051-TARGET-UNSUPPORTED:" + key) from error

    def list(self) -> list[dict[str, object]]:
        return [self._items[key].report() for key in sorted(self._items)]


@dataclass
class ArchitectureBackend:
    target: TargetDescriptor

    @classmethod
    def new(cls, targetDescriptor: TargetDescriptor) -> "ArchitectureBackend":
        if not targetDescriptor.backendImplemented or targetDescriptor.triple.normalize() != CURRENT_TRIPLE:
            raise PortabilityError("NEBO-G051-ARCH-BACKEND-UNAVAILABLE")
        return cls(targetDescriptor)

    def legalize(self, lir: Iterable[dict[str, object]]) -> list[dict[str, object]]:
        result = []
        for operation in lir:
            opcode = str(operation.get("op", ""))
            if opcode not in {"add.i64", "sub.i64", "load.i64", "store.i64", "call", "atomic.add"}:
                raise PortabilityError("NEBO-G051-LIR-ILLEGAL")
            result.append({**operation, "legal": True, "target": CURRENT_TRIPLE})
        return result

    def selectInstructions(self, lir: Iterable[dict[str, object]]) -> list[str]:
        mapping = {"add.i64": "add r64,r64", "sub.i64": "sub r64,r64", "load.i64": "mov r64,[mem]",
                   "store.i64": "mov [mem],r64", "call": "call rel32", "atomic.add": "lock xadd [mem],r64"}
        return [mapping[str(row["op"])] for row in self.legalize(lir)]

    def registerFile(self) -> dict[str, object]:
        return {"gpr": 16, "vector": 16, "argument": ["rdi", "rsi", "rdx", "rcx", "r8", "r9"], "return": ["rax", "rdx"]}

    def stackFrame(self, function: dict[str, int]) -> dict[str, int]:
        total = int(function.get("locals", 0)) + int(function.get("spills", 0))
        _bounded(total, 0, 1 << 20, "NEBO-G051-STACK-FRAME-LIMIT")
        return {"bytes": (total + 15) & ~15, "alignment": 16, "redZoneBytes": 128, "probeThreshold": 4096}

    def lowerCall(self, signature: dict[str, object]) -> dict[str, object]:
        count = _bounded(len(list(signature.get("parameters", []))), 0, 64, "NEBO-G051-CALL-PARAMETER-LIMIT")
        if signature.get("variadic"):
            raise PortabilityError("NEBO-G051-VARIADIC-UNSUPPORTED")
        return {"registerParameters": min(count, 6), "stackParameters": max(0, count - 6), "return": "rax"}

    def lowerAtomic(self, operation: dict[str, object]) -> dict[str, object]:
        if operation.get("op") not in {"load", "store", "add", "compare-exchange"} or operation.get("bits", 64) not in {8, 16, 32, 64}:
            raise PortabilityError("NEBO-G051-ATOMIC-UNSUPPORTED")
        return {"instruction": "lock" if operation.get("op") not in {"load", "store"} else "mov", "fallback": None}

    def relocationKinds(self) -> list[str]: return ["R_X86_64_64", "R_X86_64_PC32", "R_X86_64_PLT32"]
    def codeModel(self) -> dict[str, object]: return {"name": "small-static", "pic": False, "maximumImageBytes": 1 << 31}
    def disassemblyOracle(self) -> dict[str, object]: return {"kind": "internal-encoding-table", "externalOptional": "/usr/bin/objdump"}
    def conformanceCorpus(self) -> list[str]: return ["scalar-arithmetic-v1", "systemv-call-v1", "atomic-v1"]


@dataclass
class ObjectModel:
    target: TargetDescriptor
    sections: list[dict[str, object]] = field(default_factory=list)
    symbols: list[dict[str, object]] = field(default_factory=list)
    relocations: list[dict[str, object]] = field(default_factory=list)

    @classmethod
    def new(cls, target: TargetDescriptor) -> "ObjectModel":
        if not target.backendImplemented:
            raise PortabilityError("NEBO-G051-OBJECT-TARGET-UNAVAILABLE")
        return cls(target)


@dataclass
class ObjectWriter:
    model: ObjectModel
    format: str

    @classmethod
    def forFormat(cls, format: str, model: ObjectModel) -> "ObjectWriter":
        if format != model.target.objectFormat() or format != "ELF64":
            raise PortabilityError("NEBO-G051-OBJECT-FORMAT-UNSUPPORTED")
        return cls(model, format)

    def addSection(self, section: dict[str, object]) -> None:
        if len(self.model.sections) >= MAX_SECTIONS:
            raise PortabilityError("NEBO-G051-SECTION-LIMIT")
        name, alignment, size = str(section.get("name", "")), int(section.get("alignment", 0)), int(section.get("size", 0))
        if not re.fullmatch(r"\.[A-Za-z0-9_.-]{1,63}", name) or alignment < 1 or alignment > 4096 or alignment & (alignment - 1) or not 0 <= size <= MAX_ARTIFACT_BYTES:
            raise PortabilityError("NEBO-G051-SECTION-INVALID")
        self.model.sections.append({"name": name, "flags": sorted(set(section.get("flags", []))), "alignment": alignment, "size": size})

    def addSymbol(self, symbol: dict[str, object]) -> None:
        if len(self.model.symbols) >= MAX_SYMBOLS:
            raise PortabilityError("NEBO-G051-SYMBOL-LIMIT")
        section = int(symbol.get("section", -1))
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]{0,127}", str(symbol.get("name", ""))) or not 0 <= section < len(self.model.sections):
            raise PortabilityError("NEBO-G051-SYMBOL-INVALID")
        self.model.symbols.append({"name": symbol["name"], "scope": symbol.get("scope", "local"),
                                   "type": symbol.get("type", "object"), "value": int(symbol.get("value", 0)), "section": section})

    def addRelocation(self, relocation: dict[str, object]) -> None:
        if len(self.model.relocations) >= MAX_RELOCATIONS:
            raise PortabilityError("NEBO-G051-RELOCATION-LIMIT")
        if relocation.get("kind") not in ArchitectureBackend.new(self.model.target).relocationKinds():
            raise PortabilityError("NEBO-G051-RELOCATION-UNSUPPORTED")
        section, symbol = int(relocation.get("section", -1)), int(relocation.get("symbol", -1))
        if not 0 <= section < len(self.model.sections) or not 0 <= symbol < len(self.model.symbols):
            raise PortabilityError("NEBO-G051-RELOCATION-INVALID")
        self.model.relocations.append({"kind": relocation["kind"], "offset": int(relocation.get("offset", 0)), "section": section, "symbol": symbol})

    def emit(self, path: str | Path) -> dict[str, object]:
        payload = {"schema": 1, "target": self.model.target.triple.normalize(), "format": self.format,
                   "sections": self.model.sections, "symbols": self.model.symbols,
                   "relocations": self.model.relocations}
        data = b"NOBJ51\0" + _canonical_json(payload)
        target = _atomic_bytes(path, data)
        return {"path": str(target), "bytes": len(data), "digest": hashlib.sha256(data).hexdigest()}


@dataclass
class ExecutableWriter:
    target: TargetDescriptor
    segments: list[dict[str, object]] = field(default_factory=list)

    @classmethod
    def forTarget(cls, target: TargetDescriptor) -> "ExecutableWriter":
        if target.triple.normalize() != CURRENT_TRIPLE or not target.backendImplemented:
            raise PortabilityError("NEBO-G051-EXECUTABLE-TARGET-UNAVAILABLE")
        return cls(target)

    def addSegment(self, segment: dict[str, object]) -> None:
        flags = set(segment.get("flags", []))
        alignment = int(segment.get("alignment", 0))
        file_size, memory_size = int(segment.get("fileSize", 0)), int(segment.get("memorySize", 0))
        if flags == {"r", "w", "x"} or alignment < 1 or alignment > 1 << 21 or alignment & (alignment - 1) or file_size > memory_size or file_size < 0:
            raise PortabilityError("NEBO-G051-SEGMENT-INVALID")
        self.segments.append({"flags": sorted(flags), "alignment": alignment, "fileSize": file_size, "memorySize": memory_size})


@dataclass
class ObjectInspector:
    path: Path
    data: bytes
    parsed: dict[str, object] | None = None

    @classmethod
    def open(cls, path: str | Path) -> "ObjectInspector":
        regular = _regular(path, "NEBO-G051-OBJECT-REGULAR-REQUIRED")
        return cls(regular, regular.read_bytes())

    def validate(self) -> dict[str, object]:
        if self.data.startswith(b"NOBJ51\0"):
            value = json.loads(self.data[7:].decode("ascii"))
            if value.get("schema") != 1 or len(value.get("sections", [])) > MAX_SECTIONS or len(value.get("symbols", [])) > MAX_SYMBOLS or len(value.get("relocations", [])) > MAX_RELOCATIONS:
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            sections, symbols, relocations = value.get("sections", []), value.get("symbols", []), value.get("relocations", [])
            if not all(isinstance(row, dict) and re.fullmatch(r"\.[A-Za-z0-9_.-]{1,63}", str(row.get("name", "")))
                       and isinstance(row.get("alignment"), int) and 1 <= row["alignment"] <= 4096
                       and not row["alignment"] & (row["alignment"] - 1)
                       and isinstance(row.get("size"), int) and 0 <= row["size"] <= MAX_ARTIFACT_BYTES
                       for row in sections):
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            if not all(isinstance(row, dict) and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]{0,127}", str(row.get("name", "")))
                       and isinstance(row.get("section"), int) and 0 <= row["section"] < len(sections)
                       for row in symbols):
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            allowed_relocations = {"R_X86_64_64", "R_X86_64_PC32", "R_X86_64_PLT32"}
            if not all(isinstance(row, dict) and row.get("kind") in allowed_relocations
                       and isinstance(row.get("section"), int) and 0 <= row["section"] < len(sections)
                       and isinstance(row.get("symbol"), int) and 0 <= row["symbol"] < len(symbols)
                       and isinstance(row.get("offset"), int) and row["offset"] >= 0
                       for row in relocations):
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            self.parsed = value
            return {"valid": True, "format": value["format"], "target": value["target"],
                    "sections": len(value["sections"]), "symbols": len(value["symbols"]), "relocations": len(value["relocations"]), "security": "model-only"}
        if len(self.data) < 64 or self.data[:4] != b"\x7fELF" or self.data[4:7] != b"\x02\x01\x01":
            raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
        e_type, e_machine = struct.unpack_from("<HH", self.data, 16)
        phoff, shoff = struct.unpack_from("<QQ", self.data, 32)
        phentsize, phnum, shentsize, shnum, shstrndx = struct.unpack_from("<HHHHH", self.data, 54)
        if (e_machine != 62 or e_type not in {1, 2, 3}
                or (phnum and phentsize < 56) or (shnum and shentsize < 64)
                or phoff + phentsize * phnum > len(self.data)
                or shoff + shentsize * shnum > len(self.data)
                or (shnum and shstrndx >= shnum)):
            raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
        rwx = False
        dynamic = False
        interpreter = False
        for index in range(phnum):
            offset = phoff + index * phentsize
            if phentsize >= 56:
                p_type, p_flags = struct.unpack_from("<II", self.data, offset)
                if p_type == 1 and p_flags & 7 == 7:
                    rwx = True
                dynamic |= p_type == 2
                interpreter |= p_type == 3
        symbol_sections = 0
        relocation_sections = 0
        for index in range(shnum):
            offset = shoff + index * shentsize
            _, sh_type, _, _, sh_offset, sh_size, sh_link, _, _, sh_entry_size = struct.unpack_from("<IIQQQQIIQQ", self.data, offset)
            if sh_type != 8 and sh_offset + sh_size > len(self.data):
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            if sh_link and sh_link >= shnum:
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            if sh_entry_size and sh_size % sh_entry_size:
                raise PortabilityError("NEBO-G051-OBJECT-MALFORMED")
            symbol_sections += sh_type in {2, 11}
            relocation_sections += sh_type in {4, 9}
        if rwx:
            raise PortabilityError("NEBO-G051-OBJECT-RWX-SEGMENT")
        self.parsed = {"format": "ELF64", "target": CURRENT_TRIPLE, "sections": shnum,
                       "segments": phnum, "symbolSections": symbol_sections,
                       "relocationSections": relocation_sections, "type": e_type, "rwx": rwx,
                       "dynamic": dynamic, "interpreter": interpreter}
        return {"valid": True, **self.parsed, "security": "no-rwx-load"}

    def normalizedDigest(self) -> str:
        if self.parsed is None:
            self.validate()
        if self.data.startswith(b"NOBJ51\0"):
            value = dict(self.parsed or {})
            value.pop("metadata", None)
            return hashlib.sha256(_canonical_json(value)).hexdigest()
        return hashlib.sha256(self.data).hexdigest()


@dataclass
class PlatformBackend:
    target: TargetDescriptor
    requested: tuple[str, ...]

    @classmethod
    def forTarget(cls, target: TargetDescriptor, capabilities: Iterable[str]) -> "PlatformBackend":
        requested = tuple(sorted(set(capabilities)))
        if not target.runtimeImplemented or not set(requested).issubset(target.capability_set):
            raise PortabilityError("NEBO-G051-PLATFORM-CAPABILITY-UNSUPPORTED")
        return cls(target, requested)

    def _cap(self, name: str, detail: dict[str, object]) -> dict[str, object]:
        if name not in self.target.capability_set:
            raise PortabilityError("NEBO-G051-PLATFORM-CAPABILITY-UNSUPPORTED:" + name)
        return {"capability": name, "maturity": "native", **detail}

    def filesystem(self) -> dict[str, object]: return self._cap("filesystem", {"paths": "posix-bytes", "sandbox": "caller-policy"})
    def network(self) -> dict[str, object]: return self._cap("network", {"sockets": "linux", "dns": "not-self-contained", "tls": "not-provided"})
    def process(self) -> dict[str, object]: return self._cap("process", {"model": "linux-process", "shell": False})
    def time(self) -> dict[str, object]: return self._cap("time", {"monotonic": True, "wall": True})
    def random(self) -> dict[str, object]: return self._cap("random", {"source": "kernel-getrandom", "secure": True})
    def threads(self) -> dict[str, object]: return self._cap("threads", {"model": "host-thread", "bounded": True})
    def window(self) -> dict[str, object]:
        raise PortabilityError("NEBO-G051-PLATFORM-CAPABILITY-UNSUPPORTED:window")

    def errorMap(self, nativeCode: int) -> dict[str, object]:
        _bounded(nativeCode, 1, 4095, "NEBO-G051-NATIVE-ERROR-RANGE")
        return {"portable": {2: "not-found", 13: "permission-denied", 17: "already-exists"}.get(nativeCode, "platform-error"), "raw": nativeCode}

    def resourceLimits(self) -> dict[str, int]:
        return {"handles": 1024, "pathBytes": 4096, "sockets": 256, "threads": 64,
                "windows": 0, "stackBytes": 8 << 20, "memoryBytes": 1 << 30}

    def selfTest(self) -> dict[str, object]:
        results: dict[str, str] = {}
        with tempfile.TemporaryDirectory(prefix="nebo-g051-platform-") as directory:
            path = Path(directory) / "probe"
            path.write_bytes(b"g051")
            results["filesystem"] = "pass" if path.read_bytes() == b"g051" else "fail"
        results["time"] = "pass" if time.monotonic_ns() > 0 else "fail"
        results["random"] = "pass" if len(os.urandom(16)) == 16 else "fail"
        try:
            left, right = socket.socketpair()
            try:
                left.sendall(b"g051")
                results["network"] = "pass" if right.recv(4) == b"g051" else "fail"
            finally:
                left.close(); right.close()
        except OSError:
            results["network"] = "environment-limited"
        state: list[int] = []
        thread = threading.Thread(target=lambda: state.append(51)); thread.start(); thread.join(2)
        results["threads"] = "pass" if state == [51] else "fail"
        probe = subprocess.run(["/bin/true"], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, timeout=5, check=False)
        results["process"] = "pass" if probe.returncode == 0 else "fail"
        return {"target": self.target.triple.normalize(), "results": results,
                "maturity": "hardware", "allExecutedPassed": all(value != "fail" for value in results.values()),
                "environmentLimited": sorted(key for key, value in results.items() if value == "environment-limited")}

    def report(self) -> dict[str, object]:
        return {"target": self.target.triple.normalize(), "requested": list(self.requested),
                "available": self.target.capabilities(), "syscallModel": self.target.syscallModel(),
                "maturity": self.target.maturity, "externalDependencies": []}


@dataclass(frozen=True)
class TargetPredicate:
    kind: str
    value: str

    @classmethod
    def architecture(cls, name: str) -> "TargetPredicate": return cls("architecture", name)
    @classmethod
    def os(cls, name: str) -> "TargetPredicate": return cls("os", name)
    @classmethod
    def hasCapability(cls, capability: str) -> "TargetPredicate": return cls("capability", capability)
    @classmethod
    def hasFeature(cls, feature: str) -> "TargetPredicate": return cls("feature", feature)

    def evaluate(self, target: TargetDescriptor) -> bool:
        values = {"architecture": target.triple.arch, "os": target.triple.os}
        if self.kind in values: return values[self.kind] == self.value
        if self.kind == "capability": return self.value in target.capability_set
        if self.kind == "feature": return self.value in set(target.baseline) | set(target.optional)
        raise PortabilityError("NEBO-G051-PREDICATE-INVALID")


class TargetSelection:
    """Canonical construction for the contract's not-yet-frozen K spelling."""
    @staticmethod
    def select(predicate: TargetPredicate, target: TargetDescriptor, whenTrue: object, whenFalse: object,
               policy: str = "check-both") -> object:
        if policy != "check-both" or whenTrue is None or whenFalse is None:
            raise PortabilityError("NEBO-G051-TARGET-SELECTION-POLICY")
        return whenTrue if predicate.evaluate(target) else whenFalse


@dataclass
class PortableApi:
    required: tuple[str, ...] = ()
    fallbacks: list[dict[str, object]] = field(default_factory=list)

    def require(self, capabilities: Iterable[str]) -> "PortableApi":
        values = tuple(sorted(set(capabilities)))
        if len(values) > 32: raise PortabilityError("NEBO-G051-PORTABLE-API-LIMIT")
        self.required = values
        return self

    def fallback(self, primary: dict[str, object], alternative: dict[str, object]) -> dict[str, object]:
        if primary.get("signature") != alternative.get("signature") or primary.get("effects") != alternative.get("effects") or primary.get("errors") != alternative.get("errors"):
            raise PortabilityError("NEBO-G051-FALLBACK-CONTRACT-MISMATCH")
        row = {"primary": primary, "alternative": alternative, "contractEqual": True}
        self.fallbacks.append(row)
        return row


@dataclass
class PortabilityReport:
    targets: tuple[TargetDescriptor, ...]
    assumptions: list[dict[str, object]]

    def commonSubset(self) -> list[str]:
        sets = [set(item.capability_set) for item in self.targets]
        return sorted(set.intersection(*sets) if sets else set())

    def targetSpecificItems(self) -> list[dict[str, object]]:
        common = set(self.commonSubset())
        rows = [{"target": target.triple.normalize(), "capabilities": sorted(set(target.capability_set) - common),
                 "maturity": target.maturity} for target in self.targets]
        return rows + self.assumptions

    def as_dict(self) -> dict[str, object]:
        return {"schema": 1, "targets": [item.triple.normalize() for item in self.targets],
                "commonSubset": self.commonSubset(), "targetSpecificItems": self.targetSpecificItems(),
                "portable": not self.assumptions}


class PortabilityAnalyzer:
    @staticmethod
    def analyze(package: str | Path, targetSet: Iterable[TargetDescriptor]) -> PortabilityReport:
        selected = Path(package)
        files = [selected] if selected.is_file() else sorted(selected.rglob("*.no")) if selected.is_dir() else []
        if not files or len(files) > 256: raise PortabilityError("NEBO-G051-PROJECT-INVALID")
        assumptions: list[dict[str, object]] = []
        patterns = ((r"\bpointer(?:Bits|Width)\b", "pointer-width"), (r"\b(?:little|big)Endian\b", "endian"),
                    (r"\bsyscall(?:Number)?\b", "syscall"), (r"\brequireCapability\b", "capability"))
        for path in files:
            regular = _regular(path, "NEBO-G051-SOURCE-REGULAR-REQUIRED", MAX_SOURCE_BYTES)
            text = re.sub(r"//[^\n]*", "", regular.read_text(encoding="utf-8"))
            for pattern, kind in patterns:
                for match in re.finditer(pattern, text):
                    assumptions.append({"source": str(regular), "kind": kind,
                                        "offset": match.start(), "reason": f"explicit-{kind}-assumption"})
        targets = tuple(targetSet)
        if not 1 <= len(targets) <= MAX_TARGETS: raise PortabilityError("NEBO-G051-TARGET-SET-LIMIT")
        return PortabilityReport(targets, assumptions)


@dataclass
class TargetPack:
    path: Path
    manifest: dict[str, object]

    @classmethod
    def open(cls, path: str | Path) -> "TargetPack":
        regular = _regular(path, "NEBO-G051-TARGET-PACK-REGULAR-REQUIRED", MAX_PACK_BYTES)
        value = json.loads(regular.read_text(encoding="utf-8"))
        if not isinstance(value, dict): raise PortabilityError("NEBO-G051-TARGET-PACK-SCHEMA")
        return cls(regular, value)

    def runtimeObjects(self) -> list[str]: return list(self.manifest.get("runtimeObjects", []))
    def systemContracts(self) -> dict[str, object]: return dict(self.manifest.get("systemContracts", {}))

    def verify(self) -> dict[str, object]:
        if self.manifest.get("schema") != 1 or int(self.manifest.get("version", 0)) < 1:
            raise PortabilityError("NEBO-G051-TARGET-PACK-SCHEMA")
        TargetTriple.parse(str(self.manifest.get("triple", "")))
        files = self.manifest.get("files", [])
        if not isinstance(files, list) or len(files) > MAX_PACK_FILES: raise PortabilityError("NEBO-G051-TARGET-PACK-FILE-LIMIT")
        verified = []
        for row in files:
            relative = Path(str(row.get("path", "")))
            if relative.is_absolute() or ".." in relative.parts: raise PortabilityError("NEBO-G051-TARGET-PACK-PATH")
            path = _regular(self.path.parent / relative, "NEBO-G051-TARGET-PACK-FILE", MAX_PACK_BYTES)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != row.get("sha256"): raise PortabilityError("NEBO-G051-TARGET-PACK-HASH")
            verified.append(str(relative))
        return {"valid": True, "triple": self.manifest["triple"], "version": self.manifest["version"], "files": verified,
                "manifestDigest": hashlib.sha256(_canonical_json(self.manifest)).hexdigest()}


@dataclass
class CrossCompilation:
    host: TargetTriple
    target: TargetTriple
    targetPack: TargetPack | None

    @classmethod
    def new(cls, host: TargetTriple, target: TargetTriple, targetPack: TargetPack | None) -> "CrossCompilation":
        if host.normalize() != target.normalize() and targetPack is None:
            raise PortabilityError("NEBO-G051-TARGET-PACK-REQUIRED")
        if targetPack is not None and TargetTriple.parse(str(targetPack.manifest.get("triple", ""))).normalize() != target.normalize():
            raise PortabilityError("NEBO-G051-TARGET-PACK-MISMATCH")
        return cls(host, target, targetPack)


@dataclass
class CrossRunner:
    kind: str
    command: tuple[str, ...]
    limits: dict[str, int]
    capabilities: tuple[str, ...]
    last: dict[str, object] | None = None

    @classmethod
    def new(cls, kind: str, command: Iterable[str], limits: dict[str, int], capabilities: Iterable[str]) -> "CrossRunner":
        if kind not in {"local-native", "emulator", "no-run"}: raise PortabilityError("NEBO-G051-RUNNER-KIND")
        timeout = _bounded(int(limits.get("timeoutSeconds", 0)), 1, 60, "NEBO-G051-RUNNER-TIMEOUT")
        memory = _bounded(int(limits.get("memoryBytes", 0)), 1 << 20, 1 << 30, "NEBO-G051-RUNNER-MEMORY")
        values = tuple(command)
        if kind == "emulator" and (not values or not Path(values[0]).is_absolute() or not Path(values[0]).is_file()):
            raise PortabilityError("NEBO-G051-RUNNER-COMMAND")
        if kind != "emulator" and values: raise PortabilityError("NEBO-G051-RUNNER-COMMAND")
        return cls(kind, values, {"timeoutSeconds": timeout, "memoryBytes": memory}, tuple(sorted(set(capabilities))))

    def execute(self, artifact: str | Path, arguments: Iterable[str] = ()) -> dict[str, object]:
        path = _regular(artifact, "NEBO-G051-RUNNER-ARTIFACT")
        if self.kind == "no-run":
            self.last = {"classification": "compile-only", "executed": False, "reason": "runner-no-run"}
            return self.last
        argument_values = list(arguments)
        if len(argument_values) > 64 or any(len(value) > 4096 or "\0" in value for value in argument_values):
            raise PortabilityError("NEBO-G051-RUNNER-ARGUMENT-LIMIT")
        command = ([str(path)] if self.kind == "local-native" else [*self.command, str(path)]) + argument_values
        memory_limit = self.limits["memoryBytes"]
        def constrain() -> None:
            resource.setrlimit(resource.RLIMIT_AS, (memory_limit, memory_limit))
        result = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=self.limits["timeoutSeconds"], check=False,
                                cwd=path.parent, preexec_fn=constrain,
                                env={"LC_ALL": "C", "LANG": "C", "TZ": "UTC"})
        if len(result.stdout) + len(result.stderr) > 1 << 20:
            self.last = {"classification": "failed", "executed": True, "reason": "output-limit"}
            return self.last
        classification = ("hardware-pass" if self.kind == "local-native" else "emulator-pass") if result.returncode == 0 else "failed"
        self.last = {"classification": classification, "executed": True, "exitCode": result.returncode,
                     "stdout": result.stdout.decode("utf-8", "replace"), "stderr": result.stderr.decode("utf-8", "replace")}
        return self.last

    def environmentManifest(self) -> dict[str, object]:
        return {"kind": self.kind, "command": list(self.command), "limits": self.limits,
                "capabilities": list(self.capabilities), "kernel": host_platform.release() if self.kind == "local-native" else None,
                "cpu": host_platform.machine() if self.kind == "local-native" else None}

    def copyArtifact(self, artifact: str | Path, destination: str | Path, policy: str = "local-explicit") -> dict[str, object]:
        if policy != "local-explicit": raise PortabilityError("NEBO-G051-RUNNER-COPY-POLICY")
        source = _regular(artifact, "NEBO-G051-RUNNER-ARTIFACT")
        target = _atomic_bytes(destination, source.read_bytes(), source.stat().st_mode & 0o777)
        return {"path": str(target), "digest": hashlib.sha256(target.read_bytes()).hexdigest(), "bytes": target.stat().st_size}

    def classifyResult(self) -> str:
        return str((self.last or {"classification": "unavailable"})["classification"])


@dataclass(frozen=True)
class HostCompilerPlan:
    host: TargetTriple

    @classmethod
    def forTriple(cls, hostTriple: TargetTriple) -> "HostCompilerPlan":
        if hostTriple.normalize() != CURRENT_TRIPLE: raise PortabilityError("NEBO-G051-HOST-PLAN-UNAVAILABLE")
        return cls(hostTriple)

    def bootstrapSource(self) -> list[str]: return ["compiler/bootstrap/stage0_trust.tsv", "build/bin/neboc"]
    def platformBackend(self) -> str: return "linux-x86_64-raw-syscall"
    def packageLayout(self) -> list[str]: return ["bin", "target-packs", "docs", "schemas", "licenses"]
    def selfTestSuite(self) -> list[str]: return ["parse", "check", "emit-asm", "build", "object", "diagnostics"]


@dataclass
class HostCompilerPackage:
    manifestPath: Path
    manifest: dict[str, object]

    @classmethod
    def open(cls, path: str | Path) -> "HostCompilerPackage":
        regular = _regular(path, "NEBO-G051-HOST-PACKAGE-REGULAR-REQUIRED", MAX_PACK_BYTES)
        value = json.loads(regular.read_text(encoding="utf-8"))
        if not isinstance(value, dict): raise PortabilityError("NEBO-G051-HOST-PACKAGE-SCHEMA")
        return cls(regular, value)

    def verify(self) -> dict[str, object]:
        if self.manifest.get("schema") != 1 or self.manifest.get("host") != CURRENT_TRIPLE:
            raise PortabilityError("NEBO-G051-HOST-PACKAGE-SCHEMA")
        files = self.manifest.get("files", [])
        if not isinstance(files, list) or not 1 <= len(files) <= MAX_PACK_FILES:
            raise PortabilityError("NEBO-G051-HOST-PACKAGE-FILE-LIMIT")
        for row in files:
            relative = Path(str(row.get("path", "")))
            if relative.is_absolute() or ".." in relative.parts: raise PortabilityError("NEBO-G051-HOST-PACKAGE-PATH")
            actual = _regular(self.manifestPath.parent / relative, "NEBO-G051-HOST-PACKAGE-FILE")
            if hashlib.sha256(actual.read_bytes()).hexdigest() != row.get("sha256"):
                raise PortabilityError("NEBO-G051-HOST-PACKAGE-HASH")
            if relative.name == "neboc":
                inspected = ObjectInspector.open(actual).validate()
                if inspected.get("dynamic") or inspected.get("interpreter"):
                    raise PortabilityError("NEBO-G051-HOST-PACKAGE-UNEXPECTED-DEPENDENCY")
        return {"valid": True, "host": CURRENT_TRIPLE, "files": len(files), "externalDependencies": self.externalDependencies()}

    def restoreTest(self) -> dict[str, object]:
        self.verify()
        with tempfile.TemporaryDirectory(prefix="nebo-g051-host-package-") as directory:
            root = Path(directory)
            for row in self.manifest["files"]:
                relative = Path(str(row["path"])); source = self.manifestPath.parent / relative
                destination = root / relative; destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
            compiler = root / str(self.manifest.get("compiler", "bin/neboc"))
            result = subprocess.run([str(compiler), "--version"], stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=False)
            return {"executed": True, "exitCode": result.returncode,
                    "version": result.stdout.decode("utf-8", "replace").strip(), "restoredFiles": len(self.manifest["files"]),
                    "pass": result.returncode == 0}

    def compatibilityReport(self, otherHost: TargetTriple) -> dict[str, object]:
        return {"host": CURRENT_TRIPLE, "otherHost": otherHost.normalize(),
                "sameAbi": HostTriple.current().compatibility(otherHost) in {"exact", "abi-compatible"},
                "sameTargetArtifactPolicy": "content-digest"}

    def externalDependencies(self) -> list[str]:
        return list(self.manifest.get("externalDependencies", []))


@dataclass
class TargetConformanceSuite:
    target: TargetDescriptor
    source: Path | None = None
    evidence: dict[str, object] = field(default_factory=dict)

    @classmethod
    def forTarget(cls, target: TargetDescriptor, source: str | Path | None = None) -> "TargetConformanceSuite":
        return cls(target, _regular(source, "NEBO-G051-SOURCE-REGULAR-REQUIRED", MAX_SOURCE_BYTES) if source else None)

    def compileCorpus(self) -> dict[str, object]:
        if not self.target.backendImplemented or self.source is None:
            result = {"status": "not-run", "reason": "backend-or-source-unavailable"}
        else:
            with tempfile.TemporaryDirectory(prefix="nebo-g051-conformance-") as directory:
                asm = Path(directory) / "out.asm"; artifact = Path(directory) / "out"
                checks = []
                for command in ([str(NEBOC), "check", str(self.source)],
                                [str(NEBOC), "emit-asm", str(self.source), "-o", str(asm)],
                                [str(NEBOC), "build", str(self.source), "-o", str(artifact)]):
                    run = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                         stderr=subprocess.PIPE, timeout=30, check=False)
                    checks.append(run.returncode)
                result = {"status": "pass" if checks == [0, 0, 0] else "fail", "exitCodes": checks,
                          "artifactDigest": hashlib.sha256(artifact.read_bytes()).hexdigest() if artifact.is_file() else None}
        self.evidence["compile"] = result
        return result

    def runCorpus(self, runner: CrossRunner) -> dict[str, object]:
        if self.source is None or not self.target.backendImplemented:
            result = {"classification": "compile-only", "executed": False, "reason": "backend-or-source-unavailable"}
        else:
            with tempfile.TemporaryDirectory(prefix="nebo-g051-run-") as directory:
                artifact = Path(directory) / "program"
                build = subprocess.run([str(NEBOC), "build", str(self.source), "-o", str(artifact)], cwd=ROOT,
                                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       timeout=30, check=False)
                result = runner.execute(artifact) if build.returncode == 0 else {"classification": "failed", "executed": False, "reason": "build-failed"}
        self.evidence["run"] = result
        return result

    def abiVectors(self) -> dict[str, object]:
        result = self._native_vector("build/tests/rf52-g51/f03/arch_backend_test", ["calls", "stack", "atomics", "errors"])
        self.evidence["abi"] = result; return result

    def objectVectors(self) -> dict[str, object]:
        result = self._native_vector("build/tests/rf52-g51/f04/object_model_test", ["headers", "sections", "relocations", "security"])
        self.evidence["object"] = result; return result

    def runtimeVectors(self) -> dict[str, object]:
        result = self._native_vector("build/tests/rf52-g51/f05/platform_backend_test", self.target.capabilities(), runtime=True)
        self.evidence["runtime"] = result; return result

    def _native_vector(self, relative: str, vectors: list[str], runtime: bool = False) -> dict[str, object]:
        available = self.target.runtimeImplemented if runtime else self.target.backendImplemented
        path = ROOT / relative
        if not available:
            return {"status": "not-run", "reason": "target-owner-unavailable", "vectors": []}
        if not path.is_file() or not os.access(path, os.X_OK):
            return {"status": "not-run", "reason": "native-vector-not-built", "vectors": []}
        result = subprocess.run([str(path)], cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=20, check=False)
        return {"status": "pass" if result.returncode == 0 else "fail", "exitCode": result.returncode,
                "vectors": list(vectors), "owner": relative}

    def crossHostReproducibility(self, hosts: Iterable[TargetTriple]) -> dict[str, object]:
        values = list(hosts)
        if len(values) < 2:
            result = {"status": "not-run", "reason": "second-host-evidence-unavailable"}
        else:
            result = {"status": "environment-limited", "hosts": [item.normalize() for item in values], "reason": "requires-distinct-live-hosts"}
        self.evidence["crossHost"] = result; return result

    def report(self) -> dict[str, object]:
        return {"schema": 1, "target": self.target.triple.normalize(), "maturity": TargetMaturity.classify(self.evidence),
                "evidence": self.evidence, "notRunIsPass": False}


class TargetMaturity:
    @staticmethod
    def classify(evidence: dict[str, object]) -> str:
        run = evidence.get("run", {})
        compile_result = evidence.get("compile", {})
        if any(value.get("status") == "fail" or value.get("classification") == "failed" for value in evidence.values() if isinstance(value, dict)):
            return "blocked"
        required = all(evidence.get(name, {}).get("status") == "pass" for name in ("compile", "abi", "object", "runtime"))
        if required and run.get("classification") == "hardware-pass": return "hardware"
        if required and run.get("classification") == "emulator-pass": return "emulator"
        if compile_result.get("status") == "pass": return "compile-only"
        return "contract"


def compiler_manifest(path: str | Path = NEBOC) -> dict[str, object]:
    compiler = _regular(path, "NEBO-G051-COMPILER-REGULAR-REQUIRED")
    return {"schema": 1, "host": CURRENT_TRIPLE, "compiler": "bin/neboc",
            "files": [{"path": "bin/neboc", "sha256": hashlib.sha256(compiler.read_bytes()).hexdigest()}],
            "externalDependencies": []}
