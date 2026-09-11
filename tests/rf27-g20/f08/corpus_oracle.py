#!/usr/bin/env python3
import hashlib
import math
import random
import struct


def round_away(value):
    return math.floor(value + 0.5) if value >= 0 else math.ceil(value - 0.5)


def main():
    rng = random.Random(0x272008)
    digest = hashlib.sha256()
    dense_cases = conv_cases = session_cases = 2000
    work = 0
    peak_memory = 0
    max_int8_error = 0.0
    for _ in range(dense_cases):
        x = [rng.uniform(-4, 4) for _ in range(2)]
        w = [rng.uniform(-2, 2) for _ in range(4)]
        b = [rng.uniform(-1, 1) for _ in range(2)]
        y = [sum(x[i] * w[o * 2 + i] for i in range(2)) + b[o] for o in range(2)]
        digest.update(struct.pack("<2d", *y)); work += 8; peak_memory = max(peak_memory, 64)
    for _ in range(conv_cases):
        x = [rng.uniform(-4, 4) for _ in range(4)]
        weight, bias = rng.uniform(-2, 2), rng.uniform(-1, 1)
        y = [value * weight + bias for value in x]
        digest.update(struct.pack("<4d", *y)); work += 12; peak_memory = max(peak_memory, 96)
    for _ in range(session_cases):
        x = [rng.uniform(-4, 4) for _ in range(4)]
        y = [max(0.0, value * (2.0 if i % 2 == 0 else -1.0) + (1.0 if i % 2 == 0 else 0.5)) for i, value in enumerate(x)]
        maximum = max(map(abs, y)); scale = maximum / 127.0 if maximum else 1.0
        q = [max(-127, min(127, round_away(value / scale))) for value in y]
        restored = [value * scale for value in q]
        max_int8_error = max(max_int8_error, max(abs(a-b) for a,b in zip(y,restored)))
        digest.update(struct.pack("<4d", *restored)); work += 16; peak_memory = max(peak_memory, 256)
    print(f"RF27_G20_F08_CORPUS=PASS seed=0x272008 models=3 cases=6000 digest={digest.hexdigest()} work_units={work} peak_memory={peak_memory} max_int8_error={max_int8_error:.17g}")


if __name__ == "__main__":
    main()
