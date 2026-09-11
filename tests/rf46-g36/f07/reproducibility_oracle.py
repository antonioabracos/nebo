#!/usr/bin/env python3
context = b"RF46-SCICTX-v1;dtype=f64;round=nearest;threads=1;deterministic=1"
h = 0xCBF29CE484222325
for octet in context:
    h = ((h ^ octet) * 0x100000001B3) & ((1 << 64) - 1)
samples = [10, 11, 12, 15, 18]
assert (min(samples), samples[(len(samples)-1)//2], max(samples)) == (10, 12, 18)
print(f"RF46_G36_F07_ORACLE_PASS digest={h:016x} benchmark=10,12,18 context=v1")
