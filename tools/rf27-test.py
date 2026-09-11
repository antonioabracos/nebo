#!/usr/bin/env python3
"""Offline, fixed-command RF27 test/conformance/fuzz/snapshot driver."""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import random
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
NEBOC = ROOT / "build/bin/neboc"
MAX_SOURCE = 1 << 20
MAX_CASES = 1024
MAX_FUZZ = 4096


class ToolError(Exception):
    pass


def local_path(path: Path, base: Path) -> Path:
    root = base.resolve()
    resolved = path.resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ToolError("TRAVERSAL_DENIED") from exc
    if path.is_symlink():
        raise ToolError("SYMLINK_DENIED")
    return resolved


def read_source(path: Path) -> bytes:
    if not path.is_file() or path.stat().st_size > MAX_SOURCE:
        raise ToolError("SOURCE_BOUND")
    return path.read_bytes()


def run_check(path: Path) -> dict[str, object]:
    try:
        proc = subprocess.run(
            [str(NEBOC), "check", str(path)], cwd=ROOT, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=False,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        )
    except subprocess.TimeoutExpired as exc:
        raise ToolError("COMPILER_TIMEOUT") from exc
    path_bytes = os.fsencode(path)
    stdout = proc.stdout.replace(path_bytes, b"<SOURCE>")
    stderr = proc.stderr.replace(path_bytes, b"<SOURCE>")
    return {
        "status": "pass" if proc.returncode == 0 else "fail",
        "exit": proc.returncode,
        "stdout_sha256": hashlib.sha256(stdout).hexdigest(),
        "stderr_sha256": hashlib.sha256(stderr).hexdigest(),
    }


def discover(root: Path, pattern: str) -> list[Path]:
    base = root.resolve()
    if not base.is_dir() or root.is_symlink():
        raise ToolError("ROOT_INVALID")
    paths = []
    for candidate in root.rglob("*.no"):
        safe = local_path(candidate, base)
        relative = safe.relative_to(base).as_posix()
        if fnmatch.fnmatchcase(relative, pattern):
            paths.append(safe)
    paths.sort(key=lambda item: item.relative_to(base).as_posix())
    if len(paths) > MAX_CASES:
        raise ToolError("CASE_LIMIT")
    return paths


def expected_from_name(path: Path) -> str:
    if path.name.endswith(".pass.no"):
        return "pass"
    if path.name.endswith(".fail.no"):
        return "fail"
    raise ToolError("UNKNOWN_EXPECTATION")


def command_test(args: argparse.Namespace) -> dict[str, object]:
    root = Path(args.root)
    cases = []
    for path in discover(root, args.filter):
        read_source(path)
        actual = run_check(path)
        expected = expected_from_name(path)
        if actual["status"] != expected:
            raise ToolError("EXPECTATION_MISMATCH")
        cases.append({"path": path.relative_to(root.resolve()).as_posix(), "expect": expected, **actual})
    return {"schema": 1, "command": "test", "count": len(cases), "cases": cases}


def command_conformance(args: argparse.Namespace) -> dict[str, object]:
    manifest_path = Path(args.manifest).resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema") != 1 or not isinstance(manifest.get("cases"), list):
        raise ToolError("MANIFEST_SCHEMA")
    entries = manifest["cases"]
    if len(entries) > MAX_CASES:
        raise ToolError("CASE_LIMIT")
    base = manifest_path.parent.resolve()
    seen: set[str] = set()
    results = []
    for entry in entries:
        relative = entry.get("path")
        expected = entry.get("expect")
        if not isinstance(relative, str) or expected not in ("pass", "fail") or relative in seen:
            raise ToolError("MANIFEST_CASE")
        seen.add(relative)
        path = local_path(base / relative, base)
        read_source(path)
        actual = run_check(path)
        if actual["status"] != expected:
            raise ToolError("EXPECTATION_MISMATCH")
        results.append({"path": relative, "expect": expected, **actual})
    return {"schema": 1, "command": "conformance", "count": len(results), "cases": results}


def mutate(data: bytes, rng: random.Random) -> bytes:
    value = bytearray(data or b" ")
    operation = rng.randrange(3)
    index = rng.randrange(len(value))
    if operation == 0 and len(value) < MAX_SOURCE:
        value.insert(index, rng.randrange(128))
    elif operation == 1 and len(value) > 1:
        del value[index]
    else:
        value[index] = rng.randrange(128)
    return bytes(value)


def command_fuzz(args: argparse.Namespace) -> dict[str, object]:
    if args.cases < 1 or args.cases > MAX_FUZZ:
        raise ToolError("FUZZ_LIMIT")
    source = Path(args.source).resolve()
    original = read_source(source)
    rng = random.Random(args.seed)
    rows = []
    with tempfile.TemporaryDirectory(prefix="rf27-test-fuzz-") as directory:
        candidate = Path(directory) / "candidate.no"
        for case in range(args.cases):
            payload = mutate(original, rng)
            candidate.write_bytes(payload)
            result = run_check(candidate)
            rows.append(f"{case}:{hashlib.sha256(payload).hexdigest()}:{result['status']}:{result['exit']}:{result['stderr_sha256']}")
    digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
    return {"schema": 1, "command": "fuzz", "seed": args.seed, "cases": args.cases, "digest": digest}


def snapshot_record(source: Path) -> dict[str, object]:
    data = read_source(source)
    return {"schema": 1, "source_sha256": hashlib.sha256(data).hexdigest(), **run_check(source)}


def command_snapshot(args: argparse.Namespace) -> dict[str, object]:
    source = Path(args.source).resolve()
    output = Path(args.output).resolve()
    record = snapshot_record(source)
    encoded = (json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n").encode()
    if args.accept:
        output.parent.mkdir(parents=True, exist_ok=True)
        temp = output.with_name(f".{output.name}.tmp")
        temp.write_bytes(encoded)
        os.replace(temp, output)
    elif not output.is_file() or output.read_bytes() != encoded:
        raise ToolError("SNAPSHOT_DRIFT")
    return {"schema": 1, "command": "snapshot", "accepted": bool(args.accept), "fixture_sha256": hashlib.sha256(encoded).hexdigest()}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(prog="rf27-test")
    sub = result.add_subparsers(dest="command", required=True)
    test = sub.add_parser("test"); test.add_argument("root"); test.add_argument("--filter", default="*.no"); test.set_defaults(run=command_test)
    conf = sub.add_parser("conformance"); conf.add_argument("manifest"); conf.set_defaults(run=command_conformance)
    fuzz = sub.add_parser("fuzz"); fuzz.add_argument("source"); fuzz.add_argument("--cases", type=int, default=64); fuzz.add_argument("--seed", type=int, default=272410); fuzz.set_defaults(run=command_fuzz)
    snap = sub.add_parser("snapshot"); snap.add_argument("source"); snap.add_argument("--output", required=True); snap.add_argument("--accept", action="store_true"); snap.set_defaults(run=command_snapshot)
    return result


def main() -> int:
    try:
        args = parser().parse_args()
        print(json.dumps(args.run(args), sort_keys=True, separators=(",", ":")))
        return 0
    except (ToolError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"RF27_TEST_ERROR:{exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
