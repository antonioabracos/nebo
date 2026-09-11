#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from compiler.bootstrap.bootstrap import Bootstrap, BootstrapError


ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    bootstrap = Bootstrap(
        ROOT / "build/bin/neboc", ROOT / "compiler",
        ROOT / "compiler/bootstrap/stage0_trust.tsv",
    )
    report = bootstrap.stage0(ROOT / "build/bin/neboc")
    assert report["status"] == "NOT_AVAILABLE_SOURCE_COMPILER_MISSING"
    assert report["stage1_executed"] == report["stage2_executed"] == "NO"
    assert bootstrap.trustManifest() == ("STAGE0_ASSEMBLY", "NASM", "GNU_LD", "LINUX_KERNEL", "X86_64_CPU")
    try:
        bootstrap.stage1(ROOT / "missing.no")
    except BootstrapError as error:
        assert error.diagnostic == "NG46_F0702"
    else:
        raise AssertionError("fictional stage1 executed")
    for operation in (
        lambda: bootstrap.stage2(ROOT / "missing-stage1"),
        lambda: bootstrap.compare(ROOT / "missing-stage1", ROOT / "missing-stage2"),
    ):
        try:
            operation()
        except BootstrapError as error:
            assert error.diagnostic == "NG46_F0702"
        else:
            raise AssertionError("fictional bootstrap stage executed")
    divergence = bootstrap.divergenceReport()
    assert divergence["reason"] == "SOURCE_COMPILER_MISSING"
    assert divergence["comparison"] == "NOT_RUN"
    print(f"RF46_G46_F07_ORACLE_GREEN status={report['status']} stage0={report['stage0_sha256']} stage1=NO stage2=NO")


if __name__ == "__main__":
    main()
