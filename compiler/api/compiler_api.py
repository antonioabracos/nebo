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


class Compiler:
    MAX_SOURCES = 256
    MAX_SOURCE_BYTES = 1_048_576
    TARGET = "x86_64-systemv-elf-linux"

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
        self._cancelled = False

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

    def parse(self, _module: Module) -> None:
        raise CompilerApiError("NG46_F0102", "raw AST is contract-only; use check")

    def lower(self, _module: Module) -> None:
        raise CompilerApiError("NG46_F0102", "raw lowering is contract-only; use emit_assembly")

    def check(self, module: Module) -> None:
        self._run(["check", str(module.source)])
        self._events.append(f"check:{module.digest}")

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

    def link(self, objects: list[bytes]) -> bytes:
        self._require_live()
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
        return "\n".join(["compiler-api=NEBO_COMPILER_API_V1", f"target={self.TARGET}", *self._events]) + "\n"

    def cancel(self) -> None:
        self._cancelled = True

    def close(self) -> None:
        shutil.rmtree(self._root, ignore_errors=True)
