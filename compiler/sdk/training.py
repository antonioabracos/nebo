"""Bounded, deterministic training SDK for Nebo G021.

The native x86_64 owners under ``runtime/autograd`` and ``runtime/training``
remain the low-level reference implementation.  This module supplies the
current catalogue vocabulary as a correctness-first CPU profile: reverse-mode
autodiff, losses and metrics, SGD/Adam, a tiny trainer, local datasets, and
checksummed checkpoints.  It performs no downloads and rejects non-finite or
unbounded work before mutating live state.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import random
import sys
from typing import Any, Callable, Iterable, Mapping, Sequence
import weakref


MAX_ELEMENTS = 4096
MAX_GRAPH_NODES = 256
MAX_PARAMETERS = 4096
MAX_EPOCHS = 1024
MAX_BATCH = 64
MAX_SAMPLES = 4096
MAX_PREFETCH = 8
MAX_CHECKPOINT_BYTES = 1_048_576
MAX_ROTATIONS = 8
CHECKPOINT_MAGIC = "NCP1"
CHECKPOINT_VERSION = 1


class TrainingError(ValueError):
    """Stable fail-closed error for the bounded G021 profile."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def _require(condition: bool, code: str) -> None:
    if not condition:
        raise TrainingError(code)


def _finite(values: Iterable[int | float]) -> tuple[float, ...]:
    try:
        source = tuple(values)
        _require(not any(isinstance(value, bool) for value in source),
                 "NEBO-G021-NUMERIC-VALUE")
        result = tuple(float(value) for value in source)
    except (TypeError, ValueError, OverflowError) as error:
        raise TrainingError("NEBO-G021-NUMERIC-VALUE") from error
    _require(1 <= len(result) <= MAX_ELEMENTS, "NEBO-G021-ELEMENT-BUDGET")
    _require(all(math.isfinite(value) for value in result), "NEBO-G021-NONFINITE")
    return result


def _shape(shape: Sequence[int], elements: int) -> tuple[int, ...]:
    candidate = tuple(shape)
    _require(1 <= len(candidate) <= 4, "NEBO-G021-RANK")
    total = 1
    for dimension in candidate:
        _require(isinstance(dimension, int) and not isinstance(dimension, bool)
                 and 1 <= dimension <= 64, "NEBO-G021-SHAPE")
        total *= dimension
        _require(total <= MAX_ELEMENTS, "NEBO-G021-ELEMENT-BUDGET")
    _require(total == elements, "NEBO-G021-SHAPE-MISMATCH")
    return candidate


def _canonical(value: Any) -> bytes:
    try:
        return json.dumps(value, sort_keys=True, separators=(",", ":"),
                          ensure_ascii=True, allow_nan=False).encode("ascii")
    except (TypeError, ValueError, OverflowError) as error:
        raise TrainingError("NEBO-G021-SERIALIZATION") from error


@dataclass(frozen=True)
class GraphNode:
    identifier: int
    operation: str
    parents: tuple[int, ...]
    elements: int


class ComputationGraph:
    def __init__(self) -> None:
        self._nodes: list[GraphNode] = []
        self._owners: weakref.WeakKeyDictionary[Tensor, int] = weakref.WeakKeyDictionary()

    def _record(self, operation: str, parents: Sequence["Tensor"], elements: int) -> int:
        for parent in dict.fromkeys(parents):
            if parent._requires_gradient and parent not in self._owners:
                _require(len(self._nodes) < MAX_GRAPH_NODES, "NEBO-G021-GRAPH-BUDGET")
                parent._node_id = len(self._nodes) + 1
                self._nodes.append(GraphNode(parent._node_id, "leaf", (), parent.elements))
                self._owners[parent] = parent._node_id
        _require(len(self._nodes) < MAX_GRAPH_NODES, "NEBO-G021-GRAPH-BUDGET")
        identifier = len(self._nodes) + 1
        node = GraphNode(identifier, operation,
                         tuple(self._owners[parent] for parent in parents
                               if parent in self._owners),
                         elements)
        self._nodes.append(node)
        return identifier

    def nodes(self) -> tuple[GraphNode, ...]:
        return tuple(self._nodes)

    def clear(self) -> int:
        count = len(self._nodes)
        self._nodes.clear()
        self._owners.clear()
        return count


graph = ComputationGraph()


class _RecordingScope:
    def __init__(self, owner: "Autograd", previous: bool, enabled: bool) -> None:
        self._owner = owner
        self._previous = previous
        self.enabled = enabled

    def __enter__(self) -> "_RecordingScope":
        return self

    def __exit__(self, *_: object) -> None:
        self._owner._enabled = self._previous


class Operation:
    """An inspectable local backward rule, never serialized as executable code."""

    def __init__(self, name: str, rule: Callable[[tuple[float, ...]], tuple[tuple[float, ...], ...]]) -> None:
        self.name = name
        self._rule = rule

    def backwardRule(self) -> Callable[[tuple[float, ...]], tuple[tuple[float, ...], ...]]:
        return self._rule


