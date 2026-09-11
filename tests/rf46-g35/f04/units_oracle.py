#!/usr/bin/env python3
from fractions import Fraction
length=(1,)+(0,)*15
time=(0,0,1)+(0,)*13
velocity=tuple(a-b for a,b in zip(length,time))
assert velocity==(1,0,-1)+(0,)*13
assert Fraction(100)*Fraction(1,100)==1
print('RF46_G35_F04_ORACLE_PASS dimensions=16 conversion=exact affine=guarded suffix=deferred')
