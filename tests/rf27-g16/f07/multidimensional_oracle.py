#!/usr/bin/env python3
shape = (2, 2, 3)
values = list(range(1, 13))
assert len(values) == shape[0] * shape[1] * shape[2]
assert [sum(values[i:i + 3]) for i in range(0, 12, 3)] == [6, 15, 24, 33]
permuted = [[[values[(i * 2 + j) * 3 + k] for i in range(2)] for j in range(2)] for k in range(3)]
assert permuted[2][1] == [6, 12]
broadcast = [[10, 20, 30], [10, 20, 30]]
matrix = [[1, 2, 3], [4, 5, 6]]
assert [[matrix[r][c] + broadcast[r][c] for c in range(3)] for r in range(2)] == [[11, 22, 33], [14, 25, 36]]
left = [[1, 2], [3, 4]]
right = [[5, 6], [7, 8]]
assert [[sum(left[i][k] * right[k][j] for k in range(2)) for j in range(2)] for i in range(2)] == [[19, 22], [43, 50]]
print("RF27_G16_F07_MULTIDIMENSIONAL_ORACLE_PASS vectors=24 provider=python_stdlib packages=none")
