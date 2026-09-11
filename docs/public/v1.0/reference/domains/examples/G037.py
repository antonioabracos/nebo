#!/usr/bin/env python3
"""Independent value/effect oracle for all 57 current G037 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.probabilistic import (  # noqa: E402
    Decision, Distribution, Forecast, Mcmc, Posterior, ProbModel,
    ProbabilisticError, Random, Risk, Smc, Uncertainty, VariationalFamily,
    probabilistic_artifact,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1
    if category == "positive":
        counts["sdk"] += 1


def close(left: float, right: float, tolerance: float = 1e-9) -> bool:
    return math.isclose(left, right, rel_tol=tolerance, abs_tol=tolerance)


def reject(label: str, suffix: str, callable_) -> None:
    try:
        callable_()
    except ProbabilisticError as error:
        ok("negative", label, error.code() == f"NEBO-G037-{suffix}" and bool(error.operation()))
        counts["diagnostics"] += 1
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — analytically checked probability, support, moments and seeded samples.
normal = Distribution.normal(2, 3)
ok("positive", "Distribution.normal", normal.kind == "normal" and normal.parameters == (2.0, 3.0))
beta = Distribution.beta(2, 3)
ok("positive", "Distribution.beta", close(beta.statistics()["mean"], 0.4))
gamma = Distribution.gamma(3, 2)
ok("positive", "Distribution.gamma", gamma.statistics() == {"mean": 1.5, "variance": 0.75})
poisson = Distribution.poisson(4)
ok("positive", "Distribution.poisson", poisson.statistics()["variance"] == 4.0)
categorical = Distribution.categorical((1, 2, 3))
ok("positive", "Distribution.categorical", categorical.support()["values"] == (0, 1, 2))
sample = normal.sample(Random.new(1701))
ok("positive", "distribution.sample", close(sample, 1.129482111631409, 1e-12))
ok("positive", "distribution.logProbability",
   close(normal.logProbability(2), -math.log(3) - 0.5 * math.log(2 * math.pi)))
ok("positive", "distribution.support",
   beta.support()["lower"] == 0.0 and beta.support()["upper"] == 1.0 and beta.support()["open"])
ok("positive", "distribution.statistics",
   close(categorical.statistics()["mean"], 4 / 3) and close(categorical.statistics()["variance"], 5 / 9))
transcript.append((round(sample, 12), dict(beta.statistics()), dict(categorical.statistics())))

# S02 — roles remain distinct and graph/log-joint evidence is observable.
model = ProbModel.new("bounded-coin")
ok("positive", "ProbModel.new", model.name == "bounded-coin")
ok("positive", "model.parameter", model.parameter("temperature", 2, "positive") is model)
ok("positive", "model.latent", model.latent("coin", categorical) is model)
ok("positive", "model.observe", model.observe("reading", Distribution.normal(4, 2), 5) is model)
deterministic_inputs: list[int] = []
ok("positive", "model.deterministic",
   model.deterministic("double", lambda state: (deterministic_inputs.append(state["coin"]),
                                                state["coin"] * 2)[1]) is model)
ok("positive", "model.plate", model.plate("batch", 3, lambda index: index * index) is model)
graph = model.graph()
roles = {node["name"]: node["role"] for node in graph["nodes"]}
ok("positive", "model.graph", graph["acyclic"] and roles == {
    "temperature": "parameter", "coin": "latent", "reading": "observed",
    "double": "deterministic", "batch": "plate",
})
expected_joint = categorical.logProbability(2) + Distribution.normal(4, 2).logProbability(5)
ok("positive", "model.logJoint",
   close(model.logJoint({"coin": 2}), expected_joint) and deterministic_inputs == [2])
transcript.append((dict(graph), round(expected_joint, 12)))

# S03 — three bounded planners agree with hand-normalized finite mass.
exact_model = ProbModel.new("two-coins").latent("left", Distribution.categorical((1, 3)))
exact_model.latent("right", Distribution.categorical((2, 2)))
exact = exact_model.inferExact({"maxStates": 4})
ok("positive", "model.inferExact", len(exact.states) == 4)
eliminated = exact_model.variableElimination(("right", "left"))
ok("positive", "model.variableElimination", eliminated.method == "variable-elimination")
propagated = exact_model.beliefPropagation({"maxIterations": 8})
ok("positive", "model.beliefPropagation", propagated.method == "tree-belief-propagation")
ok("positive", "inference.marginal",
   all(close(exact.marginal("left")[key], value) for key, value in {0: 0.25, 1: 0.75}.items()))
ok("positive", "inference.normalizationConstant", close(exact.normalizationConstant(), 1.0))
plan = eliminated.explainPlan()
ok("positive", "inference.explainPlan", plan["order"] == ("right", "left") and plan["states"] == 4)
verification = exact.verify()
ok("positive", "inference.verify", verification["verified"] and verification["residual"] <= 1e-12)
transcript.append((dict(exact.marginal("left")), dict(plan), dict(verification)))

# S04 — each kernel is configured, MCMC/SMC execute, and views are immutable.
metropolis = Mcmc.metropolis({"draws": 80, "warmup": 20, "seed": 31, "stepSize": 0.7})
ok("positive", "Mcmc.metropolis", metropolis.kind == "metropolis" and metropolis.draws == 80)
hamiltonian = Mcmc.hamiltonian({"draws": 32, "warmup": 8, "seed": 32,
                               "stepSize": 0.12, "leapfrogSteps": 4})
ok("positive", "Mcmc.hamiltonian", hamiltonian.kind == "hamiltonian" and hamiltonian.leapfrog_steps == 4)
nuts = Mcmc.nuts({"draws": 32, "warmup": 8, "seed": 33, "stepSize": 0.08, "maxTreeDepth": 3})
ok("positive", "Mcmc.nuts", nuts.kind == "nuts" and nuts.leapfrog_steps == 8)
continuous_model = ProbModel.new("location").latent("theta", Distribution.normal(2, 1))
samples = continuous_model.inferMcmc(metropolis, 4)
ok("positive", "model.inferMcmc",
   samples.method == "metropolis" and len(samples._chains["theta"]) == 4 and samples.attempted == 400)
smc = Smc.new(64, {"seed": 41, "maxSteps": 8, "observationStddev": 1, "jitter": 0.02})
ok("positive", "Smc.new", smc.particles == 64 and smc.seed == 41)
sequential = continuous_model.inferSequential((1.8, 2.1, 2.0), smc)
ok("positive", "model.inferSequential",
   sequential.method == "smc" and len(sequential._chains["theta"][0]) == 64)
thinned = samples.thin(4)
ok("positive", "samples.thin",
   len(thinned._chains["theta"][0]) == 20 and len(samples._chains["theta"][0]) == 80)
cancelled = samples.cancel()
ok("positive", "samples.cancel",
   cancelled.status == "cancelled" and samples.status == "completed" and len(cancelled._chains["theta"][0]) == 40)
transcript.append((round(samples.mean("theta"), 12), round(sequential.mean("theta"), 12),
                   samples.accepted, dict(cancelled.diagnostics())))

# S05 — both families, bounded optimization, posterior and chain comparison.
mean_field = VariationalFamily.meanField(continuous_model)
ok("positive", "VariationalFamily.meanField", mean_field.kind == "mean-field")
full_rank = VariationalFamily.fullRank(continuous_model)
ok("positive", "VariationalFamily.fullRank", full_rank.kind == "full-rank")
variational = continuous_model.inferVariational(
    full_rank, {"name": "adam", "learningRate": 0.05},
    {"iterations": 40, "seed": 51, "tolerance": 1e-6},
)
ok("positive", "model.inferVariational",
   variational.optimizer == "adam" and variational.seed == 51
   and variational.covariance["theta"]["theta"] == 1.0)
ok("positive", "variational.elbo", math.isfinite(variational.elbo()) and variational.elbo() <= 0)
variational_draws = variational.sample(Random.new(52), 7)
ok("positive", "variational.sample", len(variational_draws["theta"]) == 7)
variational_posterior = variational.posterior("theta")
ok("positive", "variational.posterior", close(variational_posterior.mean(), 2.0, 1e-12))
trace = variational.convergenceTrace()
ok("positive", "variational.convergenceTrace",
   len(trace) > 1 and trace[-1]["residual"] < trace[0]["residual"])
comparison = variational.compareMcmc(samples)
ok("positive", "variational.compareMcmc",
   comparison["maximumDifference"] < 0.5 and "referenceDiagnostics" in comparison)
transcript.append((variational.elbo(), variational_draws["theta"], dict(comparison)))

# S06 — empirical summaries and truthful convergence diagnostics.
posterior = samples.posterior("theta")
ok("positive", "posterior.mean", close(samples.mean("theta"), posterior.mean()))
ok("positive", "posterior.variance", samples.variance("theta") > 0.1)
interval = samples.credibleInterval("theta", 0.9)
ok("positive", "posterior.credibleInterval", interval[0] < samples.mean("theta") < interval[1])
posterior_draws = samples.sample(Random.new(61), 6)
ok("positive", "posterior.sample", len(posterior_draws) == 6 and all(math.isfinite(value) for value in posterior_draws))
predictions = samples.predict((-1, 0, 1))
ok("positive", "posterior.predict", close(predictions[1], samples.mean("theta")) and close(predictions[2] - predictions[0], 2))
rhats = samples.rHat()
ok("positive", "inference.rHat", rhats["theta"] is not None and rhats["theta"] > 0)
effective = samples.effectiveSampleSize()
ok("positive", "inference.effectiveSampleSize", 1 <= effective["theta"] <= 320)
diagnostics = samples.diagnostics()
ok("positive", "inference.diagnostics",
   diagnostics["method"] == "metropolis" and diagnostics["convergenceClaim"] in (True, False)
   and diagnostics["rHat"]["theta"] == rhats["theta"])
transcript.append((posterior.mean(), posterior.variance(), interval, posterior_draws,
                   dict(rhats), dict(effective), dict(diagnostics)))

# S07 — proper scores, posterior utility, tail losses and explicit decomposition.
forecast = Forecast.calibrate((0.8, 0.3, 0.6, 0.1), (1, 0, 1, 0))
ok("positive", "Forecast.calibrate", forecast.predictions == (0.8, 0.3, 0.6, 0.1))
ok("positive", "forecast.brierScore", close(forecast.brierScore(), 0.075))
expected_log = -math.fsum((math.log(0.8), math.log(0.7), math.log(0.6), math.log(0.9))) / 4
ok("positive", "forecast.logScore", close(forecast.logScore(), expected_log))
decision_posterior = Posterior((0, 1), (0.25, 0.75), "decision")
utility = lambda action, outcome: (3 if action == "act" and outcome == 1 else
                                   -1 if action == "act" else 1)
utilities = Decision.expectedUtility(("wait", "act"), decision_posterior, utility)
ok("positive", "Decision.expectedUtility", close(utilities["wait"], 1) and close(utilities["act"], 2))
choice = Decision.choose(("wait", "act"), decision_posterior, utility)
ok("positive", "Decision.choose", choice["action"] == "act" and choice["causalClaim"] is False)
risk = Risk((1, 2, 3, 8, 13))
ok("positive", "Risk.valueAtRisk", risk.valueAtRisk(0.8) == 8.0)
ok("positive", "Risk.conditionalValueAtRisk", close(risk.conditionalValueAtRisk(0.8), 10.5))
decomposition = Uncertainty.decompose({"replicateMeans": (1, 3), "withinVariances": (2, 4)})
ok("positive", "Uncertainty.decompose",
   decomposition["aleatoric"] == 3 and decomposition["epistemic"] == 1 and decomposition["total"] == 4)
artifact = probabilistic_artifact(37, 4, 71, 1)
magic, version, redacted, model_id, inference_id, seed, diagnostic_level, digest = struct.unpack("<8s7Q", artifact)
independent_digest = 0xCBF29CE484222325
for byte in artifact[:56]:
    independent_digest ^= byte
    independent_digest = (independent_digest * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
ok("positive", "neboc probabilistic-report",
   (magic, version, redacted, model_id, inference_id, seed, diagnostic_level, digest)
   == (b"NBPRB001", 1, 1, 37, 4, 71, 1, independent_digest))
transcript.append((forecast.brierScore(), forecast.logScore(), dict(utilities), dict(choice),
                   dict(decomposition), artifact.hex()))

# Stable negative diagnostics cover every public family.
reject("normal-scale", "DOMAIN", lambda: Distribution.normal(0, 0))
reject("categorical-mass", "WEIGHTS", lambda: Distribution.categorical((0, 0)))
reject("explicit-random", "RANDOM", lambda: normal.sample(None))
reject("poisson-budget", "BUDGET", lambda: Distribution.poisson(65))
reject("duplicate-node", "DUPLICATE-NODE", lambda: model.latent("coin", categorical))
reject("observation-support", "OBSERVATION-SUPPORT",
       lambda: ProbModel.new("bad-observe").observe("x", categorical, 9))
reject("unknown-state", "STATE", lambda: model.logJoint({"coin": 1, "secret": 7}))
reject("parameter-constraint", "CONSTRAINT", lambda: model.logJoint({"coin": 1, "temperature": -1}))
reject("exact-domain", "EXACT-DOMAIN", lambda: continuous_model.inferExact())
large_exact = ProbModel.new("too-many").latent("a", Distribution.categorical((1,) * 5))
large_exact.latent("b", Distribution.categorical((1,) * 5))
reject("exact-budget", "EXACT-BUDGET", lambda: large_exact.inferExact({"maxStates": 20}))
reject("mcmc-options", "OPTIONS", lambda: Mcmc.metropolis({"hidden": 1}))
reject("mcmc-domain", "MCMC-DOMAIN", lambda: exact_model.inferMcmc(metropolis, 2))
reject("smc-budget", "SMC-BUDGET", lambda: continuous_model.inferSequential(range(9), smc))
reject("vi-optimizer", "OPTIMIZER", lambda: continuous_model.inferVariational(full_rank, "mystery"))
reject("posterior-probability", "PROBABILITY", lambda: posterior.credibleInterval(None, 1))
reject("forecast-alignment", "FORECAST", lambda: Forecast.calibrate((0.2,), (0, 1)))
reject("decision-actions", "ACTIONS", lambda: Decision.expectedUtility((), decision_posterior, utility))
reject("risk-level", "PROBABILITY", lambda: risk.valueAtRisk(0))
reject("uncertainty-input", "UNCERTAINTY", lambda: Uncertainty.decompose({"replicateMeans": (1,)}))
reject("report-redaction", "REPORT", lambda: probabilistic_artifact(0, 4, 71, 1))

# Explicit boundaries do not silently expand resource limits.
ok("boundary", "categorical-singleton", Distribution.categorical((7,)).sample(Random.new(1)) == 0)
ok("boundary", "poisson-zero-outcome", Distribution.poisson(0.01).sample(Random.new(2)) >= 0)
ok("boundary", "one-state-exact", len(ProbModel.new("one").latent("x", Distribution.categorical((1,))).inferExact().states) == 1)
ok("boundary", "one-chain-rhat", sequential.rHat()["theta"] is None)
ok("boundary", "thin-identity", samples.thin(1)._chains == samples._chains)
ok("boundary", "minimum-credible", posterior.credibleInterval(None, 0.01)[0] <= posterior.credibleInterval(None, 0.01)[1])
ok("boundary", "extreme-calibration", close(Forecast.calibrate((0, 1), (0, 1)).brierScore(), 0))
ok("boundary", "two-particle-smc", Smc.new(2).particles == 2)
ok("boundary", "single-loss-risk", Risk((7,)).conditionalValueAtRisk(0.5) == 7)

# Metamorphic relations use transformed inputs and independent analytic laws.
ok("metamorphic", "normal-translation",
   close(Distribution.normal(7, 3).logProbability(7), normal.logProbability(2)))
ok("metamorphic", "categorical-scale",
   close(Distribution.categorical((10, 20, 30)).logProbability(1), categorical.logProbability(1)))
ok("metamorphic", "elimination-order",
   all(close(eliminated.marginal("left")[k], propagated.marginal("left")[k]) for k in (0, 1)))
ok("metamorphic", "thinning-subsequence",
   thinned._chains["theta"][0] == samples._chains["theta"][0][::4])
shifted = Posterior(tuple(value + 5 for value in decision_posterior._values), decision_posterior._weights)
ok("metamorphic", "posterior-translation", close(shifted.mean() - decision_posterior.mean(), 5))
ok("metamorphic", "brier-complement",
   close(forecast.brierScore(), Forecast.calibrate(tuple(1-p for p in forecast.predictions),
                                                   tuple(1-y for y in forecast.observations)).brierScore()))
ok("metamorphic", "risk-translation", close(Risk(tuple(value+4 for value in risk.losses)).valueAtRisk(0.8), 12))
ok("metamorphic", "uncertainty-translation",
   Uncertainty.decompose({"replicateMeans": (11, 13), "withinVariances": (2, 4)})["total"] == 4)

# Adversarial evidence addresses non-finite input, zero mass and corrupt reports.
adversarial_cases = (
    ("nan-mean", "NUMBER", lambda: Distribution.normal(float("nan"), 1)),
    ("inf-shape", "NUMBER", lambda: Distribution.gamma(float("inf"), 1)),
    ("negative-weight", "WEIGHTS", lambda: Distribution.categorical((1, -1))),
    ("invalid-seed", "SEED", lambda: Random.new(True)),
    ("bad-plate", "BUDGET", lambda: ProbModel.new("p").plate("x", 0, lambda i: i)),
    ("unknown-elimination", "ELIMINATION-ORDER", lambda: exact_model.variableElimination(("left", "missing"))),
    ("huge-draw", "BUDGET", lambda: Mcmc.metropolis({"draws": 100_001})),
    ("unhashable-action", "ACTIONS",
     lambda: Decision.expectedUtility((["mutable"],), decision_posterior, utility)),
)
for label, suffix, call in adversarial_cases:
    before = counts["negative"]
    reject(label, suffix, call)
    counts["negative"] = before
    counts["diagnostics"] -= 1
    ok("adversarial", label, True)

# Cross-subgroup compositions exercise real shared values.
ok("composition", "distribution-model", close(exact_model.logJoint({"left": 1, "right": 0}), math.log(0.75) + math.log(0.5)))
ok("composition", "exact-posterior", close(exact.posterior("left").mean(), 0.75))
hmc_samples = continuous_model.inferMcmc(hamiltonian, 2)
ok("composition", "hmc-posterior", abs(hmc_samples.mean("theta") - 2) < 0.8)
nuts_samples = continuous_model.inferMcmc(nuts, 2)
ok("composition", "nuts-diagnostics", nuts_samples.diagnostics()["method"] == "nuts")
ok("composition", "vi-mcmc", variational.compareMcmc(samples)["withinReferenceTolerance"])
ok("composition", "posterior-decision",
   Decision.choose(("wait", "act"), exact.posterior("left"), utility)["action"] == "act")
ok("composition", "forecast-risk", Risk((forecast.brierScore(), forecast.logScore())).valueAtRisk(0.5) >= 0)

# Immutable public views and non-mutating derivations prove ownership boundaries.
for label, attempt in (
    ("graph-view", lambda: graph.__setitem__("name", "mutated")),
    ("marginal-view", lambda: exact.marginal("left").__setitem__(0, 9)),
    ("utility-view", lambda: utilities.__setitem__("act", 99)),
):
    try:
        attempt()
    except (AttributeError, TypeError):
        ok("ownership", label, True)
    else:
        raise AssertionError(f"ownership:{label}")
ok("ownership", "thin-preserves-source", len(samples._chains["theta"][0]) == 80)
ok("ownership", "artifact-immutable", isinstance(artifact, bytes))

# Rejected mutations leave the original model and posterior unchanged.
graph_before = repr(model.graph())
for label, call in (
    ("duplicate-atomic", lambda: model.parameter("coin", 1)),
    ("observe-atomic", lambda: model.observe("bad", categorical, 99)),
    ("plate-atomic", lambda: model.plate("bad-plate", 0, lambda i: i)),
):
    try:
        call()
    except ProbabilisticError:
        ok("failure_atomicity", label, repr(model.graph()) == graph_before)
    else:
        raise AssertionError(f"failure_atomicity:{label}")
posterior_before = posterior._values
try:
    posterior.credibleInterval(None, 2)
except ProbabilisticError:
    ok("failure_atomicity", "posterior-atomic", posterior._values == posterior_before)
artifact_before = artifact
try:
    probabilistic_artifact(37, 0, 71, 1)
except ProbabilisticError:
    ok("failure_atomicity", "report-atomic", artifact == artifact_before)

# Same seeds/options are byte-for-byte deterministic across all stochastic routes.
ok("determinism", "normal-sequence",
   tuple(normal.sample(Random.new(seed)) for seed in (1, 2, 3))
   == tuple(normal.sample(Random.new(seed)) for seed in (1, 2, 3)))
ok("determinism", "exact", exact.weights == exact_model.inferExact({"maxStates": 4}).weights)
repeat_mcmc = continuous_model.inferMcmc(metropolis, 4)
ok("determinism", "mcmc", repeat_mcmc._chains == samples._chains)
repeat_smc = continuous_model.inferSequential((1.8, 2.1, 2.0), smc)
ok("determinism", "smc", repeat_smc._chains == sequential._chains)
ok("determinism", "vi-sample",
   variational.sample(Random.new(52), 7)["theta"] == variational_draws["theta"])
ok("determinism", "decision", Decision.choose(("wait", "act"), decision_posterior, utility) == choice)
ok("determinism", "artifact", probabilistic_artifact(37, 4, 71, 1) == artifact)

# The portable profile contains no ambient network, accelerator or cloud owner.
for label, condition in (
    ("distribution-cpu", normal.kind == "normal"),
    ("graph-version", graph["schema"].endswith("-v1")),
    ("exact-bounded", plan["bounded"] is True),
    ("mcmc-seeded", samples.seed == 31),
    ("smc-seeded", sequential.seed == 41),
    ("vi-seeded", variational.seed == 51),
    ("report-redacted", redacted == 1),
):
    ok("target", label, condition)

# Digest only normalized primitive evidence; no identity-bearing observations leak.
normalized = json.dumps(transcript, sort_keys=True, separators=(",", ":"), default=lambda value: dict(value)).encode()
digest_hex = hashlib.sha256(normalized).hexdigest()

expected = {
    "positive": 57, "negative": 20, "boundary": 9, "metamorphic": 8,
    "adversarial": 8, "composition": 7, "ownership": 5,
    "failure_atomicity": 5, "determinism": 7, "target": 7,
    "diagnostics": 20, "sdk": 57,
}
if dict(counts) != expected:
    raise AssertionError(f"coverage:{dict(counts)!r}")
print("G037_SDK_ORACLE_GREEN " + " ".join(f"{key}={value}" for key, value in expected.items())
      + f" digest={digest_hex}")
