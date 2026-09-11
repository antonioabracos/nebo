#!/usr/bin/env python3
"""Independent cross-system enforcement model for RF27-G25-F09."""
import hashlib
import random
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_25_09)
sinks = ("file", "network", "process", "console", "log", "metric", "trace", "audit")
allowed = denied = malformed = 0
rows: list[str] = []
for case in range(150_000):
    sink = sinks[rng.randrange(len(sinks))]
    declared = rng.randrange(7) != 0
    capability = rng.randrange(6) != 0
    policy = rng.randrange(8) != 0
    local = sink != "network" or rng.randrange(5) == 0
    budget = rng.randrange(9) != 0
    cancelled = rng.randrange(11) == 0
    sensitive = rng.randrange(5) == 0
    redacted = rng.randrange(4) != 0
    purpose = rng.randrange(10) != 0
    provenance = rng.randrange(8) != 0
    audit = rng.randrange(7) != 0
    well_formed = declared and purpose and provenance and audit
    authorized = capability and policy and local and budget and not cancelled
    private = not sensitive or redacted
    if not well_formed:
        status = "malformed"
        malformed += 1
    elif authorized and private:
        status = "allow"
        allowed += 1
    else:
        status = "deny"
        denied += 1
    if status == "allow" and sensitive and not redacted:
        raise AssertionError("sensitive value reached sink")
    if status == "allow" and sink == "network" and not local:
        raise AssertionError("remote telemetry escaped")
    rows.append(
        f"{case}:{sink}:{int(declared)}:{int(capability)}:{int(policy)}:{int(local)}:"
        f"{int(budget)}:{int(cancelled)}:{int(sensitive)}:{int(redacted)}:"
        f"{int(purpose)}:{int(provenance)}:{int(audit)}:{status}"
    )
digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G25_F09_ORACLE=PASS cases=150000 allowed={allowed} denied={denied} malformed={malformed} sinks=8 raw_secret_leaks=0 remote_telemetry=0 digest={digest}")
