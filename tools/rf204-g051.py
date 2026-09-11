#!/usr/bin/env python3
"""Repository-local, offline CLI host for G051 portability surfaces."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.version_identity import CLI
from compiler.sdk.portability import (  # noqa: E402
    ArchitectureBackend, BuildTriple, CrossCompilation, CrossRunner,
    CURRENT_TRIPLE, HostCompilerPackage, HostCompilerPlan, HostTriple,
    MAX_SOURCE_BYTES, NEBOC, ObjectInspector, PlatformBackend,
    PortabilityAnalyzer, PortabilityError, TargetConformanceSuite,
    TargetPack, TargetRegistry, TargetTriple, compiler_manifest,
)


def emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def regular_source(value: str | Path) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise PortabilityError("NEBO-G051-SOURCE-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.suffix != ".no" or path.stat().st_size > MAX_SOURCE_BYTES:
        raise PortabilityError("NEBO-G051-SOURCE-REGULAR-REQUIRED")
    return path


def descriptor(text: str):
    return TargetRegistry.builtins().get(TargetTriple.parse(text))


def target_name(text: str) -> str:
    return HostTriple.current().normalize() if text in {"host", "current"} else TargetTriple.parse(text).normalize()


def run_native(arguments: list[str], timeout: int = 30) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run([str(NEBOC), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)


def atomic_copy(source: Path, destination: Path) -> None:
    if destination.is_symlink():
        raise PortabilityError("NEBO-G051-OUTPUT-REGULAR-REQUIRED")
    target = destination.resolve(); target.parent.mkdir(parents=True, exist_ok=True)
    descriptor_fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    os.close(descriptor_fd)
    try:
        shutil.copyfile(source, temporary); os.chmod(temporary, source.stat().st_mode & 0o777)
        os.replace(temporary, target)
    except BaseException:
        try: os.unlink(temporary)
        except FileNotFoundError: pass
        raise


def command_host(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc host"); parser.parse_args(arguments)
    host = HostTriple.current(); target = TargetRegistry.builtins().get(host)
    emit({"schema": 1, "build": BuildTriple.current().normalize(), "host": host.normalize(),
          "capabilities": target.capabilities(), "compiler": CLI})
    return 0


def command_triple(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc triple")
    parser.add_argument("--normalize", required=True)
    args = parser.parse_args(arguments); triple = TargetTriple.parse(args.normalize)
    emit({"schema": 1, "input": args.normalize, "canonical": triple.normalize(),
          "deprecatedAlias": triple.deprecatedAlias, "architecture": triple.architecture(),
          "os": triple.operatingSystem(), "environment": triple.environment()})
    return 0


def command_targets(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc targets"); parser.parse_args(arguments)
    values = TargetRegistry.builtins().list()
    emit({"schema": 1, "targets": values, "supported": [row["triple"] for row in values if row["backendImplemented"] and row["runtimeImplemented"]]})
    return 0


def command_target_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc target-report"); parser.add_argument("triple")
    args = parser.parse_args(arguments); emit({"schema": 1, **descriptor(target_name(args.triple)).report()}); return 0


def command_emit_asm(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc emit-asm")
    parser.add_argument("source"); parser.add_argument("-o", "--output", required=True); parser.add_argument("--target", required=True)
    args = parser.parse_args(arguments); target = descriptor(target_name(args.target)); source = regular_source(args.source)
    ArchitectureBackend.new(target)
    output = Path(args.output)
    if output.is_symlink(): raise PortabilityError("NEBO-G051-OUTPUT-REGULAR-REQUIRED")
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor_fd, temp_name = tempfile.mkstemp(prefix=".g051-emit.", dir=output.parent.resolve())
    os.close(descriptor_fd); os.unlink(temp_name); temporary = Path(temp_name)
    try:
        result = run_native(["g051-native-emit-asm", str(source), "-o", str(temporary)])
        sys.stdout.buffer.write(result.stdout); sys.stderr.buffer.write(result.stderr)
        if result.returncode == 0: atomic_copy(temporary, output)
        return result.returncode
    finally:
        try: temporary.unlink()
        except FileNotFoundError: pass


def command_object_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc object-report"); parser.add_argument("artifact")
    args = parser.parse_args(arguments); inspector = ObjectInspector.open(args.artifact)
    emit({"schema": 1, "path": str(inspector.path), **inspector.validate(), "normalizedDigest": inspector.normalizedDigest()}); return 0


def command_platform_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc platform-report"); parser.add_argument("--target", required=True)
    args = parser.parse_args(arguments); target = descriptor(target_name(args.target))
    if not target.runtimeImplemented:
        emit({"schema": 1, "target": target.triple.normalize(), "available": [], "maturity": target.maturity,
              "status": "unavailable", "reason": "runtime-backend-not-implemented"})
    else:
        platform = PlatformBackend.forTarget(target, target.capabilities())
        emit({"schema": 1, **platform.report(), "selfTest": platform.selfTest()})
    return 0


def parse_targets(value: str) -> list:
    names = [part.strip() for part in value.split(",") if part.strip()]
    if not names: raise PortabilityError("NEBO-G051-TARGET-SET-LIMIT")
    return [descriptor(target_name(name)) for name in names]


def command_portability_check(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc portability-check")
    parser.add_argument("project"); parser.add_argument("--targets", required=True)
    args = parser.parse_args(arguments); report = PortabilityAnalyzer.analyze(args.project, parse_targets(args.targets))
    emit(report.as_dict()); return 0 if report.as_dict()["portable"] else 2


def command_portability_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc portability-report")
    parser.add_argument("project"); parser.add_argument("--targets", default="x86_64-unknown-linux-systemv,aarch64-unknown-linux-systemv,wasm32-unknown-wasi-wasm")
    args = parser.parse_args(arguments); emit(PortabilityAnalyzer.analyze(args.project, parse_targets(args.targets)).as_dict()); return 0


def command_target_pack(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc target-pack"); sub = parser.add_subparsers(dest="action", required=True)
    verify = sub.add_parser("verify"); verify.add_argument("path")
    args = parser.parse_args(arguments); emit({"schema": 1, **TargetPack.open(args.path).verify()}); return 0


def command_build(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc build")
    parser.add_argument("source"); parser.add_argument("-o", "--output", required=True); parser.add_argument("--target", required=True)
    args = parser.parse_args(arguments); source = regular_source(args.source); target = TargetTriple.parse(target_name(args.target))
    context = CrossCompilation.new(HostTriple.current(), target, None if target.normalize() == CURRENT_TRIPLE else None)
    if target.normalize() != CURRENT_TRIPLE:
        raise PortabilityError("NEBO-G051-ARCH-BACKEND-UNAVAILABLE")
    output = Path(args.output)
    if output.is_symlink(): raise PortabilityError("NEBO-G051-OUTPUT-REGULAR-REQUIRED")
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor_fd, temp_name = tempfile.mkstemp(prefix=".g051-build.", dir=output.parent.resolve())
    os.close(descriptor_fd); os.unlink(temp_name); temporary = Path(temp_name)
    try:
        result = run_native(["g051-native-build", str(source), "-o", str(temporary)])
        if result.returncode:
            sys.stderr.buffer.write(result.stderr); return result.returncode
        atomic_copy(temporary, output)
        emit({"schema": 1, "artifact": str(output.resolve()), "build": context.host.normalize(),
              "host": context.host.normalize(), "target": context.target.normalize(),
              "sourceDigest": hashlib.sha256(source.read_bytes()).hexdigest(),
              "artifactDigest": hashlib.sha256(output.resolve().read_bytes()).hexdigest(), "runtimeExecuted": False})
        return 0
    finally:
        try: temporary.unlink()
        except FileNotFoundError: pass


def command_run(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc run")
    parser.add_argument("source"); parser.add_argument("--target", required=True); parser.add_argument("--runner", required=True)
    args = parser.parse_args(arguments); target = target_name(args.target)
    if target != CURRENT_TRIPLE: raise PortabilityError("NEBO-G051-ARCH-BACKEND-UNAVAILABLE")
    if args.runner != "local-native": raise PortabilityError("NEBO-G051-RUNNER-UNAVAILABLE")
    with tempfile.TemporaryDirectory(prefix="nebo-g051-run-") as directory:
        artifact = Path(directory) / "program"
        result = run_native(["g051-native-build", str(regular_source(args.source)), "-o", str(artifact)])
        if result.returncode: sys.stderr.buffer.write(result.stderr); return result.returncode
        runner = CrossRunner.new("local-native", [], {"timeoutSeconds": 10, "memoryBytes": 64 << 20}, [])
        observed = runner.execute(artifact); emit({"schema": 1, "target": target, "runner": runner.environmentManifest(), **observed})
        return 0 if observed["classification"] == "hardware-pass" else 1


def host_smoke() -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix="nebo-g051-self-test-") as directory:
        source = Path(directory) / "smoke.no"; source.write_text("start() {\n  0;\n}\n", encoding="utf-8")
        asm = Path(directory) / "smoke.asm"; artifact = Path(directory) / "smoke"
        commands = (["check", str(source)], ["g051-native-emit-asm", str(source), "-o", str(asm)],
                    ["g051-native-build", str(source), "-o", str(artifact)])
        codes = [run_native(list(command)).returncode for command in commands]
        run = subprocess.run([str(artifact)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             timeout=10, check=False) if artifact.is_file() else None
        inspected = ObjectInspector.open(artifact).validate() if artifact.is_file() else None
        return {"commands": codes, "runtimeExit": run.returncode if run else None, "object": inspected,
                "pass": codes == [0, 0, 0] and run is not None and run.returncode == 0}


def command_self_test(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc self-test"); parser.add_argument("--host", action="store_true", required=True)
    parser.parse_args(arguments); plan = HostCompilerPlan.forTriple(HostTriple.current()); smoke = host_smoke()
    emit({"schema": 1, "host": plan.host.normalize(), "platformBackend": plan.platformBackend(),
          "suite": plan.selfTestSuite(), "smoke": smoke}); return 0 if smoke["pass"] else 1


def command_host_package(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc host-package"); sub = parser.add_subparsers(dest="action", required=True)
    verify = sub.add_parser("verify"); verify.add_argument("path"); verify.add_argument("--restore-test", action="store_true")
    args = parser.parse_args(arguments); package = HostCompilerPackage.open(args.path); result = package.verify()
    if args.restore_test: result["restoreTest"] = package.restoreTest()
    emit({"schema": 1, **result}); return 0


def command_target_matrix(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc target-matrix"); parser.parse_args(arguments)
    emit({"schema": 1, "targets": [{"triple": row["triple"], "maturity": row["maturity"],
                                      "backend": row["backendImplemented"], "runtime": row["runtimeImplemented"]}
                                     for row in TargetRegistry.builtins().list()],
          "hardwareClaimsRequireExecution": True, "notRunIsPass": False}); return 0


def command_conformance(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc conformance")
    parser.add_argument("--target", required=True); parser.add_argument("--source")
    args = parser.parse_args(arguments); target = descriptor(target_name(args.target))
    temporary: tempfile.TemporaryDirectory[str] | None = None
    source = args.source
    if source is None and target.backendImplemented:
        temporary = tempfile.TemporaryDirectory(prefix="nebo-g051-corpus-")
        path = Path(temporary.name) / "corpus.no"; path.write_text("start() {\n  0;\n}\n", encoding="utf-8"); source = str(path)
    try:
        suite = TargetConformanceSuite.forTarget(target, source); suite.compileCorpus()
        if target.runtimeImplemented and source:
            runner = CrossRunner.new("local-native", [], {"timeoutSeconds": 10, "memoryBytes": 64 << 20}, [])
            suite.runCorpus(runner)
        suite.abiVectors(); suite.objectVectors(); suite.runtimeVectors(); suite.crossHostReproducibility([HostTriple.current()])
        report = suite.report(); emit(report); return 0 if report["maturity"] not in {"blocked"} else 1
    finally:
        if temporary is not None: temporary.cleanup()


def command_conformance_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc conformance-report"); parser.add_argument("artifact")
    args = parser.parse_args(arguments); path = Path(args.artifact)
    if path.is_symlink() or not path.resolve().is_file() or path.resolve().stat().st_size > MAX_SOURCE_BYTES:
        raise PortabilityError("NEBO-G051-CONFORMANCE-REPORT-REGULAR-REQUIRED")
    value = json.loads(path.resolve().read_text(encoding="utf-8"))
    if not isinstance(value, dict) or value.get("schema") != 1 or "maturity" not in value or "evidence" not in value:
        raise PortabilityError("NEBO-G051-CONFORMANCE-REPORT-SCHEMA")
    emit({"schema": 1, "valid": True, "target": value.get("target"), "maturity": value["maturity"],
          "notRunIsPass": value.get("notRunIsPass", False), "digest": hashlib.sha256(path.resolve().read_bytes()).hexdigest()}); return 0


COMMANDS = {
    "host": command_host, "triple": command_triple, "targets": command_targets,
    "target-report": command_target_report, "emit-asm": command_emit_asm,
    "object-report": command_object_report, "platform-report": command_platform_report,
    "portability-check": command_portability_check, "portability-report": command_portability_report,
    "target-pack": command_target_pack, "build": command_build, "run": command_run,
    "self-test": command_self_test, "host-package": command_host_package,
    "target-matrix": command_target_matrix, "conformance": command_conformance,
    "conformance-report": command_conformance_report,
}


def main(argv: list[str]) -> int:
    if not argv or argv[0] not in COMMANDS: raise PortabilityError("NEBO-G051-COMMAND-UNKNOWN")
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (PortabilityError, KeyError, ValueError, json.JSONDecodeError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr); raise SystemExit(2)
