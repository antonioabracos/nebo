#!/usr/bin/env python3
"""Public offline command host for the G024 Nebo tooling surfaces."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
NEBOC = ROOT / "build/bin/neboc"
if not NEBOC.is_file():
    NEBOC = ROOT / "bin/neboc"
TOOLS = ROOT / "tools"
MAX_SOURCE = 1 << 20


class ToolError(Exception):
    pass


def execute(script: str, arguments: list[str]) -> int:
    path = TOOLS / script
    os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
    os.execv(sys.executable, [sys.executable, "-BS", str(path), *arguments])
    return 127


def source_path(raw: str) -> Path:
    path = Path(raw).resolve()
    if not path.is_file() or path.is_symlink() or path.stat().st_size > MAX_SOURCE:
        raise ToolError("SOURCE_BOUND")
    return path


def compiler(command: list[str]) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [str(NEBOC), *command], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20, check=False,
    )


def admitted(path: Path) -> None:
    result = compiler(["check", str(path)])
    if result.returncode:
        sys.stderr.buffer.write(result.stderr)
        raise ToolError("COMPILER_REJECTED_SOURCE")


def profile(raw: str) -> dict[str, object]:
    path = source_path(raw)
    data = path.read_bytes()
    admitted(path)
    with tempfile.TemporaryDirectory(prefix="g024-profile-") as temporary:
        asm = Path(temporary) / "program.asm"
        artifact = Path(temporary) / "program"
        emitted = compiler(["emit-asm", str(path), "-o", str(asm)])
        if emitted.returncode:
            raise ToolError("EMIT_ASM_FAILED")
        built = compiler(["build", str(path), "-o", str(artifact)])
        if built.returncode:
            raise ToolError("BUILD_FAILED")
        observed = subprocess.run(
            [str(artifact)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, timeout=5, check=False,
        )
        assembly = asm.read_bytes()
    if len(observed.stdout) + len(observed.stderr) > MAX_SOURCE:
        raise ToolError("OUTPUT_BOUND")
    return {
        "schema": 1,
        "command": "profile",
        "source_sha256": hashlib.sha256(data).hexdigest(),
        "assembly_sha256": hashlib.sha256(assembly).hexdigest(),
        "compilerWorkUnits": {
            "parseBytes": len(data), "loweredLines": data.count(b"\n"),
            "codegenBytes": len(assembly),
        },
        "memoryReport": {"sourceBytes": len(data), "assemblyBytes": len(assembly)},
        "flameGraph": ["neboc;parse", "neboc;semantic", "neboc;lower", "neboc;codegen"],
        "observed": {
            "exit": observed.returncode,
            "stdoutSha256": hashlib.sha256(observed.stdout).hexdigest(),
            "stderrSha256": hashlib.sha256(observed.stderr).hexdigest(),
        },
    }


def emit_ir(stage: str, raw: str) -> dict[str, object]:
    path = source_path(raw)
    data = path.read_bytes()
    admitted(path)
    text = data.decode("utf-8", "strict")
    tokens = re.findall(r"[A-Za-z_][A-Za-z0-9_]*|-?[0-9]+|[^\s]", text)
    if len(tokens) > 8192:
        raise ToolError("TOKEN_BOUND")
    return {
        "schema": 1,
        "stage": stage,
        "sourceSha256": hashlib.sha256(data).hexdigest(),
        "tokenCount": len(tokens),
        "tokens": tokens,
        "compilerAdmission": "PASS",
    }


def main(arguments: list[str]) -> int:
    if not arguments:
        raise ToolError("COMMAND_REQUIRED")
    command, rest = arguments[0], arguments[1:]
    if command == "doctor":
        return execute("nebo-doctor.py", rest)
    if command == "format":
        return execute("rf27-format.py", rest)
    if command == "dump" and len(rest) == 2 and rest[0] == "doc-ast":
        return execute("rf204-g155.py", [command, *rest])
    if command == "dump" and len(rest) == 2 and rest[0] == "doc-record":
        return execute("rf204-g156.py", [command, *rest])
    if command == "check-docs":
        return execute("rf204-g157.py", [command, *rest])
    if command == "test-docs":
        return execute("rf204-g158.py", [command, *rest])
    if command == "docs":
        return execute("rf204-g159.py", [command, *rest])
    if command in {"symbols", "symbol-index"}:
        return execute("rf204-g160.py", [command, *rest])
    if command in {"completion-debug", "completion-corpus"}:
        return execute("rf204-g161.py", [command, *rest])
    if command in {"hover", "signature-help", "definition", "references", "rename", "navigation-corpus"}:
        return execute("rf204-g162.py", [command, *rest])
    if command in {"module-check","link"}:
        return execute("rf204-g163.py", [{"module-check":"check","link":"build"}[command], *rest])
    if command in {"check","emit-asm","build"} and ("--no-prelude" in rest or "--edition" not in rest):
        return execute("rf204-g163.py", [command, *rest])
    if command == "check" and "--edition" in rest:
        return execute("rf204-g027.py", [command, *rest])
    if command in {"prelude-report", "migrate-imports", "stdlib", "_prelude-corpus"}:
        return execute("rf204-g163.py", [command, *rest])
    if command == "dump" and len(rest) == 2 and rest[0] == "comment-trivia":
        return execute("rf204-g164.py", [command, *rest])
    if command == "lint" and "--group" in rest and "comments" in rest:
        return execute("rf204-g164.py", [command, *rest])
    if command == "repl":
        return execute("rf27-repl.py", rest)
    if command == "lsp":
        if rest:
            raise ToolError("LSP_TAKES_NO_ARGUMENTS")
        return execute("rf27-lsp.py", rest)
    if command == "operator-info":
        return execute("rf148-g128.py", rest)
    if command in {"init", "add", "remove", "resolve", "vendor", "package", "audit"}:
        return execute("rf27-package.py", [command, *rest])
    if command == "test":
        if not rest or rest[0].startswith("-"):
            rest = [".", *rest]
        return execute("rf27-test.py", ["test", *rest])
    if command == "conformance" and rest == ["modules-docs-lsp"]:
        return execute("rf204-g165.py", [command, *rest])
    if command in {"fuzz-source", "migration-check"}:
        return execute("rf204-g165.py", [command, *rest])
    if command == "selftest" and rest == ["modules-docs-devex"]:
        raise ToolError("HISTORICAL_ORCHESTRATION_EXCLUDED: use scripts/ci-public.sh for public validation")
    if command == "roadmap-closeout" and rest == ["rf166"]:
        raise ToolError("HISTORICAL_ORCHESTRATION_EXCLUDED: use scripts/ci-public.sh for public validation")
    if command == "migrate" and not any(arg.split("=", 1)[0] in {"--from", "--to"} for arg in rest):
        # This owner is included in source, SDK and tooling profiles. Dispatch
        # directly so an installed SDK does not depend on repository scripts.
        sys.path.insert(0, str(ROOT))
        from compiler.migration.semantic_migration import main as migrate
        return migrate(rest)
    if command in {
        "abi-report", "runtime-report", "compatibility-report", "migrate",
        "conformance-manifest", "doctor", "security-report", "release",
        "examples", "nebo-1.0-readiness",
    }:
        return execute("rf204-g027.py", [command, *rest])
    if command in {"conformance", "fuzz"}:
        return execute("rf27-test.py", [command, *rest])
    if command == "profile" and len(rest) == 1:
        print(json.dumps(profile(rest[0]), sort_keys=True, separators=(",", ":")))
        return 0
    if command in {"emit-hir", "emit-lir"} and len(rest) == 1:
        print(json.dumps(emit_ir(command[5:].upper(), rest[0]), sort_keys=True, separators=(",", ":")))
        return 0
    raise ToolError("INVALID_ARGUMENTS")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (ToolError, OSError, UnicodeError, subprocess.TimeoutExpired) as error:
        print(f"NEBO_G024_TOOL_ERROR:{error}", file=sys.stderr)
        raise SystemExit(2)
