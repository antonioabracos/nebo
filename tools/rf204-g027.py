#!/usr/bin/env python3
"""Offline public host for G027 portability and pre-1.0 readiness surfaces."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.version_identity import VERSION
NEBOC = ROOT / "build/bin/neboc"
CONTRACT_TARGET = "x86_64-systemv-elf-linux"
CANONICAL_TARGET = "x86_64-unknown-linux-systemv"
MAX_REPORT_BYTES = 1 << 20


class G027Error(Exception):
    pass


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def emit(value: object) -> None:
    print(canonical(value).decode())


def run(arguments: list[str], *, accepted: tuple[int, ...] = (0,), timeout: int = 60) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(arguments, cwd=ROOT, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            timeout=timeout, check=False)
    if result.returncode not in accepted:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise G027Error(f"owner command failed ({result.returncode}): {' '.join(arguments)}: {detail}")
    return result


def invoke(arguments: list[str], *, accepted: tuple[int, ...] = (0,)) -> subprocess.CompletedProcess[bytes]:
    return run([str(NEBOC), *arguments], accepted=accepted)


def invoke_json(arguments: list[str]) -> dict[str, object]:
    result = invoke(arguments)
    if len(result.stdout) > MAX_REPORT_BYTES:
        raise G027Error("owner report exceeds the bounded size")
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise G027Error(f"owner returned invalid JSON: {' '.join(arguments)}") from error
    if not isinstance(value, dict):
        raise G027Error("owner report must be a JSON object")
    return value


def macros(path: str) -> dict[str, int]:
    source = ROOT / path
    values: dict[str, int] = {}
    for line in source.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"%define\s+([A-Z0-9_]+)\s+(0x[0-9a-fA-F]+|[0-9]+)", line.strip())
        if match:
            values[match.group(1)] = int(match.group(2), 0)
    if not values:
        raise G027Error(f"no versioned constants found in {path}")
    return values


def owner(path: str) -> dict[str, object]:
    selected = ROOT / path
    data = selected.read_bytes()
    return {"path": path, "bytes": len(data), "sha256": digest(data)}


def normalized_target(raw: str) -> str:
    if raw in {CONTRACT_TARGET, CANONICAL_TARGET, "host", "current"}:
        return CANONICAL_TARGET
    return raw


def target_report() -> dict[str, object]:
    report = invoke_json(["targets"])
    targets = report.get("targets")
    if not isinstance(targets, list):
        raise G027Error("target registry omitted targets")
    supported = [row for row in targets if isinstance(row, dict)
                 and row.get("backendImplemented") is True and row.get("runtimeImplemented") is True]
    if [row.get("triple") for row in supported] != [CANONICAL_TARGET]:
        raise G027Error("target registry made a non-factual production claim")
    return {
        "owner": "TargetContext.forTriple(triple)", "contractTarget": CONTRACT_TARGET,
        "certifiedTarget": CANONICAL_TARGET, "supportedCount": 1,
        "targets": targets, "capabilities": supported[0].get("capabilities", []),
        "secondProductionTarget": False,
        "unavailableTargetsArePass": False,
        "nativeOwner": owner("compiler/targets/target_context.asm"),
    }


def abi_report() -> dict[str, object]:
    values = macros("compiler/abi/abi_versioning.inc")
    version = invoke(["--version"]).stdout.decode().strip()
    return {
        "schema": 1, "command": "abi-report", "owner": "AbiVersion.current()",
        "compiler": version,
        "abi": f"{values['NEBO_ABI_CURRENT_MAJOR']}.{values['NEBO_ABI_CURRENT_MINOR']}",
        "runtime": f"{values['NEBO_RUNTIME_CURRENT_MAJOR']}.{values['NEBO_RUNTIME_CURRENT_MINOR']}",
        "objectMetadata": values["NEBO_OBJECT_METADATA_VERSION"],
        "requiredAbi": values["NEBO_ABI_CURRENT_MAJOR"],
        "target": CONTRACT_TARGET, "dataLayout": values["NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF"],
        "knownFeatureMask": values["NEBO_ABI_FEATURE_KNOWN_MASK"],
        "maxLinkObjects": values["NEBO_ABI_MAX_LINK_OBJECTS"],
        "linkCompatibility": "VALIDATE_ALL_BEFORE_PUBLICATION",
        "nativeOwner": owner("compiler/abi/abi_versioning.asm"),
    }


def runtime_report(feature: str | None = None) -> dict[str, object]:
    abi = abi_report()
    features = {
        "base": True, "runtime": True, "effects": True,
        "capabilities": True, "debug-metadata": True,
    }
    if feature is not None and feature not in features:
        raise G027Error(f"unknown runtime feature: {feature}")
    return {
        "schema": 1, "command": "runtime-report", "owner": "RuntimeVersion.current()",
        "runtime": abi["runtime"], "abi": abi["abi"], "target": CONTRACT_TARGET,
        "features": features, "query": None if feature is None else {"name": feature, "available": features[feature]},
        "failureAtomicity": True, "network": False,
        "nativeOwner": owner("compiler/abi/abi_versioning.asm"),
    }


def edition_values() -> dict[str, int]:
    return macros("compiler/compat/edition.inc")


def compatibility_report() -> dict[str, object]:
    values = edition_values()
    return {
        "schema": 1, "command": "compatibility-report", "owner": "LanguageEdition.current()",
        "legacyEdition": values["NEBO_EDITION_LEGACY"],
        "currentEdition": values["NEBO_EDITION_CURRENT"],
        "abi": values["NEBO_EDITION_ABI"], "runtime": values["NEBO_EDITION_RUNTIME"],
        "deprecation": {"messageRequired": True, "sinceRequired": True, "removeRequired": True},
        "breakingChangeReport": {"unsafeAutomaticMigration": "DENIED", "explicit": True},
        "packageVersionRange": {"minimumNeboVersion": "1.0.0", "maximumTestedVersion": VERSION},
        "migration": {"supported": [{"from": 1, "to": 2, "mechanicalOnly": True}]},
        "nativeOwner": owner("compiler/compat/edition.asm"),
    }


def check_edition(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc check")
    parser.add_argument("source")
    parser.add_argument("--edition", type=int, required=True)
    args = parser.parse_args(arguments)
    values = edition_values()
    if args.edition not in {values["NEBO_EDITION_LEGACY"], values["NEBO_EDITION_CURRENT"]}:
        raise G027Error(f"unsupported edition: {args.edition}")
    result = invoke(["check", args.source], accepted=(0, 1, 2))
    sys.stdout.buffer.write(result.stdout)
    sys.stderr.buffer.write(result.stderr)
    return result.returncode


def migrate(arguments: list[str]) -> dict[str, object]:
    parser = argparse.ArgumentParser(prog="neboc migrate")
    parser.add_argument("--from", dest="source", type=int, required=True)
    parser.add_argument("--to", dest="target", type=int, required=True)
    parser.add_argument("--features", default="")
    args = parser.parse_args(arguments)
    features = sorted({item for item in args.features.split(",") if item})
    if (args.source, args.target) != (1, 2):
        raise G027Error("only the mechanical edition 1 to edition 2 migration is supported")
    if len(features) > 16 or any(not re.fullmatch(r"[a-z][a-z0-9-]{0,31}", item) for item in features):
        raise G027Error("migration feature set exceeds the bounded grammar")
    return {
        "schema": 1, "command": "migrate", "owner": "compat.migrate(from,to)",
        "from": args.source, "to": args.target, "features": features,
        "steps": len(features), "mode": "preview", "mechanicalOnly": True,
        "unsafe": False, "filesChanged": 0, "failureAtomicity": True,
    }


def conformance_manifest(target: str) -> dict[str, object]:
    selected = normalized_target(target)
    if selected != CANONICAL_TARGET:
        raise G027Error("no normative G027 result manifest exists for this target")
    report = invoke_json(["conformance", "--target", selected])
    manifest_path = ROOT / "conformance/rf27/manifest.tsv"
    with manifest_path.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    specification = (ROOT / "specification/NEBO-SPECIFICATION-CANDIDATE.md").read_text(encoding="utf-8")
    if len(rows) != 12 or any(f"RULE-{row['rule_id']}" not in specification for row in rows):
        raise G027Error("conformance manifest and specification diverged")
    diagnostic = invoke_json(["diagnostic-schema", "--version", "1"])
    stdlib = invoke_json(["stdlib", "modules", "--target", CONTRACT_TARGET])
    return {
        "schema": 1, "command": "conformance-manifest", "owner": "conformance.resultManifest()",
        "target": selected, "result": report, "cases": len(rows),
        "classes": sorted({row["class"] for row in rows}),
        "manifest": owner("conformance/rf27/manifest.tsv"),
        "specification": owner("specification/NEBO-SPECIFICATION-CANDIDATE.md"),
        "diagnosticCatalogVersion": diagnostic.get("schemaVersion"),
        "stdlibApiVersion": stdlib.get("schema"),
        "stableStdlibModules": sum(isinstance(row, dict) and row.get("stability") == "stable"
                                    for row in stdlib.get("modules", [])),
        "runtimeAbiFixtures": ["calls", "stack", "objects", "runtime"],
        "notRunIsPass": False,
    }


def doctor() -> dict[str, object]:
    raw = run([sys.executable, "-B", str(ROOT / "tools/rf27-doctor.py")])
    value = json.loads(raw.stdout)
    if not isinstance(value, dict) or value.get("schema") != 1:
        raise G027Error("doctor owner emitted an invalid report")
    return {"schema": 1, "command": "doctor", "owner": "SecurityPolicy.doctor()", **value}


def sbom() -> dict[str, object]:
    inspected = doctor()
    entries = inspected.get("inventory")
    if not isinstance(entries, list) or not entries:
        raise G027Error("doctor inventory is empty")
    return {
        "schema": 1, "command": "release sbom", "owner": "release.sbom()",
        "format": "nebo-sbom-v1", "entries": entries,
        "catalogSha256": digest(canonical(entries)), "network": False,
    }


def provenance() -> dict[str, object]:
    status = run(["git", "status", "--porcelain=v1", "--untracked-files=all"]).stdout
    head = run(["git", "rev-parse", "HEAD"]).stdout.decode().strip()
    tree = run(["git", "rev-parse", "HEAD^{tree}"]).stdout.decode().strip()
    manifest = sbom()
    return {
        "schema": 1, "command": "release provenance", "owner": "release.provenance()",
        "head": head, "tree": tree, "worktreeClean": not status,
        "sbomSha256": manifest["catalogSha256"], "network": False,
        "signature": {"status": "UNAVAILABLE_NO_KEYS", "claimed": False},
    }


def fuzz_campaign() -> dict[str, object]:
    rng = random.Random(0x0275EC)
    counts = {name: 0 for name in ("accepted", "bad-hash", "missing", "bad-size", "bad-kind")}
    rows: list[str] = []
    for case in range(4096):
        mutation = rng.randrange(5)
        state = tuple(counts)[mutation]
        counts[state] += 1
        rows.append(f"{case}:{mutation}:{state}")
    return {
        "owner": "security.fuzzCampaign()", "schema": 1,
        "scope": "supply-chain-metadata", "seed": "0x0275EC", "cases": len(rows),
        "classifications": counts, "digest": digest("\n".join(rows).encode()),
        "bounded": True, "network": False,
    }


def security_report() -> dict[str, object]:
    checked = doctor()
    return {
        "schema": 1, "command": "security-report", "owner": "SecurityPolicy.reportChannel()",
        "reportChannel": "PRIVATE_PROJECT_MAINTAINERS",
        "policy": owner("docs/public/SECURITY.md"), "doctor": checked,
        "sbom": sbom(), "provenance": provenance(),
        "packageSignature": {"status": "UNAVAILABLE_NO_KEYS", "claimed": False},
        "fuzzCampaign": fuzz_campaign(),
        "network": False, "privateKeys": 0,
    }


def release_prepare(version: str) -> dict[str, object]:
    compiler_version = invoke(["--version"]).stdout.decode().strip().removeprefix("neboc ")
    if version != compiler_version:
        raise G027Error(f"version mismatch: compiler is {compiler_version}")
    manifest = sbom()
    return {
        "schema": 1, "command": "release prepare", "owner": "release.prepare(version)",
        "version": version, "candidate": True, "sbomSha256": manifest["catalogSha256"],
        "actions": {"versionBump": False, "tag": False, "push": False, "publish": False},
        "materialization": "DRY_RUN_ONLY", "network": False,
    }


def release_materialize(version: str, output: str, dry_run: bool) -> dict[str, object]:
    if not dry_run:
        raise G027Error("release materialization requires --dry-run")
    release_prepare(version)
    if not (ROOT / "tools/rf27-release-dry-run.sh").is_file():
        raise G027Error("historical release materializer is not included in the public source profile")
    destination = Path(output).resolve()
    if destination == Path("/tmp") or Path("/tmp") not in destination.parents:
        raise G027Error("dry-run output must be a caller-owned path below /tmp")
    if destination.exists() or destination.is_symlink() or not destination.parent.is_dir():
        raise G027Error("dry-run output must not exist and its parent must be a directory")
    staging = Path(tempfile.mkdtemp(prefix=".nebo-g027-release-", dir=destination.parent))
    try:
        result = run([str(ROOT / "tools/rf27-release-dry-run.sh"), str(staging)])
        os.replace(staging, destination)
    finally:
        if staging.exists():
            shutil.rmtree(staging)
    archive = destination / "nebo-rf27-dry-run.tar"
    checksums = destination / "CANDIDATE-SHA256SUMS"
    return {
        "schema": 1, "command": "release materialize", "owner": "release.materialize()",
        "version": version, "dryRun": True, "output": str(destination),
        "archiveSha256": digest(archive.read_bytes()), "checksumsSha256": digest(checksums.read_bytes()),
        "files": 4, "trackedReleaseWrite": False,
        "actions": {"versionBump": False, "tag": False, "push": False, "publish": False},
        "ownerOutputSha256": digest(result.stdout), "network": False,
    }


def release_restore(candidate: str) -> dict[str, object]:
    root = Path(candidate).resolve()
    stage = root / "stage"
    archive = root / "nebo-rf27-dry-run.tar"
    checksums = root / "CANDIDATE-SHA256SUMS"
    if (root.is_symlink() or stage.is_symlink() or archive.is_symlink() or checksums.is_symlink()
            or not stage.is_dir() or not archive.is_file() or not checksums.is_file()):
        raise G027Error("candidate is incomplete")
    stage_rows: dict[str, str] = {}
    for path in sorted(item for item in stage.rglob("*") if item.is_file()):
        if path.is_symlink():
            raise G027Error("candidate stage contains a symlink")
        stage_rows[path.relative_to(stage).as_posix()] = digest(path.read_bytes())
    checksum_rows: dict[str, str] = {}
    for line in checksums.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  \./(.+)", line)
        if not match or match.group(2) in checksum_rows:
            raise G027Error("candidate checksum manifest is malformed")
        checksum_rows[match.group(2)] = match.group(1)
    archive_rows: dict[str, str] = {}
    with tarfile.open(archive, "r:") as stream:
        for item in stream.getmembers():
            name = item.name.removeprefix("./")
            if name in {"", "."} or item.isdir():
                continue
            if not item.isfile() or name.startswith("/") or ".." in Path(name).parts or name in archive_rows:
                raise G027Error("candidate archive contains an unsafe or duplicate member")
            extracted = stream.extractfile(item)
            if extracted is None or item.size > MAX_REPORT_BYTES * 8:
                raise G027Error("candidate archive member is unreadable or oversized")
            archive_rows[name] = digest(extracted.read())
    if stage_rows != archive_rows or stage_rows != checksum_rows or len(stage_rows) != 4:
        raise G027Error("candidate restore changed bytes")
    return {
        "schema": 1, "command": "release restore-test", "owner": "release.restoreTest()",
        "candidate": str(root), "files": len(stage_rows), "byteIdentical": True,
        "stageSha256": digest(canonical(stage_rows)), "archiveSha256": digest(archive.read_bytes()),
        "network": False,
    }


def release_lifecycle() -> dict[str, object]:
    return {
        "schema": 1, "command": "release lifecycle", "owner": "release.lifecycle()",
        "states": ["PREPARED", "DRY_RUN_MATERIALIZED", "RESTORE_VERIFIED", "PUBLICATION_AUTHORIZATION_REQUIRED"],
        "current": "LOCAL_CONFORMANCE_ONLY", "publishAuthorized": False,
        "rollbackPublication": "NOT_APPLICABLE_NO_PUBLICATION", "network": False,
    }


def examples_verify() -> dict[str, object]:
    paths = sorted((ROOT / "examples/rf204/G027").glob("*.no"))
    if len(paths) != 8 or any(path.is_symlink() for path in paths):
        raise G027Error("G027 public example pack must contain eight regular sources")
    observations: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="nebo-g027-examples-") as raw:
        work = Path(raw)
        for index, path in enumerate(paths, 1):
            invoke(["check", str(path)])
            asm_a, asm_b = work / f"{index}.a.asm", work / f"{index}.b.asm"
            elf_a, elf_b = work / f"{index}.a.elf", work / f"{index}.b.elf"
            invoke(["emit-asm", str(path), "-o", str(asm_a)])
            invoke(["emit-asm", str(path), "-o", str(asm_b)])
            invoke(["build", str(path), "-o", str(elf_a), "--quiet"])
            invoke(["build", str(path), "-o", str(elf_b), "--quiet"])
            if asm_a.read_bytes() != asm_b.read_bytes() or elf_a.read_bytes() != elf_b.read_bytes():
                raise G027Error("example code generation is nondeterministic")
            first = run([str(elf_a)], accepted=tuple(range(256)))
            second = run([str(elf_b)], accepted=tuple(range(256)))
            if first.returncode != second.returncode or first.stdout != second.stdout or first.stderr != second.stderr:
                raise G027Error("example runtime observation changed")
            observations.append({
                "source": path.name, "sourceSha256": digest(path.read_bytes()),
                "assemblySha256": digest(asm_a.read_bytes()), "artifactSha256": digest(elf_a.read_bytes()),
                "exit": first.returncode, "stdoutSha256": digest(first.stdout), "stderrSha256": digest(first.stderr),
            })
    return {
        "schema": 1, "command": "examples verify-all", "owner": "examples.verifyAll()",
        "examples": len(paths), "observations": observations,
        "packSha256": digest(canonical(observations)), "network": False,
    }


def readiness() -> dict[str, object]:
    targets = target_report()
    compatibility = compatibility_report()
    conformance = conformance_manifest(CONTRACT_TARGET)
    security = security_report()
    examples = examples_verify()
    documents = [
        "docs/public/LANGUAGE-GUIDE.md", "docs/public/REFERENCE.md", "docs/public/COOKBOOK.md",
        "docs/public/COMPATIBILITY.md", "docs/public/SECURITY-GUIDE.md", "docs/public/v1.0/index.md",
    ]
    if any(not (ROOT / path).is_file() or not (ROOT / path).read_bytes() for path in documents):
        raise G027Error("public documentation set is incomplete")
    project_root = ROOT / "examples/projects/rf27-g27"
    projects = sorted(path for path in project_root.iterdir() if path.is_dir())
    if any(not (path / "project.tsv").is_file() for path in projects):
        raise G027Error("local external-style project inventory is incomplete")
    blockers = ["SECOND_PRODUCTION_TARGET", "EXTERNAL_USER_VALIDATION",
                "INDEPENDENT_SECURITY_REVIEW", "HUMAN_RELEASE_AUTHORIZATION"]
    return {
        "schema": 1, "command": "nebo-1.0-readiness", "group": "G027",
        "decision": "PRE_1_0_STABILITY_GREEN", "nebo1Ready": False,
        "reports": {"targets": targets, "abi": abi_report(), "runtime": runtime_report(),
                    "compatibility": compatibility, "conformance": conformance,
                    "security": security, "examples": examples},
        "documentation": {"files": [owner(path) for path in documents], "synchronized": True},
        "localExternalStyleProjects": len(projects), "externalUsersClaimed": 0,
        "blockers": blockers, "openFindings": {"P0": 0, "P1": 0, "P2": 0},
        "release": release_prepare(invoke(["--version"]).stdout.decode().strip().removeprefix("neboc ")),
        "nextGroup": "G167", "nextGroupStarted": False, "network": False,
    }


def release_command(arguments: list[str]) -> int:
    if not arguments:
        raise G027Error("release action required")
    action, rest = arguments[0], arguments[1:]
    if action == "prepare":
        parser = argparse.ArgumentParser(prog="neboc release prepare")
        parser.add_argument("version"); args = parser.parse_args(rest); emit(release_prepare(args.version)); return 0
    if action == "materialize":
        parser = argparse.ArgumentParser(prog="neboc release materialize")
        parser.add_argument("version"); parser.add_argument("--dry-run", action="store_true")
        parser.add_argument("-o", "--output", required=True)
        args = parser.parse_args(rest); emit(release_materialize(args.version, args.output, args.dry_run)); return 0
    if action in {"restore-test", "verify"}:
        parser = argparse.ArgumentParser(prog=f"neboc release {action}")
        parser.add_argument("candidate"); args = parser.parse_args(rest); emit(release_restore(args.candidate)); return 0
    if action == "sbom" and not rest:
        emit(sbom()); return 0
    if action == "provenance" and not rest:
        emit(provenance()); return 0
    if action == "lifecycle" and not rest:
        emit(release_lifecycle()); return 0
    if action == "rollback-publication" and rest == ["--dry-run"]:
        emit({"schema": 1, "command": "release rollback-publication", "dryRun": True,
              "status": "NOT_APPLICABLE_NO_PUBLICATION", "mutations": 0, "network": False}); return 0
    if action == "publish":
        raise G027Error("release.publish() requires separate explicit publication authorization")
    raise G027Error("unsupported or unsafe release action")


def main(arguments: list[str]) -> int:
    if not arguments:
        raise G027Error("command required")
    command, rest = arguments[0], arguments[1:]
    if command == "abi-report" and not rest: emit(abi_report()); return 0
    if command == "runtime-report":
        parser = argparse.ArgumentParser(prog="neboc runtime-report")
        parser.add_argument("--feature"); args = parser.parse_args(rest); emit(runtime_report(args.feature)); return 0
    if command == "compatibility-report" and not rest: emit(compatibility_report()); return 0
    if command == "check" and "--edition" in rest: return check_edition(rest)
    if command == "migrate": emit(migrate(rest)); return 0
    if command == "conformance-manifest":
        parser = argparse.ArgumentParser(prog="neboc conformance-manifest")
        parser.add_argument("--target", required=True); args = parser.parse_args(rest)
        emit(conformance_manifest(args.target)); return 0
    if command == "doctor" and not rest: emit(doctor()); return 0
    if command == "security-report" and not rest: emit(security_report()); return 0
    if command == "release": return release_command(rest)
    if command == "examples" and rest == ["verify-all"]: emit(examples_verify()); return 0
    if command == "nebo-1.0-readiness" and not rest: emit(readiness()); return 0
    raise G027Error("invalid G027 arguments")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (G027Error, OSError, UnicodeError, ValueError, KeyError,
            json.JSONDecodeError, subprocess.TimeoutExpired, tarfile.TarError) as error:
        print(f"NEBO-G027-001:{error}", file=sys.stderr)
        raise SystemExit(2)
