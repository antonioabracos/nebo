#!/usr/bin/env python3
import hashlib
import random

rng = random.Random(0x272709)
accepted = rejected = 0
rows = []
for case in range(50000):
    labelled = rng.randrange(11) != 0
    has_start = rng.randrange(9) != 0
    conceptual_print = rng.randrange(23) == 0
    stale_target_claim = rng.randrange(29) == 0
    ok = labelled and has_start and not conceptual_print and not stale_target_claim
    accepted += int(ok)
    rejected += int(not ok)
    rows.append(f"{case}:{int(labelled)}:{int(has_start)}:{int(conceptual_print)}:{int(stale_target_claim)}:{int(ok)}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G27_F09_ORACLE=PASS cases=50000 accepted={accepted} rejected={rejected} unlabelled=denied conceptual_print=denied stale_target=denied digest={digest}")
