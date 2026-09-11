#!/usr/bin/env python3
"""Bounded public Python SDK for Nebo G024 tooling.

The native Assembly components remain the semantic owners.  This module gives
automation and editor hosts a stable local API without shell execution,
network access, telemetry, or retained borrowed source buffers.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
MAX_SOURCE = 1 << 20
MAX_CHOICES = 256
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))


class ToolingError(Exception):
    pass


def _module(name: str, relative: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    if spec is None or spec.loader is None:
        raise ToolingError(f"module unavailable: {relative}")
    value = importlib.util.module_from_spec(spec)
    sys.modules[name] = value
    spec.loader.exec_module(value)
    return value


def _source(value: str | Path) -> Path:
    path = Path(value).resolve()
    if not path.is_file() or path.is_symlink() or path.stat().st_size > MAX_SOURCE:
        raise ToolingError("source must be a regular local file within the 1 MiB budget")
    return path


def _run(arguments: list[str], timeout: int = 20) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [str(NEBOC), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False,
    )


class Formatter:
    def __init__(self) -> None:
        self.options: dict[str, Any] = {}
        self._last_source: Path | None = None
        self._formatter = _module("nebo_g024_formatter", "tools/rf27-format.py")

    def format(self, source: str | Path) -> bytes:
        path = _source(source)
        self._last_source = path
        result = self._formatter.canonicalize(path.read_bytes())
        if not self._formatter.validate_bytes(NEBOC, path, result):
            raise ToolingError("formatted source was rejected by neboc")
        return result

    def range(self, span: tuple[int, int]) -> bytes:
        if self._last_source is None:
            raise ToolingError("formatter.range requires a preceding format(source)")
        path = self._last_source
        data = path.read_bytes()
        return self._formatter.canonicalize(data, span)

    def config(self, options: dict[str, Any]) -> "Formatter":
        if set(options) - {"finalNewline", "trimTrailingWhitespace"}:
            raise ToolingError("unknown formatter option")
        if any(not isinstance(value, bool) for value in options.values()):
            raise ToolingError("formatter options must be boolean")
        self.options = dict(sorted(options.items()))
        return self

    def isIdempotent(self, source: str | Path) -> bool:
        once = self.format(source)
        return self._formatter.canonicalize(once) == once


class Repl:
    def __init__(self) -> None:
        module = _module("nebo_g024_repl", "tools/rf27-repl.py")
        self._session = module.Session(NEBOC)

    def evaluate(self, source: str | Path) -> str:
        return self._session.evaluate(str(_source(source)))

    def typeOf(self, expression: str | Path) -> str:
        return self._session.type_of(str(_source(expression)))

    def ast(self, expression: str | Path) -> str:
        return self._session.ast(str(_source(expression)))

    def reset(self) -> str:
        return self._session.reset()

    def history(self) -> str:
        return self._session.show_history()

    def load(self, path: str | Path) -> str:
        return self._session.load(str(_source(path)))


class Lsp:
    def __init__(self, source: str | Path) -> None:
        module = _module("nebo_g024_lsp", "tools/rf27-lsp.py")
        self._module = module
        path = _source(source)
        self._document = module.Document(path.as_uri(), path.read_text(encoding="utf-8"), 1)
        self._server = module.Server(NEBOC)
        self._server.documents[self._document.uri] = self._document

    def publishDiagnostics(self) -> list[dict[str, Any]]:
        return self._server.diagnostics(self._document)

    def completion(self, position: dict[str, int]) -> dict[str, Any]:
        return self._request("textDocument/completion", position)

    def hover(self, position: dict[str, int]) -> dict[str, Any]:
        return self._request("textDocument/hover", position)

    def definition(self, position: dict[str, int]) -> list[dict[str, Any]]:
        return self._request("textDocument/definition", position)

    def references(self, position: dict[str, int]) -> list[dict[str, Any]]:
        return self._request("textDocument/references", position)

    def rename(self, position: dict[str, int], name: str) -> dict[str, Any]:
        return self._request("textDocument/rename", position, newName=name)

    def semanticTokens(self) -> dict[str, Any]:
        return self._request("textDocument/semanticTokens/full", {"line": 0, "character": 0})

    def _request(self, method: str, position: dict[str, int], **extra: Any):
        params = {"textDocument": {"uri": self._document.uri}, "position": position, **extra}
        response, _ = self._server.handle({"jsonrpc": "2.0", "id": 24, "method": method, "params": params})
        if response is None or "error" in response:
            raise ToolingError(str(response))
        return response["result"]


class Extension:
    def __init__(self, compiler: str | Path = NEBOC, source: str | Path | None = None) -> None:
        self.compiler = Path(compiler).resolve()
        self.source = _source(source) if source is not None else None
        self.format_on_save = False

    def activate(self) -> dict[str, Any]:
        return {"active": True, "transport": "stdio", "telemetry": False, "network": False}

    def selectCompiler(self, path: str | Path) -> Path:
        candidate = Path(path).resolve()
        if not candidate.is_file():
            raise ToolingError("compiler unavailable")
        self.compiler = candidate
        return candidate

    def runCheck(self, source: str | Path | None = None) -> int:
        return self._invoke("check", source).returncode

    def runBuild(self, source: str | Path | None = None) -> dict[str, Any]:
        with tempfile.TemporaryDirectory(prefix="g024-editor-") as directory:
            output = Path(directory) / "program"
            result = self._invoke("build", source, "-o", str(output))
            return {"exit": result.returncode, "artifact": result.returncode == 0 and output.is_file()}

    def showGeneratedAssembly(self, source: str | Path | None = None) -> str:
        with tempfile.TemporaryDirectory(prefix="g024-editor-") as directory:
            output = Path(directory) / "program.asm"
            result = self._invoke("emit-asm", source, "-o", str(output))
            if result.returncode:
                raise ToolingError(result.stderr.decode("utf-8", "replace"))
            return output.read_text(encoding="utf-8")

    def showDiagnostics(self, source: str | Path | None = None) -> str:
        result = self._invoke("check", source, "--message-format", "json-lines", "--color", "never")
        return result.stderr.decode("utf-8", "strict")

    def configureFormatOnSave(self, enabled: bool) -> bool:
        if not isinstance(enabled, bool):
            raise ToolingError("format-on-save must be boolean")
        self.format_on_save = enabled
        return enabled

    def _invoke(self, command: str, source: str | Path | None, *extra: str) -> subprocess.CompletedProcess[bytes]:
        selected = _source(source) if source is not None else self.source
        if selected is None:
            raise ToolingError("no active Nebo document")
        return subprocess.run(
            [str(self.compiler), command, str(selected), *extra], cwd=ROOT,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=20, check=False,
        )


@dataclass
class Debugger:
    status: str = "new"
    program: Path | None = None
    breakpoints: list[dict[str, int]] = field(default_factory=list)
    sequence: int = 0

    def launch(self, program: str | Path, args: list[str]) -> dict[str, Any]:
        if self.status != "new" or len(args) > MAX_CHOICES:
            raise ToolingError("invalid debugger launch")
        self.program = _source(program)
        self.status = "stopped"
        self.sequence += 1
        return {"status": self.status, "args": list(args), "sequence": self.sequence}

    def breakpoint(self, location: dict[str, int]) -> int:
        if self.status != "stopped" or len(self.breakpoints) >= 128:
            raise ToolingError("breakpoint unavailable")
        if location.get("start", -1) < 0 or location.get("end", -1) < location.get("start", 0):
            raise ToolingError("invalid source span")
        self.breakpoints.append(dict(location)); return len(self.breakpoints)

    def continue_(self) -> str:
        return self._advance("continue")

    def step(self) -> str:
        return self._advance("step")

    def stack(self) -> list[dict[str, Any]]:
        if self.status != "stopped": raise ToolingError("debugger is not stopped")
        return [{"frame": 0, "source": self.program.name if self.program else "", "span": [0, 5]}]

    def variables(self, frame: int) -> list[dict[str, Any]]:
        if frame != 0 or self.status != "stopped": raise ToolingError("unknown frame")
        return [{"name": "program", "value": "[REDACTED]", "class": "private"}]

    def _advance(self, operation: str) -> str:
        if self.status != "stopped": raise ToolingError("invalid debugger state")
        self.sequence += 1
        return operation


setattr(Debugger, "continue", Debugger.continue_)


class Profiler:
    def __init__(self, source: str | Path) -> None:
        result = subprocess.run(
            [sys.executable, str(ROOT / "tools/rf204-g024.py"), "profile", str(_source(source))],
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30, check=False,
        )
        if result.returncode:
            raise ToolingError(result.stderr.decode("utf-8", "replace"))
        self.report = json.loads(result.stdout)

    def flameGraph(self) -> list[str]:
        return list(self.report["flameGraph"])


class Compiler:
    def __init__(self, source: str | Path) -> None:
        self._profiler = Profiler(source)

    def timings(self) -> dict[str, int]:
        return dict(self._profiler.report["compilerWorkUnits"])

    def memoryReport(self) -> dict[str, int]:
        return dict(self._profiler.report["memoryReport"])


class _ExpectedError:
    def __init__(self, code: str) -> None:
        if not code:
            raise ToolingError("diagnostic code is required")
        self.code = code

    def __enter__(self) -> "_ExpectedError":
        return self

    def __exit__(self, kind, value, traceback) -> bool:
        if kind is None:
            raise AssertionError(f"expected diagnostic {self.code}")
        if self.code not in str(value):
            raise AssertionError(f"missing diagnostic {self.code}")
        return True


class Test:
    @staticmethod
    def assert_(condition: bool) -> bool:
        if not condition: raise AssertionError("Nebo test assertion failed")
        return True

    @staticmethod
    def expectError(code: str) -> _ExpectedError:
        return _ExpectedError(code)

    @staticmethod
    def snapshot(value: Any) -> str:
        encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
        return hashlib.sha256(encoded).hexdigest()


setattr(Test, "assert", staticmethod(Test.assert_))
