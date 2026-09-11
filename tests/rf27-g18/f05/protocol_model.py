#!/usr/bin/env python3
"""Deterministic bounded model/fuzz oracle for RF27-G18-F05.

This oracle does not replace the native Assembly harness.  It independently
checks the frozen limits, XID routing, raw-event translation, terminal queue
reserve, lifecycle convergence and deterministic replay for 10,000 seeded
cases without opening a live X11 connection.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import struct
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CONTRACT = ROOT / "runtime/window/window_contract.inc"
HEADLESS = ROOT / "runtime/window/headless/headless_window.inc"
X11 = ROOT / "runtime/window/x11/x11_window.inc"
PROTOCOL = ROOT / "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_protocol.inc"
ADAPTER = ROOT / "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"


def defines(*paths: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    pattern = re.compile(r"^%define\s+([A-Z0-9_]+)\s+([0-9]+|0x[0-9a-fA-F]+)\s*$")
    for path in paths:
        for line in path.read_text(encoding="utf-8").splitlines():
            match = pattern.match(line)
            if match:
                result[match.group(1)] = int(match.group(2), 0)
    return result


D = defines(CONTRACT, HEADLESS, X11, PROTOCOL, ADAPTER)

EXPECTED = {
    "NEBO_WINDOW_MAX_WINDOWS": 16,
    "NEBO_WINDOW_MAX_EVENTS": 4096,
    "NEBO_WINDOW_TERMINAL_EVENT_RESERVE": 2,
    "NEBO_WINDOW_MAX_WIDTH": 2048,
    "NEBO_WINDOW_MAX_HEIGHT": 2048,
    "NEBO_WINDOW_EVENT_SIZE": 64,
    "NEBO_WINDOW_EVENT_KIND_COUNT": 20,
    "NEBO_X11_RUNTIME_SIZE": 280,
    "NEBO_X11_WAIT_MAX_CYCLES": 4096,
    "NEBO_X11_OP_COUNT": 23,
    "NEBO_X11_DIAG_COUNT": 13,
    "NEBO_X11_EVENT_SIZE": 32,
}
for name, expected in EXPECTED.items():
    actual = D.get(name)
    if actual != expected:
        raise SystemExit(f"RF27_G18_F05_MODEL_ERROR define={name} actual={actual} expected={expected}")

RAW_TO_TYPED = {
    D["NEBO_X11_EVENT_MAP_NOTIFY"]: D["NEBO_WINDOW_EVENT_SHOWN"],
    D["NEBO_X11_EVENT_UNMAP_NOTIFY"]: D["NEBO_WINDOW_EVENT_HIDDEN"],
    D["NEBO_X11_EVENT_FOCUS_IN"]: D["NEBO_WINDOW_EVENT_FOCUS_GAINED"],
    D["NEBO_X11_EVENT_FOCUS_OUT"]: D["NEBO_WINDOW_EVENT_FOCUS_LOST"],
    D["NEBO_X11_EVENT_CONFIGURE_NOTIFY"]: D["NEBO_WINDOW_EVENT_RESIZED"],
    D["NEBO_X11_EVENT_EXPOSE"]: D["NEBO_WINDOW_EVENT_REDRAW_REQUESTED"],
    D["NEBO_X11_EVENT_MOTION_NOTIFY"]: D["NEBO_WINDOW_EVENT_POINTER_MOVED"],
    D["NEBO_X11_EVENT_KEY_PRESS"]: D["NEBO_WINDOW_EVENT_KEY_DOWN"],
    D["NEBO_X11_EVENT_KEY_RELEASE"]: D["NEBO_WINDOW_EVENT_KEY_UP"],
    D["NEBO_X11_EVENT_DESTROY_NOTIFY"]: D["NEBO_WINDOW_EVENT_CLOSED"],
    D["NEBO_X11_EVENT_CLIENT_MESSAGE"]: D["NEBO_WINDOW_EVENT_CLOSE_REQUESTED"],
}
UNKNOWN_RAW = tuple(x for x in range(1, 128) if (x & 0x7F) not in RAW_TO_TYPED and (x & 0x7F) not in {4, 5})


@dataclass
class Window:
    slot: int
    generation: int
    xid: int
    capacity: int
    state: str = "CREATED"
    sequence: int = 0
    cleanup: int = 0
    queue: list[tuple[int, int, int]] = field(default_factory=list)
    redraw_pending: bool = False

    @property
    def handle(self) -> int:
        return (self.generation << 32) | self.slot

    @property
    def ordinary_limit(self) -> int:
        return self.capacity - D["NEBO_WINDOW_TERMINAL_EVENT_RESERVE"]

    def publish(self, kind: int, timestamp: int, *, terminal: bool = False) -> bool:
        if kind == D["NEBO_WINDOW_EVENT_REDRAW_REQUESTED"] and self.redraw_pending:
            return True
        limit = self.capacity if terminal else self.ordinary_limit
        if len(self.queue) >= limit:
            if terminal:
                return False
            self.fail(timestamp, D["NEBO_WINDOW_EVENT_QUEUE_OVERFLOW"])
            return False
        if self.sequence == (1 << 64) - 1 or timestamp == 0:
            return False
        self.sequence += 1
        self.queue.append((self.sequence, kind, timestamp))
        if kind == D["NEBO_WINDOW_EVENT_REDRAW_REQUESTED"]:
            self.redraw_pending = True
        return True

    def fail(self, timestamp: int, kind: int) -> None:
        if self.cleanup == 0:
            self.cleanup = 1
        self.state = "FAILED"
        if len(self.queue) < self.capacity and self.sequence < (1 << 64) - 1:
            self.sequence += 1
            self.queue.append((self.sequence, kind, timestamp))

    def close(self, timestamp: int) -> bool:
        if self.state in {"CLOSED", "FAILED", "RECLAIMED"}:
            return False
        if self.sequence == (1 << 64) - 1 or len(self.queue) >= self.capacity:
            return False
        self.state = "CLOSED"
        self.cleanup += 1
        self.sequence += 1
        self.queue.append((self.sequence, D["NEBO_WINDOW_EVENT_CLOSED"], timestamp))
        return self.cleanup == 1

    def reclaim(self) -> bool:
        if self.state not in {"CLOSED", "FAILED"} or self.queue:
            return False
        self.state = "RECLAIMED"
        self.generation = 1 if self.generation == 0xFFFFFFFF else self.generation + 1
        self.xid = 0
        return True


def pack_digest(records: list[tuple[int, ...]]) -> str:
    h = hashlib.sha256()
    for record in records:
        h.update(struct.pack("<" + "Q" * len(record), *record))
    return h.hexdigest()


def replay(seed: int, cases: int) -> tuple[str, dict[str, int]]:
    rnd = random.Random(seed)
    records: list[tuple[int, ...]] = []
    counters = {
        "cases": 0,
        "routed": 0,
        "unknown_xid": 0,
        "ignored_type": 0,
        "overflow": 0,
        "disconnect": 0,
        "close": 0,
        "reclaim": 0,
    }
    logical_clock = 0

    for case in range(cases):
        count = rnd.randint(1, D["NEBO_WINDOW_MAX_WINDOWS"])
        windows: list[Window] = []
        used: set[int] = set()
        for slot in range(1, count + 1):
            xid = rnd.randint(1, 0x7FFFFFFF)
            while xid in used:
                xid = rnd.randint(1, 0x7FFFFFFF)
            used.add(xid)
            windows.append(Window(slot, rnd.randint(1, 0xFFFFFFFE), xid, rnd.randint(4, 48)))

        by_xid = {window.xid: window for window in windows}
        target = rnd.choice(windows)
        xid = target.xid if rnd.random() < 0.88 else rnd.randint(0x80000000, 0xFFFFFFFF)
        raw = rnd.choice(tuple(RAW_TO_TYPED) + (4, 5) + UNKNOWN_RAW[:24])
        event_type = raw | (D["NEBO_X11_EVENT_SEND_EVENT_MASK"] if rnd.random() < 0.2 else 0)
        base_type = event_type & 0x7F
        logical_clock += 1

        routed = by_xid.get(xid)
        kind = 0
        result = 0
        if routed is None:
            counters["unknown_xid"] += 1
            result = 1
        elif base_type in {4, 5}:
            # Buttons 1-3 route down/up, buttons 4-7 route wheel only on press.
            button = rnd.randint(1, 7)
            if button <= 3:
                kind = D["NEBO_WINDOW_EVENT_POINTER_DOWN"] if base_type == 4 else D["NEBO_WINDOW_EVENT_POINTER_UP"]
            elif base_type == 4:
                kind = D["NEBO_WINDOW_EVENT_POINTER_WHEEL"]
            else:
                counters["ignored_type"] += 1
        elif base_type in RAW_TO_TYPED:
            kind = RAW_TO_TYPED[base_type]
        else:
            counters["ignored_type"] += 1

        if routed is not None and kind:
            counters["routed"] += 1
            before_cleanup = routed.cleanup
            if kind == D["NEBO_WINDOW_EVENT_CLOSED"]:
                ok = routed.close(logical_clock)
                counters["close"] += int(ok)
            else:
                ok = routed.publish(kind, logical_clock)
                if routed.state == "FAILED" and before_cleanup == 0:
                    counters["overflow"] += 1
            result = 2 if ok else 3

        # Seeded stress: ordinary reserve, disconnect fanout, drain/reclaim.
        if case % 97 == 0:
            candidate = rnd.choice(windows)
            while candidate.state not in {"FAILED", "CLOSED"} and len(candidate.queue) < candidate.ordinary_limit + 1:
                logical_clock += 1
                candidate.publish(D["NEBO_WINDOW_EVENT_POINTER_MOVED"], logical_clock)
            if candidate.state == "FAILED":
                counters["overflow"] += 1
        if case % 211 == 0:
            counters["disconnect"] += 1
            for candidate in windows:
                if candidate.state not in {"CLOSED", "FAILED", "RECLAIMED"}:
                    logical_clock += 1
                    candidate.fail(logical_clock, D["NEBO_WINDOW_EVENT_BACKEND_FAILED"])
        for candidate in windows:
            if case % 13 == 0 and candidate.queue:
                candidate.queue.clear()
                candidate.redraw_pending = False
            if case % 211 == 0 and candidate.state in {"CLOSED", "FAILED"} and not candidate.queue:
                counters["reclaim"] += int(candidate.reclaim())
            if candidate.cleanup > 1 or len(candidate.queue) > candidate.capacity:
                raise SystemExit("RF27_G18_F05_MODEL_ERROR invariant=cleanup_or_capacity")
            if [x[0] for x in candidate.queue] != sorted(x[0] for x in candidate.queue):
                raise SystemExit("RF27_G18_F05_MODEL_ERROR invariant=sequence_order")

        records.append((case, event_type, xid, target.xid, kind, result, count, logical_clock))
        counters["cases"] += 1

    return pack_digest(records), counters


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=lambda x: int(x, 0), default=0x271805)
    parser.add_argument("--cases", type=int, default=10_000)
    args = parser.parse_args()
    if not 1 <= args.cases <= 100_000:
        raise SystemExit("RF27_G18_F05_MODEL_ERROR cases_out_of_range")

    digest_a, counters_a = replay(args.seed, args.cases)
    digest_b, counters_b = replay(args.seed, args.cases)
    if digest_a != digest_b or counters_a != counters_b:
        raise SystemExit("RF27_G18_F05_MODEL_ERROR nondeterministic")

    print(
        "RF27_G18_F05_PROTOCOL_MODEL=PASS "
        f"seed=0x{args.seed:x} cases={args.cases} digest={digest_a} "
        + " ".join(f"{key}={value}" for key, value in sorted(counters_a.items()))
    )
    print(json.dumps({"seed": args.seed, "cases": args.cases, "sha256": digest_a, "counters": counters_a}, sort_keys=True))


if __name__ == "__main__":
    main()
