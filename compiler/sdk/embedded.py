"""Bounded, simulator-only reference SDK for the current G038 contract.

The module deliberately does not access physical memory, clocks, devices, or
the network.  Every hardware-facing operation requires an explicit capability
owned by a ``HardwareSimulator``.  Reports say ``SIMULATOR_ONLY`` and never
turn measured simulator behaviour into a hard-real-time claim.
"""
from __future__ import annotations

import builtins
from dataclasses import dataclass
import hashlib
import json
from types import MappingProxyType
from typing import Any, Callable, Generic, Iterable, Mapping, TypeVar


BOARD_ID = "NEBO_REFERENCE_BOARD_SIM_V1"
TARGET_TRIPLE = "x86_64-nebo-reference-none"
MAX_IMAGE_BYTES = 262_144
MAX_TRANSFER_BYTES = 4_096
MAX_TRACE_EVENTS = 4_096
MAX_TASKS = 32
ALLOWED_FENCES = frozenset(("acquire", "release", "acq-rel", "seq-cst"))


class EmbeddedError(RuntimeError):
    """Stable fail-closed G038 diagnostic."""

    def __init__(self, suffix: str, operation: str):
        self._code = f"NEBO-G038-{suffix}"
        self._operation = operation
        super().__init__(f"{self._code}: {operation}")

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _reject(condition: bool, suffix: str, operation: str) -> None:
    if condition:
        raise EmbeddedError(suffix, operation)


def _positive_int(value: Any, suffix: str, operation: str, maximum: int = 2**63 - 1) -> int:
    _reject(isinstance(value, bool) or not isinstance(value, int) or value <= 0 or value > maximum,
            suffix, operation)
    return value


def _nonnegative_int(value: Any, suffix: str, operation: str, maximum: int = 2**63 - 1) -> int:
    _reject(isinstance(value, bool) or not isinstance(value, int) or value < 0 or value > maximum,
            suffix, operation)
    return value


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(item) for key, item in value.items()})
    if isinstance(value, (list, tuple)):
        return tuple(_freeze(item) for item in value)
    return value


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


@dataclass(frozen=True)
class Board:
    id: str
    cpu: Mapping[str, Any]
    memory: Mapping[str, Any]
    peripherals: Mapping[str, Any]
    vectors: int
    claims: Mapping[str, bool]

    @staticmethod
    def define(spec: Mapping[str, Any]) -> "Board":
        operation = "Board.define"
        _reject(not isinstance(spec, Mapping), "BOARD-SPEC", operation)
        required = {"id", "cpu", "memory", "peripherals", "vectors", "claims"}
        _reject(set(spec) != required, "BOARD-SPEC", operation)
        _reject(spec["id"] != BOARD_ID, "UNSUPPORTED-BOARD", operation)
        cpu = spec["cpu"]
        memory = spec["memory"]
        claims = spec["claims"]
        _reject(not isinstance(cpu, Mapping) or cpu.get("architecture") != "x86_64"
                or cpu.get("endianness") != "little"
                or _positive_int(cpu.get("clockHz"), "BOARD-SPEC", operation) != 10_000_000,
                "BOARD-SPEC", operation)
        _reject(not isinstance(memory, Mapping) or set(memory) != {"rom", "ram", "stackAlignment"},
                "MEMORY-MAP", operation)
        regions: list[tuple[int, int, str]] = []
        for name in ("rom", "ram"):
            region = memory[name]
            _reject(not isinstance(region, Mapping), "MEMORY-MAP", operation)
            origin = _nonnegative_int(region.get("origin"), "MEMORY-MAP", operation)
            length = _positive_int(region.get("bytes"), "MEMORY-MAP", operation, MAX_IMAGE_BYTES)
            _reject(origin % 4096 != 0, "MEMORY-MAP", operation)
            regions.append((origin, origin + length, name))
        _reject(max(regions[0][0], regions[1][0]) < min(regions[0][1], regions[1][1]),
                "MEMORY-OVERLAP", operation)
        _reject(_positive_int(memory["stackAlignment"], "MEMORY-MAP", operation) not in (8, 16, 32),
                "MEMORY-MAP", operation)
        peripherals = spec["peripherals"]
        _reject(not isinstance(peripherals, Mapping)
                or set(peripherals) != {"gpio", "spi", "i2c", "uart", "timer", "watchdog"},
                "PERIPHERALS", operation)
        addresses = tuple(peripherals.values())
        _reject(any(isinstance(address, bool) or not isinstance(address, int)
                    or address < 0 or address % 4096 for address in addresses)
                or len(set(addresses)) != len(addresses), "PERIPHERALS", operation)
        vectors = _positive_int(spec["vectors"], "VECTORS", operation, 256)
        _reject(not isinstance(claims, Mapping)
                or set(claims) != {"physicalBoard", "hardRealTime", "secureBoot"}
                or any(value is not False for value in claims.values()), "CLAIMS", operation)
        return Board(BOARD_ID, _freeze(cpu), _freeze(memory), _freeze(peripherals), vectors,
                     _freeze(claims))


