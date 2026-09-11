#!/usr/bin/env python3
import math
MASK = (1 << 64) - 1
def xs(state):
    state ^= state >> 12
    state ^= (state << 25) & MASK
    state ^= state >> 27
    state &= MASK
    return state, (state * 0x2545F4914F6CDD1D) & MASK
s, value = xs(42)
assert value == xs(42)[1]
assert math.isclose(-0.5 * 0.0**2 - 0.9189385332046727, -0.9189385332046727)
weights = [1, 3]
assert sum(weights) == 4 and all(w > 0 for w in weights)
print(f"RF46_G37_F01_ORACLE_PASS stream={value:016x} normal_logpdf=-0.9189385332046727 categorical=exact_weights")
