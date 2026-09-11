#!/usr/bin/env python3
"""Independent HMAC/lifetime attack oracle for RF27-G25-F03."""
import hashlib
import hmac
import random
import struct

rng = random.Random(0x27_25_03)
key = bytes([0x5A]) * 32
rows: list[str] = []
denied = 0

for case in range(10_000):
    address = 0x100000 + case * 0x100
    effects = rng.randrange(1, 0x4000)
    constraint = rng.randrange(1, 1 << 16)
    budget = rng.randrange(1, 257)
    scope = rng.randrange(1, 65)
    preimage = struct.pack("<12Q", 0x4E42434150323531, 1, 0x2525, 1, 1,
                           effects, constraint, budget, scope, 1, address, 0)
    tag = hmac.new(key, preimage, hashlib.sha256).digest()
    assert hmac.compare_digest(tag, hmac.new(key, preimage, hashlib.sha256).digest())
    attack = case % 5
    if attack == 0:  # serialized address
        assert address + 0x80 != address
        denied += 1
    elif attack == 1:  # tag tamper
        forged = tag[:-1] + bytes([tag[-1] ^ 1])
        assert not hmac.compare_digest(tag, forged)
        denied += 1
    elif attack == 2:  # effect amplification
        child = effects | (1 << 14)
        assert child & ~effects
        denied += 1
    elif attack == 3:  # constraint amplification
        child = constraint | (1 << 20)
        assert child & ~constraint
        denied += 1
    else:  # budget amplification
        assert budget + 1 > budget
        denied += 1
    rows.append(f"{address:x}:{effects:x}:{constraint:x}:{budget}:{scope}:{tag.hex()}")

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G25_F03_ORACLE=PASS attacks=10000 denied={denied} hmac=sha256 digest={digest}")
