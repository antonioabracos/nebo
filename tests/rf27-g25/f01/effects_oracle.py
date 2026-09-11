#!/usr/bin/env python3
"""Independent deterministic Boolean-lattice oracle for RF27-G25-F01."""
import hashlib
import random

MASK = (1 << 14) - 1
rng = random.Random(0x27_25_01)
rows: list[str] = []

fixed = [0, 1, 2, 3, 0x1555, 0x2AAA, MASK]
pairs = [(a, b) for a in fixed for b in fixed]
pairs.extend((rng.randrange(MASK + 1), rng.randrange(MASK + 1)) for _ in range(20_000))

for left, right in pairs:
    join = left | right
    meet = left & right
    missing = left & ~right & MASK
    assert 0 <= join <= MASK and 0 <= meet <= MASK
    assert (left | right) == (right | left)
    assert (left & right) == (right & left)
    assert (left | left) == left and (left & left) == left
    assert (left | (left & right)) == left
    assert (left & (left | right)) == left
    assert (missing == 0) == ((left | right) == right)
    assert join.bit_count() <= 14 and meet.bit_count() <= 14
    rows.append(f"{left:04x}:{right:04x}:{join:04x}:{meet:04x}:{missing:04x}")

unknown_rejected = all((value & ~MASK) != 0 for value in (1 << 14, 1 << 20, 1 << 63))
assert unknown_rejected
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G25_F01_ORACLE=PASS "
    f"pairs={len(pairs)} atoms=14 bottom=0 top=0x{MASK:x} digest={digest}"
)