@dataclass(frozen=True)
class Target:
    triple: str
    board: Board
    maturity: str = "SIMULATOR_ONLY"
    abi: str = "NEBO_EMBEDDED_ABI_V1"

    @staticmethod
    def bareMetal(triple: str, board: Board) -> "Target":
        _reject(triple != TARGET_TRIPLE or not isinstance(board, Board),
                "UNSUPPORTED-TARGET", "Target.bareMetal")
        return Target(triple, board)


def reference_board_spec() -> Mapping[str, Any]:
    """Return a fresh public specification for the sole certified simulator."""
    return {
        "id": BOARD_ID,
        "cpu": {"architecture": "x86_64", "endianness": "little", "clockHz": 10_000_000},
        "memory": {
            "rom": {"origin": 1_048_576, "bytes": 262_144},
            "ram": {"origin": 2_097_152, "bytes": 262_144},
            "stackAlignment": 16,
        },
        "peripherals": {
            "gpio": 3_145_728, "spi": 3_149_824, "i2c": 3_153_920,
            "uart": 3_158_016, "timer": 3_162_112, "watchdog": 3_166_208,
        },
        "vectors": 16,
        "claims": {"physicalBoard": False, "hardRealTime": False, "secureBoot": False},
    }


class Firmware:
    """Deterministic image builder tied to one explicit bare-metal target."""

    def __init__(self, target: Target):
        _reject(not isinstance(target, Target), "TARGET-REQUIRED", "Firmware")
        self.target = target
        self._entry: str | None = None
        self._vectors: tuple[str, ...] = ()

    def entry(self, function: str | Callable[..., Any]) -> "Firmware":
        name = function if isinstance(function, str) else getattr(function, "__name__", "")
        _reject(not name or len(name) > 64 or not name.replace("_", "a").isalnum(),
                "ENTRY", "Firmware.entry")
        self._entry = name
        return self

    def vectorTable(self, entries: Iterable[str | Callable[..., Any]]) -> "Firmware":
        names = tuple(item if isinstance(item, str) else getattr(item, "__name__", "")
                      for item in entries)
        _reject(not names or len(names) > self.target.board.vectors
                or any(not name or len(name) > 64 or not name.replace("_", "a").isalnum()
                       for name in names)
                or len(set(names)) != len(names),
                "VECTOR-TABLE", "Firmware.vectorTable")
        self._vectors = names
        return self

    def memoryMap(self) -> Mapping[str, Any]:
        return self.target.board.memory

    def linkerScript(self) -> str:
        memory = self.target.board.memory
        rom, ram = memory["rom"], memory["ram"]
        return ("/* NEBO_EMBEDDED_LINKER_V1; SIMULATOR_ONLY */\n"
                f"MEMORY {{ ROM(rx): ORIGIN=0x{rom['origin']:x}, LENGTH=0x{rom['bytes']:x}; "
                f"RAM(rw): ORIGIN=0x{ram['origin']:x}, LENGTH=0x{ram['bytes']:x}; }}\n")

    def image(self, format: str) -> bytes:
        _reject(self._entry is None or not self._vectors, "INCOMPLETE-IMAGE", "Firmware.image")
        _reject(format not in ("elf64", "raw-bin"), "IMAGE-FORMAT", "Firmware.image")
        payload = json.dumps({
            "abi": self.target.abi, "board": self.target.board.id, "entry": self._entry,
            "format": format, "maturity": self.target.maturity, "vectors": self._vectors,
        }, sort_keys=True, separators=(",", ":")).encode()
        image = b"NEBOFW01" + len(payload).to_bytes(4, "little") + payload
        return image + bytes.fromhex(_sha256(image))


