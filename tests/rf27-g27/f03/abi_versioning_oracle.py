#!/usr/bin/env python3
import hashlib
import random

SEED = 0x2703
CASES = 50000
KNOWN = 31
VALID = {
    "magic": 0x4E42414249323731,
    "schema": 1,
    "target": 0x7838365F36345F6C,
    "abi_major": 0,
    "abi_minor": 0,
    "runtime_major": 0,
    "runtime_minor": 0,
    "object": 1,
    "features": 3,
    "layout": 0x400801,
}

def classify(meta, supported=KNOWN):
    if meta["magic"] != VALID["magic"]:
        return "corrupt"
    if meta["schema"] != 1:
        return "schema"
    if meta["target"] != VALID["target"]:
        return "target"
    if meta["abi_major"] != 0 or meta["abi_minor"] > 0:
        return "abi"
    if meta["runtime_major"] != 0 or meta["runtime_minor"] > 0:
        return "runtime"
    if meta["object"] != 1:
        return "object"
    if meta["features"] & ~KNOWN or supported & ~KNOWN or meta["features"] & ~supported:
        return "feature"
    if meta["layout"] != VALID["layout"]:
        return "layout"
    return "compatible"

rng = random.Random(SEED)
counts = {name: 0 for name in ("compatible", "corrupt", "schema", "target", "abi", "runtime", "object", "feature", "layout")}
digest = hashlib.sha256()
fields = ["magic", "schema", "target", "abi_major", "abi_minor", "runtime_major", "runtime_minor", "object", "features", "layout"]
for i in range(CASES):
    meta = dict(VALID)
    mode = rng.randrange(12)
    supported = KNOWN
    if mode < 10:
        field = fields[mode]
        meta[field] ^= 1 << rng.randrange(0, 6)
    elif mode == 10:
        supported = rng.randrange(0, KNOWN + 1)
    result = classify(meta, supported)
    counts[result] += 1
    digest.update(i.to_bytes(4, "little"))
    digest.update(result.encode("ascii") + b"\0")
    digest.update(meta["features"].to_bytes(8, "little"))
    digest.update(supported.to_bytes(8, "little"))
assert sum(counts.values()) == CASES
assert classify(dict(VALID), KNOWN) == "compatible"
assert classify({**VALID, "abi_major": 1}, KNOWN) == "abi"
assert classify({**VALID, "features": 32}, KNOWN) == "feature"
print("RF27_G27_F03_ORACLE=PASS cases=%d %s digest=%s" % (
    CASES,
    " ".join("%s=%d" % item for item in counts.items()),
    digest.hexdigest(),
))
