#!/usr/bin/env python3
matrix = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
assert [sum(row) for row in matrix] == [6.0, 15.0]
assert [sum(matrix[r][c] for r in range(2)) / 2 for c in range(3)] == [2.5, 3.5, 4.5]
transpose = [list(column) for column in zip(*matrix)]
assert [sum(row) for row in transpose] == [5.0, 7.0, 9.0]
flat = [item for row in matrix for item in row]
assert max(range(len(flat)), key=flat.__getitem__) == 5
assert all([True, True, False, True, True, True]) is False
assert any([True, True, False, True, True, True]) is True
print("RF27_G16_F05_REFERENCE_ORACLE_PASS vectors=15 provider=python_stdlib packages=none")
