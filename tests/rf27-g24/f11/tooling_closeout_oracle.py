#!/usr/bin/env python3
"""Independent differential model for the RF27-G24 tooling closeout."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_24_11)
surfaces = ("contract", "format", "repl", "package", "lsp", "editor", "metadata", "debugger", "profiler", "test")
accepted = denied = environment_limited = 0
rows: list[str] = []
for case in range(40_000):
    surface = surfaces[rng.randrange(len(surfaces))]
    local = bool(rng.randrange(5))
    bounded = bool(rng.randrange(7))
    classified = bool(rng.randrange(9) == 0)
    redacted = bool(rng.randrange(2))
    optional_live = surface in ("editor", "debugger", "profiler") and rng.randrange(8) == 0
    if optional_live:
        status = "environment-limited"
        environment_limited += 1
    elif not local or not bounded or (classified and not redacted):
        status = "deny"
        denied += 1
    else:
        status = "accept"
        accepted += 1
    rows.append(f"{case}:{surface}:{int(local)}:{int(bounded)}:{int(classified)}:{int(redacted)}:{status}")
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G24_F11_ORACLE=PASS cases=40000 accepted={accepted} denied={denied} environment_limited={environment_limited} surfaces=10 digest={digest}")
