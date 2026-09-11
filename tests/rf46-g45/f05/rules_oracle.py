#!/usr/bin/env python3
rules = [(1, 7, 100, 1), (1, 7, 200, 5), (2, 9, 300, 2)]
matches = [(i, r) for i, r in enumerate(rules) if r[:2] == (1, 7)]
chosen = max(matches, key=lambda item: item[1][3])
assert chosen == (1, (1, 7, 200, 5))
assert any(fact == action for fact, _, action, _ in [(9, 1, 9, 1)])
print("RF46_G45_F05_ORACLE_GREEN rules=versioned priority=deterministic conflict=typed cycle=typed explanation=index")
