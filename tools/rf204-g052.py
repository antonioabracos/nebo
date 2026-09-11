#!/usr/bin/env python3
"""Fixed repository-local command host for G052; always offline and bounded."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.toolchain import (  # noqa: E402
    AssemblerParser, Bootstrap, CURRENT_TARGET, DdcPlan, HermeticBuildContext,
    IndependentVerifier, InstructionEncoder, InternalLinker, InternalObjectWriter,
    NEBOC, Reproducibility, SOURCE_COMPILER_STATUS, SdkPackage, ToolchainError, atomic_bytes,
    build_trust_manifest, canonical_json, default_trace, digest_bytes,
    inspect_executable, inspect_object, regular_file,
)


def emit(value: object) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def run_native(arguments: list[str], timeout: int = 30) -> subprocess.CompletedProcess[bytes]:
    environment = {"LANG": "C", "LC_ALL": "C", "TZ": "UTC", "SOURCE_DATE_EPOCH": "0", "PATH": "/usr/bin:/bin"}
    return subprocess.run([str(NEBOC), *arguments], cwd=ROOT, env=environment, stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)


def command_build(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc build")
    parser.add_argument("source"); parser.add_argument("-o", "--output", required=True)
    parser.add_argument("--trace-tools"); parser.add_argument("--hermetic")
    args = parser.parse_args(arguments)
    source = regular_file(args.source, "NEBO-G052-SOURCE-REGULAR-REQUIRED")
    if not args.trace_tools and not args.hermetic:
        raise ToolchainError("NEBO-G052-BUILD-PROFILE-REQUIRED")
    output = Path(args.output)
    with tempfile.TemporaryDirectory(prefix="nebo-g052-build-") as directory:
        temporary = Path(directory) / "artifact"
        result = run_native(["g052-native-build", str(source), "-o", str(temporary)])
        if result.returncode:
            sys.stderr.buffer.write(result.stderr); return result.returncode
        artifact = atomic_bytes(output, temporary.read_bytes(), 0o755)
    trace = default_trace(source)
    trace.recordFile(artifact, "write", "sha256")
    trace_value = trace.as_dict()
    if args.trace_tools:
        atomic_bytes(args.trace_tools, canonical_json(trace_value) + b"\n")
    hermetic = None
    if args.hermetic:
        context = HermeticBuildContext.new(args.hermetic, ROOT, ["linux-x86_64-v1"])
        context.allowEnvironment(["LANG", "LC_ALL", "TZ", "SOURCE_DATE_EPOCH"])
        context.allowFiles([source, NEBOC])
        context.denyNetwork(); context.fixedEpoch(0); context.pathRemap(str(ROOT), "/src")
        context.fixedLocale("C"); context.fixedRandomSeed(52)
        hermetic = context.recordInputs()
    emit({"schema": 1, "artifact": str(artifact), "artifactDigest": digest_bytes(artifact.read_bytes()),
          "target": CURRENT_TARGET, "runtimeExecuted": False, "trace": trace_value,
          "hermetic": hermetic, "maturity": "external-assembler-linker"})
    return 0


def command_toolchain_report(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc toolchain-report"); parser.add_argument("subject")
    args = parser.parse_args(arguments); path = regular_file(args.subject, "NEBO-G052-REPORT-SUBJECT-INVALID")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(value, dict) or value.get("schema") != 1: raise ValueError
        report = {"schema": 1, "subject": path.name, "kind": "toolchain-trace", "trace": value,
                  "maturity": value.get("maturity", "unknown")}
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError):
        verifier = IndependentVerifier.verifyCompilerArtifact(path)
        report = {"schema": 1, "subject": path.name, "kind": "compiler-artifact", "artifact": verifier,
                  "maturity": "unknown-without-trace"}
    emit(report); return 0


def command_self_contained_audit(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc self-contained-audit"); parser.add_argument("source")
    args = parser.parse_args(arguments); trace = default_trace(args.source)
    emit({"schema": 1, "claim": "fully-internal", "status": "dependency-gap", "firstDependency": trace.externalTools()[0],
          "externalTools": trace.externalTools(), "maturity": trace.classifyMaturity(), "fullyInternal": False})
    return 2


def _module(path: str | Path):
    source = regular_file(path, "NEBO-G052-ASSEMBLER-INPUT-INVALID")
    return AssemblerParser.parse(source.read_text(encoding="utf-8"))


def _object(path: str | Path) -> tuple[InternalObjectWriter, bytes]:
    module = _module(path); module.validate()
    writer = InternalObjectWriter.new(CURRENT_TARGET, "ELF64"); writer.consume(module)
    writer.layoutSections(); writer.buildSymbolTable(); writer.buildRelocations()
    return writer, writer.emitBytes()


def command_assemble(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc assemble"); parser.add_argument("source")
    parser.add_argument("--target", required=True); parser.add_argument("-o", "--output", required=True)
    args = parser.parse_args(arguments)
    if args.target not in {CURRENT_TARGET, "host"}: raise ToolchainError("NEBO-G052-ASSEMBLER-TARGET-UNSUPPORTED")
    writer, image = _object(args.source); output = atomic_bytes(args.output, image)
    emit({"schema": 1, "artifact": str(output), "writer": writer.report(), "roundtrip": writer.verifyRoundtrip(),
          "encoder": InstructionEncoder.forTarget(CURRENT_TARGET).coverageReport()}); return 0


def command_object_verify(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc object-verify"); parser.add_argument("object")
    args = parser.parse_args(arguments); path = regular_file(args.object, "NEBO-G052-OBJECT-INVALID")
    report = inspect_object(path.read_bytes())
    if not report["valid"]: raise ToolchainError("NEBO-G052-OBJECT-INVALID")
    emit({"schema": 1, "path": str(path), **report, "digest": digest_bytes(path.read_bytes())}); return 0


def command_link(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc link"); parser.add_argument("objects", nargs="+")
    parser.add_argument("-o", "--output", required=True); parser.add_argument("--target", required=True)
    args = parser.parse_args(arguments)
    if args.target not in {CURRENT_TARGET, "host"}: raise ToolchainError("NEBO-G052-LINK-PROFILE-UNSUPPORTED")
    linker = InternalLinker.new(CURRENT_TARGET, "static-exit-x86_64-v1")
    for path in args.objects: linker.addObject(path)
    linker.resolveSymbols(); linker.buildReachability(["_start"]); linker.layout(); linker.applyRelocations()
    linker.emitExecutable("_start", args.output)
    emit({"schema": 1, "artifact": str(Path(args.output).resolve()), "profile": linker.profile,
          "map": linker.mapFile(), "verify": linker.verify(), "externalLinkerExecuted": False}); return 0


def command_reproducibility(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc reproducibility-report"); parser.add_argument("left"); parser.add_argument("right")
    args = parser.parse_args(arguments); emit({"schema": 1, **Reproducibility.compare([args.left, args.right])}); return 0


def command_bootstrap(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc bootstrap"); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--stage", type=int, choices=(0, 1, 2)); group.add_argument("--verify", action="store_true")
    args = parser.parse_args(arguments); bootstrap = Bootstrap.stage0()
    if args.verify:
        emit({"schema": 1, "status": SOURCE_COMPILER_STATUS, "stage0": bootstrap.stageManifest(0),
              "stage1": bootstrap.stageManifest(1), "stage2": bootstrap.stageManifest(2), **bootstrap.divergenceReport()}); return 0
    report = bootstrap.stageManifest(args.stage)
    emit({"schema": 1, **report}); return 0 if args.stage == 0 else 3


def command_diverse(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc diverse-build"); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--plan"); group.add_argument("--report")
    args = parser.parse_args(arguments); path = regular_file(args.plan or args.report, "NEBO-G052-DDC-PLAN-INVALID")
    value = json.loads(path.read_text(encoding="utf-8")); plan = DdcPlan.new(str(value.get("compilerA", "stage0")), str(value.get("compilerB", "NOT_AVAILABLE")), str(value.get("source", "NOT_AVAILABLE")))
    report = {"schema": 1, **plan.anomalyReport(), "assumptions": plan.assumptions(), "absoluteProofClaim": False}
    emit(report); return 3 if args.plan else 0


def command_trust_manifest(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc trust-manifest"); parser.add_argument("subject"); parser.add_argument("--output")
    args = parser.parse_args(arguments); manifest = build_trust_manifest(args.subject); value = manifest.as_dict()
    if args.output: atomic_bytes(args.output, canonical_json(value) + b"\n")
    emit(value); return 0


def command_provenance_verify(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc provenance-verify"); parser.add_argument("manifest")
    args = parser.parse_args(arguments); path = regular_file(args.manifest, "NEBO-G052-PROVENANCE-MANIFEST-INVALID")
    value = json.loads(path.read_text(encoding="utf-8")); claimed = value.pop("manifestDigest", None)
    actual = digest_bytes(canonical_json(value))
    if claimed != actual: raise ToolchainError("NEBO-G052-PROVENANCE-DIGEST-MISMATCH")
    emit({"schema": 1, "valid": True, "manifestDigest": actual, "signatureStatus": value.get("signatureStatus", "unsigned"),
          "offline": True}); return 0


def _sdk_package(targets: str) -> SdkPackage:
    names = [name.strip() for name in targets.split(",") if name.strip()]
    if names != [CURRENT_TARGET]: raise ToolchainError("NEBO-G052-SDK-TARGET-UNSUPPORTED")
    target_pack = ROOT / "sdk/nebo-1.0/targets/linux-x86_64.json"
    documentation = ROOT / "docs/public/v1.0/index.md"
    license_file = ROOT / "sdk/nebo-1.0/licenses/NeboConsoleMonoAtlas-OFL-1.1.md"
    package = SdkPackage.new(CURRENT_TARGET, NEBOC, [target_pack])
    package._add('bin/neboc', ROOT/'compiler/sdk/neboc-launcher.sh', 0o755, 'launcher')
    package._add('build/bin/neboc', NEBOC, 0o755, 'compiler')
    # Preserve canonical relative discovery without a development-tree copy.
    # This is the finite runtime/tool closure of the source compiler profile.
    fixed = {
        'build/obj/runtime_practical_io.o': 'runtime',
        'build/bin/nebo-token-scan': 'tool-probe',
        'build/bin/nebo-comment-scan': 'tool-probe',
        'build/bin/nebo-doc-examples': 'tool-probe',
        'build/bin/nebo-doc-record': 'tool-probe',
        'build/bin/nebo-doc-parser': 'tool-probe',
        'build/bin/nebo-doc-validator': 'tool-probe',
        'build/bin/nebo-docs': 'tool-probe',
        'build/tests/rf166/g154/interface_codec_probe': 'tool-probe',
        'sdk/interfaces/prelude/std.prelude.ni': 'stdlib',
        'sdk/interfaces/prelude/stdlib-registry.json': 'stdlib',
        'sdk/contracts/PRELUDE-CONTRACT.json': 'stdlib',
        'sdk/contracts/stdlib/STDLIB-API-ABI-MANIFEST.json': 'stdlib',
    }
    for name, role in sorted(fixed.items()):
        package._add(name, ROOT/name, 0o755 if role=='tool-probe' else 0o644, role)
    paths = set((ROOT/'compiler/sdk').glob('*.py')) | set((ROOT/'compiler/migration').glob('*.py'))
    paths |= set((ROOT/'compiler/stdlib').glob('*.py'))
    paths |= set((ROOT/'tools').glob('rf204-g15*.py')) | set((ROOT/'tools').glob('rf204-g16*.py'))
    paths |= {ROOT/'tools'/name for name in ('rf204-g024.py','rf204-g027.py','rf204-g048.py',
                                          'rf204-g052.py','rf27-format.py','rf27-package.py')}
    for path in sorted(paths):
        package._add(path.relative_to(ROOT).as_posix(), path, 0o644, 'tool-host')
    package.addTargetPack(target_pack); package.addDocumentation([documentation]); package.addLicenses([license_file])
    return package


def command_sdk(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc sdk"); sub = parser.add_subparsers(dest="action", required=True)
    pack = sub.add_parser("pack"); pack.add_argument("--host", required=True); pack.add_argument("--targets", required=True); pack.add_argument("-o", "--output", required=True)
    verify = sub.add_parser("verify"); verify.add_argument("package")
    restore = sub.add_parser("restore"); restore.add_argument("package"); restore.add_argument("--destination", required=True)
    test = sub.add_parser("self-test"); test.add_argument("package")
    args = parser.parse_args(arguments)
    if args.action == "pack":
        if args.host not in {"host", CURRENT_TARGET}: raise ToolchainError("NEBO-G052-SDK-HOST-UNSUPPORTED")
        emit({"schema": 1, **_sdk_package(args.targets).pack(args.output)}); return 0
    if args.action == "verify": emit({"schema": 1, **SdkPackage.verify(args.package)}); return 0
    if args.action == "restore": emit({"schema": 1, **SdkPackage.restore(args.package, args.destination)}); return 0
    with tempfile.TemporaryDirectory(prefix="nebo-g052-sdk-selftest-") as directory:
        destination = Path(directory) / "sdk"; SdkPackage.restore(args.package, destination); result = SdkPackage.selfTest(destination)
        emit({"schema": 1, **result}); return 0 if result["pass"] else 1


COMMANDS = {
    "build": command_build, "toolchain-report": command_toolchain_report,
    "self-contained-audit": command_self_contained_audit, "assemble": command_assemble,
    "object-build": command_assemble, "object-verify": command_object_verify,
    "link": command_link, "reproducibility-report": command_reproducibility,
    "bootstrap": command_bootstrap, "diverse-build": command_diverse,
    "trust-manifest": command_trust_manifest, "provenance-verify": command_provenance_verify,
    "sdk": command_sdk,
}


def main(argv: list[str]) -> int:
    if not argv or argv[0] not in COMMANDS: raise ToolchainError("NEBO-G052-COMMAND-UNKNOWN")
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (ToolchainError, KeyError, ValueError, json.JSONDecodeError, OSError, subprocess.TimeoutExpired, tarfile.TarError) as error:
        print(str(error), file=sys.stderr); raise SystemExit(2)
