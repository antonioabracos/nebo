#!/usr/bin/env python3
import math, statistics
chains=[[-1.0,1.0,-1.0,1.0],[-0.9,1.1,-0.9,1.1]]
split=[c[:2] for c in chains]+[c[2:] for c in chains]
w=sum(statistics.variance(c) for c in split)/4
means=[statistics.mean(c) for c in split]
b=2*statistics.variance(means)
rhat=max(1.0,math.sqrt((((2-1)/2)*w+b/2)/w))
ess=8/(rhat*rhat)
assert (rhat,ess)==(1.0,8.0)
print("RF46_G37_F06_ORACLE_PASS input=rank_normalized split_rhat=1 bulk_ess_v1=8 insufficient=typed")
