"""Truthful, bounded GPU API profile for Nebo G022.

No physical GPU, driver, or vendor toolchain is authenticated by this source
tree.  ``Gpu.enumerate`` therefore reports no hardware devices and physical
context creation fails closed.  The separate ``CpuReference`` device executes
the same public lifecycle, transfer, kernel, stream, planner, and profiling
contracts for differential correctness.  It is always labelled
``accelerated=False`` and must never be presented as a GPU benchmark.

The historical x86_64 runtime under ``runtime/gpu`` remains the native owner
of the zero-device and explicit CPU-fallback ABI.  This module supplies the
current catalogue vocabulary without adding an external dependency or an
unsafe JIT path.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import math
import struct
from types import MappingProxyType
from typing import Any, Callable, Mapping, MutableSequence, Sequence

from compiler.sdk.ml_inference import Tensor as HostTensor


MAX_CONTEXT_BYTES = 1_048_576
DEFAULT_CONTEXT_BYTES = 262_144
MAX_BUFFER_BYTES = 262_144
MAX_PINNED_BYTES = 262_144
MAX_STREAMS = 32
MAX_PENDING_COMMANDS = 256
MAX_LAUNCH_DIMENSION = 65_535
MAX_LAUNCH_WORK_ITEMS = 1_048_576
MAX_TRACE_EVENTS = 512


class GpuError(RuntimeError):
    """Stable fail-closed error with catalogue accessors."""

    def __init__(self, code: str, operation: str) -> None:
        super().__init__(f"{code}:{operation}")
        self._stable_code = code
        self._stable_operation = operation

    def code(self) -> str:
        return self._stable_code

    def operation(self) -> str:
        return self._stable_operation


def _require(condition: bool, code: str, operation: str) -> None:
    if not condition:
        raise GpuError(code, operation)


def _canonical(value: Any) -> bytes:
    try:
        return json.dumps(value, sort_keys=True, separators=(",", ":"),
                          ensure_ascii=True, allow_nan=False).encode("ascii")
    except (TypeError, ValueError, OverflowError) as error:
        raise GpuError("NEBO-G022-SERIALIZATION", "canonicalize") from error


def _positive_size(value: int, maximum: int, operation: str) -> int:
    _require(isinstance(value, int) and not isinstance(value, bool),
             "NEBO-G022-SIZE", operation)
    _require(0 < value <= maximum, "NEBO-G022-BUDGET", operation)
    return value


def _launch_shape(value: Sequence[int], operation: str) -> tuple[int, ...]:
    try:
        result = tuple(value)
    except TypeError as error:
        raise GpuError("NEBO-G022-LAUNCH-SHAPE", operation) from error
    _require(1 <= len(result) <= 3, "NEBO-G022-LAUNCH-RANK", operation)
    total = 1
    for dimension in result:
        _require(isinstance(dimension, int) and not isinstance(dimension, bool)
                 and 1 <= dimension <= MAX_LAUNCH_DIMENSION,
                 "NEBO-G022-LAUNCH-SHAPE", operation)
        total *= dimension
        _require(total <= MAX_LAUNCH_WORK_ITEMS,
                 "NEBO-G022-LAUNCH-BUDGET", operation)
    return result


@dataclass(frozen=True)
class GpuDevice:
    identifier: str
    name: str
    backend: str
    kind: str
    accelerated: bool
    total_memory: int
    features: tuple[str, ...]
    driver_contract: str
    license: str
    target: str

    def properties(self) -> Mapping[str, Any]:
        return MappingProxyType({
            "accelerated": self.accelerated,
            "backend": self.backend,
            "deviceId": self.identifier,
            "driverContract": self.driver_contract,
            "features": self.features,
            "kind": self.kind,
            "license": self.license,
            "name": self.name,
            "target": self.target,
            "timing": "logical-work-units" if not self.accelerated else "device",
            "totalMemory": self.total_memory,
        })


_CPU_REFERENCE_DEVICE = GpuDevice(
    identifier="cpu-reference-0",
    name="Nebo CPU differential reference",
    backend="cpu-reference",
    kind="cpu-reference",
    accelerated=False,
    total_memory=MAX_CONTEXT_BYTES,
    features=("f64", "ordered-streams", "verified-static-kernels"),
    driver_contract="none",
    license="Nebo repository license; no vendor SDK",
    target="x86_64-systemv-elf-linux",
)


class CpuReference:
    """Explicit correctness backend; never a physical GPU claim."""

    @staticmethod
    def device() -> GpuDevice:
        return _CPU_REFERENCE_DEVICE


class Gpu:
    @staticmethod
    def enumerate() -> tuple[GpuDevice, ...]:
        """Return authenticated physical GPU devices (none in this profile)."""
        return ()


class GpuContext:
    def __init__(self, device: GpuDevice, memory_budget: int) -> None:
        self._device = device
        self._memory_budget = memory_budget
        self._memory_used = 0
        self._buffers: set[DeviceBuffer] = set()
        self._streams: list[GpuStream] = []
        self._closed = False
        self._logical_clock = 0

    @staticmethod
    def create(device: GpuDevice, options: Mapping[str, Any] | None = None) -> "GpuContext":
        operation = "GpuContext.create"
        _require(isinstance(device, GpuDevice), "NEBO-G022-DEVICE", operation)
        _require(device == _CPU_REFERENCE_DEVICE,
                 "NEBO-G022-PHYSICAL-BACKEND-UNAVAILABLE", operation)
        options = {} if options is None else options
        _require(isinstance(options, Mapping), "NEBO-G022-OPTIONS", operation)
        unknown = set(options) - {"memoryBudget"}
        _require(not unknown, "NEBO-G022-OPTION", operation)
        budget = options.get("memoryBudget", DEFAULT_CONTEXT_BYTES)
        _positive_size(budget, MAX_CONTEXT_BYTES, operation)
        return GpuContext(device, budget)

    def _live(self, operation: str) -> None:
        _require(not self._closed, "NEBO-G022-CONTEXT-CLOSED", operation)

    def _tick(self, event: str, details: Mapping[str, Any]) -> int:
        self._logical_clock += 1
        GpuProfiler._record(event, self, self._logical_clock, details)
        return self._logical_clock

    def _reserve(self, size: int) -> None:
        self._live("DeviceBuffer.allocate")
        _require(self._memory_used + size <= self._memory_budget,
                 "NEBO-G022-MEMORY-BUDGET", "DeviceBuffer.allocate")
        self._memory_used += size

    def _release(self, size: int) -> None:
        self._memory_used -= size
        _require(self._memory_used >= 0, "NEBO-G022-MEMORY-ACCOUNTING",
                 "DeviceBuffer.close")

    def _register_stream(self, stream: "GpuStream") -> None:
        self._live("GpuStream.create")
        _require(len(self._streams) < MAX_STREAMS,
                 "NEBO-G022-STREAM-BUDGET", "GpuStream.create")
        self._streams.append(stream)

    def device(self) -> GpuDevice:
        self._live("context.device")
        return self._device

    def synchronize(self) -> int:
        self._live("context.synchronize")
        completed = 0
        for stream in tuple(self._streams):
            completed += stream.synchronize()
        self._tick("context.synchronize", {"commands": completed})
        return completed

    def close(self) -> int:
        if self._closed:
            return 0
        completed = 0
        failure: GpuError | None = None
        try:
            completed = self.synchronize()
        except GpuError as error:
            failure = error
        finally:
            for buffer in tuple(self._buffers):
                buffer.close()
            self._streams.clear()
            self._closed = True
        if failure is not None:
            raise failure
        return completed

    def memoryUsed(self) -> int:
        self._live("context.memoryUsed")
        return self._memory_used

    def setMemoryBudget(self, bytes: int) -> int:
        operation = "context.setMemoryBudget"
        self._live(operation)
        size = _positive_size(bytes, MAX_CONTEXT_BYTES, operation)
        _require(size >= self._memory_used,
                 "NEBO-G022-MEMORY-IN-USE", operation)
        self._memory_budget = size
        self._tick("context.memory-budget", {"bytes": size})
        return size


class DeviceBuffer:
    def __init__(self, context: GpuContext, size: int) -> None:
        self._context = context
        self._size = size
        self._data = bytearray(size)
        self._closed = False

    @staticmethod
    def allocate(context: GpuContext, bytes: int) -> "DeviceBuffer":
        operation = "DeviceBuffer.allocate"
        _require(isinstance(context, GpuContext), "NEBO-G022-CONTEXT", operation)
        size = _positive_size(bytes, MAX_BUFFER_BYTES, operation)
        context._reserve(size)
        try:
            result = DeviceBuffer(context, size)
        except BaseException:
            context._release(size)
            raise
        context._buffers.add(result)
        context._tick("buffer.allocate", {"bytes": size})
        return result

    @property
    def nbytes(self) -> int:
        return self._size

    def _live(self, operation: str) -> None:
        self._context._live(operation)
        _require(not self._closed, "NEBO-G022-BUFFER-CLOSED", operation)

    def upload(self, hostBytes: bytes | bytearray | memoryview) -> int:
        operation = "buffer.upload"
        self._live(operation)
        try:
            source = bytes(hostBytes)
        except (TypeError, ValueError) as error:
            raise GpuError("NEBO-G022-HOST-BUFFER", operation) from error
        _require(len(source) == self._size, "NEBO-G022-TRANSFER-SIZE", operation)
        self._data[:] = source
        self._context._tick("buffer.upload", {"bytes": self._size})
        return self._size

    def download(self, hostBuffer: MutableSequence[int] | memoryview) -> int:
        operation = "buffer.download"
        self._live(operation)
        _require(not isinstance(hostBuffer, bytes), "NEBO-G022-HOST-BUFFER", operation)
        try:
            length = len(hostBuffer)
        except TypeError as error:
            raise GpuError("NEBO-G022-HOST-BUFFER", operation) from error
        _require(length == self._size, "NEBO-G022-TRANSFER-SIZE", operation)
        try:
            hostBuffer[:] = self._data
        except (TypeError, ValueError) as error:
            raise GpuError("NEBO-G022-HOST-BUFFER", operation) from error
        self._context._tick("buffer.download", {"bytes": self._size})
        return self._size

    def copyTo(self, other: "DeviceBuffer") -> int:
        operation = "buffer.copyTo"
        self._live(operation)
        _require(isinstance(other, DeviceBuffer), "NEBO-G022-BUFFER", operation)
        other._live(operation)
        _require(other._context is self._context,
                 "NEBO-G022-CONTEXT-MISMATCH", operation)
        _require(other._size == self._size, "NEBO-G022-TRANSFER-SIZE", operation)
        other._data[:] = self._data
        self._context._tick("buffer.copy", {"bytes": self._size})
        return self._size

    def close(self) -> int:
        if self._closed:
            return 0
        size = self._size
        self._data[:] = b"\x00" * size
        self._closed = True
        self._context._buffers.discard(self)
        self._context._release(size)
        return size


@dataclass
class PinnedMemory:
    data: bytearray
    pinned: bool
    fallback: str


class _Memory:
    def pinned(self, length: int) -> PinnedMemory:
        size = _positive_size(length, MAX_PINNED_BYTES, "memory.pinned")
        return PinnedMemory(bytearray(size), False,
                            "page-locking unavailable; ordinary owned host memory")


memory = _Memory()


def _tensor_bytes(tensor: HostTensor) -> bytes:
    if tensor.dtype == "f64":
        return struct.pack("<" + "d" * tensor.elements,
                           *(float(value) for value in tensor.values))
    return bytes((int(value) & 0xFF for value in tensor.values))


class GpuTensor:
    """Tensor placement wrapper shared by reference transfer and planner tests."""

    def __init__(self, host: HostTensor, context: GpuContext | None = None,
                 buffer: DeviceBuffer | None = None, owns_context: bool = False) -> None:
        _require(isinstance(host, HostTensor), "NEBO-G022-TENSOR", "GpuTensor")
        self.host = host
        self._context = context
        self._buffer = buffer
        self._owns_context = owns_context

    @staticmethod
    def fromHost(tensor: HostTensor) -> "GpuTensor":
        return GpuTensor(tensor)

    def toDevice(self, device: GpuDevice) -> "GpuTensor":
        operation = "tensor.toDevice"
        _require(self._context is None, "NEBO-G022-TENSOR-PLACEMENT", operation)
        payload = _tensor_bytes(self.host)
        context = GpuContext.create(device, {"memoryBudget": max(len(payload), 1)})
        buffer = DeviceBuffer.allocate(context, len(payload))
        buffer.upload(payload)
        return GpuTensor(self.host, context, buffer, True)

    def toHost(self) -> "GpuTensor":
        operation = "tensor.toHost"
        _require(self._context is not None and self._buffer is not None,
                 "NEBO-G022-TENSOR-PLACEMENT", operation)
        payload = bytearray(self._buffer.nbytes)
        self._buffer.download(payload)
        if self.host.dtype == "f64":
            values = struct.unpack("<" + "d" * self.host.elements, payload)
            restored = HostTensor(values, self.host.shape, "f64")
        else:
            params = self.host.quantization
            values = tuple(value if value < 128 else value - 256 for value in payload)
            restored = HostTensor(values, self.host.shape, "i8", params)
        return GpuTensor(restored)

    def device(self) -> GpuDevice | None:
        return self._context.device() if self._context is not None else None

    @property
    def nbytes(self) -> int:
        return self.host.nbytes

    def close(self) -> int:
        if self._owns_context and self._context is not None:
            result = self._context.close()
            self._context = None
            self._buffer = None
            return result
        return 0


_STATIC_MODULE_TOKEN = object()


class GpuModule:
    """Verified static reference module; arbitrary source/JIT is excluded."""

    def __init__(self, name: str,
                 kernels: Mapping[str, Callable[[tuple[Any, ...]], None]],
                 signatures: Mapping[str, Sequence[str]],
                 features: Mapping[str, Sequence[str]], *, _token: object | None = None) -> None:
        _require(_token is _STATIC_MODULE_TOKEN,
                 "NEBO-G022-ARBITRARY-MODULE", "GpuModule")
        _require(isinstance(name, str) and 1 <= len(name) <= 64,
                 "NEBO-G022-MODULE-NAME", "GpuModule")
        _require(1 <= len(kernels) <= 16 and set(kernels) == set(signatures) == set(features),
                 "NEBO-G022-MODULE-MANIFEST", "GpuModule")
        self.name = name
        self._kernels = MappingProxyType(dict(kernels))
        self._signatures = MappingProxyType(
            {key: tuple(value) for key, value in signatures.items()})
        self._features = MappingProxyType(
            {key: tuple(value) for key, value in features.items()})
        self._manifest = {
            "backend": "cpu-reference",
            "kernels": {key: {"features": list(self._features[key]),
                               "signature": list(self._signatures[key])}
                        for key in sorted(self._kernels)},
            "name": name,
            "schema": 1,
        }
        self._digest = hashlib.sha256(_canonical(self._manifest)).hexdigest()

    @staticmethod
    def vectorModule() -> "GpuModule":
        def vector_add(arguments: tuple[Any, ...]) -> None:
            left, right, output = arguments
            _require(all(isinstance(value, DeviceBuffer) for value in arguments),
                     "NEBO-G022-KERNEL-ARGUMENT", "vector_add")
            _require(left.nbytes == right.nbytes == output.nbytes and left.nbytes % 8 == 0,
                     "NEBO-G022-KERNEL-SHAPE", "vector_add")
            count = left.nbytes // 8
            lhs = struct.unpack("<" + "d" * count, left._data)
            rhs = struct.unpack("<" + "d" * count, right._data)
            values = tuple(a + b for a, b in zip(lhs, rhs))
            _require(all(math.isfinite(value) for value in values),
                     "NEBO-G022-NONFINITE", "vector_add")
            output._data[:] = struct.pack("<" + "d" * count, *values)

        def scale(arguments: tuple[Any, ...]) -> None:
            source, factor, output = arguments
            _require(isinstance(source, DeviceBuffer) and isinstance(output, DeviceBuffer)
                     and isinstance(factor, (int, float)) and not isinstance(factor, bool),
                     "NEBO-G022-KERNEL-ARGUMENT", "scale")
            _require(source.nbytes == output.nbytes and source.nbytes % 8 == 0,
                     "NEBO-G022-KERNEL-SHAPE", "scale")
            factor_value = float(factor)
            _require(math.isfinite(factor_value), "NEBO-G022-NONFINITE", "scale")
            count = source.nbytes // 8
            values = struct.unpack("<" + "d" * count, source._data)
            result = tuple(value * factor_value for value in values)
            _require(all(math.isfinite(value) for value in result),
                     "NEBO-G022-NONFINITE", "scale")
            output._data[:] = struct.pack("<" + "d" * count, *result)

        return GpuModule(
            "nebo.reference.vector.v1",
            {"scale": scale, "vector_add": vector_add},
            {"scale": ("buffer", "scalar", "buffer"),
             "vector_add": ("buffer", "buffer", "buffer")},
            {"scale": ("f64",), "vector_add": ("f64",)},
            _token=_STATIC_MODULE_TOKEN,
        )

    def cacheKey(self) -> str:
        return self._digest

    def verify(self) -> bool:
        operation = "module.verify"
        _require(hashlib.sha256(_canonical(self._manifest)).hexdigest() == self._digest,
                 "NEBO-G022-MODULE-INTEGRITY", operation)
        _require(all(callable(value) for value in self._kernels.values()),
                 "NEBO-G022-MODULE-KERNEL", operation)
        return True


@dataclass(frozen=True)
class LaunchReceipt:
    stream_id: int
    sequence: int
    grid: tuple[int, ...]
    block: tuple[int, ...]


class GpuKernel:
    def __init__(self, module: GpuModule, name: str,
                 arguments: tuple[Any, ...] | None = None) -> None:
        self._module = module
        self._name = name
        self._arguments = arguments

    @staticmethod
    def load(module: GpuModule, name: str) -> "GpuKernel":
        operation = "GpuKernel.load"
        _require(isinstance(module, GpuModule), "NEBO-G022-MODULE", operation)
        module.verify()
        _require(name in module._kernels, "NEBO-G022-KERNEL-NAME", operation)
        return GpuKernel(module, name)

    def signature(self) -> tuple[str, ...]:
        return self._module._signatures[self._name]

    def bind(self, arguments: Sequence[Any]) -> "GpuKernel":
        operation = "kernel.bind"
        try:
            bound = tuple(arguments)
        except TypeError as error:
            raise GpuError("NEBO-G022-KERNEL-ARGUMENT", operation) from error
        signature = self.signature()
        _require(len(bound) == len(signature), "NEBO-G022-KERNEL-ARITY", operation)
        contexts = set()
        for expected, value in zip(signature, bound):
            if expected == "buffer":
                _require(isinstance(value, DeviceBuffer),
                         "NEBO-G022-KERNEL-ARGUMENT", operation)
                value._live(operation)
                contexts.add(value._context)
            else:
                _require(isinstance(value, (int, float)) and not isinstance(value, bool)
                         and math.isfinite(float(value)),
                         "NEBO-G022-KERNEL-ARGUMENT", operation)
        _require(len(contexts) <= 1, "NEBO-G022-CONTEXT-MISMATCH", operation)
        return GpuKernel(self._module, self._name, bound)

    def launch(self, grid: Sequence[int], block: Sequence[int],
               stream: "GpuStream") -> LaunchReceipt:
        operation = "kernel.launch"
        self._module.verify()
        _require(self._arguments is not None, "NEBO-G022-KERNEL-UNBOUND", operation)
        _require(isinstance(stream, GpuStream), "NEBO-G022-STREAM", operation)
        stream._live(operation)
        grid_value = _launch_shape(grid, operation)
        block_value = _launch_shape(block, operation)
        _require(math.prod(grid_value) * math.prod(block_value) <= MAX_LAUNCH_WORK_ITEMS,
                 "NEBO-G022-LAUNCH-BUDGET", operation)
        for argument in self._arguments:
            if isinstance(argument, DeviceBuffer):
                _require(argument._context is stream._context,
                         "NEBO-G022-CONTEXT-MISMATCH", operation)
        command = lambda: self._module._kernels[self._name](self._arguments or ())
        sequence = stream._enqueue(self._name, command)
        return LaunchReceipt(stream.identifier, sequence, grid_value, block_value)

    def requiredFeatures(self) -> tuple[str, ...]:
        return self._module._features[self._name]


class GpuEvent:
    def __init__(self, stream: "GpuStream", sequence: int) -> None:
        self._stream = stream
        self._sequence = sequence
        self._completed_tick: int | None = None

    def wait(self) -> int:
        self._stream._synchronize_to(self._sequence)
        _require(self._completed_tick is not None,
                 "NEBO-G022-EVENT-INCOMPLETE", "event.wait")
        return self._completed_tick

    def elapsed(self, other: "GpuEvent") -> int:
        operation = "event.elapsed"
        _require(isinstance(other, GpuEvent), "NEBO-G022-EVENT", operation)
        _require(other._stream._context is self._stream._context,
                 "NEBO-G022-CONTEXT-MISMATCH", operation)
        left = self.wait()
        right = other.wait()
        return abs(right - left)


class GpuStream:
    _next_identifier = 1

    def __init__(self, context: GpuContext) -> None:
        self._context = context
        self.identifier = GpuStream._next_identifier
        GpuStream._next_identifier += 1
        self._next_sequence = 0
        self._completed_sequence = 0
        self._commands: list[tuple[int, str, Callable[[], None], GpuEvent | None]] = []
        self._waits_for: set[GpuStream] = set()
        self._closed = False

    @staticmethod
    def create(context: GpuContext) -> "GpuStream":
        _require(isinstance(context, GpuContext),
                 "NEBO-G022-CONTEXT", "GpuStream.create")
        result = GpuStream(context)
        context._register_stream(result)
        context._tick("stream.create", {"stream": result.identifier})
        return result

    def _live(self, operation: str) -> None:
        self._context._live(operation)
        _require(not self._closed, "NEBO-G022-STREAM-CLOSED", operation)

    def _enqueue(self, label: str, command: Callable[[], None],
                 event: GpuEvent | None = None) -> int:
        self._live("stream.enqueue")
        _require(len(self._commands) < MAX_PENDING_COMMANDS,
                 "NEBO-G022-COMMAND-BUDGET", "stream.enqueue")
        self._next_sequence += 1
        self._commands.append((self._next_sequence, label, command, event))
        return self._next_sequence

    def recordEvent(self) -> GpuEvent:
        self._live("stream.recordEvent")
        event = GpuEvent(self, self._next_sequence + 1)
        self._enqueue("event.record", lambda: None, event)
        return event

    def wait(self, event: GpuEvent) -> int:
        operation = "stream.wait"
        self._live(operation)
        _require(isinstance(event, GpuEvent), "NEBO-G022-EVENT", operation)
        _require(event._stream._context is self._context,
                 "NEBO-G022-CONTEXT-MISMATCH", operation)
        dependency = event._stream
        if dependency is self:
            return self._enqueue("event.wait", event.wait)
        _require(not dependency._depends_on(self, set()),
                 "NEBO-G022-DEPENDENCY-CYCLE", operation)
        self._waits_for.add(dependency)

        def wait_for_dependency() -> None:
            try:
                event.wait()
            finally:
                self._waits_for.discard(dependency)

        return self._enqueue("event.wait", wait_for_dependency)

    def _depends_on(self, target: "GpuStream", visited: set[int]) -> bool:
        if self is target:
            return True
        identity = id(self)
        if identity in visited:
            return False
        visited.add(identity)
        return any(dependency._depends_on(target, visited)
                   for dependency in self._waits_for)

    def _synchronize_to(self, target: int | None) -> int:
        self._live("stream.synchronize")
        completed = 0
        while self._commands and (target is None or self._completed_sequence < target):
            sequence, label, command, event = self._commands[0]
            try:
                command()
            except GpuError:
                self._commands.pop(0)
                self._completed_sequence = sequence
                self._context._tick("command.error", {"label": label,
                                                        "stream": self.identifier})
                raise
            self._commands.pop(0)
            self._completed_sequence = sequence
            tick = self._context._tick("command.complete", {"label": label,
                                                              "stream": self.identifier})
            if event is not None:
                event._completed_tick = tick
            completed += 1
        return completed

    def synchronize(self) -> int:
        return self._synchronize_to(None)


@dataclass(frozen=True)
class GpuOperation:
    name: str
    bytes: int
    cpu_reference: Callable[[], Any]
    reference_supported: bool = True

    def __post_init__(self) -> None:
        _require(isinstance(self.name, str) and 1 <= len(self.name) <= 64,
                 "NEBO-G022-OPERATION", "GpuOperation")
        _positive_size(self.bytes, MAX_CONTEXT_BYTES, "GpuOperation")
        _require(callable(self.cpu_reference), "NEBO-G022-CPU-REFERENCE", "GpuOperation")

    def supportedOn(self, device: GpuDevice) -> bool:
        return device == _CPU_REFERENCE_DEVICE and self.reference_supported


class GpuPlanner:
    def __init__(self) -> None:
        self._operation: GpuOperation | None = None
        self._selection: GpuDevice | None = None
        self._plan: Mapping[str, Any] | None = None

    def selectDevice(self, operation: GpuOperation,
                     context: GpuContext) -> GpuDevice | None:
        route = "planner.selectDevice"
        _require(isinstance(operation, GpuOperation), "NEBO-G022-OPERATION", route)
        _require(isinstance(context, GpuContext), "NEBO-G022-CONTEXT", route)
        device = context.device()
        selected = device if operation.supportedOn(device) else None
        self._operation = operation
        self._selection = selected
        self._plan = MappingProxyType({
            "accelerated": False,
            "backend": selected.backend if selected is not None else "cpu-fallback",
            "bytes": operation.bytes,
            "deviceTransfers": 0 if selected is not None else 0,
            "reason": "cpu differential reference" if selected is not None
                      else "operation unsupported by reference backend",
        })
        return selected

    def transferPlan(self) -> Mapping[str, Any]:
        _require(self._plan is not None, "NEBO-G022-PLANNER-EMPTY",
                 "planner.transferPlan")
        return self._plan

    def fallbackToCpu(self) -> Any:
        _require(self._operation is not None, "NEBO-G022-PLANNER-EMPTY",
                 "planner.fallbackToCpu")
        return self._operation.cpu_reference()


class GpuSession:
    def __init__(self) -> None:
        self._device: GpuDevice | None = None

    def pinDevice(self, device: GpuDevice) -> GpuDevice:
        _require(device == _CPU_REFERENCE_DEVICE,
                 "NEBO-G022-PHYSICAL-BACKEND-UNAVAILABLE", "session.pinDevice")
        self._device = device
        return device


class GpuProfiler:
    _active: "GpuProfiler | None" = None

    def __init__(self) -> None:
        self._events: list[Mapping[str, Any]] = []
        self._running = True
        self._stopped = False
        self._truncated = False

    @staticmethod
    def start() -> "GpuProfiler":
        _require(GpuProfiler._active is None,
                 "NEBO-G022-PROFILER-ACTIVE", "GpuProfiler.start")
        result = GpuProfiler()
        GpuProfiler._active = result
        return result

    @staticmethod
    def _record(event: str, context: GpuContext, tick: int,
                details: Mapping[str, Any]) -> None:
        active = GpuProfiler._active
        if active is None or not active._running:
            return
        if len(active._events) >= MAX_TRACE_EVENTS:
            active._truncated = True
            return
        active._events.append(MappingProxyType({
            "accelerated": False,
            "backend": context._device.backend,
            "details": dict(details),
            "event": event,
            "tick": tick,
        }))

    def stop(self) -> int:
        _require(self._running, "NEBO-G022-PROFILER-STOPPED", "profiler.stop")
        self._running = False
        self._stopped = True
        if GpuProfiler._active is self:
            GpuProfiler._active = None
        return len(self._events)

    def exportTrace(self) -> str:
        _require(self._stopped, "NEBO-G022-PROFILER-RUNNING",
                 "profiler.exportTrace")
        return _canonical({
            "events": [dict(event) for event in self._events],
            "schema": "nebo-g022-logical-trace-v1",
            "timing": "logical-work-units-not-benchmark-time",
            "truncated": self._truncated,
        }).decode("ascii")


REFERENCE_BACKEND_CONTRACT = MappingProxyType({
    "accelerated": False,
    "backend": "cpu-reference",
    "driver": "none",
    "hardwareEnumeration": "empty",
    "license": "repository-only; no vendor SDK",
    "physicalGpuCertified": False,
    "target": "x86_64-systemv-elf-linux",
})
