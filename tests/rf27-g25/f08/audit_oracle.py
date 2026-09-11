#!/usr/bin/env python3
"""Independent deterministic audit-chain policy model for RF27-G25-F08."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_25_08)
accepted = denied = authority = bounds = malformed = 0
chain = bytes(32)
rows: list[str] = []
for case in range(90_000):
    event = rng.randrange(20)
    effect = 1 << rng.randrange(16)
    capability = rng.randrange(9)
    decision = rng.randrange(5)
    error = rng.randrange(18)
    token_ok = rng.randrange(7) != 0
    scope_ok = rng.randrange(8) != 0
    digest_ok = rng.randrange(9) != 0
    if not token_ok or not scope_ok:
        status = "authority"
        authority += 1
    elif not (1 <= event <= 16) or not (1 <= capability <= 6) or effect & ~0x3FFF:
        status = "bounds"
        bounds += 1
    elif not digest_ok or decision not in (1, 2, 3) or error > 15 or (decision == 1) != (error == 0):
        status = "malformed"
        malformed += 1
    elif decision == 1:
        status = "accept"
        accepted += 1
        chain = hashlib.sha256(chain + case.to_bytes(8, "little") + effect.to_bytes(8, "little")).digest()
    else:
        status = "deny"
        denied += 1
        chain = hashlib.sha256(chain + case.to_bytes(8, "little") + error.to_bytes(8, "little")).digest()
    rows.append(f"{case}:{event}:{effect}:{capability}:{decision}:{error}:{int(token_ok)}:{int(scope_ok)}:{int(digest_ok)}:{status}")
digest = hashlib.sha256("\n".join(rows).encode() + chain).hexdigest()
print(f"RF27_G25_F08_ORACLE=PASS cases=90000 accepted={accepted} denied={denied} authority={authority} bounds={bounds} malformed={malformed} digest={digest}")
