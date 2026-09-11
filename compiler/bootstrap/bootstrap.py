"""Factual RF46 bootstrap inventory; stage0 only until Nebo compiler source exists."""

from __future__ import annotations

import hashlib
from pathlib import Path


class BootstrapError(RuntimeError):
    def __init__(self, diagnostic: str, message: str):
        super().__init__(f"{diagnostic}: {message}")
        self.diagnostic = diagnostic


class Bootstrap:
    STATUS = "NOT_AVAILABLE_SOURCE_COMPILER_MISSING"

    def __init__(self, stage0: Path, compiler_source_root: Path, trust_manifest_path: Path):
        self._stage0 = stage0.resolve()
        self.compiler_source_root = compiler_source_root.resolve()
        self.trust_manifest_path = trust_manifest_path.resolve()

    def stage0_verify(self) -> dict[str, str]:
        if not self._stage0.is_file():
            raise BootstrapError("NG46_F0701", "stage0 missing")
        source_compiler_files = sorted(self.compiler_source_root.rglob("*.no"))
        if source_compiler_files:
            raise BootstrapError("NG46_F0703", "unexpected source compiler requires a new reviewed bootstrap plan")
        digest = hashlib.sha256(self._stage0.read_bytes()).hexdigest()
        manifest = dict(
            line.rstrip("\n").split("\t", 1)
            for line in self.trust_manifest_path.read_text(encoding="utf-8").splitlines()[1:]
        )
        if manifest.get("stage0_sha256") != digest:
            raise BootstrapError("NG46_F0703", "stage0 trust digest mismatch")
        return {
            "status": self.STATUS,
            "stage0_sha256": digest,
            "stage1_executed": "NO",
            "stage2_executed": "NO",
            "maturity": "CONTRACT_GREEN_SOURCE_COMPILER_NOT_AVAILABLE",
        }

    @staticmethod
    def trust_manifest() -> tuple[str, ...]:
        return ("STAGE0_ASSEMBLY", "NASM", "GNU_LD", "LINUX_KERNEL", "X86_64_CPU")

    def stage0(self, compiler: Path | None = None) -> dict[str, str]:
        if compiler is not None and compiler.resolve() != self._stage0:
            raise BootstrapError("NG46_F0701", "stage0 compiler identity mismatch")
        return self.stage0_verify()

    @staticmethod
    def stage1(_source_compiler: Path) -> None:
        raise BootstrapError("NG46_F0702", "stage1 unavailable: Nebo compiler source missing")

    @staticmethod
    def stage2(_stage1: Path) -> None:
        raise BootstrapError("NG46_F0702", "stage2 unavailable: stage1 was not produced")

    @staticmethod
    def compare(_stage1: Path, _stage2: Path) -> None:
        raise BootstrapError("NG46_F0702", "bootstrap comparison unavailable: stages were not produced")

    @classmethod
    def divergence_report(cls) -> dict[str, str]:
        return {
            "status": cls.STATUS,
            "stage1": "NOT_RUN",
            "stage2": "NOT_RUN",
            "comparison": "NOT_RUN",
            "reason": "SOURCE_COMPILER_MISSING",
        }

    divergenceReport = divergence_report
    trustManifest = trust_manifest
