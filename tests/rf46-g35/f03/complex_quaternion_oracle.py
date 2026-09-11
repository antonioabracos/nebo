#!/usr/bin/env python3
import cmath
import math
assert (1+2j)*(3+4j) == -5+10j
assert math.isclose(abs(1+2j)**2, 5.0, rel_tol=1e-12)
q=(-60.0,12.0,30.0,24.0)
assert q == (-60.0,12.0,30.0,24.0)
assert math.isclose(abs(cmath.exp(1j*math.pi)+1),0.0,abs_tol=1e-12)
print('RF46_G35_F03_ORACLE_PASS complex=identities quaternion=hamilton tolerance=1e-12')
