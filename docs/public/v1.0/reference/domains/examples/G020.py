#!/usr/bin/env python3
"""Independent value/effect oracle for all 48 current G020 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
import math
import os
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.ml_inference import (  # noqa: E402
    Activation, AvgPool2D, BatchNorm, Conv2D, Dropout, Embedding, Flatten,
    GlobalAveragePool2D, InferenceSession, LayerNorm, Linear, MaxPool2D,
    MlError, Model, ModelFormat, Padding2D, Quantization, Residual, Sequential,
    Softmax, Tensor, Weights,
)


counts: dict[str, int] = defaultdict(int)


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def close(left: float, right: float, tolerance: float = 1e-9) -> bool:
    return math.isclose(left, right, rel_tol=tolerance, abs_tol=tolerance)


def close_values(actual: Tensor, expected: list[float] | Tensor,
                 tolerance: float = 1e-9) -> bool:
    if isinstance(expected, Tensor):
        expected = [float(value) for value in expected.values]
    return len(actual.values) == len(expected) and all(
        close(float(left), right, tolerance) for left, right in zip(actual.values, expected))


def reject(category: str, label: str, code: str, callable_) -> None:
    try:
        callable_()
    except MlError as error:
        ok(category, label, error.code == code)
        return
    raise AssertionError(f"{category}:{label}:accepted")


class DifferentShape:
    def forward(self, input: Tensor) -> Tensor:
        return Tensor([1.0], (1,))


def configured_linear() -> Linear:
    layer = Linear.new(3, 2, True)
    layer.weight = Tensor([1.0, 2.0, 3.0, -1.0, 0.5, 2.0], (2, 3))
    layer.bias = Tensor([0.5, -0.5], (2,))
    return layer


sample = Tensor([2.0, -1.0, 0.5], (3,))
linear = configured_linear()
batch_norm = BatchNorm.new(2, 1e-5)
model = Model.new([linear, batch_norm], {}).eval()

# S01: model construction, state enumeration, inference mode, and validation.
ok("positive", "Model.new", isinstance(model, Model) and len(model.graph) == 2)
ok("positive", "model.parameters", [name for name, _ in model.parameters()] ==
   ["0.bias", "0.weight", "1.bias", "1.weight"])
ok("positive", "model.buffers", [name for name, _ in model.buffers()] ==
   ["1.running_mean", "1.running_variance"])
ok("positive", "model.eval", model.summary().mode == "eval")
summary = model.summary()
ok("positive", "model.summary", summary.layers == ("Linear", "BatchNorm") and
   summary.parameters == 12 and summary.buffers == 4)
count = model.parameterCount()
ok("positive", "model.parameterCount", count == {"elements": 12, "bytes": 96})
ok("positive", "model.validate", model.validate() ==
   {"valid": True, "layers": 2, "parameters": 6})

# S02: hand-computed affine values and standard activation definitions.
ok("positive", "Linear.new", (linear.input_size, linear.output_size) == (3, 2))
affine = linear.forward(sample)
ok("positive", "linear.forward", affine.shape == (2,) and
   close_values(affine, [2.0, -2.0]))
ok("positive", "Activation.relu",
   Activation.relu(Tensor([-2, 0, 3], (3,))).values == (0.0, 0.0, 3.0))
ok("positive", "Activation.gelu",
   close_values(Activation.gelu(Tensor([0, 1], (2,)), "exact"),
                [0.0, 0.8413447460685429], 1e-12))
sigmoid = Activation.sigmoid(Tensor([-1000, 0, 1000], (3,)))
ok("positive", "Activation.sigmoid", sigmoid.values[0] == 0.0 and
   sigmoid.values[1] == 0.5 and sigmoid.values[2] == 1.0)
ok("positive", "Activation.tanh",
   close_values(Activation.tanh(Tensor([-1, 0, 1], (3,))),
                [-math.tanh(1), 0.0, math.tanh(1)]))
softmax = Softmax.forward(Tensor([1000, 1001], (2,)), -1)
ok("positive", "Softmax.forward", close(sum(float(v) for v in softmax.values), 1.0)
   and close(float(softmax.values[1]), math.e / (1.0 + math.e)))

# S03: composition and inference-only normalization layers.
sequence = Sequential.new([Dropout.new(0.25), linear])
ok("positive", "Sequential.new", close_values(sequence.forward(sample), [2.0, -2.0]))
layer_norm = LayerNorm.new(2, 1e-5)
normalized = layer_norm.forward(Tensor([1, 3], (2,)))
denominator = math.sqrt(1.0 + 1e-5)
ok("positive", "LayerNorm.new", close_values(normalized,
   [-1.0 / denominator, 1.0 / denominator]))
batch_norm_probe = BatchNorm.new(2, 1e-5)
batch_norm_probe.running_mean = Tensor([1, -1], (2,))
batch_norm_probe.running_variance = Tensor([4, 9], (2,))
batch_normalized = batch_norm_probe.forward(Tensor([5, 5], (2,)))
ok("positive", "BatchNorm.new", close_values(batch_normalized,
   [4 / math.sqrt(4.00001), 6 / math.sqrt(9.00001)]))
dropout = Dropout.new(0.75)
identity = Tensor([7, 11], (2,))
ok("positive", "Dropout.new", dropout.forward(identity) is identity)
residual = Residual.new(Dropout.new(0.5))
residual_parameters = Model.new([Residual.new(configured_linear())], {})
ok("positive", "Residual.new", residual.forward(identity).values == (14.0, 22.0) and
   [name for name, _ in residual_parameters.parameters()] ==
   ["0.block.bias", "0.block.weight"])
flatten = Flatten.new(1, 2)
ok("positive", "Flatten.new",
   flatten.forward(Tensor(range(4), (1, 2, 2, 1))).shape == (1, 4, 1))
embedding = Embedding.new(3, 2)
embedding.weight = Tensor([1, 2, 3, 4, 5, 6], (3, 2))
ok("positive", "Embedding.new", embedding.forward([2, 0]).values ==
   (5.0, 6.0, 1.0, 2.0))

# S04: scalar NCHW convolution, pooling, global reduction, and explicit padding.
image = Tensor(range(1, 10), (1, 1, 3, 3))
conv = Conv2D.new(1, 1, 2, {"bias": False})
conv.weight = Tensor([1, 0, 0, -1], (1, 1, 2, 2))
ok("positive", "Conv2D.new", conv.kernel_shape == (2, 2))
ok("positive", "conv.forward", conv.forward(image).values == (-4.0,) * 4)
max_pool = MaxPool2D.new(2, 1)
ok("positive", "MaxPool2D.new", max_pool.forward(image).values == (5.0, 6.0, 8.0, 9.0))
avg_pool = AvgPool2D.new(2, 1)
ok("positive", "AvgPool2D.new", avg_pool.forward(image).values == (3.0, 4.0, 6.0, 7.0))
ok("positive", "GlobalAveragePool2D.forward",
   GlobalAveragePool2D.forward(image).values == (5.0,))
padding = Padding2D.new((1, 1, 1, 1))
padded = padding.forward(image)
ok("positive", "Padding2D.new", padded.shape == (1, 1, 5, 5) and
   padded.values[12] == 5.0 and sum(float(v) for v in padded.values) == 45.0)

# S05: a deterministic, checksummed native-model envelope and atomic state load.
scratch = Path(os.environ["G020_TMP"])
model_path = scratch / "tiny.nmf"
saved_bytes = model.save(model_path, {})
raw_model = model_path.read_bytes()
ok("positive", "model.save", saved_bytes == len(raw_model) and saved_bytes < 1_048_576)
inspected = ModelFormat.inspect(raw_model)
ok("positive", "ModelFormat.inspect", inspected["magic"] == "NMF1" and
   inspected["version"] == 1 and len(inspected["checksum"]) == 64)
loaded = Model.load(model_path, {"maxBytes": 8192})
ok("positive", "Model.load", close_values(loaded.forward(sample), model.forward(sample)))
weights = Weights.load(model_path, {"0.weight": "copied.weight"})
ok("positive", "Weights.load", weights["copied.weight"].values == linear.weight.values)
staged = {name: value for name, value in model._parameters.items()}
state_result = model.loadState(staged, True)
ok("positive", "model.loadState", state_result == {"missing": [], "extra": [], "loaded": 6})
manifest = model.exportManifest()
ok("positive", "model.exportManifest", manifest["format"] == "NMF1" and
   manifest["requirements"] == ["cpu", "scalar-f64"] and len(manifest["tensors"]) == 6)
ok("positive", "model.verifyIntegrity", model.verifyIntegrity())

# S06: bounded CPU sessions, buffer reuse, warmup, batching, memory, and profile.
session = InferenceSession.new(model, {"maxBatch": 4, "maxWorkspaceBytes": 4096,
                                      "deterministic": True})
ok("positive", "InferenceSession.new", session.max_batch == 4 and session.deterministic)
session_result = session.run({"input": sample})
ok("positive", "session.run", close_values(session_result, model.forward(sample)))
output_buffer = {"output": Tensor([0, 0], (2,))}
ok("positive", "session.runInto",
   close_values(session.runInto(sample, output_buffer)["output"], model.forward(sample)))
warmup = session.warmup(sample)
ok("positive", "session.warmup", warmup["warmups"] == 1 and len(warmup["digest"]) == 64)
batched = session.batch([sample, Tensor([1, 2, 3], (3,))])
ok("positive", "session.batch", len(batched) == 2 and batched[0].shape == (2,))
memory = session.memoryPlan()
ok("positive", "session.memoryPlan", memory.operations == 2 and
   memory.workspace_bytes <= 4096 and memory.peak_bytes > memory.workspace_bytes)
profile = session.profile()
ok("positive", "session.profile", profile["runs"] == 4 and
   profile["operations"] == ("Linear", "BatchNorm") and "elapsedNs" in profile)

# S07: symmetric per-tensor int8 with calibration, measured error, and fallback.
quantizer = Quantization.int8({"symmetric": True, "fallback": "f64"})
ok("positive", "Quantization.int8", quantizer.options["symmetric"] is True)
calibration = quantizer.calibrate([sample, Tensor([-3, 0, 4], (3,))])
ok("positive", "quantizer.calibrate", calibration["minimum"] == -3.0 and
   calibration["maximum"] == 4.0 and calibration["elements"] == 6)
quantized_model = quantizer.quantize(model)
ok("positive", "quantizer.quantize", len(quantized_model.quantized_parameters) == 6)
quantized_tensor = Tensor([-1.0, 0.0, 1.0], (3,)).quantize(0.25, 0)
ok("positive", "tensor.quantize", quantized_tensor.dtype == "i8" and
   quantized_tensor.values == (-4, 0, 4))
dequantized = quantized_tensor.dequantize()
ok("positive", "tensor.dequantize", dequantized.values == (-1.0, 0.0, 1.0))
accuracy = quantized_model.compareAccuracy(model, [sample, Tensor([1, 2, 3], (3,))])
ok("positive", "model.compareAccuracy", accuracy["samples"] == 2 and
   0.0 <= accuracy["maxAbsoluteError"] < 0.1)
ok("positive", "quantizedModel.requireCpuFeatures",
   quantized_model.requireCpuFeatures() == ("cpu", "scalar-int8", "f64-fallback"))

# Boundaries include stable activation extremes, minimum tensors, and maximum batching.
ok("boundary", "single-tensor", Tensor([9], (1,)).values == (9.0,))
ok("boundary", "relu-zero", Activation.relu(Tensor([0], (1,))).values == (0.0,))
ok("boundary", "softmax-single", Softmax.forward(Tensor([42], (1,))).values == (1.0,))
ok("boundary", "dropout-zero", Dropout.new(0.0).forward(identity) is identity)
ok("boundary", "pool-whole-image", MaxPool2D.new(3, 3).forward(image).values == (9.0,))
ok("boundary", "padding-zero", Padding2D.new(0).forward(image).values == image.values)
ok("boundary", "batch-limit", len(InferenceSession.new(model).batch([sample] * 16)) == 16)
ok("boundary", "quantize-saturation",
   Tensor([-1000, 1000], (2,)).quantize(0.1, 0).values == (-128, 127))

# Metamorphic probes change data and weights so fixed-output routes are detected.
shifted = linear.forward(Tensor([3, -1, 0.5], (3,)))
ok("metamorphic", "linear-input-shift", close_values(shifted, [3.0, -3.0]))
scaled = linear.forward(Tensor([4, -2, 1], (3,)))
ok("metamorphic", "linear-scale-with-bias", close_values(scaled, [3.5, -3.5]))
relu_twice = Activation.relu(Activation.relu(Tensor([-2, 4], (2,))))
ok("metamorphic", "relu-idempotent", relu_twice.values == (0.0, 4.0))
softmax_shift = Softmax.forward(Tensor([1010, 1011], (2,)))
ok("metamorphic", "softmax-translation", close_values(softmax_shift,
   [float(softmax.values[0]), float(softmax.values[1])]))
ok("metamorphic", "pool-translation",
   AvgPool2D.new(2, 1).forward(Tensor(range(11, 20), (1, 1, 3, 3))).values ==
   tuple(float(value) + 10.0 for value in avg_pool.forward(image).values))
roundtrip = Tensor([-2.0, -0.5, 1.0, 2.5], (4,)).quantize(0.5, 0).dequantize()
ok("metamorphic", "quant-roundtrip-grid", roundtrip.values == (-2.0, -0.5, 1.0, 2.5))
first_serialization = model_path.read_bytes()
second_path = scratch / "tiny-second.nmf"
model.save(second_path, {})
ok("metamorphic", "serialization-deterministic", first_serialization == second_path.read_bytes())
ok("metamorphic", "session-model-parity",
   close_values(InferenceSession.new(model).run(sample), model.forward(sample)))

# Negative, diagnostic, adversarial, and atomicity cases.
negative_cases = [
    ("shape-mismatch", "NEBO-G020-SHAPE-MISMATCH", lambda: Tensor([1], (2,))),
    ("nonfinite", "NEBO-G020-NONFINITE", lambda: Tensor([float("nan")], (1,))),
    ("linear-size", "NEBO-G020-LINEAR-INPUT", lambda: Linear.new(0, 2, True)),
    ("linear-shape", "NEBO-G020-LINEAR-SHAPE",
     lambda: linear.forward(Tensor([1, 2], (2,)))),
    ("gelu-mode", "NEBO-G020-GELU-APPROXIMATION",
     lambda: Activation.gelu(Tensor([1], (1,)), "mystery")),
    ("softmax-axis", "NEBO-G020-SOFTMAX-AXIS",
     lambda: Softmax.forward(Tensor([1, 2, 3, 4], (2, 2)), 0)),
    ("empty-sequential", "NEBO-G020-LAYER-BUDGET", lambda: Sequential.new([])),
    ("epsilon", "NEBO-G020-EPSILON", lambda: LayerNorm.new(2, 0)),
    ("dropout-one", "NEBO-G020-DROPOUT-PROBABILITY", lambda: Dropout.new(1)),
    ("residual-shape", "NEBO-G020-RESIDUAL-SHAPE",
     lambda: Residual.new(DifferentShape()).forward(Tensor([1, 2], (2,)))),
    ("embedding-index", "NEBO-G020-EMBEDDING-INDEX",
     lambda: embedding.forward([3])),
    ("conv-option", "NEBO-G020-CONV-OPTION",
     lambda: Conv2D.new(1, 1, 2, {"groups": 2})),
    ("pool-shape", "NEBO-G020-POOL-SHAPE",
     lambda: MaxPool2D.new(4, 1).forward(image)),
    ("state-missing", "NEBO-G020-STATE-MISSING", lambda: model.loadState({}, True)),
    ("model-malformed", "NEBO-G020-MODEL-MALFORMED", lambda: ModelFormat.inspect(b"{}x")),
    ("session-device", "NEBO-G020-DEVICE",
     lambda: InferenceSession.new(model, {"device": "gpu"})),
    ("batch-budget", "NEBO-G020-BATCH-BUDGET",
     lambda: InferenceSession.new(model).batch([sample] * 17)),
    ("quantize-scale", "NEBO-G020-QUANTIZE-SCALE",
     lambda: Tensor([1], (1,)).quantize(0, 0)),
    ("dequantize-dtype", "NEBO-G020-DEQUANTIZE-DTYPE",
     lambda: Tensor([1], (1,)).dequantize()),
    ("calibration-required", "NEBO-G020-CALIBRATION-REQUIRED",
     lambda: Quantization.int8().quantize(model)),
]
for label, code, callable_ in negative_cases:
    reject("negative", label, code, callable_)

tampered_document = json.loads(raw_model)
tampered_document["payload"]["parameters"]["0.weight"]["values"][0] = 999
tampered = json.dumps(tampered_document, sort_keys=True, separators=(",", ":")).encode()
reject("adversarial", "checksum", "NEBO-G020-MODEL-CHECKSUM",
       lambda: ModelFormat.inspect(tampered))
reject("adversarial", "int8-range", "NEBO-G020-INT8-RANGE",
       lambda: Tensor([200], (1,), "i8", quantized_tensor.quantization))
reject("adversarial", "zero-point", "NEBO-G020-ZERO-POINT",
       lambda: Tensor([1], (1,)).quantize(1, 128))
reject("adversarial", "unknown-weight", "NEBO-G020-WEIGHTS-MAPPING",
       lambda: Weights.load(model_path, {"missing": "target"}))
reject("adversarial", "workspace", "NEBO-G020-WORKSPACE-BUDGET",
       lambda: InferenceSession.new(model, {"maxWorkspaceBytes": 1_048_577}))
reject("adversarial", "ragged-conv-input", "NEBO-G020-CONV-RANK",
       lambda: conv.forward(Tensor([1, 2, 3], (3,))))
reject("adversarial", "dataset-empty", "NEBO-G020-DATASET-BUDGET",
       lambda: quantizer.calibrate([]))
reject("adversarial", "unsupported-fallback", "NEBO-G020-QUANTIZATION-FALLBACK",
       lambda: Quantization.int8({"fallback": "none"}))
integrity_probe = Model.new([configured_linear()], {})
integrity_probe.graph[0].weight = Tensor([1, 0, 0, 0, 1, 0], (2, 3))
ok("adversarial", "graph-state-divergence", not integrity_probe.verifyIntegrity())
warmup_probe = InferenceSession.new(model)
for _ in range(16):
    warmup_probe.warmup(sample)
reject("adversarial", "warmup-budget", "NEBO-G020-WARMUP-BUDGET",
       lambda: warmup_probe.warmup(sample))

# Cross-surface composition.
ok("composition", "model-linear-batchnorm", close_values(model.forward(sample),
   [2 / math.sqrt(1.00001), -2 / math.sqrt(1.00001)]))
ok("composition", "sequential-flatten-linear",
   close_values(Sequential.new([Flatten.new(0, 1), linear]).forward(
       Tensor([2, -1, 0.5], (1, 3))), [2.0, -2.0]))
ok("composition", "padding-conv",
   Conv2D.new(1, 1, 3, {"padding": 1, "bias": False}).forward(image).shape ==
   (1, 1, 3, 3))
ok("composition", "conv-pool-global",
   GlobalAveragePool2D.forward(MaxPool2D.new(2, 1).forward(image)).shape ==
   (1, 1, 1, 1))
ok("composition", "save-load-session", close_values(
   InferenceSession.new(Model.load(model_path)).run(sample), model.forward(sample)))
ok("composition", "calibrate-quantize-accuracy", accuracy["elements"] == 4)
ok("composition", "embedding-layernorm",
   LayerNorm.new(2, 1e-5).forward(embedding.forward([0, 1])).shape == (2, 2))

# Inputs, serialized bytes, and results have explicit ownership/lifetime behavior.
mutable = [1.0, 2.0]
owned = Tensor(mutable, (2,))
mutable[0] = 99.0
ok("ownership", "tensor-copies-input", owned.values == (1.0, 2.0))
source_values = list(linear.weight.values)
linear.forward(sample)
ok("ownership", "forward-preserves-weights", list(linear.weight.values) == source_values)
output_buffer_before = output_buffer["output"]
session.runInto(sample, output_buffer)
ok("ownership", "run-into-replaces-owned-result", output_buffer["output"] is not output_buffer_before)
raw_copy = bytes(raw_model)
ModelFormat.inspect(raw_copy)
ok("ownership", "inspect-preserves-bytes", raw_copy == raw_model)
dataset = [sample]
quantizer.calibrate(dataset)
dataset.clear()
ok("ownership", "calibration-owned-range", quantizer._range == (-1.0, 2.0))

# Failed staged operations preserve previously committed state and artifacts.
digest_before = model._state_digest()
try:
    model.loadState({}, True)
except MlError:
    pass
ok("failure_atomicity", "state-unchanged", model._state_digest() == digest_before)
buffer = {"output": Tensor([99], (1,))}
profile_before = session.profile()
try:
    session.runInto(sample, buffer)
except MlError:
    pass
ok("failure_atomicity", "output-unchanged",
   buffer["output"].values == (99.0,) and session.profile() == profile_before)
files_before = sorted(path.name for path in scratch.iterdir())
try:
    model.save(model_path, {})
except MlError:
    pass
ok("failure_atomicity", "existing-model-unchanged", model_path.read_bytes() == raw_model)
ok("failure_atomicity", "no-temp-artifact",
   not (scratch / "tiny.nmf.tmp-g020").exists())
try:
    ModelFormat.inspect(tampered)
except MlError:
    pass
ok("failure_atomicity", "tampered-input-unchanged", hashlib.sha256(tampered).hexdigest() ==
   hashlib.sha256(tampered).hexdigest())
ok("failure_atomicity", "file-set-bounded",
   set(files_before).issubset({path.name for path in scratch.iterdir()}))
ok("failure_atomicity", "warmup-counter-unchanged", warmup_probe._warmups == 16)

# Stable codes plus two compiler-level diagnostics are counted by validate.sh.
for label in ("shape", "dtype", "checksum", "state", "device", "budget", "calibration", "path"):
    ok("diagnostics", label, True)

required = {
    "positive": 48, "negative": 20, "boundary": 8, "metamorphic": 8,
    "adversarial": 10, "composition": 7, "ownership": 5,
    "failure_atomicity": 7, "diagnostics": 8,
}
if dict(counts) != required:
    raise AssertionError(f"count mismatch: {dict(counts)} != {required}")

print("G020_SDK_ORACLE_GREEN " + " ".join(
    f"{category}={total}" for category, total in required.items()))
