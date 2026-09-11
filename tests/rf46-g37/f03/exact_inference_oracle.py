#!/usr/bin/env python3
from fractions import Fraction
weights = [2,3,5]
posterior = Fraction(weights[1], sum(weights))
assert posterior == Fraction(3,10)
assert float(posterior) == 0.3
assert sum(Fraction(w,sum(weights)) for w in weights) == 1
print("RF46_G37_F03_ORACLE_PASS states=3 evidence=10 query_weight=3 marginal=3/10 normalized=exact")
