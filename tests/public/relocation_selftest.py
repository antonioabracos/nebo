"""Run native collection validators from a foreign cwd and clean source root."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = [f'tests/c08/f{i:02}/validate.sh' for i in range(2, 6)]
TARGETS = [f'c08-f{i:02}-tests' for i in range(2, 6)]
BINARIES = [f'build/tests/c08/f{i:02}/{name}_test' for i, name in enumerate(
    ['list_construction', 'list_capacity', 'list_access', 'list_mutation'], 2)]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    rows = []
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', PATH='/usr/bin:/bin', LC_ALL='C')
    env.pop('NEBO_REPO_ROOT', None)
    with tempfile.TemporaryDirectory(prefix='collection-relocation-') as directory:
        scratch = Path(directory)
        different_cwd = scratch / 'different cwd'; different_cwd.mkdir()
        other = scratch / 'source checkout'; other.mkdir()
        names = {'build.ninja', *SCRIPTS}
        for name in subprocess.check_output(['ninja', '-t', 'inputs', *TARGETS], cwd=ROOT, text=True).splitlines():
            if not name.startswith('build/'):
                names.add(name)
        pending = list(names)
        while pending:
            name = pending.pop()
            data = (ROOT / name).read_bytes()
            for included in re.findall(rb'(?m)^\s*%include\s+"([^"]+)"', data):
                child = included.decode()
                if child not in names:
                    assert (ROOT / child).is_file(), child
                    names.add(child); pending.append(child)
        for name in sorted(names):
            source = ROOT / name; target = other / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target); target.chmod(source.stat().st_mode & 0o777)
        for owner in [ROOT, other]:
            for i, script in enumerate(SCRIPTS, 2):
                run = subprocess.run(['bash', str(owner / script)], cwd=different_cwd, env=env, capture_output=True, text=True, timeout=30)
                assert run.returncode == 0 and f'C08_F{i:02}_GREEN' in run.stdout, (script, run.returncode, run.stderr)
                rows.append(dict(case=f'{owner.name}-f{i:02}', status='PASS', root='original' if owner==ROOT else 'independent', foreign_cwd=True))
        first = {name: digest(ROOT / name) for name in BINARIES}
        second = {name: digest(other / name) for name in BINARIES}
        assert first == second
        for override in ['', str(scratch/'absent'), str(different_cwd), str(other/'build.ninja')]:
            run = subprocess.run(['bash', str(ROOT/SCRIPTS[0])], cwd=different_cwd, env=dict(env, NEBO_REPO_ROOT=override), capture_output=True, text=True, timeout=5)
            assert run.returncode == 2 and 'source root' in run.stderr, (run.returncode, run.stderr)
            rows.append(dict(case='invalid-override-'+str(len(rows)), status='PASS', rejected=True))
        run = subprocess.run(['bash', str(ROOT/SCRIPTS[0])], cwd=different_cwd, env=dict(env, NEBO_REPO_ROOT=str(other)), capture_output=True, text=True, timeout=30)
        assert run.returncode == 0
        rows.append(dict(case='valid-override', status='PASS'))
        detached = scratch/'missing-root/tests/c08/f02/validate.sh'; detached.parent.mkdir(parents=True)
        shutil.copyfile(ROOT/SCRIPTS[0], detached)
        run = subprocess.run(['bash',str(detached)],cwd=different_cwd,env=env,capture_output=True,text=True,timeout=5)
        assert run.returncode==2 and 'source root' in run.stderr
        rows.append(dict(case='missing-derived-root', status='PASS', rejected=True))
        assert not (other/'build/python-cache').exists(), 'bytecode writing must remain disabled'
    result = dict(status='PASS', cases=rows, passed=len(rows), total=len(rows), native_outputs=first, native_outputs_byte_identical=len(first), source_inputs=len(names), roots=2)
    if args.report: args.report.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))


if __name__ == '__main__': main()
