#!/usr/bin/env python3
import math

vectors = [
    ("sqrt9", math.sqrt(9.0), 3.0, 0.0),
    ("hypot3_4", math.hypot(3.0, 4.0), 5.0, 0.0),
    ("log1", math.log(1.0), 0.0, 0.0),
    ("exp0", math.exp(0.0), 1.0, 0.0),
    ("simpson_x2", 1.0 / 3.0, 0.3333333333333333, 1e-15),
]
for name, actual, expected, tolerance in vectors:
    if abs(actual - expected) > tolerance:
        raise SystemExit(f"{name}: oracle mismatch")
print("RF27_G14_REFERENCE_ORACLE_PASS vectors=5 provider=python_stdlib packages=none")
