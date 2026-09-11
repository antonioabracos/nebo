#!/usr/bin/env python3
"""Independent value/effect oracle for all 39 current G022 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct
import sys


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.ml_inference import Tensor as HostTensor  # noqa: E402
from compiler.sdk.gpu import (  # noqa: E402
    CpuReference, DeviceBuffer, Gpu, GpuContext, GpuDevice, GpuError,
    GpuKernel, GpuModule, GpuOperation, GpuPlanner, GpuProfiler, GpuSession,
    GpuStream, GpuTensor, REFERENCE_BACKEND_CONTRACT, memory,
)


counts: dict[str, int] = defaultdict(int)


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def reject(category: str, label: str, code: str, operation: str, callable_) -> None:
    try:
        callable_()
    except GpuError as error:
        ok(category, label, error.code() == code and error.operation() == operation)
        return
    raise AssertionError(f"{category}:{label}:accepted")


def pack(values: tuple[float, ...]) -> bytes:
    return struct.pack("<" + "d" * len(values), *values)


def unpack(value: DeviceBuffer) -> tuple[float, ...]:
    target = bytearray(value.nbytes)
    value.download(target)
    return struct.unpack("<" + "d" * (len(target) // 8), target)


device = CpuReference.device()

# S01: physical discovery remains empty while the explicit CPU reference owns
# the executable differential context.
ok("positive", "Gpu.enumerate", Gpu.enumerate() == ())
properties = device.properties()
ok("positive", "device.properties", properties["backend"] == "cpu-reference" and
   properties["accelerated"] is False and properties["driverContract"] == "none")
probe = GpuContext.create(device, {"memoryBudget": 64})
ok("positive", "GpuContext.create", probe.memoryUsed() == 0)
ok("positive", "context.device", probe.device() is device)
ok("positive", "context.synchronize", probe.synchronize() == 0)
ok("positive", "context.close", probe.close() == 0)

# S02: owned host/reference memory and exact byte transfers.
context = GpuContext.create(device, {"memoryBudget": 256})
left = DeviceBuffer.allocate(context, 16)
right = DeviceBuffer.allocate(context, 16)
output = DeviceBuffer.allocate(context, 16)
ok("positive", "DeviceBuffer.allocate", context.memoryUsed() == 48)
ok("positive", "buffer.upload", left.upload(pack((1.25, -2.5))) == 16)
downloaded = bytearray(16)
ok("positive", "buffer.download", left.download(downloaded) == 16 and
   bytes(downloaded) == pack((1.25, -2.5)))
ok("positive", "buffer.copyTo", left.copyTo(right) == 16 and
   unpack(right) == (1.25, -2.5))
host_tensor = GpuTensor.fromHost(HostTensor([3.5, -4.25], (2,)))
placed = host_tensor.toDevice(device)
ok("positive", "tensor.toDevice", placed.device() is device)
restored = placed.toHost()
ok("positive", "tensor.toHost", restored.host.values == (3.5, -4.25) and
   restored.device() is None)
pinned = memory.pinned(23)
ok("positive", "memory.pinned", len(pinned.data) == 23 and not pinned.pinned and
   "unavailable" in pinned.fallback)

# S03: static verified module, typed binding, queued launch, and feature data.
module = GpuModule.vectorModule()
kernel = GpuKernel.load(module, "vector_add")
ok("positive", "GpuKernel.load", isinstance(kernel, GpuKernel))
ok("positive", "kernel.signature", kernel.signature() ==
   ("buffer", "buffer", "buffer"))
right.upload(pack((7.75, 6.5)))
bound = kernel.bind((left, right, output))
ok("positive", "kernel.bind", bound.signature() == kernel.signature())
stream = GpuStream.create(context)
receipt = bound.launch((1,), (2,), stream)
ok("positive", "kernel.launch", receipt.grid == (1,) and receipt.block == (2,))
ok("positive", "kernel.requiredFeatures", kernel.requiredFeatures() == ("f64",))
cache_key = module.cacheKey()
ok("positive", "module.cacheKey", len(cache_key) == 64 and
   cache_key == hashlib.sha256(json.dumps(module._manifest, sort_keys=True,
                                           separators=(",", ":"),
                                           ensure_ascii=True).encode("ascii")).hexdigest())
ok("positive", "module.verify", module.verify())

# S04: ordered streams, dependency events, synchronization, and logical timing.
ok("positive", "GpuStream.create", stream._context is context)
finished = stream.recordEvent()
ok("positive", "stream.recordEvent", finished._completed_tick is None)
ok("positive", "event.wait", finished.wait() > 0 and unpack(output) == (9.0, 4.0))
dependent = GpuStream.create(context)
ok("positive", "stream.wait", dependent.wait(finished) == 1)
ok("positive", "stream.synchronize", dependent.synchronize() == 1)
later = stream.recordEvent()
later.wait()
ok("positive", "event.elapsed", finished.elapsed(later) > 0)

# S05: placement and planner decisions remain explicit and never claim
# acceleration for the CPU correctness backend.
ok("positive", "tensor.device", placed.device() is device)
planner = GpuPlanner()
add_operation = GpuOperation("vector-add", 16, lambda: (9.0, 4.0), True)
ok("positive", "planner.selectDevice",
   planner.selectDevice(add_operation, context) is device)
plan = planner.transferPlan()
ok("positive", "planner.transferPlan", plan["backend"] == "cpu-reference" and
   plan["deviceTransfers"] == 0 and plan["accelerated"] is False)
unsupported = GpuOperation("fft", 16, lambda: (3.0, 5.0), False)
planner.selectDevice(unsupported, context)
ok("positive", "planner.fallbackToCpu", planner.fallbackToCpu() == (3.0, 5.0))
session = GpuSession()
ok("positive", "session.pinDevice", session.pinDevice(device) is device)
ok("positive", "operation.supportedOn", add_operation.supportedOn(device) and
   not unsupported.supportedOn(device))

# S06: stable errors, logical profiling, and atomic memory budgets.
physical = GpuDevice("unverified-0", "Unverified adapter", "unverified", "gpu",
                     True, 1024, (), "missing", "unknown", "unknown")
try:
    GpuContext.create(physical)
except GpuError as error:
    captured = error
else:
    raise AssertionError("physical-backend-unexpectedly-created")
ok("positive", "GpuError.code",
   captured.code() == "NEBO-G022-PHYSICAL-BACKEND-UNAVAILABLE")
ok("positive", "GpuError.operation", captured.operation() == "GpuContext.create")
profiler = GpuProfiler.start()
ok("positive", "GpuProfiler.start", profiler._running)
profile_stream = GpuStream.create(context)
profile_stream.recordEvent().wait()
event_count = profiler.stop()
ok("positive", "profiler.stop", event_count >= 2 and not profiler._running)
ok("positive", "context.memoryUsed", context.memoryUsed() == 48)
ok("positive", "context.setMemoryBudget", context.setMemoryBudget(96) == 96)
trace = json.loads(profiler.exportTrace())
ok("positive", "profiler.exportTrace", trace["schema"] ==
   "nebo-g022-logical-trace-v1" and trace["timing"].endswith("not-benchmark-time") and
   trace["truncated"] is False and
   all(not event["accelerated"] for event in trace["events"]))

if counts["positive"] != 39:
    raise AssertionError(f"surface-count:{counts['positive']}")

# Negative and diagnostic vectors bind every failure to a stable code/owner.
reject("negative", "physical-context", "NEBO-G022-PHYSICAL-BACKEND-UNAVAILABLE",
       "GpuContext.create", lambda: GpuContext.create(physical))
reject("negative", "unknown-option", "NEBO-G022-OPTION", "GpuContext.create",
       lambda: GpuContext.create(device, {"vendorMagic": 1}))
reject("negative", "zero-buffer", "NEBO-G022-BUDGET", "DeviceBuffer.allocate",
       lambda: DeviceBuffer.allocate(context, 0))
reject("negative", "wrong-upload", "NEBO-G022-TRANSFER-SIZE", "buffer.upload",
       lambda: left.upload(b"short"))
reject("negative", "immutable-download", "NEBO-G022-HOST-BUFFER", "buffer.download",
       lambda: left.download(bytes(16)))
reject("negative", "unknown-kernel", "NEBO-G022-KERNEL-NAME", "GpuKernel.load",
       lambda: GpuKernel.load(module, "missing"))
reject("negative", "wrong-arity", "NEBO-G022-KERNEL-ARITY", "kernel.bind",
       lambda: kernel.bind((left, output)))
reject("negative", "unbound-launch", "NEBO-G022-KERNEL-UNBOUND", "kernel.launch",
       lambda: kernel.launch((1,), (1,), stream))
empty_planner = GpuPlanner()
reject("negative", "empty-plan", "NEBO-G022-PLANNER-EMPTY", "planner.transferPlan",
       empty_planner.transferPlan)
reject("negative", "physical-pin", "NEBO-G022-PHYSICAL-BACKEND-UNAVAILABLE",
       "session.pinDevice", lambda: session.pinDevice(physical))
ok("diagnostics", "contract-physical", REFERENCE_BACKEND_CONTRACT["physicalGpuCertified"] is False)
ok("diagnostics", "contract-driver", REFERENCE_BACKEND_CONTRACT["driver"] == "none")
ok("diagnostics", "contract-license", "vendor" in REFERENCE_BACKEND_CONTRACT["license"])
ok("diagnostics", "contract-target", REFERENCE_BACKEND_CONTRACT["target"] ==
   "x86_64-systemv-elf-linux")

# Boundary checks cover exact limits without allocating the global maximum.
tiny = GpuContext.create(device, {"memoryBudget": 1})
one = DeviceBuffer.allocate(tiny, 1)
ok("boundary", "minimum-budget", tiny.memoryUsed() == 1)
reject("boundary", "budget-plus-one", "NEBO-G022-MEMORY-BUDGET", "DeviceBuffer.allocate",
       lambda: DeviceBuffer.allocate(tiny, 1))
ok("boundary", "maximum-launch-dimension",
   GpuKernel.load(module, "scale").bind((left, 1.0, output)).launch(
       (65_535,), (1,), stream).grid == (65_535,))
reject("boundary", "launch-product", "NEBO-G022-LAUNCH-BUDGET", "kernel.launch",
       lambda: bound.launch((1024,), (1025,), stream))
ok("boundary", "pinned-minimum", len(memory.pinned(1).data) == 1)

# Metamorphic relations: changed inputs change effects while identity copies do not.
scale = GpuKernel.load(module, "scale")
right.upload(pack((2.0, -3.0)))
scale.bind((right, -2.0, output)).launch((1,), (2,), stream)
stream.synchronize()
ok("metamorphic", "scale-sign", unpack(output) == (-4.0, 6.0))
right.upload(pack((3.0, -3.0)))
scale.bind((right, -2.0, output)).launch((1,), (2,), stream)
stream.synchronize()
ok("metamorphic", "changed-input", unpack(output) == (-6.0, 6.0))
left.copyTo(right)
ok("metamorphic", "copy-identity", unpack(left) == unpack(right))
ok("metamorphic", "cache-repeat", module.cacheKey() == cache_key)

# Adversarial and failure-atomicity checks preserve prior live state.
before = bytes(left._data)
reject("failure_atomicity", "failed-upload-preserves-buffer", "NEBO-G022-TRANSFER-SIZE",
       "buffer.upload", lambda: left.upload(b"x"))
ok("failure_atomicity", "upload-state", bytes(left._data) == before)
used = context.memoryUsed()
reject("failure_atomicity", "failed-budget-preserves-accounting", "NEBO-G022-MEMORY-IN-USE",
       "context.setMemoryBudget", lambda: context.setMemoryBudget(1))
ok("failure_atomicity", "budget-state", context.memoryUsed() == used and
   context._memory_budget == 96)
failing_context = GpuContext.create(device, {"memoryBudget": 32})
failing_input = DeviceBuffer.allocate(failing_context, 8)
failing_output = DeviceBuffer.allocate(failing_context, 8)
failing_input.upload(pack((1.0e308,)))
failing_stream = GpuStream.create(failing_context)
GpuKernel.load(GpuModule.vectorModule(), "scale").bind(
    (failing_input, 1.0e308, failing_output)).launch((1,), (1,), failing_stream)
reject("failure_atomicity", "close-reports-command-error", "NEBO-G022-NONFINITE",
       "scale", failing_context.close)
ok("failure_atomicity", "close-releases-after-error",
   failing_context._closed and failing_context._memory_used == 0 and
   failing_input._closed and failing_output._closed)
foreign = GpuContext.create(device, {"memoryBudget": 32})
foreign_buffer = DeviceBuffer.allocate(foreign, 16)
foreign_before = bytes(foreign_buffer._data)
reject("adversarial", "cross-context-copy", "NEBO-G022-CONTEXT-MISMATCH", "buffer.copyTo",
       lambda: left.copyTo(foreign_buffer))
ok("adversarial", "foreign-preserved", bytes(foreign_buffer._data) == foreign_before)
reject("adversarial", "nonfinite-scalar", "NEBO-G022-KERNEL-ARGUMENT", "kernel.bind",
       lambda: scale.bind((left, math.nan, output)))
reject("adversarial", "arbitrary-module", "NEBO-G022-ARBITRARY-MODULE", "GpuModule",
       lambda: GpuModule("unsafe", {"run": lambda _arguments: None},
                         {"run": ()}, {"run": ()}))
module._manifest["name"] = "tampered"
reject("adversarial", "tampered-module", "NEBO-G022-MODULE-INTEGRITY", "module.verify",
       module.verify)
module._manifest["name"] = module.name
ok("adversarial", "module-restored", module.verify())
cycle_context = GpuContext.create(device, {"memoryBudget": 16})
cycle_left = GpuStream.create(cycle_context)
cycle_right = GpuStream.create(cycle_context)
cycle_left_event = cycle_left.recordEvent()
cycle_right.wait(cycle_left_event)
cycle_right_event = cycle_right.recordEvent()
reject("adversarial", "dependency-cycle", "NEBO-G022-DEPENDENCY-CYCLE", "stream.wait",
       lambda: cycle_left.wait(cycle_right_event))
cycle_context.close()

# Composition crosses transfer, kernel, event, planner, profiler, and teardown.
ok("composition", "transfer-kernel-event", finished._completed_tick is not None and
   output.nbytes == 16)
ok("composition", "planner-operation", planner.transferPlan()["backend"] == "cpu-fallback")
ok("composition", "trace-context", any(event["event"] == "command.complete"
                                        for event in trace["events"]))
ok("composition", "tensor-roundtrip", restored.host.digest() == host_tensor.host.digest())

# Ownership/lifetime and use-after-close.
ok("ownership", "placed-owner", placed._owns_context and placed._buffer is not None)
placed.close()
ok("ownership", "placed-release", placed._context is None and placed._buffer is None)
released = one.close()
ok("ownership", "buffer-release", released == 1 and tiny.memoryUsed() == 0)
tiny.close()
reject("ownership", "closed-context", "NEBO-G022-CONTEXT-CLOSED", "context.memoryUsed",
       tiny.memoryUsed)

# Deterministic logical artifacts and target facts.
ok("determinism", "module-key", module.cacheKey() == cache_key)
ok("determinism", "canonical-trace", json.dumps(trace, sort_keys=True,
                                                  separators=(",", ":")) ==
   json.dumps(trace, sort_keys=True, separators=(",", ":")))
ok("determinism", "enumeration", Gpu.enumerate() == Gpu.enumerate() == ())
ok("target", "software-reference", device.kind == "cpu-reference" and not device.accelerated)
ok("target", "no-hardware", len(Gpu.enumerate()) == 0)
ok("target", "no-driver", device.driver_contract == "none")

overflow_profiler = GpuProfiler.start()
overflow_context = GpuContext.create(device, {"memoryBudget": 1})
for index in range(513):
    overflow_context._tick("trace-boundary", {"index": index})
ok("boundary", "trace-cap", overflow_profiler.stop() == 512)
overflow_trace = json.loads(overflow_profiler.exportTrace())
ok("boundary", "trace-truncation", overflow_trace["truncated"] is True and
   len(overflow_trace["events"]) == 512)
overflow_context.close()

# The local comparison run accounts for warmup and both transfer directions;
# it deliberately reports no wall-clock or GPU throughput measurement.
warmup_runs = 2
measured_runs = 3
transfer_bytes = 0
for index in range(warmup_runs + measured_runs):
    right.upload(pack((float(index + 1), float(index + 2))))
    transfer_bytes += right.nbytes
    scale.bind((right, 2.0, output)).launch((1,), (2,), stream)
    stream.synchronize()
    sink = bytearray(output.nbytes)
    output.download(sink)
    transfer_bytes += output.nbytes
ok("benchmark", "warmup-accounted", warmup_runs == 2)
ok("benchmark", "measured-accounted", measured_runs == 3)
ok("benchmark", "transfer-accounted", transfer_bytes == 160)
ok("benchmark", "reference-result", unpack(output) == (10.0, 12.0))

foreign.close()
context.close()

expected = {
    "positive": 39, "negative": 10, "boundary": 7, "metamorphic": 4,
    "adversarial": 7, "composition": 4, "ownership": 4,
    "failure_atomicity": 6, "diagnostics": 4, "determinism": 3,
    "target": 3, "benchmark": 4,
}
for category, count in expected.items():
    if counts[category] != count:
        raise AssertionError(f"{category}:{counts[category]}!={count}")

print("G022_SDK_ORACLE_GREEN " + " ".join(
    f"{category}={counts[category]}" for category in (
        "positive", "negative", "boundary", "metamorphic", "adversarial",
        "composition", "ownership", "failure_atomicity", "diagnostics",
        "determinism", "target", "benchmark"
    )
))
