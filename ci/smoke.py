#!/usr/bin/env python3
"""One finite hosted-runner probe, no original checkout or Nebo binary execution."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time

import supervisor as S

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ci-results'


def run(argv, timeout=8):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
        return dict(exit=p.returncode, stdout=p.stdout[:16000], stderr=p.stderr[:4000])
    except (FileNotFoundError, subprocess.TimeoutExpired) as error:
        return dict(exit=None, error=type(error).__name__)


def verify_publication():
    manifest = json.loads((ROOT / 'PUBLICATION-MANIFEST.json').read_text())
    for item in manifest['files']:
        path = ROOT / item['path']
        if not path.is_file() or S.digest(path) != item['sha256']:
            raise RuntimeError('Publication identity changed: ' + item['path'])
    return len(manifest['files'])


def scenario(name, soft_stop):
    maximum = S.remaining_seconds(soft_stop, 3 if name == 'timeout' else 15)
    folder = OUT / name
    evidence = folder / 'fixture'
    command = [sys.executable, '-B', str(ROOT / 'ci/process_fixture.py'),
               '--output', str(evidence), '--mode', name]
    started = time.monotonic()
    unit, process = S.start(command, ROOT, maximum, folder)
    try:
        if name == 'cancel':
            limit = time.monotonic() + 6
            while not (evidence / 'grandchild.json').exists() and time.monotonic() < limit:
                time.sleep(0.02)
            if not (evidence / 'grandchild.json').exists():
                raise RuntimeError('Fixture tree did not start')
            S.stop(unit)
        rc = process.wait(timeout=maximum + 12)
    except BaseException:
        S.stop(unit)
        process.wait(timeout=8)
        raise
    births = [json.loads(p.read_text()) for p in evidence.glob('*.json')]
    survivors = S.wait_no_survivors(births)
    expected = (rc == 0) if name == 'normal' else (rc != 0)
    tree_complete = len(births) == (1 if name in ('normal', 'fail') else 3)
    preserved = (folder / 'stdout.txt').is_file() and (folder / 'stderr.txt').is_file()
    if name == 'fail':
        preserved = preserved and (evidence / 'partial-evidence.txt').read_text() == 'preserve expected fixture failure\n'
    value = dict(case=name, process_exit=rc, expected_exit_observed=expected,
                 birth_records=births, tree_complete=tree_complete, survivors=survivors,
                 logs_preserved=preserved, elapsed=time.monotonic() - started,
                 result='PASS' if expected and tree_complete and not survivors and preserved else 'FAIL',
                 native_requests=0)
    S.write_json(folder / 'result.json', value)
    return value


def compatibility():
    mem = {line.split(':')[0]: int(line.split()[1]) * 1024 for line in Path('/proc/meminfo').read_text().splitlines()}
    vm = dict(line.split() for line in Path('/proc/vmstat').read_text().splitlines())
    information = dict(architecture=platform.machine(), system=platform.system(),
        kernel=platform.release(), libc=platform.libc_ver(), python=platform.python_version(),
        memory_available_B=mem['MemAvailable'], swap_used_B=mem['SwapTotal']-mem['SwapFree'],
        root_free_B=shutil.disk_usage('/').free, tmp_free_B=shutil.disk_usage('/tmp').free,
        oom_kill=int(vm['oom_kill']), cgroup_v2=Path('/sys/fs/cgroup/cgroup.controllers').is_file(),
        image_os=os.getenv('ImageOS'), image_version=os.getenv('ImageVersion'),
        runner_os=os.getenv('RUNNER_OS'), runner_arch=os.getenv('RUNNER_ARCH'),
        cpu_sensor_files=len(list(Path('/sys/class/hwmon').glob('hwmon*/temp*_input'))),
        nvidia_smi_available=shutil.which('nvidia-smi') is not None,
        powerprofilesctl_available=shutil.which('powerprofilesctl') is not None,
        systemd_user=run(['systemctl', '--user', 'is-system-running']),
        systemd_system=run(['systemctl', 'is-system-running']),
        bwrap_available=shutil.which('bwrap') is not None, strace_available=shutil.which('strace') is not None)
    if information['bwrap_available']:
        information['bwrap_version'] = run(['bwrap', '--version'])
        information['namespace_smoke'] = run(['bwrap', '--unshare-all', '--die-with-parent',
            '--new-session', '--ro-bind', '/', '/', '--proc', '/proc', '--dev', '/dev',
            '--tmpfs', '/tmp', '--', '/usr/bin/true'])
    else:
        information['namespace_smoke'] = dict(result='NOT_EXECUTED_TOOL_MISSING')
    blockers = ['FROZEN_NATIVE_INPUTS_WITHHELD_FROM_PUBLICATION',
                'PINNED_TOOLCHAIN_AND_ABI_NOT_YET_AUTHENTICATED',
                'FROZEN_TOOL_PROVENANCE_ADAPTER_NOT_YET_VALIDATED']
    if information['architecture'] != 'x86_64': blockers.append('ARCHITECTURE_MISMATCH')
    if not information['nvidia_smi_available']: blockers.append('ORIGINAL_GUARD_REQUIRES_NVIDIA_TELEMETRY')
    if not information['cpu_sensor_files']: blockers.append('ORIGINAL_GUARD_REQUIRES_CPU_TELEMETRY')
    if not information['powerprofilesctl_available']: blockers.append('ORIGINAL_GUARD_REQUIRES_BALANCED_PROFILE_TOOL')
    if information['root_free_B'] < 35 * 1024**3: blockers.append('ORIGINAL_GUARD_ROOT_FREE_BELOW_35_GIB')
    if information['memory_available_B'] < 3 * 1024**3: blockers.append('MEMORY_AVAILABLE_BELOW_3_GIB')
    if information['namespace_smoke'].get('exit') != 0: blockers.append('BWRAP_NAMESPACE_NOT_PROVEN')
    information.update(native_admission_ready=False, native_blockers=blockers,
                       sensor_values='NOT_MEASURED', native_requests=0)
    return information


def main():
    OUT.mkdir(mode=0o700, exist_ok=False)
    started = time.time()
    settings = json.loads((ROOT / 'ci/session.json').read_text())
    soft_stop = datetime.fromisoformat(settings['soft_stop_utc']).timestamp()
    summary = dict(schema='nebo-rev218-ci-smoke-v1', result='INCOMPLETE',
        batch_id='supervisor-smoke', input_sha256=S.digest(ROOT / 'PUBLICATION-MANIFEST.json'),
        baseline_revision=217, candidate_revision=218,
        runner_identity={key:os.getenv(key) for key in ['GITHUB_REPOSITORY','GITHUB_SHA','GITHUB_RUN_ID','GITHUB_RUN_ATTEMPT','GITHUB_JOB','RUNNER_OS','RUNNER_ARCH']},
        actual_requests=0, native_passed=0, native_failed=0, native_incomplete=0,
        admission='NOT_EXECUTED', resume_position='collection.iteratorMutable: before first native admission',
        started_at=datetime.now(timezone.utc).isoformat(), cases=[])
    try:
        S.remaining_seconds(soft_stop, 1200)
        summary['publication_files_verified'] = verify_publication()
        # No secrets, original packet, source-machine identity, or complete env dump.
        summary['compatibility'] = compatibility()
        for name in ('normal', 'timeout', 'cancel', 'monitor-exit', 'fail'):
            summary['cases'].append(scenario(name, soft_stop))
        try:
            S.remaining_seconds(time.time()-1, 1)
        except RuntimeError:
            summary['cases'].append(dict(case='expired-session-rejected', result='PASS', native_requests=0))
        else:
            summary['cases'].append(dict(case='expired-session-rejected', result='FAIL', native_requests=0))
        probe = OUT / 'integrity-probe.txt'
        probe.write_text('before'); original = S.digest(probe); probe.write_text('after')
        summary['cases'].append(dict(case='changed-input-detected', result='PASS' if S.digest(probe)!=original else 'FAIL',native_requests=0))
        summary['result'] = 'PASS_INFRASTRUCTURE_ONLY' if all(c['result']=='PASS' for c in summary['cases']) else 'FAIL'
    except Exception as error:
        summary.update(result='FAIL', error=type(error).__name__ + ': ' + str(error))
    finally:
        summary.update(elapsed=time.time()-started, finished_at=datetime.now(timezone.utc).isoformat(),
                       passed=sum(c['result']=='PASS' for c in summary['cases']),
                       failed=sum(c['result']!='PASS' for c in summary['cases']),
                       incomplete=max(0,7-len(summary['cases'])), output_sha256=None)
        # Digest covers the output payload manifest, not a circular self hash.
        payloads = [dict(path=str(p.relative_to(OUT)), sha256=S.digest(p), bytes=p.stat().st_size)
                    for p in sorted(OUT.rglob('*')) if p.is_file()]
        S.write_json(OUT / 'OUTPUT-MANIFEST.json', dict(files=payloads))
        summary['output_sha256'] = S.digest(OUT / 'OUTPUT-MANIFEST.json')
        S.write_json(OUT / 'BATCH-RESULT.json', summary)
        files = [p for p in sorted(OUT.rglob('*')) if p.is_file()]
        (OUT / 'SHA256SUMS').write_text(''.join(S.digest(p)+'  '+str(p.relative_to(OUT))+'\n' for p in files))
        print(json.dumps({k:summary[k] for k in ['result','passed','failed','incomplete','actual_requests','admission','elapsed']},indent=2))
    return 0 if summary['result']=='PASS_INFRASTRUCTURE_ONLY' else 1


if __name__ == '__main__':
    sys.exit(main())
