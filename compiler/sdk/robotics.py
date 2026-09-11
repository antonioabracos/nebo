"""Deterministic G041 robotics, control, DSP, and sensor-fusion reference API.

The module is deliberately dependency-free.  It is a bounded simulation API: it
does not open devices, claim hard real-time behaviour, or actuate hardware.
Public results are immutable so callers cannot mutate hidden controller state.
"""

from __future__ import annotations

import cmath
import hashlib
import json
import math
from dataclasses import dataclass
from types import MappingProxyType
from typing import Any, Callable, Iterable, Mapping, Sequence


MAX_SAMPLES = 4096
MAX_TRANSFORM_POINTS = 256
MAX_MATRIX_DIMENSION = 16
MAX_LOOP_TICKS = 512
EPSILON = 1.0e-12


class RoboticsError(ValueError):
    """Stable failure carrying a machine-readable code and operation."""

    def __init__(self, code: str, operation: str, message: str) -> None:
        super().__init__(f"{code}: {operation}: {message}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, message: str) -> None:
    raise RoboticsError(code, operation, message)


def _number(value: Any, operation: str, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        _fail("INVALID_NUMBER", operation, f"{name} must be numeric")
    result = float(value)
    if not math.isfinite(result):
        _fail("NON_FINITE", operation, f"{name} must be finite")
    return result


def _positive(value: Any, operation: str, name: str) -> float:
    result = _number(value, operation, name)
    if result <= 0.0:
        _fail("OUT_OF_RANGE", operation, f"{name} must be positive")
    return result


def _integer(value: Any, operation: str, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        _fail("INVALID_INTEGER", operation, f"{name} must be an integer")
    if value < minimum or value > maximum:
        _fail("OUT_OF_RANGE", operation, f"{name} must be in [{minimum}, {maximum}]")
    return value


def _text(value: Any, operation: str, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        _fail("INVALID_TEXT", operation, f"{name} must be non-empty text")
    return value.strip()


def _vector(
    values: Any,
    operation: str,
    name: str,
    *,
    length: int | None = None,
    maximum: int = MAX_MATRIX_DIMENSION,
) -> tuple[float, ...]:
    if isinstance(values, (str, bytes, bytearray)) or not isinstance(values, Sequence):
        _fail("INVALID_VECTOR", operation, f"{name} must be a numeric sequence")
    result = tuple(_number(value, operation, f"{name}[{index}]") for index, value in enumerate(values))
    if length is not None and len(result) != length:
        _fail("DIMENSION_MISMATCH", operation, f"{name} must contain {length} values")
    if not result:
        _fail("EMPTY_VECTOR", operation, f"{name} cannot be empty")
    if len(result) > maximum:
        _fail("LIMIT_EXCEEDED", operation, f"{name} exceeds {maximum} values")
    return result


def _matrix(values: Any, operation: str, name: str) -> tuple[tuple[float, ...], ...]:
    if isinstance(values, (str, bytes, bytearray)) or not isinstance(values, Sequence) or not values:
        _fail("INVALID_MATRIX", operation, f"{name} must be a non-empty matrix")
    rows = tuple(_vector(row, operation, f"{name}[{index}]") for index, row in enumerate(values))
    width = len(rows[0])
    if len(rows) > MAX_MATRIX_DIMENSION or width > MAX_MATRIX_DIMENSION:
        _fail("LIMIT_EXCEEDED", operation, f"{name} exceeds {MAX_MATRIX_DIMENSION}x{MAX_MATRIX_DIMENSION}")
    if any(len(row) != width for row in rows):
        _fail("RAGGED_MATRIX", operation, f"{name} rows must have equal length")
    return rows


def _options(value: Any, operation: str) -> Mapping[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, Mapping):
        _fail("INVALID_OPTIONS", operation, "options must be a mapping")
    return value


def _freeze_mapping(value: Mapping[str, Any]) -> Mapping[str, Any]:
    def freeze(item: Any) -> Any:
        if isinstance(item, Mapping):
            return MappingProxyType({str(key): freeze(inner) for key, inner in item.items()})
        if isinstance(item, (list, tuple)):
            return tuple(freeze(inner) for inner in item)
        return item

    return freeze(value)


def _dot(row: Sequence[float], vector: Sequence[float]) -> float:
    return sum(left * right for left, right in zip(row, vector))


def _matmul(left: Sequence[Sequence[float]], right: Sequence[Sequence[float]]) -> tuple[tuple[float, ...], ...]:
    columns = tuple(zip(*right))
    return tuple(tuple(_dot(row, column) for column in columns) for row in left)


def _identity(size: int) -> tuple[tuple[float, ...], ...]:
    return tuple(tuple(1.0 if row == column else 0.0 for column in range(size)) for row in range(size))


def _rank(matrix: Sequence[Sequence[float]]) -> int:
    work = [list(row) for row in matrix]
    if not work:
        return 0
    row_count = len(work)
    column_count = len(work[0])
    pivot_row = 0
    for column in range(column_count):
        pivot = max(range(pivot_row, row_count), key=lambda row: abs(work[row][column]), default=pivot_row)
        if pivot_row >= row_count or abs(work[pivot][column]) <= EPSILON:
            continue
        work[pivot_row], work[pivot] = work[pivot], work[pivot_row]
        divisor = work[pivot_row][column]
        work[pivot_row] = [value / divisor for value in work[pivot_row]]
        for row in range(row_count):
            if row == pivot_row:
                continue
            factor = work[row][column]
            work[row] = [value - factor * base for value, base in zip(work[row], work[pivot_row])]
        pivot_row += 1
        if pivot_row == row_count:
            break
    return pivot_row


@dataclass(frozen=True)
class SignalSample:
    value: float | None
    timestamp: float


@dataclass(frozen=True)
class SpectrumBin:
    frequency: float
    magnitude: float
    phase: float


class SignalBuffer:
    """Bounded timestamped signal buffer with explicit rate and unit."""

    def __init__(self, capacity: int, sample_rate: float, unit: str) -> None:
        operation = "SignalBuffer.new"
        self.capacity = _integer(capacity, operation, "capacity", 2, MAX_SAMPLES)
        self.sample_rate = _positive(sample_rate, operation, "sampleRate")
        self.unit = _text(unit, operation, "unit")
        self._samples: list[SignalSample] = []

    @classmethod
    def new(cls, capacity: int, sampleRate: float, unit: str) -> "SignalBuffer":
        return cls(capacity, sampleRate, unit)

    def push(self, sample: float | None, timestamp: float) -> "SignalBuffer":
        operation = "signal.push"
        stamp = _number(timestamp, operation, "timestamp")
        if self._samples and stamp <= self._samples[-1].timestamp:
            _fail("NON_MONOTONIC_TIMESTAMP", operation, "timestamp must increase strictly")
        numeric = None if sample is None else _number(sample, operation, "sample")
        self._samples.append(SignalSample(numeric, stamp))
        if len(self._samples) > self.capacity:
            self._samples.pop(0)
        return self

    def window(self, count: int) -> tuple[SignalSample, ...]:
        size = _integer(count, "signal.window", "count", 1, self.capacity)
        return tuple(self._samples[-size:])

    def _numeric_samples(self, operation: str) -> tuple[SignalSample, ...]:
        if len(self._samples) < 2:
            _fail("INSUFFICIENT_SAMPLES", operation, "at least two samples are required")
        if any(sample.value is None for sample in self._samples):
            _fail("MISSING_SAMPLE", operation, "transform requires samples without missing values")
        return tuple(self._samples)

    def interpolate(self, timestamp: float, method: str) -> float:
        operation = "signal.interpolate"
        stamp = _number(timestamp, operation, "timestamp")
        interpolation = _text(method, operation, "method").lower()
        if interpolation not in {"linear", "nearest"}:
            _fail("UNSUPPORTED_METHOD", operation, "method must be linear or nearest")
        samples = self._numeric_samples(operation)
        if stamp < samples[0].timestamp or stamp > samples[-1].timestamp:
            _fail("TIMESTAMP_OUTSIDE_WINDOW", operation, "timestamp is outside buffered data")
        for left, right in zip(samples, samples[1:]):
            if stamp <= right.timestamp:
                assert left.value is not None and right.value is not None
                if interpolation == "nearest":
                    return left.value if stamp - left.timestamp <= right.timestamp - stamp else right.value
                ratio = (stamp - left.timestamp) / (right.timestamp - left.timestamp)
                return left.value + ratio * (right.value - left.value)
        assert samples[-1].value is not None
        return samples[-1].value

    def resample(self, rate: float, method: str) -> tuple[SignalSample, ...]:
        operation = "signal.resample"
        target_rate = _positive(rate, operation, "rate")
        samples = self._numeric_samples(operation)
        duration = samples[-1].timestamp - samples[0].timestamp
        count = int(math.floor(duration * target_rate + EPSILON)) + 1
        if count < 2 or count > MAX_SAMPLES:
            _fail("LIMIT_EXCEEDED", operation, f"resampling would create {count} samples")
        return tuple(
            SignalSample(self.interpolate(samples[0].timestamp + index / target_rate, method), samples[0].timestamp + index / target_rate)
            for index in range(count)
        )

    def decimate(self, factor: int, filter: "Filter") -> tuple[SignalSample, ...]:
        operation = "signal.decimate"
        stride = _integer(factor, operation, "factor", 2, self.capacity)
        if not isinstance(filter, Filter) or filter.kind not in {"lowpass", "bandpass", "moving-average"}:
            _fail("ANTI_ALIAS_FILTER_REQUIRED", operation, "an explicit smoothing filter is required")
        samples = self._numeric_samples(operation)
        filter.reset(None)
        filtered = [SignalSample(filter.step(sample.value), sample.timestamp) for sample in samples]
        return tuple(filtered[::stride])

    def spectrum(self, options: Mapping[str, Any] | None) -> tuple[SpectrumBin, ...]:
        operation = "signal.spectrum"
        config = _options(options, operation)
        samples = self._numeric_samples(operation)
        if len(samples) > MAX_TRANSFORM_POINTS:
            _fail("LIMIT_EXCEEDED", operation, f"spectrum is bounded to {MAX_TRANSFORM_POINTS} samples")
        window = str(config.get("window", "hann")).lower()
        if window not in {"hann", "rectangular"}:
            _fail("UNSUPPORTED_WINDOW", operation, "window must be hann or rectangular")
        values = [float(sample.value) for sample in samples if sample.value is not None]
        if window == "hann" and len(values) > 1:
            values = [value * (0.5 - 0.5 * math.cos(2.0 * math.pi * index / (len(values) - 1))) for index, value in enumerate(values)]
        bins: list[SpectrumBin] = []
        for frequency_index in range(len(values) // 2 + 1):
            coefficient = sum(
                value * cmath.exp(-2j * math.pi * frequency_index * index / len(values))
                for index, value in enumerate(values)
            )
            bins.append(
                SpectrumBin(
                    frequency_index * self.sample_rate / len(values),
                    abs(coefficient) / len(values),
                    cmath.phase(coefficient),
                )
            )
        return tuple(bins)

    def statistics(self) -> Mapping[str, Any]:
        numeric = [sample.value for sample in self._samples if sample.value is not None]
        if not numeric:
            _fail("NO_NUMERIC_SAMPLES", "signal.statistics", "buffer has no numeric samples")
        mean = sum(numeric) / len(numeric)
        return _freeze_mapping(
            {
                "count": len(self._samples),
                "missing": len(self._samples) - len(numeric),
                "mean": mean,
                "minimum": min(numeric),
                "maximum": max(numeric),
                "rms": math.sqrt(sum(value * value for value in numeric) / len(numeric)),
                "unit": self.unit,
                "sampleRate": self.sample_rate,
            }
        )


@dataclass(frozen=True)
class FrequencyResponsePoint:
    frequency: float
    magnitude: float
    phase: float


class Filter:
    """Stateful scalar filters with bounded, deterministic configuration."""

    def __init__(self, kind: str, parameters: Mapping[str, Any]) -> None:
        self.kind = kind
        self.parameters = MappingProxyType(dict(parameters))
        self._states: list[float] = []
        self._window: list[float] = []
        self._estimate = float(parameters.get("initialState", 0.0))
        self._covariance = float(parameters.get("initialCovariance", 1.0))

    @classmethod
    def lowPass(cls, cutoff: float, sampleRate: float, order: int) -> "Filter":
        operation = "Filter.lowPass"
        cutoff_value = _positive(cutoff, operation, "cutoff")
        rate = _positive(sampleRate, operation, "sampleRate")
        filter_order = _integer(order, operation, "order", 1, 2)
        if cutoff_value >= rate / 2.0:
            _fail("NYQUIST_VIOLATION", operation, "cutoff must be below Nyquist frequency")
        return cls("lowpass", {"cutoff": cutoff_value, "sampleRate": rate, "order": filter_order})

    @classmethod
    def highPass(cls, cutoff: float, sampleRate: float, order: int) -> "Filter":
        operation = "Filter.highPass"
        cutoff_value = _positive(cutoff, operation, "cutoff")
        rate = _positive(sampleRate, operation, "sampleRate")
        filter_order = _integer(order, operation, "order", 1, 2)
        if cutoff_value >= rate / 2.0:
            _fail("NYQUIST_VIOLATION", operation, "cutoff must be below Nyquist frequency")
        return cls("highpass", {"cutoff": cutoff_value, "sampleRate": rate, "order": filter_order})

    @classmethod
    def bandPass(cls, low: float, high: float, sampleRate: float) -> "Filter":
        operation = "Filter.bandPass"
        low_value = _positive(low, operation, "low")
        high_value = _positive(high, operation, "high")
        rate = _positive(sampleRate, operation, "sampleRate")
        if low_value >= high_value or high_value >= rate / 2.0:
            _fail("INVALID_BAND", operation, "require 0 < low < high < Nyquist")
        return cls("bandpass", {"low": low_value, "high": high_value, "sampleRate": rate})

    @classmethod
    def movingAverage(cls, window: int) -> "Filter":
        size = _integer(window, "Filter.movingAverage", "window", 1, MAX_TRANSFORM_POINTS)
        return cls("moving-average", {"window": size})

    @classmethod
    def kalman(cls, model: Mapping[str, Any], processNoise: float, measurementNoise: float) -> "Filter":
        operation = "Filter.kalman"
        if not isinstance(model, Mapping):
            _fail("INVALID_MODEL", operation, "model must be a mapping")
        transition = _number(model.get("transition", 1.0), operation, "model.transition")
        measurement = _number(model.get("measurement", 1.0), operation, "model.measurement")
        process = _positive(processNoise, operation, "processNoise")
        noise = _positive(measurementNoise, operation, "measurementNoise")
        return cls(
            "kalman",
            {
                "transition": transition,
                "measurement": measurement,
                "processNoise": process,
                "measurementNoise": noise,
                "initialState": _number(model.get("initialState", 0.0), operation, "model.initialState"),
                "initialCovariance": _positive(model.get("initialCovariance", 1.0), operation, "model.initialCovariance"),
            },
        )

    def _alpha(self, cutoff: float, rate: float) -> float:
        dt = 1.0 / rate
        rc = 1.0 / (2.0 * math.pi * cutoff)
        return dt / (rc + dt)

    def step(self, value: float | None) -> float:
        operation = "filter.step"
        sample = _number(value, operation, "value")
        if self.kind == "moving-average":
            self._window.append(sample)
            self._window = self._window[-int(self.parameters["window"]):]
            return sum(self._window) / len(self._window)
        if self.kind == "kalman":
            transition = float(self.parameters["transition"])
            measurement = float(self.parameters["measurement"])
            predicted = transition * self._estimate
            predicted_covariance = transition * transition * self._covariance + float(self.parameters["processNoise"])
            innovation_covariance = measurement * measurement * predicted_covariance + float(self.parameters["measurementNoise"])
            gain = predicted_covariance * measurement / innovation_covariance
            self._estimate = predicted + gain * (sample - measurement * predicted)
            self._covariance = (1.0 - gain * measurement) * predicted_covariance
            return self._estimate
        if self.kind == "bandpass":
            high_alpha = self._alpha(float(self.parameters["high"]), float(self.parameters["sampleRate"]))
            low_alpha = self._alpha(float(self.parameters["low"]), float(self.parameters["sampleRate"]))
            low_state = self._states[0] if self._states else sample
            slow_state = self._states[1] if len(self._states) > 1 else sample
            low_state += high_alpha * (sample - low_state)
            slow_state += low_alpha * (sample - slow_state)
            self._states = [low_state, slow_state]
            return low_state - slow_state
        cutoff = float(self.parameters["cutoff"])
        rate = float(self.parameters["sampleRate"])
        alpha = self._alpha(cutoff, rate)
        stages = int(self.parameters["order"])
        while len(self._states) < stages * 2:
            self._states.append(sample)
        current = sample
        for stage in range(stages):
            state_index = stage * 2
            previous_output = self._states[state_index]
            previous_input = self._states[state_index + 1]
            if self.kind == "lowpass":
                output = previous_output + alpha * (current - previous_output)
            else:
                output = (1.0 - alpha) * (previous_output + current - previous_input)
            self._states[state_index] = output
            self._states[state_index + 1] = current
            current = output
        return current

    def reset(self, state: Any) -> "Filter":
        operation = "filter.reset"
        self._states.clear()
        self._window.clear()
        if self.kind == "kalman":
            if state is None:
                self._estimate = float(self.parameters["initialState"])
                self._covariance = float(self.parameters["initialCovariance"])
            elif isinstance(state, Mapping):
                self._estimate = _number(state.get("estimate"), operation, "state.estimate")
                self._covariance = _positive(state.get("covariance"), operation, "state.covariance")
            else:
                self._estimate = _number(state, operation, "state")
                self._covariance = float(self.parameters["initialCovariance"])
        elif state is not None:
            initial = _number(state, operation, "state")
            self._states = [initial] * int(self.parameters.get("order", 1)) * 2
            self._window = [initial]
        return self

    def frequencyResponse(self, points: int) -> tuple[FrequencyResponsePoint, ...]:
        operation = "filter.frequencyResponse"
        count = _integer(points, operation, "points", 2, MAX_TRANSFORM_POINTS)
        if self.kind == "kalman":
            _fail("UNSUPPORTED_OPERATION", operation, "Kalman gain is state-dependent")
        rate = float(self.parameters.get("sampleRate", 1.0))
        results: list[FrequencyResponsePoint] = []
        for index in range(count):
            frequency = (rate / 2.0) * index / (count - 1)
            if self.kind == "moving-average":
                size = int(self.parameters["window"])
                omega = math.pi * index / (count - 1)
                if abs(math.sin(omega / 2.0)) <= EPSILON:
                    response = complex(1.0, 0.0)
                else:
                    response = cmath.exp(-1j * omega * (size - 1) / 2.0) * math.sin(size * omega / 2.0) / (size * math.sin(omega / 2.0))
            else:
                omega = 2.0 * math.pi * frequency / rate
                z_inverse = cmath.exp(-1j * omega)
                if self.kind == "bandpass":
                    low_alpha = self._alpha(float(self.parameters["low"]), rate)
                    high_alpha = self._alpha(float(self.parameters["high"]), rate)
                    slow = low_alpha / (1.0 - (1.0 - low_alpha) * z_inverse)
                    fast = high_alpha / (1.0 - (1.0 - high_alpha) * z_inverse)
                    response = fast - slow
                else:
                    alpha = self._alpha(float(self.parameters["cutoff"]), rate)
                    low_response = alpha / (1.0 - (1.0 - alpha) * z_inverse)
                    response = low_response if self.kind == "lowpass" else 1.0 - low_response
                    response **= int(self.parameters["order"])
            results.append(FrequencyResponsePoint(frequency, abs(response), cmath.phase(response)))
        return tuple(results)


@dataclass(frozen=True)
class PidStep:
    output: float
    error: float
    proportional: float
    integral: float
    derivative: float
    saturated: bool


class PidController:
    def __init__(self, kp: float, ki: float, kd: float, options: Mapping[str, Any] | None) -> None:
        operation = "PidController.new"
        self.kp = _number(kp, operation, "kp")
        self.ki = _number(ki, operation, "ki")
        self.kd = _number(kd, operation, "kd")
        config = _options(options, operation)
        self.anti_windup = str(config.get("antiWindup", "clamp")).lower()
        if self.anti_windup not in {"clamp", "disabled"}:
            _fail("UNSUPPORTED_POLICY", operation, "antiWindup must be clamp or disabled")
        self.derivative_filter = _positive(config.get("derivativeFilter", 1.0), operation, "derivativeFilter")
        self.target = 0.0
        self.minimum = -math.inf
        self.maximum = math.inf
        self._integral = 0.0
        self._previous_error: float | None = None
        self._previous_derivative = 0.0
        self._trace: list[PidStep] = []

    @classmethod
    def new(cls, kp: float, ki: float, kd: float, options: Mapping[str, Any] | None) -> "PidController":
        return cls(kp, ki, kd, options)

    def setTarget(self, value: float) -> "PidController":
        self.target = _number(value, "controller.setTarget", "value")
        return self

    def setLimits(self, min: float, max: float) -> "PidController":
        minimum = _number(min, "controller.setLimits", "min")
        maximum = _number(max, "controller.setLimits", "max")
        if minimum >= maximum:
            _fail("INVALID_LIMITS", "controller.setLimits", "min must be lower than max")
        self.minimum = minimum
        self.maximum = maximum
        return self

    def step(self, measurement: float, dt: float) -> PidStep:
        operation = "controller.step"
        observed = _number(measurement, operation, "measurement")
        interval = _positive(dt, operation, "dt")
        error = self.target - observed
        candidate_integral = self._integral + error * interval
        raw_derivative = 0.0 if self._previous_error is None else (error - self._previous_error) / interval
        blend = min(1.0, interval * self.derivative_filter)
        derivative_state = self._previous_derivative + blend * (raw_derivative - self._previous_derivative)
        proportional = self.kp * error
        integral_term = self.ki * candidate_integral
        derivative_term = self.kd * derivative_state
        raw_output = proportional + integral_term + derivative_term
        output = max(self.minimum, min(self.maximum, raw_output))
        saturated = output != raw_output
        if not saturated or self.anti_windup == "disabled":
            self._integral = candidate_integral
        else:
            integral_term = self.ki * self._integral
        self._previous_error = error
        self._previous_derivative = derivative_state
        result = PidStep(output, error, proportional, integral_term, derivative_term, saturated)
        self._trace.append(result)
        self._trace = self._trace[-MAX_TRANSFORM_POINTS:]
        return result

    def reset(self, state: Mapping[str, Any] | None) -> "PidController":
        config = _options(state, "controller.reset")
        self._integral = _number(config.get("integral", 0.0), "controller.reset", "state.integral")
        previous = config.get("previousError")
        self._previous_error = None if previous is None else _number(previous, "controller.reset", "state.previousError")
        self._previous_derivative = _number(config.get("derivative", 0.0), "controller.reset", "state.derivative")
        self._trace.clear()
        return self

    def tune(self, method: str, data: Mapping[str, Any]) -> Mapping[str, float]:
        operation = "controller.tune"
        strategy = _text(method, operation, "method").lower()
        if not isinstance(data, Mapping):
            _fail("INVALID_TUNING_DATA", operation, "data must be a mapping")
        if strategy == "ziegler-nichols-pi":
            gain = _positive(data.get("ultimateGain"), operation, "data.ultimateGain")
            period = _positive(data.get("ultimatePeriod"), operation, "data.ultimatePeriod")
            self.kp = 0.45 * gain
            self.ki = self.kp / (period / 1.2)
            self.kd = 0.0
        elif strategy == "step-response":
            gain = _positive(data.get("processGain"), operation, "data.processGain")
            time_constant = _positive(data.get("timeConstant"), operation, "data.timeConstant")
            dead_time = _positive(data.get("deadTime"), operation, "data.deadTime")
            self.kp = 0.9 * time_constant / (gain * dead_time)
            self.ki = self.kp / (3.33 * dead_time)
            self.kd = 0.0
        else:
            _fail("UNSUPPORTED_METHOD", operation, "unsupported bounded tuning method")
        return _freeze_mapping({"kp": self.kp, "ki": self.ki, "kd": self.kd})

    def stabilityReport(self, model: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "controller.stabilityReport"
        if not isinstance(model, Mapping):
            _fail("INVALID_MODEL", operation, "model must be a first-order model mapping")
        gain = _positive(model.get("processGain"), operation, "model.processGain")
        time_constant = _positive(model.get("timeConstant"), operation, "model.timeConstant")
        loop_gain = self.kp * gain
        pole = -(1.0 + loop_gain) / time_constant
        return _freeze_mapping(
            {
                "assumption": "linear-first-order-no-delay",
                "closedLoopPole": pole,
                "stable": pole < 0.0 and self.ki >= 0.0,
                "integralAction": self.ki > 0.0,
                "saturationConfigured": math.isfinite(self.minimum) and math.isfinite(self.maximum),
            }
        )

    def trace(self) -> tuple[PidStep, ...]:
        return tuple(self._trace)


@dataclass(frozen=True)
class StateStep:
    state: tuple[float, ...]
    output: tuple[float, ...]


class StateSpace:
    def __init__(self, A: Any, B: Any, C: Any, D: Any, sample_time: float) -> None:
        operation = "StateSpace.define"
        self.A = _matrix(A, operation, "A")
        self.B = _matrix(B, operation, "B")
        self.C = _matrix(C, operation, "C")
        self.D = _matrix(D, operation, "D")
        self.sample_time = _number(sample_time, operation, "sampleTime")
        if self.sample_time < 0.0:
            _fail("OUT_OF_RANGE", operation, "sampleTime cannot be negative")
        state_count = len(self.A)
        input_count = len(self.B[0])
        output_count = len(self.C)
        if len(self.A[0]) != state_count or len(self.B) != state_count:
            _fail("DIMENSION_MISMATCH", operation, "A must be square and B must have matching rows")
        if len(self.C[0]) != state_count or len(self.D) != output_count or len(self.D[0]) != input_count:
            _fail("DIMENSION_MISMATCH", operation, "C and D dimensions must match state and input sizes")
        self.state_count = state_count
        self.input_count = input_count

    @classmethod
    def define(cls, A: Any, B: Any, C: Any, D: Any, sampleTime: float) -> "StateSpace":
        return cls(A, B, C, D, sampleTime)

    def step(self, state: Sequence[float], input: Sequence[float]) -> StateStep:
        operation = "model.step"
        if self.sample_time <= 0.0:
            _fail("CONTINUOUS_MODEL", operation, "discretize the model before stepping")
        state_vector = _vector(state, operation, "state", length=self.state_count)
        input_vector = _vector(input, operation, "input", length=self.input_count)
        next_state = tuple(_dot(row, state_vector) + _dot(control, input_vector) for row, control in zip(self.A, self.B))
        output = tuple(_dot(row, state_vector) + _dot(feedthrough, input_vector) for row, feedthrough in zip(self.C, self.D))
        return StateStep(next_state, output)

    def simulate(self, input: Sequence[Sequence[float]], initialState: Sequence[float]) -> tuple[StateStep, ...]:
        operation = "model.simulate"
        if isinstance(input, (str, bytes, bytearray)) or not isinstance(input, Sequence):
            _fail("INVALID_INPUT_SERIES", operation, "input must be a sequence")
        if len(input) > MAX_TRANSFORM_POINTS:
            _fail("LIMIT_EXCEEDED", operation, f"input exceeds {MAX_TRANSFORM_POINTS} steps")
        state = _vector(initialState, operation, "initialState", length=self.state_count)
        result: list[StateStep] = []
        for control in input:
            point = self.step(state, control)
            result.append(point)
            state = point.state
        return tuple(result)

    def controllable(self) -> bool:
        power = _identity(self.state_count)
        blocks: list[tuple[tuple[float, ...], ...]] = []
        for _ in range(self.state_count):
            blocks.append(_matmul(power, self.B))
            power = _matmul(power, self.A)
        matrix = tuple(tuple(value for block in blocks for value in block[row]) for row in range(self.state_count))
        return _rank(matrix) == self.state_count

    def observable(self) -> bool:
        power = _identity(self.state_count)
        rows: list[tuple[float, ...]] = []
        for _ in range(self.state_count):
            rows.extend(_matmul(self.C, power))
            power = _matmul(power, self.A)
        return _rank(rows) == self.state_count

    def discretize(self, period: float, method: str) -> "StateSpace":
        operation = "model.discretize"
        interval = _positive(period, operation, "period")
        strategy = _text(method, operation, "method").lower()
        if strategy not in {"forward-euler", "euler"}:
            _fail("UNSUPPORTED_METHOD", operation, "only explicit forward-euler is supported")
        if self.sample_time != 0.0:
            _fail("ALREADY_DISCRETE", operation, "model already has a sample time")
        discrete_a = tuple(
            tuple((1.0 if row == column else 0.0) + interval * self.A[row][column] for column in range(self.state_count))
            for row in range(self.state_count)
        )
        discrete_b = tuple(tuple(interval * value for value in row) for row in self.B)
        return StateSpace(discrete_a, discrete_b, self.C, self.D, interval)


class Identification:
    def __init__(self, coefficient: float, input_gain: float, residuals: Sequence[float], observations: Sequence[float]) -> None:
        self.coefficient = coefficient
        self.input_gain = input_gain
        self._residuals = tuple(residuals)
        self._observations = tuple(observations)

    def residualReport(self) -> Mapping[str, Any]:
        residuals = self._residuals
        mse = sum(value * value for value in residuals) / len(residuals)
        mean_observed = sum(self._observations) / len(self._observations)
        total = sum((value - mean_observed) ** 2 for value in self._observations)
        fit = 1.0 if total <= EPSILON else max(0.0, 1.0 - sum(value * value for value in residuals) / total)
        if len(residuals) > 1:
            mean_residual = sum(residuals) / len(residuals)
            denominator = sum((value - mean_residual) ** 2 for value in residuals)
            autocorrelation = 0.0 if denominator <= EPSILON else sum(
                (left - mean_residual) * (right - mean_residual) for left, right in zip(residuals, residuals[1:])
            ) / denominator
        else:
            autocorrelation = 0.0
        return _freeze_mapping({"mse": mse, "fit": fit, "lag1Autocorrelation": autocorrelation, "samples": len(residuals)})


class SystemIdentification:
    @staticmethod
    def fit(data: Mapping[str, Any], structure: str, options: Mapping[str, Any] | None) -> Identification:
        operation = "SystemIdentification.fit"
        if not isinstance(data, Mapping):
            _fail("INVALID_DATA", operation, "data must contain input and output sequences")
        if _text(structure, operation, "structure").lower() != "arx-1":
            _fail("UNSUPPORTED_STRUCTURE", operation, "only bounded scalar arx-1 is supported")
        _options(options, operation)
        inputs = _vector(data.get("input"), operation, "data.input", maximum=MAX_TRANSFORM_POINTS)
        outputs = _vector(data.get("output"), operation, "data.output", maximum=MAX_TRANSFORM_POINTS)
        if len(inputs) != len(outputs) or len(outputs) < 3:
            _fail("INSUFFICIENT_DATA", operation, "equal input/output sequences need at least three samples")
        if len(outputs) > MAX_TRANSFORM_POINTS:
            _fail("LIMIT_EXCEEDED", operation, f"identification is bounded to {MAX_TRANSFORM_POINTS} samples")
        x1 = outputs[:-1]
        x2 = inputs[:-1]
        y = outputs[1:]
        s11 = sum(value * value for value in x1)
        s22 = sum(value * value for value in x2)
        s12 = sum(left * right for left, right in zip(x1, x2))
        sy1 = sum(left * right for left, right in zip(x1, y))
        sy2 = sum(left * right for left, right in zip(x2, y))
        determinant = s11 * s22 - s12 * s12
        if abs(determinant) <= EPSILON:
            _fail("SINGULAR_DATA", operation, "input data does not identify both coefficients")
        coefficient = (sy1 * s22 - sy2 * s12) / determinant
        input_gain = (s11 * sy2 - s12 * sy1) / determinant
        residuals = tuple(observed - (coefficient * previous + input_gain * control) for previous, control, observed in zip(x1, x2, y))
        return Identification(coefficient, input_gain, residuals, y)


def _quaternion(value: Any, operation: str, name: str) -> tuple[float, float, float, float]:
    quaternion = _vector(value, operation, name, length=4)
    norm = math.sqrt(sum(component * component for component in quaternion))
    if norm <= EPSILON:
        _fail("INVALID_ORIENTATION", operation, f"{name} cannot be zero")
    return tuple(component / norm for component in quaternion)  # type: ignore[return-value]


def _quat_multiply(left: Sequence[float], right: Sequence[float]) -> tuple[float, float, float, float]:
    lw, lx, ly, lz = left
    rw, rx, ry, rz = right
    return (
        lw * rw - lx * rx - ly * ry - lz * rz,
        lw * rx + lx * rw + ly * rz - lz * ry,
        lw * ry - lx * rz + ly * rw + lz * rx,
        lw * rz + lx * ry - ly * rx + lz * rw,
    )


def _quat_conjugate(value: Sequence[float]) -> tuple[float, float, float, float]:
    return (value[0], -value[1], -value[2], -value[3])


def _quat_rotate(rotation: Sequence[float], vector: Sequence[float]) -> tuple[float, float, float]:
    rotated = _quat_multiply(_quat_multiply(rotation, (0.0, vector[0], vector[1], vector[2])), _quat_conjugate(rotation))
    return (rotated[1], rotated[2], rotated[3])


@dataclass(frozen=True)
class Pose:
    position: tuple[float, float, float]
    orientation: tuple[float, float, float, float]
    frame: str

    @classmethod
    def of(cls, position: Sequence[float], orientation: Sequence[float], frame: str) -> "Pose":
        operation = "Pose.of"
        return cls(
            _vector(position, operation, "position", length=3),  # type: ignore[arg-type]
            _quaternion(orientation, operation, "orientation"),
            _text(frame, operation, "frame"),
        )


@dataclass(frozen=True)
class Transform:
    translation: tuple[float, float, float]
    rotation: tuple[float, float, float, float]
    frame: str

    @classmethod
    def between(cls, from_: Pose, to: Pose) -> "Transform":
        operation = "Transform.between"
        if not isinstance(from_, Pose) or not isinstance(to, Pose):
            _fail("INVALID_POSE", operation, "from and to must be poses")
        if from_.frame != to.frame:
            _fail("FRAME_MISMATCH", operation, "poses must use the same explicit frame")
        rotation_from_source = _quat_conjugate(from_.orientation)
        translation = _quat_rotate(rotation_from_source, tuple(right - left for left, right in zip(from_.position, to.position)))
        rotation = _quat_multiply(rotation_from_source, to.orientation)
        return cls(translation, rotation, from_.frame)  # type: ignore[arg-type]


@dataclass(frozen=True)
class IkResult:
    joints: tuple[float, ...]
    converged: bool
    singular: bool
    iterations: int
    residual: float


class RobotModel:
    def __init__(self, description: Mapping[str, Any], capability: str) -> None:
        operation = "RobotModel.load"
        if not isinstance(description, Mapping):
            _fail("INVALID_DESCRIPTION", operation, "description must be a mapping")
        if _text(capability, operation, "capability") != "simulation":
            _fail("CAPABILITY_DENIED", operation, "only the simulation capability is available")
        if description.get("version") != 1:
            _fail("UNSUPPORTED_VERSION", operation, "description.version must be 1")
        self.link_lengths = _vector(description.get("linkLengths"), operation, "description.linkLengths")
        if len(self.link_lengths) != 2 or any(length <= 0.0 for length in self.link_lengths):
            _fail("UNSUPPORTED_MODEL", operation, "the bounded model requires two positive planar links")
        limits = description.get("jointLimits")
        if not isinstance(limits, Sequence) or len(limits) != 2:
            _fail("INVALID_LIMITS", operation, "two joint limit pairs are required")
        self.joint_limits = tuple(_vector(limit, operation, f"jointLimits[{index}]", length=2) for index, limit in enumerate(limits))
        if any(low >= high for low, high in self.joint_limits):
            _fail("INVALID_LIMITS", operation, "each lower joint limit must be below its upper limit")
        self.frame = _text(description.get("frame"), operation, "description.frame")
        self.capability = capability

    @classmethod
    def load(cls, description: Mapping[str, Any], capability: str) -> "RobotModel":
        return cls(description, capability)

    def forwardKinematics(self, joints: Sequence[float]) -> Pose:
        angles = _vector(joints, "robot.forwardKinematics", "joints", length=2)
        for index, (angle, limits) in enumerate(zip(angles, self.joint_limits)):
            if angle < limits[0] or angle > limits[1]:
                _fail("JOINT_LIMIT", "robot.forwardKinematics", f"joint {index} violates its limits")
        first, second = angles
        first_length, second_length = self.link_lengths
        x = first_length * math.cos(first) + second_length * math.cos(first + second)
        y = first_length * math.sin(first) + second_length * math.sin(first + second)
        half = (first + second) / 2.0
        return Pose.of((x, y, 0.0), (math.cos(half), 0.0, 0.0, math.sin(half)), self.frame)

    def inverseKinematics(self, target: Pose, seed: Sequence[float], options: Mapping[str, Any] | None) -> IkResult:
        operation = "robot.inverseKinematics"
        if not isinstance(target, Pose) or target.frame != self.frame:
            _fail("FRAME_MISMATCH", operation, "target must use the robot frame")
        seed_angles = _vector(seed, operation, "seed", length=2)
        config = _options(options, operation)
        elbow = str(config.get("elbow", "nearest")).lower()
        if elbow not in {"up", "down", "nearest"}:
            _fail("UNSUPPORTED_OPTION", operation, "elbow must be up, down, or nearest")
        x, y, _ = target.position
        first_length, second_length = self.link_lengths
        cosine_second = (x * x + y * y - first_length * first_length - second_length * second_length) / (2.0 * first_length * second_length)
        if cosine_second < -1.0 - EPSILON or cosine_second > 1.0 + EPSILON:
            _fail("UNREACHABLE_TARGET", operation, "target is outside the planar workspace")
        cosine_second = max(-1.0, min(1.0, cosine_second))
        base = math.acos(cosine_second)
        candidates = []
        for second in (base, -base):
            first = math.atan2(y, x) - math.atan2(second_length * math.sin(second), first_length + second_length * math.cos(second))
            candidates.append((first, second))
        if elbow == "up":
            joints = candidates[0]
        elif elbow == "down":
            joints = candidates[1]
        else:
            joints = min(candidates, key=lambda candidate: sum((angle - reference) ** 2 for angle, reference in zip(candidate, seed_angles)))
        if any(angle < limits[0] or angle > limits[1] for angle, limits in zip(joints, self.joint_limits)):
            _fail("JOINT_LIMIT", operation, "solution violates joint limits")
        actual = self.forwardKinematics(joints)
        residual = math.dist(actual.position, target.position)
        return IkResult(tuple(joints), residual <= 1.0e-8, abs(math.sin(joints[1])) <= 1.0e-8, 1, residual)


@dataclass(frozen=True)
class TrajectorySample:
    position: tuple[float, ...]
    velocity: tuple[float, ...]
    acceleration: tuple[float, ...]


class Trajectory:
    def __init__(self, start: tuple[float, ...], goal: tuple[float, ...], duration: float, limits: Mapping[str, Any]) -> None:
        self.start = start
        self.goal = goal
        self.duration = duration
        self.limits = MappingProxyType(dict(limits))

    @classmethod
    def plan(
        cls,
        start: Sequence[float],
        goal: Sequence[float],
        limits: Mapping[str, Any],
        obstacles: Sequence[Mapping[str, Any]],
    ) -> "Trajectory":
        operation = "Trajectory.plan"
        start_point = _vector(start, operation, "start")
        goal_point = _vector(goal, operation, "goal", length=len(start_point))
        if not isinstance(limits, Mapping):
            _fail("INVALID_LIMITS", operation, "limits must be a mapping")
        maximum_velocity = _positive(limits.get("maximumVelocity"), operation, "limits.maximumVelocity")
        maximum_acceleration = _positive(limits.get("maximumAcceleration"), operation, "limits.maximumAcceleration")
        distance = max(abs(right - left) for left, right in zip(start_point, goal_point))
        minimum_duration = max(1.5 * distance / maximum_velocity, math.sqrt(6.0 * distance / maximum_acceleration)) if distance > 0.0 else 1.0e-6
        duration = _positive(limits.get("duration", minimum_duration), operation, "limits.duration")
        if duration + EPSILON < minimum_duration:
            _fail("INFEASIBLE_LIMITS", operation, "duration violates velocity or acceleration limits")
        if isinstance(obstacles, (str, bytes, bytearray)) or not isinstance(obstacles, Sequence):
            _fail("INVALID_OBSTACLES", operation, "obstacles must be a bounded sequence")
        if len(obstacles) > 64:
            _fail("LIMIT_EXCEEDED", operation, "at most 64 obstacles are supported")
        for obstacle_index, obstacle in enumerate(obstacles):
            if not isinstance(obstacle, Mapping):
                _fail("INVALID_OBSTACLE", operation, f"obstacle {obstacle_index} must be a mapping")
            center = _vector(obstacle.get("center"), operation, f"obstacles[{obstacle_index}].center", length=len(start_point))
            radius = _positive(obstacle.get("radius"), operation, f"obstacles[{obstacle_index}].radius")
            delta = tuple(right - left for left, right in zip(start_point, goal_point))
            squared_length = sum(component * component for component in delta)
            if squared_length <= EPSILON:
                nearest = start_point
            else:
                projection = sum((axis - left) * change for axis, left, change in zip(center, start_point, delta)) / squared_length
                ratio = max(0.0, min(1.0, projection))
                nearest = tuple(left + ratio * change for left, change in zip(start_point, delta))
            if math.dist(nearest, center) <= radius:
                _fail("PATH_COLLISION", operation, f"straight-line path intersects obstacle {obstacle_index}")
        return cls(start_point, goal_point, duration, limits)

    def sample(self, time: float) -> TrajectorySample:
        operation = "trajectory.sample"
        instant = _number(time, operation, "time")
        if instant < 0.0 or instant > self.duration:
            _fail("TIME_OUTSIDE_TRAJECTORY", operation, "time must be within the planned duration")
        ratio = instant / self.duration
        blend = 3.0 * ratio * ratio - 2.0 * ratio * ratio * ratio
        first_derivative = (6.0 * ratio - 6.0 * ratio * ratio) / self.duration
        second_derivative = (6.0 - 12.0 * ratio) / (self.duration * self.duration)
        delta = tuple(right - left for left, right in zip(self.start, self.goal))
        return TrajectorySample(
            tuple(left + blend * change for left, change in zip(self.start, delta)),
            tuple(first_derivative * change for change in delta),
            tuple(second_derivative * change for change in delta),
        )

    def validate(self, limits: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "trajectory.validate"
        if not isinstance(limits, Mapping):
            _fail("INVALID_LIMITS", operation, "limits must be a mapping")
        maximum_velocity = _positive(limits.get("maximumVelocity"), operation, "limits.maximumVelocity")
        maximum_acceleration = _positive(limits.get("maximumAcceleration"), operation, "limits.maximumAcceleration")
        samples = tuple(self.sample(self.duration * index / 64.0) for index in range(65))
        peak_velocity = max(abs(value) for point in samples for value in point.velocity)
        peak_acceleration = max(abs(value) for point in samples for value in point.acceleration)
        return _freeze_mapping(
            {
                "valid": peak_velocity <= maximum_velocity + EPSILON and peak_acceleration <= maximum_acceleration + EPSILON,
                "peakVelocity": peak_velocity,
                "peakAcceleration": peak_acceleration,
                "duration": self.duration,
            }
        )


@dataclass(frozen=True)
class FusionUpdate:
    accepted: bool
    innovation: float
    normalizedInnovation: float
    sensor: str
    timestamp: float


class SensorFusion:
    def __init__(self, state_model: Mapping[str, Any], options: Mapping[str, Any] | None) -> None:
        operation = "SensorFusion.new"
        if not isinstance(state_model, Mapping):
            _fail("INVALID_MODEL", operation, "stateModel must be a mapping")
        config = _options(options, operation)
        self.frame = _text(state_model.get("frame"), operation, "stateModel.frame")
        self._state = list(_vector(config.get("initialState", (0.0, 0.0)), operation, "options.initialState", length=2))
        initial_covariance = _positive(config.get("initialCovariance", 1.0), operation, "options.initialCovariance")
        self._covariance = [[initial_covariance, 0.0], [0.0, initial_covariance]]
        self.process_noise = _positive(state_model.get("processNoise", 0.01), operation, "stateModel.processNoise")
        self._sensors: dict[str, dict[str, Any]] = {}
        self._policy = {"threshold": math.inf}
        self._last_timestamp: float | None = None
        self._innovations: list[FusionUpdate] = []

    @classmethod
    def new(cls, stateModel: Mapping[str, Any], options: Mapping[str, Any] | None) -> "SensorFusion":
        return cls(stateModel, options)

    def addSensor(self, name: str, model: Mapping[str, Any], frame: str) -> "SensorFusion":
        operation = "fusion.addSensor"
        sensor_name = _text(name, operation, "name")
        if sensor_name in self._sensors:
            _fail("DUPLICATE_SENSOR", operation, f"sensor {sensor_name} already exists")
        if _text(frame, operation, "frame") != self.frame:
            _fail("FRAME_MISMATCH", operation, "sensor frame must match the state frame")
        if not isinstance(model, Mapping):
            _fail("INVALID_MODEL", operation, "model must be a mapping")
        index = _integer(model.get("stateIndex"), operation, "model.stateIndex", 0, 1)
        measurement_noise = _positive(model.get("measurementNoise"), operation, "model.measurementNoise")
        self._sensors[sensor_name] = {"stateIndex": index, "measurementNoise": measurement_noise, "frame": frame}
        return self

    def predict(self, control: float, dt: float) -> tuple[float, float]:
        operation = "fusion.predict"
        acceleration = _number(control, operation, "control")
        interval = _positive(dt, operation, "dt")
        position, velocity = self._state
        self._state = [position + velocity * interval + 0.5 * acceleration * interval * interval, velocity + acceleration * interval]
        p00, p01 = self._covariance[0]
        p10, p11 = self._covariance[1]
        q = self.process_noise
        self._covariance = [
            [p00 + interval * (p01 + p10) + interval * interval * p11 + q * interval ** 4 / 4.0, p01 + interval * p11 + q * interval ** 3 / 2.0],
            [p10 + interval * p11 + q * interval ** 3 / 2.0, p11 + q * interval * interval],
        ]
        return tuple(self._state)  # type: ignore[return-value]

    def update(self, sensor: str, measurement: Any, timestamp: float) -> FusionUpdate:
        operation = "fusion.update"
        sensor_name = _text(sensor, operation, "sensor")
        if sensor_name not in self._sensors:
            _fail("UNKNOWN_SENSOR", operation, f"sensor {sensor_name} is not registered")
        stamp = _number(timestamp, operation, "timestamp")
        if self._last_timestamp is not None and stamp <= self._last_timestamp:
            _fail("NON_MONOTONIC_TIMESTAMP", operation, "timestamp must increase strictly")
        if isinstance(measurement, Mapping):
            if measurement.get("frame") != self.frame:
                _fail("FRAME_MISMATCH", operation, "measurement frame must match the state frame")
            value = _number(measurement.get("value"), operation, "measurement.value")
        else:
            value = _number(measurement, operation, "measurement")
        model = self._sensors[sensor_name]
        index = int(model["stateIndex"])
        variance = self._covariance[index][index] + float(model["measurementNoise"])
        innovation = value - self._state[index]
        normalized = abs(innovation) / math.sqrt(variance)
        accepted = normalized <= float(self._policy["threshold"])
        result = FusionUpdate(accepted, innovation, normalized, sensor_name, stamp)
        self._innovations.append(result)
        self._innovations = self._innovations[-MAX_TRANSFORM_POINTS:]
        self._last_timestamp = stamp
        if not accepted:
            return result
        gains = [self._covariance[row][index] / variance for row in range(2)]
        self._state = [value_at_index + gain * innovation for value_at_index, gain in zip(self._state, gains)]
        source_row = tuple(self._covariance[index])
        self._covariance = [
            [self._covariance[row][column] - gains[row] * source_row[column] for column in range(2)]
            for row in range(2)
        ]
        return result

    def state(self) -> tuple[float, float]:
        return tuple(self._state)  # type: ignore[return-value]

    def covariance(self) -> tuple[tuple[float, float], tuple[float, float]]:
        return tuple(tuple(row) for row in self._covariance)  # type: ignore[return-value]

    def rejectOutliers(self, policy: Mapping[str, Any]) -> "SensorFusion":
        operation = "fusion.rejectOutliers"
        if not isinstance(policy, Mapping) or policy.get("method") != "normalized-innovation":
            _fail("UNSUPPORTED_POLICY", operation, "method must be normalized-innovation")
        threshold = _positive(policy.get("threshold"), operation, "policy.threshold")
        self._policy = {"threshold": threshold}
        return self

    def innovationReport(self) -> tuple[FusionUpdate, ...]:
        return tuple(self._innovations)


@dataclass(frozen=True)
class LoopRunResult:
    status: str
    ticks: int
    safeStateCalls: int
    fault: str | None


@dataclass(frozen=True)
class ReplayReport:
    deterministic: bool
    events: int
    digest: str
    hardware: bool


class RobotLoop:
    """Deterministic simulated control loop with explicit fail-safe behaviour."""

    def __init__(self, period: float, deadline: float, controller: Any) -> None:
        operation = "RobotLoop.new"
        self.period = _positive(period, operation, "period")
        self.deadline = _positive(deadline, operation, "deadline")
        if self.deadline > self.period:
            _fail("INVALID_DEADLINE", operation, "deadline cannot exceed period")
        if controller is None:
            _fail("INVALID_CONTROLLER", operation, "controller is required")
        self.controller = controller
        self._read: Callable[..., Any] | None = None
        self._compute: Callable[..., Any] | None = None
        self._write: Callable[..., Any] | None = None
        self._safe: Callable[..., Any] | None = None
        self._watchdog = self.period
        self._safe_calls = 0
        self._durations: list[float] = []
        self._log: list[Mapping[str, Any]] = []

    @classmethod
    def new(cls, period: float, deadline: float, controller: Any) -> "RobotLoop":
        return cls(period, deadline, controller)

    def readSensors(self, function: Callable[..., Any]) -> "RobotLoop":
        if not callable(function):
            _fail("INVALID_CALLBACK", "loop.readSensors", "function must be callable")
        self._read = function
        return self

    def compute(self, function: Callable[..., Any]) -> "RobotLoop":
        if not callable(function):
            _fail("INVALID_CALLBACK", "loop.compute", "function must be callable")
        self._compute = function
        return self

    def writeActuators(self, function: Callable[..., Any]) -> "RobotLoop":
        if not callable(function):
            _fail("INVALID_CALLBACK", "loop.writeActuators", "function must be callable")
        self._write = function
        return self

    def safeState(self, function: Callable[..., Any]) -> "RobotLoop":
        if not callable(function):
            _fail("INVALID_CALLBACK", "loop.safeState", "function must be callable")
        self._safe = function
        return self

    def watchdog(self, timeout: float) -> "RobotLoop":
        interval = _positive(timeout, "loop.watchdog", "timeout")
        if interval > self.period:
            _fail("INVALID_WATCHDOG", "loop.watchdog", "watchdog timeout cannot exceed period")
        self._watchdog = interval
        return self

    def _enter_safe_state(self, reason: str) -> None:
        if self._safe_calls == 0 and self._safe is not None:
            self._safe(reason)
            self._safe_calls = 1

    def run(self, cancellation: Mapping[str, Any]) -> LoopRunResult:
        operation = "loop.run"
        if not isinstance(cancellation, Mapping):
            _fail("INVALID_CANCELLATION", operation, "cancellation must be a mapping")
        if any(callback is None for callback in (self._read, self._compute, self._write, self._safe)):
            _fail("INCOMPLETE_LOOP", operation, "read, compute, write, and safe callbacks are required")
        ticks = _integer(cancellation.get("maxTicks", 1), operation, "cancellation.maxTicks", 1, MAX_LOOP_TICKS)
        phase_durations = cancellation.get("phaseDurations", ())
        if not isinstance(phase_durations, Sequence):
            _fail("INVALID_TIMING", operation, "phaseDurations must be a sequence")
        self._safe_calls = 0
        self._durations.clear()
        self._log.clear()
        for tick in range(ticks):
            if bool(cancellation.get("cancelled", False)):
                self._enter_safe_state("CANCELLED")
                return LoopRunResult("SAFE", tick, self._safe_calls, "CANCELLED")
            duration = self.period * 0.5
            if tick < len(phase_durations):
                duration = _number(phase_durations[tick], operation, f"phaseDurations[{tick}]")
                if duration < 0.0:
                    _fail("INVALID_TIMING", operation, "phase duration cannot be negative")
            try:
                assert self._read is not None and self._compute is not None and self._write is not None
                sensed = self._read(tick)
                command = self._compute(sensed, self.controller, self.period)
            except Exception:
                self._enter_safe_state("DEVICE_OR_CALLBACK_FAILURE")
                self._log.append(_freeze_mapping({"tick": tick, "event": "SAFE", "reason": "DEVICE_OR_CALLBACK_FAILURE"}))
                return LoopRunResult("SAFE", tick, self._safe_calls, "DEVICE_OR_CALLBACK_FAILURE")
            self._durations.append(duration)
            if duration > self.deadline:
                self._enter_safe_state("DEADLINE_MISS")
                self._log.append(_freeze_mapping({"tick": tick, "event": "SAFE", "reason": "DEADLINE_MISS"}))
                return LoopRunResult("SAFE", tick + 1, self._safe_calls, "DEADLINE_MISS")
            if duration > self._watchdog:
                self._enter_safe_state("WATCHDOG")
                self._log.append(_freeze_mapping({"tick": tick, "event": "SAFE", "reason": "WATCHDOG"}))
                return LoopRunResult("SAFE", tick + 1, self._safe_calls, "WATCHDOG")
            try:
                self._write(command)
            except Exception:
                self._enter_safe_state("DEVICE_OR_CALLBACK_FAILURE")
                self._log.append(_freeze_mapping({"tick": tick, "event": "SAFE", "reason": "DEVICE_OR_CALLBACK_FAILURE"}))
                return LoopRunResult("SAFE", tick, self._safe_calls, "DEVICE_OR_CALLBACK_FAILURE")
            self._log.append(_freeze_mapping({"tick": tick, "event": "WRITE", "duration": duration, "simulated": True}))
        return LoopRunResult("COMPLETED", ticks, self._safe_calls, None)

    def timingReport(self) -> Mapping[str, Any]:
        if not self._durations:
            return _freeze_mapping({"ticks": 0, "maximum": 0.0, "mean": 0.0, "deadline": self.deadline, "misses": 0})
        return _freeze_mapping(
            {
                "ticks": len(self._durations),
                "maximum": max(self._durations),
                "mean": sum(self._durations) / len(self._durations),
                "deadline": self.deadline,
                "misses": sum(duration > self.deadline for duration in self._durations),
            }
        )

    def replay(self, log: Sequence[Mapping[str, Any]]) -> ReplayReport:
        operation = "loop.replay"
        if isinstance(log, (str, bytes, bytearray)) or not isinstance(log, Sequence):
            _fail("INVALID_LOG", operation, "log must be a sequence")
        if len(log) > MAX_LOOP_TICKS * 2:
            _fail("LIMIT_EXCEEDED", operation, "replay log exceeds the bounded event count")
        normalized: list[dict[str, Any]] = []
        for index, event in enumerate(log):
            if not isinstance(event, Mapping):
                _fail("INVALID_LOG", operation, f"event {index} must be a mapping")
            if event.get("hardware") is True:
                _fail("HARDWARE_REPLAY_FORBIDDEN", operation, "replay is simulation-only")
            normalized.append({str(key): event[key] for key in sorted(event)})
        try:
            encoded = json.dumps(normalized, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")
        except (TypeError, ValueError):
            _fail("INVALID_LOG", operation, "log values must have a canonical JSON representation")
        digest = hashlib.sha256(encoded).hexdigest()
        second_digest = hashlib.sha256(encoded).hexdigest()
        return ReplayReport(digest == second_digest, len(normalized), digest, False)

    @property
    def log(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(self._log)


__all__ = [
    "Filter",
    "FrequencyResponsePoint",
    "FusionUpdate",
    "Identification",
    "IkResult",
    "LoopRunResult",
    "PidController",
    "PidStep",
    "Pose",
    "ReplayReport",
    "RobotLoop",
    "RobotModel",
    "RoboticsError",
    "SensorFusion",
    "SignalBuffer",
    "SignalSample",
    "SpectrumBin",
    "StateSpace",
    "StateStep",
    "SystemIdentification",
    "Trajectory",
    "TrajectorySample",
    "Transform",
]
