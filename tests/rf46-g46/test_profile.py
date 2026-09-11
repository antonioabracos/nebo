#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path

from compiler.api.compiler_api import Compiler, CompilerApiError
from runtime.profile.profile import ArtifactIdentity, AutoTuner, Candidate, Profile, ProfileError, ProfileOptimizer

ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
SOURCE = ROOT / "examples/evolution/g03/numeric-safety-foundation.no"


def main() -> None:
    source_text = SOURCE.read_text(encoding="utf-8")
    identity = ArtifactIdentity(
        hashlib.sha256(source_text.encode()).hexdigest(),
        "neboc 1.0.0", "runtime-v1", "nebo-internal-v1",
        "x86_64-systemv-elf-linux", "baseline",
    )
    profile = Profile.collect(identity, b"workload-v1", {
        "counters": {"cold": 1, "hot": 9}, "seed": 0x4605, "run_count": 3,
    })
    profile.validate_compatibility(identity)
    assert profile.hotFunctions() == ("hot", "cold")
    assert profile.branchProbabilities() == (("cold", "1/10"), ("hot", "9/10"))
    assert profile.callGraph() == (("entry", "cold", 1), ("entry", "hot", 9))
    report = ProfileOptimizer.optimize_with(profile, identity)
    assert "observable-semantics=UNCHANGED" in report and "non-pgo-path=AVAILABLE" in report
    assert "performance-delta=NOT_CLAIMED_DETERMINISTIC" in report
    assert report.report() == str(report)
    with Compiler.new({"neboc": NEBOC, "target": Compiler.TARGET}, frozenset({"compile"})) as compiler:
        compiler.addSource("profiled.no", source_text)
        assert compiler.optimizeWith(profile).report() == report.report()
        incompatible = Profile.collect(
            ArtifactIdentity(**(identity.__dict__ | {"runtime": "wrong"})),
            b"workload-v1", {"counters": {"hot": 1}, "seed": 1, "run_count": 1},
        )
        try:
            compiler.optimizeWith(incompatible)
        except CompilerApiError as error:
            assert error.diagnostic == "NG46_F0502"
        else:
            raise AssertionError("compiler accepted incompatible PGO profile")
    try:
        profile.validate_compatibility(ArtifactIdentity(**(identity.__dict__ | {"abi": "wrong"})))
    except ProfileError as error:
        assert error.diagnostic == "NG46_F0502"
    else:
        raise AssertionError("incompatible profile accepted")
    reference = lambda shape: sum(shape)
    candidates = (
        Candidate("scalar", lambda shape: sum(shape), lambda shape: 10 + len(shape)),
        Candidate("bounded-fast", lambda shape: sum(shape), lambda shape: 3 + len(shape)),
        Candidate("incorrect", lambda shape: sum(shape) + 1, lambda _shape: 1),
    )
    tuner = AutoTuner.new(candidates, "deterministic-local-cost", {"seed": 0x4605, "runs": 4, "reference": reference})
    first = tuner.select((1, 2, 3), identity.target)
    second = tuner.select((1, 2, 3), identity.target)
    assert first == second and first.candidate == "bounded-fast" and first.rejected == ("incorrect",)
    print(f"RF46_G46_F05_ORACLE_GREEN profile={profile.digest()} candidate={first.candidate} rejected={','.join(first.rejected)} runs=4")


if __name__ == "__main__":
    main()
