"""G010 source examples and the current independent typed data oracles."""
import argparse
import json
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/rf204/G170'))
from harness import Failure, console_trace, pipeline, reject
import data_test

# Each value follows from the public operation and the source inputs. The
# runtime trace validates the sequence and types, separately from process exit.
EXAMPLES = [
    (1, 91, [2, 4, 5, 4, 4, 4, 4], ['score', 1, 'true', 1, 17, 29, 17]),
    (2, 92, [4] * 7, [200, 29, 117, 17, 71, 0, 117]),
    (3, 93, [4] * 6, [3, 1, 29, 71, 3, 1]),
    (4, 94, [5, 4, 4, 4, 5, 4], ['true', 88, 117, 0, 'false', 1]),
    (5, 95, [4] * 9, [0, 2, 2, 1, 2, 3, 17, 71, 3]),
    (6, 96, [4, 4, 2] + [4] * 9, [17, 29, 'ready', 17, 29, 36, 71, 78, 2, 2, 29, 2]),
]


def run_examples(root):
    results = []
    for number, status, kinds, values in EXAMPLES:
        source = ROOT / f'examples/rf204/G010/RF204-G010-S{number:02d}.no'
        work = root / f's{number:02d}'
        work.mkdir()
        proof = pipeline(source, work, status, kinds=kinds,
                         text=''.join(map(str, values)).encode())
        results.append(dict(id=work.name, status='PASS', **proof))
    for name, status, kinds, text in [
        ('metamorphic-table', 101, [4, 4, 4], b'172983'),
        ('metamorphic-stream', 102, [4, 4, 4], b'36782'),
        ('boundary-column', 255, [4, 4], b'31496'),
        ('partial-surface', 1, None, b''),
        ('zero-seed', 0, [4], b'17'),
    ]:
        source = ROOT / f'tests/rf204/G010/cases/{name}.no'
        work = root / name
        work.mkdir()
        results.append(dict(id=name, status='PASS', **pipeline(source, work, status, kinds=kinds, text=text)))
    for name, code in [('unknown-method', 'NEBO_TYPE_MISMATCH'),
                       ('missing-brace', 'NEBO_PARSE_UNEXPECTED_TOKEN')]:
        source = ROOT / f'tests/rf204/G010/cases/{name}.no'
        work = root / name
        work.mkdir()
        results.append(dict(id=name, status='PASS', **reject(source, work, code)))
    # An independently malformed observation must be rejected by the same
    # source-effect oracle used above, even if the executable exits correctly.
    try:
        console_trace(b'wrong output', [4], b'17')
    except Failure:
        results.append(dict(id='known-bad-observation', status='PASS'))
    else:
        raise AssertionError('oracle accepted known-bad output')
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--examples-only', action='store_true')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='nebo-g010-current-') as directory:
        examples = run_examples(Path(directory))
    data = None if args.examples_only else data_test.run()
    if data is not None:
        assert data['passed'] == data['total'] and data['total'] > 0
    result = dict(status='PASS', examples=examples, current_data=data)
    args.report.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(dict(status='PASS', examples=len(examples), data_cases=data['total'] if data else 0)))
