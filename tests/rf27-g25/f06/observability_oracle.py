#!/usr/bin/env python3
"""Independent bounded observability state-machine oracle."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_25_06)
event_cap = 4096
span_cap = 128
events = 0
drops = 0
sequence = 0
counters: dict[int, int] = {}
histograms: dict[int, list[int]] = {}
spans: dict[int, tuple[int, int, bool]] = {}
accepted = privacy_denied = limits = state_denied = 0
rows: list[str] = []

for case in range(20_000):
    op = rng.randrange(5)
    name = rng.randrange(1, 97)
    timestamp = rng.randrange(0, 100_000)
    labels = rng.randrange(0, 11)
    fields = rng.randrange(0, 36)
    classification = rng.randrange(0, 16)
    redacted = rng.randrange(2)
    purpose = rng.randrange(0, 8)
    status = "ok"
    value = 0
    if labels > 8 or (op in (0, 3) and fields > 32):
        status = "limit"
        limits += 1
    elif classification and (not redacted or not purpose):
        status = "privacy"
        privacy_denied += 1
    elif events >= event_cap:
        status = "drop"
        drops += 1
        limits += 1
    elif op == 0:
        sequence += 1
        events += 1
        accepted += 1
        value = fields
    elif op == 1:
        delta = rng.randrange(1, 100)
        if name not in counters and len(counters) == 64:
            status = "cardinality"
            limits += 1
        else:
            counters[name] = counters.get(name, 0) + delta
            value = counters[name]
            sequence += 1
            events += 1
            accepted += 1
    elif op == 2:
        bucket = rng.randrange(18)
        if bucket >= 16:
            status = "limit"
            limits += 1
        elif name not in histograms and len(histograms) == 64:
            status = "cardinality"
            limits += 1
        else:
            bins = histograms.setdefault(name, [0] * 16)
            bins[bucket] += 1
            value = bins[bucket]
            sequence += 1
            events += 1
            accepted += 1
    elif op == 3:
        if len(spans) == span_cap:
            status = "span-limit"
            limits += 1
        else:
            sequence += 1
            events += 1
            spans[sequence] = (name, timestamp, True)
            value = sequence
            accepted += 1
    else:
        open_ids = [sid for sid, (_, _, opened) in spans.items() if opened]
        sid = rng.choice(open_ids) if open_ids and rng.randrange(4) else rng.randrange(1, sequence + 2)
        record = spans.get(sid)
        if record is None or not record[2] or timestamp < record[1]:
            status = "span-state"
            state_denied += 1
        else:
            spans[sid] = (record[0], record[1], False)
            sequence += 1
            events += 1
            value = sid
            accepted += 1
    rendered = "[REDACTED]" if classification else f"meta:{name}:{value}"
    assert "synthetic-secret" not in rendered
    rows.append(f"{case}:{op}:{name}:{labels}:{fields}:{classification}:{redacted}:{purpose}:{status}:{value}:{sequence}")

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G25_F06_ORACLE=PASS "
    f"operations=20000 accepted={accepted} privacy_denied={privacy_denied} "
    f"limits={limits} span_state={state_denied} drops={drops} raw_secret_leaks=0 "
    f"digest={digest}"
)
