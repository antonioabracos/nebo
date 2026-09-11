#!/usr/bin/python3
"""Bounded G153 CLI renderer over the native module semantic authority."""

from __future__ import annotations

import json
import os
import stat
import subprocess
import sys
from pathlib import Path

MAX_SOURCE_BYTES = 4096
TIMEOUT_SECONDS = 10


class InitError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def usage() -> int:
    print(
        "neboc: usage: module-init-report <entry.no> --unit <file.no> --unit <file.no>; "
        "check <entry.no> --unit <file.no> --unit <file.no> --deny-effectful-init",
        file=sys.stderr,
    )
    return 2


def parse_paths(arguments: list[str], command: str) -> tuple[Path, list[Path]]:
    deny = "--deny-effectful-init"
    if command == "check":
        if arguments.count(deny) != 1:
            raise InitError("USAGE", "the deny gate must occur exactly once")
        arguments = [value for value in arguments if value != deny]
    if len(arguments) != 5 or arguments[1] != "--unit" or arguments[3] != "--unit":
        raise InitError("USAGE", "an entry and exactly two --unit inputs are required")
    paths = [Path(arguments[0]), Path(arguments[2]), Path(arguments[4])]
    identities: set[tuple[int, int]] = set()
    for path in paths:
        try:
            info = path.lstat()
        except OSError as exc:
            raise InitError("NEBO-RF166-G153-IO", f"cannot inspect {path}: {exc.strerror}") from exc
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
            raise InitError("NEBO-RF166-G153-IO", f"source must be a regular non-symlink file: {path}")
        if info.st_size > MAX_SOURCE_BYTES:
            raise InitError("NEBO-RF166-G153-005", f"source exceeds {MAX_SOURCE_BYTES} bytes: {path}")
        identity = (info.st_dev, info.st_ino)
        if identity in identities:
            raise InitError("NEBO-RF166-G153-006", "module inputs must be distinct")
        identities.add(identity)
    return paths[0], paths[1:]


def compiler_path() -> Path:
    root = Path(__file__).resolve().parents[1]
    compiler = root / "build" / "bin" / "neboc"
    if not compiler.is_file():
        raise InitError("NEBO-RF166-G153-IO", f"native compiler is unavailable: {compiler}")
    return compiler


def run_native(compiler: Path, arguments: list[str]) -> subprocess.CompletedProcess[str]:
    environment = dict(os.environ)
    environment["LC_ALL"] = "C"
    return subprocess.run(
        [str(compiler), *arguments],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        timeout=TIMEOUT_SECONDS,
        check=False,
        env=environment,
    )


def graph_arguments(entry: Path, units: list[Path]) -> list[str]:
    return [str(entry), "--unit", str(units[0]), "--unit", str(units[1])]


