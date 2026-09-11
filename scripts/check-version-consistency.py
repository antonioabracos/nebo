#!/usr/bin/env python3
"""Read-only product identity checks with declared owners and reference classes."""
import argparse
import fnmatch
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
POLICY='version/DERIVED-VERSION-OWNERS.json'
SEMVER=re.compile(r'(?<![\d.])\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?(?![\d.])')
BINARY={'.tar','.gz','.xz','.zip','.png','.jpg','.jpeg','.ttf','.woff','.woff2','.o','.elf','.a','.so','.ni','.bin','.pdf'}


def read_json(path):
    def unique(items):
        value={}
        for k,v in items:
            if k in value:raise ValueError('duplicate JSON key '+k)
            value[k]=v
        return value
    return json.loads(path.read_bytes(),object_pairs_hook=unique)


def inspect(root, binary=False):
    identity=read_json(root/'version/NEBO-VERSION.json')
    version=identity.get('version');edition=identity.get('edition')
    if not isinstance(version,str) or not re.fullmatch(r'[1-9]\d*\.\d+\.\d+',version):
        raise ValueError('invalid final product version')
    if (set(identity)!={'schema','version','edition','cli','compiler','language','target'}
        or identity.get('schema')!='NEBO-VERSION-v1' or identity.get('compiler')!='neboc'
        or identity.get('language')!='Nebo' or identity.get('target')!='x86_64-systemv-elf-linux'
        or identity.get('cli')!='neboc '+version or edition!='1.0'):
        raise ValueError('canonical identity mismatch')
    major,minor,patch=version.split('.')
    values=dict(version=version,edition=edition,major=major,minor=minor,patch=patch,version_markdown=version.replace(".",r"\."))
    policy=read_json(root/POLICY)
    if policy.get('schema')!='NEBO-DERIVED-VERSION-OWNERS-v1':raise ValueError('owner policy schema')
    rows=[];owners={}
    for owner in policy['owners']:
        path=owner['path'].format(**values)
        if path in owners:raise ValueError('duplicate owner '+path)
        owners[path]=owner
        p=root/path;errors=[]
        if not p.is_file():errors.append('MISSING_OWNER')
        else:
            text=p.read_text()
            if owner['kind']=='json':
                doc=read_json(p)
                for key,template in owner['fields'].items():
                    expected=template.format(**values)
                    observed=doc
                    for part in key.split('.'):
                        observed=observed[int(part)] if isinstance(observed,list) else observed.get(part)
                    if observed!=expected:errors.append('FIELD_DRIFT:'+key)
            elif owner['kind']=='text':
                for template in owner['contains']:
                    expected=template.format(**values)
                    if text.count(expected)!=1:errors.append('TEXT_DRIFT:'+expected)
            elif owner['kind']=='python':
                for expected in owner['contains']:
                    if expected not in text:errors.append('AUTHORITY_IMPORT_DRIFT')
                if re.search(r'(?m)^(?:VERSION|CURRENT|CLI)\s*=\s*[\"\'](?:neboc )?\d+\.\d+\.\d+',text):
                    errors.append('INDEPENDENT_PRODUCT_CONSTANT')
            elif owner['kind']=='assets':
                doc=read_json(p)
                if doc.get('version')!=version or doc.get('edition')!=edition:errors.append('ASSET_IDENTITY')
                for asset in doc.get('assets',[]):
                    if asset['name']!=owner['names'].get(asset['profile'],'').format(**values):errors.append('ASSET_NAME_DRIFT')
                if (len(doc.get('assets',[]))!=len(owner['names'])
                    or {a['profile'] for a in doc.get('assets',[])}!=set(owner['names'])):
                    errors.append('ASSET_MEMBERSHIP')
            elif owner['kind']=='sha256-pin':
                expected=hashlib.sha256((root/owner['source']).read_bytes()).hexdigest()
                pattern=rf'(?m)^{re.escape(owner["constant"])} = "([0-9a-f]{{64}})"$'
                found=re.findall(pattern,text)
                if found!=[expected]:errors.append('CANONICAL_AUTHORITY_PIN_DRIFT')
            elif owner['kind']=='copy':
                if p.read_bytes()!=(root/owner['source'].format(**values)).read_bytes():errors.append('DERIVATIVE_COPY_DRIFT')
            else:raise ValueError('unknown owner kind')
        rows.append(dict(owner=path,expected_version=version,expected_edition=edition,status='FAIL' if errors else 'PASS',errors=errors))
    # Search the current product/documentation roots, not only declared owners.
    # Every version-bearing path must be an owner or have an explicit semantic
    # classification. New paths never acquire an implicit exemption.
    references=[]
    candidates=set()
    for name in policy['scan_roots']:
        path=root/name
        if path.is_file():candidates.add(path)
        elif path.is_dir():candidates.update(p for p in path.rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    for path in sorted(candidates):
        rel=path.relative_to(root).as_posix()
        if path.suffix in BINARY:continue
        raw=path.read_bytes()
        if b'\0' in raw:continue
        try:text=raw.decode()
        except UnicodeError:continue
        matches=sorted(set(SEMVER.findall(text)))
        if not matches:continue
        classification='CURRENT_PRODUCT_OWNER' if rel in owners else None
        if classification is None:
            rules=[r for r in policy['references'] if fnmatch.fnmatchcase(rel,r['path'])]
            if rules:
                rule=rules[0]
                if 'allowed_versions' not in rule or set(matches)<=set(rule['allowed_versions']):
                    classification=rule['classification']
        if classification is None:
            classification='UNKNOWN_CURRENT_VERSION_OWNER'
            rows.append(dict(owner=rel,expected_version=version,expected_edition=edition,status='FAIL',errors=[classification]))
        references.append(dict(path=rel,classification=classification,versions=matches))
    if binary:
        executable=root/'build/bin/neboc'
        human=subprocess.run([str(executable),'--version'],capture_output=True,timeout=15)
        machine=subprocess.run([str(executable),'--version-json'],capture_output=True,timeout=15)
        errors=[]
        if human.returncode or human.stderr or human.stdout.decode()!=identity['cli']+'\n':errors.append('HUMAN_VERSION')
        if machine.returncode or machine.stderr or json.loads(machine.stdout)!=identity:errors.append('MACHINE_VERSION')
        rows.append(dict(owner='build/bin/neboc',expected_version=version,expected_edition=edition,status='FAIL' if errors else 'PASS',errors=errors))
    return dict(schema='nebo.version-consistency.v1',status='PASS' if all(r['status']=='PASS' for r in rows) else 'FAIL',version=version,edition=edition,owners=rows,references=references,mismatches=sum(r['status']!='PASS' for r in rows))


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=ROOT)
    parser.add_argument('--binary',action='store_true')
    parser.add_argument('--report',type=Path)
    parser.add_argument('--expected-cli',action='store_true')
    args=parser.parse_args()
    if args.expected_cli:
        print(read_json(args.root/'version/NEBO-VERSION.json')['cli']);return
    try:result=inspect(args.root.resolve(),args.binary)
    except (ValueError,KeyError,IndexError,TypeError,AttributeError,OSError,subprocess.SubprocessError) as error:
        result=dict(schema='nebo.version-consistency.v1',status='FAIL',error=str(error))
    if args.report:args.report.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,sort_keys=True))
    if result['status']!='PASS':raise SystemExit(1)

if __name__=='__main__':main()
