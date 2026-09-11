#!/usr/bin/env python3
import hashlib
import math
import random
import struct


def round_away(value):
    return math.floor(value + 0.5) if value >= 0.0 else math.ceil(value - 0.5)


def main():
    rng = random.Random(0x272007)
    values = [rng.uniform(-32.0, 32.0) for _ in range(4096)]
    maximum = max(abs(value) for value in values)
    scale = maximum / 127.0 if maximum else 1.0
    quantized = [max(-127, min(127, round_away(value / scale))) for value in values]
    restored = [value * scale for value in quantized]
    errors = [abs(a - b) for a, b in zip(values, restored)]
    assert max(errors) <= scale / 2.0 + 1e-12
    assert quantized == sorted(quantized) if values == sorted(values) else True
    monotonic = sorted(values)
    monotonic_q = [max(-127, min(127, round_away(value / scale))) for value in monotonic]
    assert monotonic_q == sorted(monotonic_q)
    digest = hashlib.sha256()
    digest.update(bytes(value & 0xFF for value in quantized))
    for value in restored:
        digest.update(struct.pack("<d", value))
    mean = sum(errors) / len(errors)
    mse = sum(error * error for error in errors) / len(errors)
    print(f"RF27_G20_F07_ORACLE=PASS seed=0x272007 samples=4096 digest={digest.hexdigest()} scale={scale:.17g} max_error={max(errors):.17g} mean_error={mean:.17g} mse={mse:.17g}")


if __name__ == "__main__":
    main()
