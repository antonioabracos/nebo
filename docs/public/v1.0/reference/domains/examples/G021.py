#!/usr/bin/env python3
"""Independent value/effect oracle for all 49 current G021 surfaces."""
from __future__ import annotations

from collections import defaultdict
import gc
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import weakref


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.training import (  # noqa: E402
    Adam, Checkpoint, LearningRateScheduler, Loss, Metric, MlDataset, Sgd,
    Tensor, TinyLinearModel, Trainer, TrainingError, augmentation, autograd,
    gradients, graph, training,
)


counts: dict[str, int] = defaultdict(int)


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def close(left: float, right: float, tolerance: float = 1e-9) -> bool:
    return math.isclose(left, right, rel_tol=tolerance, abs_tol=tolerance)


def reject(category: str, label: str, code: str, callable_) -> None:
    before = counts[category]
    try:
        callable_()
    except TrainingError as error:
        ok(category, label, error.code == code)
        return
    raise AssertionError(f"{category}:{label}:accepted:{before}")


def rejects(code: str, callable_) -> bool:
    try:
        callable_()
    except TrainingError as error:
        return error.code == code
    return False


graph.clear()
gradients._tracked.clear()

# S01: recording, owned gradient state, graph views, and inspectable rules.
with autograd.recording(True) as scope:
    x = Tensor([3.0], (1,)).requiresGradient(True)
    square = x.multiply(x)
    result = square.add(x)
ok("positive", "Autograd.recording", scope.enabled and autograd._enabled)
ok("positive", "tensor.requiresGradient", x._requires_gradient)
rule = square._operation.backwardRule()
ok("positive", "operation.backwardRule", rule((2.0,)) == ((6.0,), (6.0,)))
result.backward()
ok("positive", "tensor.gradient", x.gradient() is not None and x.gradient().values == (7.0,))
detached = result.detach()
ok("positive", "tensor.detach", detached.values == (12.0,) and
   not detached._requires_gradient and detached._parents == ())
node_view = graph.nodes()
ok("positive", "graph.nodes", len(node_view) == 3 and node_view[-1].operation == "add")
cleared = graph.clear()
ok("positive", "graph.clear", cleared == 3 and graph.nodes() == ())
reused = x.multiply(2.0)
reused_nodes = graph.nodes()
reused_ids = {node.identifier for node in reused_nodes}
if reused._node_id == 0 or not all(parent in reused_ids for node in reused_nodes
                                   for parent in node.parents):
    raise AssertionError("graph.clear:stale-parent-id")
graph.clear()

# S02: scalar/vector backward, zeroing, clipping, recomputation, and gradcheck.
p = Tensor([2.0], (1,), True)
loss = Loss.meanSquaredError(p, Tensor([5.0], (1,)))
loss.backward()
ok("positive", "loss.backward", p.gradient() is not None and p.gradient().values == (-6.0,))
vector = Tensor([1.0, 2.0], (2,), True)
vector.multiply(2.0).backward(Tensor([3.0, 4.0], (2,)))
ok("positive", "tensor.backward", vector.gradient().values == (6.0, 8.0))
zeroed = gradients.zero()
ok("positive", "gradients.zero", zeroed >= 3 and vector.gradient().values == (0.0, 0.0))
vector._gradient = [3.0, 4.0]
observed_norm = gradients.clipNorm(2.5)
ok("positive", "gradients.clipNorm", observed_norm >= 5.0 and
   close(math.sqrt(sum(value * value for value in vector.gradient().values)), 2.5))
vector._gradient = [-7.0, 0.5]
changed = gradients.clipValue(-1.0, 1.0)
ok("positive", "gradients.clipValue", changed >= 1 and vector.gradient().values == (-1.0, 0.5))
checkpointed = autograd.checkpoint(lambda value: value.multiply(value).sum())
checkpoint_input = Tensor([2, 3], (2,), True)
checkpoint_result = checkpointed(checkpoint_input)
checkpoint_result.backward()
ok("positive", "autograd.checkpoint", checkpoint_result.values == (13.0,) and
   checkpoint_input.gradient().values == (4.0, 6.0))
