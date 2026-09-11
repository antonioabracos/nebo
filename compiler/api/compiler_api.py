"""Bounded RF46 compiler session API backed by the canonical neboc executable.

This module intentionally owns no lexer, parser, semantic model, or code
generator.  All source processing is delegated to the same versioned `neboc`
pipeline used by the CLI; NASM and ld are only used for object/link stages.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile


class CompilerApiError(RuntimeError):
    def __init__(self, diagnostic: str, message: str):
        super().__init__(f"{diagnostic}: {message}")
        self.diagnostic = diagnostic


@dataclass(frozen=True)
class Module:
    name: str
    source: Path
    digest: str


@dataclass(frozen=True)
class ParsedModule:
    module: Module
    ast_digest: str
    diagnostics: tuple[str, ...]


@dataclass(frozen=True)
class CheckedModule:
    parsed: ParsedModule
    semantic_digest: str


@dataclass(frozen=True)
class LoweredModule:
    checked: CheckedModule
    hir_digest: str
    lir_digest: str
    assembly: bytes


class Compiler:
    MAX_SOURCES = 256
    MAX_SOURCE_BYTES = 1_048_576
    TARGET = "x86_64-systemv-elf-linux"
    RUNTIME = "runtime-v1"
    ABI = "nebo-internal-v1"
    FEATURES = "baseline"

    @classmethod
    def new(cls, options: dict[str, object], capabilities: frozenset[str]) -> "Compiler":
        neboc = options.get("neboc")
        target = options.get("target", cls.TARGET)
        if not isinstance(neboc, Path) or not isinstance(target, str) or "compile" not in capabilities:
            raise CompilerApiError("NG46_F0101", "invalid options or missing compile capability")
        return cls(neboc, target=target)

    def __init__(self, neboc: Path, *, target: str = TARGET):
        if target != self.TARGET:
            raise CompilerApiError("NG46_F0102", "unsupported target")
        executable = neboc.resolve()
        if not executable.is_file():
            raise CompilerApiError("NG46_F0101", "neboc executable missing")
        self._neboc = executable
        self._runtime_object = executable.parents[2] / "build/obj/runtime_practical_io.o"
        self._root = Path(tempfile.mkdtemp(prefix="nebo-compiler-api."))
        self._modules: dict[str, Module] = {}
        self._events: list[str] = []
        self._diagnostic_count = 0
        self._cancelled = False
        self._compiler_version = self._run(["--version"]).stdout.decode("utf-8", "strict").strip()

    def __enter__(self) -> "Compiler":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def _require_live(self) -> None:
        if self._cancelled:
            raise CompilerApiError("NG46_F0103", "session cancelled")

    def _run(self, arguments: list[str]) -> subprocess.CompletedProcess[bytes]:
        self._require_live()
        result = subprocess.run(
            [str(self._neboc), *arguments],
            cwd=self._root,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )
        if result.returncode != 0:
            self._diagnostic_count += 1
            raise CompilerApiError("NG46_F0103", result.stderr.decode("utf-8", "replace").strip())
        return result

    def add_source(self, path: str, text: str) -> Module:
        self._require_live()
        if len(self._modules) >= self.MAX_SOURCES:
            raise CompilerApiError("NG46_F0101", "source count limit")
        encoded = text.encode("utf-8")
        if len(encoded) > self.MAX_SOURCE_BYTES or not path.endswith(".no"):
            raise CompilerApiError("NG46_F0101", "invalid source path or size")
        name = Path(path).name
        if name in self._modules or name in {".", ".."}:
            raise CompilerApiError("NG46_F0101", "duplicate source")
        source = self._root / name
        source.write_bytes(encoded)
        module = Module(name, source, hashlib.sha256(encoded).hexdigest())
        self._modules[name] = module
        self._events.append(f"add:{name}:{module.digest}")
        return module

    def parse(self, module: Module) -> ParsedModule:
        self._run(["check", str(module.source)])
        digest = hashlib.sha256(("NEBO-AST-V1\0" + module.digest).encode()).hexdigest()
        self._events.append(f"parse:{digest}")
        return ParsedModule(module, digest, ())

    def check(self, module: Module) -> CheckedModule:
        self._run(["check", str(module.source)])
        self._events.append(f"check:{module.digest}")
        parsed = ParsedModule(module, hashlib.sha256(("NEBO-AST-V1\0" + module.digest).encode()).hexdigest(), ())
        semantic = hashlib.sha256(("NEBO-CHECKED-V1\0" + parsed.ast_digest).encode()).hexdigest()
        return CheckedModule(parsed, semantic)

    def lower(self, module: Module) -> LoweredModule:
        checked = self.check(module)
        assembly = self.emit_assembly(module)
        hir = hashlib.sha256(("NEBO-HIR-V1\0" + checked.semantic_digest).encode()).hexdigest()
        lir = hashlib.sha256(b"NEBO-LIR-V1\0" + assembly).hexdigest()
        self._events.append(f"lower:{hir}:{lir}")
        return LoweredModule(checked, hir, lir, assembly)

    def emit_assembly(self, module: Module, target: str = TARGET) -> bytes:
        if target != self.TARGET:
            raise CompilerApiError("NG46_F0102", "unsupported target")
        output = self._root / f"{module.name}.asm"
        self._run(["emit-asm", str(module.source), "-o", str(output)])
        data = output.read_bytes()
        self._events.append(f"asm:{hashlib.sha256(data).hexdigest()}")
        return data

    def emit_object(self, module: Module, target: str = TARGET) -> bytes:
        assembly = self.emit_assembly(module, target)
        asm_path = self._root / f"{module.name}.object.asm"
        object_path = self._root / f"{module.name}.o"
        asm_path.write_bytes(assembly)
        result = subprocess.run(
            ["nasm", "-f", "elf64", "-o", object_path.name, asm_path.name],
            cwd=self._root,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30, check=False,
        )
        if result.returncode != 0:
            raise CompilerApiError("NG46_F0103", result.stderr.decode("utf-8", "replace").strip())
        data = object_path.read_bytes()
        self._events.append(f"object:{hashlib.sha256(data).hexdigest()}")
        return data

    def link(self, objects: list[bytes], options: dict[str, object] | None = None) -> bytes:
        self._require_live()
        if options not in (None, {}, {"static": True}):
            raise CompilerApiError("NG46_F0102", "only static bounded linking is supported")
        if not objects or len(objects) > self.MAX_SOURCES:
            raise CompilerApiError("NG46_F0101", "object count limit")
        paths: list[str] = []
        for index, data in enumerate(objects):
            if len(data) > self.MAX_SOURCE_BYTES:
                raise CompilerApiError("NG46_F0101", "object size limit")
            path = self._root / f"link-{index}.o"
            path.write_bytes(data)
            paths.append(path.name)
        output = self._root / "linked.elf"
        if not self._runtime_object.is_file():
            raise CompilerApiError("NG46_F0103", "canonical runtime object missing")
        result = subprocess.run(
            ["ld", "-static", "-nostdlib", "-o", output.name, *paths, str(self._runtime_object)],
            cwd=self._root,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30, check=False,
        )
        if result.returncode != 0:
            raise CompilerApiError("NG46_F0103", result.stderr.decode("utf-8", "replace").strip())
        data = output.read_bytes()
        self._events.append(f"link:{hashlib.sha256(data).hexdigest()}")
        return data

    def report(self) -> str:
        source_bytes = sum(module.source.stat().st_size for module in self._modules.values())
        return "\n".join([
            "compiler-api=NEBO_COMPILER_API_V1",
            f"compiler={self._compiler_version}",
            f"target={self.TARGET}",
            "timing-model=DETERMINISTIC_PHASE_INVOCATION_COUNTS",
            f"phase-invocations={len(self._events)}",
            f"memory-source-bytes={source_bytes}",
            "cache-policy=SESSION_LOCAL_NO_CROSS_SESSION_CACHE",
            f"diagnostic-count={self._diagnostic_count}",
            *self._events,
        ]) + "\n"

    def optimize_with(self, profile: object) -> object:
        from runtime.profile.profile import Profile, ProfileOptimizer

        if not isinstance(profile, Profile):
            raise CompilerApiError("NG46_F0502", "invalid profile")
        identity = profile.identity
        module_digests = {module.digest for module in self._modules.values()}
        if (
            identity.program_digest not in module_digests
            or identity.compiler != self._compiler_version
            or identity.runtime != self.RUNTIME
            or identity.abi != self.ABI
            or identity.target != self.TARGET
            or identity.features != self.FEATURES
        ):
            raise CompilerApiError("NG46_F0502", "profile does not match this compiler session")
        result = ProfileOptimizer.optimize_with(profile, identity)
        self._events.append(f"pgo:{profile.digest()}")
        return result

    def cancel(self) -> None:
        self._cancelled = True

    def self_check(self, source_tree: Path) -> tuple[str, ...]:
        self._require_live()
        sources = sorted(source_tree.resolve().rglob("*.no"))
        if not sources:
            raise CompilerApiError("NG46_F0702", "source compiler modules are not available")
        if len(sources) > self.MAX_SOURCES:
            raise CompilerApiError("NG46_F0101", "source count limit")
        checked = []
        for index, source in enumerate(sources):
            module = self.add_source(f"self-{index}.no", source.read_text(encoding="utf-8"))
            checked.append(self.check(module).semantic_digest)
        return tuple(checked)

    def close(self) -> None:
        shutil.rmtree(self._root, ignore_errors=True)

    addSource = add_source
    emitAssembly = emit_assembly
    emitObject = emit_object
    optimizeWith = optimize_with
    selfCheck = self_check
