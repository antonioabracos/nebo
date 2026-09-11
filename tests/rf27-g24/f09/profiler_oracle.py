#!/usr/bin/env python3
"""Independent deterministic oracle for the bounded compiler profiler."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_24_09)
events: list[tuple[int, int, int, int, int, int]] = []
stacks: set[int] = set()
total = peak = privacy = limits = cardinality = timing = 0
rows: list[str] = []
for case in range(50_000):
    phase = rng.randrange(0, 6)
    unit = rng.randrange(1, 1025)
    start = rng.randrange(0, 1_000_000)
    end = start + rng.randrange(-2, 200)
    memory = rng.randrange(0, 1 << 24)
    stack = rng.randrange(1, 96)
    classification = rng.randrange(16)
    redacted = rng.randrange(2)
    status = "ok"
    if phase < 1 or phase > 4:
        status = "phase"
        limits += 1
    elif end < start:
        status = "timing"
        timing += 1
    elif classification and not redacted:
        status = "privacy"
        privacy += 1
    elif len(events) == 4096:
        status = "limit"
        limits += 1
    elif stack not in stacks and len(stacks) == 64:
        status = "cardinality"
        cardinality += 1
    else:
        duration = end - start
        stacks.add(stack)
        events.append((phase, unit, duration, memory, stack, int(bool(classification))))
        total += duration
        peak = max(peak, memory)
    rows.append(f"{case}:{phase}:{unit}:{start}:{end}:{memory}:{stack}:{classification}:{redacted}:{status}:{len(events)}")
phase_counts = [sum(event[0] == phase for event in events) for phase in range(1, 5)]
phase_times = [sum(event[2] for event in events if event[0] == phase) for phase in range(1, 5)]
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G24_F09_ORACLE=PASS operations=50000 "
    f"accepted={len(events)} privacy={privacy} limits={limits} cardinality={cardinality} timing={timing} "
    f"stacks={len(stacks)} total={total} peak={peak} phases={','.join(map(str, phase_counts))} "
    f"phase_times={','.join(map(str, phase_times))} raw_secret_leaks=0 digest={digest}"
)