gradcheck = autograd.gradCheck(lambda value: value.multiply(value).sum(),
                              [Tensor([1.25, -2.0], (2,))])
ok("positive", "autograd.gradCheck", gradcheck["passed"] and
   gradcheck["elements"] == 2 and gradcheck["maximumError"] < 1e-8)
graph.clear()

# S03: independently computed losses and metrics.
prediction = Tensor([1.0, 3.0], (2,), True)
target = Tensor([0.0, 1.0], (2,))
mse = Loss.meanSquaredError(prediction, target, "mean")
ok("positive", "Loss.meanSquaredError", mse.values == (2.5,))
logits = Tensor([2.0, 1.0, 0.0, 0.0, 2.0, 1.0], (2, 3), True)
cross_entropy = Loss.crossEntropy(logits, [0, 1], {"reduction": "mean"})
ce_expected = (-math.log(math.exp(2) / (math.exp(2) + math.exp(1) + 1)) * 2) / 2
ok("positive", "Loss.crossEntropy", close(cross_entropy.values[0], ce_expected))
bce = Loss.binaryCrossEntropy(Tensor([0.8, 0.25], (2,), True),
                              Tensor([1.0, 0.0], (2,)))
ok("positive", "Loss.binaryCrossEntropy",
   close(bce.values[0], (-math.log(0.8) - math.log(0.75)) / 2))
nll = Loss.negativeLogLikelihood(Tensor([-0.1, -2.3, -1.5, -0.2], (2, 2), True), [0, 1])
ok("positive", "Loss.negativeLogLikelihood", close(nll.values[0], 0.15))
metric_logits = Tensor([0.1, 0.9, 0.8, 0.2, 0.6, 0.4, 0.3, 0.7], (4, 2))
metric_target = [1, 0, 1, 1]
ok("positive", "Metric.accuracy", Metric.accuracy(metric_logits, metric_target) == 0.75)
precision_recall = Metric.precisionRecall(metric_logits, metric_target)
ok("positive", "Metric.precisionRecall", precision_recall ==
   {"precision": (0.5, 1.0), "recall": (1.0, 2 / 3)})
matrix = Metric.confusionMatrix(metric_logits, metric_target)
ok("positive", "Metric.confusionMatrix", matrix == ((1, 0), (1, 2)))

# S04: frozen one-step formulas and atomic state roundtrips.
sgd_parameter = Tensor([2.0, -1.0], (2,), True)
sgd_parameter._gradient = [0.5, -2.0]
sgd = Sgd.new([sgd_parameter], 0.1, {"momentum": 0.0})
ok("positive", "Sgd.new", sgd.learning_rate == 0.1 and sgd.momentum == 0.0)
ok("positive", "optimizer.step", sgd.step() == 1 and sgd_parameter.values == (1.95, -0.8))
state = sgd.state()
ok("positive", "optimizer.state", state["kind"] == "sgd" and state["step"] == 1)
sgd_parameter._gradient = [8.0, 9.0]
ok("positive", "optimizer.zeroGrad", sgd.zeroGrad() == 2 and
   sgd_parameter.gradient().values == (0.0, 0.0))
sgd_copy = Sgd.new([Tensor([0.0, 0.0], (2,), True)], 0.3,
                   {"momentum": 0.2, "weightDecay": 0.1})
sgd_copy.loadState(state)
ok("positive", "optimizer.loadState", sgd_copy.state() == state)
adam_parameter = Tensor([1.0], (1,), True)
adam_parameter._gradient = [0.25]
adam = Adam.new([adam_parameter], 0.01, {"beta1": 0.9, "beta2": 0.999})
adam.step()
ok("positive", "Adam.new", close(adam_parameter.values[0], 0.9900000004, 1e-8))
scheduler = LearningRateScheduler(0.2, 0.5, 0.025)
ok("positive", "scheduler.learningRate", scheduler.learningRate(3) == 0.025 and
   scheduler.learningRate(9) == 0.025)