class Tensor:
    """Owned Float64 tensor with a bounded reverse-mode graph."""

    def __init__(self, values: Iterable[int | float], shape: Sequence[int] | None = None,
                 requires_gradient: bool = False,
                 parents: Sequence["Tensor"] = (), operation: Operation | None = None) -> None:
        converted = _finite(values)
        self._values = list(converted)
        self.shape = _shape(shape or (len(converted),), len(converted))
        _require(isinstance(requires_gradient, bool), "NEBO-G021-REQUIRES-GRADIENT")
        self._requires_gradient = requires_gradient
        self._gradient: list[float] | None = None
        self._parents = tuple(parents)
        self._operation = operation
        should_record = autograd._enabled and (requires_gradient or any(
            parent._requires_gradient for parent in parents))
        self._node_id = graph._record(operation.name if operation else "leaf", parents,
                                      len(converted)) if should_record else 0
        if self._node_id:
            graph._owners[self] = self._node_id
        if requires_gradient and not parents:
            gradients._track(self)

    @property
    def values(self) -> tuple[float, ...]:
        return tuple(self._values)

    @property
    def elements(self) -> int:
        return len(self._values)

    def requiresGradient(self, enabled: bool) -> "Tensor":
        _require(isinstance(enabled, bool), "NEBO-G021-REQUIRES-GRADIENT")
        self._requires_gradient = enabled
        if enabled:
            gradients._track(self)
            if self not in graph._owners and autograd._enabled:
                self._node_id = graph._record("leaf", (), self.elements)
                graph._owners[self] = self._node_id
        else:
            gradients._tracked.pop(id(self), None)
        return self

    def gradient(self) -> "Tensor | None":
        if self._gradient is None:
            return None
        return Tensor(self._gradient, self.shape, False)

    def detach(self) -> "Tensor":
        return Tensor(self._values, self.shape, False)

    def _binary(self, other: "Tensor | int | float", name: str,
                forward: Callable[[float, float], float],
                derivative: Callable[[float, float, float], tuple[float, float]]) -> "Tensor":
        right = other if isinstance(other, Tensor) else Tensor([other] * self.elements, self.shape)
        _require(self.shape == right.shape, "NEBO-G021-SHAPE-MISMATCH")
        values = [forward(left, rhs) for left, rhs in zip(self._values, right._values)]

        def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
            left_gradient: list[float] = []
            right_gradient: list[float] = []
            for left, rhs, grad in zip(self._values, right._values, upstream):
                dl, dr = derivative(left, rhs, grad)
                left_gradient.append(dl)
                right_gradient.append(dr)
            return tuple(left_gradient), tuple(right_gradient)

        requires = self._requires_gradient or right._requires_gradient
        return Tensor(values, self.shape, requires, (self, right), Operation(name, rule))

    def add(self, other: "Tensor | int | float") -> "Tensor":
        return self._binary(other, "add", lambda left, right: left + right,
                            lambda _left, _right, grad: (grad, grad))

    def multiply(self, other: "Tensor | int | float") -> "Tensor":
        return self._binary(other, "multiply", lambda left, right: left * right,
                            lambda left, right, grad: (grad * right, grad * left))

    def sum(self) -> "Tensor":
        values = tuple(self._values)

        def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
            return (tuple(upstream[0] for _ in values),)

        return Tensor([math.fsum(values)], (1,), self._requires_gradient,
                      (self,), Operation("sum", rule))

    def mean(self) -> "Tensor":
        return self.sum().multiply(1.0 / self.elements)

    def backward(self, gradient: "Tensor | Sequence[float] | float | None" = None) -> None:
        if gradient is None:
            _require(self.elements == 1, "NEBO-G021-BACKWARD-GRADIENT")
            seed = (1.0,)
        elif isinstance(gradient, Tensor):
            _require(gradient.shape == self.shape, "NEBO-G021-SHAPE-MISMATCH")
            seed = gradient.values
        elif isinstance(gradient, (int, float)) and not isinstance(gradient, bool):
            _require(self.elements == 1, "NEBO-G021-BACKWARD-GRADIENT")
            seed = _finite([gradient])
        else:
            seed = _finite(gradient)  # type: ignore[arg-type]
            _require(len(seed) == self.elements, "NEBO-G021-SHAPE-MISMATCH")
        topology: list[Tensor] = []
        seen: set[int] = set()

        def visit(value: Tensor) -> None:
            identity = id(value)
            if identity in seen:
                return
            seen.add(identity)
            for parent in value._parents:
                visit(parent)
            topology.append(value)

        visit(self)
        pending: dict[int, list[float]] = {id(self): list(seed)}
        for value in reversed(topology):
            incoming = pending.get(id(value), [0.0] * value.elements)
            _require(all(math.isfinite(item) for item in incoming), "NEBO-G021-NONFINITE")
            if value._requires_gradient:
                if value._gradient is None:
                    value._gradient = [0.0] * value.elements
                value._gradient = [left + right for left, right in zip(value._gradient, incoming)]
            if value._operation is None:
                continue
            parent_gradients = value._operation.backwardRule()(tuple(incoming))
            _require(len(parent_gradients) == len(value._parents), "NEBO-G021-BACKWARD-RULE")
            for parent, contribution in zip(value._parents, parent_gradients):
                _require(len(contribution) == parent.elements, "NEBO-G021-BACKWARD-RULE")
                slot = pending.setdefault(id(parent), [0.0] * parent.elements)
                pending[id(parent)] = [left + right for left, right in zip(slot, contribution)]


class GradientSet:
    def __init__(self) -> None:
        self._tracked: weakref.WeakValueDictionary[int, Tensor] = weakref.WeakValueDictionary()

    def _track(self, tensor: Tensor) -> None:
        existing = self._tracked.get(id(tensor))
        elements = sum(value.elements for value in self._tracked.values())
        _require(existing is tensor or elements + tensor.elements <= MAX_PARAMETERS,
                 "NEBO-G021-PARAMETER-BUDGET")
        self._tracked[id(tensor)] = tensor

    def zero(self) -> int:
        changed = 0
        for tensor in tuple(self._tracked.values()):
            if tensor._gradient is not None:
                tensor._gradient = [0.0] * tensor.elements
                changed += tensor.elements
        return changed

    def clipNorm(self, maxNorm: float) -> float:
        limit = float(maxNorm)
        _require(math.isfinite(limit) and limit > 0.0, "NEBO-G021-CLIP-NORM")
        values = [item for tensor in self._tracked.values()
                  for item in (tensor._gradient or ())]
        _require(all(math.isfinite(item) for item in values), "NEBO-G021-NONFINITE")
        norm = math.sqrt(math.fsum(item * item for item in values))
        if norm > limit and norm > 0.0:
            factor = limit / norm
            for tensor in self._tracked.values():
                if tensor._gradient is not None:
                    tensor._gradient = [item * factor for item in tensor._gradient]
        return norm

    def clipValue(self, minimum: float, maximum: float) -> int:
        low, high = float(minimum), float(maximum)
        _require(math.isfinite(low) and math.isfinite(high) and low <= high,
                 "NEBO-G021-CLIP-VALUE")
        count = 0
        for tensor in self._tracked.values():
            if tensor._gradient is None:
                continue
            _require(all(math.isfinite(item) for item in tensor._gradient),
                     "NEBO-G021-NONFINITE")
            clipped = [max(low, min(high, item)) for item in tensor._gradient]
            count += sum(left != right for left, right in zip(tensor._gradient, clipped))
            tensor._gradient = clipped
        return count


