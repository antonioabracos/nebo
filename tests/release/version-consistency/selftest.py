#!/usr/bin/env python3
"""Mutation tests in a small temporary identity fixture, never in the worktree."""
import importlib.util,json,shutil,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('identity_check',ROOT/'scripts/check-version-consistency.py')
check=importlib.util.module_from_spec(spec);spec.loader.exec_module(check)
policy=check.read_json(ROOT/check.POLICY)
identity=check.read_json(ROOT/'version/NEBO-VERSION.json')
values=dict(version=identity['version'],edition=identity['edition'])
rows=[]
def test(name,mutation,expected):
    with tempfile.TemporaryDirectory(prefix='nebo-version-mutation-') as td:
        root=Path(td)
        names={r['path'].format(**values) for r in policy['owners']}|{check.POLICY}
        names.update(r['source'] for r in policy['owners'] if r['kind']=='sha256-pin')
        for rel in names:
            out=root/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/rel,out)
        mutation(root)
        try:result=check.inspect(root);passed=result['status']=='PASS'
        except (ValueError,KeyError,TypeError):passed=False
        assert passed==expected,name
        rows.append(dict(id=name,status='PASS',expected_acceptance=expected))
def replace(root,name,before,after):
    p=root/name;s=p.read_text();assert before in s;p.write_text(s.replace(before,after))
def add(root,name,text):
    p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
v=identity['version']
test('unmodified',lambda r:None,True)
test('wrong-compiler-rejected',lambda r:replace(r,'compiler/driver/cli/linux-x86_64/version.inc',v,'9.9.9'),False)
test('wrong-sdk-rejected',lambda r:replace(r,'sdk/nebo-1.0/sdk-layout.json',v,'9.9.9'),False)
test('wrong-readme-rejected',lambda r:replace(r,'README.md',v,'9.9.9'),False)
test('historical-public-1.0.1-preserved',lambda r:add(r,'docs/releases/history/public.md','Historical release 1.0.1\n'),True)
test('sarif-schema-independent',lambda r:add(r,'compiler/diagnostics/machine.asm','; SARIF schema 2.1.0\n'),True)
test('leftover-rc-rejected',lambda r:replace(r,'README.md',v,v+'-rc.1'),False)
test('asset-filename-mismatch-rejected',lambda r:replace(r,'version/RELEASE-ASSET-NAMES.json','nebo-'+v+'-source.tar','nebo-9.9.9-source.tar'),False)
test('unknown-current-owner-rejected',lambda r:add(r,'runtime/unknown-version.txt','Current product version '+v+'\n'),False)
test('placeholder-rejected',lambda r:replace(r,'sdk/nebo-1.0/sdk-layout.json',v,'TODO'),False)
test('stale-registry-pin-rejected',lambda r:replace(r,'compiler/sdk/operator_tooling.py','b7e5694ceadf30ccffb4077c994fe230d2a10201b64dc6e9e218bdcf4b157f14','0'*64),False)
test('schema-exemption-cannot-hide-product-version',lambda r:add(r,'compiler/diagnostics/machine.asm','; SARIF 2.1.0\n; product 9.9.9\n'),False)
print(json.dumps(dict(schema='nebo.version-selftests.v1',status='PASS',cases=rows),sort_keys=True))