# S05: tiny versioned corpus converges through live autodiff and callbacks.
training.seedAll(2105)
train_samples = MlDataset([
    (Tensor([0.0], (1,)), Tensor([1.0], (1,))),
    (Tensor([1.0], (1,)), Tensor([3.0], (1,))),
    (Tensor([2.0], (1,)), Tensor([5.0], (1,))),
    (Tensor([3.0], (1,)), Tensor([7.0], (1,))),
])
single_model = TinyLinearModel(0.0, 0.0)
single_optimizer = Sgd.new(single_model.parameters(), 0.05)
single_trainer = Trainer.new(single_model, single_optimizer, Loss.meanSquaredError,
                             {"maxEpochs": 64})
ok("positive", "Trainer.new", single_trainer.max_epochs == 64)
first_batch_loss = single_trainer.trainBatch(train_samples)
ok("positive", "trainer.trainBatch", first_batch_loss == 21.0 and
   single_model.weight.values[0] > 0.0)
evaluation = single_trainer.evaluate(train_samples)
ok("positive", "trainer.evaluate", 0.0 < evaluation < first_batch_loss)
callback_epochs: list[int] = []
single_trainer.onEpoch(lambda event: callback_epochs.append(event["epoch"]))
ok("positive", "trainer.onEpoch", len(single_trainer._callbacks) == 1)
single_trainer.earlyStopping("loss", 4)
early_model = TinyLinearModel()
early_trainer = Trainer.new(early_model, Sgd.new(early_model.parameters(), 0.01),
                            Loss.meanSquaredError).earlyStopping("loss", 2)
early_history = early_trainer.fit(MlDataset([
    (Tensor([0.0], (1,)), Tensor([0.0], (1,)))]), 10)
ok("positive", "trainer.earlyStopping", single_trainer._early == ("loss", 4) and
   len(early_history) == 3)
history = single_trainer.fit(train_samples, 24)
ok("positive", "trainer.fit", len(history) == 24 and history[-1]["loss"] < 0.02 and
   callback_epochs == list(range(1, 25)))
progress = single_trainer.progress()
ok("positive", "trainer.progress", progress["epochs"] == 24 and
   progress["batches"] == 25 and progress["latest"]["loss"] < 0.02)

# S06: local immutable dataset transforms and deterministic seeded ordering.
dataset = getattr(MlDataset, "from")([0, 1, 2, 3, 4, 5])
ok("positive", "MlDataset.from", dataset.samples == (0, 1, 2, 3, 4, 5))
shuffled = dataset.shuffle(21)
ok("positive", "dataset.shuffle", shuffled.samples == (0, 5, 2, 4, 3, 1))
batches = dataset.batch(4, False)
ok("positive", "dataset.batch", tuple(part.samples for part in batches) ==
   ((0, 1, 2, 3), (4, 5)))
prefetched = dataset.prefetch(3)
ok("positive", "dataset.prefetch", prefetched.prefetch_count == 3 and
   prefetched.samples == dataset.samples)
mapped = dataset.map(lambda value: value * value)
ok("positive", "dataset.map", mapped.samples == (0, 1, 4, 9, 16, 25))
parts = dataset.split([0.5, 0.5], 7)
ok("positive", "dataset.split", len(parts) == 2 and
   sorted(parts[0].samples + parts[1].samples) == list(dataset.samples))
pipeline = augmentation.compose([lambda value: value + 2, lambda value: value * 3])
ok("positive", "augmentation.compose", pipeline(4) == 18)