gradients = GradientSet()


class Autograd:
    def __init__(self) -> None:
        self._enabled = True

    def recording(self, enabled: bool) -> _RecordingScope:
        _require(isinstance(enabled, bool), "NEBO-G021-RECORDING")
        previous = self._enabled
        self._enabled = enabled
        return _RecordingScope(self, previous, enabled)

    def checkpoint(self, function: Callable[..., Tensor]) -> Callable[..., Tensor]:
        _require(callable(function), "NEBO-G021-CHECKPOINT-FUNCTION")

        def recomputed(*inputs: Tensor) -> Tensor:
            _require(all(isinstance(value, Tensor) for value in inputs),
                     "NEBO-G021-CHECKPOINT-INPUT")
            with self.recording(False):
                forward = function(*(value.detach() for value in inputs))
            _require(isinstance(forward, Tensor), "NEBO-G021-CHECKPOINT-RESULT")
            forward_values = forward.values
            forward_shape = forward.shape

            def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
                probes = [Tensor(value.values, value.shape, value._requires_gradient)
                          for value in inputs]
                with self.recording(False):
                    replay = function(*probes)
                _require(isinstance(replay, Tensor) and replay.shape == forward_shape,
                         "NEBO-G021-CHECKPOINT-RESULT")
                replay.backward(Tensor(upstream, replay.shape))
                return tuple(tuple(probe._gradient or [0.0] * probe.elements)
                             for probe in probes)

            requires = any(value._requires_gradient for value in inputs)
            return Tensor(forward_values, forward_shape, requires, inputs,
                          Operation("checkpoint", rule))

        return recomputed

    def gradCheck(self, function: Callable[..., Tensor], inputs: Sequence[Tensor],
                  step: float = 1e-5, tolerance: float = 1e-4) -> dict[str, Any]:
        _require(callable(function) and 1 <= len(inputs) <= 16,
                 "NEBO-G021-GRADCHECK-INPUT")
        h, allowed = float(step), float(tolerance)
        _require(math.isfinite(h) and 0.0 < h <= 1e-2,
                 "NEBO-G021-GRADCHECK-STEP")
        _require(math.isfinite(allowed) and 0.0 < allowed <= 1e-2,
                 "NEBO-G021-GRADCHECK-TOLERANCE")
        probes = [Tensor(value.values, value.shape, True) for value in inputs]
        output = function(*probes)
        _require(isinstance(output, Tensor) and output.elements == 1,
                 "NEBO-G021-GRADCHECK-OUTPUT")
        output.backward()
        analytic = [item for probe in probes for item in (probe._gradient or [])]
        numerical: list[float] = []
        for input_index, original in enumerate(inputs):
            for element_index in range(original.elements):
                plus = [Tensor(value.values, value.shape) for value in inputs]
                minus = [Tensor(value.values, value.shape) for value in inputs]
                plus[input_index]._values[element_index] += h
                minus[input_index]._values[element_index] -= h
                plus_result = function(*plus)
                minus_result = function(*minus)
                _require(plus_result.elements == minus_result.elements == 1,
                         "NEBO-G021-GRADCHECK-OUTPUT")
                numerical.append((plus_result.values[0] - minus_result.values[0]) / (2.0 * h))
        errors = [abs(left - right) for left, right in zip(analytic, numerical)]
        maximum = max(errors, default=0.0)
        return {"passed": maximum <= allowed, "maximumError": maximum,
                "elements": len(errors), "step": h, "tolerance": allowed}


autograd = Autograd()


class Loss:
    @staticmethod
    def _reduce(values: Tensor, reduction: str) -> Tensor:
        _require(reduction in {"mean", "sum", "none"}, "NEBO-G021-REDUCTION")
        return values.mean() if reduction == "mean" else values.sum() if reduction == "sum" else values

    @staticmethod
    def meanSquaredError(prediction: Tensor, target: Tensor,
                         reduction: str = "mean") -> Tensor:
        _require(isinstance(prediction, Tensor) and isinstance(target, Tensor),
                 "NEBO-G021-LOSS-INPUT")
        delta = prediction.add(target.multiply(-1.0))
        return Loss._reduce(delta.multiply(delta), reduction)

    @staticmethod
    def crossEntropy(logits: Tensor, target: Sequence[int],
                     options: Mapping[str, Any] | None = None) -> Tensor:
        options = dict(options or {})
        reduction = str(options.pop("reduction", "mean"))
        _require(not options, "NEBO-G021-LOSS-OPTION")
        _require(len(logits.shape) == 2, "NEBO-G021-LOGITS-SHAPE")
        samples, classes = logits.shape
        labels = tuple(target)
        _require(len(labels) == samples and all(isinstance(label, int) and
                 not isinstance(label, bool) and 0 <= label < classes for label in labels),
                 "NEBO-G021-TARGET")
        losses: list[float] = []
        probabilities: list[list[float]] = []
        for row, label in enumerate(labels):
            values = logits._values[row * classes:(row + 1) * classes]
            maximum = max(values)
            exponentials = [math.exp(value - maximum) for value in values]
            denominator = math.fsum(exponentials)
            probs = [value / denominator for value in exponentials]
            probabilities.append(probs)
            losses.append(-math.log(probs[label]))
        divisor = samples if reduction == "mean" else 1

        def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
            result: list[float] = []
            for row, (probs, label) in enumerate(zip(probabilities, labels)):
                scale = upstream[0] / divisor if reduction != "none" else upstream[row]
                result.extend((probability - (column == label)) * scale
                              for column, probability in enumerate(probs))
            return (tuple(result),)

        raw = losses if reduction == "none" else [math.fsum(losses) / divisor]
        if reduction == "sum":
            raw = [math.fsum(losses)]
        output_shape = (samples,) if reduction == "none" else (1,)
        return Tensor(raw, output_shape, logits._requires_gradient, (logits,),
                      Operation("cross_entropy", rule))

    @staticmethod
    def binaryCrossEntropy(input: Tensor, target: Tensor,
                           options: Mapping[str, Any] | None = None) -> Tensor:
        options = dict(options or {})
        reduction = str(options.pop("reduction", "mean"))
        epsilon = float(options.pop("epsilon", 1e-12))
        _require(not options and 0.0 < epsilon <= 1e-3, "NEBO-G021-LOSS-OPTION")
        _require(input.shape == target.shape, "NEBO-G021-SHAPE-MISMATCH")
        _require(all(0.0 <= value <= 1.0 for value in input.values + target.values),
                 "NEBO-G021-PROBABILITY")
        clipped = [min(1.0 - epsilon, max(epsilon, value)) for value in input.values]
        values = [-(truth * math.log(value) + (1.0 - truth) * math.log(1.0 - value))
                  for value, truth in zip(clipped, target.values)]
        divisor = input.elements if reduction == "mean" else 1

        def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
            gradients_out = []
            for index, (value, truth) in enumerate(zip(clipped, target.values)):
                scale = upstream[0] / divisor if reduction != "none" else upstream[index]
                gradients_out.append(((value - truth) / (value * (1.0 - value))) * scale)
            return tuple(gradients_out), tuple(0.0 for _ in target.values)

        if reduction == "none":
            raw, output_shape = values, input.shape
        else:
            raw = [math.fsum(values) / divisor]
            output_shape = (1,)
        return Tensor(raw, output_shape, input._requires_gradient,
                      (input, target), Operation("binary_cross_entropy", rule))

    @staticmethod
    def negativeLogLikelihood(input: Tensor, target: Sequence[int]) -> Tensor:
        _require(len(input.shape) == 2, "NEBO-G021-LOGITS-SHAPE")
        samples, classes = input.shape
        labels = tuple(target)
        _require(len(labels) == samples and all(isinstance(label, int) and
                 not isinstance(label, bool) and 0 <= label < classes for label in labels),
                 "NEBO-G021-TARGET")
        chosen = [input.values[row * classes + label] for row, label in enumerate(labels)]

        def rule(upstream: tuple[float, ...]) -> tuple[tuple[float, ...], ...]:
            result = [0.0] * input.elements
            for row, label in enumerate(labels):
                result[row * classes + label] = -upstream[0] / samples
            return (tuple(result),)

        return Tensor([-math.fsum(chosen) / samples], (1,), input._requires_gradient,
                      (input,), Operation("negative_log_likelihood", rule))


