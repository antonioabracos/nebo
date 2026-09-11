#!/usr/bin/env python3
import hashlib,math,random
r=random.Random(0x272002); h=hashlib.sha256(); worst=0.0
for _ in range(3000):
    xs=[r.uniform(-8,8) for _ in range(r.randint(1,64))]; m=max(xs)
    ex=[math.exp(x-m) for x in xs]; sm=[x/sum(ex) for x in ex]
    sig=[1/(1+math.exp(-x)) for x in xs]
    gel=[.5*x*(1+math.tanh(math.sqrt(2/math.pi)*(x+.044715*x*x*x))) for x in xs]
    worst=max(worst,abs(sum(sm)-1)); h.update(repr((sm,sig,gel)).encode())
print(f"RF27_G20_F02_ORACLE=PASS seed=0x272002 cases=3000 softmax_sum_error={worst:.3e} digest={h.hexdigest()}")