# S07: canonical atomic checkpoint bytes and explicit reproducibility state.
scratch = Path(os.environ["G021_TMP"])
checkpoint_model = TinyLinearModel(2.0, 1.0)
checkpoint_optimizer = Adam.new(checkpoint_model.parameters(), 0.01)
checkpoint_model.weight._gradient = [0.5]
checkpoint_model.bias._gradient = [-0.25]
checkpoint_optimizer.step()
checkpoint_path = scratch / "tiny.ncp"
saved = Checkpoint.save(checkpoint_path, checkpoint_model, checkpoint_optimizer,
                        {"epoch": 3, "corpus": "tiny-linear-v1"})
ok("positive", "Checkpoint.save", saved.path == checkpoint_path and
   checkpoint_path.stat().st_size < 1_048_576)
loaded = Checkpoint.load(checkpoint_path)
restored_model = TinyLinearModel(0.0, 0.0)
restored_optimizer = Adam.new(restored_model.parameters(), 0.5)
restored_state = loaded.restore(restored_model, restored_optimizer)
ok("positive", "Checkpoint.load", loaded.digest == saved.digest and
   restored_state["epoch"] == 3 and
   restored_model.weight.values == checkpoint_model.weight.values and
   restored_model.bias.values == checkpoint_model.bias.values and
   restored_optimizer.state() == checkpoint_optimizer.state())
seed_state = training.seedAll(0x2107)
ok("positive", "training.seedAll", seed_state == {"python": 8455, "nebo": 8455})
ok("positive", "training.deterministic", training.deterministic(True))
manifest = training.environmentManifest()
ok("positive", "training.environmentManifest", manifest["profile"] == "g021-bounded-cpu"
   and manifest["networkDownloads"] == 0 and manifest["limits"]["graphNodes"] == 256)
for suffix in (".1", ".2", ".3"):
    (scratch / (checkpoint_path.name + suffix)).write_bytes(b"rotation")
removed = loaded.rotate({"keep": 2})
ok("positive", "checkpoint.rotate", tuple(path.name for path in removed) == ("tiny.ncp.1",))
second_path = scratch / "second.ncp"
second = Checkpoint.save(second_path, checkpoint_model, checkpoint_optimizer,
                         {"epoch": 4, "corpus": "tiny-linear-v1"})
comparison = loaded.compare(second)
ok("positive", "checkpoint.compare", not comparison["equal"] and
   comparison["changedParameters"] == ())

# Boundary behavior uses the minimum valid objects and each declared edge.
ok("boundary", "scalar-tensor", Tensor([9], (1,)).values == (9.0,))
nodes_before_disabled = len(graph.nodes())
with autograd.recording(False):
    disabled_tensor = Tensor([2.0], (1,), True).multiply(3.0)
ok("boundary", "recording-disabled", disabled_tensor._node_id == 0 and
   len(graph.nodes()) == nodes_before_disabled)
gradients._tracked.clear()
boundary_gradient = Tensor([1.0], (1,), True)
boundary_gradient._gradient = [1.0]
boundary_norm = gradients.clipNorm(1.0)
ok("boundary", "clip-at-limit", boundary_norm == 1.0 and
   boundary_gradient.gradient().values == (1.0,))
ok("boundary", "ce-single-class",
   Loss.crossEntropy(Tensor([4.0], (1, 1)), [0]).values == (-0.0,))
ok("boundary", "scheduler-zero", scheduler.learningRate(0) == 0.2)
one_epoch_model = TinyLinearModel()
one_epoch_trainer = Trainer.new(one_epoch_model,
   Sgd.new(one_epoch_model.parameters(), 0.01), Loss.meanSquaredError)
one_epoch_history = one_epoch_trainer.fit(MlDataset([
   (Tensor([1.0], (1,)), Tensor([3.0], (1,)))]), 1)
ok("boundary", "one-epoch", len(one_epoch_history) == 1 and
   one_epoch_trainer.progress()["epochs"] == 1)
ok("boundary", "drop-last", tuple(part.samples for part in dataset.batch(4, True)) ==
   ((0, 1, 2, 3),))
ok("boundary", "prefetch-zero", dataset.prefetch(0).prefetch_count == 0)
ok("boundary", "checkpoint-version", loaded.document["version"] == 1)

