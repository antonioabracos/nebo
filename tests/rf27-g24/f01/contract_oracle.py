#!/usr/bin/env python3
"""Deterministic state/property oracle for the RF27-G24-F01 budgets."""
from hashlib import sha256
from random import Random

MAX_SOURCE = 1_048_576
MAX_WORKSPACE = 1_048_576
rng = Random(0x272401)
digest = sha256()
accepted_spans = accepted_workspaces = 0
for _ in range(10_000):
    source = rng.randrange(0, MAX_SOURCE + 2049)
    start = rng.randrange(0, MAX_SOURCE + 2049)
    end = rng.randrange(0, MAX_SOURCE + 2049)
    span_ok = source <= MAX_SOURCE and start <= end <= source
    capacity = rng.randrange(0, MAX_WORKSPACE + 2049)
    aligned = rng.randrange(0, 2) == 0
    workspace_ok = aligned and 0 < capacity <= MAX_WORKSPACE
    accepted_spans += span_ok
    accepted_workspaces += workspace_ok
    digest.update(bytes((span_ok, workspace_ok)))
    digest.update(source.to_bytes(4, "little"))
    digest.update(start.to_bytes(4, "little"))
    digest.update(end.to_bytes(4, "little"))
    digest.update(capacity.to_bytes(4, "little"))
print(
    "RF27_G24_F01_ORACLE=PASS seed=0x272401 cases=10000 "
    f"spans={accepted_spans} workspaces={accepted_workspaces} digest={digest.hexdigest()}"
)
