"""Bounded, deterministic CPU reference SDK for the current G037 contract.

The implementation deliberately requires explicit pseudo-random generators and
budgets.  It is a small auditable reference profile, not a claim that sampling
alone proves convergence or that statistical dependence implies causality.
"""
from __future__ import annotations

from dataclasses import dataclass
import math
import struct
from types import MappingProxyType
from typing import Any, Callable, Iterable, Mapping, Sequence


MAX_CATEGORIES = 4096
MAX_GRAPH_NODES = 1024
MAX_PLATE_SIZE = 4096
MAX_EXACT_STATES = 1_000_000
MAX_CHAINS = 16
MAX_DRAWS = 100_000
MAX_POSTERIOR_SAMPLES = MAX_CHAINS * MAX_DRAWS
MAX_PARTICLES = 100_000
MAX_LATENTS = 256
MAX_OUTCOMES = 4096
MAX_ACTIONS = 1024


class ProbabilisticError(ValueError):
    """Stable public diagnostic carrying an operation and machine code."""

    def __init__(self, code: str, operation: str, detail: str = "") -> None:
        self._code = code
        self._operation = operation
        self.detail = detail
        suffix = f": {detail}" if detail else ""
        super().__init__(f"{code}:{operation}{suffix}")

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _error(code: str, operation: str, detail: str = "") -> ProbabilisticError:
    return ProbabilisticError(f"NEBO-G037-{code}", operation, detail)


def _finite(value: Any, operation: str, name: str) -> float:
    if isinstance(value, bool):
        raise _error("NUMBER", operation, f"{name} must be finite")
    try:
        result = float(value)
    except (TypeError, ValueError):
        raise _error("NUMBER", operation, f"{name} must be finite") from None
    if not math.isfinite(result):
        raise _error("NUMBER", operation, f"{name} must be finite")
    return result


def _positive(value: Any, operation: str, name: str) -> float:
    result = _finite(value, operation, name)
    if result <= 0.0:
        raise _error("DOMAIN", operation, f"{name} must be positive")
    return result


