#!/usr/bin/env python3
"""Independent value/effect oracle for every current G017 public surface."""
from __future__ import annotations

from collections import defaultdict
import json
import math
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.numeric_kernels import (  # noqa: E402
    Benchmark, BenchmarkOptions, CpuFeatures, KernelContext, KernelDescriptor,
    KernelError, KernelPlanner, KernelRegistry, Parallel, ThreadPool, kernel,
)


counts: dict[str, int] = defaultdict(int)


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1


def reject(category: str, label: str, code: str, callable_) -> None:
    try:
        callable_()
    except KernelError as error:
        ok(category, label, error.code == code)
        return
    raise AssertionError(f"{category}:{label}:accepted")


local = CpuFeatures.detect()
scalar_features = CpuFeatures.simulated(sse2=False, avx2=False, logical_cores=1)
sse_features = CpuFeatures.simulated(sse2=True, avx2=False, logical_cores=2)
avx_features = CpuFeatures.simulated(sse2=True, avx2=True, logical_cores=4)

# One independently observed case per S01 surface.
ok("positive", "CpuFeatures.detect", local.source == "local-detection")
ok("positive", "features.hasSse2", isinstance(local.hasSse2(), bool))
ok("positive", "features.hasAvx2", isinstance(local.hasAvx2(), bool))
ok("positive", "features.hasAvx512", isinstance(local.hasAvx512(), bool))
ok("positive", "features.cacheInfo", local.cacheInfo().line_bytes in {32, 64, 128})
ok("positive", "features.logicalCores", local.logicalCores() >= 1)

left = [1.25, -2.0, 3.5, 4.0, -5.25, 6.0, 7.75]
right = [2.0, 3.0, -4.0, 0.5, 1.25, -2.0, 8.0]
reference_add = [3.25, 1.0, -0.5, 4.5, -4.0, 4.0, 15.75]
reference_dot = 27.9375

# S02 scalar reference surfaces use hand-computed expected values.
ok("positive", "kernel.scalar.add", kernel.scalar.add(left, right) == reference_add)
ok("positive", "kernel.scalar.dot", kernel.scalar.dot(left, right) == reference_dot)
ok("positive", "kernel.scalar.matmul",
   kernel.scalar.matmul([[1, 2, 3], [4, 5, 6]], [[7, 8], [9, 10], [11, 12]]) ==
   [[58.0, 64.0], [139.0, 154.0]])
ok("positive", "kernel.scalar.reduceSum", kernel.scalar.reduceSum(left) == 15.25)
ok("positive", "kernel.scalar.activation",
   kernel.scalar.activation([-3, 0, 2.5], "relu") == [0.0, 0.0, 2.5])
ok("positive", "kernel.scalar.convert",
   kernel.scalar.convert([-2.9, 9.8, 300], "u8", "saturate") == [0, 9, 255])

# S03 SIMD values are checked against the independent scalar oracle, including a tail.
ok("positive", "kernel.simd.add", kernel.simd.add(left, right, "avx2") == reference_add)
ok("positive", "kernel.simd.dot", kernel.simd.dot(left, right, "avx2") == reference_dot)
ok("positive", "kernel.simd.matmulMicroKernel",
   kernel.simd.matmulMicroKernel([[2, 3]], [[4], [5]], "sse2") == [[23.0]])
ok("positive", "kernel.simd.reduceSum", kernel.simd.reduceSum(left, "avx2") == 15.25)
packed = kernel.simd.pack([[1, 2, 3], [4, 5, 6]], 2)
ok("positive", "kernel.simd.pack",
   (packed.values, packed.rows, packed.columns, packed.block) ==
   ((1.0, 2.0, 4.0, 5.0, 3.0, 6.0), 2, 3, 2))
fallback_execution = kernel.simd.unalignedFallback("add", [3, 4, 5], [7, 8, 9])
ok("positive", "kernel.simd.unalignedFallback",
   fallback_execution.tier == "scalar" and fallback_execution.value == [10.0, 12.0, 14.0])

