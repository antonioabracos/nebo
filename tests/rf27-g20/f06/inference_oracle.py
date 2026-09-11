#!/usr/bin/env python3
import hashlib
import math
import random
import struct


def execute(values, features, ops):
    out = list(values)
    for opcode, scale, bias in ops:
        if opcode == "identity":
            continue
        if opcode == "relu":
            out = [max(0.0, value) for value in out]
            continue
        out = [value * scale[index % features] + bias[index % features] for index, value in enumerate(out)]
        if not all(math.isfinite(value) for value in out):
            raise ValueError("nonfinite")
    return out


def main():
    rng = random.Random(0x272006)
    digest = hashlib.sha256()
    total_elements = total_ops = peak_workspace = 0
    for case in range(3000):
        features = rng.randint(1, 8)
        batch = rng.randint(1, 16)
        values = [rng.uniform(-4.0, 4.0) for _ in range(features * batch)]
        scale = [rng.uniform(-2.0, 2.0) for _ in range(features)]
        bias = [rng.uniform(-1.0, 1.0) for _ in range(features)]
        ops = [("scale_bias", scale, bias), ("relu", None, None), ("identity", None, None)]
        first = execute(values, features, ops)
        second = execute(values, features, ops)
        assert first == second and all(value >= 0.0 for value in first)
        packed = b"".join(struct.pack("<d", value) for value in first)
        digest.update(packed)
        digest.update(struct.pack("<III", features, batch, len(ops)))
        total_elements += len(values)
        total_ops += len(values) * len(ops)
        peak_workspace = max(peak_workspace, len(values) * 8)
    print(f"RF27_G20_F06_ORACLE=PASS seed=0x272006 cases=3000 digest={digest.hexdigest()} elements={total_elements} operation_elements={total_ops} peak_workspace={peak_workspace}")


if __name__ == "__main__":
    main()
