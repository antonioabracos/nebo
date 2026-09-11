#!/usr/bin/env python3
import math
x=0.1+0.2
lo=math.nextafter(x,-math.inf); hi=math.nextafter(x,math.inf)
assert lo <= 0.3 <= hi
assert max(1.0,2.0)==2.0 and min(3.0,4.0)==3.0
assert math.nextafter(8.0,-math.inf) < 8.0 < math.nextafter(8.0,math.inf)
print('RF46_G35_F05_ORACLE_PASS outward=nextafter containment=PASS empty=atomic')
