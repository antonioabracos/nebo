"""Reuse the Matrix/Tensor function-boundary value and ownership oracles."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
from runner import run
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/rf204/G170'))
from harness import pipeline
import matrix_test
import tensor_test


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path,required=True);args=parser.parse_args()
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-scientific-remediation-') as directory:
        root=Path(directory)
        for kind,module in [('Matrix',matrix_test),('Tensor',tensor_test)]:
            for ordinal,(name,body,status,options) in enumerate(module.function_cases()):
                for padding in ([0,64] if ordinal < 3 else [0]):
                    # Extra declarations contain nested arithmetic parentheses;
                    # their bodies must not become speculative new preambles.
                    unused=''.join(f'(Int.x)unused{i}(){{((x+17)*29).return;}}' for i in range(padding))
                    work=root/f'{kind}-{ordinal}-{padding}';work.mkdir();source=work/'arbitrary.no'
                    source.write_text(f'import "std.scientific" {{ {kind}; }}.scientific;\n'+unused+body)
                    proof=pipeline(source,work,status,**options)
                    rows.append(dict(id=work.name,source_case=name,status='PASS',proof=proof))
    # The sole large original source needs a measured, finite budget. Keep the
    # default 3 s for every other row. Five independent native observations
    # verify progress to the same causal diagnostic before an 8 s replay.
    source=ROOT/'examples/conformance/nebo-v1.0-public-callable-atlas.no'
    measurements=[]
    for _ in range(5):
        observation=run([str(ROOT/'build/bin/neboc'),'g163-native-check',str(source),'--message-format','json-lines'],timeout=15)
        assert observation['termination_reason'] is None and observation['python_returncode']==1
        diagnostic=json.loads(observation['stderr'] or observation['stdout'])
        assert diagnostic['code']=='NEBO_TYPE_MISMATCH'
        assert source.read_bytes()[diagnostic['primary']['start']:diagnostic['primary']['end']]==b'tensor.sum()'
        measurements.append({k:observation[k] for k in ['elapsed_seconds','cpu_seconds','python_returncode','signal','orphan_processes_remaining']})
    worst=max(r['elapsed_seconds'] for r in measurements)
    assert worst < 6, measurements
    args.report.write_text(json.dumps(dict(status='PASS',compiler_sha256=hashlib.sha256((ROOT/'build/bin/neboc').read_bytes()).hexdigest(),cases=rows,atlas_measurements=measurements,
                                          atlas_worst_seconds=worst,atlas_bounded_budget_seconds=8),indent=2)+'\n')
    print(json.dumps(dict(status='PASS',cases=len(rows),atlas_worst_seconds=worst)))


if __name__=='__main__':main()
