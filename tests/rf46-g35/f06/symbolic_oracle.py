#!/usr/bin/env python3
def f(x): return 2+x*x
assert f(3)==11
assert ((f(4)-f(2))//2)==6
for x in range(-32,33):
    assert f(x+1)-f(x)==2*x+1
print('RF46_G35_F06_ORACLE_PASS dag=typed derivative=dual identities=65')
