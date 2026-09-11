"""Bounded deterministic scientific-computing profile for Nebo G036.

The production x86-64 runtime remains the native scalar owner.  This module
materializes the current catalogue vocabulary as a dependency-free reference
SDK: binary64 values, one deterministic thread, explicit budgets, immutable
result evidence, and stable fail-closed diagnostics.
"""
from __future__ import annotations

from dataclasses import dataclass
import cmath
import hashlib
import itertools
import json
import math
from types import MappingProxyType
from typing import Any, Callable, Mapping, Sequence


MAX_DIMENSION = 4096
MAX_NONZERO = 65536
MAX_DENSE_CELLS = 65536
MAX_FFT_LENGTH = 64
MAX_ITERATIONS = 100000
MAX_GRID_CELLS = 65536
MAX_TRACE = 4096


class ScientificError(RuntimeError):
    """Stable public error carrying a diagnostic code and operation."""

    def __init__(self, code: str, operation: str) -> None:
        super().__init__(f"{code}:{operation}")
        self._code = code
        self._operation = operation

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _require(condition: bool, code: str, operation: str) -> None:
    if not condition:
        raise ScientificError(code, operation)


def _finite(value: Any, operation: str) -> float:
    _require(isinstance(value, (int, float)) and not isinstance(value, bool),
             "NEBO-G036-NUMERIC", operation)
    result = float(value)
    _require(math.isfinite(result), "NEBO-G036-NONFINITE", operation)
    return result


def _positive(value: Any, maximum: int, operation: str) -> int:
    _require(isinstance(value, int) and not isinstance(value, bool) and
             0 < value <= maximum, "NEBO-G036-BUDGET", operation)
    return value


def _jsonable(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _jsonable(item) for key, item in value.items()}
    if isinstance(value, complex):
        return {"real": value.real, "imaginary": value.imag}
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        return [_jsonable(item) for item in value]
    return value


def _canonical(value: Any) -> bytes:
    try:
        return json.dumps(_jsonable(value), sort_keys=True, separators=(",", ":"),
                          allow_nan=False).encode("ascii")
    except (TypeError, ValueError, OverflowError) as error:
        raise ScientificError("NEBO-G036-SERIALIZATION", "canonicalize") from error


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


