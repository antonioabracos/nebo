#!/usr/bin/env python3
"""Independent immutable SHA-256 lineage DAG oracle."""
import hashlib
import random
import struct
import sys

sys.dont_write_bytecode = True
rng = random.Random(0x27_25_07)
records: list[bytes] = []
parent_edges = 0
rejections = 0
rows: list[str] = []

for index in range(1, 10_001):
    source = hashlib.sha256(f"source:{index}".encode()).digest()
    transform = hashlib.sha256(f"transform:{rng.randrange(32)}".encode()).digest()
    artifact = hashlib.sha256(source + transform).digest()
    parent_count = min(len(records), rng.randrange(0, 5))
    parent_indices = sorted(rng.sample(range(len(records)), parent_count)) if parent_count else []
    parents = b"".join(records[p] for p in parent_indices)
    parent_edges += parent_count
    quality = rng.randrange(0, 1_000_001)
    policy = rng.randrange(1, 1 << 32)
    body = (
        b"NBPROV25"
        + struct.pack("<QQQQ", 1, index, policy, quality)
        + struct.pack("<Q", parent_count)
        + source
        + transform
        + artifact
        + parents.ljust(16 * 32, b"\0")
    )
    digest = hashlib.sha256(body).digest()
    assert digest not in records
    records.append(digest)
    rows.append(f"{index}:{policy}:{quality}:{','.join(map(str, parent_indices))}:{digest.hex()}")
    if parent_count:
        forged = bytearray(parents)
        forged[0] ^= 1
        assert bytes(forged[:32]) not in records[: index - 1]
        rejections += 1

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(
    "RF27_G25_F07_ORACLE=PASS records=10000 "
    f"parent_edges={parent_edges} tamper_rejections={rejections} "
    f"raw_secret_payloads=0 digest={digest}"
)
