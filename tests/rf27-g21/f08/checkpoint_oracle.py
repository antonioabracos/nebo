#!/usr/bin/env python3
import hashlib
import pathlib
import random
import struct

root = pathlib.Path(__file__).resolve().parents[3]
golden_hex = (root / 'tests/goldens/rf27-g21/f08/checkpoint.hex').read_text().replace('\n', '')
golden = bytes.fromhex(golden_hex)
assert hashlib.sha256(golden).hexdigest() == 'a56cf01470a648bd7fdd9e948db5f27e969a9273ab002e965ff31d9530b3c79f'
magic, version, header, total, payload_len, step, seed = struct.unpack('<IHHIIQQ', golden[:32])
assert (magic, version, header, total, payload_len, step, seed) == (0x314B4354, 1, 64, 88, 24, 7, 42)
assert hashlib.sha256(golden[64:]).digest() == golden[32:64]
rng = random.Random(0x272108)
digest = hashlib.sha256()
for case in range(4000):
    length = rng.randrange(1, 257)
    payload = rng.randbytes(length)
    step = rng.randrange(10001)
    seed = rng.randrange(1, 1 << 64)
    header = struct.pack('<IHHIIQQ', 0x314B4354, 1, 64, 64 + length, length, step, seed)
    image = header + hashlib.sha256(payload).digest() + payload
    restored = image[64:]
    assert restored == payload
    digest.update(hashlib.sha256(image).digest())
print(f'RF27_G21_F08_ORACLE=PASS seed=0x272108 cases=4000 golden_sha256=a56cf01470a648bd7fdd9e948db5f27e969a9273ab002e965ff31d9530b3c79f digest={digest.hexdigest()}')