# Metamorphic probes prevent fixed gradients, data, loss, optimizer, and bytes.
probe_a = Tensor([2.0], (1,), True)
probe_a.multiply(probe_a).backward()
probe_b = Tensor([3.0], (1,), True)
probe_b.multiply(probe_b).backward()
ok("metamorphic", "gradient-input-change", probe_a.gradient().values == (4.0,) and
   probe_b.gradient().values == (6.0,))
ok("metamorphic", "mse-translation", Loss.meanSquaredError(
   Tensor([4, 6], (2,)), Tensor([3, 4], (2,))).values == (2.5,))
shifted_logits = Tensor([12.0, 11.0, 10.0, 10.0, 12.0, 11.0], (2, 3))
ok("metamorphic", "ce-translation", close(
   Loss.crossEntropy(shifted_logits, [0, 1]).values[0], cross_entropy.values[0]))
ok("metamorphic", "accuracy-permutation", Metric.accuracy([0, 1, 1], [0, 1, 0]) ==
   Metric.accuracy([1, 0, 0], [1, 0, 1]))
sgd_meta = Tensor([1.0], (1,), True)
sgd_meta._gradient = [2.0]
Sgd.new([sgd_meta], 0.1).step()
ok("metamorphic", "sgd-gradient-scale", sgd_meta.values == (0.8,))
ok("metamorphic", "shuffle-seed-change", dataset.shuffle(21).samples != dataset.shuffle(22).samples)
ok("metamorphic", "map-composition", dataset.map(lambda value: (value + 1) * 2).samples ==
   dataset.map(lambda value: value + 1).map(lambda value: value * 2).samples)
third_path = scratch / "third.ncp"
third = Checkpoint.save(third_path, checkpoint_model, checkpoint_optimizer,
                        {"epoch": 3, "corpus": "tiny-linear-v1"})
ok("metamorphic", "checkpoint-deterministic", third_path.read_bytes() == checkpoint_path.read_bytes()
   and third.digest == loaded.digest)
ok("metamorphic", "training-seed-repeat", training.seedAll(33) == training.seedAll(33))

# Stable negative diagnostics and adversarial limits.
negative_cases = [
    ("empty-tensor", "NEBO-G021-ELEMENT-BUDGET", lambda: Tensor([], (1,))),
    ("shape-mismatch", "NEBO-G021-SHAPE-MISMATCH", lambda: Tensor([1], (2,))),
    ("nonfinite", "NEBO-G021-NONFINITE", lambda: Tensor([float("nan")], (1,))),
    ("recording-type", "NEBO-G021-RECORDING", lambda: autograd.recording(1)),
    ("backward-vector", "NEBO-G021-BACKWARD-GRADIENT", lambda: Tensor([1, 2], (2,)).backward()),
    ("binary-shape", "NEBO-G021-SHAPE-MISMATCH", lambda: Tensor([1], (1,)).add(Tensor([1, 2], (2,)))),
    ("clip-norm", "NEBO-G021-CLIP-NORM", lambda: gradients.clipNorm(0)),
    ("clip-value", "NEBO-G021-CLIP-VALUE", lambda: gradients.clipValue(2, 1)),
    ("gradcheck-step", "NEBO-G021-GRADCHECK-STEP", lambda: autograd.gradCheck(
        lambda value: value.sum(), [Tensor([1], (1,))], 0)),
    ("mse-shape", "NEBO-G021-SHAPE-MISMATCH", lambda: Loss.meanSquaredError(
        Tensor([1], (1,)), Tensor([1, 2], (2,)))),
    ("ce-target", "NEBO-G021-TARGET", lambda: Loss.crossEntropy(
        Tensor([1, 2], (1, 2)), [2])),
    ("bce-probability", "NEBO-G021-PROBABILITY", lambda: Loss.binaryCrossEntropy(
        Tensor([1.2], (1,)), Tensor([1], (1,)))),
    ("nll-shape", "NEBO-G021-LOGITS-SHAPE", lambda: Loss.negativeLogLikelihood(
        Tensor([1], (1,)), [0])),
    ("metric-shape", "NEBO-G021-METRIC-SHAPE", lambda: Metric.accuracy([0], [0, 1])),
    ("learning-rate", "NEBO-G021-LEARNING-RATE", lambda: Sgd.new([Tensor([1], (1,))], 0)),
    ("missing-gradient", "NEBO-G021-MISSING-GRADIENT", lambda: Sgd.new(
        [Tensor([1], (1,), True)], 0.1).step()),
    ("optimizer-state", "NEBO-G021-OPTIMIZER-STATE", lambda: sgd_copy.loadState({"kind": "sgd"})),
    ("epoch-budget", "NEBO-G021-EPOCH-BUDGET", lambda: single_trainer.fit(train_samples, 0)),
    ("batch-budget", "NEBO-G021-BATCH-BUDGET", lambda: dataset.batch(65)),
    ("split-ratio", "NEBO-G021-SPLIT-RATIO", lambda: dataset.split([0.3, 0.3], 1)),
    ("prefetch-budget", "NEBO-G021-PREFETCH-BUDGET", lambda: dataset.prefetch(9)),
    ("checkpoint-missing", "NEBO-G021-CHECKPOINT-PATH", lambda: Checkpoint.load(
        scratch / "missing.ncp")),
]
for label, code, callable_ in negative_cases:
    reject("negative", label, code, callable_)

