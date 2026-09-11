#!/usr/bin/env python3
"""Dependency-free reference corpus for the bounded RF27 Matrix group."""

import math


def determinant_2x2(a):
    return a[0][0] * a[1][1] - a[0][1] * a[1][0]


def inverse_2x2(a):
    det = determinant_2x2(a)
    if det == 0.0:
        raise ValueError("singular")
    return [
        [a[1][1] / det, -a[0][1] / det],
        [-a[1][0] / det, a[0][0] / det],
    ]


def multiply(a, b):
    return [
        [sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))]
        for i in range(len(a))
    ]


def close(actual, expected, tolerance=1.0e-12):
    if not math.isclose(actual, expected, rel_tol=tolerance, abs_tol=tolerance):
        raise SystemExit(f"oracle mismatch: {actual!r} != {expected!r}")


matrix = [[4.0, 7.0], [2.0, 6.0]]
close(determinant_2x2(matrix), 10.0)
inverse = inverse_2x2(matrix)
for row_actual, row_expected in zip(inverse, [[0.6, -0.7], [-0.2, 0.4]]):
    for actual, expected in zip(row_actual, row_expected):
        close(actual, expected)

identity = multiply(matrix, inverse)
for i, row in enumerate(identity):
    for j, actual in enumerate(row):
        close(actual, 1.0 if i == j else 0.0)

spd = [[4.0, 2.0], [2.0, 3.0]]
l00 = math.sqrt(spd[0][0])
l10 = spd[1][0] / l00
l11 = math.sqrt(spd[1][1] - l10 * l10)
close(l00, 2.0)
close(l10, 1.0)
close(l11, math.sqrt(2.0))

hilbert2 = [[1.0, 0.5], [0.5, 1.0 / 3.0]]
hilbert_inverse = inverse_2x2(hilbert2)
norm_a = max(sum(abs(row[j]) for row in hilbert2) for j in range(2))
norm_inverse = max(sum(abs(row[j]) for row in hilbert_inverse) for j in range(2))
close(norm_a * norm_inverse, 27.0)

try:
    inverse_2x2([[1.0, 2.0], [2.0, 4.0]])
except ValueError:
    pass
else:
    raise SystemExit("singular matrix was accepted")

print("RF27_G15_REFERENCE_ORACLE_PASS vectors=19 provider=python_stdlib packages=none")
