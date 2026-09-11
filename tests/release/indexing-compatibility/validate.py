#!/usr/bin/env python3
"""Independent native observations for the public 1.0.1 indexing envelope."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
ORIGINAL_SHA = '8e3f4904e2dbf32a40a6734ae119097ed768a6cf9a56491144388166f5f2e91e'


def run(args, cwd, *, trace=False):
    env = dict(PATH='/usr/bin:/bin', HOME=str(cwd), TMPDIR=str(cwd),
               LC_ALL='C', LANG='C', TZ='UTC')
    if trace:
        env['NEBO_CONSOLE_TRACE'] = '1'
    return subprocess.run(list(map(str, args)), cwd=cwd, env=env,
                          capture_output=True, timeout=30)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--compiler', type=Path, default=ROOT/'build/bin/neboc')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    authority = json.loads((ROOT/'docs/specifications/nebo-language/NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json').read_text())
    assert authority['registry_id'] == 'NSR-RES-015-COMPAT-1.0.1'
    assert authority['related_registry_id'] == 'NSR-RES-015'
    assert authority['state'] == 'LEGACY_PUBLIC_COMPATIBILITY_ACTIVE'
    assert authority['valid_indices'] == [0, 1, 2, 3]
    assert authority['general_indexing'] == authority['slicing'] == 'RESERVED'
    assert authority['default_warning'] is None and not authority['separate_mode']
    assert not authority['user_defined_index_protocol']
    assert authority['compatibility_window']['removal_version'] is None
    original = ROOT/'tests/release/indexing-compatibility/fixtures/public-1.0.1-array.no'
    assert hashlib.sha256(original.read_bytes()).hexdigest() == ORIGINAL_SHA
    rows = []
    with tempfile.TemporaryDirectory(prefix='nebo-indexing-') as directory:
        work = Path(directory)

        def positive(name, source, expected, console=None):
            case = work/name
            case.mkdir()
            path = case/'unrelated-name.no'
            path.write_bytes(source if isinstance(source, bytes) else (source+'\n').encode())
            check = run([compiler, 'check', path], case)
            assert check.returncode == 0 and not check.stdout and not check.stderr, (name, 'check', check.stderr)
            binaries = []
            assemblies = []
            for number in (0, 1):
                asm = case/f'output{number}.asm'
                elf = case/f'output{number}.elf'
                emit = run([compiler, 'emit-asm', path, '-o', asm], case)
                assert emit.returncode == 0 and asm.is_file(), (name, 'emit', emit.stderr)
                build = run([compiler, 'build', path, '-o', elf], case)
                assert build.returncode == 0 and elf.is_file(), (name, 'build', build.stderr)
                raw = elf.read_bytes()
                assert raw[:7] == b'\x7fELF\x02\x01\x01'
                assert not run(['nm', '-u', elf], case).stdout
                headers = run(['readelf', '-lW', elf], case)
                assert b'INTERP' not in headers.stdout
                observed = run([elf], case, trace=console is not None)
                assert observed.returncode == expected and not observed.stderr, (name, expected, observed.returncode, observed.stderr)
                if console is None:
                    assert not observed.stdout, (name, observed.stdout)
                else:
                    magic, count, length, pubs = struct.unpack_from('<8sQQQ', observed.stdout)
                    assert magic == b'NEBOTRC1' and count == pubs == len(console)
                    assert observed.stdout[32+count*8:] == ''.join(console).encode()
                    assert length == len(''.join(console).encode())
                binaries.append(hashlib.sha256(raw).hexdigest())
                assemblies.append(hashlib.sha256(asm.read_bytes()).hexdigest())
            assert binaries[0] == binaries[1] and assemblies[0] == assemblies[1], name
            rows.append(dict(id=name, status='PASS', expected_exit=expected,
                             source_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                             elf_sha256=binaries[0], assembly_sha256=assemblies[0],
                             builds=2, console=console))
            return binaries[0]

        positive('published-original', original.read_bytes(), 5)
        positive('published-migration', (ROOT/'tests/release/indexing-compatibility/fixtures/migrated-array.no').read_bytes(), 5)
        formatter = ROOT/'build/bin/nebo-symbol-format'
        for profile in ('preserve', 'ascii', 'math'):
            formatted = subprocess.run([str(formatter), profile], input=original.read_bytes(),
                                       capture_output=True, timeout=15)
            assert formatted.returncode == 0 and not formatted.stderr
            assert formatted.stdout == original.read_bytes(), ('formatter', profile)
        for seed in range(1, 9):
            values = [seed*3+1, seed*5+2, seed*7+3, seed*11+4]
            literal = ','.join(map(str, values))
            for index in range(4):
                prefix = 'start(){Array<Int,4> ['+literal+'].renamed;'
                a = positive(f'legacy-{seed}-{index}', prefix+f'renamed[{index}].return;}}', values[index])
                b = positive(f'canonical-{seed}-{index}', prefix+f'renamed.at({index}).return;}}', values[index])
                # Same canonical semantic/lowering owner, no secondary engine.
                assert a == b, ('alias ELF drift', seed, index)
        for name, source, expected, console in [
            ('two-arrays', 'start(){[1,2,3,4].a;[5,6,7,8].b;(a[1]+b[2]).return;}', 9, None),
            ('binding', 'start(){[7,11,13,17].a;a[2].value;(value+4).return;}', 17, None),
            ('return', 'start(){[1,2,3,4].a;a[1];31.return;}', 31, None),
            ('function', '(Int.self)answer(){[1,2,3,4].a;(a[2]+self).return;}start(){7.answer().return;}', 10, None),
            ('console', 'start(){[1,2,3,4].a;a[2].console();31.return;}', 31, ['3']),
            ('exactly-once-consumer', '(Int.self)observe(){self.console();self.return;}start(){[7,11,13,17].a;"before".console();a[2].observe().v;"after".console();v.return;}', 13, ['before','13','after']),
            ('negative-values', 'start(){[-7,11,-13,17].a;a[0]+a[2];}', 236, None),
            ('integer-limit', 'start(){[9223372036854775807,1,2,3].a;a[0];}', 255, None),
            ('scalar-adjacent', 'start(){31.x;[1,2,3,4].a;a[2];}', 3, None),
        ]:
            positive(name, source, expected, console)
        for n, spelling in enumerate(['0x2','0b10','0o2','0_2',' 2 ','//before\n2','2 //after\n']):
            positive(f'literal-spelling-{n}', 'start(){[1,2,3,4].a;a['+spelling+'];}', 3)

        negatives = {
            'bounds': 'start(){[1,2,3,4].a;a[4];}',
            'negative-index': 'start(){[1,2,3,4].a;a[-1];}',
            'index-type': 'start(){[1,2,3,4].a;a[true];}',
            'dynamic-index': 'start(){1.i;[1,2,3,4].a;a[i];}',
            'index-expression': 'start(){[1,2,3,4].a;a[1+1];}',
            'index-function': '(Int.self)index(){self.console();self.return;}start(){[1,2,3,4].a;a[1.index()];}',
            'slicing': 'start(){[1,2,3,4].a;a[1:2];}',
            'unknown-receiver': 'start(){values[0];}',
            'reserved-index': 'start(){values[index];}',
            'text-receiver': 'start(){"abcd".a;a[1];}',
            'slice-receiver': 'start(){Array<Int,4> [1,2,3,4].a;a.asSlice().s;s[1];}',
            'bool-elements': 'start(){Array<Bool,4> [true,false,true,false].a;a[1];}',
            'length3': 'start(){Array<Int,3> [1,2,3].a;a[1];}',
            'untyped-length3': 'start(){[1,2,3].a;a[1];}',
            'mutable': 'start(){[1,2,3,4].a;a.mutable();a[1];}',
            'name-collision': 'start(){[1,2,3,4].a;5.a;a[1];}',
        }
        for name, source in negatives.items():
            case = work/name
            case.mkdir()
            path = case/'renamed.no'
            path.write_text(source+'\n')
            diagnostics = []
            for mode in ('check','emit-asm','build'):
                output = case/'forbidden'
                command = [compiler, mode, path]
                if mode != 'check':
                    command += ['-o',output]
                observed = run(command, case)
                assert observed.returncode != 0 and observed.stderr and not output.exists(), (name, mode, observed.returncode)
                diagnostics.append(observed.stderr.decode().replace(str(case), 'CASE_ROOT'))
            assert diagnostics[0] == diagnostics[1] == diagnostics[2], name
            rows.append(dict(id=name, status='PASS', expected='REJECTION', diagnostic=diagnostics[0]))
    report = dict(schema='nebo.public-indexing-compatibility.tests.v1', status='PASS',
                  cases=rows, count=len(rows), canonical_elf_equivalence_pairs=32,
                  receiver='immutable Array<Int,4>', index='Int literal',
                  dynamic_index_activated=False, general_indexing_activated=False,
                  slicing_activated=False, original_source_sha256=ORIGINAL_SHA,
                  compiler_sha256=hashlib.sha256(compiler.read_bytes()).hexdigest())
    if args.report:
        args.report.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(dict(status='PASS', cases=len(rows), canonical_elf_equivalence_pairs=32)))


if __name__ == '__main__':
    main()