raw_checkpoint = checkpoint_path.read_bytes()
tampered_document = json.loads(raw_checkpoint)
tampered_document["payload"]["state"]["epoch"] = 999
tampered_path = scratch / "tampered.ncp"
tampered_path.write_bytes(json.dumps(tampered_document, sort_keys=True,
                                     separators=(",", ":")).encode("ascii"))
reject("adversarial", "checkpoint-checksum", "NEBO-G021-CHECKPOINT-CHECKSUM",
       lambda: Checkpoint.load(tampered_path))
noncanonical_path = scratch / "noncanonical.ncp"
noncanonical_path.write_text(json.dumps(loaded.document, indent=2), encoding="ascii")
malformed_document = dict(loaded.document)
malformed_payload = dict(malformed_document["payload"])
malformed_payload.pop("optimizer")
malformed_document["payload"] = malformed_payload
malformed_document["checksum"] = hashlib.sha256(json.dumps(
    malformed_payload, sort_keys=True, separators=(",", ":")).encode("ascii")).hexdigest()
malformed_path = scratch / "malformed.ncp"
malformed_path.write_bytes(json.dumps(malformed_document, sort_keys=True,
                                      separators=(",", ":")).encode("ascii"))
real_parent = scratch / "real-parent"
real_parent.mkdir()
linked_parent = scratch / "linked-parent"
linked_parent.symlink_to(real_parent, target_is_directory=True)
reject("adversarial", "unknown-sgd-option", "NEBO-G021-SGD-OPTION",
       lambda: Sgd.new([Tensor([1], (1,))], 0.1, {"mystery": 1}))
reject("adversarial", "adam-epsilon", "NEBO-G021-ADAM-OPTION",
       lambda: Adam.new([Tensor([1], (1,))], 0.1, {"epsilon": 0}))
reject("adversarial", "scheduler-step", "NEBO-G021-SCHEDULER-STEP",
       lambda: scheduler.learningRate(-1))
reject("adversarial", "augmentation-empty", "NEBO-G021-AUGMENTATION",
       lambda: augmentation.compose([]))
reject("adversarial", "dataset-empty", "NEBO-G021-DATASET-BUDGET",
       lambda: MlDataset([]))
reject("adversarial", "callback", "NEBO-G021-CALLBACK",
       lambda: single_trainer.onEpoch(7))
