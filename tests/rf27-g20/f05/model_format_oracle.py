#!/usr/bin/env python3
import argparse
import hashlib
import random
import struct

MAGIC = 0x31464D4E
HEADER = 64
ENTRY = 48
MAX_FILE = 1 << 20


def canonical() -> bytes:
    entry = struct.pack("<QBBHI4I2IQ", 0x101, 1, 1, 0, 2, 2, 0, 0, 0, 0, 16, 0)
    data = struct.pack("<2d", 1.5, -2.0)
    payload = entry + data
    header = struct.pack("<IHHIHHIIII", MAGIC, 1, HEADER, HEADER + len(payload), 1, 1, 2, HEADER, ENTRY, HEADER + ENTRY)
    return header + hashlib.sha256(payload).digest() + payload


def parse(blob: bytes):
    if len(blob) < HEADER or len(blob) > MAX_FILE:
        raise ValueError("size")
    magic, version, hsize, fsize, nodes, tensors, elements, moff, mbytes, doff = struct.unpack_from("<IHHIHHIIII", blob)
    if magic != MAGIC:
        raise ValueError("magic")
    if version != 1 or hsize != HEADER:
        raise ValueError("version")
    if fsize != len(blob):
        raise ValueError("size")
    if nodes > 64 or tensors == 0 or tensors > 128 or elements == 0 or elements > 4096:
        raise ValueError("limit")
    if moff != HEADER or mbytes != tensors * ENTRY or doff != HEADER + mbytes or doff > len(blob):
        raise ValueError("manifest")
    previous = total = cursor = 0
    states = {}
    for index in range(tensors):
        off = HEADER + index * ENTRY
        sid, dtype, rank, flags, count, *tail = struct.unpack_from("<QBBHI4I2IQ", blob, off)
        dims, data_off, data_bytes, reserved = tail[:4], tail[4], tail[5], tail[6]
        if sid == 0 or sid <= previous or dtype not in (1, 2) or rank not in range(1, 5) or flags or reserved:
            raise ValueError("manifest")
        if any(d == 0 or d > 4096 for d in dims[:rank]) or any(dims[rank:]):
            raise ValueError("manifest")
        product = 1
        for dim in dims[:rank]:
            product *= dim
        width = 8 if dtype == 1 else 1
        if product != count or count == 0 or count > 4096 or data_off != cursor or data_bytes != count * width:
            raise ValueError("manifest")
        cursor += data_bytes
        total += count
        if cursor > len(blob) - doff or total > 4096:
            raise ValueError("limit")
        states[sid] = (dtype, rank, count, blob[doff + data_off:doff + data_off + data_bytes])
        previous = sid
    if cursor != len(blob) - doff or total != elements:
        raise ValueError("manifest")
    if hashlib.sha256(blob[HEADER:]).digest() != blob[32:64]:
        raise ValueError("checksum")
    return nodes, states


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit-golden", action="store_true")
    args = parser.parse_args()
    valid = canonical()
    if args.emit_golden:
        print(valid.hex())
        return
    assert parse(valid)[1][0x101][3] == struct.pack("<2d", 1.5, -2.0)
    rng = random.Random(0x272005)
    digest = hashlib.sha256()
    for case in range(5000):
        mutant = bytearray(valid)
        mode = case % 10
        if mode == 0:
            mutant[0] ^= 1
        elif mode == 1:
            mutant[4] = 2
        elif mode == 2:
            mutant[8:12] = struct.pack("<I", 127)
        elif mode == 3:
            mutant[14:16] = struct.pack("<H", 129)
        elif mode == 4:
            mutant[20:24] = struct.pack("<I", 65)
        elif mode == 5:
            mutant[72] = 9
        elif mode == 6:
            mutant[73] = 0
        elif mode == 7:
            mutant[76:80] = struct.pack("<I", 0)
        elif mode == 8:
            mutant[100:104] = struct.pack("<I", 15)
        else:
            mutant[112 + rng.randrange(16)] ^= 1 << rng.randrange(8)
        try:
            parse(bytes(mutant))
        except ValueError as error:
            digest.update(error.args[0].encode("ascii"))
            digest.update(case.to_bytes(4, "little"))
        else:
            raise AssertionError(f"hostile case accepted: {case}")
    print(f"RF27_G20_F05_ORACLE=PASS seed=0x272005 cases=5000 digest={digest.hexdigest()}")


if __name__ == "__main__":
    main()
