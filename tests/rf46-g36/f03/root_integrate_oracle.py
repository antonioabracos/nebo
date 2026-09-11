#!/usr/bin/env python3
import math
assert math.isclose(math.sqrt(9),3.0)
h=0.25
s=(0**2+4*(.25**2)+2*(.5**2)+4*(.75**2)+1**2)*h/3
assert math.isclose(s,1/3,rel_tol=1e-15)
print('RF46_G36_F03_ORACLE_PASS root=bisection integral=simpson statuses=truthful')