class _EvidenceResult:
    _algorithm: str
    _trace: tuple[Mapping[str, Any], ...]

    def _payload(self) -> Any:
        raise NotImplementedError

    def reproducibilityManifest(self) -> Mapping[str, Any]:
        payload = self._payload()
        return MappingProxyType({
            "algorithm": self._algorithm,
            "deterministic": True,
            "dtype": "binary64",
            "payloadSha256": _digest(payload),
            "rounding": "nearest-even",
            "schema": "nebo-scientific-result-v1",
            "target": "cpu-reference",
            "threads": 1,
            "traceRecords": len(self._trace),
        })

    def compare(self, reference: Any,
                tolerances: Mapping[str, Any] | None = None) -> Mapping[str, Any]:
        options = {} if tolerances is None else tolerances
        _require(isinstance(options, Mapping), "NEBO-G036-TOLERANCE", "result.compare")
        absolute = _finite(options.get("absolute", 1e-9), "result.compare")
        relative = _finite(options.get("relative", 1e-9), "result.compare")
        _require(absolute >= 0.0 and relative >= 0.0,
                 "NEBO-G036-TOLERANCE", "result.compare")
        left = _flatten_numeric(self._payload())
        right = _flatten_numeric(reference._payload() if isinstance(reference, _EvidenceResult)
                                 else reference)
        _require(len(left) == len(right), "NEBO-G036-SHAPE", "result.compare")
        errors = [abs(a - b) for a, b in zip(left, right)]
        passed = all(error <= absolute + relative * abs(expected)
                     for error, expected in zip(errors, right))
        return MappingProxyType({"passed": passed, "elements": len(left),
                                 "maximumError": max(errors, default=0.0),
                                 "absolute": absolute, "relative": relative})

    def convergenceTrace(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(MappingProxyType(dict(record)) for record in self._trace)

    def checkpoint(self) -> bytes:
        return _canonical({"schema": "nebo-scientific-checkpoint-v1",
                           "algorithm": self._algorithm,
                           "payload": self._payload(),
                           "trace": [dict(record) for record in self._trace]})


def _flatten_numeric(value: Any) -> list[float]:
    if isinstance(value, complex):
        return [float(value.real), float(value.imag)]
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return [float(value)]
    if isinstance(value, Mapping):
        output: list[float] = []
        for key in sorted(value):
            output.extend(_flatten_numeric(value[key]))
        return output
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        output = []
        for item in value:
            output.extend(_flatten_numeric(item))
        return output
    if isinstance(value, (str, bool)) or value is None:
        return []
    raise ScientificError("NEBO-G036-NUMERIC-PAYLOAD", "result.compare")


@dataclass(frozen=True)
class SparseVector:
    length: int
    indices: tuple[int, ...]
    values: tuple[float, ...]

    @staticmethod
    def fromIndices(length: int, indices: Sequence[int],
                    values: Sequence[Any]) -> "SparseVector":
        operation = "SparseVector.fromIndices"
        length = _positive(length, MAX_DIMENSION, operation)
        indices = tuple(indices)
        values = tuple(_finite(value, operation) for value in values)
        _require(len(indices) == len(values) <= MAX_NONZERO,
                 "NEBO-G036-SPARSE-SHAPE", operation)
        previous = -1
        for index in indices:
            _require(isinstance(index, int) and not isinstance(index, bool) and
                     previous < index < length, "NEBO-G036-SPARSE-INDEX", operation)
            previous = index
        return SparseVector(length, indices, values)

    def dense(self) -> tuple[float, ...]:
        result = [0.0] * self.length
        for index, value in zip(self.indices, self.values):
            result[index] = value
        return tuple(result)


class SparseMatrix:
    def __init__(self, rows: int, columns: int, row_offsets: Sequence[int],
                 column_indices: Sequence[int], values: Sequence[Any], storage: str) -> None:
        self.rows = rows
        self.columns = columns
        self.row_offsets = tuple(row_offsets)
        self.column_indices = tuple(column_indices)
        self.values = tuple(float(value) for value in values)
        self.storage = storage

    @staticmethod
    def csr(rows: int, columns: int, rowOffsets: Sequence[int],
            columnIndices: Sequence[int], values: Sequence[Any]) -> "SparseMatrix":
        return SparseMatrix._from_compressed(rows, columns, rowOffsets,
                                             columnIndices, values, "csr")

    @staticmethod
    def csc(rows: int, columns: int, columnOffsets: Sequence[int],
            rowIndices: Sequence[int], values: Sequence[Any]) -> "SparseMatrix":
        csc = SparseMatrix._from_compressed(columns, rows, columnOffsets,
                                            rowIndices, values, "csc-raw")
        entries = [(row, column, value)
                   for column in range(columns)
                   for row, value in zip(csc.column_indices[csc.row_offsets[column]:csc.row_offsets[column + 1]],
                                         csc.values[csc.row_offsets[column]:csc.row_offsets[column + 1]])]
        return SparseMatrix._from_entries(rows, columns, entries, "csc")

    @staticmethod
    def _from_compressed(rows: int, columns: int, offsets: Sequence[int],
                         indices: Sequence[int], values: Sequence[Any], storage: str) -> "SparseMatrix":
        operation = "SparseMatrix.csr" if storage == "csr" else "SparseMatrix.csc"
        rows = _positive(rows, MAX_DIMENSION, operation)
        columns = _positive(columns, MAX_DIMENSION, operation)
        offsets = tuple(offsets)
        indices = tuple(indices)
        numeric = tuple(_finite(value, operation) for value in values)
        _require(len(offsets) == rows + 1 and offsets[0] == 0 and
                 offsets[-1] == len(indices) == len(numeric) <= MAX_NONZERO,
                 "NEBO-G036-SPARSE-OFFSETS", operation)
        for outer in range(rows):
            _require(isinstance(offsets[outer], int) and offsets[outer] <= offsets[outer + 1],
                     "NEBO-G036-SPARSE-OFFSETS", operation)
            prior = -1
            for index in indices[offsets[outer]:offsets[outer + 1]]:
                _require(isinstance(index, int) and not isinstance(index, bool) and
                         prior < index < columns, "NEBO-G036-SPARSE-INDEX", operation)
                prior = index
        return SparseMatrix(rows, columns, offsets, indices, numeric, storage)

    @staticmethod
    def _from_entries(rows: int, columns: int,
                      entries: Sequence[tuple[int, int, float]], storage: str = "csr") -> "SparseMatrix":
        grouped: list[list[tuple[int, float]]] = [[] for _ in range(rows)]
        for row, column, value in sorted(entries):
            if value != 0.0:
                grouped[row].append((column, value))
        offsets = [0]
        indices: list[int] = []
        values: list[float] = []
        for row in grouped:
            indices.extend(column for column, _ in row)
            values.extend(value for _, value in row)
            offsets.append(len(indices))
        result = SparseMatrix._from_compressed(rows, columns, offsets, indices, values, "csr")
        result.storage = storage
        return result

    def nonZeroCount(self) -> int:
        return len(self.values)

    def density(self) -> float:
        return len(self.values) / (self.rows * self.columns)

    def transpose(self) -> "SparseMatrix":
        entries = [(column, row, value) for row in range(self.rows)
                   for column, value in zip(self.column_indices[self.row_offsets[row]:self.row_offsets[row + 1]],
                                            self.values[self.row_offsets[row]:self.row_offsets[row + 1]])]
        return SparseMatrix._from_entries(self.columns, self.rows, entries,
                                          "csc" if self.storage == "csr" else "csr")

    def matmul(self, other: Any) -> Any:
        operation = "sparse.matmul"
        if isinstance(other, SparseVector):
            _require(self.columns == other.length, "NEBO-G036-SHAPE", operation)
            return self.matmul(other.dense())
        if isinstance(other, SparseMatrix):
            _require(self.columns == other.rows, "NEBO-G036-SHAPE", operation)
            right_rows = [{column: value for column, value in
                           zip(other.column_indices[other.row_offsets[row]:other.row_offsets[row + 1]],
                               other.values[other.row_offsets[row]:other.row_offsets[row + 1]])}
                          for row in range(other.rows)]
            entries: list[tuple[int, int, float]] = []
            for row in range(self.rows):
                accumulator: dict[int, float] = {}
                for inner, left in zip(self.column_indices[self.row_offsets[row]:self.row_offsets[row + 1]],
                                       self.values[self.row_offsets[row]:self.row_offsets[row + 1]]):
                    for column, right in right_rows[inner].items():
                        accumulator[column] = accumulator.get(column, 0.0) + left * right
                entries.extend((row, column, value) for column, value in accumulator.items()
                               if value != 0.0)
                _require(len(entries) <= MAX_NONZERO, "NEBO-G036-SPARSE-BUDGET", operation)
            return SparseMatrix._from_entries(self.rows, other.columns, entries)
        try:
            vector = tuple(_finite(value, operation) for value in other)
        except TypeError as error:
            raise ScientificError("NEBO-G036-SPARSE-OPERAND", operation) from error
        _require(len(vector) == self.columns, "NEBO-G036-SHAPE", operation)
        return tuple(sum(value * vector[column] for column, value in
                         zip(self.column_indices[self.row_offsets[row]:self.row_offsets[row + 1]],
                             self.values[self.row_offsets[row]:self.row_offsets[row + 1]]))
                     for row in range(self.rows))

    def toDense(self, limit: int) -> tuple[tuple[float, ...], ...]:
        limit = _positive(limit, MAX_DENSE_CELLS, "sparse.toDense")
        _require(self.rows * self.columns <= limit, "NEBO-G036-DENSIFY-LIMIT", "sparse.toDense")
        dense = [[0.0] * self.columns for _ in range(self.rows)]
        for row in range(self.rows):
            for column, value in zip(self.column_indices[self.row_offsets[row]:self.row_offsets[row + 1]],
                                     self.values[self.row_offsets[row]:self.row_offsets[row + 1]]):
                dense[row][column] = value
        return tuple(tuple(row) for row in dense)

    def validateInvariants(self) -> Mapping[str, Any]:
        SparseMatrix._from_compressed(self.rows, self.columns, self.row_offsets,
                                      self.column_indices, self.values, "csr")
        return MappingProxyType({"valid": True, "storage": self.storage,
                                 "rows": self.rows, "columns": self.columns,
                                 "nonZeroCount": len(self.values)})


def _complex_sequence(values: Sequence[Any], length: int, operation: str) -> tuple[complex, ...]:
    _require(len(values) == length, "NEBO-G036-FFT-LENGTH", operation)
    output = tuple(complex(value) for value in values)
    _require(all(math.isfinite(value.real) and math.isfinite(value.imag) for value in output),
             "NEBO-G036-NONFINITE", operation)
    return output


class Spectrum(tuple):
    def magnitude(self) -> tuple[float, ...]:
        return tuple(abs(value) for value in self)

    def power(self) -> tuple[float, ...]:
        return tuple(value.real * value.real + value.imag * value.imag for value in self)


@dataclass(frozen=True)
class FftPlan:
    length: int
    direction: str
    normalization: str

    def _transform(self, signal: Sequence[Any], inverse: bool) -> Spectrum:
        values = _complex_sequence(signal, self.length,
                                   "fft.inverse" if inverse else "fft.forward")
        sign = 1.0 if inverse else -1.0
        result = []
        for frequency in range(self.length):
            total = 0j
            for sample, value in enumerate(values):
                total += value * cmath.exp(sign * 2j * math.pi * frequency * sample / self.length)
            if inverse:
                total /= self.length
            result.append(total)
        return Spectrum(result)

    def forward(self, signal: Sequence[Any]) -> Spectrum:
        return self._transform(signal, False)

    def inverse(self, spectrum: Sequence[Any]) -> Spectrum:
        return self._transform(spectrum, True)


class Fft:
    @staticmethod
    def plan(length: int, direction: str = "both",
             options: Mapping[str, Any] | None = None) -> FftPlan:
        operation = "Fft.plan"
        length = _positive(length, MAX_FFT_LENGTH, operation)
        _require(direction in {"forward", "inverse", "both"},
                 "NEBO-G036-FFT-DIRECTION", operation)
        options = {} if options is None else options
        _require(isinstance(options, Mapping) and set(options) <= {"normalization"},
                 "NEBO-G036-FFT-OPTIONS", operation)
        normalization = options.get("normalization", "inverse")
        _require(normalization == "inverse", "NEBO-G036-FFT-NORMALIZATION", operation)
        return FftPlan(length, direction, normalization)


class Signal(tuple):
    def __new__(cls, values: Sequence[Any]):
        return tuple.__new__(cls, tuple(_finite(value, "Signal") for value in values))

    @staticmethod
    def _mode(values: list[float], left: int, right: int, mode: str) -> tuple[float, ...]:
        _require(mode in {"full", "same", "valid"}, "NEBO-G036-SIGNAL-MODE", "signal")
        if mode == "full":
            return tuple(values)
        if mode == "same":
            start = (right - 1) // 2
            return tuple(values[start:start + left])
        size = max(left, right) - min(left, right) + 1
        start = min(left, right) - 1
        return tuple(values[start:start + size])

    def convolve(self, kernel: Sequence[Any], mode: str = "full") -> tuple[float, ...]:
        kernel = tuple(_finite(value, "signal.convolve") for value in kernel)
        _require(self and kernel, "NEBO-G036-SIGNAL-EMPTY", "signal.convolve")
        _require(len(self) * len(kernel) <= MAX_DENSE_CELLS,
                 "NEBO-G036-SIGNAL-BUDGET", "signal.convolve")
        full = [0.0] * (len(self) + len(kernel) - 1)
        for i, left in enumerate(self):
            for j, right in enumerate(kernel):
                full[i + j] += left * right
        return self._mode(full, len(self), len(kernel), mode)

    def correlate(self, other: Sequence[Any], mode: str = "full") -> tuple[float, ...]:
        other = tuple(_finite(value, "signal.correlate") for value in other)
        return self.convolve(tuple(reversed(other)), mode)

    def autocorrelation(self) -> tuple[float, ...]:
        return self.correlate(self, "full")


class WindowFunction:
    @staticmethod
    def hann(length: int) -> tuple[float, ...]:
        length = _positive(length, MAX_FFT_LENGTH, "WindowFunction.hann")
        if length == 1:
            return (1.0,)
        return tuple(0.5 - 0.5 * math.cos(2.0 * math.pi * index / (length - 1))
                     for index in range(length))


@dataclass(frozen=True)
class NumericResult(_EvidenceResult):
    value: float
    error: float
    iterations: int
    status: str
    _algorithm: str
    _trace: tuple[Mapping[str, Any], ...]

    def errorEstimate(self) -> float:
        return self.error

    def _payload(self) -> Any:
        return {"value": self.value, "error": self.error,
                "iterations": self.iterations, "status": self.status}


def _solver_inputs(function: Callable[[float], Any], bracket: Sequence[Any],
                   tolerance: Any, operation: str) -> tuple[float, float, float, float, float]:
    _require(callable(function) and len(bracket) == 2, "NEBO-G036-SOLVER-INPUT", operation)
    low, high = (_finite(value, operation) for value in bracket)
    tolerance = _finite(tolerance, operation)
    _require(low < high and tolerance > 0.0, "NEBO-G036-SOLVER-INPUT", operation)
    f_low, f_high = _finite(function(low), operation), _finite(function(high), operation)
    _require(f_low == 0.0 or f_high == 0.0 or f_low * f_high < 0.0,
             "NEBO-G036-ROOT-BRACKET", operation)
    return low, high, tolerance, f_low, f_high


class Root:
    @staticmethod
    def bisection(function: Callable[[float], Any], bracket: Sequence[Any],
                  tolerance: Any) -> NumericResult:
        low, high, tolerance, f_low, _ = _solver_inputs(function, bracket, tolerance,
                                                        "Root.bisection")
        if f_low == 0.0:
            return NumericResult(low, 0.0, 0, "converged", "bisection", ())
        f_high = _finite(function(high), "Root.bisection")
        if f_high == 0.0:
            return NumericResult(high, 0.0, 0, "converged", "bisection", ())
        trace = []
        for iteration in range(1, 257):
            middle = (low + high) / 2.0
            f_middle = _finite(function(middle), "Root.bisection")
            error = (high - low) / 2.0
            trace.append({"iteration": iteration, "estimate": middle, "error": error})
            if f_middle == 0.0 or error <= tolerance:
                return NumericResult(middle, error, iteration, "converged", "bisection", tuple(trace))
            if f_low * f_middle <= 0.0:
                high = middle
            else:
                low, f_low = middle, f_middle
        return NumericResult((low + high) / 2.0, (high - low) / 2.0, 256,
                             "timeout", "bisection", tuple(trace))

    @staticmethod
    def brent(function: Callable[[float], Any], bracket: Sequence[Any],
              tolerance: Any) -> NumericResult:
        low, high, tolerance, f_low, f_high = _solver_inputs(function, bracket, tolerance,
                                                              "Root.brent")
        if f_low == 0.0:
            return NumericResult(low, 0.0, 0, "converged", "brent", ())
        if f_high == 0.0:
            return NumericResult(high, 0.0, 0, "converged", "brent", ())
        trace = []
        for iteration in range(1, 257):
            denominator = f_high - f_low
            candidate = high - f_high * (high - low) / denominator if denominator else (low + high) / 2
            if not low < candidate < high or min(candidate - low, high - candidate) < tolerance * 0.25:
                candidate = (low + high) / 2.0
            f_candidate = _finite(function(candidate), "Root.brent")
            error = high - low
            trace.append({"iteration": iteration, "estimate": candidate, "error": error})
            if f_candidate == 0.0 or error <= tolerance:
                return NumericResult(candidate, error, iteration, "converged", "brent", tuple(trace))
            if f_low * f_candidate <= 0:
                high, f_high = candidate, f_candidate
            else:
                low, f_low = candidate, f_candidate
        return NumericResult((low + high) / 2, high - low, 256, "timeout", "brent", tuple(trace))

    @staticmethod
    def newton(function: Callable[[float], Any], derivative: Callable[[float], Any],
               initial: Any, options: Mapping[str, Any] | None = None) -> NumericResult:
        operation = "Root.newton"
        _require(callable(function) and callable(derivative), "NEBO-G036-SOLVER-INPUT", operation)
        options = {} if options is None else options
        _require(isinstance(options, Mapping) and set(options) <= {"tolerance", "maxIterations"},
                 "NEBO-G036-SOLVER-OPTIONS", operation)
        tolerance = _finite(options.get("tolerance", 1e-10), operation)
        maximum = _positive(options.get("maxIterations", 64), 256, operation)
        value = _finite(initial, operation)
        trace = []
        for iteration in range(1, maximum + 1):
            residual = _finite(function(value), operation)
            slope = _finite(derivative(value), operation)
            _require(abs(slope) > 1e-15, "NEBO-G036-ROOT-DERIVATIVE", operation)
            next_value = value - residual / slope
            error = abs(next_value - value)
            trace.append({"iteration": iteration, "estimate": next_value, "error": error})
            value = next_value
            if error <= tolerance and abs(_finite(function(value), operation)) <= tolerance:
                return NumericResult(value, error, iteration, "converged", "newton", tuple(trace))
        return NumericResult(value, abs(_finite(function(value), operation)), maximum,
                             "timeout", "newton", tuple(trace))


class Integrate:
    @staticmethod
    def trapezoid(function: Callable[[float], Any], interval: Sequence[Any], steps: int) -> NumericResult:
        low, high = (_finite(value, "Integrate.trapezoid") for value in interval)
        steps = _positive(steps, 65536, "Integrate.trapezoid")
        _require(low < high and callable(function), "NEBO-G036-INTEGRAL-INPUT", "Integrate.trapezoid")
        width = (high - low) / steps
        total = (_finite(function(low), "Integrate.trapezoid") +
                 _finite(function(high), "Integrate.trapezoid")) / 2
        for index in range(1, steps):
            total += _finite(function(low + index * width), "Integrate.trapezoid")
        value = total * width
        return NumericResult(value, abs(width) ** 2, steps + 1, "converged", "trapezoid", ())

    @staticmethod
    def simpson(function: Callable[[float], Any], interval: Sequence[Any], steps: int) -> NumericResult:
        operation = "Integrate.simpson"
        low, high = (_finite(value, operation) for value in interval)
        steps = _positive(steps, 65536, operation)
        _require(low < high and steps % 2 == 0 and callable(function),
                 "NEBO-G036-SIMPSON-STEPS", operation)
        width = (high - low) / steps
        total = _finite(function(low), operation) + _finite(function(high), operation)
        for index in range(1, steps):
            total += (4 if index % 2 else 2) * _finite(function(low + index * width), operation)
        return NumericResult(total * width / 3, abs(width) ** 4, steps + 1,
                             "converged", "simpson", ())

    @staticmethod
    def adaptive(function: Callable[[float], Any], interval: Sequence[Any], tolerance: Any) -> NumericResult:
        operation = "Integrate.adaptive"
        low, high = (_finite(value, operation) for value in interval)
        tolerance = _finite(tolerance, operation)
        _require(low < high and tolerance > 0 and callable(function),
                 "NEBO-G036-INTEGRAL-INPUT", operation)
        evaluations = 0
        trace: list[Mapping[str, Any]] = []
        def sample(point: float) -> float:
            nonlocal evaluations
            evaluations += 1
            _require(evaluations <= MAX_ITERATIONS, "NEBO-G036-INTEGRAL-BUDGET", operation)
            return _finite(function(point), operation)
        a, b = low, high
        fa, fb, fm = sample(a), sample(b), sample((a + b) / 2)
        whole = (b - a) * (fa + 4 * fm + fb) / 6
        stack = [(a, b, fa, fm, fb, whole, tolerance, 0)]
        total = error = 0.0
        while stack:
            a, b, fa, fm, fb, whole, local_tolerance, depth = stack.pop()
            middle = (a + b) / 2
            left_mid, right_mid = (a + middle) / 2, (middle + b) / 2
            flm, frm = sample(left_mid), sample(right_mid)
            left = (middle - a) * (fa + 4 * flm + fm) / 6
            right = (b - middle) * (fm + 4 * frm + fb) / 6
            estimate = abs(left + right - whole) / 15
            if estimate <= local_tolerance or depth >= 20:
                total += left + right + (left + right - whole) / 15
                error += estimate
                trace.append({"depth": depth, "error": estimate})
            else:
                stack.append((middle, b, fm, frm, fb, right, local_tolerance / 2, depth + 1))
                stack.append((a, middle, fa, flm, fm, left, local_tolerance / 2, depth + 1))
        return NumericResult(total, error, evaluations, "converged", "adaptive-simpson", tuple(trace))

    @staticmethod
    def multiDimensional(function: Callable[[Sequence[float]], Any], domain: Sequence[Sequence[Any]],
                         options: Mapping[str, Any] | None = None) -> NumericResult:
        operation = "Integrate.multiDimensional"
        options = {} if options is None else options
        _require(callable(function) and isinstance(options, Mapping) and set(options) <= {"steps"},
                 "NEBO-G036-INTEGRAL-INPUT", operation)
        bounds = tuple(tuple(_finite(value, operation) for value in axis) for axis in domain)
        _require(1 <= len(bounds) <= 3 and all(len(axis) == 2 and axis[0] < axis[1] for axis in bounds),
                 "NEBO-G036-INTEGRAL-DOMAIN", operation)
        steps = _positive(options.get("steps", 8), 32, operation)
        evaluations = steps ** len(bounds)
        _require(evaluations <= 32768, "NEBO-G036-INTEGRAL-BUDGET", operation)
        widths = tuple((high - low) / steps for low, high in bounds)
        total = 0.0
        for indices in itertools.product(range(steps), repeat=len(bounds)):
            point = tuple(bounds[axis][0] + (index + 0.5) * widths[axis]
                          for axis, index in enumerate(indices))
            total += _finite(function(point), operation)
        volume = math.prod(widths)
        return NumericResult(total * volume, max(widths) ** 2, evaluations,
                             "converged", "midpoint-tensor", ())


@dataclass(frozen=True)
class OdeMethodConfig:
    kind: str
    step: float
    options: Mapping[str, Any]


class OdeMethod:
    @staticmethod
    def rk4(step: Any) -> OdeMethodConfig:
        value = _finite(step, "OdeMethod.rk4")
        _require(value > 0, "NEBO-G036-ODE-STEP", "OdeMethod.rk4")
        return OdeMethodConfig("rk4", value, MappingProxyType({}))

    @staticmethod
    def adaptiveRk(options: Mapping[str, Any]) -> OdeMethodConfig:
        operation = "OdeMethod.adaptiveRk"
        _require(isinstance(options, Mapping) and set(options) <= {"initialStep", "minimumStep", "maximumStep"},
                 "NEBO-G036-ODE-OPTIONS", operation)
        initial = _finite(options.get("initialStep", 0.05), operation)
        minimum = _finite(options.get("minimumStep", 1e-6), operation)
        maximum = _finite(options.get("maximumStep", 0.25), operation)
        _require(0 < minimum <= initial <= maximum, "NEBO-G036-ODE-STEP", operation)
        return OdeMethodConfig("adaptive-rk4", initial,
                               MappingProxyType({"minimumStep": minimum, "maximumStep": maximum}))


class OdeProblem:
    def __init__(self, initial: tuple[float, ...], derivative: Callable[..., Any], interval: tuple[float, float]):
        self.initial = initial
        self.derivative = derivative
        self.interval = interval
        self._events: list[tuple[Callable[..., Any], int]] = []

    @staticmethod
    def define(initialState: Sequence[Any], derivative: Callable[..., Any],
               interval: Sequence[Any]) -> "OdeProblem":
        operation = "OdeProblem.define"
        initial = tuple(_finite(value, operation) for value in initialState)
        times = tuple(_finite(value, operation) for value in interval)
        _require(1 <= len(initial) <= 64 and len(times) == 2 and times[0] < times[1] and callable(derivative),
                 "NEBO-G036-ODE-INPUT", operation)
        return OdeProblem(initial, derivative, (times[0], times[1]))

    def event(self, condition: Callable[..., Any], direction: int = 0) -> "OdeProblem":
        _require(callable(condition) and direction in {-1, 0, 1},
                 "NEBO-G036-ODE-EVENT", "ode.event")
        self._events.append((condition, direction))
        return self

    def _derivative(self, time: float, state: tuple[float, ...]) -> tuple[float, ...]:
        values = tuple(_finite(value, "ode.solve") for value in self.derivative(time, state))
        _require(len(values) == len(state), "NEBO-G036-ODE-SHAPE", "ode.solve")
        return values

    def _rk4(self, time: float, state: tuple[float, ...], step: float) -> tuple[float, ...]:
        k1 = self._derivative(time, state)
        k2 = self._derivative(time + step / 2, tuple(y + step * k / 2 for y, k in zip(state, k1)))
        k3 = self._derivative(time + step / 2, tuple(y + step * k / 2 for y, k in zip(state, k2)))
        k4 = self._derivative(time + step, tuple(y + step * k for y, k in zip(state, k3)))
        return tuple(y + step * (a + 2*b + 2*c + d) / 6
                     for y, a, b, c, d in zip(state, k1, k2, k3, k4))

    def solve(self, method: OdeMethodConfig,
              tolerances: Mapping[str, Any] | None = None) -> "Trajectory":
        operation = "ode.solve"
        _require(isinstance(method, OdeMethodConfig), "NEBO-G036-ODE-METHOD", operation)
        tolerances = {} if tolerances is None else tolerances
        _require(isinstance(tolerances, Mapping) and set(tolerances) <= {"absolute", "relative", "maxSteps"},
                 "NEBO-G036-ODE-TOLERANCE", operation)
        absolute = _finite(tolerances.get("absolute", 1e-8), operation)
        relative = _finite(tolerances.get("relative", 1e-8), operation)
        maximum = _positive(tolerances.get("maxSteps", 10000), MAX_ITERATIONS, operation)
        time, end = self.interval
        state, step = self.initial, method.step
        samples = [(time, state)]
        trace: list[Mapping[str, Any]] = []
        events: list[Mapping[str, Any]] = []
        rejected = 0
        previous_events = [_finite(condition(time, state), operation) for condition, _ in self._events]
        while time < end:
            _require(len(trace) < maximum, "NEBO-G036-ODE-BUDGET", operation)
            step = min(step, end - time)
            estimate = 0.0
            if method.kind == "adaptive-rk4":
                whole = self._rk4(time, state, step)
                half = self._rk4(time, state, step / 2)
                half = self._rk4(time + step / 2, half, step / 2)
                estimate = max(abs(a - b) for a, b in zip(whole, half)) / 15
                scale = max(max(abs(value) for value in half), 1.0)
                limit = absolute + relative * scale
                if estimate > limit and step > method.options["minimumStep"]:
                    step = max(method.options["minimumStep"], step / 2)
                    rejected += 1
                    continue
                next_state = half
                if estimate < limit / 16:
                    next_step = min(method.options["maximumStep"], step * 2)
                else:
                    next_step = step
            else:
                next_state = self._rk4(time, state, step)
                next_step = step
            next_time = time + step
            for index, (condition, direction) in enumerate(self._events):
                current = _finite(condition(next_time, next_state), operation)
                crossed = previous_events[index] == 0 or current == 0 or previous_events[index] * current < 0
                slope = current - previous_events[index]
                if crossed and (direction == 0 or (direction > 0 and slope > 0) or (direction < 0 and slope < 0)):
                    events.append({"event": index, "time": next_time, "direction": direction})
                previous_events[index] = current
            time, state = next_time, next_state
            samples.append((time, state))
            trace.append({"step": len(trace) + 1, "time": time, "error": estimate})
            step = next_step
        return Trajectory(samples, trace, events, rejected, absolute, relative, method.kind)


class Trajectory(_EvidenceResult):
    def __init__(self, samples: Sequence[tuple[float, tuple[float, ...]]], trace: Sequence[Mapping[str, Any]],
                 events: Sequence[Mapping[str, Any]], rejected: int, absolute: float, relative: float,
                 algorithm: str) -> None:
        self._samples = tuple(samples)
        self._trace = tuple(trace)
        self._events = tuple(events)
        self._rejected = rejected
        self._absolute = absolute
        self._relative = relative
        self._algorithm = algorithm

    def sample(self, time: Any) -> tuple[float, ...]:
        time = _finite(time, "trajectory.sample")
        _require(self._samples[0][0] <= time <= self._samples[-1][0],
                 "NEBO-G036-ODE-TIME", "trajectory.sample")
        for index in range(1, len(self._samples)):
            right_time, right = self._samples[index]
            if time <= right_time:
                left_time, left = self._samples[index - 1]
                ratio = 0.0 if right_time == left_time else (time - left_time) / (right_time - left_time)
                return tuple(a + ratio * (b - a) for a, b in zip(left, right))
        return self._samples[-1][1]

    def steps(self) -> int:
        return len(self._samples) - 1

    def errorReport(self) -> Mapping[str, Any]:
        return MappingProxyType({"acceptedSteps": self.steps(), "rejectedSteps": self._rejected,
                                 "maximumEstimate": max((record["error"] for record in self._trace), default=0.0),
                                 "absoluteTolerance": self._absolute, "relativeTolerance": self._relative,
                                 "events": tuple(MappingProxyType(dict(event)) for event in self._events)})

    def _payload(self) -> Any:
        return {"samples": self._samples, "events": self._events,
                "accepted": self.steps(), "rejected": self._rejected}


@dataclass(frozen=True)
class Grid:
    bounds: tuple[tuple[float, float], ...]
    shape: tuple[int, ...]

    @staticmethod
    def uniform(bounds: Sequence[Any], shape: Sequence[int]) -> "Grid":
        operation = "Grid.uniform"
        shape = tuple(shape)
        _require(1 <= len(shape) <= 2, "NEBO-G036-GRID-RANK", operation)
        dimensions = tuple(_positive(value, 256, operation) for value in shape)
        _require(math.prod(dimensions) <= MAX_GRID_CELLS, "NEBO-G036-GRID-BUDGET", operation)
        if len(shape) == 1 and len(bounds) == 2 and not isinstance(bounds[0], Sequence):
            bounds = (bounds,)
        normalized = tuple(tuple(_finite(value, operation) for value in axis) for axis in bounds)
        _require(len(normalized) == len(shape) and all(len(axis) == 2 and axis[0] < axis[1]
                 for axis in normalized) and all(size >= 3 for size in dimensions),
                 "NEBO-G036-GRID-BOUNDS", operation)
        return Grid(normalized, dimensions)

    def coordinates(self) -> tuple[Any, ...]:
        axes = [tuple(low + index * (high - low) / (size - 1) for index in range(size))
                for (low, high), size in zip(self.bounds, self.shape)]
        if len(axes) == 1:
            return axes[0]
        return tuple(itertools.product(*axes))


@dataclass(frozen=True)
class Boundary:
    kind: str
    region: str
    value: float

    @staticmethod
    def dirichlet(region: str, value: Any) -> "Boundary":
        _require(region in {"lower", "upper", "all"}, "NEBO-G036-BOUNDARY-REGION", "Boundary.dirichlet")
        return Boundary("dirichlet", region, _finite(value, "Boundary.dirichlet"))

    @staticmethod
    def neumann(region: str, flux: Any) -> "Boundary":
        _require(region in {"lower", "upper", "all"}, "NEBO-G036-BOUNDARY-REGION", "Boundary.neumann")
        return Boundary("neumann", region, _finite(flux, "Boundary.neumann"))


class PdeProblem:
    def __init__(self, operator: Callable[[float], Any], grid: Grid,
                 boundaries: tuple[Boundary, ...]) -> None:
        self.operator, self.grid, self.boundaries = operator, grid, boundaries

    @staticmethod
    def define(operator: Callable[[float], Any], grid: Grid,
               boundaries: Sequence[Boundary]) -> "PdeProblem":
        operation = "PdeProblem.define"
        boundaries = tuple(boundaries)
        _require(callable(operator) and isinstance(grid, Grid) and len(grid.shape) == 1 and
                 boundaries and all(isinstance(value, Boundary) for value in boundaries),
                 "NEBO-G036-PDE-INPUT", operation)
        return PdeProblem(operator, grid, boundaries)

    def solve(self, method: str = "jacobi", options: Mapping[str, Any] | None = None) -> "Field":
        operation = "pde.solve"
        options = {} if options is None else options
        _require(method == "jacobi" and isinstance(options, Mapping) and
                 set(options) <= {"tolerance", "maxIterations"},
                 "NEBO-G036-PDE-METHOD", operation)
        tolerance = _finite(options.get("tolerance", 1e-10), operation)
        maximum = _positive(options.get("maxIterations", 10000), MAX_ITERATIONS, operation)
        lower = next((b.value for b in self.boundaries if b.kind == "dirichlet" and b.region in {"lower", "all"}), None)
        upper = next((b.value for b in self.boundaries if b.kind == "dirichlet" and b.region in {"upper", "all"}), None)
        _require(lower is not None and upper is not None, "NEBO-G036-PDE-BOUNDARY", operation)
        coordinates = self.grid.coordinates()
        step = coordinates[1] - coordinates[0]
        values = [0.0] * self.grid.shape[0]
        values[0], values[-1] = lower, upper
        trace = []
        for iteration in range(1, maximum + 1):
            updated = values[:]
            residual = 0.0
            for index in range(1, len(values) - 1):
                source = _finite(self.operator(coordinates[index]), operation)
                updated[index] = (values[index - 1] + values[index + 1] + step * step * source) / 2
                residual = max(residual, abs(updated[index] - values[index]))
            values = updated
            trace.append({"iteration": iteration, "residual": residual})
            if residual <= tolerance:
                return Field(self.grid, values, trace, residual, "converged")
        return Field(self.grid, values, trace, trace[-1]["residual"], "timeout")


class Field(_EvidenceResult):
    def __init__(self, grid: Grid, values: Sequence[Any], trace: Sequence[Mapping[str, Any]],
                 residual: float, status: str) -> None:
        self.grid = grid
        self.values = tuple(float(value) for value in values)
        self._trace = tuple(trace)
        self.residual = residual
        self.status = status
        self._algorithm = "poisson1d-jacobi"

    def gradient(self) -> tuple[float, ...]:
        step = self.grid.coordinates()[1] - self.grid.coordinates()[0]
        result = [(self.values[1] - self.values[0]) / step]
        result.extend((self.values[index + 1] - self.values[index - 1]) / (2 * step)
                      for index in range(1, len(self.values) - 1))
        result.append((self.values[-1] - self.values[-2]) / step)
        return tuple(result)

    def laplacian(self) -> tuple[float, ...]:
        step = self.grid.coordinates()[1] - self.grid.coordinates()[0]
        result = [0.0]
        result.extend((self.values[index - 1] - 2 * self.values[index] + self.values[index + 1]) / step**2
                      for index in range(1, len(self.values) - 1))
        result.append(0.0)
        return tuple(result)

    def _payload(self) -> Any:
        return {"values": self.values, "residual": self.residual, "status": self.status}


@dataclass(frozen=True)
class OptimizerConfig:
    kind: str
    options: Mapping[str, Any]

    def bounds(self, lower: Sequence[Any], upper: Sequence[Any]) -> "Optimizer":
        return Optimizer(self, lower, upper, ())

    def constraints(self, functions: Sequence[Callable[[Sequence[float]], Any]]) -> "Optimizer":
        return Optimizer(self, (), (), functions)

    def minimize(self, function: Callable[[Sequence[float]], Any], initial: Sequence[Any]) -> "Solution":
        return Optimizer(self, (), (), ()).minimize(function, initial)


class ContinuousOptimizer:
    @staticmethod
    def _new(kind: str, options: Mapping[str, Any] | None) -> OptimizerConfig:
        operation = f"ContinuousOptimizer.{kind}"
        options = {} if options is None else options
        allowed = {"learningRate", "tolerance", "maxIterations", "history", "beta1", "beta2", "epsilon"}
        _require(isinstance(options, Mapping) and set(options) <= allowed,
                 "NEBO-G036-OPTIMIZER-OPTIONS", operation)
        normalized = dict(options)
        normalized.setdefault("learningRate", 0.1 if kind != "adam" else 0.05)
        normalized.setdefault("tolerance", 1e-8)
        normalized.setdefault("maxIterations", 1000)
        normalized.setdefault("history", 8)
        normalized.setdefault("beta1", 0.9)
        normalized.setdefault("beta2", 0.999)
        normalized.setdefault("epsilon", 1e-8)
        _finite(normalized["learningRate"], operation)
        _finite(normalized["tolerance"], operation)
        _positive(normalized["maxIterations"], MAX_ITERATIONS, operation)
        _positive(normalized["history"], 32, operation)
        return OptimizerConfig(kind, MappingProxyType(normalized))

    @staticmethod
    def gradientDescent(options: Mapping[str, Any] | None = None) -> OptimizerConfig:
        return ContinuousOptimizer._new("gradientDescent", options)

    @staticmethod
    def lbfgs(options: Mapping[str, Any] | None = None) -> OptimizerConfig:
        return ContinuousOptimizer._new("lbfgs", options)

    @staticmethod
    def adam(options: Mapping[str, Any] | None = None) -> OptimizerConfig:
        return ContinuousOptimizer._new("adam", options)


class Optimizer:
    def __init__(self, config: OptimizerConfig, lower: Sequence[Any], upper: Sequence[Any],
                 constraints: Sequence[Callable[[Sequence[float]], Any]]) -> None:
        self.config = config
        self.lower = tuple(_finite(value, "optimizer.bounds") for value in lower)
        self.upper = tuple(_finite(value, "optimizer.bounds") for value in upper)
        _require((not self.lower and not self.upper) or
                 (len(self.lower) == len(self.upper) and all(a <= b for a, b in zip(self.lower, self.upper))),
                 "NEBO-G036-OPTIMIZER-BOUNDS", "optimizer.bounds")
        self._constraints = tuple(constraints)
        _require(all(callable(value) for value in self._constraints),
                 "NEBO-G036-OPTIMIZER-CONSTRAINT", "optimizer.constraints")

    def bounds(self, lower: Sequence[Any], upper: Sequence[Any]) -> "Optimizer":
        return Optimizer(self.config, lower, upper, self._constraints)

    def constraints(self, functions: Sequence[Callable[[Sequence[float]], Any]]) -> "Optimizer":
        return Optimizer(self.config, self.lower, self.upper, functions)

    @staticmethod
    def _evaluate(function: Callable[[Sequence[float]], Any], point: tuple[float, ...]) -> tuple[float, tuple[float, ...]]:
        operation = "optimizer.minimize"
        observed = function(point)
        _require(isinstance(observed, Sequence) and len(observed) == 2,
                 "NEBO-G036-OPTIMIZER-OBJECTIVE", operation)
        value = _finite(observed[0], operation)
        gradient = tuple(_finite(item, operation) for item in observed[1])
        _require(len(gradient) == len(point), "NEBO-G036-OPTIMIZER-SHAPE", operation)
        return value, gradient

    def minimize(self, function: Callable[[Sequence[float]], Any], initial: Sequence[Any]) -> "Solution":
        operation = "optimizer.minimize"
        _require(callable(function), "NEBO-G036-OPTIMIZER-OBJECTIVE", operation)
        point = tuple(_finite(value, operation) for value in initial)
        _require(1 <= len(point) <= 256, "NEBO-G036-OPTIMIZER-SHAPE", operation)
        if self.lower:
            _require(len(self.lower) == len(point), "NEBO-G036-OPTIMIZER-SHAPE", operation)
            point = tuple(min(max(value, low), high) for value, low, high in zip(point, self.lower, self.upper))
        options = self.config.options
        rate = _finite(options["learningRate"], operation)
        tolerance = _finite(options["tolerance"], operation)
        maximum = _positive(options["maxIterations"], MAX_ITERATIONS, operation)
        _require(rate > 0 and tolerance > 0, "NEBO-G036-OPTIMIZER-OPTIONS", operation)
        trace: list[Mapping[str, Any]] = []
        moment = [0.0] * len(point)
        variance = [0.0] * len(point)
        prior_point: tuple[float, ...] | None = None
        prior_gradient: tuple[float, ...] | None = None
        inverse_scale = 1.0
        status = "timeout"
        for iteration in range(1, maximum + 1):
            try:
                value, gradient = self._evaluate(function, point)
            except ScientificError as error:
                if error.code() == "NEBO-G036-NONFINITE":
                    trace.append({"iteration": iteration, "status": "invalid",
                                  "diagnostic": error.code()})
                    return Solution(point, 0.0, 0.0, "invalid", tuple(trace), self.config.kind)
                raise
            penalty_gradient = [0.0] * len(point)
            penalty = 0.0
            for constraint in self._constraints:
                observed = constraint(point)
                _require(isinstance(observed, Sequence) and len(observed) == 2,
                         "NEBO-G036-OPTIMIZER-CONSTRAINT", operation)
                violation = max(0.0, _finite(observed[0], operation))
                derivative = tuple(_finite(item, operation) for item in observed[1])
                _require(len(derivative) == len(point), "NEBO-G036-OPTIMIZER-SHAPE", operation)
                penalty += 100.0 * violation * violation
                for index, item in enumerate(derivative):
                    penalty_gradient[index] += 200.0 * violation * item
            gradient = tuple(a + b for a, b in zip(gradient, penalty_gradient))
            norm = math.sqrt(sum(item * item for item in gradient))
            trace.append({"iteration": iteration, "value": value + penalty, "gradientNorm": norm})
            if norm <= tolerance:
                status = "converged"
                break
            if self.config.kind == "adam":
                beta1, beta2, epsilon = options["beta1"], options["beta2"], options["epsilon"]
                for index, item in enumerate(gradient):
                    moment[index] = beta1 * moment[index] + (1 - beta1) * item
                    variance[index] = beta2 * variance[index] + (1 - beta2) * item * item
                direction = tuple((moment[index] / (1 - beta1**iteration)) /
                                  (math.sqrt(variance[index] / (1 - beta2**iteration)) + epsilon)
                                  for index in range(len(point)))
            elif self.config.kind == "lbfgs":
                if prior_point is not None and prior_gradient is not None:
                    s = tuple(a - b for a, b in zip(point, prior_point))
                    y = tuple(a - b for a, b in zip(gradient, prior_gradient))
                    yy = sum(item * item for item in y)
                    if yy > 1e-30:
                        inverse_scale = max(1e-6, min(1e6, sum(a*b for a, b in zip(s, y)) / yy))
                direction = tuple(inverse_scale * item for item in gradient)
            else:
                direction = gradient
            prior_point, prior_gradient = point, gradient
            candidate = tuple(value - rate * direction[index] for index, value in enumerate(point))
            if any(not math.isfinite(value) or abs(value) > 1e12 for value in candidate):
                status = "diverged"
                break
            if self.lower:
                candidate = tuple(min(max(value, low), high)
                                  for value, low, high in zip(candidate, self.lower, self.upper))
            if candidate == point:
                status = "stalled"
                break
            point = candidate
        value, gradient = self._evaluate(function, point)
        return Solution(point, value, math.sqrt(sum(item * item for item in gradient)),
                        status, tuple(trace), self.config.kind)


class Solution(_EvidenceResult):
    def __init__(self, point: Sequence[float], value: float, norm: float, status: str,
                 trace: Sequence[Mapping[str, Any]], algorithm: str) -> None:
        self.point, self.value, self.norm, self.status = tuple(point), value, norm, status
        self._trace = tuple(trace)
        self._algorithm = algorithm

    def gradientNorm(self) -> float:
        return self.norm

    def optimalityReport(self) -> Mapping[str, Any]:
        return MappingProxyType({"status": self.status, "objective": self.value,
                                 "gradientNorm": self.norm, "iterations": len(self._trace),
                                 "method": self._algorithm})

    def _payload(self) -> Any:
        return {"point": self.point, "objective": self.value,
                "gradientNorm": self.norm, "status": self.status}


@dataclass(frozen=True)
class ScientificContext:
    options: Mapping[str, Any]

    @staticmethod
    def new(options: Mapping[str, Any] | None = None) -> "ScientificContext":
        operation = "ScientificContext.new"
        options = {} if options is None else options
        allowed = {"dtype", "rounding", "threads", "deterministic", "absoluteTolerance", "relativeTolerance"}
        _require(isinstance(options, Mapping) and set(options) <= allowed,
                 "NEBO-G036-CONTEXT-OPTIONS", operation)
        normalized = {"dtype": options.get("dtype", "binary64"),
                      "rounding": options.get("rounding", "nearest-even"),
                      "threads": options.get("threads", 1),
                      "deterministic": options.get("deterministic", True),
                      "absoluteTolerance": options.get("absoluteTolerance", 1e-9),
                      "relativeTolerance": options.get("relativeTolerance", 1e-9)}
        _require(normalized["dtype"] == "binary64" and normalized["rounding"] == "nearest-even" and
                 normalized["threads"] == 1 and normalized["deterministic"] is True,
                 "NEBO-G036-CONTEXT-UNSUPPORTED", operation)
        _require(_finite(normalized["absoluteTolerance"], operation) >= 0 and
                 _finite(normalized["relativeTolerance"], operation) >= 0,
                 "NEBO-G036-TOLERANCE", operation)
        return ScientificContext(MappingProxyType(normalized))

    def manifest(self) -> Mapping[str, Any]:
        return MappingProxyType({"schema": "nebo-scientific-context-v1",
                                 **dict(self.options), "target": "cpu-reference",
                                 "implementation": "bounded-scalar"})


def scientific_bench(suite: str) -> Mapping[str, Any]:
    _require(suite in {"core", "sparse", "fft", "solvers"},
             "NEBO-G036-BENCH-SUITE", "scientific-bench")
    cases: dict[str, Any] = {}
    if suite in {"core", "sparse"}:
        sparse = SparseMatrix.csr(2, 3, (0, 2, 3), (0, 2, 1), (1, 2, 3))
        cases["sparse"] = {"value": sparse.matmul((4, 5, 6)), "workUnits": 3}
    if suite in {"core", "fft"}:
        spectrum = Fft.plan(4).forward((1, 0, 0, 0))
        cases["fft"] = {"power": spectrum.power(), "workUnits": 16}
    if suite in {"core", "solvers"}:
        root = Root.bisection(lambda x: x*x - 2, (0, 2), 1e-10)
        cases["root"] = {"value": root.value, "error": root.error,
                         "workUnits": root.iterations}
    payload = {"schema": "nebo-scientific-bench-v1", "suite": suite,
               "methodology": "deterministic logical work units; not wall-clock time",
               "context": dict(ScientificContext.new().manifest()), "cases": cases}
    return MappingProxyType({**payload, "sha256": _digest(payload)})


def numeric_report(artifact: Mapping[str, Any]) -> Mapping[str, Any]:
    _require(isinstance(artifact, Mapping) and artifact.get("schema") == "nebo-scientific-bench-v1" and
             isinstance(artifact.get("cases"), Mapping),
             "NEBO-G036-REPORT-SCHEMA", "numeric-report")
    supplied_digest = artifact.get("sha256")
    unsigned_artifact = {key: value for key, value in artifact.items() if key != "sha256"}
    _require(isinstance(supplied_digest, str) and len(supplied_digest) == 64 and
             all(character in "0123456789abcdef" for character in supplied_digest) and
             supplied_digest == _digest(unsigned_artifact),
             "NEBO-G036-REPORT-INTEGRITY", "numeric-report")
    case_names = tuple(sorted(artifact["cases"]))
    work_units = 0
    for value in artifact["cases"].values():
        _require(isinstance(value, Mapping) and isinstance(value.get("workUnits"), int),
                 "NEBO-G036-REPORT-SCHEMA", "numeric-report")
        work_units += value["workUnits"]
    payload = {"schema": "nebo-numeric-report-v1", "sourceSchema": artifact["schema"],
               "suite": artifact.get("suite"), "cases": case_names,
               "totalWorkUnits": work_units, "artifactSha256": _digest(artifact),
               "status": "valid"}
    return MappingProxyType(payload)


__all__ = [
    "Boundary", "ContinuousOptimizer", "Fft", "FftPlan", "Field", "Grid", "Integrate",
    "NumericResult", "OdeMethod", "OdeProblem", "Optimizer", "PdeProblem", "Root", "ScientificContext",
    "ScientificError", "Signal", "Solution", "SparseMatrix", "SparseVector",
    "Spectrum", "Trajectory", "WindowFunction", "numeric_report", "scientific_bench",
]
