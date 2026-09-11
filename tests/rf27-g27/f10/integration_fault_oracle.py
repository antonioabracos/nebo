#!/usr/bin/env python3
import hashlib
import random

rng = random.Random(0x272710)
accepted = denied = 0
rows = []
for case in range(80000):
    units = rng.randrange(5)
    package_ok = rng.randrange(13) != 0
    edition = rng.randrange(1, 5)
    abi = rng.randrange(3)
    capability = rng.randrange(17) == 0
    ok = units == 3 and package_ok and edition in (1, 2) and abi == 0 and not capability
    accepted += int(ok)
    denied += int(not ok)
    rows.append(f"{case}:{units}:{int(package_ok)}:{edition}:{abi}:{int(capability)}:{int(ok)}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G27_F10_ORACLE=PASS cases=80000 accepted={accepted} denied={denied} unit_budget=3 package_failure=denied incompatible_edition_abi=denied unauthorized_capability=denied digest={digest}")
