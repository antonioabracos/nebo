"""Bounded, correctness-first SDK surface for Nebo G017 numeric kernels.

The native runtime remains the execution owner for scalar/SSE2/AVX2 kernels and
the ``neboc bench numeric`` command.  This module exposes the complete current
catalogue vocabulary to SDK consumers and keeps every optimized path paired
with a deterministic scalar oracle.
"""
from __future__ import annotations

from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import statistics
import threading
import time
import tracemalloc
from typing import Any, Callable, Iterable, Sequence


MAX_ELEMENTS = 4096
MAX_DIMENSION = 64
MAX_WORKSPACE_BYTES = 65536
MAX_WORKERS = 8
MAX_BENCH_SAMPLES = 64
MAX_BENCH_WARMUP = 32


class KernelError(ValueError):
    """Stable fail-closed diagnostic raised by the bounded G017 profile."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def _require(condition: bool, code: str) -> None:
    if not condition:
        raise KernelError(code)


def _finite_vector(values: Iterable[int | float], *, allow_nonfinite: bool = True) -> tuple[float, ...]:
    try:
        source = tuple(values)
        _require(not any(isinstance(value, bool) for value in source), "NEBO-G017-NUMERIC-VALUE")
        result = tuple(float(value) for value in source)
    except (TypeError, ValueError, OverflowError) as error:
        raise KernelError("NEBO-G017-NUMERIC-VALUE") from error
    _require(len(result) <= MAX_ELEMENTS, "NEBO-G017-ELEMENT-BUDGET")
    if not allow_nonfinite:
        _require(all(math.isfinite(value) for value in result), "NEBO-G017-NONFINITE")
    return result


def _same_length(left: Sequence[float], right: Sequence[float]) -> None:
    _require(len(left) == len(right), "NEBO-G017-SHAPE-MISMATCH")


@dataclass(frozen=True)
class CacheInfo:
    line_bytes: int
    l1_data_bytes: int
    source: str


@dataclass(frozen=True)
class CpuFeatures:
    _sse2: bool
    _avx2: bool
    _avx512: bool
    _cache: CacheInfo
    _logical_cores: int
    source: str

    @staticmethod
    def detect() -> "CpuFeatures":
        machine = platform.machine().lower()
        flags: set[str] = set()
        cpuinfo = Path("/proc/cpuinfo")
        if cpuinfo.is_file():
            try:
                for line in cpuinfo.read_text(encoding="utf-8", errors="replace").splitlines():
                    if line.lower().startswith(("flags", "features")) and ":" in line:
                        flags.update(line.split(":", 1)[1].strip().lower().split())
            except OSError:
                flags.clear()
        x86_64 = machine in {"x86_64", "amd64"}
        sse2 = x86_64 or "sse2" in flags
        os_vector_state = "xsave" in flags or "osxsave" in flags
        avx2 = "avx" in flags and "avx2" in flags and os_vector_state
        avx512 = avx2 and {"avx512f", "avx512dq", "avx512bw", "avx512vl"}.issubset(flags)
        line_bytes = 64
        l1_bytes = 32768
        source = "bounded-default"
        cache_root = Path("/sys/devices/system/cpu/cpu0/cache")
        if cache_root.is_dir():
            for index in sorted(cache_root.glob("index*")):
                try:
                    if (index / "level").read_text().strip() != "1":
                        continue
                    if (index / "type").read_text().strip().lower() not in {"data", "unified"}:
                        continue
                    line_bytes = int((index / "coherency_line_size").read_text().strip())
                    size_text = (index / "size").read_text().strip().upper()
                    multiplier = 1024 if size_text.endswith("K") else 1
                    l1_bytes = int(size_text.rstrip("K")) * multiplier
                    if line_bytes not in {32, 64, 128}:
                        line_bytes = 64
                    source = "linux-sysfs"
                    break
                except (OSError, ValueError):
                    continue
        cores = os.cpu_count() or 1
        return CpuFeatures(sse2, avx2, avx512, CacheInfo(line_bytes, l1_bytes, source),
                           max(1, min(int(cores), 65536)), "local-detection")

    @staticmethod
    def simulated(*, sse2: bool, avx2: bool, avx512: bool = False,
                  logical_cores: int = 1, cache_line_bytes: int = 64) -> "CpuFeatures":
        _require(all(isinstance(value, bool) for value in (sse2, avx2, avx512)),
                 "NEBO-G017-FEATURE-BOOLEAN")
        _require(1 <= logical_cores <= 65536, "NEBO-G017-CORE-COUNT")
        _require(cache_line_bytes in {32, 64, 128}, "NEBO-G017-CACHE-LINE")
        _require(not avx2 or sse2, "NEBO-G017-FEATURE-HIERARCHY")
        _require(not avx512 or avx2, "NEBO-G017-FEATURE-HIERARCHY")
        return CpuFeatures(sse2, avx2, avx512,
                           CacheInfo(cache_line_bytes, 32768, "simulated"),
                           logical_cores, "simulated")

    def hasSse2(self) -> bool:
        return self._sse2

    def hasAvx2(self) -> bool:
        return self._avx2

    def hasAvx512(self) -> bool:
        return self._avx512

    def cacheInfo(self) -> CacheInfo:
        return self._cache

    def logicalCores(self) -> int:
        return self._logical_cores


class ScalarKernels:
    def add(self, left: Iterable[int | float], right: Iterable[int | float]) -> list[float]:
        a, b = _finite_vector(left), _finite_vector(right)
        _same_length(a, b)
        return [x + y for x, y in zip(a, b)]

    def dot(self, left: Iterable[int | float], right: Iterable[int | float]) -> float:
        a, b = _finite_vector(left), _finite_vector(right)
        _same_length(a, b)
        total = 0.0
        for x, y in zip(a, b):
            total += x * y
        return total

    def matmul(self, left: Sequence[Sequence[int | float]],
               right: Sequence[Sequence[int | float]]) -> list[list[float]]:
        a = tuple(_finite_vector(row) for row in left)
        b = tuple(_finite_vector(row) for row in right)
        _require(bool(a) and bool(b), "NEBO-G017-MATRIX-EMPTY")
        a_cols = len(a[0])
        b_cols = len(b[0])
        _require(a_cols > 0 and b_cols > 0, "NEBO-G017-MATRIX-EMPTY")
        _require(all(len(row) == a_cols for row in a), "NEBO-G017-MATRIX-RAGGED")
        _require(all(len(row) == b_cols for row in b), "NEBO-G017-MATRIX-RAGGED")
        _require(a_cols == len(b), "NEBO-G017-SHAPE-MISMATCH")
        _require(max(len(a), a_cols, b_cols) <= MAX_DIMENSION, "NEBO-G017-DIMENSION-BUDGET")
        result: list[list[float]] = []
        for row in a:
            output_row: list[float] = []
            for column in range(b_cols):
                total = 0.0
                for inner, value in enumerate(row):
                    total += value * b[inner][column]
                output_row.append(total)
            result.append(output_row)
        return result

    def reduceSum(self, values: Iterable[int | float]) -> float:
        total = 0.0
        for value in _finite_vector(values):
            total += value
        return total

    def activation(self, values: Iterable[int | float], name: str = "relu") -> list[float]:
        data = _finite_vector(values)
        if name == "relu":
            return [value if value > 0.0 else 0.0 for value in data]
        if name == "tanh":
            return [math.tanh(value) for value in data]
        if name == "sigmoid":
            result = []
            for value in data:
                if value >= 0.0:
                    result.append(1.0 / (1.0 + math.exp(-value)))
                else:
                    exponential = math.exp(value)
                    result.append(exponential / (1.0 + exponential))
            return result
        raise KernelError("NEBO-G017-ACTIVATION-UNSUPPORTED")

    def convert(self, values: Iterable[int | float], dtype: str = "f64",
                policy: str = "error") -> list[int | float]:
        data = _finite_vector(values, allow_nonfinite=False)
        _require(policy in {"error", "saturate"}, "NEBO-G017-CONVERSION-POLICY")
        if dtype == "f64":
            return list(data)
        bounds = {"i64": (-(1 << 63), (1 << 63) - 1), "u8": (0, 255)}
        _require(dtype in bounds, "NEBO-G017-DTYPE-UNSUPPORTED")
        lower, upper = bounds[dtype]
        result: list[int] = []
        for value in data:
            truncated = math.trunc(value)
            if not lower <= truncated <= upper:
                if policy == "error":
                    raise KernelError("NEBO-G017-CONVERSION-OVERFLOW")
                truncated = min(upper, max(lower, truncated))
            result.append(truncated)
        return result


@dataclass(frozen=True)
class PackedBlock:
    values: tuple[float, ...]
    rows: int
    columns: int
    block: int


@dataclass(frozen=True)
class KernelExecution:
    tier: str
    reason: str
    value: Any


class SimdKernels:
    def __init__(self, scalar: ScalarKernels) -> None:
        self._scalar = scalar

    @staticmethod
    def _width(isa: str) -> int:
        widths = {"sse2": 2, "avx2": 4}
        _require(isa in widths, "NEBO-G017-ISA-UNSUPPORTED")
        return widths[isa]

    def add(self, left: Iterable[int | float], right: Iterable[int | float],
            isa: str = "sse2") -> list[float]:
        width = self._width(isa)
        a, b = _finite_vector(left), _finite_vector(right)
        _same_length(a, b)
        result: list[float] = []
        for start in range(0, len(a), width):
            result.extend(x + y for x, y in zip(a[start:start + width], b[start:start + width]))
        return result

    def dot(self, left: Iterable[int | float], right: Iterable[int | float],
            isa: str = "sse2") -> float:
        width = self._width(isa)
        a, b = _finite_vector(left), _finite_vector(right)
        _same_length(a, b)
        partials = [sum(x * y for x, y in zip(a[start:start + width], b[start:start + width]))
                    for start in range(0, len(a), width)]
        return sum(partials)

    def matmulMicroKernel(self, left: Sequence[Sequence[int | float]],
                          right: Sequence[Sequence[int | float]],
                          isa: str = "sse2") -> list[list[float]]:
        self._width(isa)
        return self._scalar.matmul(left, right)

    def reduceSum(self, values: Iterable[int | float], isa: str = "sse2") -> float:
        width = self._width(isa)
        data = _finite_vector(values)
        return sum(sum(data[start:start + width]) for start in range(0, len(data), width))

    def pack(self, matrix: Sequence[Sequence[int | float]], block: int = 4) -> PackedBlock:
        _require(block in {2, 4, 8}, "NEBO-G017-PACK-BLOCK")
        rows = tuple(_finite_vector(row) for row in matrix)
        _require(bool(rows) and bool(rows[0]), "NEBO-G017-MATRIX-EMPTY")
        columns = len(rows[0])
        _require(all(len(row) == columns for row in rows), "NEBO-G017-MATRIX-RAGGED")
        packed: list[float] = []
        for row_start in range(0, len(rows), block):
            for column_start in range(0, columns, block):
                for row in rows[row_start:row_start + block]:
                    packed.extend(row[column_start:column_start + block])
        return PackedBlock(tuple(packed), len(rows), columns, block)

    def unalignedFallback(self, operation: str, *arguments: Any) -> KernelExecution:
        routes: dict[str, Callable[..., Any]] = {
            "add": self._scalar.add,
            "dot": self._scalar.dot,
            "matmul": self._scalar.matmul,
            "reduceSum": self._scalar.reduceSum,
        }
        _require(operation in routes, "NEBO-G017-OPERATION-UNSUPPORTED")
        return KernelExecution("scalar", "unaligned", routes[operation](*arguments))


@dataclass(frozen=True)
class KernelDescriptor:
    name: str
    operation: str
    tier: str
    dtype: str = "f64"
    minimum_elements: int = 0
    alignment: int = 1
    workspace_bytes: int = 0
    deterministic: bool = True


class KernelRegistry:
    def __init__(self) -> None:
        self._descriptors: list[KernelDescriptor] = []

    @staticmethod
    def default() -> "KernelRegistry":
        registry = KernelRegistry()
        for operation in ("add", "dot", "matmul", "reduceSum", "activation", "convert"):
            dtype = "i64" if operation == "convert" else "f64"
            registry.register(KernelDescriptor(f"scalar.{operation}", operation, "scalar", dtype=dtype))
        for tier, minimum, alignment in (("sse2", 4, 16), ("avx2", 8, 32)):
            for operation in ("add", "dot", "reduceSum"):
                registry.register(KernelDescriptor(f"{tier}.{operation}", operation, tier,
                                                   minimum_elements=minimum, alignment=alignment,
                                                   deterministic=operation == "add"))
        registry.register(KernelDescriptor("avx2.matmul", "matmul", "avx2",
                                           minimum_elements=64, alignment=32,
                                           workspace_bytes=4096, deterministic=False))
        return registry

    def register(self, descriptor: KernelDescriptor | dict[str, Any]) -> KernelDescriptor:
        if isinstance(descriptor, dict):
            try:
                descriptor = KernelDescriptor(**descriptor)
            except TypeError as error:
                raise KernelError("NEBO-G017-DESCRIPTOR") from error
        _require(isinstance(descriptor, KernelDescriptor), "NEBO-G017-DESCRIPTOR")
        _require(bool(descriptor.name) and bool(descriptor.operation), "NEBO-G017-DESCRIPTOR")
        _require(descriptor.tier in {"scalar", "sse2", "avx2", "avx512"},
                 "NEBO-G017-ISA-UNSUPPORTED")
        _require(descriptor.dtype in {"f64", "i64", "u8"}, "NEBO-G017-DTYPE-UNSUPPORTED")
        _require(isinstance(descriptor.minimum_elements, int) and
                 not isinstance(descriptor.minimum_elements, bool) and
                 0 <= descriptor.minimum_elements <= MAX_ELEMENTS,
                 "NEBO-G017-ELEMENT-BUDGET")
        _require(isinstance(descriptor.alignment, int) and
                 not isinstance(descriptor.alignment, bool) and
                 descriptor.alignment > 0 and descriptor.alignment & (descriptor.alignment - 1) == 0,
                 "NEBO-G017-ALIGNMENT")
        _require(isinstance(descriptor.workspace_bytes, int) and
                 not isinstance(descriptor.workspace_bytes, bool), "NEBO-G017-WORKSPACE-BUDGET")
        _require(descriptor.name not in {item.name for item in self._descriptors},
                 "NEBO-G017-DESCRIPTOR-DUPLICATE")
        _require(0 <= descriptor.workspace_bytes <= MAX_WORKSPACE_BYTES,
                 "NEBO-G017-WORKSPACE-BUDGET")
        self._descriptors.append(descriptor)
        return descriptor

    def descriptors(self, operation: str | None = None) -> tuple[KernelDescriptor, ...]:
        return tuple(item for item in self._descriptors
                     if operation is None or item.operation == operation)


@dataclass(frozen=True)
class KernelContext:
    elements: int
    dtype: str
    features: CpuFeatures
    alignment: int = 1
    workspace_limit: int = MAX_WORKSPACE_BYTES
    deterministic: bool = False

    def __post_init__(self) -> None:
        _require(isinstance(self.elements, int) and not isinstance(self.elements, bool),
                 "NEBO-G017-ELEMENT-BUDGET")
        _require(0 <= self.elements <= MAX_ELEMENTS, "NEBO-G017-ELEMENT-BUDGET")
        _require(self.dtype in {"f64", "i64", "u8"}, "NEBO-G017-DTYPE-UNSUPPORTED")
        _require(isinstance(self.alignment, int) and not isinstance(self.alignment, bool),
                 "NEBO-G017-ALIGNMENT")
        _require(self.alignment > 0 and self.alignment & (self.alignment - 1) == 0,
                 "NEBO-G017-ALIGNMENT")
        _require(isinstance(self.workspace_limit, int) and not isinstance(self.workspace_limit, bool) and
                 0 <= self.workspace_limit <= MAX_WORKSPACE_BYTES,
                 "NEBO-G017-WORKSPACE-BUDGET")
        _require(isinstance(self.deterministic, bool), "NEBO-G017-DETERMINISTIC-BOOLEAN")


@dataclass(frozen=True)
class KernelPlan:
    descriptor: KernelDescriptor
    reason: str
    workspace: int
    deterministic: bool

    def workspaceBytes(self) -> int:
        return self.workspace


class KernelPlanner:
    def __init__(self, registry: KernelRegistry | None = None) -> None:
        self.registry = registry or KernelRegistry.default()
        self._deterministic = False
        self._last_plan: KernelPlan | None = None
        self._parallel_threshold = 512

    def select(self, operation: str, context: KernelContext) -> KernelPlan:
        candidates = list(self.registry.descriptors(operation))
        _require(bool(candidates), "NEBO-G017-OPERATION-UNSUPPORTED")
        deterministic = self._deterministic or context.deterministic
        eligible: list[KernelDescriptor] = []
        for item in candidates:
            feature_ok = (item.tier == "scalar" or
                          item.tier == "sse2" and context.features.hasSse2() or
                          item.tier == "avx2" and context.features.hasAvx2() or
                          item.tier == "avx512" and context.features.hasAvx512())
            if (feature_ok and item.dtype == context.dtype and
                    item.minimum_elements <= context.elements and
                    item.alignment <= context.alignment and
                    item.workspace_bytes <= context.workspace_limit and
                    (not deterministic or item.deterministic)):
                eligible.append(item)
        if not eligible:
            return self.fallback(operation, context)
        priority = {"scalar": 0, "sse2": 1, "avx2": 2, "avx512": 3}
        selected = max(eligible, key=lambda item: priority[item.tier])
        reason = "deterministic" if deterministic else ("isa" if selected.tier != "scalar" else "scalar")
        self._last_plan = KernelPlan(selected, reason, selected.workspace_bytes, deterministic)
        return self._last_plan

    def explain(self) -> dict[str, Any]:
        _require(self._last_plan is not None, "NEBO-G017-PLAN-REQUIRED")
        plan = self._last_plan
        return {"kernel": plan.descriptor.name, "tier": plan.descriptor.tier,
                "reason": plan.reason, "workspaceBytes": plan.workspace,
                "deterministic": plan.deterministic}

    def fallback(self, operation: str, context: KernelContext | None = None) -> KernelPlan:
        candidates = [item for item in self.registry.descriptors(operation)
                      if item.tier == "scalar" and (context is None or item.dtype == context.dtype)]
        _require(bool(candidates), "NEBO-G017-FALLBACK-UNAVAILABLE")
        deterministic = self._deterministic or bool(context and context.deterministic)
        self._last_plan = KernelPlan(candidates[0], "fallback", 0, deterministic)
        return self._last_plan

    def workspaceBytes(self) -> int:
        _require(self._last_plan is not None, "NEBO-G017-PLAN-REQUIRED")
        return self._last_plan.workspaceBytes()

    def deterministicMode(self, enabled: bool) -> "KernelPlanner":
        _require(isinstance(enabled, bool), "NEBO-G017-DETERMINISTIC-BOOLEAN")
        self._deterministic = enabled
        return self

    def parallelThreshold(self, elements: int | None = None) -> int:
        if elements is not None:
            _require(1 <= elements <= MAX_ELEMENTS, "NEBO-G017-PARALLEL-THRESHOLD")
            self._parallel_threshold = elements
        return self._parallel_threshold


class ThreadPool:
    def __init__(self, size: int) -> None:
        _require(isinstance(size, int) and not isinstance(size, bool) and 1 <= size <= MAX_WORKERS,
                 "NEBO-G017-WORKER-BUDGET")
        self.size = size
        self._executor = ThreadPoolExecutor(max_workers=size, thread_name_prefix="nebo-g017")
        self._futures: list[Future[Any]] = []
        self._lock = threading.Lock()
        self._closed = False

    @classmethod
    def new(cls, size: int) -> "ThreadPool":
        return cls(size)

    def submit(self, job: Callable[[], Any]) -> Future[Any]:
        _require(not self._closed, "NEBO-G017-POOL-CLOSED")
        _require(callable(job), "NEBO-G017-JOB-CALLABLE")
        future = self._executor.submit(job)
        with self._lock:
            self._futures.append(future)
        return future

    def waitIdle(self) -> tuple[Any, ...]:
        with self._lock:
            pending = tuple(self._futures)
            self._futures.clear()
        return tuple(future.result() for future in pending)

    def close(self) -> None:
        if not self._closed:
            self.waitIdle()
            self._executor.shutdown(wait=True, cancel_futures=False)
            self._closed = True

    def __enter__(self) -> "ThreadPool":
        return self

    def __exit__(self, _type: object, _value: object, _traceback: object) -> None:
        self.close()


class Parallel:
    @staticmethod
    def _chunks(selected: range, grain: int) -> tuple[range, ...]:
        _require(isinstance(selected, range) and selected.step == 1, "NEBO-G017-RANGE")
        _require(isinstance(grain, int) and not isinstance(grain, bool) and grain > 0,
                 "NEBO-G017-GRAIN")
        _require(len(selected) <= MAX_ELEMENTS, "NEBO-G017-ELEMENT-BUDGET")
        return tuple(range(start, min(start + grain, selected.stop))
                     for start in range(selected.start, selected.stop, grain))

    @staticmethod
    def forRange(selected: range, grain: int, callable_: Callable[[range], Any],
                 workers: int | None = None) -> tuple[Any, ...]:
        _require(callable(callable_), "NEBO-G017-JOB-CALLABLE")
        chunks = Parallel._chunks(selected, grain)
        size = workers or min(MAX_WORKERS, max(1, len(chunks)))
        with ThreadPool.new(size) as pool:
            for chunk in chunks:
                pool.submit(lambda chunk=chunk: callable_(chunk))
            return pool.waitIdle()

    @staticmethod
    def reduce(selected: range, identity: Any, combine: Callable[[Any, Any], Any],
               grain: int = 256, workers: int | None = None) -> Any:
        _require(callable(combine), "NEBO-G017-COMBINE-CALLABLE")

        def reduce_chunk(chunk: range) -> Any:
            value = identity
            for item in chunk:
                value = combine(value, item)
            return value

        partials = Parallel.forRange(selected, grain, reduce_chunk, workers)
        value = identity
        for partial in partials:
            value = combine(value, partial)
        return value


@dataclass(frozen=True)
class BenchmarkOptions:
    warmup: int = 2
    samples: int = 5
    units: float = 1.0
    track_allocations: bool = False


@dataclass(frozen=True)
class BenchmarkResult:
    samples_ns: tuple[int, ...]
    warmup: int
    result_digest: str
    allocation_bytes: int
    metadata: dict[str, Any]

    def throughput(self, units: float) -> float:
        _require(math.isfinite(units) and units > 0.0, "NEBO-G017-THROUGHPUT-UNITS")
        median_ns = statistics.median(self.samples_ns)
        return units * 1_000_000_000.0 / median_ns

    def allocations(self) -> dict[str, int]:
        return {"bytes": self.allocation_bytes, "samples": len(self.samples_ns)}

    def compare(self, baseline: "BenchmarkResult", tolerance: float = 0.10) -> dict[str, Any]:
        _require(isinstance(baseline, BenchmarkResult), "NEBO-G017-BASELINE")
        _require(math.isfinite(tolerance) and 0.0 <= tolerance <= 1.0,
                 "NEBO-G017-COMPARE-TOLERANCE")
        current = float(statistics.median(self.samples_ns))
        previous = float(statistics.median(baseline.samples_ns))
        ratio = current / previous
        return {"medianRatio": ratio, "tolerance": tolerance,
                "regression": ratio > 1.0 + tolerance,
                "comparable": self.metadata.get("schema") == baseline.metadata.get("schema")}

    def exportJson(self) -> str:
        payload = {"schema": 1, "samplesNs": list(self.samples_ns), "warmup": self.warmup,
                   "resultDigest": self.result_digest, "allocations": self.allocations(),
                   "metadata": self.metadata}
        return json.dumps(payload, sort_keys=True, separators=(",", ":"))


class Benchmark:
    @staticmethod
    def measure(callable_: Callable[[], Any], options: BenchmarkOptions | dict[str, Any] | None = None) -> BenchmarkResult:
        _require(callable(callable_), "NEBO-G017-BENCH-CALLABLE")
        if options is None:
            options = BenchmarkOptions()
        elif isinstance(options, dict):
            aliases = {"trackAllocations": "track_allocations"}
            normalized = {aliases.get(key, key): value for key, value in options.items()}
            try:
                options = BenchmarkOptions(**normalized)
            except TypeError as error:
                raise KernelError("NEBO-G017-BENCH-OPTIONS") from error
        _require(isinstance(options, BenchmarkOptions), "NEBO-G017-BENCH-OPTIONS")
        _require(isinstance(options.warmup, int) and not isinstance(options.warmup, bool),
                 "NEBO-G017-WARMUP-BUDGET")
        _require(isinstance(options.samples, int) and not isinstance(options.samples, bool),
                 "NEBO-G017-SAMPLE-BUDGET")
        _require(isinstance(options.track_allocations, bool), "NEBO-G017-BENCH-OPTIONS")
        _require(0 <= options.warmup <= MAX_BENCH_WARMUP, "NEBO-G017-WARMUP-BUDGET")
        _require(1 <= options.samples <= MAX_BENCH_SAMPLES, "NEBO-G017-SAMPLE-BUDGET")
        _require(math.isfinite(options.units) and options.units > 0.0, "NEBO-G017-THROUGHPUT-UNITS")
        for _ in range(options.warmup):
            callable_()
        durations: list[int] = []
        digests: list[str] = []
        for _ in range(options.samples):
            started = time.perf_counter_ns()
            value = callable_()
            durations.append(max(1, time.perf_counter_ns() - started))
            digests.append(hashlib.sha256(repr(value).encode("utf-8")).hexdigest())
        _require(len(set(digests)) == 1, "NEBO-G017-BENCH-NONDETERMINISTIC")
        allocation_bytes = 0
        if options.track_allocations:
            tracemalloc.start()
            before = tracemalloc.take_snapshot()
            callable_()
            after = tracemalloc.take_snapshot()
            allocation_bytes = max(0, sum(item.size_diff for item in after.compare_to(before, "lineno")))
            tracemalloc.stop()
        features = CpuFeatures.detect()
        metadata = {"schema": 1, "clock": "perf_counter_ns", "samples": options.samples,
                    "units": options.units, "target": platform.machine().lower(),
                    "python": platform.python_version(), "logicalCores": features.logicalCores(),
                    "cacheLineBytes": features.cacheInfo().line_bytes,
                    "descriptiveOnly": True, "superiorityClaim": False}
        return BenchmarkResult(tuple(durations), options.warmup, digests[0], allocation_bytes, metadata)


class KernelNamespace:
    def __init__(self) -> None:
        self.scalar = ScalarKernels()
        self.simd = SimdKernels(self.scalar)


kernel = KernelNamespace()
planner = KernelPlanner()


__all__ = [
    "Benchmark", "BenchmarkOptions", "BenchmarkResult", "CacheInfo", "CpuFeatures",
    "KernelContext", "KernelDescriptor", "KernelError", "KernelExecution", "KernelPlan",
    "KernelPlanner", "KernelRegistry", "PackedBlock", "Parallel", "ThreadPool", "kernel",
    "planner",
]
