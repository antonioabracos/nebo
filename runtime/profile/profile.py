"""Local, deterministic RF46 PGO metadata and finite autotuning."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import hashlib
import json
from typing import Callable


class ProfileError(ValueError):
    def __init__(self, diagnostic: str, message: str):
        super().__init__(f"{diagnostic}: {message}")
        self.diagnostic = diagnostic


@dataclass(frozen=True)
class ArtifactIdentity:
    program_digest: str
    compiler: str
    runtime: str
    abi: str
    target: str
    features: str


@dataclass(frozen=True)
class Profile:
    format: str
    identity: ArtifactIdentity
    workload_digest: str
    seed: int
    run_count: int
    counters: tuple[tuple[str, int], ...]
    environment: str = "LOCAL_REDACTED"
    timestamp_policy: str = "OMITTED_DETERMINISTIC"

    @classmethod
    def collect(
        cls, identity: ArtifactIdentity, workload: bytes,
        counters: dict[str, int], *, seed: int, run_count: int,
    ) -> "Profile":
        if len(workload) > 1_048_576 or not 1 <= run_count <= 32 or len(counters) > 256:
            raise ProfileError("NG46_F0501", "profile budget")
        if any(not name or value < 0 or value > 1_000_000 for name, value in counters.items()):
            raise ProfileError("NG46_F0501", "invalid counter")
        return cls(
            "NEBO-PROFILE-V1", identity, hashlib.sha256(workload).hexdigest(), seed,
            run_count, tuple(sorted(counters.items())),
        )

    def validate_compatibility(self, artifact: ArtifactIdentity) -> None:
        if artifact != self.identity:
            raise ProfileError("NG46_F0502", "incompatible artifact/compiler/runtime/ABI/target")

    def hot_functions(self) -> tuple[str, ...]:
        return tuple(name for name, _ in sorted(self.counters, key=lambda item: (-item[1], item[0])))

    def branch_probabilities(self) -> tuple[tuple[str, str], ...]:
        total = sum(value for _, value in self.counters) or 1
        return tuple((name, f"{value}/{total}") for name, value in self.counters)

    def call_graph(self) -> tuple[tuple[str, str, int], ...]:
        return tuple(("entry", name, value) for name, value in self.counters)

    def serialize(self) -> bytes:
        payload = asdict(self)
        return (json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n").encode()

    def digest(self) -> str:
        return hashlib.sha256(self.serialize()).hexdigest()


@dataclass(frozen=True)
class Candidate:
    name: str
    implementation: Callable[[tuple[int, ...]], int]
    deterministic_cost: Callable[[tuple[int, ...]], int]


@dataclass(frozen=True)
class TuningDecision:
    format: str
    candidate: str
    objective: str
    scores: tuple[tuple[str, int], ...]
    rejected: tuple[str, ...]
    seed: int
    target: str
    input_digest: str

    def serialize(self) -> str:
        return json.dumps(asdict(self), sort_keys=True, separators=(",", ":")) + "\n"


class AutoTuner:
    MAX_CANDIDATES = 16
    MAX_RUNS = 32

    def __init__(self, candidates: tuple[Candidate, ...], *, seed: int, run_budget: int):
        if not candidates or len(candidates) > self.MAX_CANDIDATES or not 1 <= run_budget <= self.MAX_RUNS:
            raise ProfileError("NG46_F0501", "autotuning budget")
        if len({candidate.name for candidate in candidates}) != len(candidates):
            raise ProfileError("NG46_F0501", "duplicate candidate")
        self.candidates = tuple(sorted(candidates, key=lambda candidate: candidate.name))
        self.seed = seed
        self.run_budget = run_budget

    def select(
        self, input_shape: tuple[int, ...], target: str,
        reference: Callable[[tuple[int, ...]], int],
    ) -> TuningDecision:
        if target != "x86_64-systemv-elf-linux" or len(input_shape) > 64:
            raise ProfileError("NG46_F0502", "unsupported target or shape")
        expected = reference(input_shape)
        scores = []
        rejected = []
        for candidate in self.candidates:
            if candidate.implementation(input_shape) != expected:
                rejected.append(candidate.name)
                continue
            score_samples = [candidate.deterministic_cost(input_shape) for _ in range(self.run_budget)]
            if any(score < 0 for score in score_samples):
                rejected.append(candidate.name)
                continue
            scores.append((candidate.name, sum(score_samples)))
        if not scores:
            raise ProfileError("NG46_F0503", "no correct candidate")
        winner = min(scores, key=lambda item: (item[1], item[0]))[0]
        digest = hashlib.sha256(json.dumps(input_shape).encode()).hexdigest()
        return TuningDecision("NEBO-AUTOTUNE-V1", winner, "MIN_DETERMINISTIC_LOCAL_COST", tuple(scores), tuple(rejected), self.seed, target, digest)


class ProfileOptimizer:
    @staticmethod
    def optimize_with(profile: Profile, artifact: ArtifactIdentity) -> str:
        profile.validate_compatibility(artifact)
        return (
            "pgo=ADVISORY_LOCAL_V1\n"
            f"profile-sha256={profile.digest()}\n"
            f"hot-functions={','.join(profile.hot_functions())}\n"
            "observable-semantics=UNCHANGED\nnon-pgo-path=AVAILABLE\n"
        )
