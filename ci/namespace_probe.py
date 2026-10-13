#!/usr/bin/env python3
"""Authenticate a pinned Ubuntu dependency and probe namespaces off-host only."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

import smoke
import supervisor as S

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ci-results'
VERSION = '0.9.0-1ubuntu0.3'


def execute(name, argv, timeout=180, cwd=None):
    started = time.monotonic()
    with (OUT / (name + '.stdout')).open('xb') as out, (OUT / (name + '.stderr')).open('xb') as err:
        p = subprocess.run(['timeout', '--signal=TERM', '--kill-after=5s', str(timeout) + 's', *argv],
                           stdout=out, stderr=err, cwd=cwd, timeout=timeout + 10)
    return dict(command_role=name, exit=p.returncode, elapsed=time.monotonic()-started)


def main():
    OUT.mkdir(mode=0o700, exist_ok=False)
    started = time.time()
    settings = json.loads((ROOT / 'ci/session.json').read_text())
    soft = datetime.fromisoformat(settings['soft_stop_utc']).timestamp()
    result = dict(schema='nebo-rev218-namespace-probe-v1', batch_id='namespace-and-toolchain-probe',
                  actual_requests=0, native_passed=0, native_failed=0, native_incomplete=0,
                  result='INCOMPLETE', cases=[], admission='NOT_EXECUTED',
                  input_sha256=S.digest(ROOT/'PUBLICATION-MANIFEST.json'),
                  runner_identity={k:os.getenv(k) for k in ['GITHUB_REPOSITORY','GITHUB_SHA','GITHUB_RUN_ID','GITHUB_RUN_ATTEMPT','GITHUB_JOB','RUNNER_OS','RUNNER_ARCH']},
                  resume_position='collection.iteratorMutable: before first native admission')
    try:
        S.remaining_seconds(soft, 1200)
        smoke.verify_publication()
        previous = json.loads((ROOT / 'SUPERVISOR-SMOKE-RECEIPT.json').read_text())
        if previous['supervisor_sha256'] != S.digest(ROOT/'ci/supervisor.py') or previous['fixture_sha256'] != S.digest(ROOT/'ci/process_fixture.py'):
            raise RuntimeError('Cannot reuse smoke: changed supervisor/fixture inputs')
        if previous['passed'] != 7 or previous['failed'] != 0:
            raise RuntimeError('Prior smoke did not pass')
        result['reused_supervisor_evidence'] = previous
        update = execute('signed-apt-index-update', ['sudo','-n','apt-get','update'], timeout=180)
        result['cases'].append(update)
        if update['exit'] != 0: raise RuntimeError('Signed package index update failed')
        metadata = subprocess.check_output(['apt-cache','show','bubblewrap='+VERSION], text=True, timeout=10)
        (OUT/'bubblewrap-package-metadata.txt').write_text(metadata)
        paragraphs = [dict(line.split(': ',1) for line in part.splitlines() if ': ' in line and not line.startswith(' '))
                      for part in metadata.strip().split('\n\n')]
        rows = [x for x in paragraphs if x.get('Version')==VERSION and x.get('Architecture')=='amd64']
        if len({r['SHA256'] for r in rows}) != 1 or not rows:
            raise RuntimeError('Pinned package identity missing or ambiguous')
        declared = rows[0]['SHA256']
        with tempfile.TemporaryDirectory(prefix='nebo-reviewed-dependency-') as temp:
            download = execute('download-pinned-bubblewrap', ['apt-get','download','bubblewrap='+VERSION], cwd=temp)
            result['cases'].append(download)
            files = list(Path(temp).glob('*.deb'))
            if download['exit'] != 0 or len(files)!=1 or S.digest(files[0]) != declared:
                raise RuntimeError('Pinned Ubuntu dependency digest mismatch')
            result['dependency'] = dict(package='bubblewrap', version=VERSION,
                archive_sha256=declared, origin='Ubuntu signed package indices',
                upstream_reference='https://packages.ubuntu.com/noble/bubblewrap',
                binary_uploaded_as_artifact=False)
            install = execute('install-pinned-bubblewrap', ['sudo','-n','dpkg','--install',str(files[0])], timeout=60)
            result['cases'].append(install)
            if install['exit'] != 0: raise RuntimeError('Pinned dependency installation failed')
        version = subprocess.check_output(['dpkg-query','-W','-f=${Version}','bubblewrap'],text=True,timeout=5)
        if version != VERSION: raise RuntimeError('Installed version mismatch')
        trace = execute('bwrap-strace-true', ['bwrap','--unshare-all','--die-with-parent',
            '--new-session','--ro-bind','/','/','--proc','/proc','--dev','/dev','--tmpfs','/tmp',
            '--','/usr/bin/strace','-f','-qq','-e','trace=execve','/usr/bin/true'], timeout=10)
        result['cases'].append(trace)
        result['namespace_ptrace'] = 'PASS_SYSTEM_SMOKE_ONLY' if trace['exit']==0 else 'BLOCKED'
        expected = json.loads((ROOT/'ci/native-tool-digests.json').read_text())
        comparisons=[]
        for entry in expected['bindings']:
            p=Path(entry['destination'])
            actual=S.digest(p) if p.is_file() else None
            comparisons.append(dict(destination=entry['destination'],expected_sha256=entry['sha256'],
                                    observed_sha256=actual,match=actual==entry['sha256']))
        result['stock_toolchain_comparison']=comparisons
        result['stock_toolchain_matches_frozen_inputs']=all(x['match'] for x in comparisons)
        result['compatibility']=smoke.compatibility()
        result['result']='PROBE_COMPLETED_NATIVE_ADMISSION_BLOCKED'
    except Exception as error:
        result.update(result='FAIL',error=type(error).__name__+': '+str(error))
    finally:
        result.update(elapsed=time.time()-started,finished_at=datetime.now(timezone.utc).isoformat(),
                      passed=sum(c['exit']==0 for c in result['cases']),
                      failed=sum(c['exit']!=0 for c in result['cases']),
                      incomplete=max(0,4-len(result['cases'])))
        payloads=[dict(path=str(p.relative_to(OUT)),sha256=S.digest(p),bytes=p.stat().st_size)
                  for p in sorted(OUT.rglob('*')) if p.is_file()]
        S.write_json(OUT/'OUTPUT-MANIFEST.json',dict(files=payloads))
        result['output_sha256']=S.digest(OUT/'OUTPUT-MANIFEST.json')
        S.write_json(OUT/'BATCH-RESULT.json',result)
        (OUT/'SHA256SUMS').write_text(''.join(S.digest(p)+'  '+str(p.relative_to(OUT))+'\n'
            for p in sorted(OUT.rglob('*')) if p.is_file() and p.name!='SHA256SUMS'))
        print(json.dumps({k:result[k] for k in ['result','passed','failed','incomplete','actual_requests','admission','elapsed']},indent=2))
    return 0 if result['result']=='PROBE_COMPLETED_NATIVE_ADMISSION_BLOCKED' else 1


if __name__=='__main__':
    sys.exit(main())
