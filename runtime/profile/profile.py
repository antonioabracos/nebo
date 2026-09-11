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
        cls, program: ArtifactIdentity, workload: bytes, options: dict[str, object],
    ) -> "Profile":
        counters = options.get("counters")
        seed = options.get("seed")
        run_count = options.get("run_count")
        if not isinstance(counters, dict) or not isinstance(seed, int) or not isinstance(run_count, int):
            raise ProfileError("NG46_F0501", "invalid profile collection options")
        if any(not isinstance(name, str) or not isinstance(value, int) for name, value in counters.items()):
            raise ProfileError("NG46_F0501", "invalid counter")
        if len(workload) > 1_048_576 or not 1 <= run_count <= 32 or len(counters) > 256:
            raise ProfileError("NG46_F0501", "profile budget")
        if any(not name or value < 0 or value > 1_000_000 for name, value in counters.items()):
            raise ProfileError("NG46_F0501", "invalid counter")
        return cls(
            "NEBO-PROFILE-V1", program, hashlib.sha256(workload).hexdigest(), seed,
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

    hotFunctions = hot_functions
    branchProbabilities = branch_probabilities
    callGraph = call_graph
    validateCompatibility = validate_compatibility


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

    @classmethod
    def new(cls, candidates: tuple[Candidate, ...], benchmark: str, budgets: dict[str, object]) -> "AutoTuner":
        if benchmark != "deterministic-local-cost":
            raise ProfileError("NG46_F0501", "unsupported benchmark objective")
        seed = budgets.get("seed", 0)
        runs = budgets.get("runs", 0)
        reference = budgets.get("reference")
        if not isinstance(seed, int) or not isinstance(runs, int) or not callable(reference):
            raise ProfileError("NG46_F0501", "invalid autotuning budgets or reference")
        return cls(candidates, seed=seed, run_budget=runs, reference=reference)

    def __init__(
        self, candidates: tuple[Candidate, ...], *, seed: int, run_budget: int,
        reference: Callable[[tuple[int, ...]], int] | None = None,
    ):
        if not candidates or len(candidates) > self.MAX_CANDIDATES or not 1 <= run_budget <= self.MAX_RUNS:
            raise ProfileError("NG46_F0501", "autotuning budget")
        if len({candidate.name for candidate in candidates}) != len(candidates):
            raise ProfileError("NG46_F0501", "duplicate candidate")
        self.candidates = tuple(sorted(candidates, key=lambda candidate: candidate.name))
        self.seed = seed
        self.run_budget = run_budget
        self.reference = reference

    def select(
        self, input_shape: tuple[int, ...], target: str,
        reference: Callable[[tuple[int, ...]], int] | None = None,
    ) -> TuningDecision:
        if target != "x86_64-systemv-elf-linux" or len(input_shape) > 64:
            raise ProfileError("NG46_F0502", "unsupported target or shape")
        oracle = reference or self.reference
        if oracle is None:
            raise ProfileError("NG46_F0501", "correctness reference missing")
        expected = oracle(input_shape)
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
    def optimize_with(profile: Profile, artifact: ArtifactIdentity) -> "PgoOptimization":
        profile.validate_compatibility(artifact)
        return PgoOptimization(
            "pgo=ADVISORY_LOCAL_V1\n"
            f"profile-sha256={profile.digest()}\n"
            f"hot-functions={','.join(profile.hot_functions())}\n"
            "observable-semantics=UNCHANGED\n"
            "performance-delta=NOT_CLAIMED_DETERMINISTIC\n"
            "non-pgo-path=AVAILABLE\n"
        )

    optimizeWith = optimize_with


@dataclass(frozen=True)
class PgoOptimization:
    text: str

    def report(self) -> str:
        return self.text

    def __contains__(self, item: str) -> bool:
        return item in self.text

    def __str__(self) -> str:
        return self.text