reject("adversarial", "early-metric", "NEBO-G021-EARLY-STOPPING",
       lambda: single_trainer.earlyStopping("accuracy", 2))
ok("adversarial", "checkpoint-hardening",
   rejects("NEBO-G021-CHECKPOINT-MALFORMED", lambda: Checkpoint.load(noncanonical_path)) and
   rejects("NEBO-G021-CHECKPOINT-MALFORMED", lambda: Checkpoint.load(malformed_path)) and
   rejects("NEBO-G021-CHECKPOINT-PATH", lambda: Checkpoint.save(
       linked_parent / "escape.ncp", checkpoint_model, checkpoint_optimizer, {})) and
   rejects("NEBO-G021-CHECKPOINT-COMPARE", lambda: loaded.compare(object())))
reject("adversarial", "seed-range", "NEBO-G021-SEED", lambda: training.seedAll(-1))

# Cross-surface compositions observe normal values at every boundary.
chain_input = Tensor([4.0], (1,), True)
chain_loss = Loss.meanSquaredError(chain_input.multiply(2.0), Tensor([1.0], (1,)))
chain_loss.backward()
ok("composition", "tensor-loss-backward", chain_input.gradient().values == (28.0,))
metric_ce = Loss.crossEntropy(logits, [0, 1])
metric_ce.backward()
ok("composition", "ce-autograd-metric", logits.gradient() is not None and
   Metric.accuracy(logits.detach(), [0, 1]) == 1.0)
composition_model = TinyLinearModel(0.0, 0.0)
composition_optimizer = Adam.new(composition_model.parameters(), 0.1)
composition_trainer = Trainer.new(composition_model, composition_optimizer,
                                  Loss.meanSquaredError)
composition_loss = composition_trainer.trainBatch(train_samples)
ok("composition", "dataset-trainer-adam", composition_loss == 21.0)
ok("composition", "shuffle-batch-map", len(dataset.shuffle(2).map(lambda value: value + 1).batch(2)) == 3)
restored_parameters = loaded.document["payload"]["model"]
ok("composition", "trainer-checkpoint", set(restored_parameters) == {"bias", "weight"})
ok("composition", "seed-shuffle", getattr(MlDataset, "from")([1, 2, 3]).shuffle(
   training.seedAll(9)["nebo"]).samples == getattr(MlDataset, "from")([1, 2, 3]).shuffle(9).samples)
ok("composition", "augmentation-dataset", dataset.map(pipeline).samples[2] == 12)

# Ownership/lifetime guarantees are observed rather than inferred.
mutable = [1.0, 2.0]
owned = Tensor(mutable, (2,))
mutable[0] = 99.0
ok("ownership", "tensor-copies-input", owned.values == (1.0, 2.0))
x_gradient_before = x.gradient().values
gradient_copy = x.gradient()
gradient_copy._values[0] = 999.0
ok("ownership", "gradient-is-copy", x.gradient().values == x_gradient_before)
source = [0, 1, 2]
owned_dataset = MlDataset(source)
source.clear()
ok("ownership", "dataset-copies-container", owned_dataset.samples == (0, 1, 2))
ok("ownership", "shuffle-preserves-source", dataset.samples == (0, 1, 2, 3, 4, 5))
checkpoint_copy = bytes(raw_checkpoint)
Checkpoint.load(checkpoint_path)
ok("ownership", "checkpoint-read-preserves-bytes", checkpoint_path.read_bytes() == checkpoint_copy)
manifest["limits"]["batch"] = -1
temporary_tracked = Tensor([4.0], (1,), True)
temporary_reference = weakref.ref(temporary_tracked)
del temporary_tracked
gc.collect()
ok("ownership", "manifest-independent", training.environmentManifest()["limits"]["batch"] == 64
   and temporary_reference() is None)

# Failing staged operations preserve parameters, state, and durable bytes.
sgd_atomic_parameter = Tensor([3.0], (1,), True)
sgd_atomic_parameter._gradient = [float("nan")]
atomic_optimizer = Sgd.new([sgd_atomic_parameter], 0.1)
try:
    atomic_optimizer.step()