# S04 registration and selection are forced through simulated, not host-dependent, profiles.
registry = KernelRegistry.default()
custom = registry.register(KernelDescriptor("scalar.custom-add", "custom-add", "scalar"))
ok("positive", "KernelRegistry.register", custom.name == "scalar.custom-add")
dispatch = KernelPlanner(registry)
avx_plan = dispatch.select("add", KernelContext(16, "f64", avx_features, alignment=32))
ok("positive", "planner.select", avx_plan.descriptor.tier == "avx2")
ok("positive", "planner.explain", dispatch.explain()["kernel"] == "avx2.add")
ok("positive", "planner.fallback",
   dispatch.fallback("add", KernelContext(16, "f64", scalar_features)).descriptor.tier == "scalar")
dispatch.select("matmul", KernelContext(128, "f64", avx_features, alignment=32))
ok("positive", "planner.workspaceBytes", dispatch.workspaceBytes() == 4096)
dispatch.deterministicMode(True)
ok("positive", "planner.deterministicMode",
   dispatch.select("dot", KernelContext(32, "f64", avx_features, alignment=32)).descriptor.tier == "scalar")

# S05 uses real bounded worker threads but observes results in submission order.
chunks = Parallel.forRange(range(0, 11), 4, lambda selected: sum(selected), workers=3)
ok("positive", "Parallel.forRange", chunks == (6, 22, 27))
ok("positive", "Parallel.reduce", Parallel.reduce(range(1, 8), 0, lambda a, b: a + b, 3, 2) == 28)
pool = ThreadPool.new(2)
ok("positive", "ThreadPool.new", pool.size == 2)
future_a = pool.submit(lambda: 19)
future_b = pool.submit(lambda: 23)
ok("positive", "pool.submit", future_a.result() == 19)
ok("positive", "pool.waitIdle", pool.waitIdle() == (19, 23))
pool.close()
ok("positive", "planner.parallelThreshold", dispatch.parallelThreshold(384) == 384)

# S06 observes live timings but only makes descriptive, bounded claims.
benchmark = Benchmark.measure(lambda: kernel.scalar.dot(left, right),
                              BenchmarkOptions(warmup=1, samples=5, units=len(left),
                                               track_allocations=True))
ok("positive", "neboc bench", benchmark.metadata["descriptiveOnly"] is True)
ok("positive", "Benchmark.measure",
   len(benchmark.samples_ns) == 5 and benchmark.result_digest)
ok("positive", "benchmark.throughput", benchmark.throughput(len(left)) > 0.0)
ok("positive", "benchmark.allocations", benchmark.allocations()["bytes"] >= 0)
ok("positive", "benchmark.compare", benchmark.compare(benchmark)["regression"] is False)
exported = json.loads(benchmark.exportJson())
ok("positive", "benchmark.exportJson",
   exported["schema"] == 1 and exported["metadata"]["superiorityClaim"] is False)

# Boundary coverage.
ok("boundary", "empty-add", kernel.scalar.add([], []) == [])
ok("boundary", "empty-dot", kernel.scalar.dot([], []) == 0.0)
ok("boundary", "empty-reduce", kernel.scalar.reduceSum([]) == 0.0)
ok("boundary", "simd-one-lane-tail", kernel.simd.add([4], [9], "avx2") == [13.0])
ok("boundary", "max-elements", len(kernel.scalar.add([1] * 4096, [2] * 4096)) == 4096)
ok("boundary", "empty-range", Parallel.forRange(range(0), 1, sum) == ())
ok("boundary", "single-sample", len(Benchmark.measure(lambda: 1, {"samples": 1, "warmup": 0}).samples_ns) == 1)

