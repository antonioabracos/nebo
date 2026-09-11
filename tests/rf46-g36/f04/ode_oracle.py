#!/usr/bin/env python3
import math
def euler(n):
    h=1/n; y=1.0
    for _ in range(n): y += h*y
    return y
coarse=euler(512); fine=euler(1024)
assert abs(fine-math.e)<0.002
assert abs(fine-math.e)<abs(coarse-math.e)
print(f'RF46_G36_F04_ORACLE_PASS ode=euler steps=1024 error={abs(fine-math.e):.9f} event=threshold')
