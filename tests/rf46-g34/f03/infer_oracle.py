#!/usr/bin/env python3
rules=[(1,2,101),(2,4,102),(6,8,103)]
state=1; proofs={}
for round_no in range(1,65):
    old=state
    for premise,conclusion,rid in rules:
        if state & premise == premise:
            if not state & conclusion: proofs[conclusion]=(rid,premise)
            state |= conclusion
    if state==old: break
assert state==15 and proofs[8]==(103,6)
print("RF46_G34_F03_ORACLE_GREEN rules=monotonic fixpoint=15 rounds_bounded provenance=rule_premises termination=converged")