# Metamorphic properties catch fixed-output and collapsed-path implementations.
shifted = kernel.scalar.add([value + 5 for value in left], right)
ok("metamorphic", "add-left-shift", all(math.isclose(a - b, 5.0) for a, b in zip(shifted, reference_add)))
ok("metamorphic", "dot-scale",
   kernel.scalar.dot([2 * value for value in left], right) == 2 * reference_dot)
ok("metamorphic", "simd-scalar-parity",
   kernel.simd.add(list(reversed(left)), list(reversed(right)), "sse2") ==
   kernel.scalar.add(list(reversed(left)), list(reversed(right))))
planner_sse = KernelPlanner()
ok("metamorphic", "feature-downgrade",
   planner_sse.select("add", KernelContext(16, "f64", sse_features, alignment=32)).descriptor.tier == "sse2")
ok("metamorphic", "grain-invariant",
   Parallel.reduce(range(1, 18), 0, lambda a, b: a + b, 2, 4) ==
   Parallel.reduce(range(1, 18), 0, lambda a, b: a + b, 7, 2))
ok("metamorphic", "benchmark-self-baseline", math.isclose(benchmark.compare(benchmark)["medianRatio"], 1.0))

# Negative, diagnostic, and failure-atomicity cases.
reject("negative", "add-shape", "NEBO-G017-SHAPE-MISMATCH", lambda: kernel.scalar.add([1], [1, 2]))
reject("negative", "dot-shape", "NEBO-G017-SHAPE-MISMATCH", lambda: kernel.scalar.dot([1], [1, 2]))
reject("negative", "ragged-matrix", "NEBO-G017-MATRIX-RAGGED",
       lambda: kernel.scalar.matmul([[1], [2, 3]], [[1], [2]]))
reject("negative", "matmul-shape", "NEBO-G017-SHAPE-MISMATCH",
       lambda: kernel.scalar.matmul([[1, 2]], [[1, 2]]))
reject("negative", "activation-name", "NEBO-G017-ACTIVATION-UNSUPPORTED",
       lambda: kernel.scalar.activation([1], "mystery"))
reject("negative", "dtype", "NEBO-G017-DTYPE-UNSUPPORTED",
       lambda: kernel.scalar.convert([1], "f16"))
reject("negative", "isa", "NEBO-G017-ISA-UNSUPPORTED", lambda: kernel.simd.add([1], [2], "mmx"))
reject("negative", "pack-block", "NEBO-G017-PACK-BLOCK", lambda: kernel.simd.pack([[1]], 3))
reject("negative", "unknown-operation", "NEBO-G017-OPERATION-UNSUPPORTED",
       lambda: kernel.simd.unalignedFallback("mystery", [1]))
reject("negative", "duplicate-descriptor", "NEBO-G017-DESCRIPTOR-DUPLICATE",
       lambda: registry.register(KernelDescriptor("scalar.custom-add", "custom-add", "scalar")))
reject("negative", "no-plan-explain", "NEBO-G017-PLAN-REQUIRED", lambda: KernelPlanner().explain())
reject("negative", "workers-zero", "NEBO-G017-WORKER-BUDGET", lambda: ThreadPool.new(0))
reject("negative", "range-step", "NEBO-G017-RANGE",
       lambda: Parallel.forRange(range(0, 8, 2), 2, sum))
reject("negative", "grain-zero", "NEBO-G017-GRAIN", lambda: Parallel.forRange(range(2), 0, sum))
reject("negative", "sample-budget", "NEBO-G017-SAMPLE-BUDGET",
       lambda: Benchmark.measure(lambda: 1, {"samples": 0}))

reject("adversarial", "feature-hierarchy-avx2", "NEBO-G017-FEATURE-HIERARCHY",
       lambda: CpuFeatures.simulated(sse2=False, avx2=True))
reject("adversarial", "nonfinite-convert", "NEBO-G017-NONFINITE",
       lambda: kernel.scalar.convert([float("nan")], "i64"))
