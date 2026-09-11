#!/usr/bin/env python3
q = [2.0, 2.0]
c = [-2.0, -4.0]
x = [0.0, 0.0]
lo = [0.0, 0.0]
hi = [10.0, 10.0]
step = 0.25
gradient = [a * b + d for a, b, d in zip(q, x, c)]
candidate = [min(u, max(l, b - step * g)) for b, g, l, u in zip(x, gradient, lo, hi)]
objective = lambda z: sum(0.5 * a * b * b + d * b for a, b, d in zip(q, z, c))
assert candidate == [0.5, 1.0]
assert objective(candidate) < objective(x)
assert sum(g * g for g in gradient) == 20.0
print("RF46_G36_F06_ORACLE_PASS candidate=0.5,1 objective=decreased gradient_norm2=20")