class Metric:
    @staticmethod
    def _labels(prediction: Tensor | Sequence[int], target: Sequence[int]) -> tuple[tuple[int, ...], tuple[int, ...], int]:
        truth = tuple(target)
        _require(truth and all(isinstance(value, int) and not isinstance(value, bool)
                              and value >= 0 for value in truth), "NEBO-G021-TARGET")
        if isinstance(prediction, Tensor):
            _require(len(prediction.shape) == 2 and prediction.shape[0] == len(truth),
                     "NEBO-G021-METRIC-SHAPE")
            samples, classes = prediction.shape
            labels = tuple(max(range(classes), key=lambda column:
                         prediction.values[row * classes + column]) for row in range(samples))
        else:
            labels = tuple(prediction)
            _require(len(labels) == len(truth) and all(isinstance(value, int) and
                     not isinstance(value, bool) and value >= 0 for value in labels),
                     "NEBO-G021-METRIC-SHAPE")
            classes = max(labels + truth) + 1
        _require(classes <= 64 and all(value < classes for value in truth),
                 "NEBO-G021-CLASS-BUDGET")
        return labels, truth, classes

    @staticmethod
    def accuracy(prediction: Tensor | Sequence[int], target: Sequence[int]) -> float:
        labels, truth, _ = Metric._labels(prediction, target)
        return sum(left == right for left, right in zip(labels, truth)) / len(truth)

    @staticmethod
    def precisionRecall(prediction: Tensor | Sequence[int], target: Sequence[int]) -> dict[str, tuple[float, ...]]:
        matrix = Metric.confusionMatrix(prediction, target)
        classes = len(matrix)
        precision, recall = [], []
        for index in range(classes):
            true_positive = matrix[index][index]
            predicted = sum(matrix[row][index] for row in range(classes))
            actual = sum(matrix[index])
            precision.append(true_positive / predicted if predicted else 0.0)
            recall.append(true_positive / actual if actual else 0.0)
        return {"precision": tuple(precision), "recall": tuple(recall)}

    @staticmethod
    def confusionMatrix(prediction: Tensor | Sequence[int], target: Sequence[int]) -> tuple[tuple[int, ...], ...]:
        labels, truth, classes = Metric._labels(prediction, target)
        matrix = [[0 for _ in range(classes)] for _ in range(classes)]
        for actual, predicted in zip(truth, labels):
            matrix[actual][predicted] += 1
        return tuple(tuple(row) for row in matrix)


class Optimizer:
    def __init__(self, parameters: Sequence[Tensor], learning_rate: float) -> None:
        _require(1 <= len(parameters) <= MAX_PARAMETERS and
                 all(isinstance(parameter, Tensor) for parameter in parameters),
                 "NEBO-G021-PARAMETERS")
        self.parameters = tuple(parameters)
        _require(sum(parameter.elements for parameter in parameters) <= MAX_PARAMETERS,
                 "NEBO-G021-PARAMETER-BUDGET")
        self.learning_rate = float(learning_rate)
        _require(math.isfinite(self.learning_rate) and self.learning_rate > 0.0,
                 "NEBO-G021-LEARNING-RATE")
        self._step = 0

    def zeroGrad(self) -> int:
        changed = 0
        for parameter in self.parameters:
            if parameter._gradient is not None:
                parameter._gradient = [0.0] * parameter.elements
                changed += parameter.elements
        return changed

    def state(self) -> dict[str, Any]:
        raise NotImplementedError

    def loadState(self, state: Mapping[str, Any]) -> None:
        raise NotImplementedError