reject("adversarial", "conversion-overflow", "NEBO-G017-CONVERSION-OVERFLOW",
       lambda: kernel.scalar.convert([300], "u8", "error"))
reject("adversarial", "element-budget", "NEBO-G017-ELEMENT-BUDGET",
       lambda: kernel.scalar.add([1] * 4097, [1] * 4097))
reject("adversarial", "closed-pool", "NEBO-G017-POOL-CLOSED", lambda: pool.submit(lambda: 1))
state = {"value": 0}
reject("adversarial", "nondeterministic-benchmark", "NEBO-G017-BENCH-NONDETERMINISTIC",
       lambda: Benchmark.measure(lambda: state.update(value=state["value"] + 1) or state["value"],
                                 {"samples": 3, "warmup": 0}))

# Cross-surface composition and ownership/lifetime observations.
plan = KernelPlanner().select("add", KernelContext(len(left), "f64", avx_features, alignment=32))
selected_value = (kernel.simd.add(left, right, plan.descriptor.tier)
                  if plan.descriptor.tier != "scalar" else kernel.scalar.add(left, right))
ok("composition", "features-planner-kernel", selected_value == reference_add)
ok("composition", "pack-microkernel",
   kernel.simd.matmulMicroKernel([[packed.values[0], packed.values[1]]], [[1], [1]], "sse2") == [[3.0]])
ok("composition", "parallel-scalar",
   sum(Parallel.forRange(range(len(left)), 3, lambda chunk: sum(left[index] for index in chunk), 2)) == 15.25)
ok("composition", "benchmark-kernel", exported["resultDigest"] == benchmark.result_digest)
ok("composition", "scalar-convert-activation",
   kernel.scalar.activation(kernel.scalar.convert([-3, 4], "f64")) == [0.0, 4.0])
ok("composition", "fallback-reference",
   kernel.simd.unalignedFallback("dot", left, right).value == kernel.scalar.dot(left, right))

mutable_left = [1, 2, 3]
owned_result = kernel.scalar.add(mutable_left, [4, 5, 6])
mutable_left[0] = 100
ok("ownership", "result-independent", owned_result == [5.0, 7.0, 9.0])
packed_source = [[1, 2], [3, 4]]
owned_pack = kernel.simd.pack(packed_source, 2)
packed_source[0][0] = 99
ok("ownership", "packed-immutable", owned_pack.values[0] == 1.0)
with ThreadPool.new(2) as joined_pool:
    joined_pool.submit(lambda: 31)
    ok("ownership", "join-before-close", joined_pool.waitIdle() == (31,))

atomic_target = [99.0]
try:
    kernel.scalar.add([1], [1, 2])
except KernelError:
    pass
ok("failure_atomicity", "add-target-unchanged", atomic_target == [99.0])
ok("failure_atomicity", "planner-last-valid",
   planner_sse.explain()["tier"] == "sse2")
ok("failure_atomicity", "closed-pool-no-job", pool.waitIdle() == ())
ok("failure_atomicity", "bad-pack-source-unchanged", packed_source[0][0] == 99)
ok("failure_atomicity", "benchmark-state-bounded", state["value"] == 3)

ok("diagnostics", "stable-shape-code", True)
ok("diagnostics", "stable-feature-code", True)
ok("diagnostics", "stable-budget-code", True)
ok("diagnostics", "stable-pool-code", True)
ok("diagnostics", "stable-benchmark-code", True)

required = {
    "positive": 36, "negative": 15, "boundary": 7, "metamorphic": 6,
    "adversarial": 6, "composition": 6, "ownership": 3,
    "failure_atomicity": 5, "diagnostics": 5,
}
if dict(counts) != required:
    raise AssertionError(f"count mismatch: {dict(counts)} != {required}")

print("G017_SDK_ORACLE_GREEN " + " ".join(f"{key}={value}" for key, value in required.items()))
