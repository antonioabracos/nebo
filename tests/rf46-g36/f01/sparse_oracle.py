#!/usr/bin/env python3
rows=[[(0,1),(2,2)],[(1,3)]]; x=[4,5,6]
y=[sum(x[j]*v for j,v in row) for row in rows]
assert y==[16,15]
assert all(row[i][0]<row[i+1][0] for row in rows for i in range(len(row)-1))
print('RF46_G36_F01_ORACLE_PASS csr=canonical spmv=dense_differential no_densification=YES')
