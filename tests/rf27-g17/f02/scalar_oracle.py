#!/usr/bin/env python3
import math
a = [1.0, 2.0, 3.0, 4.0, 5.0]
b = [5.0, 4.0, 3.0, 2.0, 1.0]
assert [x + y for x, y in zip(a, b)] == [6.0] * 5
assert sum(x * y for x, y in zip(a, b)) == 35.0
assert sum(a) == 15.0
relu = lambda x: x if x > 0.0 else 0.0
assert [relu(x) for x in [-2.0, -0.0, 3.0]] == [0.0, 0.0, 3.0]
assert [float(x) for x in [-2, 0, 7]] == [-2.0, 0.0, 7.0]
ma = [[1.0, 2.0], [3.0, 4.0]]
mb = [[5.0, 6.0], [7.0, 8.0]]
product = [[sum(ma[i][k] * mb[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
assert product == [[19.0, 22.0], [43.0, 50.0]]
assert math.copysign(1.0, relu(-0.0)) == 1.0
print("RF27_G17_F02_REFERENCE_ORACLE_PASS vectors=25 provider=python_stdlib packages=none")
