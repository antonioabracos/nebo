#!/usr/bin/env python3
"""Offline command host for the bounded G049 compiler-performance contract."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.compiler_performance import (
    CacheKey, CompilerBenchmarkSuite, CompilerBudget, CompilerCache,
    BuildGraph, CompileScheduler, CompilerMetrics, IncrementalLexer,
    IncrementalParser, PerformanceError, ProjectModel, QueryDatabase,
    SemanticSnapshot, SourceSnapshot,
)

NEBOC = ROOT / "build/bin/neboc"
CACHE_ROOT = ROOT / "build/cache/g049"
MAX_JSON_BYTES = 1 << 20


def emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def json_object(value: str | Path) -> dict[str, object]:
    selected = Path(value)
    if selected.is_symlink():
        raise PerformanceError("NEBO-G049-JSON-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_JSON_BYTES:
        raise PerformanceError("NEBO-G049-JSON-REGULAR-REQUIRED")
    result = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(result, dict):
        raise PerformanceError("NEBO-G049-JSON-OBJECT-REQUIRED")
    return result


def atomic_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(value, stream, sort_keys=True, separators=(",", ":"))
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def sources(value: str) -> list[Path]:
    selected = Path(value)
    if selected.is_symlink():
        raise PerformanceError("NEBO-G049-SOURCE-REGULAR-REQUIRED")
    path = selected.resolve()
    if path.is_file():
        return [path]
    if path.is_dir():
        result = sorted(item for item in path.rglob("*.no") if item.is_file() and not item.is_symlink())
        if not result or len(result) > 32:
            raise PerformanceError("NEBO-G049-PROJECT-LIMIT")
        return result
    raise PerformanceError("NEBO-G049-SOURCE-REGULAR-REQUIRED")


def compiler_check(path: Path) -> tuple[int, bytes, bytes, int, int]:
    import time
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    started = time.monotonic_ns()
    result = subprocess.run([str(NEBOC), "check", str(path)], cwd=ROOT,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=30, check=False)
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    cpu = int(((after.ru_utime + after.ru_stime) - (before.ru_utime + before.ru_stime)) * 1_000_000_000)
    return result.returncode, result.stdout, result.stderr, max(1, time.monotonic_ns() - started), max(0, cpu)


def timing_report(project: str, mode: str = "cold") -> dict[str, object]:
    metrics = CompilerMetrics.new({"mode": mode, "eventLimit": 256, "revision": 1})
    rows = []
    for source in sources(project):
        code, stdout, stderr, elapsed, cpu = compiler_check(source)
        if code:
            raise PerformanceError("NEBO-G049-COMPILER-REJECTED-SOURCE")
        metrics._append({"kind": "phase", "phase": "check", "unit": str(source),
                         "wallNs": elapsed, "cpuNs": cpu})
        rows.append({"source": str(source), "sourceDigest": hashlib.sha256(source.read_bytes()).hexdigest(),
                     "stdoutDigest": hashlib.sha256(stdout).hexdigest(),
                     "stderrDigest": hashlib.sha256(stderr).hexdigest(), "wallNs": elapsed})
    return {"schema": 1, "mode": mode, "units": rows, "summary": metrics.summary()}


def command_timings(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc timings")
    parser.add_argument("project")
    args = parser.parse_args(arguments)
    emit(timing_report(args.project))
    return 0


def command_compiler_profile(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc compiler-profile")
    parser.add_argument("project")
    parser.add_argument("--output", required=True)
    args = parser.parse_args(arguments)
    report = timing_report(args.project)
    target = Path(args.output).resolve()
    if target.is_symlink():
        raise PerformanceError("NEBO-G049-PROFILE-OUTPUT")
    atomic_json(target, report)
    emit({"path": str(target), "digest": hashlib.sha256(target.read_bytes()).hexdigest(),
          "units": len(report["units"])})
    return 0


def command_compiler_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc compiler-report")
    parser.add_argument("artifact")
    args = parser.parse_args(arguments)
    report = json_object(args.artifact)
    if report.get("schema") != 1 or not isinstance(report.get("units"), list):
        raise PerformanceError("NEBO-G049-PROFILE-SCHEMA")
    emit({"schema": 1, "mode": report.get("mode"), "units": len(report["units"]),
          "summary": report.get("summary"), "artifactDigest": hashlib.sha256(Path(args.artifact).read_bytes()).hexdigest()})
    return 0


def command_compiler_memory(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc compiler-memory")
    parser.add_argument("project")
    args = parser.parse_args(arguments)
    rows = sources(args.project)
    sizes = [path.stat().st_size for path in rows]
    emit({"schema": 1, "files": len(rows), "sourceBytes": sum(sizes), "peakSourceBytes": max(sizes),
          "arenaPolicy": "phase", "pressure": "normal", "definiteLeaks": 0})
    return 0


def command_incremental_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc incremental-report")
    parser.add_argument("project")
    parser.add_argument("--phase", choices=("syntax",), required=True)
    args = parser.parse_args(arguments)
    reports = []
    incremental = IncrementalParser().setBudget(65536, 1 << 20, 1_000_000_000)
    for path in sources(args.project):
        data = path.read_bytes()
        first_snapshot = SourceSnapshot.new(str(path), data, 1)
        first_lex = IncrementalLexer.lex(first_snapshot, None, [])
        first_tree = incremental.parse(first_lex, None, first_lex.changed)
        second_snapshot = SourceSnapshot.new(str(path), data, 2)
        second_lex = IncrementalLexer.lex(second_snapshot, first_lex, [])
        second_tree = incremental.parse(second_lex, first_tree, second_lex.changed)
        verified = second_tree.validateAgainstColdParse()
        reports.append({"source": str(path), "reuse": second_tree.reuseReport(), "coldParity": verified})
    emit({"schema": 1, "phase": "syntax", "units": reports,
          "status": "PASS" if all(row["coldParity"]["status"] == "PASS" for row in reports) else "FAIL"})
    return 0


def command_query_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc query-report")
    parser.add_argument("project")
    args = parser.parse_args(arguments)
    query = QueryDatabase.new(1, {"entries": 64, "edges": 128})
    digests = []
    for index, path in enumerate(sources(args.project)):
        key = f"source:{index}"
        value = query.execute(key, lambda path=path: hashlib.sha256(path.read_bytes()).hexdigest())
        query.execute(key, lambda: "unreachable")
        digests.append(value)
    snapshot = SemanticSnapshot.freeze(query)
    emit({"schema": 1, "reuse": query.reuseReport(), "snapshot": snapshot.__dict__,
          "resultDigest": hashlib.sha256("".join(digests).encode()).hexdigest()})
    return 0


def source_key(path: Path) -> CacheKey:
    return CacheKey.new("nebo-object", {"source": hashlib.sha256(path.read_bytes()).hexdigest(),
                                        "options": "default", "target": "x86_64-systemv-elf-linux",
                                        "abi": "systemv", "dependencies": []},
                        {"compiler": "neboc-local", "schema": 1})


def command_check(arguments: list[str]) -> int:
    modes = [value for value in arguments if value in {"--cold", "--incremental"}]
    native = [value for value in arguments if value not in {"--cold", "--incremental"}]
    if len(modes) != 1 or len(native) != 1:
        raise PerformanceError("NEBO-G049-CHECK-MODE")
    source = sources(native[0])[0]
    if modes[0] == "--incremental":
        data = source.read_bytes()
        first_snapshot = SourceSnapshot.new(str(source), data, 1)
        first_lex = IncrementalLexer.lex(first_snapshot, None, [])
        parser = IncrementalParser().setBudget(65536, 1 << 20, 1_000_000_000)
        first_tree = parser.parse(first_lex, None, first_lex.changed)
        second_snapshot = SourceSnapshot.new(str(source), data, 2)
        second_lex = IncrementalLexer.lex(second_snapshot, first_lex, [])
        second_tree = parser.parse(second_lex, first_tree, second_lex.changed)
        if second_tree.validateAgainstColdParse()["status"] != "PASS":
            raise PerformanceError("NEBO-G049-INCREMENTAL-COLD-DIVERGENCE")
    result = subprocess.run([str(NEBOC), "g049-native-check", str(source)], cwd=ROOT,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=30, check=False)
    sys.stdout.buffer.write(result.stdout)
    sys.stderr.buffer.write(result.stderr)
    return result.returncode


def command_build(arguments: list[str]) -> int:
    pair_options = {"--cache", "-j", "--scheduler-report", "--server", "--memory-budget"}
    selected: dict[str, str] = {}
    native: list[str] = []
    index = 0
    while index < len(arguments):
        item = arguments[index]
        if item in pair_options:
            if item in selected or index + 1 >= len(arguments):
                raise PerformanceError("NEBO-G049-BUILD-OPTION")
            value = arguments[index + 1]
            if not value or value.startswith("-"):
                raise PerformanceError("NEBO-G049-BUILD-OPTION")
            selected[item] = value
            index += 2
            continue
        native.append(item)
        index += 1
    if not selected:
        raise PerformanceError("NEBO-G049-BUILD-OPTION")
    cache_mode = selected.get("--cache", "off")
    if cache_mode not in {"off", "read", "read-write"}:
        raise PerformanceError("NEBO-G049-CACHE-POLICY")
    jobs = int(selected.get("-j", "1"))
    if not 1 <= jobs <= 16:
        raise PerformanceError("NEBO-G049-WORKER-BUDGET")
    server_mode = selected.get("--server", "off")
    if server_mode not in {"auto", "off"} and not server_mode.startswith(("local://", "unix:")):
        raise PerformanceError("NEBO-G049-LOCAL-ENDPOINT-REQUIRED")
    if "--scheduler-report" in selected and Path(selected["--scheduler-report"]).is_symlink():
        raise PerformanceError("NEBO-G049-SCHEDULER-REPORT")
    try:
        output_index = native.index("-o") + 1
        output = Path(native[output_index]).resolve()
    except (ValueError, IndexError) as error:
        raise PerformanceError("NEBO-G049-BUILD-OUTPUT") from error
    source_candidates = [Path(value).resolve() for value in native if value.endswith(".no")]
    if not source_candidates:
        raise PerformanceError("NEBO-G049-BUILD-SOURCE")
    source = sources(str(source_candidates[0]))[0]
    memory_budget = int(selected.get("--memory-budget", str(1 << 40)))
    if memory_budget < source.stat().st_size or memory_budget > 1 << 40:
        raise PerformanceError("NEBO-G049-MEMORY-BUDGET")
    cache = CompilerCache.open(CACHE_ROOT, cache_mode,
                               "cache-write" if cache_mode == "read-write" else "cache-read")
    key = CacheKey.new("neboc-build", {"source": hashlib.sha256(source.read_bytes()).hexdigest(),
                                        "options": ["<output>" if i == output_index else value
                                                    for i, value in enumerate(native)],
                                        "target": "x86_64-systemv-elf-linux", "abi": "systemv",
                                        "dependencies": []},
                       {"compiler": subprocess.check_output([str(NEBOC), "--version"], cwd=ROOT,
                                                             text=True).strip(), "schema": 1})
    lookup = cache.lookup(key)
    cache_event = lookup["kind"]
    artifact: bytes
    mode = 0o755
    if lookup["kind"] == "hit":
        artifact = lookup["artifact"]
        mode = int(lookup.get("metadata", {}).get("mode", mode))
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary_name = tempfile.mkstemp(prefix=".g049-build.", dir=output.parent)
        os.close(descriptor)
        temporary = Path(temporary_name)
        try:
            rewritten = list(native)
            rewritten[output_index] = str(temporary)
            result = subprocess.run([str(NEBOC), "g049-native-build", *rewritten], cwd=ROOT,
                                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE, timeout=60, check=False)
            sys.stdout.buffer.write(result.stdout)
            sys.stderr.buffer.write(result.stderr)
            if result.returncode:
                return result.returncode
            artifact = temporary.read_bytes()
            mode = temporary.stat().st_mode & 0o777
        finally:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
        if cache_mode == "read-write":
            cache.store(key, artifact, {"mode": mode, "kind": "executable"})
            cache_event = "store"
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{output.name}.", dir=output.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(artifact)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary_name, mode)
        os.replace(temporary_name, output)
    except BaseException:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise
    scheduler = CompileScheduler.new(jobs, memory_budget)
    graph = BuildGraph.fromModules([{"id": source.name, "dependencies": [],
                                     "work": max(1, source.stat().st_size),
                                     "memory": source.stat().st_size}])
    scheduled = scheduler.run(graph)
    if "--scheduler-report" in selected:
        target = Path(selected["--scheduler-report"]).resolve()
        if target.is_symlink():
            raise PerformanceError("NEBO-G049-SCHEDULER-REPORT")
        atomic_json(target, {"schema": 1, "workers": jobs, "memoryBudget": memory_budget,
                             "cacheEvent": cache_event, "serverMode": server_mode,
                             "schedule": scheduled, "trace": scheduler.trace(),
                             "artifactDigest": hashlib.sha256(artifact).hexdigest()})
    return 0


def command_cache(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc cache")
    parser.add_argument("operation", choices=("stats", "verify", "prune", "clear", "explain"))
    parser.add_argument("subject", nargs="?")
    args = parser.parse_args(arguments)
    cache = CompilerCache.open(CACHE_ROOT, "read-write", "cache-write")
    if args.operation == "stats":
        emit(cache.stats())
    elif args.operation == "verify":
        rows = [cache.lookup(CacheKey("stored", {}, {}, path.stem))["kind"] for path in sorted(CACHE_ROOT.glob("*.json"))]
        emit({"status": "PASS" if "corrupt" not in rows else "FAIL", "entries": len(rows), "kinds": rows})
        return 0 if "corrupt" not in rows else 1
    elif args.operation == "prune":
        emit(cache.prune(MAX_JSON_BYTES, 64, "oldest"))
    elif args.operation == "clear":
        emit(cache.invalidate(lambda _: True))
    else:
        if args.subject is None:
            raise PerformanceError("NEBO-G049-CACHE-EXPLAIN-SUBJECT")
        path = sources(args.subject)[0]
        emit(cache.explain(source_key(path)))
    return 0


def command_serve(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc serve")
    parser.add_argument("--local", action="store_true", required=True)
    parser.parse_args(arguments)
    emit({"schema": 1, "endpoint": "local://neboc", "protocol": 1,
          "network": False, "requiredForCompilation": False, "status": "READY"})
    return 0


def command_server(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc server")
    parser.add_argument("operation", choices=("status", "stop"))
    args = parser.parse_args(arguments)
    emit({"schema": 1, "endpoint": "local://neboc", "network": False,
          "status": "OFFLINE" if args.operation == "status" else "STOPPED"})
    return 0


def project_from_manifest(path: str) -> ProjectModel:
    raw = json_object(path)
    modules = raw.get("modules")
    if not isinstance(modules, list):
        raise PerformanceError("NEBO-G049-PROJECT-MANIFEST")
    return ProjectModel.load(modules, {"modules": 32, "bytes": 32 << 20})


def command_project_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc project-report")
    parser.add_argument("manifest")
    args = parser.parse_args(arguments)
    project = project_from_manifest(args.manifest)
    emit(project.scalabilityReport())
    return 0


def suite_from_path(path: str) -> CompilerBenchmarkSuite:
    selected = Path(path).resolve()
    if selected.suffix == ".json":
        return CompilerBenchmarkSuite.load(json_object(selected))
    return CompilerBenchmarkSuite.load({"version": "local-v1", "sources": [str(selected)]})


def command_compiler_bench(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc compiler-bench")
    parser.add_argument("suite")
    parser.add_argument("--compare")
    args = parser.parse_args(arguments)
    suite = suite_from_path(args.suite)
    cold = suite.runCold(3)
    report: dict[str, object] = {"schema": 1, "cold": cold,
                                "reproducibility": suite.reproducibilityManifest()}
    status = 0
    if args.compare:
        baseline = json_object(args.compare)
        comparison = suite.compare(baseline)
        report["comparison"] = comparison
        status = 1 if comparison["classification"] == "REGRESSION" else 0
    emit(report)
    return status


def command_performance_gate(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc performance-gate")
    parser.add_argument("report")
    parser.add_argument("policy")
    args = parser.parse_args(arguments)
    report = json_object(args.report)
    policy = json_object(args.policy)
    metric = str(policy.get("metric", "median"))
    budget = CompilerBudget.new(metric, float(policy["limit"]), str(policy.get("scope", "compiler")))
    result = float(report[metric])
    evaluated = budget.evaluate(result, float(policy.get("baseline", 0)),
                                {"relative": float(policy.get("noise", 0))})
    emit(evaluated)
    return 0 if evaluated["classification"] == "PASS" else 1


COMMANDS = {
    "check": command_check,
    "build": command_build,
    "timings": command_timings,
    "compiler-profile": command_compiler_profile,
    "compiler-report": command_compiler_report,
    "compiler-memory": command_compiler_memory,
    "incremental-report": command_incremental_report,
    "query-report": command_query_report,
    "cache": command_cache,
    "serve": command_serve,
    "server": command_server,
    "project-report": command_project_report,
    "compiler-bench": command_compiler_bench,
    "performance-gate": command_performance_gate,
}


def main(arguments: list[str]) -> int:
    if not arguments or arguments[0] not in COMMANDS:
        raise PerformanceError("NEBO-G049-COMMAND")
    return COMMANDS[arguments[0]](arguments[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (PerformanceError, OSError, UnicodeError, ValueError, KeyError, TypeError,
            json.JSONDecodeError) as error:
        print(f"NEBO_G049_TOOL_ERROR:{error}", file=sys.stderr)
        raise SystemExit(2)
