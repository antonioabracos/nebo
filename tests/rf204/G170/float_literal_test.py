"""Exact literal bits versus Python's independent correctly rounded parser."""
import hashlib
import json
import math
import random
import struct
import tempfile
from decimal import Decimal, localcontext
from pathlib import Path
from harness import ROOT, Failure, execute, elf, pipeline, reject


def native_cases():
    values = ['0.0', '0.75', '1.75', '25.3125', '0.1', '1.234567890123456789',
              '9007199254740993.0', '9007199254740995.0',
              '0.' + '0' * 65534, '0.75' + '0' * 65000 + '1',
              '0' * 32000 + '1.75', '9' * 309 + '.0',
              '0.' + '0' * 1300 + '1']
    generator = random.Random(170015)
    bit_patterns = [0, 1, 2, 3, (1 << 52) - 1, 1 << 52,
                    0x3fe8000000000000, 0x3ff0000000000000,
                    0x3ff0000000000001, 0x7feffffffffffffe]
    bit_patterns += [generator.randrange(0, 0x7feffffffffffffe) for _ in range(64)]
    with localcontext() as context:
        context.prec = 2200
        epsilon = Decimal(10) ** -1300
        for bits in bit_patterns:
            value = struct.unpack('<d', struct.pack('<Q', bits))[0]
            upper = math.nextafter(value, math.inf)
            exact = Decimal.from_float(value)
            midpoint = (exact + Decimal.from_float(upper)) / 2
            for number in (exact, midpoint - epsilon, midpoint, midpoint + epsilon):
                if number < 0:
                    continue
                spelling = format(number, 'f')
                values.append(spelling if '.' in spelling else spelling + '.0')
        threshold = Decimal(2) ** 1024 - Decimal(2) ** 970
        for number in (threshold - 1, threshold, threshold + 1):
            values.append(format(number, 'f') + '.0')
    cases = []
    for index, spelling in enumerate(dict.fromkeys(values)):
        bits = struct.unpack('<Q', struct.pack('<d', float(spelling)))[0]
        integer, fraction = spelling.split('.')
        cases.append((f'bits-{index}', spelling, (0, bits, len(integer), len(fraction))))
    for index, spelling in enumerate(('', '.', '1.', '.5', '-1.0', '1.0e3',
                                        '1.2.3', '1a.2', ' 1.0', '1.0\n')):
        cases.append((f'shape-{index}', spelling, (4, 0, 0, 0)))
    cases.append(('source-limit', '0.' + '0' * 65535, (8, 0, 0, 0)))
    return cases


def native_controls(root):
    cases = [(name + '-rounding-' + str(mode), spelling, expected, mode)
             for name, spelling, expected in native_cases() for mode in range(4)]
    data = root/'literal-input.bin'
    data.write_bytes(b''.join(struct.pack('<QQ', len(s.encode()), mode) + s.encode()
                              for _, s, _, mode in cases))
    obj, binary = root/'literal.o', root/'literal-native'
    commands = [
        ['ninja', 'build/obj/foundation_float_lowering.o'],
        ['nasm', '-f', 'elf64', '-I', './', '-DG170_LITERAL_DATA="' + str(data) + '"',
         'tests/rf204/G170/float_literal_native.asm', '-o', obj],
        ['ld', '-m', 'elf_x86_64', '-nostdlib', '-z', 'noexecstack', '--build-id=none',
         '-o', binary, obj, ROOT/'build/obj/foundation_float_lowering.o'],
    ]
    for command in commands:
        status, out, err = execute(command, root, timeout=45)
        if status or err:
            raise Failure('LITERAL_NATIVE_BUILD:' + str((status, out, err)))
    elf(binary)
    status, out, err = execute([binary], root, runtime=True, timeout=30)
    if status or err or len(out) != 32 * len(cases):
        raise Failure('LITERAL_NATIVE_PROTOCOL:' + str((status, len(out), err)))
    rows = []
    for index, (name, spelling, expected, mode) in enumerate(cases):
        observed = struct.unpack_from('<QQQQ', out, index * 32)
        row = dict(id=name, category='native-literal-bits', result='PASS',
                   source_sha256=hashlib.sha256(spelling.encode()).hexdigest(),
                   rounding_mode=mode, expected_bits=hex(expected[1]),
                   observed_bits=hex(observed[1]))
        if observed != expected:
            row.update(result='FAIL', failure='EXACT_LITERAL_BITS:' + repr((expected, observed)))
        rows.append(row)
    return rows


def public_cases():
    rows = []
    for spelling, numerator, denominator in [('0.75', 3, 4), ('1.75', 7, 4),
                                            ('0.125', 1, 8), ('25.3125', 405, 16)]:
        source = f'start(){{({spelling}==({numerator}.0/{denominator}.0)).console();23.return;}}'
        rows.append(('literal-ratio-' + spelling, source, b'true'))
        source = f'start(){{({spelling}==({numerator+1}.0/{denominator}.0)).console();23.return;}}'
        rows.append(('literal-ratio-changed-' + spelling, source, b'false'))
    for value, expected in [('0.75', '0.750'), ('1.75', '1.750'),
                            ('25.3125', '25.312'), ('25.3135', '25.314')]:
        rows.append(('literal-fixed-' + value,
                     f'start(){{{value}.x;"${{x:fixed(3)}}".console();23.return;}}', expected.encode()))
    return rows


def run():
    with tempfile.TemporaryDirectory(prefix='nebo-G170-literal-') as directory:
        root = Path(directory)
        rows = native_controls(root)
        for name, source, text in public_cases():
            work = root/name
            work.mkdir()
            path = work/'source.no'
            path.write_text(source)
            try:
                proof = pipeline(path, work, 23, kinds=[5 if text in (b'true', b'false') else 2], text=text)
                row = dict(result='PASS', **proof)
            except Failure as error:
                row = dict(result='FAIL', failure=str(error))
            rows.append(dict(id=name, category='positive', **row))
        for name, source, diagnostic in [
            ('mixed-ratio', 'start(){(0.75==(3/4)).console();23.return;}', 'NEBO_TYPE_MISMATCH'),
            ('mixed-operands', 'start(){(0.75==(3.0/4)).console();23.return;}', 'NEBO_TYPE_MISMATCH'),
            ('float-status', 'start(){(0.75==(3.0/4.0)).console();23.0.return;}', 'NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
        ]:
            work = root/name
            work.mkdir()
            path = work/'source.no'
            path.write_text(source)
            try:
                row = dict(result='PASS', **reject(path, work, diagnostic))
            except Failure as error:
                row = dict(result='FAIL', failure=str(error))
            rows.append(dict(id=name, category='negative', **row))
    return dict(cases=rows, passed=sum(row['result'] == 'PASS' for row in rows), total=len(rows))


if __name__ == '__main__':
    print(json.dumps(run(), sort_keys=True))