class Sgd(Optimizer):
    def __init__(self, parameters: Sequence[Tensor], learning_rate: float,
                 options: Mapping[str, Any] | None = None) -> None:
        super().__init__(parameters, learning_rate)
        options = dict(options or {})
        self.momentum = float(options.pop("momentum", 0.0))
        self.weight_decay = float(options.pop("weightDecay", 0.0))
        _require(not options and math.isfinite(self.momentum) and 0.0 <= self.momentum < 1.0
                 and math.isfinite(self.weight_decay) and self.weight_decay >= 0.0,
                 "NEBO-G021-SGD-OPTION")
        self._velocity = [[0.0] * parameter.elements for parameter in self.parameters]

    @staticmethod
    def new(parameters: Sequence[Tensor], learningRate: float,
            options: Mapping[str, Any] | None = None) -> "Sgd":
        return Sgd(parameters, learningRate, options)

    def step(self) -> int:
        staged: list[tuple[list[float], list[float]]] = []
        for parameter, velocity in zip(self.parameters, self._velocity):
            _require(parameter._gradient is not None, "NEBO-G021-MISSING-GRADIENT")
            gradients_in = parameter._gradient
            _require(all(math.isfinite(value) for value in gradients_in), "NEBO-G021-NONFINITE")
            next_velocity = [self.momentum * old + grad + self.weight_decay * value
                             for old, grad, value in zip(velocity, gradients_in, parameter._values)]
            next_values = [value - self.learning_rate * delta
                           for value, delta in zip(parameter._values, next_velocity)]
            _require(all(math.isfinite(value) for value in next_values), "NEBO-G021-NONFINITE")
            staged.append((next_values, next_velocity))
        for parameter, velocity, (next_values, next_velocity) in zip(
                self.parameters, self._velocity, staged):
            parameter._values[:] = next_values
            velocity[:] = next_velocity
        self._step += 1
        return self._step

    def state(self) -> dict[str, Any]:
        return {"kind": "sgd", "step": self._step, "learningRate": self.learning_rate,
                "momentum": self.momentum, "weightDecay": self.weight_decay,
                "velocity": [list(values) for values in self._velocity]}

    def loadState(self, state: Mapping[str, Any]) -> None:
        try:
            _require(state.get("kind") == "sgd", "NEBO-G021-OPTIMIZER-STATE")
            step = int(state["step"])
            learning_rate = float(state["learningRate"])
            momentum = float(state["momentum"])
            weight_decay = float(state["weightDecay"])
            velocity = [[float(value) for value in row] for row in state["velocity"]]
        except (KeyError, TypeError, ValueError, OverflowError) as error:
            raise TrainingError("NEBO-G021-OPTIMIZER-STATE") from error
        _require(0 <= step <= 1_000_000 and math.isfinite(learning_rate)
                 and learning_rate > 0.0 and math.isfinite(momentum)
                 and 0.0 <= momentum < 1.0 and math.isfinite(weight_decay)
                 and weight_decay >= 0.0 and len(velocity) == len(self.parameters)
                 and all(len(row) == parameter.elements and all(math.isfinite(value)
                 for value in row) for row, parameter in zip(velocity, self.parameters)),
                 "NEBO-G021-OPTIMIZER-STATE")
        self._step = step
        self.learning_rate, self.momentum, self.weight_decay = learning_rate, momentum, weight_decay
        self._velocity = velocity


class Adam(Optimizer):
    def __init__(self, parameters: Sequence[Tensor], learning_rate: float,
                 options: Mapping[str, Any] | None = None) -> None:
        super().__init__(parameters, learning_rate)
        options = dict(options or {})
        self.beta1 = float(options.pop("beta1", 0.9))
        self.beta2 = float(options.pop("beta2", 0.999))
        self.epsilon = float(options.pop("epsilon", 1e-8))
        _require(not options and 0.0 <= self.beta1 < 1.0 and 0.0 <= self.beta2 < 1.0
                 and math.isfinite(self.epsilon) and 0.0 < self.epsilon <= 1e-2,
                 "NEBO-G021-ADAM-OPTION")
        self._first = [[0.0] * parameter.elements for parameter in self.parameters]
        self._second = [[0.0] * parameter.elements for parameter in self.parameters]

    @staticmethod
    def new(parameters: Sequence[Tensor], learningRate: float,
            options: Mapping[str, Any] | None = None) -> "Adam":
        return Adam(parameters, learningRate, options)

    def step(self) -> int:
        next_step = self._step + 1
        staged = []
        for parameter, first, second in zip(self.parameters, self._first, self._second):
            _require(parameter._gradient is not None, "NEBO-G021-MISSING-GRADIENT")
            grad = parameter._gradient
            _require(all(math.isfinite(value) for value in grad), "NEBO-G021-NONFINITE")
            next_first = [self.beta1 * old + (1.0 - self.beta1) * value
                          for old, value in zip(first, grad)]
            next_second = [self.beta2 * old + (1.0 - self.beta2) * value * value
                           for old, value in zip(second, grad)]
            corrected_first = [value / (1.0 - self.beta1 ** next_step) for value in next_first]
            corrected_second = [value / (1.0 - self.beta2 ** next_step) for value in next_second]
            next_values = [value - self.learning_rate * mean /
                           (math.sqrt(variance) + self.epsilon)
                           for value, mean, variance in zip(parameter._values,
                                                           corrected_first, corrected_second)]
            _require(all(math.isfinite(value) for value in next_values), "NEBO-G021-NONFINITE")
            staged.append((next_values, next_first, next_second))
        for parameter, first, second, values in zip(self.parameters, self._first,
                                                     self._second, staged):
            parameter._values[:], first[:], second[:] = values
        self._step = next_step
        return self._step

    def state(self) -> dict[str, Any]:
        return {"kind": "adam", "step": self._step, "learningRate": self.learning_rate,
                "beta1": self.beta1, "beta2": self.beta2, "epsilon": self.epsilon,
                "first": [list(values) for values in self._first],
                "second": [list(values) for values in self._second]}

    def loadState(self, state: Mapping[str, Any]) -> None:
        try:
            _require(state.get("kind") == "adam", "NEBO-G021-OPTIMIZER-STATE")
            step = int(state["step"])
            learning_rate = float(state["learningRate"])
            beta1 = float(state["beta1"])
            beta2 = float(state["beta2"])
            epsilon = float(state["epsilon"])
            first = [[float(value) for value in row] for row in state["first"]]
            second = [[float(value) for value in row] for row in state["second"]]
        except (KeyError, TypeError, ValueError, OverflowError) as error:
            raise TrainingError("NEBO-G021-OPTIMIZER-STATE") from error
        _require(0 <= step <= 1_000_000 and math.isfinite(learning_rate)
                 and learning_rate > 0.0 and 0.0 <= beta1 < 1.0 and 0.0 <= beta2 < 1.0
                 and math.isfinite(epsilon) and 0.0 < epsilon <= 1e-2
                 and len(first) == len(second) == len(self.parameters)
                 and all(len(one) == len(two) == parameter.elements and
                 all(math.isfinite(value) for value in one + two)
                 for one, two, parameter in zip(first, second, self.parameters)),
                 "NEBO-G021-OPTIMIZER-STATE")
        self._step, self._first, self._second = step, first, second
        self.learning_rate, self.beta1, self.beta2, self.epsilon = (
            learning_rate, beta1, beta2, epsilon)


