#!/usr/bin/env python3
"""Exercise stack-aligned compiler bytes through worktree, source and SDK roots."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tarfile
import tempfile
import time

ROOT = Path(__file__).resolve().parents[3]
AUDIT = ROOT / "scripts/mf056/audit-stack-alignment.py"
SOURCE_BUILDER = ROOT / "scripts/release/nebo-1.0/prepublication-remediation/build_assets.py"
SDK_BUILDER = ROOT / "compiler/sdk/sdk_builder.py"


def run(argv: list[str | Path], cwd: Path, *, expected: int = 0) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run([str(value) for value in argv], cwd=cwd,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}, check=False)
    if result.returncode != expected:
        raise SystemExit(
            f"PRODUCT_COMMAND_FAIL expected={expected} actual={result.returncode} "
            f"argv={argv!r} stdout={result.stdout!r} stderr={result.stderr!r}"
        )
    return result


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def assert_static_elf(path: Path, cwd: Path) -> None:
    header = run(["readelf", "-hW", path], cwd).stdout
    program = run(["readelf", "-lW", path], cwd).stdout
    dynamic = run(["readelf", "-dW", path], cwd).stdout
    undefined = run(["nm", "-u", path], cwd).stdout
    assert b"ELF64" in header and b"X86-64" in header
    assert b"INTERP" not in program and b"NEEDED" not in dynamic and not undefined.strip()


def exercise(neboc: Path, work: Path, label: str) -> list[float]:
    work.mkdir(parents=True, exist_ok=True)
    assert run([neboc, "--version"], work).stdout.strip() == b"neboc 1.0.0"
    run([sys.executable, "-B", AUDIT, neboc], ROOT)
    source = work / f"{label}.no"
    source.write_text("start() { 7 + 5; }\n", encoding="utf-8")
    durations: list[float] = []
    for index in range(7):
        started = time.perf_counter_ns()
        run([neboc, "check", source], work)
        durations.append((time.perf_counter_ns() - started) / 1_000_000)
    outputs: list[Path] = []
    assemblies: list[Path] = []
    for suffix in ("a", "b"):
        assembly = work / f"{label}-{suffix}.asm"
        output = work / f"{label}-{suffix}.elf"
        run([neboc, "emit-asm", source, "-o", assembly], work)
        run([neboc, "build", source, "-o", output], work)
        run([output], work)
        assert_static_elf(output, work)
        run([sys.executable, "-B", AUDIT, output], ROOT)
        assemblies.append(assembly)
        outputs.append(output)
    assert sha(assemblies[0]) == sha(assemblies[1])
    assert sha(outputs[0]) == sha(outputs[1])
    invalid = work / f"{label}-invalid.no"
    invalid.write_text("start( {\n", encoding="utf-8")
    forbidden = work / f"{label}-invalid.elf"
    run([neboc, "build", invalid, "-o", forbidden], work, expected=1)
    assert not forbidden.exists()
    return durations


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="nebo-stack-product-") as raw:
        work = Path(raw)
        all_durations = exercise(ROOT / "build/bin/neboc", work / "worktree", "worktree")

        archive = work / "nebo-source.tar"
        source_manifest = work / "source-manifest.json"
        run([sys.executable, "-B", SOURCE_BUILDER, "source", "--repo", ROOT,
             "--output", archive, "--manifest", source_manifest], ROOT)
        run([sys.executable, "-B", SOURCE_BUILDER, "verify-source", "--archive", archive,
             "--manifest", source_manifest], ROOT)
        extract_root = work / "source"
        extract_root.mkdir()
        with tarfile.open(archive, "r") as handle:
            handle.extractall(extract_root, filter="data")
        source_root = extract_root / json.loads(source_manifest.read_text())["single_root"]
        run(["bash", "scripts/build-neboc.sh"], source_root)
        all_durations.extend(exercise(source_root / "build/bin/neboc", source_root, "source"))

        sdk_root = work / "sdk-bundle"
        sdk_archive = work / "sdk.tar"
        run([sys.executable, "-B", SDK_BUILDER, "build", "--repo", ROOT,
             "--neboc", ROOT / "build/bin/neboc", "--output", sdk_root,
             "--profile", "sdk"], ROOT)
        run([sys.executable, "-B", SDK_BUILDER, "archive", sdk_root, sdk_archive], ROOT)
        prefix = work / "sdk-prefix"
        installer = sdk_root / "install-nebo-sdk.py"
        run([sys.executable, "-B", installer, "install", sdk_root, prefix], ROOT)
        all_durations.extend(exercise(prefix / "bin/neboc", work / "sdk-project", "sdk"))
        run([sys.executable, "-B", installer, "verify", prefix], ROOT)

        ordered = sorted(all_durations)
        median = statistics.median(ordered)
        p95 = ordered[max(0, int(len(ordered) * 0.95) - 1)]
        print("PRODUCT_COMPILER_ROOTS=3_OF_3_GREEN")
        print("WORKTREE_NEBOC=PASS")
        print("SOURCE_ARCHIVE_BUILD_NEBOC=PASS")
        print("SDK_INSTALLED_NEBOC=PASS")
        print("GENERATED_REPRESENTATIVE_ELFS=6_OF_6_GREEN")
        print("FAILURE_ATOMICITY=PASS")
        print("DETERMINISM=PASS")
        print("NO_C_NO_LIBC=PASS")
        print("ELF=PASS")
        print(f"COMPILE_CHECK_MEDIAN_MS={median:.3f}")
        print(f"COMPILE_CHECK_P95_MS={p95:.3f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