def parse_info(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key in result:
            raise InitError("NEBO-RF166-G153-006", f"duplicate native fact: {key}")
        result[key] = value
    required = {
        "module.id",
        "module.logical",
        "module.rank",
        "module.sourceRevision",
        "graph.snapshot",
        "graph.units",
        "module.imports",
        "module.startRefs",
        "module.visibility",
        "module.exportValue",
    }
    if required - result.keys():
        raise InitError("NEBO-RF166-G153-006", "native module-info omitted required initialization facts")
    return result


def load_native_plan(
    entry: Path, units: list[Path], *, translate_hidden: bool = False
) -> dict[str, object]:
    compiler = compiler_path()
    common = graph_arguments(entry, units)
    checked = run_native(compiler, ["module-check", *common])
    if checked.returncode != 0:
        if translate_hidden and "TYPE-003" in checked.stderr:
            raise InitError(
                "NEBO-RF166-G153-001",
                "hidden effectful module initialization is forbidden; "
                f"primary={units[0]}:1:1; related={entry}:1:1; "
                "note=imports grant no effects or capabilities; call explicitly from start()",
            )
        if (
            "NEBO-RF166-G150-005" in checked.stderr
            or "IMPORT-CYCLE" in checked.stderr
            or "SECURITY-006" in checked.stderr
        ):
            raise InitError(
                "NEBO-RF166-G153-002",
                "initialization dependency cycle rejected; "
                f"primary={entry}:1:1; related={units[0]}:1:1,{units[1]}:1:1; "
                "note=native module graph has no dependency-first startup order",
            )
        sys.stderr.write(checked.stderr)
        raise InitError("NATIVE", "native module semantic validation failed")
    graph_result = run_native(compiler, ["module-graph", *common, "--format", "json"])
    if graph_result.returncode != 0:
        sys.stderr.write(graph_result.stderr)
        raise InitError("NATIVE", "native module graph construction failed")
    try:
        graph = json.loads(graph_result.stdout)
    except (ValueError, TypeError) as exc:
        raise InitError("NEBO-RF166-G153-006", "native module graph was not valid JSON") from exc
    paths = [entry, *units]
    infos: list[dict[str, str]] = []
    for index, root in enumerate(paths):
        others = [path for position, path in enumerate(paths) if position != index]
        result = run_native(compiler, ["module-info", *graph_arguments(root, others)])
        if result.returncode != 0:
            sys.stderr.write(result.stderr)
            raise InitError("NATIVE", "native module-info construction failed")
        infos.append(parse_info(result.stdout))
    snapshots = {item["graph.snapshot"] for item in infos}
    if snapshots != {str(graph.get("snapshot"))}:
        raise InitError("NEBO-RF166-G153-006", "native graph snapshot changed while building the plan")
    by_id = {int(item["module.id"]): item["module.logical"] for item in infos}
    try:
        order = [by_id[int(identity)] for identity in graph["order"]]
    except (KeyError, TypeError, ValueError) as exc:
        raise InitError("NEBO-RF166-G153-006", "native order contains an unknown ModuleId") from exc
    hidden = [
        {"module": item["module.logical"], "path": str(path), "reason": "hidden-effectful-init"}
        for path, item in zip(units, infos[1:])
        if int(item["module.startRefs"]) != 0
    ]
    return {
        "compiler": compiler,
        "graph": graph,
        "infos": infos,
        "order": order,
        "hidden": hidden,
    }


def report(entry: Path, units: list[Path]) -> int:
    plan = load_native_plan(entry, units)
    infos = plan["infos"]
    assert isinstance(infos, list)
    hidden = plan["hidden"]
    assert isinstance(hidden, list)
    payload = {
        "command": "module-init-report",
        "schema": 1,
        "target": infos[0]["module.logical"],
        "snapshot": int(infos[0]["graph.snapshot"]),
        "order": plan["order"],
        "pureConstants": sum(int(item["module.visibility"]) != 0 for item in infos),
        "runtimeInitializers": 0,
        "explicitStartRefs": int(infos[0]["module.startRefs"]),
        "requiredEffects": ["runtime-start"] if hidden else [],
        "requiredCapabilities": ["explicit-call"] if hidden else [],
        "rejected": hidden,
        "startupAuthority": "native-module-graph",
        "interfaceLoadExecutesUserCode": False,
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    return 0


def deny_effectful(entry: Path, units: list[Path]) -> int:
    plan = load_native_plan(entry, units, translate_hidden=True)
    hidden = plan["hidden"]
    assert isinstance(hidden, list)
    if hidden:
        first = hidden[0]
        print(
            "NEBO-RF166-G153-001: hidden effectful module initialization is forbidden; "
            f"primary={first['path']}:1:1; related={entry}:1:1; "
            "note=imports grant no effects or capabilities; call explicitly from start()",
            file=sys.stderr,
        )
        return 1
    return 0


def main(arguments: list[str]) -> int:
    try:
        if not arguments or arguments[0] not in {"module-init-report", "check"}:
            return usage()
        command = arguments[0]
        entry, units = parse_paths(arguments[1:], command)
        return report(entry, units) if command == "module-init-report" else deny_effectful(entry, units)
    except InitError as exc:
        if exc.code == "USAGE":
            return usage()
        if exc.code == "NATIVE":
            return 1
        print(f"{exc.code}: {exc.message}", file=sys.stderr)
        return 1
    except subprocess.TimeoutExpired:
        print("NEBO-RF166-G153-006: native module analysis exceeded the bounded timeout", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"NEBO-RF166-G153-IO: {exc}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