@dataclass(frozen=True)
class Capability:
    simulator: "HardwareSimulator"
    kind: str
    base: int
    length: int
    operations: frozenset[str]

    @staticmethod
    def new(simulator: "HardwareSimulator", kind: str, base: int, length: int,
            operations: Iterable[str]) -> "Capability":
        operation = "Capability.new"
        _reject(not isinstance(simulator, HardwareSimulator), "CAPABILITY", operation)
        base = _nonnegative_int(base, "CAPABILITY", operation)
        length = _positive_int(length, "CAPABILITY", operation, 1 << 20)
        rights = frozenset(operations)
        _reject(not kind or not rights or not rights <= {
            "read", "write", "modify", "fence", "bind", "configure", "transfer", "control"
        }, "CAPABILITY", operation)
        return Capability(simulator, kind, base, length, rights)

    def covers(self, address: int, length: int, right: str) -> bool:
        return (right in self.operations and address >= self.base and length >= 0
                and address + length <= self.base + self.length)


class HardwareSimulator:
    def __init__(self, board: Board):
        self.board = board
        self.time_ns = 0
        self._trace: list[Mapping[str, Any]] = []
        self._registers: dict[int, int] = {}
        self._pins: dict[int, bool] = {}
        self._interrupts: dict[int, "InterruptBinding"] = {}
        self.interrupts_enabled = True
        self._timers: list["TimerHandle"] = []
        self.watchdog: "WatchdogHandle | None" = None

    @staticmethod
    def new(boardSpec: Board | Mapping[str, Any]) -> "HardwareSimulator":
        board = boardSpec if isinstance(boardSpec, Board) else Board.define(boardSpec)
        return HardwareSimulator(board)

    def _record(self, kind: str, **fields: Any) -> None:
        _reject(len(self._trace) >= MAX_TRACE_EVENTS, "TRACE-BUDGET", kind)
        self._trace.append(MappingProxyType({"sequence": len(self._trace), "timeNs": self.time_ns,
                                             "kind": kind, **fields}))

    def injectInterrupt(self, vector: int, time: int) -> Any:
        vector = _nonnegative_int(vector, "INTERRUPT-VECTOR", "simulator.injectInterrupt", 255)
        time = _nonnegative_int(time, "TIME", "simulator.injectInterrupt")
        _reject(vector >= self.board.vectors or time < self.time_ns,
                "INTERRUPT-VECTOR", "simulator.injectInterrupt")
        self.time_ns = time
        binding = self._interrupts.get(vector)
        _reject(binding is None or not binding.enabled or not self.interrupts_enabled,
                "INTERRUPT-DISABLED", "simulator.injectInterrupt")
        self._record("interrupt-enter", vector=vector, priority=binding.priority_level)
        try:
            return binding.handler()
        finally:
            binding.pending = True
            self._record("interrupt-exit", vector=vector)

    def trace(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(self._trace)

    def advance(self, duration_ns: int) -> None:
        duration_ns = _nonnegative_int(duration_ns, "TIME", "simulator.advance")
        target = self.time_ns + duration_ns
        while True:
            candidates = tuple((handle.due_ns, index, handle)
                               for index, handle in enumerate(self._timers)
                               if not handle.cancelled and handle.due_ns <= target)
            if not candidates:
                break
            due, _, handle = min(candidates, key=lambda item: (item[0], item[1]))
            self.time_ns = due
            handle._fire_once()
        self.time_ns = target
        if self.watchdog is not None:
            self.watchdog._check(self.time_ns)


class MemoryRegion:
    def __init__(self, base: int, length: int, capability: Capability):
        self.base, self.length, self.capability = base, length, capability

    def fence(self, order: str) -> int:
        _reject(order not in ALLOWED_FENCES or "fence" not in self.capability.operations,
                "FENCE", "mmio.fence")
        self.capability.simulator._record("mmio-fence", order=order)
        return len(self.capability.simulator.trace())


class MemoryMapped:
    @staticmethod
    def region(base: int, length: int, capability: Capability) -> MemoryRegion:
        operation = "MemoryMapped.region"
        _reject(not isinstance(capability, Capability), "CAPABILITY", operation)
        base = _nonnegative_int(base, "MMIO-RANGE", operation)
        length = _positive_int(length, "MMIO-RANGE", operation, 1 << 20)
        _reject(base % 4 != 0 or length % 4 != 0 or not capability.covers(base, length, "read"),
                "MMIO-RANGE", operation)
        return MemoryRegion(base, length, capability)


T = TypeVar("T", bound=int)


class Register(Generic[T]):
    def __init__(self, address: int, capability: Capability, bits: int):
        self.address, self.capability, self.bits = address, capability, bits
        self._mask = (1 << bits) - 1

    @staticmethod
    def at(address: int, capability: Capability, bits: int = 32) -> "Register[int]":
        operation = "Register.at"
        _reject(not isinstance(capability, Capability) or bits not in (8, 16, 32, 64),
                "REGISTER", operation)
        address = _nonnegative_int(address, "REGISTER", operation)
        width = bits // 8
        _reject(address % width != 0 or not capability.covers(address, width, "read"),
                "CAPABILITY", operation)
        return Register(address, capability, bits)

    def read(self) -> int:
        _reject("read" not in self.capability.operations, "CAPABILITY", "register.read")
        value = self.capability.simulator._registers.get(self.address, 0)
        self.capability.simulator._record("mmio-read", address=self.address, value=value,
                                          volatile=True)
        return value

    def write(self, value: int) -> None:
        _reject("write" not in self.capability.operations or isinstance(value, bool)
                or not isinstance(value, int) or value < 0 or value > self._mask,
                "REGISTER-VALUE", "register.write")
        self.capability.simulator._registers[self.address] = value
        self.capability.simulator._record("mmio-write", address=self.address, value=value,
                                          volatile=True)

    def modify(self, transform: Callable[[int], int]) -> int:
        _reject("modify" not in self.capability.operations or not callable(transform),
                "CAPABILITY", "register.modify")
        old = self.capability.simulator._registers.get(self.address, 0)
        try:
            value = transform(old)
        except builtins.Exception as error:
            raise EmbeddedError("TRANSFORM", "register.modify") from error
        _reject(isinstance(value, bool) or not isinstance(value, int) or value < 0 or value > self._mask,
                "REGISTER-VALUE", "register.modify")
        self.capability.simulator._registers[self.address] = value
        self.capability.simulator._record("mmio-modify", address=self.address, before=old, after=value,
                                          volatile=True)
        return value

    def setBits(self, mask: int) -> int:
        _reject(isinstance(mask, bool) or not isinstance(mask, int) or mask < 0 or mask > self._mask,
                "REGISTER-MASK", "register.setBits")
        return self.modify(lambda value: value | mask)

    def clearBits(self, mask: int) -> int:
        _reject(isinstance(mask, bool) or not isinstance(mask, int) or mask < 0 or mask > self._mask,
                "REGISTER-MASK", "register.clearBits")
        return self.modify(lambda value: value & ~mask)


@dataclass
class InterruptBinding:
    simulator: HardwareSimulator
    vector: int
    handler: Callable[[], Any]
    enabled: bool = False
    priority_level: int = 0
    pending: bool = False
    budget_ns: int | None = None

    def enable(self) -> "InterruptBinding":
        self.enabled = True
        self.simulator._record("interrupt-enable", vector=self.vector)
        return self

    def disable(self) -> "InterruptBinding":
        self.enabled = False
        self.simulator._record("interrupt-disable", vector=self.vector)
        return self

    def priority(self, level: int) -> "InterruptBinding":
        level = _nonnegative_int(level, "INTERRUPT-PRIORITY", "interrupt.priority", 255)
        self.priority_level = level
        return self

    def acknowledge(self) -> None:
        _reject(not self.pending, "INTERRUPT-NOT-PENDING", "interrupt.acknowledge")
        self.pending = False
        self.simulator._record("interrupt-acknowledge", vector=self.vector)

    def latencyBudget(self, duration: int) -> "InterruptBinding":
        self.budget_ns = _positive_int(duration, "LATENCY-BUDGET", "interrupt.latencyBudget")
        return self


class Interrupt:
    def __init__(self, simulator: HardwareSimulator, capability: Capability):
        _reject(capability.simulator is not simulator or "bind" not in capability.operations,
                "CAPABILITY", "Interrupt")
        self.simulator = simulator

    def bind(self, vector: int, handler: Callable[[], Any]) -> InterruptBinding:
        vector = _nonnegative_int(vector, "INTERRUPT-VECTOR", "Interrupt.bind", 255)
        _reject(vector >= self.simulator.board.vectors or not callable(handler)
                or vector in self.simulator._interrupts, "INTERRUPT-VECTOR", "Interrupt.bind")
        binding = InterruptBinding(self.simulator, vector, handler)
        self.simulator._interrupts[vector] = binding
        return binding


class CriticalSection:
    def __init__(self, simulator: HardwareSimulator):
        self.simulator = simulator

    def run(self, callable: Callable[[], T]) -> T:
        _reject(not builtins.callable(callable), "CALLABLE", "CriticalSection.run")
        previous = self.simulator.interrupts_enabled
        self.simulator.interrupts_enabled = False
        self.simulator._record("critical-enter")
        try:
            return callable()
        finally:
            self.simulator.interrupts_enabled = previous
            self.simulator._record("critical-exit", restored=previous)


@dataclass(frozen=True)
class ExceptionBinding:
    kind: str
    function: Callable[..., Any]


class Exception:
    def __init__(self, simulator: HardwareSimulator):
        self.simulator = simulator
        self._handlers: dict[str, ExceptionBinding] = {}

    def handler(self, kind: str, function: Callable[..., Any]) -> ExceptionBinding:
        _reject(kind not in ("fault", "trap", "panic") or not callable(function),
                "EXCEPTION-HANDLER", "Exception.handler")
        binding = ExceptionBinding(kind, function)
        self._handlers[kind] = binding
        self.simulator._record("exception-handler", exceptionKind=kind)
        return binding


class PinHandle:
    def __init__(self, simulator: HardwareSimulator, pin_id: int, direction: str):
        self.simulator, self.pin_id, self.direction = simulator, pin_id, direction

    def write(self, value: bool) -> None:
        _reject(self.direction != "output" or not isinstance(value, bool), "PIN-DIRECTION", "pin.write")
        self.simulator._pins[self.pin_id] = value
        self.simulator._record("gpio-write", pin=self.pin_id, value=value)

    def read(self) -> bool:
        value = self.simulator._pins.get(self.pin_id, False)
        self.simulator._record("gpio-read", pin=self.pin_id, value=value)
        return value


class Pin:
    @staticmethod
    def _open(pin_id: int, options: Mapping[str, Any], direction: str) -> PinHandle:
        _reject(not isinstance(options, Mapping), "PIN-OPTIONS", f"Pin.{direction}")
        simulator, capability = options.get("simulator"), options.get("capability")
        pin_id = _nonnegative_int(pin_id, "PIN", f"Pin.{direction}", 63)
        _reject(not isinstance(simulator, HardwareSimulator) or not isinstance(capability, Capability)
                or capability.simulator is not simulator or capability.kind != "gpio"
                or "configure" not in capability.operations, "CAPABILITY", f"Pin.{direction}")
        simulator._record("gpio-configure", pin=pin_id, direction=direction)
        return PinHandle(simulator, pin_id, direction)

    @staticmethod
    def output(id: int, options: Mapping[str, Any]) -> PinHandle:
        return Pin._open(id, options, "output")

    @staticmethod
    def input(id: int, options: Mapping[str, Any]) -> PinHandle:
        return Pin._open(id, options, "input")


class Bus:
    def __init__(self, kind: str, config: Mapping[str, Any], capability: Capability):
        self.kind, self.config, self.capability = kind, _freeze(config), capability
        self.latency_ns = _positive_int(config.get("latencyNs", 100), "BUS-CONFIG", f"{kind}.open",
                                        1_000_000_000)
        _reject("fault" in config and not isinstance(config["fault"], bool),
                "BUS-CONFIG", f"{kind}.open")
        self.fault = bool(config.get("fault", False))

    def transfer(self, write: bytes, readLength: int, deadline: int) -> bytes:
        operation = "bus.transfer"
        _reject(not isinstance(write, bytes), "TRANSFER", operation)
        read_length = _nonnegative_int(readLength, "TRANSFER", operation, MAX_TRANSFER_BYTES)
        deadline = _nonnegative_int(deadline, "DEADLINE", operation)
        simulator = self.capability.simulator
        latency = self.latency_ns
        _reject(len(write) + read_length > MAX_TRANSFER_BYTES, "TRANSFER-BUDGET", operation)
        _reject(self.fault or simulator.time_ns + latency > deadline,
                "TRANSFER-FAILED", operation)
        seed = hashlib.sha256(self.kind.encode() + write).digest()
        result = bytes(seed[index % len(seed)] for index in range(read_length))
        simulator.time_ns += latency
        simulator._record("bus-transfer", bus=self.kind, wrote=len(write), read=read_length)
        return result


def _open_bus(kind: str, config: Mapping[str, Any], capability: Capability) -> Bus:
    _reject(not isinstance(config, Mapping) or not isinstance(capability, Capability)
            or capability.kind != kind or "transfer" not in capability.operations,
            "CAPABILITY", f"{kind}.open")
    _reject(config.get("simulator") is not capability.simulator,
            "CAPABILITY", f"{kind}.open")
    return Bus(kind, config, capability)


class Spi:
    @staticmethod
    def open(config: Mapping[str, Any], capability: Capability) -> Bus:
        return _open_bus("spi", config, capability)


class I2c:
    @staticmethod
    def open(config: Mapping[str, Any], capability: Capability) -> Bus:
        return _open_bus("i2c", config, capability)


class Uart:
    @staticmethod
    def open(config: Mapping[str, Any], capability: Capability) -> Bus:
        return _open_bus("uart", config, capability)


class DmaTransfer:
    def __init__(self, simulator: HardwareSimulator, source: bytes,
                 destination: bytearray, length: int):
        self.simulator, self.source, self.destination, self.length = simulator, source, destination, length
        self.completed = False

    def await_(self, deadline: int) -> int:
        deadline = _nonnegative_int(deadline, "DEADLINE", "dma.await")
        _reject(self.simulator.time_ns + self.length > deadline, "DMA-DEADLINE", "dma.await")
        staged = self.source[:self.length]
        self.destination[:self.length] = staged
        self.simulator.time_ns += self.length
        self.completed = True
        self.simulator._record("dma-complete", bytes=self.length)
        return self.length


setattr(DmaTransfer, "await", DmaTransfer.await_)


class DmaChannel:
    def __init__(self, channel_id: int, capability: Capability):
        self.id, self.capability = channel_id, capability

    @staticmethod
    def open(id: int, capability: Capability) -> "DmaChannel":
        channel_id = _nonnegative_int(id, "DMA-CHANNEL", "DmaChannel.open", 15)
        _reject(not isinstance(capability, Capability) or capability.kind != "dma"
                or "transfer" not in capability.operations, "CAPABILITY", "DmaChannel.open")
        return DmaChannel(channel_id, capability)

    def transfer(self, source: bytes, destination: bytearray, length: int) -> DmaTransfer:
        operation = "dma.transfer"
        _reject(not isinstance(source, bytes) or not isinstance(destination, bytearray),
                "DMA-BUFFER", operation)
        length = _nonnegative_int(length, "DMA-LENGTH", operation, MAX_TRANSFER_BYTES)
        _reject(length > len(source) or length > len(destination), "DMA-LENGTH", operation)
        self.capability.simulator._record("dma-submit", channel=self.id, bytes=length)
        return DmaTransfer(self.capability.simulator, source, destination, length)


@dataclass
class TimerHandle:
    simulator: HardwareSimulator
    due_ns: int
    handler: Callable[[], Any]
    period_ns: int | None = None
    cancelled: bool = False
    firings: int = 0

    def cancel(self) -> bool:
        was_active = not self.cancelled
        self.cancelled = True
        self.simulator._record("timer-cancel", active=was_active)
        return was_active

    def _fire_once(self) -> None:
        _reject(self.firings >= 1024, "TIMER-BUDGET", "timer.fire")
        try:
            self.handler()
        finally:
            self.firings += 1
            self.simulator._record("timer-fire", firing=self.firings)
            if self.period_ns is None:
                self.cancelled = True
            else:
                self.due_ns += self.period_ns


class Timer:
    def __init__(self, simulator: HardwareSimulator):
        self.simulator = simulator

    def after(self, duration: int, handler: Callable[[], Any]) -> TimerHandle:
        duration = _positive_int(duration, "TIMER-DURATION", "Timer.after")
        _reject(not callable(handler), "CALLABLE", "Timer.after")
        handle = TimerHandle(self.simulator, self.simulator.time_ns + duration, handler)
        self.simulator._timers.append(handle)
        return handle

    def periodic(self, period: int, handler: Callable[[], Any]) -> TimerHandle:
        period = _positive_int(period, "TIMER-DURATION", "Timer.periodic")
        _reject(not callable(handler), "CALLABLE", "Timer.periodic")
        handle = TimerHandle(self.simulator, self.simulator.time_ns + period, handler, period)
        self.simulator._timers.append(handle)
        return handle


@dataclass
class WatchdogHandle:
    simulator: HardwareSimulator
    timeout_ns: int
    deadline_ns: int
    resets: int = 0

    def feed(self) -> int:
        self.deadline_ns = self.simulator.time_ns + self.timeout_ns
        self.simulator._record("watchdog-feed", deadline=self.deadline_ns)
        return self.deadline_ns

    def _check(self, now: int) -> None:
        if now > self.deadline_ns:
            self.resets += 1
            self.deadline_ns = now + self.timeout_ns
            self.simulator._record("watchdog-reset", resets=self.resets)


class Watchdog:
    def __init__(self, simulator: HardwareSimulator):
        self.simulator = simulator

    def start(self, timeout: int) -> WatchdogHandle:
        timeout = _positive_int(timeout, "WATCHDOG-TIMEOUT", "Watchdog.start")
        _reject(self.simulator.watchdog is not None, "WATCHDOG-ACTIVE", "Watchdog.start")
        handle = WatchdogHandle(self.simulator, timeout, self.simulator.time_ns + timeout)
        self.simulator.watchdog = handle
        self.simulator._record("watchdog-start", timeout=timeout)
        return handle


@dataclass
class RealTimeTask:
    name: str
    period_ns: int
    deadline_ns: int
    function: Callable[[], Any]
    budget_ns: int | None = None
    priority_level: int | None = None

    def worstCaseBudget(self, duration: int) -> "RealTimeTask":
        duration = _positive_int(duration, "TASK-BUDGET", "task.worstCaseBudget")
        _reject(duration > self.deadline_ns, "TASK-BUDGET", "task.worstCaseBudget")
        self.budget_ns = duration
        return self

    def priority(self, level: int) -> "RealTimeTask":
        self.priority_level = _nonnegative_int(level, "TASK-PRIORITY", "task.priority", 255)
        return self


class RealTime:
    @staticmethod
    def task(name: str, period: int, deadline: int, function: Callable[[], Any]) -> RealTimeTask:
        operation = "RealTime.task"
        _reject(not name or len(name) > 64 or not callable(function), "TASK", operation)
        period = _positive_int(period, "TASK-PERIOD", operation)
        deadline = _positive_int(deadline, "TASK-DEADLINE", operation)
        _reject(deadline > period, "TASK-DEADLINE", operation)
        return RealTimeTask(name, period, deadline, function)


class Scheduler:
    def __init__(self, policy: str, tasks: Iterable[RealTimeTask]):
        self.policy = policy
        self.tasks = tuple(tasks)
        _reject(not self.tasks or len(self.tasks) > MAX_TASKS
                or any(not isinstance(task, RealTimeTask) for task in self.tasks),
                "TASKS", f"RealTimeScheduler.{policy}")
        _reject(len({task.name for task in self.tasks}) != len(self.tasks),
                "DUPLICATE-TASK", f"RealTimeScheduler.{policy}")
        if policy == "fixed-priority":
            _reject(any(task.priority_level is None for task in self.tasks),
                    "TASK-PRIORITY", "RealTimeScheduler.fixedPriority")

    def admissionTest(self) -> Mapping[str, Any]:
        complete = all(task.budget_ns is not None for task in self.tasks)
        utilization = (sum(task.budget_ns / task.period_ns for task in self.tasks
                           if task.budget_ns is not None) if complete else float("inf"))
        deadlines = complete and all(task.budget_ns <= task.deadline_ns for task in self.tasks)  # type: ignore[operator]
        feasibility: tuple[int, ...] | float | None = None
        admitted = bool(complete and deadlines and utilization <= 1.0)
        analysis = "missing-budgets"
        if admitted and self.policy == "fixed-priority":
            analysis = "response-time-v1"
            ordered = sorted(self.tasks, key=lambda task: (-int(task.priority_level), task.name))
            response_times: list[int] = []
            for index, task in enumerate(ordered):
                response = int(task.budget_ns)
                converged = False
                for _ in range(128):
                    interference = sum(
                        ((response + higher.period_ns - 1) // higher.period_ns)
                        * int(higher.budget_ns) for higher in ordered[:index]
                    )
                    next_response = int(task.budget_ns) + interference
                    if next_response == response:
                        converged = True
                        break
                    response = next_response
                    if response > task.deadline_ns:
                        break
                response_times.append(response)
                if not converged or response > task.deadline_ns:
                    admitted = False
                    break
            feasibility = tuple(response_times)
        elif admitted and self.policy == "edf":
            analysis = "constrained-deadline-density-v1"
            density = sum(int(task.budget_ns) / min(task.period_ns, task.deadline_ns)
                          for task in self.tasks)
            feasibility = density
            admitted = density <= 1.0
        return MappingProxyType({"admitted": admitted, "policy": self.policy,
                                 "utilization": utilization, "environment": "SIMULATOR_ONLY",
                                 "hardRealTimeClaim": False, "analysis": analysis,
                                 "feasibility": feasibility})

    def run(self) -> tuple[Any, ...]:
        _reject(not self.admissionTest()["admitted"], "NOT-ADMITTED", "scheduler.run")
        if self.policy == "fixed-priority":
            order = sorted(self.tasks, key=lambda task: (-int(task.priority_level), task.name))
        else:
            order = sorted(self.tasks, key=lambda task: (task.deadline_ns, task.name))
        return tuple(task.function() for task in order)

    def deadlineReport(self) -> Mapping[str, Any]:
        admission = self.admissionTest()
        return MappingProxyType({
            "environment": "SIMULATOR_ONLY", "hardwareMeasured": False,
            "hardRealTimeClaim": False, "policy": self.policy, "admission": admission,
            "tasks": tuple(MappingProxyType({"name": task.name, "periodNs": task.period_ns,
                                               "deadlineNs": task.deadline_ns,
                                               "budgetNs": task.budget_ns}) for task in self.tasks),
        })


class RealTimeScheduler:
    @staticmethod
    def fixedPriority(tasks: Iterable[RealTimeTask]) -> Scheduler:
        return Scheduler("fixed-priority", tasks)

    @staticmethod
    def edf(tasks: Iterable[RealTimeTask]) -> Scheduler:
        return Scheduler("edf", tasks)


class FirmwareState:
    def __init__(self, version: int, target: Target, hashes: Mapping[str, str]):
        self.version, self.target = version, target
        self.hashes = MappingProxyType(dict(hashes))
        self.active_slot = "A"
        self.previous_slot: str | None = None
        self.slots: dict[str, bytes] = {"A": b""}
        self.rollback_counter = version

    def verify(self) -> Mapping[str, Any]:
        valid_hashes = bool(self.hashes) and all(
            isinstance(digest, str) and len(digest) == 64
            and all(char in "0123456789abcdef" for char in digest)
            for digest in self.hashes.values())
        return MappingProxyType({"verified": valid_hashes, "target": self.target.board.id,
                                 "slots": 2, "secureBoot": False,
                                 "environment": "SIMULATOR_ONLY"})

    def update(self, slot: str, image: bytes, policy: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "firmware.update"
        _reject(slot not in ("A", "B") or slot == self.active_slot or not isinstance(image, bytes)
                or not isinstance(policy, Mapping), "UPDATE", operation)
        _reject(len(image) == 0 or len(image) > MAX_IMAGE_BYTES, "IMAGE-SIZE", operation)
        expected = self.hashes.get("candidate")
        _reject(expected is None or _sha256(image) != expected, "IMAGE-HASH", operation)
        power_cut = policy.get("powerCutAfter")
        _reject(power_cut is not None and (isinstance(power_cut, bool)
                or not isinstance(power_cut, int) or power_cut not in range(5)),
                "POWER-CUT", operation)
        next_version = policy.get("version", self.version + 1)
        next_version = _positive_int(next_version, "UPDATE-VERSION", operation, 2**31 - 1)
        _reject(next_version <= self.rollback_counter, "ROLLBACK-COUNTER", operation)
        steps = ("write", "verify", "counter", "activate")
        staged_slots = dict(self.slots)
        staged_counter = self.rollback_counter
        staged_active = self.active_slot
        verified = False
        for index, step in enumerate(steps):
            if power_cut == index:
                return MappingProxyType({"committed": False, "activeSlot": self.active_slot,
                                         "powerCutAfter": index})
            if step == "write":
                staged_slots[slot] = bytes(image)
            elif step == "verify":
                verified = _sha256(staged_slots[slot]) == expected
            elif step == "counter":
                _reject(not verified, "IMAGE-HASH", operation)
                staged_counter = next_version
            else:
                _reject(not verified, "IMAGE-HASH", operation)
                staged_active = slot
        self.previous_slot = self.active_slot
        self.slots, self.rollback_counter, self.active_slot = staged_slots, staged_counter, staged_active
        return MappingProxyType({"committed": True, "activeSlot": self.active_slot,
                                 "rollbackCounter": self.rollback_counter})

    def rollback(self) -> str:
        _reject(self.previous_slot is None or self.previous_slot not in self.slots,
                "NO-ROLLBACK", "firmware.rollback")
        self.active_slot, self.previous_slot = self.previous_slot, self.active_slot
        return self.active_slot


class FirmwareManifest:
    @staticmethod
    def new(version: int, target: Target, hashes: Mapping[str, str]) -> FirmwareState:
        version = _positive_int(version, "MANIFEST-VERSION", "FirmwareManifest.new", 2**31 - 1)
        _reject(not isinstance(target, Target) or not isinstance(hashes, Mapping),
                "MANIFEST", "FirmwareManifest.new")
        state = FirmwareState(version, target, hashes)
        _reject(not state.verify()["verified"], "MANIFEST-HASH", "FirmwareManifest.new")
        return state


__all__ = [
    "BOARD_ID", "TARGET_TRIPLE", "Board", "Capability", "CriticalSection", "DmaChannel",
    "EmbeddedError", "Exception", "Firmware", "FirmwareManifest", "HardwareSimulator", "I2c",
    "Interrupt", "MemoryMapped", "Pin", "RealTime", "RealTimeScheduler", "Register", "Spi",
    "Target", "Timer", "Uart", "Watchdog", "reference_board_spec",
]