class LearningRateScheduler:
    def __init__(self, initial: float, decay: float = 1.0, floor: float = 0.0) -> None:
        self.initial, self.decay, self.floor = float(initial), float(decay), float(floor)
        _require(math.isfinite(self.initial) and self.initial > 0.0 and
                 math.isfinite(self.decay) and 0.0 < self.decay <= 1.0 and
                 math.isfinite(self.floor) and 0.0 <= self.floor <= self.initial,
                 "NEBO-G021-SCHEDULER")

    def learningRate(self, step: int) -> float:
        _require(isinstance(step, int) and not isinstance(step, bool) and 0 <= step <= 1_000_000,
                 "NEBO-G021-SCHEDULER-STEP")
        return max(self.floor, self.initial * self.decay ** step)


class TinyLinearModel:
    """A tiny differentiable affine model used by local training examples."""

    def __init__(self, weight: float = 0.0, bias: float = 0.0) -> None:
        self.weight = Tensor([weight], (1,), True)
        self.bias = Tensor([bias], (1,), True)

    def parameters(self) -> tuple[Tensor, Tensor]:
        return self.weight, self.bias

    def namedParameters(self) -> dict[str, Tensor]:
        return {"bias": self.bias, "weight": self.weight}

    def forward(self, input: Tensor) -> Tensor:
        _require(input.shape == (1,), "NEBO-G021-MODEL-INPUT")
        return input.multiply(self.weight).add(self.bias)


class MlDataset:
    def __init__(self, samples: Iterable[Any], prefetch_count: int = 0) -> None:
        values = tuple(samples)
        _require(1 <= len(values) <= MAX_SAMPLES, "NEBO-G021-DATASET-BUDGET")
        self.samples = values
        self.prefetch_count = prefetch_count

    @staticmethod
    def fromDataset(dataset: Iterable[Any]) -> "MlDataset":
        return MlDataset(dataset)

    def shuffle(self, seed: int) -> "MlDataset":
        _require(isinstance(seed, int) and not isinstance(seed, bool), "NEBO-G021-SEED")
        values = list(self.samples)
        random.Random(seed).shuffle(values)
        return MlDataset(values, self.prefetch_count)

    def batch(self, size: int, dropLast: bool = False) -> tuple["MlDataset", ...]:
        _require(isinstance(size, int) and not isinstance(size, bool) and 1 <= size <= MAX_BATCH,
                 "NEBO-G021-BATCH-BUDGET")
        _require(isinstance(dropLast, bool), "NEBO-G021-DROP-LAST")
        batches = []
        for offset in range(0, len(self.samples), size):
            part = self.samples[offset:offset + size]
            if len(part) < size and dropLast:
                break
            batches.append(MlDataset(part, self.prefetch_count))
        return tuple(batches)

    def prefetch(self, count: int) -> "MlDataset":
        _require(isinstance(count, int) and not isinstance(count, bool)
                 and 0 <= count <= MAX_PREFETCH, "NEBO-G021-PREFETCH-BUDGET")
        return MlDataset(self.samples, count)

    def map(self, transform: Callable[[Any], Any]) -> "MlDataset":
        _require(callable(transform), "NEBO-G021-TRANSFORM")
        staged = tuple(transform(sample) for sample in self.samples)
        return MlDataset(staged, self.prefetch_count)

    def split(self, ratios: Sequence[float], seed: int) -> tuple["MlDataset", ...]:
        _require(2 <= len(ratios) <= 8, "NEBO-G021-SPLIT-RATIO")
        converted = tuple(float(value) for value in ratios)
        _require(all(math.isfinite(value) and value > 0.0 for value in converted)
                 and math.isclose(math.fsum(converted), 1.0, abs_tol=1e-12),
                 "NEBO-G021-SPLIT-RATIO")
        shuffled = self.shuffle(seed).samples
        boundaries, assigned = [], 0
        for ratio in converted[:-1]:
            assigned += int(len(shuffled) * ratio)
            boundaries.append(assigned)
        parts, start = [], 0
        for end in boundaries + [len(shuffled)]:
            _require(end > start, "NEBO-G021-SPLIT-EMPTY")
            parts.append(MlDataset(shuffled[start:end], self.prefetch_count))
            start = end
        return tuple(parts)


setattr(MlDataset, "from", staticmethod(MlDataset.fromDataset))


class Augmentation:
    def compose(self, stages: Sequence[Callable[[Any], Any]]) -> Callable[[Any], Any]:
        pipeline = tuple(stages)
        _require(1 <= len(pipeline) <= 32 and all(callable(stage) for stage in pipeline),
                 "NEBO-G021-AUGMENTATION")

        def apply(value: Any) -> Any:
            for stage in pipeline:
                value = stage(value)
            return value

        return apply


augmentation = Augmentation()


