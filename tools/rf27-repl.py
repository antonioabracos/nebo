#!/usr/bin/env python3
"""Bounded local REPL adapter; all language decisions are delegated to neboc."""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from hashlib import sha256
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

MAX_DECLARATIONS = 128
MAX_SOURCE_BYTES = 65_536
MAX_HISTORY = 64
MAX_LOADS = 16
MAX_OUTPUT_BYTES = 1_048_576


class ReplError(Exception):
    pass


@dataclass
class Session:
    compiler: Path
    generation: int = 1
    source_bytes: int = 0
    loads: int = 0
    current: Path | None = None
    history: list[tuple[str, str, str]] = field(default_factory=list)

    def _check_budget(self, content: bytes, load: bool = False) -> None:
        if not content or len(content) > MAX_SOURCE_BYTES:
            raise ReplError("source is empty or exceeds 64 KiB")
        if len(self.history) >= min(MAX_DECLARATIONS, MAX_HISTORY):
            raise ReplError("session history/declaration budget exhausted")
        if self.source_bytes + len(content) > MAX_SOURCE_BYTES:
            raise ReplError("session source budget exhausted")
        if load and self.loads >= MAX_LOADS:
            raise ReplError("session load budget exhausted")

    def _accepted(self, path: Path) -> bool:
        result = subprocess.run(
            [str(self.compiler), "check", str(path)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        return result.returncode == 0

    def admit(self, action: str, raw: str, load: bool = False) -> tuple[Path, bytes]:
        path = Path(raw).resolve()
        if not path.is_file() or path.is_symlink():
            raise ReplError(f"not a regular non-symlink source: {path}")
        content = path.read_bytes()
        self._check_budget(content, load)
        if not self._accepted(path):
            raise ReplError(f"compiler rejected source: {path}")
        digest = sha256(content).hexdigest()
        self.source_bytes += len(content)
        self.loads += load
        self.current = path
        self.history.append((action, path.name, digest))
        return path, content

    def load(self, raw: str) -> str:
        path, content = self.admit("load", raw, True)
        return f"load ok file={path.name} bytes={len(content)} generation={self.generation}"

    def evaluate(self, raw: str) -> str:
        path, content = self.admit("evaluate", raw)
        with tempfile.TemporaryDirectory(prefix="rf27-g24-repl-") as temp:
            artifact = Path(temp) / "program"
            build = subprocess.run(
                [str(self.compiler), "build", str(path), "-o", str(artifact)],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if build.returncode != 0:
                raise ReplError(f"compiler build rejected admitted source: {path}")
            run = subprocess.run(
                [str(artifact)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, timeout=5, check=False,
            )
            if len(run.stdout) + len(run.stderr) > MAX_OUTPUT_BYTES:
                raise ReplError("evaluation output budget exceeded")
        return (
            f"evaluate ok file={path.name} bytes={len(content)} exit={run.returncode} "
            f"stdout={len(run.stdout)} stderr={len(run.stderr)}"
        )

    def type_of(self, raw: str) -> str:
        path, content = self.admit("typeOf", raw)
        return f"typeOf file={path.name} type=Program bytes={len(content)} authority=neboc-check"

    def ast(self, raw: str) -> str:
        path, content = self.admit("ast", raw)
        return (
            f"ast file={path.name} status=compiler-accepted span=0:{len(content)} "
            f"source_sha256={sha256(content).hexdigest()}"
        )

    def reset(self) -> str:
        self.generation += 1
        self.source_bytes = 0
        self.loads = 0
        self.current = None
        self.history.clear()
        return f"reset ok generation={self.generation}"

    def show_history(self) -> str:
        rows = [f"history count={len(self.history)} generation={self.generation}"]
        rows.extend(
            f"{index}\t{action}\t{name}\t{digest[:16]}"
            for index, (action, name, digest) in enumerate(self.history, 1)
        )
        return "\n".join(rows)


def dispatch(session: Session, line: str) -> tuple[bool, str | None]:
    words = shlex.split(line, comments=False, posix=True)
    if not words:
        return True, None
    command = words[0]
    if command in {"quit", "exit"} and len(words) == 1:
        return False, "quit ok"
    if command in {"history", "reset"} and len(words) == 1:
        return True, session.show_history() if command == "history" else session.reset()
    if command in {"load", "evaluate", "typeOf", "ast"} and len(words) == 2:
        operation = {"load": session.load, "evaluate": session.evaluate,
                     "typeOf": session.type_of, "ast": session.ast}[command]
        return True, operation(words[1])
    raise ReplError(f"invalid command: {line}")


def main(argv: list[str] | None = None) -> int:
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(prog="neboc repl")
    parser.add_argument("--script", type=Path, help="read deterministic local commands")
    parser.add_argument("--compiler", type=Path, default=repo / "build/bin/neboc")
    args = parser.parse_args(argv)
    compiler = args.compiler.resolve()
    if not compiler.is_file():
        print(f"neboc repl: compiler not found: {compiler}", file=sys.stderr)
        return 2
    session = Session(compiler)
    stream = args.script.open(encoding="utf-8") if args.script else sys.stdin
    try:
        for raw in stream:
            try:
                keep_going, output = dispatch(session, raw.strip())
            except (OSError, ReplError, subprocess.TimeoutExpired) as exc:
                print(f"neboc repl: {exc}", file=sys.stderr)
                return 2
            if output is not None:
                print(output)
            if not keep_going:
                break
    finally:
        if args.script:
            stream.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
