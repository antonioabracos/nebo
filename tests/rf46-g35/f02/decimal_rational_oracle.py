#!/usr/bin/env python3
from decimal import Decimal, Context, ROUND_HALF_EVEN
from fractions import Fraction
assert Fraction(-6, -8) == Fraction(3, 4)
assert Fraction(1, 3) + Fraction(1, 6) == Fraction(1, 2)
assert Context(prec=16, rounding=ROUND_HALF_EVEN).divide(Decimal(7), Decimal(2)) == Decimal('3.5')
v = 9007199254740993
assert int(float(v)) != v and v.bit_length() - 53 == 1
print('RF46_G35_F02_ORACLE_PASS rational=normalized rounding=explicit loss=factual')