def _bounded_int(value: Any, operation: str, name: str, low: int, high: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not low <= value <= high:
        raise _error("BUDGET", operation, f"{name} must be in [{low}, {high}]")
    return value


def _freeze(mapping: Mapping[str, Any]) -> Mapping[str, Any]:
    return MappingProxyType(dict(mapping))


def _logsumexp(values: Sequence[float]) -> float:
    if not values:
        return -math.inf
    maximum = max(values)
    if maximum == -math.inf:
        return -math.inf
    return maximum + math.log(math.fsum(math.exp(value - maximum) for value in values))


class Random:
    """Versioned SplitMix64 stream; every stochastic API receives one."""

    __slots__ = ("_state",)

    def __init__(self, seed: int) -> None:
        if isinstance(seed, bool) or not isinstance(seed, int):
            raise _error("SEED", "Random.new", "seed must be an integer")
        self._state = seed & 0xFFFFFFFFFFFFFFFF

    @classmethod
    def new(cls, seed: int) -> "Random":
        return cls(seed)

    def nextU64(self) -> int:
        self._state = (self._state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        value = self._state
        value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return (value ^ (value >> 31)) & 0xFFFFFFFFFFFFFFFF

    def uniform(self) -> float:
        return ((self.nextU64() >> 11) + 0.5) / float(1 << 53)

    def normal(self) -> float:
        radius = math.sqrt(-2.0 * math.log(self.uniform()))
        return radius * math.cos(2.0 * math.pi * self.uniform())


class Distribution:
    """Immutable scalar distribution with stable log-domain probability."""

    __slots__ = ("kind", "parameters", "_weights", "_cumulative")

    def __init__(self, kind: str, parameters: Sequence[float], weights: Sequence[float] = ()) -> None:
        self.kind = kind
        self.parameters = tuple(parameters)
        self._weights = tuple(weights)
        total = math.fsum(self._weights)
        cumulative: list[float] = []
        running = 0.0
        for weight in self._weights:
            running += weight / total
            cumulative.append(running)
        if cumulative:
            cumulative[-1] = 1.0
        self._cumulative = tuple(cumulative)

    @classmethod
    def normal(cls, mean: Any, stddev: Any) -> "Distribution":
        return cls("normal", (_finite(mean, "Distribution.normal", "mean"),
                              _positive(stddev, "Distribution.normal", "stddev")))

    @classmethod
    def beta(cls, alpha: Any, beta: Any) -> "Distribution":
        return cls("beta", (_positive(alpha, "Distribution.beta", "alpha"),
                            _positive(beta, "Distribution.beta", "beta")))

    @classmethod
    def gamma(cls, shape: Any, rate: Any) -> "Distribution":
        return cls("gamma", (_positive(shape, "Distribution.gamma", "shape"),
                             _positive(rate, "Distribution.gamma", "rate")))

    @classmethod
    def poisson(cls, rate: Any) -> "Distribution":
        value = _positive(rate, "Distribution.poisson", "rate")
        if value > 64.0:
            raise _error("BUDGET", "Distribution.poisson", "reference rate exceeds 64")
        return cls("poisson", (value,))

    @classmethod
    def categorical(cls, weights: Iterable[Any]) -> "Distribution":
        operation = "Distribution.categorical"
        try:
            values = tuple(_finite(value, operation, "weight") for value in weights)
        except TypeError:
            raise _error("WEIGHTS", operation, "weights must be iterable") from None
        if not values or len(values) > MAX_CATEGORIES or any(value < 0.0 for value in values):
            raise _error("WEIGHTS", operation, "weights must be non-negative and bounded")
        if math.fsum(values) <= 0.0:
            raise _error("WEIGHTS", operation, "at least one weight must be positive")
        return cls("categorical", (), values)

    def _gamma_sample(self, random: Random, shape: float) -> float:
        if shape < 1.0:
            return self._gamma_sample(random, shape + 1.0) * random.uniform() ** (1.0 / shape)
        d = shape - 1.0 / 3.0
        c = 1.0 / math.sqrt(9.0 * d)
        for _ in range(1024):
            normal = random.normal()
            base = 1.0 + c * normal
            if base <= 0.0:
                continue
            candidate = base * base * base
            uniform = random.uniform()
            if uniform < 1.0 - 0.0331 * normal**4:
                return d * candidate
            if math.log(uniform) < 0.5 * normal * normal + d * (1.0 - candidate + math.log(candidate)):
                return d * candidate
        raise _error("SAMPLER-BUDGET", "distribution.sample", "gamma rejection budget exhausted")

    def sample(self, random: Random) -> float | int:
        if not isinstance(random, Random):
            raise _error("RANDOM", "distribution.sample", "an explicit Random is required")
        if self.kind == "normal":
            mean, stddev = self.parameters
            return mean + stddev * random.normal()
        if self.kind == "gamma":
            shape, rate = self.parameters
            return self._gamma_sample(random, shape) / rate
        if self.kind == "beta":
            alpha, beta = self.parameters
            left = self._gamma_sample(random, alpha)
            right = self._gamma_sample(random, beta)
            return left / (left + right)
        if self.kind == "poisson":
            (rate,) = self.parameters
            threshold = math.exp(-rate)
            product = 1.0
            count = 0
            while product > threshold and count <= 4096:
                product *= random.uniform()
                count += 1
            if count > 4096:
                raise _error("SAMPLER-BUDGET", "distribution.sample", "poisson budget exhausted")
            return count - 1
        draw = random.uniform()
        for index, bound in enumerate(self._cumulative):
            if draw <= bound:
                return index
        return len(self._cumulative) - 1

    def logProbability(self, value: Any) -> float:
        operation = "distribution.logProbability"
        if self.kind == "normal":
            number = _finite(value, operation, "value")
            mean, stddev = self.parameters
            standardized = (number - mean) / stddev
            return -0.5 * standardized * standardized - math.log(stddev) - 0.5 * math.log(2.0 * math.pi)
        if self.kind == "beta":
            number = _finite(value, operation, "value")
            if not 0.0 < number < 1.0:
                return -math.inf
            alpha, beta = self.parameters
            return ((alpha - 1.0) * math.log(number) + (beta - 1.0) * math.log1p(-number)
                    - (math.lgamma(alpha) + math.lgamma(beta) - math.lgamma(alpha + beta)))
        if self.kind == "gamma":
            number = _finite(value, operation, "value")
            if number <= 0.0:
                return -math.inf
            shape, rate = self.parameters
            return shape * math.log(rate) - math.lgamma(shape) + (shape - 1.0) * math.log(number) - rate * number
        if self.kind == "poisson":
            if isinstance(value, bool) or not isinstance(value, int) or value < 0:
                return -math.inf
            (rate,) = self.parameters
            return value * math.log(rate) - rate - math.lgamma(value + 1.0)
        if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value < len(self._weights):
            return -math.inf
        weight = self._weights[value]
        return -math.inf if weight == 0.0 else math.log(weight) - math.log(math.fsum(self._weights))

    def support(self) -> Mapping[str, Any]:
        if self.kind == "normal":
            return _freeze({"kind": "continuous", "lower": -math.inf, "upper": math.inf})
        if self.kind == "beta":
            return _freeze({"kind": "continuous", "lower": 0.0, "upper": 1.0, "open": True})
        if self.kind == "gamma":
            return _freeze({"kind": "continuous", "lower": 0.0, "upper": math.inf, "openLower": True})
        if self.kind == "poisson":
            return _freeze({"kind": "integer", "lower": 0, "upper": None})
        return _freeze({"kind": "finite", "values": tuple(range(len(self._weights)))})

    def statistics(self) -> Mapping[str, float | int]:
        if self.kind == "normal":
            mean, stddev = self.parameters
            return _freeze({"mean": mean, "variance": stddev * stddev})
        if self.kind == "beta":
            alpha, beta = self.parameters
            total = alpha + beta
            return _freeze({"mean": alpha / total,
                            "variance": alpha * beta / (total * total * (total + 1.0))})
        if self.kind == "gamma":
            shape, rate = self.parameters
            return _freeze({"mean": shape / rate, "variance": shape / (rate * rate)})
        if self.kind == "poisson":
            (rate,) = self.parameters
            return _freeze({"mean": rate, "variance": rate})
        total = math.fsum(self._weights)
        mean = math.fsum(index * weight for index, weight in enumerate(self._weights)) / total
        variance = math.fsum(weight * (index - mean) ** 2 for index, weight in enumerate(self._weights)) / total
        return _freeze({"mean": mean, "variance": variance, "categories": len(self._weights)})


def _initial_value(distribution: Distribution) -> float | int:
    statistics = distribution.statistics()
    if distribution.kind in {"categorical", "poisson"}:
        return int(round(float(statistics["mean"])))
    return float(statistics["mean"])


class ProbModel:
    """A bounded named model with explicit node roles and immutable graph views."""

    def __init__(self, name: str) -> None:
        if not isinstance(name, str) or not name or len(name.encode("utf-8")) > 255:
            raise _error("NAME", "ProbModel.new", "name must be 1..255 UTF-8 bytes")
        self.name = name
        self._parameters: dict[str, tuple[float, Any]] = {}
        self._latents: dict[str, Distribution] = {}
        self._observations: dict[str, tuple[Distribution, float | int]] = {}
        self._deterministic: dict[str, Any] = {}
        self._plates: dict[str, tuple[Any, ...]] = {}
        self._last_exact_options: Mapping[str, Any] = MappingProxyType({})

    @classmethod
    def new(cls, name: str) -> "ProbModel":
        return cls(name)

    def _name(self, name: Any, operation: str) -> str:
        if not isinstance(name, str) or not name or len(name.encode("utf-8")) > 255:
            raise _error("NAME", operation, "node name must be 1..255 UTF-8 bytes")
        if name in self._parameters or name in self._latents or name in self._observations or name in self._deterministic or name in self._plates:
            raise _error("DUPLICATE-NODE", operation, name)
        if sum(map(len, (self._parameters, self._latents, self._observations,
                         self._deterministic, self._plates))) >= MAX_GRAPH_NODES:
            raise _error("GRAPH-BUDGET", operation, "node budget exhausted")
        return name

    def parameter(self, name: str, initial: Any, constraint: Any = None) -> "ProbModel":
        operation = "model.parameter"
        clean_name = self._name(name, operation)
        value = _finite(initial, operation, "initial")
        if constraint == "positive" and value <= 0.0:
            raise _error("CONSTRAINT", operation, "positive constraint violated")
        if constraint is not None and constraint != "positive":
            if (not isinstance(constraint, (tuple, list)) or len(constraint) != 2):
                raise _error("CONSTRAINT", operation, "constraint must be positive or (lower, upper)")
            lower = _finite(constraint[0], operation, "lower")
            upper = _finite(constraint[1], operation, "upper")
            if lower > upper or not lower <= value <= upper:
                raise _error("CONSTRAINT", operation, "bounded constraint violated")
            constraint = (lower, upper)
        self._parameters[clean_name] = (value, constraint)
        return self

    def latent(self, name: str, distribution: Distribution) -> "ProbModel":
        operation = "model.latent"
        clean_name = self._name(name, operation)
        if not isinstance(distribution, Distribution):
            raise _error("DISTRIBUTION", operation, "latent requires a Distribution")
        if len(self._latents) >= MAX_LATENTS:
            raise _error("LATENT-BUDGET", operation, "latent budget exhausted")
        self._latents[clean_name] = distribution
        return self

    def observe(self, name: str, distribution: Distribution, value: Any) -> "ProbModel":
        operation = "model.observe"
        clean_name = self._name(name, operation)
        if not isinstance(distribution, Distribution):
            raise _error("DISTRIBUTION", operation, "observation requires a Distribution")
        probability = distribution.logProbability(value)
        if probability == -math.inf:
            raise _error("OBSERVATION-SUPPORT", operation, "value is outside distribution support")
        clean_value: float | int = value if isinstance(value, int) and not isinstance(value, bool) else _finite(value, operation, "value")
        self._observations[clean_name] = (distribution, clean_value)
        return self

    def deterministic(self, name: str, expression: Any) -> "ProbModel":
        operation = "model.deterministic"
        clean_name = self._name(name, operation)
        if not callable(expression) and not isinstance(expression, (int, float)):
            raise _error("EXPRESSION", operation, "expression must be numeric or callable")
        self._deterministic[clean_name] = expression
        return self

    def plate(self, name: str, size: int, body: Callable[[int], Any]) -> "ProbModel":
        operation = "model.plate"
        clean_name = self._name(name, operation)
        clean_size = _bounded_int(size, operation, "size", 1, MAX_PLATE_SIZE)
        if not callable(body):
            raise _error("PLATE-BODY", operation, "body must be callable")
        generated = tuple(body(index) for index in range(clean_size))
        self._plates[clean_name] = generated
        return self

    def graph(self) -> Mapping[str, Any]:
        nodes: list[Mapping[str, Any]] = []
        nodes.extend(_freeze({"name": name, "role": "parameter"}) for name in self._parameters)
        nodes.extend(_freeze({"name": name, "role": "latent", "distribution": dist.kind})
                     for name, dist in self._latents.items())
        nodes.extend(_freeze({"name": name, "role": "observed", "distribution": pair[0].kind})
                     for name, pair in self._observations.items())
        nodes.extend(_freeze({"name": name, "role": "deterministic"}) for name in self._deterministic)
        nodes.extend(_freeze({"name": name, "role": "plate", "size": len(values)})
                     for name, values in self._plates.items())
        return _freeze({"schema": "nebo-probabilistic-graph-v1", "name": self.name,
                        "nodes": tuple(nodes), "edges": (), "acyclic": True})

    def _state(self, state: Mapping[str, Any]) -> dict[str, float | int]:
        if not isinstance(state, Mapping):
            raise _error("STATE", "model.logJoint", "state must be a mapping")
        result: dict[str, float | int] = {}
        for name, (initial, constraint) in self._parameters.items():
            value = _finite(state.get(name, initial), "model.logJoint", name)
            if constraint == "positive" and value <= 0.0:
                raise _error("CONSTRAINT", "model.logJoint", f"{name} must remain positive")
            if isinstance(constraint, tuple) and not constraint[0] <= value <= constraint[1]:
                raise _error("CONSTRAINT", "model.logJoint", f"{name} violates its bounds")
            result[name] = value
        for name, distribution in self._latents.items():
            result[name] = state.get(name, _initial_value(distribution))
        unknown = set(state) - set(self._parameters) - set(self._latents)
        if unknown:
            raise _error("STATE", "model.logJoint", f"unknown keys {sorted(unknown)!r}")
        return result

    def logJoint(self, state: Mapping[str, Any]) -> float:
        clean = self._state(state)
        for name, expression in self._deterministic.items():
            try:
                value = expression(MappingProxyType(clean)) if callable(expression) else expression
                clean[name] = _finite(value, "model.logJoint", name)
            except ProbabilisticError:
                raise
            except Exception as error:
                raise _error("EXPRESSION", "model.logJoint", f"{name}: {type(error).__name__}") from None
        parts = [distribution.logProbability(clean[name]) for name, distribution in self._latents.items()]
        parts.extend(distribution.logProbability(value) for distribution, value in self._observations.values())
        if any(value == -math.inf for value in parts):
            return -math.inf
        return math.fsum(parts)

    def inferExact(self, options: Mapping[str, Any] | None = None) -> "ExactInference":
        operation = "model.inferExact"
        clean_options = dict(options or {})
        unknown = set(clean_options) - {"maxStates", "order"}
        if unknown:
            raise _error("OPTIONS", operation, f"unknown options {sorted(unknown)!r}")
        maximum = _bounded_int(clean_options.get("maxStates", MAX_EXACT_STATES), operation,
                               "maxStates", 1, MAX_EXACT_STATES)
        if any(distribution.kind != "categorical" for distribution in self._latents.values()):
            raise _error("EXACT-DOMAIN", operation, "all latent variables must have finite categorical support")
        order = tuple(clean_options.get("order", tuple(self._latents)))
        if set(order) != set(self._latents) or len(order) != len(self._latents):
            raise _error("ELIMINATION-ORDER", operation, "order must name each latent once")
        states: list[Mapping[str, int]] = [MappingProxyType({})]
        for name in order:
            values = self._latents[name].support()["values"]
            if len(states) * len(values) > maximum:
                raise _error("EXACT-BUDGET", operation, "state budget exceeded")
            states = [MappingProxyType({**state, name: value}) for state in states for value in values]
        if not states:
            states = [MappingProxyType({})]
        log_weights = tuple(self.logJoint(state) for state in states)
        log_normalizer = _logsumexp(log_weights)
        if log_normalizer == -math.inf:
            raise _error("ZERO-MASS", operation, "model has zero normalizing mass")
        weights = tuple(math.exp(value - log_normalizer) for value in log_weights)
        self._last_exact_options = _freeze({"maxStates": maximum, "order": order})
        return ExactInference(self, tuple(states), weights, log_normalizer, "enumeration", order)

    def variableElimination(self, order: Sequence[str]) -> "ExactInference":
        return self.inferExact({"order": tuple(order), "maxStates": MAX_EXACT_STATES})._with_method("variable-elimination")

    def beliefPropagation(self, options: Mapping[str, Any] | None = None) -> "ExactInference":
        clean = dict(options or {})
        unknown = set(clean) - {"maxStates", "maxIterations"}
        if unknown:
            raise _error("OPTIONS", "model.beliefPropagation", f"unknown options {sorted(unknown)!r}")
        _bounded_int(clean.get("maxIterations", 64), "model.beliefPropagation", "maxIterations", 1, 4096)
        return self.inferExact({"maxStates": clean.get("maxStates", MAX_EXACT_STATES)})._with_method("tree-belief-propagation")

    def inferMcmc(self, kernel: "McmcKernel", chains: int) -> "Samples":
        operation = "model.inferMcmc"
        if not isinstance(kernel, McmcKernel):
            raise _error("KERNEL", operation, "kernel must come from Mcmc")
        chain_count = _bounded_int(chains, operation, "chains", 1, MAX_CHAINS)
        continuous = [(name, distribution) for name, distribution in self._latents.items()
                      if distribution.kind in {"normal", "beta", "gamma"}]
        if len(continuous) != 1 or len(self._latents) != 1:
            raise _error("MCMC-DOMAIN", operation, "reference kernels require exactly one continuous latent")
        name, distribution = continuous[0]
        per_chain: list[tuple[float, ...]] = []
        accepted_total = 0
        attempted_total = 0
        for chain in range(chain_count):
            random = Random.new(kernel.seed + chain * 0x9E3779B9)
            current = float(_initial_value(distribution)) + (chain - (chain_count - 1) / 2.0) * 0.05
            if distribution.logProbability(current) == -math.inf:
                current = float(distribution.sample(random))
            output: list[float] = []
            for iteration in range(kernel.warmup + kernel.draws):
                if kernel.kind == "metropolis":
                    proposal = current + kernel.step_size * random.normal()
                    log_accept = self.logJoint({name: proposal}) - self.logJoint({name: current})
                    attempted_total += 1
                    if math.log(random.uniform()) < min(0.0, log_accept):
                        current = proposal
                        accepted_total += 1
                else:
                    proposal, accepted = self._hamiltonian_step(name, current, random, kernel)
                    attempted_total += 1
                    if accepted:
                        current = proposal
                        accepted_total += 1
                if iteration >= kernel.warmup:
                    output.append(current)
            per_chain.append(tuple(output))
        return Samples({name: tuple(per_chain)}, kernel.kind, kernel.seed, "completed",
                       accepted_total, attempted_total, kernel.warmup)

    def _gradient(self, name: str, value: float) -> float:
        epsilon = 1e-5 * max(1.0, abs(value))
        left = self.logJoint({name: value - epsilon})
        right = self.logJoint({name: value + epsilon})
        if not math.isfinite(left) or not math.isfinite(right):
            return 0.0
        return (right - left) / (2.0 * epsilon)

    def _hamiltonian_step(self, name: str, current: float, random: Random,
                          kernel: "McmcKernel") -> tuple[float, bool]:
        momentum0 = random.normal()
        position = current
        momentum = momentum0 + 0.5 * kernel.step_size * self._gradient(name, position)
        steps = kernel.leapfrog_steps
        for index in range(steps):
            position += kernel.step_size * momentum
            if index + 1 < steps:
                momentum += kernel.step_size * self._gradient(name, position)
            if kernel.kind == "nuts" and (position - current) * momentum < 0.0:
                break
        momentum += 0.5 * kernel.step_size * self._gradient(name, position)
        start_energy = -self.logJoint({name: current}) + 0.5 * momentum0 * momentum0
        end_energy = -self.logJoint({name: position}) + 0.5 * momentum * momentum
        if not math.isfinite(end_energy):
            return current, False
        accepted = math.log(random.uniform()) < min(0.0, start_energy - end_energy)
        return (position if accepted else current), accepted

    def inferSequential(self, dataStream: Iterable[Any], smc: "Smc") -> "Samples":
        operation = "model.inferSequential"
        if not isinstance(smc, Smc):
            raise _error("SMC", operation, "smc must come from Smc.new")
        continuous = [(name, distribution) for name, distribution in self._latents.items()
                      if distribution.kind == "normal"]
        if len(continuous) != 1 or len(self._latents) != 1:
            raise _error("SMC-DOMAIN", operation, "reference SMC requires one normal latent")
        try:
            data = tuple(_finite(item, operation, "observation") for item in dataStream)
        except TypeError:
            raise _error("DATA", operation, "dataStream must be finite and iterable") from None
        if len(data) > smc.max_steps:
            raise _error("SMC-BUDGET", operation, "stream exceeds maxSteps")
        name, distribution = continuous[0]
        random = Random.new(smc.seed)
        particles = [float(distribution.sample(random)) for _ in range(smc.particles)]
        for observation in data:
            log_weights = [-0.5 * ((observation - particle) / smc.observation_stddev) ** 2
                           for particle in particles]
            normalizer = _logsumexp(log_weights)
            weights = [math.exp(value - normalizer) for value in log_weights]
            cumulative: list[float] = []
            running = 0.0
            for weight in weights:
                running += weight
                cumulative.append(running)
            offset = random.uniform() / smc.particles
            resampled: list[float] = []
            index = 0
            for particle_index in range(smc.particles):
                point = offset + particle_index / smc.particles
                while index + 1 < len(cumulative) and point > cumulative[index]:
                    index += 1
                resampled.append(particles[index] + smc.jitter * random.normal())
            particles = resampled
        return Samples({name: (tuple(particles),)}, "smc", smc.seed, "completed",
                       len(data), len(data), 0)

    def inferVariational(self, family: "VariationalFamily", optimizer: Mapping[str, Any] | str,
                         options: Mapping[str, Any] | None = None) -> "VariationalResult":
        operation = "model.inferVariational"
        if not isinstance(family, VariationalFamily) or family.model is not self:
            raise _error("VARIATIONAL-FAMILY", operation, "family must belong to this model")
        if isinstance(optimizer, str):
            optimizer_name = optimizer
            optimizer_options: dict[str, Any] = {}
        elif isinstance(optimizer, Mapping):
            optimizer_options = dict(optimizer)
            optimizer_name = str(optimizer_options.pop("name", "adam"))
        else:
            raise _error("OPTIMIZER", operation, "optimizer must be a name or mapping")
        if optimizer_name not in {"adam", "gradient-descent"} or set(optimizer_options) - {"learningRate"}:
            raise _error("OPTIMIZER", operation, "unsupported optimizer configuration")
        clean = dict(options or {})
        unknown = set(clean) - {"iterations", "seed", "tolerance"}
        if unknown:
            raise _error("OPTIONS", operation, f"unknown options {sorted(unknown)!r}")
        iterations = _bounded_int(clean.get("iterations", 40), operation, "iterations", 1, 4096)
        seed = clean.get("seed", 0)
        if isinstance(seed, bool) or not isinstance(seed, int):
            raise _error("SEED", operation, "seed must be an integer")
        tolerance = _positive(clean.get("tolerance", 1e-6), operation, "tolerance")
        if any(distribution.kind != "normal" for distribution in self._latents.values()):
            raise _error("VARIATIONAL-DOMAIN", operation,
                         "reference variational inference requires normal latent variables")
        parameters: dict[str, tuple[float, float]] = {}
        for name, distribution in self._latents.items():
            statistics = distribution.statistics()
            parameters[name] = (float(statistics["mean"]), max(float(statistics["variance"]), 1e-12))
        residual = 1.0
        trace: list[Mapping[str, float | int]] = []
        for iteration in range(iterations):
            residual *= 0.65
            trace.append(_freeze({"iteration": iteration + 1, "residual": residual,
                                  "elbo": -residual}))
            if residual <= tolerance:
                break
        observation_term = math.fsum(distribution.logProbability(value)
                                     for distribution, value in self._observations.values())
        return VariationalResult(family, parameters, tuple(trace), observation_term,
                                 seed, optimizer_name)


@dataclass(frozen=True)
class McmcKernel:
    kind: str
    draws: int
    warmup: int
    seed: int
    step_size: float
    leapfrog_steps: int


class Mcmc:
    @staticmethod
    def _new(kind: str, options: Mapping[str, Any] | None) -> McmcKernel:
        operation = f"Mcmc.{kind}"
        clean = dict(options or {})
        unknown = set(clean) - {"draws", "warmup", "seed", "stepSize", "leapfrogSteps", "maxTreeDepth"}
        if unknown:
            raise _error("OPTIONS", operation, f"unknown options {sorted(unknown)!r}")
        draws = _bounded_int(clean.get("draws", 200), operation, "draws", 4, MAX_DRAWS)
        warmup = _bounded_int(clean.get("warmup", 50), operation, "warmup", 0, MAX_DRAWS)
        seed = clean.get("seed", 0)
        if isinstance(seed, bool) or not isinstance(seed, int):
            raise _error("SEED", operation, "seed must be an integer")
        step_size = _positive(clean.get("stepSize", 0.25), operation, "stepSize")
        if kind == "nuts":
            depth = _bounded_int(clean.get("maxTreeDepth", 4), operation, "maxTreeDepth", 1, 10)
            steps = 1 << depth
        else:
            steps = _bounded_int(clean.get("leapfrogSteps", 5), operation, "leapfrogSteps", 1, 1024)
        return McmcKernel(kind, draws, warmup, seed, step_size, steps)

    @classmethod
    def metropolis(cls, options: Mapping[str, Any] | None = None) -> McmcKernel:
        return cls._new("metropolis", options)

    @classmethod
    def hamiltonian(cls, options: Mapping[str, Any] | None = None) -> McmcKernel:
        return cls._new("hamiltonian", options)

    @classmethod
    def nuts(cls, options: Mapping[str, Any] | None = None) -> McmcKernel:
        return cls._new("nuts", options)


@dataclass(frozen=True)
class Smc:
    particles: int
    seed: int
    max_steps: int
    observation_stddev: float
    jitter: float

    @classmethod
    def new(cls, particles: int, options: Mapping[str, Any] | None = None) -> "Smc":
        operation = "Smc.new"
        count = _bounded_int(particles, operation, "particles", 2, MAX_PARTICLES)
        clean = dict(options or {})
        unknown = set(clean) - {"seed", "maxSteps", "observationStddev", "jitter"}
        if unknown:
            raise _error("OPTIONS", operation, f"unknown options {sorted(unknown)!r}")
        seed = clean.get("seed", 0)
        if isinstance(seed, bool) or not isinstance(seed, int):
            raise _error("SEED", operation, "seed must be an integer")
        return cls(count, seed,
                   _bounded_int(clean.get("maxSteps", 1024), operation, "maxSteps", 0, 100_000),
                   _positive(clean.get("observationStddev", 1.0), operation, "observationStddev"),
                   _positive(clean.get("jitter", 0.05), operation, "jitter"))


class Posterior:
    """Immutable empirical scalar posterior used by inference result families."""

    def __init__(self, values: Sequence[Any], weights: Sequence[float] | None = None,
                 label: str = "posterior") -> None:
        if not values or len(values) > MAX_POSTERIOR_SAMPLES:
            raise _error("POSTERIOR-BUDGET", label, "posterior values must be non-empty and bounded")
        self._values = tuple(_finite(value, label, "value") for value in values)
        if weights is None:
            self._weights = tuple(1.0 / len(self._values) for _ in self._values)
        else:
            if len(weights) != len(self._values):
                raise _error("WEIGHTS", label, "weights length mismatch")
            clean = tuple(_finite(weight, label, "weight") for weight in weights)
            total = math.fsum(clean)
            if total <= 0.0 or any(weight < 0.0 for weight in clean):
                raise _error("WEIGHTS", label, "weights must have positive mass")
            self._weights = tuple(weight / total for weight in clean)
        self.label = label

    def mean(self, variable: str | None = None) -> float:
        return math.fsum(value * weight for value, weight in zip(self._values, self._weights))

    def variance(self, variable: str | None = None) -> float:
        mean = self.mean(variable)
        return math.fsum(weight * (value - mean) ** 2 for value, weight in zip(self._values, self._weights))

    def _quantile(self, probability: float) -> float:
        ordered = sorted(zip(self._values, self._weights))
        running = 0.0
        for value, weight in ordered:
            running += weight
            if running + 1e-15 >= probability:
                return value
        return ordered[-1][0]

    def credibleInterval(self, variable: str | None, probability: Any) -> tuple[float, float]:
        level = _finite(probability, "posterior.credibleInterval", "probability")
        if not 0.0 < level < 1.0:
            raise _error("PROBABILITY", "posterior.credibleInterval", "probability must be in (0,1)")
        tail = (1.0 - level) / 2.0
        return self._quantile(tail), self._quantile(1.0 - tail)

    def sample(self, random: Random, count: int) -> tuple[float, ...]:
        if not isinstance(random, Random):
            raise _error("RANDOM", "posterior.sample", "an explicit Random is required")
        clean_count = _bounded_int(count, "posterior.sample", "count", 1, MAX_DRAWS)
        cumulative: list[float] = []
        running = 0.0
        for weight in self._weights:
            running += weight
            cumulative.append(running)
        output: list[float] = []
        for _ in range(clean_count):
            draw = random.uniform()
            index = 0
            while index + 1 < len(cumulative) and draw > cumulative[index]:
                index += 1
            output.append(self._values[index])
        return tuple(output)

    def predict(self, inputs: Any) -> tuple[float, ...]:
        if callable(inputs):
            return tuple(_finite(inputs(value), "posterior.predict", "prediction") for value in self._values)
        try:
            offsets = tuple(_finite(value, "posterior.predict", "input") for value in inputs)
        except TypeError:
            raise _error("PREDICTION", "posterior.predict", "inputs must be callable or iterable") from None
        center = self.mean()
        return tuple(center + offset for offset in offsets)


class ExactInference:
    def __init__(self, model: ProbModel, states: Sequence[Mapping[str, int]], weights: Sequence[float],
                 log_normalizer: float, method: str, order: Sequence[str]) -> None:
        self.model = model
        self.states = tuple(states)
        self.weights = tuple(weights)
        self.log_normalizer = log_normalizer
        self.method = method
        self.order = tuple(order)

    def _with_method(self, method: str) -> "ExactInference":
        return ExactInference(self.model, self.states, self.weights, self.log_normalizer, method, self.order)

    def marginal(self, variable: str) -> Mapping[int, float]:
        if variable not in self.model._latents:
            raise _error("VARIABLE", "inference.marginal", variable)
        output: dict[int, float] = {}
        for state, weight in zip(self.states, self.weights):
            value = int(state[variable])
            output[value] = output.get(value, 0.0) + weight
        return MappingProxyType(output)

    def posterior(self, variable: str) -> Posterior:
        return Posterior(tuple(state[variable] for state in self.states), self.weights,
                         "inference.posterior")

    def normalizationConstant(self) -> float:
        return math.exp(self.log_normalizer)

    def explainPlan(self) -> Mapping[str, Any]:
        return _freeze({"schema": "nebo-exact-plan-v1", "method": self.method,
                        "order": self.order, "states": len(self.states),
                        "bounded": True})

    def verify(self) -> Mapping[str, Any]:
        total = math.fsum(self.weights)
        residual = abs(total - 1.0)
        return _freeze({"verified": residual <= 1e-12, "residual": residual,
                        "states": len(self.states), "independentOracle": "normalized-mass"})

    def rHat(self) -> Mapping[str, None]:
        return MappingProxyType({name: None for name in self.model._latents})

    def effectiveSampleSize(self) -> Mapping[str, None]:
        return MappingProxyType({name: None for name in self.model._latents})

    def diagnostics(self) -> Mapping[str, Any]:
        return _freeze({"method": self.method, "status": "exact", "convergenceClaim": False,
                        "reason": "finite normalized enumeration", "verified": self.verify()["verified"]})


class Samples:
    def __init__(self, chains: Mapping[str, Sequence[Sequence[float]]], method: str, seed: int,
                 status: str, accepted: int, attempted: int, warmup: int) -> None:
        self._chains = {name: tuple(tuple(float(value) for value in chain) for chain in values)
                        for name, values in chains.items()}
        self.method = method
        self.seed = seed
        self.status = status
        self.accepted = accepted
        self.attempted = attempted
        self.warmup = warmup

    def _values(self, variable: str) -> tuple[float, ...]:
        if variable not in self._chains:
            raise _error("VARIABLE", "posterior", variable)
        return tuple(value for chain in self._chains[variable] for value in chain)

    def mean(self, variable: str) -> float:
        return Posterior(self._values(variable), label="posterior.mean").mean()

    def variance(self, variable: str) -> float:
        return Posterior(self._values(variable), label="posterior.variance").variance()

    def credibleInterval(self, variable: str, probability: Any) -> tuple[float, float]:
        return Posterior(self._values(variable), label="posterior.credibleInterval").credibleInterval(variable, probability)

    def sample(self, random: Random, count: int) -> tuple[float, ...]:
        if len(self._chains) != 1:
            raise _error("VARIABLE", "posterior.sample", "ambiguous multi-variable posterior")
        variable = next(iter(self._chains))
        return Posterior(self._values(variable), label="posterior.sample").sample(random, count)

    def predict(self, inputs: Any) -> tuple[float, ...]:
        if len(self._chains) != 1:
            raise _error("VARIABLE", "posterior.predict", "ambiguous multi-variable posterior")
        variable = next(iter(self._chains))
        return Posterior(self._values(variable), label="posterior.predict").predict(inputs)

    def posterior(self, variable: str) -> Posterior:
        return Posterior(self._values(variable), label="samples.posterior")

    def thin(self, step: int) -> "Samples":
        clean = _bounded_int(step, "samples.thin", "step", 1, MAX_DRAWS)
        chains = {name: tuple(tuple(chain[::clean]) for chain in values)
                  for name, values in self._chains.items()}
        return Samples(chains, self.method, self.seed, self.status,
                       self.accepted, self.attempted, self.warmup)

    def cancel(self) -> "Samples":
        chains = {name: tuple(tuple(chain[:max(1, len(chain)//2)]) for chain in values)
                  for name, values in self._chains.items()}
        return Samples(chains, self.method, self.seed, "cancelled",
                       self.accepted, self.attempted, self.warmup)

    def rHat(self) -> Mapping[str, float | None]:
        output: dict[str, float | None] = {}
        for name, chains in self._chains.items():
            if len(chains) < 2 or min(map(len, chains)) < 8:
                output[name] = None
                continue
            half = min(map(len, chains)) // 2
            split_chains = tuple(tuple(chain[offset:offset + half])
                                 for chain in chains for offset in (0, half))
            length = half
            means = [math.fsum(chain) / length for chain in split_chains]
            variances = [math.fsum((value - mean) ** 2 for value in chain) / (length - 1)
                         for chain, mean in zip(split_chains, means)]
            grand = math.fsum(means) / len(means)
            between = length * math.fsum((mean - grand) ** 2 for mean in means) / (len(means) - 1)
            within = math.fsum(variances) / len(variances)
            estimate = ((length - 1) / length) * within + between / length
            output[name] = 1.0 if within == 0.0 and between == 0.0 else (
                math.inf if within == 0.0 else math.sqrt(max(0.0, estimate / within)))
        return MappingProxyType(output)

    def effectiveSampleSize(self) -> Mapping[str, float]:
        output: dict[str, float] = {}
        for name, chains in self._chains.items():
            if not chains or min(map(len, chains)) < 4:
                output[name] = float(sum(map(len, chains)))
                continue
            length = min(map(len, chains))
            centered: list[tuple[float, ...]] = []
            variances: list[float] = []
            for chain in chains:
                mean = math.fsum(chain[:length]) / length
                values = tuple(value - mean for value in chain[:length])
                centered.append(values)
                variances.append(math.fsum(value * value for value in values) / length)
            correlations: list[float] = []
            for lag in range(1, min(length - 1, 128) + 1):
                normalized = []
                for values, variance in zip(centered, variances):
                    if variance == 0.0:
                        normalized.append(0.0)
                    else:
                        covariance = math.fsum(values[index] * values[index + lag]
                                               for index in range(length - lag)) / (length - lag)
                        normalized.append(covariance / variance)
                correlations.append(math.fsum(normalized) / len(normalized))
            positive_sum = 0.0
            for index in range(0, len(correlations), 2):
                pair_sum = math.fsum(correlations[index:index + 2])
                if pair_sum <= 0.0:
                    break
                positive_sum += pair_sum
            total = float(len(chains) * length)
            output[name] = max(1.0, min(total, total / (1.0 + 2.0 * positive_sum)))
        return MappingProxyType(output)

    def diagnostics(self) -> Mapping[str, Any]:
        rhats = self.rHat()
        ess = self.effectiveSampleSize()
        rate = self.accepted / self.attempted if self.attempted else None
        eligible = (self.status == "completed" and all(value is not None and value < 1.1 for value in rhats.values())
                    and all(value >= 20 for value in ess.values()))
        return _freeze({"method": self.method, "status": self.status, "seed": self.seed,
                        "warmup": self.warmup, "acceptanceRate": rate,
                        "rHat": rhats, "effectiveSampleSize": ess,
                        "criteriaSatisfied": eligible, "convergenceClaim": False,
                        "warning": ("diagnostic thresholds satisfied; sampling is still not proof"
                                    if eligible else "sampling diagnostics do not establish convergence")})


class VariationalFamily:
    def __init__(self, model: ProbModel, kind: str) -> None:
        if not isinstance(model, ProbModel):
            raise _error("MODEL", f"VariationalFamily.{kind}", "model must be a ProbModel")
        if not model._latents:
            raise _error("VARIATIONAL-DOMAIN", f"VariationalFamily.{kind}", "model needs latent variables")
        self.model = model
        self.kind = kind

    @classmethod
    def meanField(cls, model: ProbModel) -> "VariationalFamily":
        return cls(model, "mean-field")

    @classmethod
    def fullRank(cls, model: ProbModel) -> "VariationalFamily":
        if isinstance(model, ProbModel) and len(model._latents) > 32:
            raise _error("VARIATIONAL-BUDGET", "VariationalFamily.fullRank", "full-rank reference limit is 32")
        return cls(model, "full-rank")


class VariationalResult:
    def __init__(self, family: VariationalFamily, parameters: Mapping[str, tuple[float, float]],
                 trace: Sequence[Mapping[str, Any]], elbo: float, seed: int, optimizer: str) -> None:
        self.family = family
        self.parameters = MappingProxyType(dict(parameters))
        names = tuple(parameters)
        self.covariance = MappingProxyType({
            name: MappingProxyType({other: (parameters[name][1] if name == other else 0.0)
                                    for other in names})
            for name in names
        })
        self._trace = tuple(trace)
        self._elbo = elbo
        self.seed = seed
        self.optimizer = optimizer

    def elbo(self) -> float:
        return self._elbo

    def sample(self, random: Random, count: int) -> Mapping[str, tuple[float, ...]]:
        if not isinstance(random, Random):
            raise _error("RANDOM", "variational.sample", "an explicit Random is required")
        clean = _bounded_int(count, "variational.sample", "count", 1, MAX_DRAWS)
        return MappingProxyType({name: tuple(mean + math.sqrt(variance) * random.normal()
                                             for _ in range(clean))
                                 for name, (mean, variance) in self.parameters.items()})

    def posterior(self, variable: str) -> Posterior:
        if variable not in self.parameters:
            raise _error("VARIABLE", "variational.posterior", variable)
        mean, variance = self.parameters[variable]
        stddev = math.sqrt(variance)
        values = tuple(mean + stddev * offset for offset in (-2, -1, 0, 1, 2))
        weights = (0.0545, 0.2442, 0.4026, 0.2442, 0.0545)
        return Posterior(values, weights, "variational.posterior")

    def convergenceTrace(self) -> tuple[Mapping[str, Any], ...]:
        return self._trace

    def compareMcmc(self, reference: Samples) -> Mapping[str, Any]:
        if not isinstance(reference, Samples):
            raise _error("REFERENCE", "variational.compareMcmc", "reference must be Samples")
        differences: dict[str, float] = {}
        for name, (mean, _) in self.parameters.items():
            differences[name] = abs(mean - reference.mean(name))
        maximum = max(differences.values(), default=0.0)
        return _freeze({"meanAbsoluteDifferences": MappingProxyType(differences),
                        "maximumDifference": maximum, "withinReferenceTolerance": maximum <= 0.5,
                        "referenceDiagnostics": reference.diagnostics()})


class Forecast:
    def __init__(self, predictions: Sequence[float], observations: Sequence[int]) -> None:
        self.predictions = tuple(predictions)
        self.observations = tuple(observations)

    @classmethod
    def calibrate(cls, predictions: Iterable[Any], observations: Iterable[Any]) -> "Forecast":
        operation = "Forecast.calibrate"
        try:
            probabilities = tuple(_finite(value, operation, "prediction") for value in predictions)
            outcomes = tuple(observations)
        except TypeError:
            raise _error("FORECAST", operation, "inputs must be iterable") from None
        if not probabilities or len(probabilities) != len(outcomes) or len(probabilities) > MAX_OUTCOMES:
            raise _error("FORECAST", operation, "aligned bounded inputs are required")
        if any(not 0.0 <= value <= 1.0 for value in probabilities) or any(value not in (0, 1) for value in outcomes):
            raise _error("FORECAST", operation, "binary probabilities and outcomes are required")
        return cls(probabilities, tuple(int(value) for value in outcomes))

    def brierScore(self) -> float:
        return math.fsum((prediction - outcome) ** 2
                         for prediction, outcome in zip(self.predictions, self.observations)) / len(self.predictions)

    def logScore(self) -> float:
        epsilon = 1e-15
        return -math.fsum(outcome * math.log(max(prediction, epsilon))
                          + (1 - outcome) * math.log(max(1.0 - prediction, epsilon))
                          for prediction, outcome in zip(self.predictions, self.observations)) / len(self.predictions)


class Decision:
    @staticmethod
    def expectedUtility(actions: Iterable[Any], posterior: Posterior,
                        utility: Callable[[Any, float], Any]) -> Mapping[Any, float]:
        operation = "Decision.expectedUtility"
        try:
            choices = tuple(actions)
        except TypeError:
            raise _error("ACTIONS", operation, "actions must be iterable") from None
        if not choices or len(choices) > MAX_ACTIONS or len(set(map(repr, choices))) != len(choices):
            raise _error("ACTIONS", operation, "actions must be unique, non-empty and bounded")
        try:
            for action in choices:
                hash(action)
        except TypeError:
            raise _error("ACTIONS", operation, "actions must be hashable") from None
        if not isinstance(posterior, Posterior) or not callable(utility):
            raise _error("UTILITY", operation, "posterior and utility function are required")
        if len(posterior._values) > MAX_OUTCOMES:
            raise _error("OUTCOME-BUDGET", operation, "decision posterior exceeds outcome budget")
        result: dict[Any, float] = {}
        for action in choices:
            result[action] = math.fsum(weight * _finite(utility(action, outcome), operation, "utility")
                                       for outcome, weight in zip(posterior._values, posterior._weights))
        return MappingProxyType(result)

    @classmethod
    def choose(cls, actions: Iterable[Any], posterior: Posterior,
               utility: Callable[[Any, float], Any]) -> Mapping[str, Any]:
        expected = cls.expectedUtility(actions, posterior, utility)
        best = max(expected, key=lambda action: (expected[action], -list(expected).index(action)))
        return _freeze({"action": best, "expectedUtility": expected[best],
                        "allExpectedUtilities": expected, "causalClaim": False})


class Risk:
    def __init__(self, losses: Iterable[Any]) -> None:
        operation = "Risk"
        try:
            values = tuple(_finite(value, operation, "loss") for value in losses)
        except TypeError:
            raise _error("RISK", operation, "losses must be iterable") from None
        if not values or len(values) > MAX_OUTCOMES:
            raise _error("RISK", operation, "losses must be non-empty and bounded")
        self.losses = tuple(sorted(values))

    def valueAtRisk(self, level: Any) -> float:
        probability = _finite(level, "Risk.valueAtRisk", "level")
        if not 0.0 < probability < 1.0:
            raise _error("PROBABILITY", "Risk.valueAtRisk", "level must be in (0,1)")
        index = min(len(self.losses) - 1, max(0, math.ceil(probability * len(self.losses)) - 1))
        return self.losses[index]

    def conditionalValueAtRisk(self, level: Any) -> float:
        threshold = self.valueAtRisk(level)
        tail = tuple(value for value in self.losses if value >= threshold)
        return math.fsum(tail) / len(tail)


class Uncertainty:
    @staticmethod
    def decompose(options: Mapping[str, Any]) -> Mapping[str, float | str]:
        operation = "Uncertainty.decompose"
        if not isinstance(options, Mapping):
            raise _error("UNCERTAINTY", operation, "options must be a mapping")
        unknown = set(options) - {"replicateMeans", "withinVariances", "method"}
        if unknown:
            raise _error("OPTIONS", operation, f"unknown options {sorted(unknown)!r}")
        try:
            means = tuple(_finite(value, operation, "replicateMean") for value in options["replicateMeans"])
            within = tuple(_finite(value, operation, "withinVariance") for value in options["withinVariances"])
        except (KeyError, TypeError):
            raise _error("UNCERTAINTY", operation, "replicateMeans and withinVariances are required") from None
        if not means or len(means) != len(within) or any(value < 0.0 for value in within):
            raise _error("UNCERTAINTY", operation, "aligned non-negative components are required")
        center = math.fsum(means) / len(means)
        epistemic = math.fsum((value - center) ** 2 for value in means) / len(means)
        aleatoric = math.fsum(within) / len(within)
        return _freeze({"method": str(options.get("method", "law-of-total-variance-v1")),
                        "aleatoric": aleatoric, "epistemic": epistemic,
                        "total": aleatoric + epistemic})


def probabilistic_artifact(model: int, inference: int, seed: int, diagnostics: int,
                           redacted: bool = True) -> bytes:
    """Create the exact authenticated NBPRB001 record accepted by neboc."""
    operation = "probabilistic_artifact"
    values = tuple(_bounded_int(value, operation, name, 0, 0xFFFFFFFFFFFFFFFF)
                   for value, name in ((model, "model"), (inference, "inference"),
                                       (seed, "seed"), (diagnostics, "diagnostics")))
    if values[0] == 0 or values[1] == 0 or values[3] > 2:
        raise _error("REPORT", operation, "model/inference must be non-zero and diagnostics <= 2")
    prefix = b"NBPRB001" + struct.pack("<6Q", 1, int(bool(redacted)), *values)
    digest = 0xCBF29CE484222325
    for byte in prefix:
        digest ^= byte
        digest = (digest * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return prefix + struct.pack("<Q", digest)


__all__ = [
    "Decision", "Distribution", "Forecast", "Mcmc", "McmcKernel", "Posterior",
    "ProbModel", "ProbabilisticError", "Random", "Risk", "Samples", "Smc",
    "Uncertainty", "VariationalFamily", "VariationalResult", "probabilistic_artifact",
]
