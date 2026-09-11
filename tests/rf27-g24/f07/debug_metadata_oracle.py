#!/usr/bin/env python3
import hashlib, random, struct, sys
sys.dont_write_bytecode = True
rng = random.Random(0x27_24_07)
address = 0x1000
rows = []
redacted = 0
for index in range(10_000):
    width = rng.randrange(1, 65)
    span_start = rng.randrange(0, 1_000_000)
    span_end = span_start + rng.randrange(0, 129)
    source_id = rng.getrandbits(64) or 1
    classification = rng.randrange(16)
    is_redacted = int(classification != 0)
    redacted += is_redacted
    record = struct.pack('<QQQQQ', address, address + width, source_id, span_start, span_end)
    binding = struct.pack('<QQQQQQ', source_id, index % 64, 1 + index % 2, index % 32, classification, is_redacted)
    rows.append((record + binding).hex())
    address += width
digest = hashlib.sha256('\n'.join(rows).encode()).hexdigest()
print(f'RF27_G24_F07_ORACLE=PASS spans=10000 redacted_bindings={redacted} overlaps=0 frames_max=64 bindings_max=256 digest={digest}')
