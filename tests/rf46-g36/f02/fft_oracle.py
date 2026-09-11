#!/usr/bin/env python3
import cmath
x=[1+0j,0j,0j,0j]
y=[sum(x[n]*cmath.exp(-2j*cmath.pi*k*n/4) for n in range(4)) for k in range(4)]
assert all(abs(v-1)<1e-12 for v in y)
z=[sum(y[k]*cmath.exp(2j*cmath.pi*k*n/4) for k in range(4))/4 for n in range(4)]
assert all(abs(a-b)<1e-12 for a,b in zip(x,z))
print('RF46_G36_F02_ORACLE_PASS fft4=direct_dft inverse=normalized spectrum=power')
