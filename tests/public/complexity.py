#!/usr/bin/env python3
"""Bounded regression checks for long receiver chains and scientific dispatch."""
import argparse, hashlib, json, re, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT/'tests/release/post-g204-remediation'), str(ROOT/'tests/rf204/G170')]
from runner import run
from harness import pipeline, reject, human_diagnostic

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def oracle(source):
    text = source.read_text()
    code = re.sub(r'//[^\n]*', '', text)
    # Identity callbacks and a final integer expression have an independent
    # scalar value oracle. No group, filename, hash or measured exit selects it.
    bodies = re.findall(r'\(Int\.self\)\w+\(\)\s*\{\s*self\.return;\s*\}', code)
    rest = re.sub(r'\(Int\.self\)\w+\(\)\s*\{\s*self\.return;\s*\}', '', code)
    positive = re.fullmatch(r'\s*start\(\)\s*\{\s*(\d+)(?:\.\w+\(\))+;\s*\}\s*', rest)
    if positive and bodies:
        return dict(kind='IDENTITY_CALLBACK_VALUE', exit=int(positive[1]) % 256)
    transformed = re.fullmatch(r'\s*start\(\)\s*\{\s*("(?:[^"\\]|\\.)*")\.trim\(\)\.normalizeNewlines\(\)\.lower\(\)\.replaceAll\("::", "/"\)\.split\("/"\)\.join\("-"\)\.padStart\(8, "0"\)\.upper\(\)\.byteLength\(\)\.return;\s*\}\s*', code)
    if transformed:
        value=json.loads(transformed[1]).strip().replace('\r\n','\n').replace('\r','\n').lower().replace('::','/')
        value='-'.join(value.split('/')).rjust(8,'0').upper()
        return dict(kind='COMPOSED_TEXT_VALUE', exit=len(value.encode()))
    if 'RenderPlan;' in code:
        if 'protocol.' in code:
            return dict(kind='UNBOUND_RECEIVER', code='NEBO_NAME_UNDEFINED', phase=5, token='protocol')
        if 'lifecycle.' in code:
            return dict(kind='UNBOUND_RECEIVER', code='NEBO_NAME_UNDEFINED', phase=5, token='lifecycle')
        # Historical slash-delimited label is not a textual literal in the
        # current grammar. Confirm the exact token at the parser diagnostic.
        return dict(kind='LEGACY_SLASH_GRAMMAR', code='NEBO_PARSE_UNEXPECTED_TOKEN', phase=4, token='/')
    if re.search(r'\(Int\.self\)\w+\(Tensor<Int>\.tensor\)', code) and 'tensor.sum()' in code:
        # Historical atlas tensor reduction signature omits its reduction
        # axes/keep-dimensions arguments; current tensor tests own that API.
        return dict(kind='LEGACY_TENSOR_SIGNATURE', code='NEBO_TYPE_MISMATCH', phase=6, token='tensor.sum()')
    raise AssertionError('source has no independent oracle: '+str(source))



def reject_atlas(source, work, diagnostic, budget):
    # The original inventory is explicitly a native admission differential.
    # Verify that phase through all native artifact commands, then separately
    # check the earlier public optional-module visibility boundary.
    for mode in ('emit-asm','build'):
        target=work/(mode+'.native-artifact')
        result=run([str(ROOT/'build/bin/neboc'),'g163-native-'+mode,str(source),'-o',str(target)],timeout=budget)
        assert result['termination_reason'] is None and result['python_returncode']==1 and not target.exists()
        human_diagnostic((result['stdout']+result['stderr']).encode().splitlines(),diagnostic['code'],diagnostic)
    repeated=run([str(ROOT/'build/bin/neboc'),'g163-native-check',str(source),'--message-format','json-lines'],timeout=budget)
    assert repeated['termination_reason'] is None and repeated['python_returncode']==1
    assert json.loads(repeated['stderr'] or repeated['stdout'])==diagnostic
    assert 'import "std.scientific"' not in re.sub(r'//[^\n]*','',source.read_text())
    public=[]
    for mode in ('check','emit-asm','build'):
        target=work/(mode+'.public-artifact')
        argv=[str(ROOT/'build/bin/neboc'),mode,str(source)]
        argv+=['--message-format','json-lines'] if mode=='check' else ['-o',str(target)]
        result=run(argv,timeout=budget)
        assert result['termination_reason'] is None and result['python_returncode']==1 and not target.exists()
        assert not result['stdout'] and result['stderr'].startswith('NEBO-RF166-G163-004: explicit stdlib import required for Matrix;')
        public.append(dict(mode=mode,exit=1,code='NEBO-RF166-G163-004',phase='PUBLIC_VISIBILITY',artifact_published=False,elapsed_seconds=result['elapsed_seconds']))
    return dict(stages=3,code=diagnostic['code'],native_diagnostic=diagnostic,public_visibility=public)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path,required=True);args=parser.parse_args()
    entries=json.loads((ROOT/'tests/public/complexity-oracles.json').read_bytes())['cases']
    assert len(entries)==166 and len({r['id'] for r in entries})==166
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-complexity-') as directory:
        for entry in entries:
            source=ROOT/entry['path'];assert sha(source)==entry['sha256']
            expected=oracle(source);assert expected==entry['oracle']
            budget=8 if expected['kind']=='LEGACY_TENSOR_SIGNATURE' else 3
            work=Path(directory)/entry['id'];work.mkdir()
            observation=run([str(ROOT/'build/bin/neboc'),'g163-native-check',str(source),'--message-format','json-lines','--color','never'],timeout=budget)
            assert observation['termination_reason'] is None and observation['orphan_processes_remaining']==0
            if 'exit' in expected:
                assert observation['python_returncode']==0 and not observation['stdout'] and not observation['stderr']
                proof=pipeline(source,work,expected['exit'])
            else:
                assert observation['python_returncode']==1
                diagnostic=json.loads(observation['stderr'] or observation['stdout'])
                assert diagnostic['code']==expected['code'] and diagnostic['phase']==expected['phase']
                begin,end=diagnostic['primary']['start'],diagnostic['primary']['end']
                assert source.read_bytes()[begin:end].decode()==expected['token']
                proof=reject_atlas(source,work,diagnostic,budget) if budget==8 else reject(source,work,expected['code'],span=(begin,end))
            results.append(dict(id=entry['id'],status='PASS',budget_seconds=budget,elapsed_seconds=observation['elapsed_seconds'],proof=proof))
    args.report.write_text(json.dumps(dict(status='PASS',cases=results,resolved=len(results),unresolved=0,orphans=0),indent=2)+'\n')
    print('PUBLIC_COMPLEXITY=166/166 PASS')

if __name__=='__main__':main()
