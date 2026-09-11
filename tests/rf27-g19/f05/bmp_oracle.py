#!/usr/bin/env python3
"""Independent deterministic parser model for the frozen BMP3 subset."""
import hashlib
import random
import struct

SEED = 0x271905
CASES = 5000

def inspect(data: bytes):
    if len(data) < 54:
        return ("truncated",)
    if data[:2] != b"BM":
        return ("magic",)
    size, off, dib = struct.unpack_from("<III", data, 2)[0], struct.unpack_from("<I", data, 10)[0], struct.unpack_from("<I", data, 14)[0]
    if size != len(data) or size < 54:
        return ("header",)
    if off != 54 or dib != 40:
        return ("unsupported",)
    width, height, planes, bpp, comp, image = struct.unpack_from("<iiHHII", data, 18)
    if width <= 0 or width > 2048:
        return ("limit",)
    if height <= 0:
        return ("unsupported",)
    if height > 2048:
        return ("limit",)
    if planes != 1 or bpp not in (24, 32) or comp != 0:
        return ("unsupported",)
    row = (width * (bpp // 8) + 3) & ~3
    pixels = row * height
    if pixels > 16 * 1024 * 1024:
        return ("limit",)
    if image not in (0, pixels) or size != 54 + pixels:
        return ("header",)
    return ("ok", width, height, bpp, row, pixels)

def canonical(width, height, bpp):
    row = (width * (bpp // 8) + 3) & ~3
    pixels = row * height
    head = struct.pack("<2sIHHIIIIHHIIIIII", b"BM", 54 + pixels, 0, 0, 54, 40,
                       width, height, 1, bpp, 0, pixels, 0, 0, 0, 0)
    return head + bytes(pixels)

rng = random.Random(SEED)
h = hashlib.sha256()
accepted = 0
rejected = 0
for i in range(CASES):
    if i % 5 == 0:
        data = canonical(rng.randint(1, 64), rng.randint(1, 64), rng.choice((24, 32)))
    else:
        n = rng.randint(0, 300)
        buf = bytearray(rng.getrandbits(8) for _ in range(n))
        if n >= 54 and i % 3 == 0:
            base = canonical(rng.randint(1, 8), rng.randint(1, 8), rng.choice((24, 32)))
            buf = bytearray(base)
            p = rng.randrange(54)
            buf[p] ^= 1 << rng.randrange(8)
        data = bytes(buf)
    result = inspect(data)
    accepted += result[0] == "ok"
    rejected += result[0] != "ok"
    h.update(repr(result).encode("ascii") + b"\n")
assert inspect(canonical(2, 2, 32)) == ("ok", 2, 2, 32, 8, 16)
print(f"RF27_G19_F05_ORACLE=PASS seed=0x{SEED:x} cases={CASES} accepted={accepted} rejected={rejected} digest={h.hexdigest()}")