class Trainer:
    def __init__(self, model: Any, optimizer: Optimizer,
                 loss: Callable[[Tensor, Tensor], Tensor],
                 options: Mapping[str, Any] | None = None) -> None:
        options = dict(options or {})
        _require(callable(getattr(model, "forward", None)) and isinstance(optimizer, Optimizer)
                 and callable(loss), "NEBO-G021-TRAINER-INPUT")
        self.model, self.optimizer, self.loss = model, optimizer, loss
        self.max_epochs = int(options.pop("maxEpochs", MAX_EPOCHS))
        _require(not options and 1 <= self.max_epochs <= MAX_EPOCHS,
                 "NEBO-G021-EPOCH-BUDGET")
        self._callbacks: list[Callable[[dict[str, Any]], None]] = []
        self._early: tuple[str, int] | None = None
        self._history: list[dict[str, Any]] = []
        self._batches = 0

    @staticmethod
    def new(model: Any, optimizer: Optimizer,
            loss: Callable[[Tensor, Tensor], Tensor],
            options: Mapping[str, Any] | None = None) -> "Trainer":
        return Trainer(model, optimizer, loss, options)

    @staticmethod
    def _dataset(dataset: MlDataset | Iterable[Any]) -> MlDataset:
        return dataset if isinstance(dataset, MlDataset) else MlDataset(dataset)

    def trainBatch(self, batch: MlDataset | Iterable[tuple[Tensor, Tensor]]) -> float:
        source = Trainer._dataset(batch)
        _require(len(source.samples) <= MAX_BATCH, "NEBO-G021-BATCH-BUDGET")
        parameter_gradients = [[0.0] * parameter.elements for parameter in self.optimizer.parameters]
        losses: list[float] = []
        previous_gradients = [None if parameter._gradient is None else list(parameter._gradient)
                              for parameter in self.optimizer.parameters]
        try:
            for sample in source.samples:
                _require(isinstance(sample, tuple) and len(sample) == 2,
                         "NEBO-G021-DATASET-SAMPLE")
                input_value, target = sample
                _require(isinstance(input_value, Tensor) and isinstance(target, Tensor),
                         "NEBO-G021-DATASET-SAMPLE")
                self.optimizer.zeroGrad()
                observed = self.model.forward(input_value)
                loss = self.loss(observed, target)
                _require(isinstance(loss, Tensor) and loss.elements == 1,
                         "NEBO-G021-LOSS-RESULT")
                loss.backward()
                losses.append(loss.values[0])
                for aggregate, parameter in zip(parameter_gradients, self.optimizer.parameters):
                    _require(parameter._gradient is not None, "NEBO-G021-MISSING-GRADIENT")
                    for index, value in enumerate(parameter._gradient):
                        aggregate[index] += value / len(source.samples)
                # Backward state is already owned by tensors; releasing the registry
                # here bounds graph lifetime independently of epoch count.
                graph.clear()
            for parameter, aggregate in zip(self.optimizer.parameters, parameter_gradients):
                parameter._gradient = aggregate
            self.optimizer.step()
        except Exception:
            for parameter, previous in zip(self.optimizer.parameters, previous_gradients):
                parameter._gradient = previous
            graph.clear()
            raise
        self._batches += 1
        return math.fsum(losses) / len(losses)

    def fit(self, dataset: MlDataset | Iterable[tuple[Tensor, Tensor]], epochs: int) -> tuple[dict[str, Any], ...]:
        _require(isinstance(epochs, int) and not isinstance(epochs, bool)
                 and 1 <= epochs <= self.max_epochs, "NEBO-G021-EPOCH-BUDGET")
        source = Trainer._dataset(dataset)
        best = math.inf
        stale = 0
        for epoch in range(1, epochs + 1):
            value = self.trainBatch(source)
            entry = {"epoch": epoch, "loss": value, "batches": self._batches}
            for callback in tuple(self._callbacks):
                callback(dict(entry))
            self._history.append(entry)
            if self._early is not None:
                _metric, patience = self._early
                if value < best - 1e-12:
                    best, stale = value, 0
                else:
                    stale += 1
                    if stale >= patience:
                        break
        return tuple(dict(entry) for entry in self._history)

    def evaluate(self, dataset: MlDataset | Iterable[tuple[Tensor, Tensor]]) -> float:
        source = Trainer._dataset(dataset)
        values = []
        with autograd.recording(False):
            for input_value, target in source.samples:
                values.append(self.loss(self.model.forward(input_value), target).values[0])
        return math.fsum(values) / len(values)

    def onEpoch(self, handler: Callable[[dict[str, Any]], None]) -> "Trainer":
        _require(callable(handler) and len(self._callbacks) < 32, "NEBO-G021-CALLBACK")
        self._callbacks.append(handler)
        return self

    def earlyStopping(self, metric: str, patience: int) -> "Trainer":
        _require(metric == "loss" and isinstance(patience, int) and not isinstance(patience, bool)
                 and 1 <= patience <= MAX_EPOCHS, "NEBO-G021-EARLY-STOPPING")
        self._early = metric, patience
        return self

    def progress(self) -> dict[str, Any]:
        return {"epochs": len(self._history), "batches": self._batches,
                "latest": dict(self._history[-1]) if self._history else None}


def _named_parameters(model: Any) -> dict[str, Tensor]:
    if callable(getattr(model, "namedParameters", None)):
        result = dict(model.namedParameters())
    elif callable(getattr(model, "parameters", None)):
        values = tuple(model.parameters())
        if values and isinstance(values[0], tuple):
            result = dict(values)
        else:
            result = {str(index): value for index, value in enumerate(values)}
    else:
        raise TrainingError("NEBO-G021-CHECKPOINT-MODEL")
    _require(result and all(isinstance(name, str) and isinstance(value, Tensor)
                            for name, value in result.items()),
             "NEBO-G021-CHECKPOINT-MODEL")
    return dict(sorted(result.items()))


def _local_path(path: str | os.PathLike[str]) -> Path:
    candidate = Path(path)
    _require(candidate.name not in {"", ".", ".."} and not candidate.is_symlink()
             and not any(parent.is_symlink() for parent in candidate.parents),
             "NEBO-G021-CHECKPOINT-PATH")
    return candidate


