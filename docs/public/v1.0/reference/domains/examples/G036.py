#!/usr/bin/env python3
"""Independent value/effect oracle for all 57 current G036 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT_PATH = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT_PATH))

from compiler.sdk.scientific import (  # noqa: E402
    Boundary, ContinuousOptimizer, Fft, Grid, Integrate, OdeMethod, OdeProblem,
    PdeProblem, Root, ScientificContext, ScientificError, Signal, SparseMatrix,
    SparseVector, WindowFunction, numeric_report, scientific_bench,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def close(left: float, right: float, tolerance: float = 1e-8) -> bool:
    return math.isclose(left, right, rel_tol=tolerance, abs_tol=tolerance)


def reject(label: str, code: str, callable_) -> None:
    try:
        callable_()
    except ScientificError as error:
        ok("negative", label, error.code() == code and bool(error.operation()))
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — sparse values, canonical representations and explicit densification.
vector = SparseVector.fromIndices(3, (0, 2), (4, 6))
ok("positive", "SparseVector.fromIndices", vector.dense() == (4.0, 0.0, 6.0))
csr = SparseMatrix.csr(2, 3, (0, 2, 3), (0, 2, 1), (1, 2, 3))
ok("positive", "SparseMatrix.csr", csr.toDense(6) == ((1.0, 0.0, 2.0), (0.0, 3.0, 0.0)))
csc = SparseMatrix.csc(2, 3, (0, 1, 2, 3), (0, 1, 0), (1, 3, 2))
ok("positive", "SparseMatrix.csc", csc.toDense(6) == csr.toDense(6) and csc.storage == "csc")
ok("positive", "sparse.nonZeroCount", csr.nonZeroCount() == 3)
ok("positive", "sparse.density", csr.density() == 0.5)
transposed = csr.transpose()
ok("positive", "sparse.transpose", transposed.toDense(6) == ((1.0, 0.0), (0.0, 3.0), (2.0, 0.0)))
product = csr.matmul((4, 5, 6))
ok("positive", "sparse.matmul", product == (16.0, 15.0))
ok("positive", "sparse.toDense", csr.toDense(6)[1][1] == 3.0)
invariants = csr.validateInvariants()
ok("positive", "sparse.validateInvariants", invariants["valid"] and invariants["nonZeroCount"] == 3)
transcript.append((product, csr.toDense(6), transposed.storage))

# S02 — scalar DFT, inverse identity, signal operations and Hann endpoints.
plan = Fft.plan(4, "both", {"normalization": "inverse"})
ok("positive", "Fft.plan", plan.length == 4 and plan.direction == "both")
spectrum = plan.forward((1, 2, 3, 4))
ok("positive", "fft.forward", close(spectrum[0].real, 10) and close(spectrum[1].imag, 2))
restored = plan.inverse(spectrum)
ok("positive", "fft.inverse", all(close(value.real, expected) and close(value.imag, 0)
                                    for value, expected in zip(restored, (1, 2, 3, 4))))
signal = Signal((1, 2, 3))
ok("positive", "signal.convolve", signal.convolve((2, 1), "full") == (2.0, 5.0, 8.0, 3.0))
ok("positive", "signal.correlate", signal.correlate((2, 1), "full") == (1.0, 4.0, 7.0, 6.0))
ok("positive", "signal.autocorrelation", signal.autocorrelation() == (3.0, 8.0, 14.0, 8.0, 3.0))
magnitudes = spectrum.magnitude()
ok("positive", "spectrum.magnitude", close(magnitudes[0], 10) and close(magnitudes[2], 2))
powers = spectrum.power()
ok("positive", "spectrum.power", close(powers[0], 100) and close(powers[2], 4))
hann = WindowFunction.hann(5)
ok("positive", "WindowFunction.hann", hann[0] == hann[-1] == 0.0 and close(hann[2], 1))
transcript.append(([round(value.real, 12) for value in spectrum], powers, hann))

# S03 — three root strategies and four quadrature policies publish errors.
bisection = Root.bisection(lambda x: x*x - 2, (0, 2), 1e-10)
ok("positive", "Root.bisection", close(bisection.value, math.sqrt(2), 1e-9))
brent = Root.brent(lambda x: x*x - 2, (0, 2), 1e-10)
ok("positive", "Root.brent", close(brent.value, math.sqrt(2), 1e-9))
newton = Root.newton(lambda x: x*x - 2, lambda x: 2*x, 1.0)
ok("positive", "Root.newton", close(newton.value, math.sqrt(2), 1e-10))
trapezoid = Integrate.trapezoid(lambda x: x*x, (0, 1), 100)
ok("positive", "Integrate.trapezoid", close(trapezoid.value, 1/3, 2e-5))
simpson = Integrate.simpson(lambda x: x*x, (0, 1), 10)
ok("positive", "Integrate.simpson", close(simpson.value, 1/3, 1e-12))
adaptive = Integrate.adaptive(math.sin, (0, math.pi), 1e-9)
ok("positive", "Integrate.adaptive", close(adaptive.value, 2.0, 1e-9))
multi = Integrate.multiDimensional(lambda point: point[0] + point[1], ((0, 1), (0, 1)), {"steps": 8})
ok("positive", "Integrate.multiDimensional", close(multi.value, 1.0, 1e-12))
ok("positive", "numericResult.errorEstimate", 0 <= adaptive.errorEstimate() <= 1e-9)
transcript.append((bisection.value, brent.value, newton.value,
                   trapezoid.value, simpson.value, adaptive.value, multi.value))

# S04 — fixed/adaptive RK, directed events, interpolation and error evidence.
problem = OdeProblem.define((1.0,), lambda _time, state: (state[0],), (0.0, 1.0))
ok("positive", "OdeProblem.define", problem.initial == (1.0,) and problem.interval == (0.0, 1.0))
problem.event(lambda _time, state: state[0] - 2.0, 1)
fixed_method = OdeMethod.rk4(0.05)
ok("positive", "OdeMethod.rk4", fixed_method.kind == "rk4" and fixed_method.step == 0.05)
adaptive_method = OdeMethod.adaptiveRk({"initialStep": 0.2, "maximumStep": 0.25})
ok("positive", "OdeMethod.adaptiveRk", adaptive_method.kind == "adaptive-rk4")
ok("positive", "ode.event", len(problem._events) == 1)
trajectory = problem.solve(fixed_method, {"maxSteps": 100})
ok("positive", "ode.solve", close(trajectory.sample(1)[0], math.e, 2e-6))
ok("positive", "trajectory.sample", close(trajectory.sample(0.5)[0], math.exp(0.5), 1e-6))
ok("positive", "trajectory.steps", trajectory.steps() == 20)
ode_report = trajectory.errorReport()
ok("positive", "trajectory.errorReport", ode_report["acceptedSteps"] == 20 and len(ode_report["events"]) == 1)
transcript.append((trajectory.sample(0.5), trajectory.sample(1), dict(ode_report)))

# S05 — uniform coordinates, both boundary kinds, Jacobi solve and derivatives.
grid = Grid.uniform((0, 1), (17,))
ok("positive", "Grid.uniform", grid.shape == (17,))
coordinates = grid.coordinates()
ok("positive", "Grid.coordinates", len(coordinates) == 17 and coordinates[8] == 0.5)
lower = Boundary.dirichlet("lower", 0)
ok("positive", "Boundary.dirichlet", lower.kind == "dirichlet" and lower.value == 0)
flux = Boundary.neumann("upper", 0)
ok("positive", "Boundary.neumann", flux.kind == "neumann" and flux.value == 0)
pde = PdeProblem.define(lambda _x: 2.0, grid, (lower, Boundary.dirichlet("upper", 0)))
ok("positive", "PdeProblem.define", pde.grid is grid and len(pde.boundaries) == 2)
field = pde.solve("jacobi", {"tolerance": 1e-10, "maxIterations": 10000})
ok("positive", "pde.solve", field.status == "converged" and close(field.values[8], 0.25, 1e-7))
gradient = field.gradient()
ok("positive", "field.gradient", close(gradient[8], 0.0, 1e-7))
laplacian = field.laplacian()
ok("positive", "field.laplacian", close(laplacian[8], -2.0, 1e-6))
transcript.append((field.values[8], gradient[8], laplacian[8], field.residual))

# S06 — all optimizer families plus explicit bounds, constraints and reports.
objective = lambda point: ((point[0] - 3)**2 + (point[1] + 2)**2,
                           (2*(point[0] - 3), 2*(point[1] + 2)))
gradient_config = ContinuousOptimizer.gradientDescent({"learningRate": 0.2})
ok("positive", "ContinuousOptimizer.gradientDescent", gradient_config.kind == "gradientDescent")
lbfgs_config = ContinuousOptimizer.lbfgs({"learningRate": 0.5})
ok("positive", "ContinuousOptimizer.lbfgs", lbfgs_config.kind == "lbfgs")
adam_config = ContinuousOptimizer.adam({"learningRate": 0.2})
ok("positive", "ContinuousOptimizer.adam", adam_config.kind == "adam")
bounded = gradient_config.bounds((-5, -5), (5, 5))
ok("positive", "optimizer.bounds", bounded.lower == (-5.0, -5.0) and bounded.upper == (5.0, 5.0))
constrained = bounded.constraints((lambda point: (point[0] - 4, (1, 0)),))
ok("positive", "optimizer.constraints", len(constrained._constraints) == 1)
solution = constrained.minimize(objective, (0, 0))
ok("positive", "optimizer.minimize", solution.status == "converged" and close(solution.point[0], 3, 1e-6))
ok("positive", "solution.gradientNorm", solution.gradientNorm() < 1e-7)
optimality = solution.optimalityReport()
ok("positive", "solution.optimalityReport", optimality["status"] == "converged" and optimality["method"] == "gradientDescent")
transcript.append((solution.point, dict(optimality)))

# S07 — versioned context, generic result evidence and the two CLI algorithms.
context = ScientificContext.new({"absoluteTolerance": 1e-10})
ok("positive", "ScientificContext.new", context.manifest()["threads"] == 1)
manifest = solution.reproducibilityManifest()
ok("positive", "result.reproducibilityManifest", manifest["schema"] == "nebo-scientific-result-v1" and len(manifest["payloadSha256"]) == 64)
comparison = solution.compare(solution, {"absolute": 0, "relative": 0})
ok("positive", "result.compare", comparison["passed"] and comparison["maximumError"] == 0)
trace = solution.convergenceTrace()
ok("positive", "solver.convergenceTrace", len(trace) > 1 and trace[-1]["gradientNorm"] < trace[0]["gradientNorm"])
checkpoint = solution.checkpoint()
ok("positive", "solver.checkpoint", json.loads(checkpoint)["schema"] == "nebo-scientific-checkpoint-v1")
benchmark = scientific_bench("core")
ok("positive", "neboc scientific-bench", benchmark["schema"] == "nebo-scientific-bench-v1" and len(benchmark["sha256"]) == 64)
report = numeric_report(benchmark)
ok("positive", "neboc numeric-report", report["status"] == "valid" and report["totalWorkUnits"] > 0)
transcript.append((dict(context.manifest()), dict(manifest), dict(report)))

# Negative diagnostics cover every algorithm family and leave owned inputs intact.
reject("sparse-duplicate", "NEBO-G036-SPARSE-INDEX",
       lambda: SparseVector.fromIndices(3, (1, 1), (2, 3)))
reject("sparse-offset", "NEBO-G036-SPARSE-OFFSETS",
       lambda: SparseMatrix.csr(2, 2, (0, 2), (0, 1), (2, 3)))
reject("densify-limit", "NEBO-G036-DENSIFY-LIMIT", lambda: csr.toDense(5))
reject("sparse-shape", "NEBO-G036-SHAPE", lambda: csr.matmul((1, 2)))
reject("fft-length", "NEBO-G036-BUDGET", lambda: Fft.plan(65))
reject("signal-mode", "NEBO-G036-SIGNAL-MODE", lambda: signal.convolve((1,), "circular"))
reject("root-bracket", "NEBO-G036-ROOT-BRACKET",
       lambda: Root.bisection(lambda x: x*x + 1, (-1, 1), 1e-6))
reject("newton-derivative", "NEBO-G036-ROOT-DERIVATIVE",
       lambda: Root.newton(lambda x: x*x + 1, lambda _x: 0, 1))
reject("simpson-odd", "NEBO-G036-SIMPSON-STEPS",
       lambda: Integrate.simpson(lambda x: x, (0, 1), 3))
reject("integral-rank", "NEBO-G036-INTEGRAL-DOMAIN",
       lambda: Integrate.multiDimensional(lambda point: sum(point), ((0, 1),)*4))
reject("ode-shape", "NEBO-G036-ODE-SHAPE",
       lambda: OdeProblem.define((1,), lambda _t, _y: (1, 2), (0, 1)).solve(OdeMethod.rk4(0.1)))
reject("ode-direction", "NEBO-G036-ODE-EVENT", lambda: problem.event(lambda _t, _y: 0, 2))
reject("grid-rank", "NEBO-G036-GRID-RANK", lambda: Grid.uniform(((0, 1),)*3, (3, 3, 3)))
reject("pde-boundary", "NEBO-G036-PDE-BOUNDARY",
       lambda: PdeProblem.define(lambda _x: 0, grid, (flux,)).solve())
reject("optimizer-options", "NEBO-G036-OPTIMIZER-OPTIONS",
       lambda: ContinuousOptimizer.adam({"mystery": 1}))
reject("objective-shape", "NEBO-G036-OPTIMIZER-OBJECTIVE",
       lambda: gradient_config.minimize(lambda _point: 7, (0,)))
reject("context-threads", "NEBO-G036-CONTEXT-UNSUPPORTED",
       lambda: ScientificContext.new({"threads": 2}))
reject("report-schema", "NEBO-G036-REPORT-SCHEMA", lambda: numeric_report({"schema": "wrong"}))
tampered_benchmark = dict(benchmark)
tampered_benchmark["suite"] = "fft"
reject("report-integrity", "NEBO-G036-REPORT-INTEGRITY", lambda: numeric_report(tampered_benchmark))

# Boundaries are explicit rather than silently expanded.
ok("boundary", "single-sparse", SparseVector.fromIndices(1, (), ()).dense() == (0.0,))
ok("boundary", "single-fft", Fft.plan(1).inverse((7,)) == (7+0j,))
ok("boundary", "single-hann", WindowFunction.hann(1) == (1.0,))
ok("boundary", "root-endpoint", Root.bisection(lambda x: x, (0, 1), 1e-9).value == 0.0)
ok("boundary", "small-simpson", Integrate.simpson(lambda x: 1, (0, 1), 2).value == 1.0)
ok("boundary", "three-grid", len(Grid.uniform((0, 1), (3,)).coordinates()) == 3)
timeout_solution = ContinuousOptimizer.gradientDescent({"maxIterations": 1, "learningRate": 0.01}).minimize(objective, (0, 0))
ok("boundary", "optimizer-timeout", timeout_solution.status == "timeout")
stalled_solution = ContinuousOptimizer.gradientDescent().bounds((0,), (0,)).minimize(
    lambda point: ((point[0]-1)**2, (2*(point[0]-1),)), (0,))
ok("boundary", "optimizer-stalled", stalled_solution.status == "stalled")
adaptive_trajectory = OdeProblem.define((1,), lambda _t, state: (state[0],), (0, 1)).solve(
    OdeMethod.adaptiveRk({"initialStep": 0.2}), {"maxSteps": 100})
ok("boundary", "adaptive-rejection", adaptive_trajectory.errorReport()["rejectedSteps"] >= 1)

# Metamorphic properties prevent fixed reports and collapsed algorithms.
ok("metamorphic", "sparse-scale", csr.matmul((8, 10, 12)) == tuple(2*x for x in product))
shifted_spectrum = plan.forward((2, 3, 4, 5))
ok("metamorphic", "fft-dc-shift", close(shifted_spectrum[0].real - spectrum[0].real, 4))
ok("metamorphic", "convolution-scale", Signal((2, 4, 6)).convolve((2, 1)) == tuple(2*x for x in signal.convolve((2, 1))))
root_nine = Root.bisection(lambda x: x*x - 9, (0, 4), 1e-10)
ok("metamorphic", "root-target", close(root_nine.value, 3, 1e-9) and root_nine.value != bisection.value)
scaled_trajectory = OdeProblem.define((2,), lambda _t, state: (state[0],), (0, 1)).solve(fixed_method)
ok("metamorphic", "ode-scale", close(scaled_trajectory.sample(1)[0], 2*trajectory.sample(1)[0]))
scaled_field = PdeProblem.define(lambda _x: 4, grid, (lower, Boundary.dirichlet("upper", 0))).solve()
ok("metamorphic", "pde-source-scale", close(scaled_field.values[8], 2*field.values[8], 1e-7))
shift_solution = gradient_config.minimize(
    lambda point: ((point[0]-5)**2, (2*(point[0]-5),)), (0,))
ok("metamorphic", "optimizer-target", close(shift_solution.point[0], 5, 1e-6))

# Adversarial claims: bounded work, stable schemas and no hidden target upgrade.
ok("adversarial", "sparse-storage", csr.storage == "csr" and csc.storage == "csc")
ok("adversarial", "fft-scalar", plan.normalization == "inverse" and plan.length <= 64)
ok("adversarial", "root-budget", bisection.iterations <= 256 and brent.iterations <= 256)
ok("adversarial", "integration-budget", adaptive.iterations <= 100000)
ok("adversarial", "ode-budget", trajectory.steps() <= 100)
ok("adversarial", "pde-budget", len(field.convergenceTrace()) <= 10000)
invalid_solution = gradient_config.minimize(lambda _point: (math.inf, (0,)), (0,))
diverged_solution = ContinuousOptimizer.gradientDescent({"learningRate": 100, "maxIterations": 20}).minimize(
    lambda point: (-point[0]*point[0], (-2*point[0],)), (1,))
ok("adversarial", "optimizer-status",
   {solution.status, stalled_solution.status, timeout_solution.status,
    invalid_solution.status, diverged_solution.status} ==
   {"converged", "stalled", "timeout", "invalid", "diverged"})
ok("adversarial", "benchmark-methodology", "not wall-clock" in benchmark["methodology"])

# Each domain composes through ordinary returned values.
ok("composition", "sparse-transpose-product", transposed.matmul(product) == (16.0, 45.0, 32.0))
ok("composition", "fft-power", len(plan.inverse(spectrum).magnitude()) == 4)
ok("composition", "root-compare", bisection.compare(bisection, {"absolute": 0, "relative": 0})["passed"] and
   close(bisection.value, brent.value, 1e-8))
ok("composition", "ode-manifest", trajectory.reproducibilityManifest()["traceRecords"] == trajectory.steps())
ok("composition", "field-report", numeric_report(scientific_bench("solvers"))["cases"] == ("root",))
ok("composition", "optimizer-checkpoint", json.loads(solution.checkpoint())["algorithm"] == "gradientDescent")
ok("composition", "context-report", context.manifest()["target"] == benchmark["context"]["target"])

# Returned containers do not alias caller-owned input state.
source_indices = [0, 2]
owned_vector = SparseVector.fromIndices(3, source_indices, [4, 6])
source_indices[0] = 1
ok("ownership", "sparse-copy", owned_vector.indices == (0, 2))
input_signal = [1, 2, 3]
owned_signal = Signal(input_signal)
input_signal[0] = 9
ok("ownership", "signal-copy", owned_signal[0] == 1)
source_bounds = [[0, 1]]
owned_grid = Grid.uniform(source_bounds, (3,))
source_bounds[0][0] = -1
ok("ownership", "grid-copy", owned_grid.bounds[0][0] == 0)
mutable_initial = [1]
owned_problem = OdeProblem.define(mutable_initial, lambda _t, state: state, (0, 1))
mutable_initial[0] = 9
ok("ownership", "ode-copy", owned_problem.initial == (1.0,))
manifest_copy = dict(solution.reproducibilityManifest())
manifest_copy["target"] = "gpu"
ok("ownership", "manifest-copy", solution.reproducibilityManifest()["target"] == "cpu-reference")

# Rejected operations preserve all live state and produce no partial result.
before_dense = csr.toDense(6)
try:
    csr.toDense(5)
except ScientificError:
    pass
ok("failure_atomicity", "sparse", csr.toDense(6) == before_dense)
before_events = tuple(problem._events)
try:
    problem.event(lambda _t, _y: 0, 7)
except ScientificError:
    pass
ok("failure_atomicity", "ode", tuple(problem._events) == before_events)
before_field = field.values
try:
    PdeProblem.define(lambda _x: 0, grid, (flux,)).solve()
except ScientificError:
    pass
ok("failure_atomicity", "pde", field.values == before_field)
before_solution = solution.point
try:
    bounded.bounds((2, 0), (1, 1))
except ScientificError:
    pass
ok("failure_atomicity", "optimizer", solution.point == before_solution)
before_checkpoint = solution.checkpoint()
try:
    solution.compare((1,), {"absolute": -1})
except ScientificError:
    pass
ok("failure_atomicity", "result", solution.checkpoint() == before_checkpoint)

# Repeatability and target truthfulness use frozen data, not ambient timing.
ok("determinism", "sparse", SparseMatrix.csr(2, 3, (0, 2, 3), (0, 2, 1), (1, 2, 3)).matmul((4, 5, 6)) == product)
ok("determinism", "fft", plan.forward((1, 2, 3, 4)) == spectrum)
ok("determinism", "root", Root.bisection(lambda x: x*x-2, (0, 2), 1e-10).checkpoint() == bisection.checkpoint())
ok("determinism", "ode", OdeProblem.define((1,), lambda _t, state: (state[0],), (0, 1)).solve(fixed_method).sample(1) ==
   OdeProblem.define((1,), lambda _t, state: (state[0],), (0, 1)).solve(fixed_method).sample(1))
ok("determinism", "pde", PdeProblem.define(lambda _x: 2, grid, (lower, Boundary.dirichlet("upper", 0))).solve().values == field.values)
ok("determinism", "optimizer", gradient_config.minimize(objective, (0, 0)).checkpoint() == gradient_config.minimize(objective, (0, 0)).checkpoint())
ok("determinism", "benchmark", scientific_bench("core") == benchmark)

for label, value in (("sparse", csr), ("fft", plan), ("root", bisection),
                     ("ode", trajectory), ("pde", field), ("optimizer", solution),
                     ("context", context)):
    ok("target", label, (getattr(value, "reproducibilityManifest", lambda: context.manifest())())["target"] == "cpu-reference")

expected = {"positive": 57, "negative": 19, "boundary": 9,
            "metamorphic": 7, "adversarial": 8, "composition": 7,
            "ownership": 5, "failure_atomicity": 5, "determinism": 7,
            "target": 7}
if dict(counts) != expected:
    raise AssertionError(f"counts:{dict(counts)}")
digest = hashlib.sha256(json.dumps(transcript, sort_keys=True, default=str).encode()).hexdigest()
print("G036_SDK_ORACLE_GREEN " + " ".join(f"{key}={value}" for key, value in expected.items()) +
      f" diagnostics=19 sdk=57 digest={digest}")
