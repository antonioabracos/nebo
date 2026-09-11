"""Adversarial runner and source-level inference regression tests."""
import argparse
import json
from pathlib import Path
import sys
import tempfile

from runner import run

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/rf204/G170'))
from harness import pipeline, reject


def selftests():
    rows = []
    for name, script, timeout, limit, reason, status in [
        ('direct-124', 'raise SystemExit(124)', 2, 1048576, None, 124),
        ('deadline', 'while True: pass', .15, 1048576, 'DEADLINE', -15),
        ('open-descendant-pipe', 'import os,time; p=os.fork(); time.sleep(20) if p==0 else None',
         .15, 1048576, 'DEADLINE', 0),
        ('stdout-budget', 'import os;\nwhile True: os.write(1,b"x"*65536)',
         2, 32768, 'LOG_LIMIT', -15),
        ('stdin-eof', 'import sys; assert sys.stdin.read()==""', 2, 1048576, None, 0),
    ]:
        result = run([sys.executable, '-B', '-c', script], timeout=timeout, log_limit=limit)
        assert result['termination_reason'] == reason, (name, result)
        assert result['python_returncode'] == status, (name, result)
        assert result['orphan_processes_remaining'] == 0
        rows.append(dict(id=name, status='PASS', **result))
    return rows


def inference_tests(root):
    rows = []
    for seed, depth in [(17, 1), (29, 4), (71, 8), (17, 12), (29, 16)]:
        directory = root / f'chain-{seed}-{depth}'
        directory.mkdir()
        source = directory / 'renamed.no'
        source.write_text('(Int.self)advance(){self.console();(self+1).return;}'
                          'start(){'+str(seed)+'.advance()'*depth+'.value;value.return;}')
        result = run([str(ROOT / 'build/bin/neboc'), 'g163-native-check', str(source)], timeout=3)
        assert result['termination_reason'] is None and result['python_returncode'] == 0, result
        proof = pipeline(source, directory, seed + depth, kinds=[4]*depth,
                         text=''.join(str(seed+i) for i in range(depth)).encode())
        rows.append(dict(id=directory.name, status='PASS', elapsed_seconds=result['elapsed_seconds'], **proof))
    bad = root / 'unknown-chain'
    bad.mkdir()
    source = bad / 'source.no'
    source.write_text('(Int.self)advance(){self.return;}'
                      'start(){unknown'+'.advance()'*8+'.console();23.return;}')
    rows.append(dict(id='unknown-chain', status='PASS',
                     **reject(source, bad, 'NEBO_NAME_UNDEFINED')))
    # Different statements/functions must not reuse a speculative answer for
    # a spelling whose lexical receiver has changed.
    scoped = root / 'lexical-context'
    scoped.mkdir()
    source = scoped / 'source.no'
    source.write_text('start(){if(true){List<Int>.from([17,29]).v;v.length().console();}'
                      'if(true){Stack<Int>.new().v;v.push(71);v.length().console();}'
                      '23.return;}')
    rows.append(dict(id='lexical-context', status='PASS',
                     **pipeline(source, scoped, 23, kinds=[4,4], text=b'21')))
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    rows = selftests()
    with tempfile.TemporaryDirectory(prefix='nebo-remediation-clusters-') as directory:
        rows += inference_tests(Path(directory))
    args.report.write_text(json.dumps(dict(status='PASS', cases=rows), indent=2)+'\n')
    print(json.dumps(dict(status='PASS', cases=len(rows))))