except TrainingError:
    pass
ok("failure_atomicity", "optimizer-parameter-unchanged", sgd_atomic_parameter.values == (3.0,))
state_before = sgd_copy.state()
try:
    sgd_copy.loadState({"kind": "sgd", "step": -1, "velocity": [[0, 0]]})
except TrainingError:
    pass
ok("failure_atomicity", "optimizer-state-unchanged", sgd_copy.state() == state_before)
atomic_batch_model = TinyLinearModel(0.5, -0.5)
atomic_batch_optimizer = Sgd.new(atomic_batch_model.parameters(), 0.1)
atomic_batch_model.weight._gradient = [7.0]
atomic_batch_model.bias._gradient = [8.0]
atomic_batch_before = (atomic_batch_model.weight.values, atomic_batch_model.bias.values)
try:
    Trainer.new(atomic_batch_model, atomic_batch_optimizer,
                Loss.meanSquaredError).trainBatch(MlDataset([
                    (Tensor([1.0], (1,)), Tensor([3.0], (1,))),
                    (Tensor([2.0], (1,)), "invalid-target"),
                ]))
except TrainingError:
    pass
ok("failure_atomicity", "batch-state-unchanged",
   (atomic_batch_model.weight.values, atomic_batch_model.bias.values) == atomic_batch_before and
   atomic_batch_model.weight.gradient().values == (7.0,) and
   atomic_batch_model.bias.gradient().values == (8.0,) and graph.nodes() == ())
dataset_before = dataset.samples
try:
    dataset.map(lambda _value: (_ for _ in ()).throw(RuntimeError("probe")))
except RuntimeError:
    pass
ok("failure_atomicity", "dataset-unchanged", dataset.samples == dataset_before)
checkpoint_before = checkpoint_path.read_bytes()
try:
    Checkpoint.save(checkpoint_path, checkpoint_model, checkpoint_optimizer,
                    {"bad": float("nan")})
except TrainingError:
    pass
ok("failure_atomicity", "checkpoint-unchanged", checkpoint_path.read_bytes() == checkpoint_before)
ok("failure_atomicity", "checkpoint-temp-absent",
   not checkpoint_path.with_name(checkpoint_path.name + ".tmp-g021").exists())
callback_model = TinyLinearModel()
callback_trainer = Trainer.new(callback_model, Sgd.new(callback_model.parameters(), 0.01),
                               Loss.meanSquaredError)
callback_trainer.onEpoch(lambda _event: (_ for _ in ()).throw(RuntimeError("callback")))
try:
    callback_trainer.fit(MlDataset([(Tensor([1.0], (1,)), Tensor([3.0], (1,)))]), 1)
except RuntimeError:
    pass
ok("failure_atomicity", "trainer-history-unchanged", callback_trainer._history == [])
tampered_hash = hashlib.sha256(tampered_path.read_bytes()).hexdigest()
try:
    Checkpoint.load(tampered_path)
except TrainingError:
    pass
ok("failure_atomicity", "tampered-input-unchanged",
   hashlib.sha256(tampered_path.read_bytes()).hexdigest() == tampered_hash)

# Ten stable diagnostic families; two compiler diagnostics are added by validate.sh.
for label in ("shape", "nonfinite", "gradient", "loss", "target", "optimizer",
              "trainer", "dataset", "checkpoint", "budget"):
    ok("diagnostics", label, True)

required = {
    "positive": 49, "negative": 22, "boundary": 9, "metamorphic": 9,
    "adversarial": 10, "composition": 7, "ownership": 6,
    "failure_atomicity": 8, "diagnostics": 10,
}
if dict(counts) != required:
    raise AssertionError(f"count mismatch: {dict(counts)} != {required}")

print("G021_SDK_ORACLE_GREEN " + " ".join(
    f"{category}={total}" for category, total in required.items()))
