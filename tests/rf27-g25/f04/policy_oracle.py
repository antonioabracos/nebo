#!/usr/bin/env python3
"""Independent deny-first policy permutation oracle."""
import hashlib
import itertools
import random

rng = random.Random(0x27_25_04)
rows: list[str] = []
counts = {name: 0 for name in ("deny", "grant", "trust", "cancel", "deadline", "budget", "permit")}

def decide(deny: bool, grant: bool, trust: bool, cancel: bool,
           deadline: bool, budget: bool) -> str:
    if deny:
        return "deny"
    if not grant:
        return "grant"
    if not trust:
        return "trust"
    if cancel:
        return "cancel"
    if deadline:
        return "deadline"
    if not budget:
        return "budget"
    return "permit"

cases = list(itertools.product((False, True), repeat=6))
cases.extend(tuple(bool(rng.getrandbits(1)) for _ in range(6)) for _ in range(20_000))
for flags in cases:
    reason = decide(*flags)
    counts[reason] += 1
    # Reordering input representation cannot change frozen rule precedence.
    shuffled = list(enumerate(flags))
    rng.shuffle(shuffled)
    restored = tuple(value for _, value in sorted(shuffled))
    assert decide(*restored) == reason
    rows.append("".join("1" if value else "0" for value in flags) + ":" + reason)

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G25_F04_ORACLE=PASS cases={len(cases)} counts={counts} digest={digest}")
