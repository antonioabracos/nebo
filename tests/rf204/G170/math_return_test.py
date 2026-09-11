#!/usr/bin/env python3
"""Permanent complete-source return and scalar-effect regression matrix."""
import hashlib
import json
import tempfile
from pathlib import Path
from harness import ROOT, execute, pipeline, reject, Failure
from math_oracle import source_oracle, compare_trace

HERE = Path(__file__).resolve().parent

def run():
    original = (HERE / 'reproducers/math-return.no').read_text()
    prefix, suffix = original.rsplit('23.return;', 1)
    cases = [(f'return-{value}', prefix + f'{value}.return;' + suffix, value)
             for value in (0, 7, 23, 29, 255)]
    changed = original.replace('141;', '197;').replace('max(17, 29)', 'max(71, 13)')
    changed = changed.replace('min(17, 29)', 'min(-17, 59)').replace('abs(-37)', 'abs(-83)')
    changed = changed.replace('clamp(41, 7, 23)', 'clamp(-41, -23, -7)')
    changed = changed.replace('sqrt(9.0)', 'sqrt(49.0)').replace('pow(2.0, 5.0)', 'pow(3.0, 4.0)')
    changed = changed.replace('hypot(5.0, 12.0)', 'hypot(8.0, 15.0)')
    cases += [('changed-math-same-return', changed, 23),
              ('single-call-return', 'start(){std.math.max(17,29);23.return;}\n', 23),
              ('non-math-return', 'start(){(11+12).return;}\n', 23),
              ('implicit-integer', 'start(){std.math.max(17,29);}\n', 29),
              ('implicit-float', 'start(){std.math.sqrt(9.0);}\n', 0)]
    cases += [('atomic-pow', 'start(){std.math.pow(3.0,4.0);23.return;}', 23),
              ('atomic-hypot', 'start(){std.math.hypot(8.0,15.0);23.return;}', 23)]
    # Exercise each transcendental owner separately with nontrivial operands.
    for name, arguments in [('sin', '0.5'), ('cos', '0.5'), ('tan', '0.5'),
                            ('atan2', '3.0, 7.0'), ('exp', '1.25'),
                            ('log', '7.0'), ('log2', '32.0')]:
        cases.append((name, f'start(){{std.math.{name}({arguments});29.return;}}', 29))
    cases.append(('record-capacity', 'start(){' + 'std.math.max(11,37);' * 127 + '7.return;}', 7))
    negatives = [('text-return', 'start(){"bad".return;}', 'NEBO_TYPE_MISMATCH'),
                 ('math-text-return', prefix + '"bad".return;' + suffix, 'NEBO_TYPE_MISMATCH'),
                 ('math-float-return', 'start(){std.math.sqrt(9.0).return;}', 'NEBO_TYPE_MISMATCH'),
                 ('after-return', prefix + '23.return; 7;' + suffix, 'NEBO_PARSE_UNEXPECTED_TOKEN'),
                 ('duplicate-return', prefix + '23.return; 7.return;' + suffix, 'NEBO_PARSE_UNEXPECTED_TOKEN'),
                 ('unclaimed-statement', prefix + 'mystery();23.return;' + suffix, 'NEBO_PARSE_UNEXPECTED_TOKEN'),
                 ('unclaimed-before-math', original.replace('141;', 'mystery();141;'), 'NEBO_PARSE_UNEXPECTED_TOKEN')]
    negatives.append(('record-capacity-plus-one', 'start(){' + 'std.math.max(11,37);' * 128 + '7.return;}', 'NEBO_LIMIT_EXCEEDED'))
    results = []
    with tempfile.TemporaryDirectory(prefix='nebo-G170-math-', dir='/tmp') as directory:
        root = Path(directory)
        for name, source, expected in cases:
            work = root / name; work.mkdir()
            path = work / 'source.no'; path.write_text(source)
            proof = pipeline(path, work, expected, keep_artifacts=True)
            if 'std.math.' in source:
                oracle = source_oracle(source)
                trace = execute([work / 'root-0/program.elf'], work, math_trace=True)
                if trace[0] != expected or trace[2]: raise Failure('MATH_TRACE_STATUS')
                compare_trace(trace[1], oracle)
                proof['observed_math_calls'] = len(oracle)
                proof['math_trace_sha256'] = hashlib.sha256(trace[1]).hexdigest()
                assembly = (work / 'root-0/program.asm').read_text()
                if 'nebo_g014_source_probe' in assembly: raise Failure('LEGACY_WHOLE_FILE_ECLIPSE')
            from harness import release_artifacts
            release_artifacts(work)
            results.append(dict(id=name, result='PASS', **proof))
        # A checked owner must still run even when its result is discarded by
        # an explicit return. These are valid sources with defined runtime traps.
        for name, call in [('sqrt-domain', 'sqrt(-9.0)'), ('log-domain', 'log(0.0)'),
                           ('log2-domain', 'log2(-2.0)'), ('pow-domain', 'pow(-2.0,3.0)')]:
            work = root / name; work.mkdir()
            path = work / 'source.no'; path.write_text('start(){std.math.' + call + ';23.return;}')
            # runtime_core uses 128 + the typed arithmetic-domain trap code 49.
            proof = pipeline(path, work, 177)
            results.append(dict(id=name, result='PASS', **proof))
        for name, source, code in negatives:
            work = root / name; work.mkdir()
            path = work / 'source.no'; path.write_text(source)
            proof = reject(path, work, code)
            results.append(dict(id=name, result='PASS', **proof))
    return {'schema': 1, 'oracle_version': 1, 'cases': results,
            'passed': len(results), 'total': len(cases) + len(negatives) + 4}

if __name__ == '__main__':
    print(json.dumps(run(), sort_keys=True))
