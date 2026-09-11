"""Bounded, correctness-first SDK for Nebo G020 CPU inference.

The historical native runtime owns the scalar x86_64 kernels and NMF1 format.
This module exposes the complete current catalogue vocabulary with tiny local
models, explicit shapes, deterministic serialization, and measured int8 error.
It deliberately provides inference only; training and gradient state belong to
G021.
"""
from __future__ import annotations

from dataclasses import dataclass
import copy
import hashlib
import json
import math
import os
from pathlib import Path
import statistics
import time
from typing import Any, Iterable, Iterator, Mapping, MutableMapping, Sequence

from compiler.sdk.numeric_kernels import KernelError, kernel


MAX_ELEMENTS = 4096
MAX_DIMENSION = 64
MAX_LAYERS = 64
MAX_MODEL_BYTES = 1_048_576
MAX_BATCH = 16
MAX_WARMUP = 16
MAX_WORKSPACE_BYTES = 1_048_576
NMF_MAGIC = "NMF1"
NMF_VERSION = 1


class MlError(ValueError):
    """Stable fail-closed error for the bounded G020 profile."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def _require(condition: bool, code: str) -> None:
    if not condition:
        raise MlError(code)


def _product(shape: Sequence[int]) -> int:
    _require(1 <= len(shape) <= 4, "NEBO-G020-RANK")
    total = 1
    for dimension in shape:
        _require(isinstance(dimension, int) and not isinstance(dimension, bool),
                 "NEBO-G020-SHAPE")
        _require(1 <= dimension <= MAX_DIMENSION, "NEBO-G020-DIMENSION-BUDGET")
        total *= dimension
        _require(total <= MAX_ELEMENTS, "NEBO-G020-ELEMENT-BUDGET")
    return total


def _finite(values: Iterable[int | float]) -> tuple[float, ...]:
    try:
        source = tuple(values)
        _require(not any(isinstance(value, bool) for value in source),
                 "NEBO-G020-NUMERIC-VALUE")
        result = tuple(float(value) for value in source)
    except (TypeError, ValueError, OverflowError) as error:
        raise MlError("NEBO-G020-NUMERIC-VALUE") from error
    _require(len(result) <= MAX_ELEMENTS, "NEBO-G020-ELEMENT-BUDGET")
    _require(all(math.isfinite(value) for value in result), "NEBO-G020-NONFINITE")
    return result


def _round_int8(value: float) -> int:
    rounded = math.floor(value + 0.5) if value >= 0 else math.ceil(value - 0.5)
    return max(-128, min(127, rounded))


def _canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=True, allow_nan=False).encode("ascii")


@dataclass(frozen=True)
class QuantizedParameters:
    scale: float
    zero_point: int


@dataclass(frozen=True)
class Tensor:
    values: tuple[float | int, ...]
    shape: tuple[int, ...]
    dtype: str = "f64"
    quantization: QuantizedParameters | None = None

    def __init__(self, values: Iterable[int | float], shape: Sequence[int],
                 dtype: str = "f64",
                 quantization: QuantizedParameters | None = None) -> None:
        shape_tuple = tuple(shape)
        expected = _product(shape_tuple)
        raw = tuple(values)
        _require(len(raw) == expected, "NEBO-G020-SHAPE-MISMATCH")
        _require(dtype in {"f64", "i8"}, "NEBO-G020-DTYPE")
        if dtype == "f64":
            converted: tuple[float | int, ...] = _finite(raw)
            _require(quantization is None, "NEBO-G020-QUANTIZATION-METADATA")
        else:
            _require(all(isinstance(value, int) and not isinstance(value, bool)
                         and -128 <= value <= 127 for value in raw),
                     "NEBO-G020-INT8-RANGE")
            _require(quantization is not None, "NEBO-G020-QUANTIZATION-METADATA")
            converted = tuple(int(value) for value in raw)
        object.__setattr__(self, "values", converted)
        object.__setattr__(self, "shape", shape_tuple)
        object.__setattr__(self, "dtype", dtype)
        object.__setattr__(self, "quantization", quantization)

    @property
    def elements(self) -> int:
        return len(self.values)

    @property
    def nbytes(self) -> int:
        return self.elements * (8 if self.dtype == "f64" else 1)

    def reshape(self, shape: Sequence[int]) -> "Tensor":
        _require(_product(tuple(shape)) == self.elements, "NEBO-G020-SHAPE-MISMATCH")
        return Tensor(self.values, shape, self.dtype, self.quantization)

    def quantize(self, scale: float, zeroPoint: int) -> "Tensor":
        _require(self.dtype == "f64", "NEBO-G020-QUANTIZE-DTYPE")
        _require(isinstance(scale, (int, float)) and not isinstance(scale, bool)
                 and math.isfinite(float(scale)) and float(scale) > 0.0,
                 "NEBO-G020-QUANTIZE-SCALE")
        _require(isinstance(zeroPoint, int) and not isinstance(zeroPoint, bool)
                 and -128 <= zeroPoint <= 127, "NEBO-G020-ZERO-POINT")
        scale_value = float(scale)
        result = tuple(_round_int8(float(value) / scale_value + zeroPoint)
                       for value in self.values)
        return Tensor(result, self.shape, "i8", QuantizedParameters(scale_value, zeroPoint))

    def dequantize(self) -> "Tensor":
        _require(self.dtype == "i8" and self.quantization is not None,
                 "NEBO-G020-DEQUANTIZE-DTYPE")
        params = self.quantization
        result = tuple((int(value) - params.zero_point) * params.scale for value in self.values)
        return Tensor(result, self.shape)

    def digest(self) -> str:
        return hashlib.sha256(_canonical(_tensor_to_dict(self))).hexdigest()


def _float_tensor(value: Tensor) -> Tensor:
    return value.dequantize() if value.dtype == "i8" else value


def _tensor_to_dict(tensor: Tensor) -> dict[str, Any]:
    result: dict[str, Any] = {
        "dtype": tensor.dtype,
        "shape": list(tensor.shape),
        "values": list(tensor.values),
    }
    if tensor.quantization is not None:
        result["quantization"] = {
            "scale": tensor.quantization.scale,
            "zeroPoint": tensor.quantization.zero_point,
        }
    return result


def _tensor_from_dict(data: Mapping[str, Any]) -> Tensor:
    _require(isinstance(data, Mapping), "NEBO-G020-MODEL-TENSOR")
    quantization = data.get("quantization")
    params = None
    if quantization is not None:
        _require(isinstance(quantization, Mapping), "NEBO-G020-MODEL-TENSOR")
        params = QuantizedParameters(float(quantization["scale"]),
                                     int(quantization["zeroPoint"]))
    return Tensor(data["values"], data["shape"], str(data["dtype"]), params)


class Linear:
    def __init__(self, input_size: int, output_size: int, bias: bool) -> None:
        _require(isinstance(input_size, int) and 1 <= input_size <= MAX_DIMENSION,
                 "NEBO-G020-LINEAR-INPUT")
        _require(isinstance(output_size, int) and 1 <= output_size <= MAX_DIMENSION,
                 "NEBO-G020-LINEAR-OUTPUT")
        _require(isinstance(bias, bool), "NEBO-G020-LINEAR-BIAS")
        _require(input_size * output_size <= MAX_ELEMENTS, "NEBO-G020-ELEMENT-BUDGET")
        self.input_size = input_size
        self.output_size = output_size
        self.weight = Tensor([0.0] * (output_size * input_size),
                             (output_size, input_size))
        self.bias = Tensor([0.0] * output_size, (output_size,)) if bias else None

    @staticmethod
    def new(inputSize: int, outputSize: int, bias: bool) -> "Linear":
        return Linear(inputSize, outputSize, bias)

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        _require(source.shape[-1] == self.input_size and len(source.shape) in {1, 2},
                 "NEBO-G020-LINEAR-SHAPE")
        rows = 1 if len(source.shape) == 1 else source.shape[0]
        matrix = [list(source.values[row * self.input_size:(row + 1) * self.input_size])
                  for row in range(rows)]
        weights = _float_tensor(self.weight)
        transposed = [[float(weights.values[out * self.input_size + inner])
                       for out in range(self.output_size)]
                      for inner in range(self.input_size)]
        try:
            result = kernel.scalar.matmul(matrix, transposed)
        except KernelError as error:
            raise MlError("NEBO-G020-KERNEL-" + error.code) from error
        bias = _float_tensor(self.bias) if self.bias is not None else None
        flattened = [value + (float(bias.values[column]) if bias is not None else 0.0)
                     for row in result for column, value in enumerate(row)]
        shape = (self.output_size,) if rows == 1 else (rows, self.output_size)
        return Tensor(flattened, shape)


class Activation:
    @staticmethod
    def relu(input: Tensor) -> Tensor:
        source = _float_tensor(input)
        return Tensor((max(0.0, float(value)) for value in source.values), source.shape)

    @staticmethod
    def gelu(input: Tensor, approximation: str = "tanh") -> Tensor:
        _require(approximation in {"tanh", "exact"}, "NEBO-G020-GELU-APPROXIMATION")
        source = _float_tensor(input)
        result = []
        for raw in source.values:
            value = float(raw)
            if approximation == "exact":
                result.append(0.5 * value * (1.0 + math.erf(value / math.sqrt(2.0))))
            else:
                result.append(0.5 * value * (1.0 + math.tanh(
                    math.sqrt(2.0 / math.pi) * (value + 0.044715 * value ** 3))))
        return Tensor(result, source.shape)

    @staticmethod
    def sigmoid(input: Tensor) -> Tensor:
        source = _float_tensor(input)
        result = []
        for raw in source.values:
            value = float(raw)
            if value >= 0.0:
                result.append(1.0 / (1.0 + math.exp(-value)))
            else:
                exponential = math.exp(value)
                result.append(exponential / (1.0 + exponential))
        return Tensor(result, source.shape)

    @staticmethod
    def tanh(input: Tensor) -> Tensor:
        source = _float_tensor(input)
        return Tensor((math.tanh(float(value)) for value in source.values), source.shape)


class Softmax:
    @staticmethod
    def forward(input: Tensor, axis: int = -1) -> Tensor:
        source = _float_tensor(input)
        rank = len(source.shape)
        normalized_axis = axis + rank if axis < 0 else axis
        _require(normalized_axis == rank - 1, "NEBO-G020-SOFTMAX-AXIS")
        width = source.shape[-1]
        result: list[float] = []
        for offset in range(0, source.elements, width):
            row = [float(value) for value in source.values[offset:offset + width]]
            maximum = max(row)
            exponentials = [math.exp(value - maximum) for value in row]
            denominator = sum(exponentials)
            result.extend(value / denominator for value in exponentials)
        return Tensor(result, source.shape)


class Sequential:
    def __init__(self, layers: Sequence[Any]) -> None:
        _require(1 <= len(layers) <= MAX_LAYERS, "NEBO-G020-LAYER-BUDGET")
        _require(all(callable(getattr(layer, "forward", None)) for layer in layers),
                 "NEBO-G020-LAYER")
        self.layers = tuple(layers)

    @staticmethod
    def new(layers: Sequence[Any]) -> "Sequential":
        return Sequential(layers)

    def forward(self, input: Tensor) -> Tensor:
        value = input
        for layer in self.layers:
            value = layer.forward(value)
            _require(isinstance(value, Tensor), "NEBO-G020-LAYER-OUTPUT")
        return value


class LayerNorm:
    def __init__(self, shape: int | Sequence[int], epsilon: float) -> None:
        normalized = (shape,) if isinstance(shape, int) else tuple(shape)
        self.normalized_shape = normalized
        _product(normalized)
        _require(math.isfinite(float(epsilon)) and 0.0 < float(epsilon) <= 0.1,
                 "NEBO-G020-EPSILON")
        self.epsilon = float(epsilon)

    @staticmethod
    def new(shape: int | Sequence[int], epsilon: float) -> "LayerNorm":
        return LayerNorm(shape, epsilon)

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        width = _product(self.normalized_shape)
        _require(tuple(source.shape[-len(self.normalized_shape):]) == self.normalized_shape,
                 "NEBO-G020-NORM-SHAPE")
        result: list[float] = []
        for offset in range(0, source.elements, width):
            values = [float(value) for value in source.values[offset:offset + width]]
            mean = sum(values) / width
            variance = sum((value - mean) ** 2 for value in values) / width
            denominator = math.sqrt(variance + self.epsilon)
            result.extend((value - mean) / denominator for value in values)
        return Tensor(result, source.shape)


class BatchNorm:
    def __init__(self, features: int, epsilon: float) -> None:
        _require(isinstance(features, int) and 1 <= features <= MAX_DIMENSION,
                 "NEBO-G020-BATCHNORM-FEATURES")
        _require(math.isfinite(float(epsilon)) and 0.0 < float(epsilon) <= 0.1,
                 "NEBO-G020-EPSILON")
        self.features = features
        self.epsilon = float(epsilon)
        self.running_mean = Tensor([0.0] * features, (features,))
        self.running_variance = Tensor([1.0] * features, (features,))
        self.weight = Tensor([1.0] * features, (features,))
        self.bias = Tensor([0.0] * features, (features,))

    @staticmethod
    def new(features: int, epsilon: float) -> "BatchNorm":
        return BatchNorm(features, epsilon)

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        _require(source.shape[-1] == self.features, "NEBO-G020-NORM-SHAPE")
        result = []
        for index, raw in enumerate(source.values):
            feature = index % self.features
            normalized = ((float(raw) - float(self.running_mean.values[feature])) /
                          math.sqrt(float(self.running_variance.values[feature]) + self.epsilon))
            result.append(normalized * float(self.weight.values[feature]) +
                          float(self.bias.values[feature]))
        return Tensor(result, source.shape)


class Dropout:
    def __init__(self, probability: float) -> None:
        _require(isinstance(probability, (int, float)) and not isinstance(probability, bool)
                 and math.isfinite(float(probability)) and 0.0 <= float(probability) < 1.0,
                 "NEBO-G020-DROPOUT-PROBABILITY")
        self.probability = float(probability)

    @staticmethod
    def new(probability: float) -> "Dropout":
        return Dropout(probability)

    def forward(self, input: Tensor) -> Tensor:
        return input


class Residual:
    def __init__(self, block: Any) -> None:
        _require(callable(getattr(block, "forward", None)), "NEBO-G020-LAYER")
        self.block = block

    @staticmethod
    def new(block: Any) -> "Residual":
        return Residual(block)

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        output = _float_tensor(self.block.forward(source))
        _require(output.shape == source.shape, "NEBO-G020-RESIDUAL-SHAPE")
        return Tensor((float(left) + float(right)
                       for left, right in zip(source.values, output.values)), source.shape)


class Flatten:
    def __init__(self, start_axis: int, end_axis: int) -> None:
        _require(isinstance(start_axis, int) and isinstance(end_axis, int),
                 "NEBO-G020-FLATTEN-AXIS")
        self.start_axis = start_axis
        self.end_axis = end_axis

    @staticmethod
    def new(startAxis: int, endAxis: int) -> "Flatten":
        return Flatten(startAxis, endAxis)

    def forward(self, input: Tensor) -> Tensor:
        rank = len(input.shape)
        start = self.start_axis + rank if self.start_axis < 0 else self.start_axis
        end = self.end_axis + rank if self.end_axis < 0 else self.end_axis
        _require(0 <= start <= end < rank, "NEBO-G020-FLATTEN-AXIS")
        flattened = math.prod(input.shape[start:end + 1])
        shape = input.shape[:start] + (flattened,) + input.shape[end + 1:]
        return input.reshape(shape)


class Embedding:
    def __init__(self, count: int, dimension: int) -> None:
        _require(isinstance(count, int) and 1 <= count <= MAX_DIMENSION,
                 "NEBO-G020-EMBEDDING-COUNT")
        _require(isinstance(dimension, int) and 1 <= dimension <= MAX_DIMENSION,
                 "NEBO-G020-EMBEDDING-DIMENSION")
        _require(count * dimension <= MAX_ELEMENTS, "NEBO-G020-ELEMENT-BUDGET")
        self.count = count
        self.dimension = dimension
        self.weight = Tensor([0.0] * (count * dimension), (count, dimension))

    @staticmethod
    def new(count: int, dimension: int) -> "Embedding":
        return Embedding(count, dimension)

    def forward(self, indices: Sequence[int]) -> Tensor:
        _require(1 <= len(indices) <= MAX_ELEMENTS, "NEBO-G020-EMBEDDING-INDICES")
        _require(all(isinstance(index, int) and not isinstance(index, bool)
                     and 0 <= index < self.count for index in indices),
                 "NEBO-G020-EMBEDDING-INDEX")
        weight = _float_tensor(self.weight)
        values = []
        for index in indices:
            start = index * self.dimension
            values.extend(weight.values[start:start + self.dimension])
        return Tensor(values, (len(indices), self.dimension))


def _pair(value: int | Sequence[int], code: str) -> tuple[int, int]:
    pair = (value, value) if isinstance(value, int) else tuple(value)
    _require(len(pair) == 2 and all(isinstance(item, int) and 1 <= item <= MAX_DIMENSION
                                    for item in pair), code)
    return int(pair[0]), int(pair[1])


class Padding2D:
    def __init__(self, spec: int | Sequence[int]) -> None:
        if isinstance(spec, int):
            padding = (spec, spec, spec, spec)
        else:
            padding = tuple(spec)
        _require(len(padding) == 4 and all(isinstance(item, int) and 0 <= item <= 16
                                           for item in padding),
                 "NEBO-G020-PADDING")
        self.spec = padding

    @staticmethod
    def new(spec: int | Sequence[int]) -> "Padding2D":
        return Padding2D(spec)

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        _require(len(source.shape) == 4, "NEBO-G020-CONV-RANK")
        batch, channels, height, width = source.shape
        top, bottom, left, right = self.spec
        out_h, out_w = height + top + bottom, width + left + right
        _require(batch * channels * out_h * out_w <= MAX_ELEMENTS,
                 "NEBO-G020-ELEMENT-BUDGET")
        result = [0.0] * (batch * channels * out_h * out_w)
        for n in range(batch):
            for channel in range(channels):
                for y in range(height):
                    for x in range(width):
                        src = ((n * channels + channel) * height + y) * width + x
                        dst = ((n * channels + channel) * out_h + y + top) * out_w + x + left
                        result[dst] = float(source.values[src])
        return Tensor(result, (batch, channels, out_h, out_w))


class Conv2D:
    def __init__(self, channels_in: int, channels_out: int,
                 kernel_shape: int | Sequence[int], options: Mapping[str, Any]) -> None:
        _require(isinstance(channels_in, int) and 1 <= channels_in <= MAX_DIMENSION,
                 "NEBO-G020-CONV-CHANNELS")
        _require(isinstance(channels_out, int) and 1 <= channels_out <= MAX_DIMENSION,
                 "NEBO-G020-CONV-CHANNELS")
        self.channels_in = channels_in
        self.channels_out = channels_out
        self.kernel_shape = _pair(kernel_shape, "NEBO-G020-CONV-KERNEL")
        self.stride = _pair(options.get("stride", 1), "NEBO-G020-CONV-STRIDE")
        self.padding = Padding2D(options.get("padding", 0))
        _require(set(options).issubset({"stride", "padding", "bias"}),
                 "NEBO-G020-CONV-OPTION")
        elements = channels_in * channels_out * math.prod(self.kernel_shape)
        _require(elements <= MAX_ELEMENTS, "NEBO-G020-ELEMENT-BUDGET")
        self.weight = Tensor([0.0] * elements,
                             (channels_out, channels_in, *self.kernel_shape))
        use_bias = options.get("bias", True)
        _require(isinstance(use_bias, bool), "NEBO-G020-CONV-BIAS")
        self.bias = Tensor([0.0] * channels_out, (channels_out,)) if use_bias else None

    @staticmethod
    def new(channelsIn: int, channelsOut: int, kernel: int | Sequence[int],
            options: Mapping[str, Any] | None = None) -> "Conv2D":
        return Conv2D(channelsIn, channelsOut, kernel, dict(options or {}))

    def forward(self, input: Tensor) -> Tensor:
        source = self.padding.forward(_float_tensor(input))
        batch, channels, height, width = source.shape
        _require(channels == self.channels_in, "NEBO-G020-CONV-CHANNELS")
        kh, kw = self.kernel_shape
        sh, sw = self.stride
        _require(height >= kh and width >= kw, "NEBO-G020-CONV-SHAPE")
        out_h = (height - kh) // sh + 1
        out_w = (width - kw) // sw + 1
        _require(batch * self.channels_out * out_h * out_w <= MAX_ELEMENTS,
                 "NEBO-G020-ELEMENT-BUDGET")
        weights = _float_tensor(self.weight)
        bias = _float_tensor(self.bias) if self.bias is not None else None
        result: list[float] = []
        for n in range(batch):
            for out_channel in range(self.channels_out):
                for out_y in range(out_h):
                    for out_x in range(out_w):
                        total = float(bias.values[out_channel]) if bias is not None else 0.0
                        for in_channel in range(self.channels_in):
                            for ky in range(kh):
                                for kx in range(kw):
                                    src = (((n * channels + in_channel) * height + out_y * sh + ky)
                                           * width + out_x * sw + kx)
                                    weight = (((out_channel * channels + in_channel) * kh + ky)
                                              * kw + kx)
                                    total += float(source.values[src]) * float(weights.values[weight])
                        result.append(total)
        return Tensor(result, (batch, self.channels_out, out_h, out_w))


class _Pool2D:
    def __init__(self, kernel_shape: int | Sequence[int], stride: int | Sequence[int],
                 mode: str) -> None:
        self.kernel_shape = _pair(kernel_shape, "NEBO-G020-POOL-KERNEL")
        self.stride = _pair(stride, "NEBO-G020-POOL-STRIDE")
        self.mode = mode

    def forward(self, input: Tensor) -> Tensor:
        source = _float_tensor(input)
        _require(len(source.shape) == 4, "NEBO-G020-CONV-RANK")
        batch, channels, height, width = source.shape
        kh, kw = self.kernel_shape
        sh, sw = self.stride
        _require(height >= kh and width >= kw, "NEBO-G020-POOL-SHAPE")
        out_h = (height - kh) // sh + 1
        out_w = (width - kw) // sw + 1
        result: list[float] = []
        for n in range(batch):
            for channel in range(channels):
                for out_y in range(out_h):
                    for out_x in range(out_w):
                        window = []
                        for ky in range(kh):
                            for kx in range(kw):
                                index = (((n * channels + channel) * height + out_y * sh + ky)
                                         * width + out_x * sw + kx)
                                window.append(float(source.values[index]))
                        result.append(max(window) if self.mode == "max" else sum(window) / len(window))
        return Tensor(result, (batch, channels, out_h, out_w))


class MaxPool2D(_Pool2D):
    @staticmethod
    def new(kernel: int | Sequence[int], stride: int | Sequence[int]) -> "MaxPool2D":
        return MaxPool2D(kernel, stride, "max")


class AvgPool2D(_Pool2D):
    @staticmethod
    def new(kernel: int | Sequence[int], stride: int | Sequence[int]) -> "AvgPool2D":
        return AvgPool2D(kernel, stride, "avg")


class GlobalAveragePool2D:
    @staticmethod
    def forward(input: Tensor) -> Tensor:
        source = _float_tensor(input)
        _require(len(source.shape) == 4, "NEBO-G020-CONV-RANK")
        batch, channels, height, width = source.shape
        area = height * width
        result = []
        for n in range(batch):
            for channel in range(channels):
                start = (n * channels + channel) * area
                result.append(sum(float(value) for value in source.values[start:start + area]) / area)
        return Tensor(result, (batch, channels, 1, 1))


def _named_layer_tensors(layers: Sequence[Any], prefix: str = "") -> Iterator[tuple[str, Tensor]]:
    for index, layer in enumerate(layers):
        name = f"{prefix}{index}"
        for attribute in ("weight", "bias"):
            value = getattr(layer, attribute, None)
            if isinstance(value, Tensor):
                yield f"{name}.{attribute}", value
        if isinstance(layer, BatchNorm):
            yield f"{name}.running_mean", layer.running_mean
            yield f"{name}.running_variance", layer.running_variance
        nested = layer.layers if isinstance(layer, Sequential) else None
        if nested is not None:
            yield from _named_layer_tensors(nested, f"{name}.")
        if isinstance(layer, Residual):
            block = layer.block
            for attribute in ("weight", "bias"):
                value = getattr(block, attribute, None)
                if isinstance(value, Tensor):
                    yield f"{name}.block.{attribute}", value
            if isinstance(block, Sequential):
                yield from _named_layer_tensors(block.layers, f"{name}.block.")


def _apply_named_tensor(layers: Sequence[Any], name: str, value: Tensor) -> bool:
    parts = name.split(".")
    current: Any = layers
    index = 0
    try:
        while index < len(parts):
            if isinstance(current, (tuple, list)):
                current = current[int(parts[index])]
                index += 1
            elif isinstance(current, Sequential):
                current = current.layers[int(parts[index])]
                index += 1
            elif isinstance(current, Residual) and parts[index] == "block":
                current = current.block
                index += 1
            else:
                setattr(current, ".".join(parts[index:]), value)
                return True
    except (IndexError, ValueError, AttributeError):
        return False
    return False


@dataclass(frozen=True)
class ModelSummary:
    layers: tuple[str, ...]
    parameters: int
    parameter_bytes: int
    buffers: int
    mode: str


class Model:
    def __init__(self, graph: Sequence[Any], parameters: Mapping[str, Tensor]) -> None:
        _require(1 <= len(graph) <= MAX_LAYERS, "NEBO-G020-LAYER-BUDGET")
        _require(all(callable(getattr(layer, "forward", None)) for layer in graph),
                 "NEBO-G020-LAYER")
        self.graph = tuple(graph)
        auto = dict(_named_layer_tensors(self.graph))
        supplied = dict(parameters)
        _require(all(isinstance(name, str) and name and isinstance(value, Tensor)
                     for name, value in supplied.items()), "NEBO-G020-PARAMETER")
        auto.update(supplied)
        _require(len(auto) <= 128, "NEBO-G020-PARAMETER-BUDGET")
        self._parameters = auto
        self._buffers = {name: value for name, value in auto.items()
                         if name.endswith(("running_mean", "running_variance"))}
        self._eval_mode = False
        self._integrity = self._state_digest()
        self.validate()

    @staticmethod
    def new(graph: Sequence[Any], parameters: Mapping[str, Tensor]) -> "Model":
        return Model(graph, parameters)

    def parameters(self) -> Iterator[tuple[str, Tensor]]:
        for item in sorted(self._parameters.items()):
            if item[0] not in self._buffers:
                yield item

    def buffers(self) -> Iterator[tuple[str, Tensor]]:
        yield from sorted(self._buffers.items())

    def eval(self) -> "Model":
        self._eval_mode = True
        return self

    def summary(self) -> ModelSummary:
        count = self.parameterCount()
        return ModelSummary(tuple(type(layer).__name__ for layer in self.graph),
                            count["elements"], count["bytes"],
                            sum(tensor.elements for tensor in self._buffers.values()),
                            "eval" if self._eval_mode else "inference-pending")

    def parameterCount(self) -> dict[str, int]:
        tensors = [value for name, value in self._parameters.items() if name not in self._buffers]
        return {"elements": sum(tensor.elements for tensor in tensors),
                "bytes": sum(tensor.nbytes for tensor in tensors)}

    def validate(self) -> dict[str, Any]:
        _require(len(self.graph) <= MAX_LAYERS, "NEBO-G020-LAYER-BUDGET")
        total = sum(tensor.elements for tensor in self._parameters.values())
        _require(total <= MAX_ELEMENTS, "NEBO-G020-PARAMETER-ELEMENT-BUDGET")
        _require(len(self._parameters) == len(set(self._parameters)),
                 "NEBO-G020-PARAMETER-DUPLICATE")
        return {"valid": True, "layers": len(self.graph), "parameters": len(self._parameters)}

    def forward(self, input: Tensor) -> Tensor:
        _require(self._eval_mode, "NEBO-G020-EVAL-REQUIRED")
        value = input
        for layer in self.graph:
            value = layer.forward(value)
            _require(isinstance(value, Tensor), "NEBO-G020-LAYER-OUTPUT")
        return value

    def _state_digest(self) -> str:
        state = {
            "graph": [_layer_to_dict(layer) for layer in self.graph],
            "parameters": {name: _tensor_to_dict(value)
                           for name, value in sorted(self._parameters.items())},
        }
        return hashlib.sha256(_canonical(state)).hexdigest()

    def loadState(self, dictionary: Mapping[str, Tensor], strict: bool) -> dict[str, Any]:
        _require(isinstance(strict, bool), "NEBO-G020-STRICT")
        staged = dict(dictionary)
        _require(all(isinstance(name, str) and isinstance(value, Tensor)
                     for name, value in staged.items()), "NEBO-G020-STATE")
        expected, provided = set(self._parameters), set(staged)
        missing, extra = sorted(expected - provided), sorted(provided - expected)
        if strict:
            _require(not missing, "NEBO-G020-STATE-MISSING")
            _require(not extra, "NEBO-G020-STATE-EXTRA")
        for name in expected & provided:
            _require(self._parameters[name].shape == staged[name].shape,
                     "NEBO-G020-STATE-SHAPE")
            _require(self._parameters[name].dtype == staged[name].dtype,
                     "NEBO-G020-STATE-DTYPE")
        updated = dict(self._parameters)
        updated.update({name: staged[name] for name in expected & provided})
        self._parameters = updated
        self._buffers = {name: value for name, value in updated.items()
                         if name.endswith(("running_mean", "running_variance"))}
        for name, value in updated.items():
            _apply_named_tensor(self.graph, name, value)
        self._integrity = self._state_digest()
        return {"missing": missing, "extra": extra, "loaded": len(expected & provided)}

    def exportManifest(self) -> dict[str, Any]:
        return {
            "format": NMF_MAGIC,
            "version": NMF_VERSION,
            "mode": "eval" if self._eval_mode else "inference-pending",
            "layers": [type(layer).__name__ for layer in self.graph],
            "tensors": {name: {"shape": list(tensor.shape), "dtype": tensor.dtype,
                                "sha256": tensor.digest()}
                        for name, tensor in sorted(self._parameters.items())},
            "requirements": ["cpu", "scalar-f64"],
        }

    def verifyIntegrity(self) -> bool:
        self.validate()
        return self._integrity == self._state_digest()

    def _payload(self) -> dict[str, Any]:
        return {
            "eval": self._eval_mode,
            "graph": [_layer_to_dict(layer) for layer in self.graph],
            "parameters": {name: _tensor_to_dict(value)
                           for name, value in sorted(self._parameters.items())},
        }

    def save(self, path: str | os.PathLike[str], options: Mapping[str, Any] | None = None) -> int:
        options_value = dict(options or {})
        _require(set(options_value).issubset({"overwrite"}), "NEBO-G020-SAVE-OPTION")
        target = Path(path)
        _require(not target.is_symlink(), "NEBO-G020-PATH-SYMLINK")
        _require(target.parent.is_dir() and not target.parent.is_symlink(), "NEBO-G020-PATH")
        _require(options_value.get("overwrite", False) or not target.exists(),
                 "NEBO-G020-PATH-EXISTS")
        payload = self._payload()
        payload_bytes = _canonical(payload)
        document = {"magic": NMF_MAGIC, "version": NMF_VERSION, "payload": payload,
                    "checksum": hashlib.sha256(payload_bytes).hexdigest()}
        encoded = _canonical(document)
        _require(len(encoded) <= MAX_MODEL_BYTES, "NEBO-G020-MODEL-BYTE-BUDGET")
        temporary = target.with_name(target.name + ".tmp-g020")
        _require(not temporary.exists(), "NEBO-G020-TEMP-EXISTS")
        try:
            temporary.write_bytes(encoded)
            os.replace(temporary, target)
        except OSError as error:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass
            raise MlError("NEBO-G020-MODEL-IO") from error
        return len(encoded)

    @staticmethod
    def load(path: str | os.PathLike[str], options: Mapping[str, Any] | None = None) -> "Model":
        options_value = dict(options or {})
        _require(set(options_value).issubset({"maxBytes"}), "NEBO-G020-LOAD-OPTION")
        maximum = int(options_value.get("maxBytes", MAX_MODEL_BYTES))
        _require(1 <= maximum <= MAX_MODEL_BYTES, "NEBO-G020-MODEL-BYTE-BUDGET")
        data = _safe_read(Path(path), maximum)
        inspected = ModelFormat.inspect(data)
        model = _model_from_payload(inspected["payload"])
        model._integrity = model._state_digest()
        return model

    def compareAccuracy(self, reference: "Model", dataset: Sequence[Tensor]) -> dict[str, float | int]:
        _require(isinstance(reference, Model), "NEBO-G020-REFERENCE-MODEL")
        _require(1 <= len(dataset) <= 64, "NEBO-G020-DATASET-BUDGET")
        candidate_session = InferenceSession.new(self.eval(), {})
        reference_session = InferenceSession.new(reference.eval(), {})
        differences: list[float] = []
        for sample in dataset:
            candidate = candidate_session.run(sample)
            expected = reference_session.run(sample)
            _require(candidate.shape == expected.shape, "NEBO-G020-ACCURACY-SHAPE")
            differences.extend(abs(float(left) - float(right))
                               for left, right in zip(candidate.values, expected.values))
        return {"samples": len(dataset), "elements": len(differences),
                "maxAbsoluteError": max(differences, default=0.0),
                "meanAbsoluteError": statistics.fmean(differences) if differences else 0.0,
                "mse": statistics.fmean(value * value for value in differences)
                       if differences else 0.0}


def _safe_read(path: Path, maximum: int) -> bytes:
    _require(path.is_file() and not path.is_symlink(), "NEBO-G020-MODEL-PATH")
    try:
        size = path.stat().st_size
        _require(0 < size <= maximum, "NEBO-G020-MODEL-BYTE-BUDGET")
        return path.read_bytes()
    except OSError as error:
        raise MlError("NEBO-G020-MODEL-IO") from error


class ModelFormat:
    @staticmethod
    def inspect(bytes: bytes | bytearray) -> dict[str, Any]:
        _require(isinstance(bytes, (builtins_bytes, bytearray)), "NEBO-G020-MODEL-BYTES")
        raw = builtins_bytes(bytes)
        _require(0 < len(raw) <= MAX_MODEL_BYTES, "NEBO-G020-MODEL-BYTE-BUDGET")
        try:
            document = json.loads(raw.decode("ascii"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise MlError("NEBO-G020-MODEL-MALFORMED") from error
        _require(isinstance(document, dict), "NEBO-G020-MODEL-MALFORMED")
        _require(document.get("magic") == NMF_MAGIC, "NEBO-G020-MODEL-MAGIC")
        _require(document.get("version") == NMF_VERSION, "NEBO-G020-MODEL-VERSION")
        _require(isinstance(document.get("payload"), dict), "NEBO-G020-MODEL-PAYLOAD")
        expected = hashlib.sha256(_canonical(document["payload"])).hexdigest()
        _require(document.get("checksum") == expected, "NEBO-G020-MODEL-CHECKSUM")
        return {"magic": NMF_MAGIC, "version": NMF_VERSION, "bytes": len(raw),
                "checksum": expected, "payload": document["payload"]}


builtins_bytes = bytes


class Weights:
    @staticmethod
    def load(path: str | os.PathLike[str], mapping: Mapping[str, str]) -> dict[str, Tensor]:
        _require(isinstance(mapping, Mapping), "NEBO-G020-WEIGHTS-MAPPING")
        inspected = ModelFormat.inspect(_safe_read(Path(path), MAX_MODEL_BYTES))
        parameters = inspected["payload"].get("parameters")
        _require(isinstance(parameters, dict), "NEBO-G020-MODEL-PAYLOAD")
        result: dict[str, Tensor] = {}
        for source, destination in mapping.items():
            _require(isinstance(source, str) and isinstance(destination, str)
                     and source in parameters and destination not in result,
                     "NEBO-G020-WEIGHTS-MAPPING")
            result[destination] = _tensor_from_dict(parameters[source])
        return result


def _layer_to_dict(layer: Any) -> dict[str, Any]:
    if isinstance(layer, Linear):
        return {"type": "Linear", "input": layer.input_size, "output": layer.output_size,
                "bias": layer.bias is not None, "weight": _tensor_to_dict(layer.weight),
                "biasTensor": _tensor_to_dict(layer.bias) if layer.bias is not None else None}
    if isinstance(layer, LayerNorm):
        return {"type": "LayerNorm", "shape": list(layer.normalized_shape),
                "epsilon": layer.epsilon}
    if isinstance(layer, BatchNorm):
        return {"type": "BatchNorm", "features": layer.features, "epsilon": layer.epsilon,
                "runningMean": _tensor_to_dict(layer.running_mean),
                "runningVariance": _tensor_to_dict(layer.running_variance),
                "weight": _tensor_to_dict(layer.weight), "bias": _tensor_to_dict(layer.bias)}
    if isinstance(layer, Dropout):
        return {"type": "Dropout", "probability": layer.probability}
    if isinstance(layer, Flatten):
        return {"type": "Flatten", "start": layer.start_axis, "end": layer.end_axis}
    if isinstance(layer, Embedding):
        return {"type": "Embedding", "count": layer.count, "dimension": layer.dimension,
                "weight": _tensor_to_dict(layer.weight)}
    if isinstance(layer, Conv2D):
        return {"type": "Conv2D", "channelsIn": layer.channels_in,
                "channelsOut": layer.channels_out, "kernel": list(layer.kernel_shape),
                "stride": list(layer.stride), "padding": list(layer.padding.spec),
                "bias": layer.bias is not None, "weight": _tensor_to_dict(layer.weight),
                "biasTensor": _tensor_to_dict(layer.bias) if layer.bias is not None else None}
    if isinstance(layer, MaxPool2D):
        return {"type": "MaxPool2D", "kernel": list(layer.kernel_shape),
                "stride": list(layer.stride)}
    if isinstance(layer, AvgPool2D):
        return {"type": "AvgPool2D", "kernel": list(layer.kernel_shape),
                "stride": list(layer.stride)}
    if isinstance(layer, Padding2D):
        return {"type": "Padding2D", "padding": list(layer.spec)}
    if isinstance(layer, Sequential):
        return {"type": "Sequential", "layers": [_layer_to_dict(item) for item in layer.layers]}
    if isinstance(layer, Residual):
        return {"type": "Residual", "block": _layer_to_dict(layer.block)}
    raise MlError("NEBO-G020-LAYER-SERIALIZATION")


def _layer_from_dict(data: Mapping[str, Any]) -> Any:
    kind = data.get("type")
    if kind == "Linear":
        layer = Linear.new(int(data["input"]), int(data["output"]), bool(data["bias"]))
        layer.weight = _tensor_from_dict(data["weight"])
        layer.bias = _tensor_from_dict(data["biasTensor"]) if data["biasTensor"] else None
        return layer
    if kind == "LayerNorm":
        return LayerNorm.new(data["shape"], float(data["epsilon"]))
    if kind == "BatchNorm":
        layer = BatchNorm.new(int(data["features"]), float(data["epsilon"]))
        layer.running_mean = _tensor_from_dict(data["runningMean"])
        layer.running_variance = _tensor_from_dict(data["runningVariance"])
        layer.weight = _tensor_from_dict(data["weight"])
        layer.bias = _tensor_from_dict(data["bias"])
        return layer
    if kind == "Dropout":
        return Dropout.new(float(data["probability"]))
    if kind == "Flatten":
        return Flatten.new(int(data["start"]), int(data["end"]))
    if kind == "Embedding":
        layer = Embedding.new(int(data["count"]), int(data["dimension"]))
        layer.weight = _tensor_from_dict(data["weight"])
        return layer
    if kind == "Conv2D":
        layer = Conv2D.new(int(data["channelsIn"]), int(data["channelsOut"]), data["kernel"],
                           {"stride": data["stride"], "padding": data["padding"],
                            "bias": bool(data["bias"])})
        layer.weight = _tensor_from_dict(data["weight"])
        layer.bias = _tensor_from_dict(data["biasTensor"]) if data["biasTensor"] else None
        return layer
    if kind == "MaxPool2D":
        return MaxPool2D.new(data["kernel"], data["stride"])
    if kind == "AvgPool2D":
        return AvgPool2D.new(data["kernel"], data["stride"])
    if kind == "Padding2D":
        return Padding2D.new(data["padding"])
    if kind == "Sequential":
        return Sequential.new([_layer_from_dict(item) for item in data["layers"]])
    if kind == "Residual":
        return Residual.new(_layer_from_dict(data["block"]))
    raise MlError("NEBO-G020-LAYER-SERIALIZATION")


def _model_from_payload(payload: Mapping[str, Any]) -> Model:
    _require(isinstance(payload.get("graph"), list) and
             isinstance(payload.get("parameters"), dict), "NEBO-G020-MODEL-PAYLOAD")
    graph = [_layer_from_dict(item) for item in payload["graph"]]
    parameters = {name: _tensor_from_dict(value)
                  for name, value in payload["parameters"].items()}
    model = Model.new(graph, parameters)
    if payload.get("eval"):
        model.eval()
    return model


@dataclass(frozen=True)
class MemoryPlan:
    input_bytes: int
    output_bytes: int
    workspace_bytes: int
    peak_bytes: int
    operations: int


class InferenceSession:
    def __init__(self, model: Model, options: Mapping[str, Any]) -> None:
        _require(isinstance(model, Model), "NEBO-G020-MODEL")
        _require(set(options).issubset({"device", "maxBatch", "maxWorkspaceBytes",
                                       "deterministic", "profile"}),
                 "NEBO-G020-SESSION-OPTION")
        _require(options.get("device", "cpu") == "cpu", "NEBO-G020-DEVICE")
        self.model = model.eval()
        self.max_batch = int(options.get("maxBatch", MAX_BATCH))
        self.max_workspace = int(options.get("maxWorkspaceBytes", MAX_WORKSPACE_BYTES))
        _require(1 <= self.max_batch <= MAX_BATCH, "NEBO-G020-BATCH-BUDGET")
        _require(0 <= self.max_workspace <= MAX_WORKSPACE_BYTES,
                 "NEBO-G020-WORKSPACE-BUDGET")
        self.deterministic = bool(options.get("deterministic", True))
        self.profile_enabled = bool(options.get("profile", True))
        self._runs = 0
        self._warmups = 0
        self._last_profile: dict[str, Any] = {"runs": 0, "warmups": 0,
                                              "operations": (), "elapsedNs": 0}

    @staticmethod
    def new(model: Model, options: Mapping[str, Any] | None = None) -> "InferenceSession":
        return InferenceSession(model, dict(options or {}))

    def _execute(self, value: Tensor) -> tuple[Tensor, int]:
        started = time.perf_counter_ns()
        result = self.model.forward(value)
        elapsed = time.perf_counter_ns() - started
        return result, elapsed

    def _record(self, value: Tensor, result: Tensor, elapsed: int) -> None:
        self._runs += 1
        self._last_profile = {"runs": self._runs, "warmups": self._warmups,
                              "operations": tuple(type(layer).__name__
                                                  for layer in self.model.graph),
                              "elapsedNs": elapsed if self.profile_enabled else 0,
                              "inputElements": value.elements,
                              "outputElements": result.elements}

    def run(self, inputs: Tensor | Mapping[str, Tensor]) -> Tensor:
        value = _single_input(inputs)
        result, elapsed = self._execute(value)
        self._record(value, result, elapsed)
        return result

    def runInto(self, inputs: Tensor | Mapping[str, Tensor],
                outputs: MutableMapping[str, Tensor]) -> MutableMapping[str, Tensor]:
        _require(isinstance(outputs, MutableMapping), "NEBO-G020-OUTPUT-BUFFER")
        value = _single_input(inputs)
        result, elapsed = self._execute(value)
        existing = outputs.get("output")
        if existing is not None:
            _require(isinstance(existing, Tensor) and existing.shape == result.shape
                     and existing.dtype == result.dtype, "NEBO-G020-OUTPUT-SHAPE")
        self._record(value, result, elapsed)
        outputs["output"] = result
        return outputs

    def warmup(self, inputs: Tensor | Mapping[str, Tensor]) -> dict[str, Any]:
        value = _single_input(inputs)
        _require(self._warmups < MAX_WARMUP, "NEBO-G020-WARMUP-BUDGET")
        before = self._runs
        result = self.model.forward(value)
        self._warmups += 1
        _require(self._runs == before, "NEBO-G020-WARMUP-PROFILE")
        return {"warmups": self._warmups, "digest": result.digest()}

    def batch(self, inputs: Sequence[Tensor]) -> tuple[Tensor, ...]:
        _require(1 <= len(inputs) <= self.max_batch, "NEBO-G020-BATCH-BUDGET")
        _require(all(isinstance(item, Tensor) and item.shape == inputs[0].shape
                     and item.dtype == inputs[0].dtype for item in inputs),
                 "NEBO-G020-BATCH-SHAPE")
        return tuple(self.run(item) for item in inputs)

    def memoryPlan(self) -> MemoryPlan:
        parameter_bytes = self.model.parameterCount()["bytes"]
        workspace = min(self.max_workspace, max(64, parameter_bytes))
        return MemoryPlan(MAX_ELEMENTS * 8, MAX_ELEMENTS * 8, workspace,
                          MAX_ELEMENTS * 16 + workspace, len(self.model.graph))

    def profile(self) -> dict[str, Any]:
        return copy.deepcopy(self._last_profile)


def _single_input(inputs: Tensor | Mapping[str, Tensor]) -> Tensor:
    if isinstance(inputs, Tensor):
        return inputs
    _require(isinstance(inputs, Mapping) and set(inputs) == {"input"}
             and isinstance(inputs["input"], Tensor), "NEBO-G020-INPUTS")
    return inputs["input"]


class QuantizedModel(Model):
    def __init__(self, model: Model, quantized_parameters: Mapping[str, Tensor]) -> None:
        self.reference_model = model
        graph = copy.deepcopy(model.graph)
        approximated = {name: value.dequantize() for name, value in quantized_parameters.items()}
        for name, value in approximated.items():
            _apply_named_tensor(graph, name, value)
        super().__init__(graph, approximated)
        self.quantized_parameters = dict(quantized_parameters)
        self.eval()

    def requireCpuFeatures(self) -> tuple[str, ...]:
        return ("cpu", "scalar-int8", "f64-fallback")


class Quantizer:
    def __init__(self, options: Mapping[str, Any]) -> None:
        _require(set(options).issubset({"symmetric", "fallback", "percentile"}),
                 "NEBO-G020-QUANTIZATION-OPTION")
        _require(options.get("symmetric", True) is True,
                 "NEBO-G020-QUANTIZATION-PROFILE")
        _require(options.get("fallback", "f64") == "f64",
                 "NEBO-G020-QUANTIZATION-FALLBACK")
        percentile = float(options.get("percentile", 100.0))
        _require(math.isfinite(percentile) and 90.0 <= percentile <= 100.0,
                 "NEBO-G020-QUANTIZATION-PERCENTILE")
        self.options = {"symmetric": True, "fallback": "f64", "percentile": percentile}
        self._range: tuple[float, float] | None = None

    def calibrate(self, dataset: Sequence[Tensor]) -> dict[str, float | int]:
        _require(1 <= len(dataset) <= 64, "NEBO-G020-DATASET-BUDGET")
        values: list[float] = []
        for tensor in dataset:
            _require(isinstance(tensor, Tensor), "NEBO-G020-DATASET")
            values.extend(float(value) for value in _float_tensor(tensor).values)
        _require(values, "NEBO-G020-DATASET")
        self._range = (min(values), max(values))
        return {"samples": len(dataset), "elements": len(values),
                "minimum": self._range[0], "maximum": self._range[1]}

    def quantize(self, model: Model) -> QuantizedModel:
        _require(isinstance(model, Model), "NEBO-G020-MODEL")
        _require(self._range is not None, "NEBO-G020-CALIBRATION-REQUIRED")
        quantized: dict[str, Tensor] = {}
        for name, tensor in model._parameters.items():
            source = _float_tensor(tensor)
            maximum = max((abs(float(value)) for value in source.values), default=0.0)
            scale = maximum / 127.0 if maximum > 0.0 else 1.0
            quantized[name] = source.quantize(scale, 0)
        return QuantizedModel(model, quantized)


class Quantization:
    @staticmethod
    def int8(options: Mapping[str, Any] | None = None) -> Quantizer:
        return Quantizer(dict(options or {}))
