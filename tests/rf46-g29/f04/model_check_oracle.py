#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x462904); safe=violated=deadlock=0; rows=[]
for _ in range(70000):
    n=r.randrange(1,17); transitions=[r.randrange(1<<n) for _ in range(n)]; initial=1<<r.randrange(n); unsafe=r.randrange(1<<n)
    visited=frontier=initial; depth=0; witness=-1
    while frontier:
        hit=frontier&unsafe
        if hit: witness=(hit&-hit).bit_length()-1; break
        nxt=0
        for s in range(n):
            if frontier>>s&1: nxt|=transitions[s]
        frontier=nxt&~visited; visited|=frontier; depth+=1
    if witness>=0: state="violated"; violated+=1
    else: state="safe"; safe+=1
    deadlock+=not frontier and visited==initial
    rows.append(f"{n}:{initial}:{unsafe}:{state}:{witness}:{depth}:{visited}")
assert safe and violated and deadlock
print(f"RF46_G29_F04_ORACLE=PASS cases=70000 safe={safe} violated={violated} initial_deadlock={deadlock} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
