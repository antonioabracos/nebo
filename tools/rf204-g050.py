#!/usr/bin/env python3
"""Repository-local offline CLI host for the bounded G050 contract."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
import time


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.whole_program import (  # noqa: E402
    BinarySizeBudget, BuildProfile, DataFootprint, LinkLayout,
    OptimizationError, RuntimeProfile, RuntimeRegistry, SizeReport,
    StartupGraph, WholeProgramGraph, atomic_json,
)
from compiler.sdk.prelude import without_std_imports

NEBOC = ROOT / "build/bin/neboc"
STRIP = "/usr/bin/strip"
OBJCOPY = "/usr/bin/objcopy"
MAX_SOURCE_BYTES = 1 << 20


def emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def regular_source(value: str | Path) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise OptimizationError("NEBO-G050-SOURCE-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_SOURCE_BYTES or path.suffix != ".no":
        raise OptimizationError("NEBO-G050-SOURCE-REGULAR-REQUIRED")
    return path


def json_object(value: str | Path) -> dict[str, object]:
    selected = Path(value)
    if selected.is_symlink():
        raise OptimizationError("NEBO-G050-POLICY-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_SOURCE_BYTES:
        raise OptimizationError("NEBO-G050-POLICY-REGULAR-REQUIRED")
    result = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(result, dict):
        raise OptimizationError("NEBO-G050-POLICY-OBJECT-REQUIRED")
    return result


def graph_from_source(value: str | Path, policy: str = "closed") -> WholeProgramGraph:
    path = regular_source(value)
    text = path.read_text(encoding="utf-8")
    functions = re.findall(r"^\s*(?:\([^\n]+\))?\s*([A-Za-z_][A-Za-z0-9_]*)\s*\([^\n]*\)\s*\{", text, re.M)
    if "start" not in functions:
        functions.append("start")
    symbols = []
    for name in sorted(set(functions)):
        calls = [target for target in functions if target != name and re.search(rf"\b{re.escape(target)}\s*\(", text)]
        symbols.append({"name": name, "kind": "function", "calls": sorted(set(calls)),
                        "root": name == "start", "reason": "entry"})
    symbols.append({"name": "runtime.core", "kind": "runtime", "calls": []})
    for row in symbols:
        if row["name"] == "start":
            row["runtime"] = ["runtime.core"]
    return WholeProgramGraph.build([{"id": path.name, "symbols": symbols}], "x86_64-linux", policy)


def command_reachability(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc reachability-report")
    parser.add_argument("input")
    parser.add_argument("--policy", choices=["closed", "open", "unsupported"], default="closed")
    args = parser.parse_args(arguments)
    selected = Path(args.input)
    if selected.suffix == ".no":
        graph = graph_from_source(selected, args.policy)
        emit({"schema": 1, "inputKind": "source", "target": graph.target,
              "roots": sorted(graph.roots),
              "retained": sorted(set(graph.nodes) - set(graph.unreachableSymbols())),
              "pruned": graph.unreachableSymbols(), "world": graph.validateClosedWorld(),
              "digest": graph.digest()})
    else:
        report = SizeReport.fromArtifact(selected)
        if args.policy == "unsupported":
            raise OptimizationError("NEBO-G050-OPEN-WORLD-UNSUPPORTED")
        retained = [row["name"] for row in report.bySymbol()]
        if not retained:
            retained = [row["name"] for row in report.bySection() if row["memoryBytes"]]
        world = {"status": "complete" if args.policy == "closed" else "conservative-unknown",
                 "unknownEdges": 0 if args.policy == "closed" else 1}
        emit({"schema": 1, "inputKind": "artifact", "target": "x86_64-linux",
              "roots": ["ELF-entrypoint"], "retained": retained, "pruned": [],
              "world": world, "digest": hashlib.sha256(report.path.read_bytes()).hexdigest(),
              "stripped": report.stripped})
    return 0


def source_capabilities(path: Path) -> list[str]:
    text = re.sub(r"//[^\n]*", "", path.read_text(encoding="utf-8"))
    result = []
    for token, capability in (("console", "console"), ("scan", "text-input"),
                              ("Window", "window"), ("Network", "network"), ("Tensor", "tensor")):
        if token in text:
            result.append(capability)
    return sorted(set(result))


def runtime_registry() -> RuntimeRegistry:
    registry = RuntimeRegistry()
    registry.component("core", 1, symbols=["_start"], capabilities=["core"], dependencies=[], bytes=4096, init="none")
    registry.component("diagnostics", 1, symbols=["nebo_runtime_trap"], capabilities=["diagnostics"], dependencies=["core"], bytes=2048)
    registry.component("console", 1, symbols=["nebo_runtime_console_publish_int"], capabilities=["console"], dependencies=["core", "diagnostics"], bytes=8192, init="lazy", cleanup="registered")
    registry.component("text-input", 1, symbols=["nebo_runtime_scan_stdin_text"], capabilities=["text-input"], dependencies=["core", "diagnostics"], bytes=6144, init="lazy", cleanup="registered")
    registry.component("window", 1, symbols=[], capabilities=["window"], dependencies=["core"], bytes=16384, init="lazy")
    registry.component("network", 1, symbols=[], capabilities=["network"], dependencies=["core"], bytes=16384, init="lazy")
    registry.component("tensor", 1, symbols=[], capabilities=["tensor"], dependencies=["core"], bytes=16384, init="lazy")
    return registry


def command_runtime_graph(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc runtime-graph")
    parser.add_argument("input")
    parser.add_argument("--runtime", choices=["minimal", "standard"], default="minimal")
    args = parser.parse_args(arguments)
    selected = Path(args.input)
    if selected.suffix == ".no":
        path = regular_source(selected)
        capabilities = source_capabilities(path)
        input_kind = "source"
    else:
        report = SizeReport.fromArtifact(selected)
        names = "\n".join(row["name"] for row in report.bySymbol()).lower()
        capabilities = [name for token, name in (("console", "console"), ("scan", "text-input"),
                        ("window", "window"), ("network", "network"), ("tensor", "tensor")) if token in names]
        input_kind = "artifact"
    registry = runtime_registry()
    profile = RuntimeProfile.minimal() if args.runtime == "minimal" else RuntimeProfile.standard()
    profile.require("core")
    resolved = registry.resolve(capabilities, "x86_64-linux", profile)
    profile.selected = resolved
    emit({"schema": 1, **profile.manifest(registry),
          "inputKind": input_kind, "explanations": [registry.explain(name) for name in resolved]})
    return 0


def command_data_footprint(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc data-footprint")
    parser.add_argument("artifact")
    args = parser.parse_args(arguments)
    report = DataFootprint.analyze(args.artifact)
    emit({"schema": 1, "artifact": str(report.path), "fileBytes": report.fileBytes,
          "sections": report.sections, "pageTouch": report.pageTouchReport(),
          "limits": report.limitReport()})
    return 0


def command_link_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc link-report")
    parser.add_argument("artifact")
    args = parser.parse_args(arguments)
    artifact = SizeReport.fromArtifact(args.artifact).path
    layout = LinkLayout.new("x86_64-linux", "release")
    layout.artifact = artifact
    emit({"schema": 1, "security": layout.securityReport(artifact), "layout": layout.mapFile(artifact),
          "buildId": layout.buildId("content")})
    return 0


def select_profile(name: str) -> BuildProfile:
    if name == "debug": return BuildProfile.debug()
    if name == "release": return BuildProfile.release()
    if name == "min-size": return BuildProfile.minSize()
    raise OptimizationError("NEBO-G050-PROFILE-UNKNOWN")


def command_profile_explain(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc profile-explain")
    parser.add_argument("profile", choices=["debug", "release", "min-size"])
    args = parser.parse_args(arguments)
    emit(select_profile(args.profile).manifest())
    return 0


def command_startup(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc startup-report")
    parser.add_argument("artifact")
    parser.add_argument("--samples", type=int, default=5)
    args = parser.parse_args(arguments)
    report = SizeReport.fromArtifact(args.artifact)
    graph = StartupGraph.build({"components": [
        {"id": "core", "dependencies": [], "eager": True, "bytes": min(report.fileBytes, 4096)},
        {"id": "diagnostics", "dependencies": ["core"], "eager": False, "guardProved": True, "bytes": 2048},
    ]})
    if not 2 <= args.samples <= 100:
        raise OptimizationError("NEBO-G050-STARTUP-SAMPLES")
    durations = []
    for _ in range(args.samples):
        started = time.perf_counter_ns()
        result = subprocess.run([str(report.path)], stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=10, check=False, env={"LC_ALL": "C", "LANG": "C", "TZ": "UTC"})
        durations.append(time.perf_counter_ns() - started)
        if result.returncode:
            raise OptimizationError("NEBO-G050-STARTUP-EXECUTION")
    model = graph.measure(str(report.path), args.samples)
    model.update({"medianNs": int(statistics.median(durations)), "minNs": min(durations),
                  "maxNs": max(durations), "observedExit": 0})
    emit({"schema": 1, "eager": graph.eagerComponents(), "lazy": graph.lazyComponents(),
          "measurement": model})
    return 0


def report_value(path: str) -> SizeReport:
    return SizeReport.fromArtifact(path)


def command_size_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc size-report")
    parser.add_argument("artifact")
    parser.add_argument("--top", type=int, default=10)
    args = parser.parse_args(arguments)
    report = report_value(args.artifact)
    emit({"schema": 1, "artifact": str(report.path), "fileBytes": report.fileBytes,
          "stripped": report.stripped, "sections": report.bySection(),
          "components": report.byComponent(), "topSymbols": report.top(args.top, "symbol")})
    return 0


def command_why_linked(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc why-linked")
    parser.add_argument("artifact")
    parser.add_argument("query")
    args = parser.parse_args(arguments)
    emit({"schema": 1, **report_value(args.artifact).whyLinked(args.query)})
    return 0


def command_binary_diff(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc binary-diff")
    parser.add_argument("before")
    parser.add_argument("after")
    args = parser.parse_args(arguments)
    emit({"schema": 1, **report_value(args.after).compare(report_value(args.before))})
    return 0


def command_size_gate(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc size-gate")
    parser.add_argument("artifact")
    parser.add_argument("policy")
    args = parser.parse_args(arguments)
    policy = json_object(args.policy)
    budget = BinarySizeBudget.new(str(policy.get("scope", "file")), int(policy["maxBytes"]), int(policy.get("deltaBytes", 0)))
    result = budget.evaluate(report_value(args.artifact))
    emit({"schema": 1, **result})
    return 0 if result["status"] == "pass" else 2


def atomic_copy(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    os.close(descriptor)
    try:
        shutil.copyfile(source, temporary)
        os.chmod(temporary, source.stat().st_mode & 0o777)
        os.replace(temporary, target)
    except BaseException:
        try: os.unlink(temporary)
        except FileNotFoundError: pass
        raise


def command_build(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc build")
    parser.add_argument("source")
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("--gc-sections", choices=["auto", "on", "off"], default="auto")
    parser.add_argument("--runtime", choices=["minimal", "standard", "custom"], default="standard")
    parser.add_argument("--profile", choices=["debug", "release", "min-size"], default="debug")
    parser.add_argument("--strip", action="store_true")
    parser.add_argument("--split-debug")
    args = parser.parse_args(arguments)
    source = regular_source(args.source)
    # Profiling must retain the same public edition/import admission boundary.
    admission = subprocess.run([str(NEBOC), "check", str(source)], cwd=ROOT,
                               stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, timeout=30, check=False)
    if admission.returncode:
        sys.stdout.buffer.write(admission.stdout)
        sys.stderr.buffer.write(admission.stderr)
        return admission.returncode
    output_selected = Path(args.output)
    if output_selected.is_symlink():
        raise OptimizationError("NEBO-G050-BUILD-POLICY")
    output = output_selected.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=".g050-build.", dir=output.parent)
    os.close(descriptor)
    os.unlink(temporary_name)
    temporary = Path(temporary_name)
    debug: Path | None = None
    debug_temp: Path | None = None
    debug_stage: Path | None = None
    try:
        native_mode = "g050-native-build-retain" if args.gc_sections == "off" else "g050-native-build"
        # Reuse the canonical visibility owner's projection after public
        # admission; stdlib imports must not hide adjacent native statements.
        with tempfile.TemporaryDirectory(prefix=".profile-source.", dir=output.parent) as source_root:
            projected = Path(source_root) / source.name
            projected.write_text(without_std_imports(source.read_text(encoding="utf-8")))
            result = subprocess.run([str(NEBOC), native_mode, str(projected), "-o", str(temporary)],
                                    cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE, timeout=30, check=False)
        if result.returncode:
            sys.stderr.buffer.write(result.stderr)
            return result.returncode
        before = temporary.stat().st_size
        strip_requested = args.strip or args.profile == "min-size"
        debug_result = None
        if args.split_debug:
            debug_selected = Path(args.split_debug)
            if debug_selected.is_symlink(): raise OptimizationError("NEBO-G050-DEBUG-OUTPUT")
            debug = debug_selected.resolve()
            if debug == output or (debug.exists() and not debug.is_file()):
                raise OptimizationError("NEBO-G050-DEBUG-OUTPUT")
            debug.parent.mkdir(parents=True, exist_ok=True)
            debug_stage = Path(tempfile.mkdtemp(prefix=".g050-debug.", dir=debug.parent))
            debug_temp = debug_stage / debug.name
            tool = subprocess.run([OBJCOPY, "--only-keep-debug", str(temporary), str(debug_temp)],
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  timeout=20, check=False)
            if tool.returncode: raise OptimizationError("NEBO-G050-SPLIT-DEBUG-FAILED")
        if strip_requested:
            tool = subprocess.run([STRIP, "--strip-all", str(temporary)], stdin=subprocess.DEVNULL,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20, check=False)
            if tool.returncode: raise OptimizationError("NEBO-G050-STRIP-FAILED")
        if debug_temp is not None:
            tool = subprocess.run([OBJCOPY, f"--add-gnu-debuglink={debug_temp}", str(temporary)],
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  timeout=20, check=False)
            if tool.returncode: raise OptimizationError("NEBO-G050-SPLIT-DEBUG-FAILED")
        atomic_copy(temporary, output)
        if debug_temp is not None and debug is not None:
            os.replace(debug_temp, debug)
            debug_result = {"path": str(debug), "digest": hashlib.sha256(debug.read_bytes()).hexdigest(),
                            "buildIdentity": hashlib.sha256(output.read_bytes()).hexdigest(),
                            "debugLink": debug.name}
        layout = LinkLayout.new("x86_64-linux", args.profile)
        layout.artifact = output
        capabilities = source_capabilities(source)
        emit({"schema": 1, "artifact": str(output), "beforeBytes": before,
              "afterBytes": output.stat().st_size, "profile": select_profile(args.profile).manifest(),
              "runtime": args.runtime, "runtimeCapabilities": capabilities,
              "gcSections": args.gc_sections,
              "gcSectionsApplied": args.gc_sections != "off",
              "gcSectionsReason": "disabled-reference" if args.gc_sections == "off" else "native-relocation-component-closure",
              "strip": strip_requested,
              "splitDebug": debug_result, "security": layout.securityReport(),
              "sourceDigest": hashlib.sha256(source.read_bytes()).hexdigest()})
        return 0
    finally:
        try: temporary.unlink()
        except FileNotFoundError: pass
        if debug_stage is not None:
            shutil.rmtree(debug_stage, ignore_errors=True)


COMMANDS = {
    "reachability-report": command_reachability,
    "runtime-graph": command_runtime_graph,
    "data-footprint": command_data_footprint,
    "link-report": command_link_report,
    "profile-explain": command_profile_explain,
    "startup-report": command_startup,
    "size-report": command_size_report,
    "why-linked": command_why_linked,
    "binary-diff": command_binary_diff,
    "size-gate": command_size_gate,
    "build": command_build,
}


def main(argv: list[str]) -> int:
    if not argv or argv[0] not in COMMANDS:
        raise OptimizationError("NEBO-G050-COMMAND-UNKNOWN")
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (OptimizationError, KeyError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(2)
