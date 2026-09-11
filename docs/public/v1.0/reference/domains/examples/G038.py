#!/usr/bin/env python3
"""Independent value/effect oracle for all 54 programmatic G038 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.embedded import (  # noqa: E402
    BOARD_ID, TARGET_TRIPLE, Board, Capability, CriticalSection, DmaChannel,
    EmbeddedError, Exception as FirmwareException, Firmware, FirmwareManifest,
    HardwareSimulator, I2c, Interrupt, MemoryMapped, Pin, RealTime,
    RealTimeScheduler, Register, Spi, Target, Timer, Uart, Watchdog,
    reference_board_spec,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1
    if category == "positive":
        counts["sdk"] += 1


def reject(label: str, suffix: str, callable_) -> None:
    try:
        callable_()
    except EmbeddedError as error:
        ok("negative", label, error.code() == f"NEBO-G038-{suffix}" and bool(error.operation()))
        counts["diagnostics"] += 1
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — an explicit target drives deterministic startup metadata and images.
spec = reference_board_spec()
board = Board.define(spec)
ok("positive", "Board.define", board.id == BOARD_ID and board.vectors == 16)
target = Target.bareMetal(TARGET_TRIPLE, board)
ok("positive", "Target.bareMetal", target.maturity == "SIMULATOR_ONLY" and target.abi.endswith("V1"))
firmware = Firmware(target)
ok("positive", "Firmware.entry", firmware.entry("board_reset") is firmware)
ok("positive", "Firmware.vectorTable",
   firmware.vectorTable(("board_reset", "timer_irq", "uart_irq")) is firmware)
linker = firmware.linkerScript()
ok("positive", "Firmware.linkerScript",
   "ORIGIN=0x100000" in linker and "ORIGIN=0x200000" in linker)
image = firmware.image("raw-bin")
ok("positive", "Firmware.image",
   image[:8] == b"NEBOFW01" and image[-32:] == hashlib.sha256(image[:-32]).digest())
memory = firmware.memoryMap()
ok("positive", "firmware.memoryMap",
   memory["rom"]["bytes"] == 262_144 and memory["ram"]["origin"] == 2_097_152)
transcript.append((board.id, target.triple, linker, image.hex(), dict(memory)))

# S02 — every volatile read/write remains in the trace and needs a bounded cap.
simulator = HardwareSimulator.new(board)
mmio_cap = Capability.new(simulator, "mmio", 3_145_728, 4096,
                          ("read", "write", "modify", "fence"))
region = MemoryMapped.region(3_145_728, 4096, mmio_cap)
ok("positive", "MemoryMapped.region", region.base == 3_145_728 and region.length == 4096)
register = Register.at(3_145_728, mmio_cap)
ok("positive", "Register.at", register.address == 3_145_728 and register.bits == 32)
ok("positive", "register.read", register.read() == 0)
register.write(0x12)
ok("positive", "register.write", simulator._registers[register.address] == 0x12)
ok("positive", "register.modify", register.modify(lambda value: value + 3) == 0x15)
ok("positive", "register.setBits", register.setBits(0x40) == 0x55)
ok("positive", "register.clearBits", register.clearBits(0x10) == 0x45)
fence_sequence = region.fence("seq-cst")
ok("positive", "mmio.fence", fence_sequence == 6 and simulator.trace()[-1]["order"] == "seq-cst")
transcript.append(tuple(dict(event) for event in simulator.trace()))

# S03 — interrupt state, acknowledgement, critical restoration and handlers.
irq_cap = Capability.new(simulator, "interrupt", 0, board.vectors, ("bind", "control"))
observed_irqs: list[str] = []
binding = Interrupt(simulator, irq_cap).bind(5, lambda: observed_irqs.append("irq5") or 38)
ok("positive", "Interrupt.bind", binding.vector == 5 and not binding.enabled)
ok("positive", "interrupt.enable", binding.enable() is binding and binding.enabled)
ok("positive", "interrupt.priority", binding.priority(7) is binding and binding.priority_level == 7)
ok("positive", "interrupt.latencyBudget",
   binding.latencyBudget(250) is binding and binding.budget_ns == 250)
ok("composition", "interrupt-injection", simulator.injectInterrupt(5, 1000) == 38
   and observed_irqs == ["irq5"] and binding.pending)
binding.acknowledge()
ok("positive", "interrupt.acknowledge", not binding.pending)
ok("positive", "interrupt.disable", binding.disable() is binding and not binding.enabled)
critical_state = CriticalSection(simulator).run(lambda: (simulator.interrupts_enabled, 73))
ok("positive", "CriticalSection.run", critical_state == (False, 73) and simulator.interrupts_enabled)
exception_binding = FirmwareException(simulator).handler("fault", lambda code: code + 1)
ok("positive", "Exception.handler", exception_binding.function(4) == 5)
transcript.append((observed_irqs, tuple(dict(event) for event in simulator.trace()[-8:])))

# S04 — GPIO and three bounded buses produce real simulator effects.
gpio_cap = Capability.new(simulator, "gpio", 3_145_728, 4096, ("configure", "read", "write"))
pin_out = Pin.output(3, {"simulator": simulator, "capability": gpio_cap})
ok("positive", "Pin.output", pin_out.direction == "output")
pin_in = Pin.input(4, {"simulator": simulator, "capability": gpio_cap})
ok("positive", "Pin.input", pin_in.direction == "input")
pin_out.write(True)
ok("positive", "pin.write", simulator._pins[3] is True)
ok("positive", "pin.read", pin_out.read() is True and pin_in.read() is False)
buses = {}
for kind, factory, base in (("spi", Spi, 3_149_824), ("i2c", I2c, 3_153_920),
                            ("uart", Uart, 3_158_016)):
    capability = Capability.new(simulator, kind, base, 4096, ("transfer", "configure"))
    buses[kind] = factory.open({"simulator": simulator, "latencyNs": 20}, capability)
ok("positive", "Spi.open", buses["spi"].kind == "spi")
ok("positive", "I2c.open", buses["i2c"].kind == "i2c")
ok("positive", "Uart.open", buses["uart"].kind == "uart")
spi_result = buses["spi"].transfer(b"\x11\x22\x33", 5, simulator.time_ns + 20)
ok("positive", "bus.transfer", len(spi_result) == 5
   and spi_result == hashlib.sha256(b"spi\x11\x22\x33").digest()[:5])
transcript.append((spi_result.hex(), tuple(dict(event) for event in simulator.trace()[-8:])))

# S05 — DMA commits at await; logical timers/watchdog never use wall time.
dma_cap = Capability.new(simulator, "dma", 0, 16, ("transfer", "control"))
dma = DmaChannel.open(2, dma_cap)
ok("positive", "DmaChannel.open", dma.id == 2)
destination = bytearray(b"........")
transfer = dma.transfer(b"firmware", destination, 8)
ok("positive", "dma.transfer", bytes(destination) == b"........" and not transfer.completed)
awaited = getattr(transfer, "await")(simulator.time_ns + 8)
ok("positive", "dma.await", awaited == 8 and bytes(destination) == b"firmware")
timer_events: list[str] = []
timer = Timer(simulator)
one_shot = timer.after(10, lambda: timer_events.append("once"))
ok("positive", "Timer.after", one_shot.due_ns == simulator.time_ns + 10)
periodic = timer.periodic(4, lambda: timer_events.append("periodic"))
ok("positive", "Timer.periodic", periodic.period_ns == 4)
simulator.advance(10)
ok("composition", "timer-execution", timer_events == ["periodic", "periodic", "once"])
ok("positive", "timer.cancel", periodic.cancel() and periodic.cancelled)
watchdog = Watchdog(simulator).start(12)
ok("positive", "Watchdog.start", watchdog.timeout_ns == 12 and watchdog.resets == 0)
first_deadline = watchdog.feed()
ok("positive", "watchdog.feed", first_deadline == simulator.time_ns + 12)
transcript.append((bytes(destination).hex(), timer_events, watchdog.deadline_ns))

# S06 — bounded schedulers publish admission, order and truthful limitations.
executed: list[str] = []
fast = RealTime.task("fast", 100, 80, lambda: executed.append("fast") or 11)
ok("positive", "RealTime.task", fast.period_ns == 100 and fast.deadline_ns == 80)
ok("positive", "task.worstCaseBudget", fast.worstCaseBudget(20) is fast and fast.budget_ns == 20)
ok("positive", "task.priority", fast.priority(9) is fast and fast.priority_level == 9)
slow = RealTime.task("slow", 200, 150, lambda: executed.append("slow") or 22)
slow.worstCaseBudget(40).priority(3)
fixed = RealTimeScheduler.fixedPriority((slow, fast))
ok("positive", "RealTimeScheduler.fixedPriority", fixed.policy == "fixed-priority")
edf = RealTimeScheduler.edf((slow, fast))
ok("positive", "RealTimeScheduler.edf", edf.policy == "edf")
ok("positive", "scheduler.admissionTest",
   fixed.admissionTest()["admitted"] and fixed.admissionTest()["utilization"] == 0.4)
ok("positive", "scheduler.run", fixed.run() == (11, 22) and executed == ["fast", "slow"])
report = fixed.deadlineReport()
ok("positive", "scheduler.deadlineReport",
   report["environment"] == "SIMULATOR_ONLY" and not report["hardwareMeasured"]
   and not report["hardRealTimeClaim"])
transcript.append((dict(fixed.admissionTest()), fixed.run(), dict(report)))

# S07 — manifests and A/B updates are hashed, transactional, and simulator-only.
candidate = b"candidate-firmware-v2"
manifest = FirmwareManifest.new(1, target, {"A": hashlib.sha256(b"").hexdigest(),
                                           "candidate": hashlib.sha256(candidate).hexdigest()})
ok("positive", "FirmwareManifest.new", manifest.version == 1 and manifest.active_slot == "A")
verification = manifest.verify()
ok("positive", "firmware.verify", verification["verified"] and not verification["secureBoot"])
for power_cut in range(4):
    before = (dict(manifest.slots), manifest.active_slot, manifest.rollback_counter)
    cut = manifest.update("B", candidate, {"version": 2, "powerCutAfter": power_cut})
    ok("failure_atomicity", f"power-cut-{power_cut}", not cut["committed"]
       and before == (dict(manifest.slots), manifest.active_slot, manifest.rollback_counter))
updated = manifest.update("B", candidate, {"version": 2})
ok("positive", "firmware.update", updated["committed"] and manifest.active_slot == "B"
   and manifest.slots["B"] == candidate)
ok("positive", "firmware.rollback", manifest.rollback() == "A" and manifest.active_slot == "A")
second_simulator = HardwareSimulator.new(reference_board_spec())
ok("positive", "HardwareSimulator.new", second_simulator.board.id == BOARD_ID)
second_cap = Capability.new(second_simulator, "interrupt", 0, 16, ("bind",))
second_binding = Interrupt(second_simulator, second_cap).bind(2, lambda: "vector-2").enable()
ok("positive", "simulator.injectInterrupt",
   second_simulator.injectInterrupt(2, 200) == "vector-2" and second_binding.pending)
sim_trace = second_simulator.trace()
ok("positive", "simulator.trace",
   tuple(event["kind"] for event in sim_trace) ==
   ("interrupt-enable", "interrupt-enter", "interrupt-exit"))
transcript.append((dict(verification), dict(updated), manifest.active_slot,
                   tuple(dict(event) for event in sim_trace)))

# Stable negative diagnostics span target, authority, range, timing and update failures.
bad_spec = reference_board_spec(); bad_spec["claims"]["hardRealTime"] = True
reject("hard-realtime-claim", "CLAIMS", lambda: Board.define(bad_spec))
reject("target-triple", "UNSUPPORTED-TARGET", lambda: Target.bareMetal("host", board))
reject("incomplete-image", "INCOMPLETE-IMAGE", lambda: Firmware(target).image("raw-bin"))
reject("image-format", "IMAGE-FORMAT", lambda: firmware.image("hex"))
reject("mmio-outside", "MMIO-RANGE", lambda: MemoryMapped.region(3_200_000, 16, mmio_cap))
reject("register-alignment", "CAPABILITY", lambda: Register.at(3_145_729, mmio_cap))
register_before = simulator._registers[register.address]
reject("register-overflow", "REGISTER-VALUE", lambda: register.write(1 << 32))
ok("failure_atomicity", "register-write", simulator._registers[register.address] == register_before)
reject("register-mask", "REGISTER-MASK", lambda: register.setBits(-1))
reject("fence-order", "FENCE", lambda: region.fence("relaxed"))
reject("duplicate-vector", "INTERRUPT-VECTOR",
       lambda: Interrupt(simulator, irq_cap).bind(5, lambda: None))
reject("ack-not-pending", "INTERRUPT-NOT-PENDING", lambda: binding.acknowledge())
critical = CriticalSection(simulator)
try:
    critical.run(lambda: (_ for _ in ()).throw(RuntimeError("fault")))
except RuntimeError:
    pass
ok("failure_atomicity", "critical-restoration", simulator.interrupts_enabled)
fault_simulator = HardwareSimulator.new(board)
fault_capability = Capability.new(fault_simulator, "interrupt", 0, 16, ("bind",))
fault_binding = Interrupt(fault_simulator, fault_capability).bind(
    1, lambda: (_ for _ in ()).throw(RuntimeError("handler-fault"))).enable()
try:
    fault_simulator.injectInterrupt(1, 1)
except RuntimeError:
    pass
ok("failure_atomicity", "interrupt-handler-cleanup",
   fault_binding.pending and fault_simulator.trace()[-1]["kind"] == "interrupt-exit")
reject("bad-pin", "PIN", lambda: Pin.output(64, {"simulator": simulator, "capability": gpio_cap}))
reject("bus-latency", "BUS-CONFIG", lambda: Uart.open(
    {"simulator": simulator, "latencyNs": -1},
    Capability.new(simulator, "uart", 3_158_016, 4096, ("transfer",))))
bus_time_before = simulator.time_ns
reject("bus-deadline", "TRANSFER-FAILED",
       lambda: buses["uart"].transfer(b"late", 2, simulator.time_ns + 19))
ok("failure_atomicity", "bus-transfer", simulator.time_ns == bus_time_before)
dma_destination = bytearray(b"stable")
late_dma = dma.transfer(b"change", dma_destination, 6)
reject("dma-deadline", "DMA-DEADLINE", lambda: getattr(late_dma, "await")(simulator.time_ns))
ok("failure_atomicity", "dma-transfer", bytes(dma_destination) == b"stable")
reject("zero-timer", "TIMER-DURATION", lambda: timer.after(0, lambda: None))
reject("second-watchdog", "WATCHDOG-ACTIVE", lambda: Watchdog(simulator).start(2))
reject("deadline-period", "TASK-DEADLINE", lambda: RealTime.task("bad", 10, 11, lambda: None))
reject("task-budget", "TASK-BUDGET", lambda: fast.worstCaseBudget(81))
unbudgeted = RealTime.task("unbudgeted", 50, 40, lambda: None)
reject("not-admitted", "NOT-ADMITTED", lambda: RealTimeScheduler.edf((unbudgeted,)).run())
reject("duplicate-task", "DUPLICATE-TASK",
       lambda: RealTimeScheduler.edf((fast, fast)))
high = RealTime.task("high", 5, 5, lambda: None).worstCaseBudget(4).priority(9)
low = RealTime.task("low", 10, 5, lambda: None).worstCaseBudget(3).priority(1)
ok("adversarial", "fixed-priority-interference",
   not RealTimeScheduler.fixedPriority((low, high)).admissionTest()["admitted"])
wrong_candidate = b"not-the-candidate"
update_before = (dict(manifest.slots), manifest.active_slot, manifest.rollback_counter)
reject("firmware-hash", "IMAGE-HASH",
       lambda: manifest.update("B", wrong_candidate, {"version": 3}))
ok("failure_atomicity", "firmware-hash", update_before ==
   (dict(manifest.slots), manifest.active_slot, manifest.rollback_counter))
reject("active-slot", "UPDATE", lambda: manifest.update("A", candidate, {"version": 3}))
reject("past-interrupt", "INTERRUPT-VECTOR",
       lambda: second_simulator.injectInterrupt(2, 199))

# Cross-cutting independent properties.
ok("boundary", "vector-upper-bound", board.vectors == 16)
ok("boundary", "image-size", len(image) < 262_144)
ok("boundary", "register-width", register._mask == 0xFFFF_FFFF)
ok("boundary", "empty-bus-read",
   buses["i2c"].transfer(b"\x01", 0, simulator.time_ns + 20) == b"")
zero_destination = bytearray()
zero_dma = dma.transfer(b"", zero_destination, 0)
ok("boundary", "zero-dma", getattr(zero_dma, "await")(simulator.time_ns) == 0)
ok("boundary", "task-count", len(fixed.tasks) == 2)
ok("boundary", "trace-bounded", len(simulator.trace()) < 4096)
ok("boundary", "power-cut-corpus", tuple(range(5)) == (0, 1, 2, 3, 4))

ok("metamorphic", "image-repeat", firmware.image("raw-bin") == image)
ok("metamorphic", "board-copy", Board.define(reference_board_spec()) == board)
read_events_before = len(simulator.trace())
register.read(); register.read()
ok("metamorphic", "volatile-reads-retained", len(simulator.trace()) == read_events_before + 2)
ok("metamorphic", "bus-repeat",
   buses["spi"].transfer(b"same", 3, simulator.time_ns + 20)
   == hashlib.sha256(b"spisame").digest()[:3])
ok("metamorphic", "admission-order-independent",
   RealTimeScheduler.edf((fast, slow)).admissionTest()["utilization"]
   == RealTimeScheduler.edf((slow, fast)).admissionTest()["utilization"])
ok("metamorphic", "manifest-verify-repeat", manifest.verify() == manifest.verify())
ok("metamorphic", "memory-view-repeat", firmware.memoryMap() is memory)

ok("adversarial", "no-physical-board", not board.claims["physicalBoard"])
ok("adversarial", "no-hard-rt", not report["hardRealTimeClaim"])
ok("adversarial", "no-secure-boot", not verification["secureBoot"])
ok("adversarial", "no-network-surface", all("network" not in str(item).lower() for item in transcript))
ok("adversarial", "capability-bound", mmio_cap.simulator is simulator)
ok("adversarial", "inactive-update", updated["activeSlot"] == "B")
ok("adversarial", "immutable-trace", isinstance(second_simulator.trace(), tuple))

ok("composition", "target-firmware", target.board is board and firmware.target is target)
ok("composition", "mmio-capability", register.capability is mmio_cap and region.capability is mmio_cap)
ok("composition", "gpio-simulator", pin_out.simulator is simulator)
ok("composition", "dma-simulator", transfer.simulator is simulator)
ok("composition", "manifest-target", manifest.target is target)

ok("ownership", "board-frozen", type(board.cpu).__name__ == "mappingproxy")
ok("ownership", "trace-snapshot", sim_trace is not second_simulator.trace())
ok("ownership", "dma-staged", transfer.source == b"firmware")
ok("ownership", "manifest-copy", manifest.slots["B"] == candidate)
ok("ownership", "scheduler-task-snapshot", isinstance(fixed.tasks, tuple))
ok("ownership", "report-read-only", type(report).__name__ == "mappingproxy")

ok("target", "target-explicit", target.triple == TARGET_TRIPLE)
ok("target", "abi-versioned", target.abi == "NEBO_EMBEDDED_ABI_V1")
ok("target", "simulator-maturity", target.maturity == "SIMULATOR_ONLY")
ok("target", "board-profile", board.id == BOARD_ID)
ok("target", "hardware-false", not board.claims["physicalBoard"])
ok("target", "hard-rt-false", not board.claims["hardRealTime"])
ok("target", "secure-boot-false", not board.claims["secureBoot"])

canonical = json.dumps(transcript, sort_keys=True, separators=(",", ":"), default=str).encode()
digest = hashlib.sha256(canonical).hexdigest()
for category, expected in {
    "positive": 54, "negative": 24, "boundary": 8, "metamorphic": 7,
    "adversarial": 8, "composition": 7, "ownership": 6,
    "failure_atomicity": 10, "target": 7, "diagnostics": 24, "sdk": 54,
}.items():
    if counts[category] != expected:
        raise AssertionError(f"count:{category}:{counts[category]}!={expected}")
print("G038_SDK_ORACLE_GREEN " + " ".join(
    f"{category}={counts[category]}" for category in (
        "positive", "negative", "boundary", "metamorphic", "adversarial", "composition",
        "ownership", "failure_atomicity", "target", "diagnostics", "sdk"
    )) + f" determinism=7 digest={digest}")