@dataclass(frozen=True)
class CheckpointRecord:
    path: Path
    document: Mapping[str, Any]
    digest: str

    def rotate(self, policy: int | Mapping[str, Any]) -> tuple[Path, ...]:
        try:
            keep = int(policy.get("keep", 1)) if isinstance(policy, Mapping) else int(policy)
        except (TypeError, ValueError, OverflowError) as error:
            raise TrainingError("NEBO-G021-ROTATION-POLICY") from error
        _require(1 <= keep <= MAX_ROTATIONS, "NEBO-G021-ROTATION-POLICY")
        siblings = sorted(self.path.parent.glob(self.path.name + ".*"),
                          key=lambda item: item.name)
        _require(all(candidate.is_file() and not candidate.is_symlink()
                     for candidate in siblings), "NEBO-G021-CHECKPOINT-PATH")
        removed: list[Path] = []
        for candidate in siblings[:-keep]:
            candidate.unlink()
            removed.append(candidate)
        return tuple(removed)

    def compare(self, other: "CheckpointRecord") -> dict[str, Any]:
        _require(isinstance(other, CheckpointRecord), "NEBO-G021-CHECKPOINT-COMPARE")
        left_parameters = self.document["payload"]["model"]
        right_parameters = other.document["payload"]["model"]
        changed = tuple(sorted(name for name in set(left_parameters) | set(right_parameters)
                               if left_parameters.get(name) != right_parameters.get(name)))
        return {"equal": self.digest == other.digest, "changedParameters": changed,
                "leftDigest": self.digest, "rightDigest": other.digest}

    def restore(self, model: Any, optimizer: Optimizer) -> dict[str, Any]:
        live = _named_parameters(model)
        serialized = self.document["payload"]["model"]
        _require(set(live) == set(serialized), "NEBO-G021-CHECKPOINT-MODEL")
        staged: dict[str, Tensor] = {}
        for name, parameter in live.items():
            candidate = Tensor(serialized[name]["values"], serialized[name]["shape"])
            _require(candidate.shape == parameter.shape, "NEBO-G021-SHAPE-MISMATCH")
            staged[name] = candidate
        optimizer.loadState(self.document["payload"]["optimizer"])
        for name, parameter in live.items():
            parameter._values[:] = staged[name]._values
        return dict(self.document["payload"]["state"])


class Checkpoint:
    @staticmethod
    def save(path: str | os.PathLike[str], model: Any, optimizer: Optimizer,
             state: Mapping[str, Any]) -> CheckpointRecord:
        destination = _local_path(path)
        parameters = {name: {"shape": list(tensor.shape), "values": list(tensor.values)}
                      for name, tensor in _named_parameters(model).items()}
        payload = {"model": parameters, "optimizer": optimizer.state(),
                   "state": dict(state)}
        payload_bytes = _canonical(payload)
        document = {"magic": CHECKPOINT_MAGIC, "version": CHECKPOINT_VERSION,
                    "checksum": hashlib.sha256(payload_bytes).hexdigest(),
                    "payload": payload}
        serialized = _canonical(document)
        _require(len(serialized) <= MAX_CHECKPOINT_BYTES, "NEBO-G021-CHECKPOINT-BUDGET")
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_name(destination.name + ".tmp-g021")
        try:
            with temporary.open("xb") as handle:
                handle.write(serialized)
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(temporary, destination)
        except OSError as error:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass
            raise TrainingError("NEBO-G021-CHECKPOINT-IO") from error
        return CheckpointRecord(destination, document, hashlib.sha256(serialized).hexdigest())

    @staticmethod
    def load(path: str | os.PathLike[str]) -> CheckpointRecord:
        source = _local_path(path)
        _require(source.is_file(), "NEBO-G021-CHECKPOINT-PATH")
        try:
            raw = source.read_bytes()
            _require(len(raw) <= MAX_CHECKPOINT_BYTES, "NEBO-G021-CHECKPOINT-BUDGET")
            document = json.loads(raw)
        except (OSError, json.JSONDecodeError, UnicodeDecodeError) as error:
            raise TrainingError("NEBO-G021-CHECKPOINT-MALFORMED") from error
        _require(isinstance(document, dict) and document.get("magic") == CHECKPOINT_MAGIC
                 and document.get("version") == CHECKPOINT_VERSION,
                 "NEBO-G021-CHECKPOINT-HEADER")
        _require(set(document) == {"magic", "version", "checksum", "payload"},
                 "NEBO-G021-CHECKPOINT-MALFORMED")
        payload = document["payload"]
        _require(raw == _canonical(document) and isinstance(payload, dict)
                 and set(payload) == {"model", "optimizer", "state"}
                 and isinstance(payload["model"], dict) and payload["model"]
                 and isinstance(payload["optimizer"], dict)
                 and isinstance(payload["state"], dict),
                 "NEBO-G021-CHECKPOINT-MALFORMED")
        for name, tensor in payload["model"].items():
            _require(isinstance(name, str) and isinstance(tensor, dict)
                     and set(tensor) == {"shape", "values"},
                     "NEBO-G021-CHECKPOINT-MALFORMED")
            try:
                Tensor(tensor["values"], tensor["shape"])
            except (TrainingError, TypeError) as error:
                raise TrainingError("NEBO-G021-CHECKPOINT-MALFORMED") from error
        _require(hashlib.sha256(_canonical(payload)).hexdigest() == document["checksum"],
                 "NEBO-G021-CHECKPOINT-CHECKSUM")
        return CheckpointRecord(source, document, hashlib.sha256(raw).hexdigest())


class Training:
    def __init__(self) -> None:
        self._seed = 0
        self._deterministic = True

    def seedAll(self, seed: int) -> dict[str, int]:
        _require(isinstance(seed, int) and not isinstance(seed, bool)
                 and 0 <= seed <= 0xFFFFFFFFFFFFFFFF, "NEBO-G021-SEED")
        self._seed = seed
        random.seed(seed)
        return {"python": seed, "nebo": seed}

    def deterministic(self, enabled: bool) -> bool:
        _require(isinstance(enabled, bool), "NEBO-G021-DETERMINISTIC")
        self._deterministic = enabled
        return self._deterministic

    def environmentManifest(self) -> dict[str, Any]:
        return {"profile": "g021-bounded-cpu", "python": platform.python_version(),
                "byteorder": sys.byteorder, "seed": self._seed,
                "deterministic": self._deterministic,
                "limits": {"batch": MAX_BATCH, "elements": MAX_ELEMENTS,
                           "epochs": MAX_EPOCHS, "graphNodes": MAX_GRAPH_NODES},
                "networkDownloads": 0}


training = Training()


__all__ = [
    "Adam", "Autograd", "Checkpoint", "CheckpointRecord", "ComputationGraph",
    "GradientSet", "LearningRateScheduler", "Loss", "Metric", "MlDataset",
    "Operation", "Sgd", "Tensor", "TinyLinearModel", "Trainer", "TrainingError",
    "augmentation", "autograd", "gradients", "graph", "training",
]
