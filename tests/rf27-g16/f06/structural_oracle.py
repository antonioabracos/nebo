#!/usr/bin/env python3
a = [[1.0, 2.0], [3.0, 4.0]]
b = [[5.0, 6.0], [7.0, 8.0]]
assert a + b == [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [7.0, 8.0]]
assert [a, b][1][1][1] == 8.0
assert a[:1] + a[1:] == a
padded = [[0.0] * 4, [0.0, 1.0, 2.0, 0.0], [0.0, 3.0, 4.0, 0.0], [0.0] * 4]
assert padded[2][2] == 4.0
product = [[sum(a[i][k] * b[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
assert product == [[19.0, 22.0], [43.0, 50.0]]
print("RF27_G16_F06_REFERENCE_ORACLE_PASS vectors=12 provider=python_stdlib packages=none")
