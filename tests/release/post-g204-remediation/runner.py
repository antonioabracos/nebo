"""Bounded local process observation; deadline is never an expected exit code."""
import ctypes
import hashlib
import os
from pathlib import Path
import resource
import selectors
import signal
import subprocess
import time

MAX_LOG_BYTES = 1048576
MAX_CHILDREN = 16


def group_snapshot(pgid):
    members = []
    for path in Path('/proc').glob('[0-9]*/stat'):
        try:
            fields = path.read_text().rsplit(')', 1)[1].split()
            if int(fields[2]) != pgid:
                continue
            pid = int(path.parent.name)
            fds = {}
            for fd in (path.parent / 'fd').iterdir():
                try:
                    fds[fd.name] = os.readlink(fd)
                except OSError:
                    pass
            members.append(dict(pid=pid, state=fields[0], ppid=int(fields[1]),
                                cpu_ticks=int(fields[11]) + int(fields[12]),
                                wchan=(path.parent / 'wchan').read_text(), fds=fds))
        except (OSError, ValueError, IndexError):
            continue
    return members


def run(argv, timeout=3, cwd=None, env=None, log_limit=MAX_LOG_BYTES):
    # Adopt and reap descendants if a wrapper dies before its children.
    if ctypes.CDLL(None, use_errno=True).prctl(36, 1, 0, 0, 0) != 0:
        raise OSError('cannot enable child subreaper')
    started = time.monotonic()
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    child_env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', LC_ALL='C')
    child_env.update(env or {})
    p = subprocess.Popen(argv, shell=False, start_new_session=True, cwd=cwd,
                         env=child_env, stdin=subprocess.DEVNULL,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    sel = selectors.DefaultSelector()
    streams = {'stdout': bytearray(), 'stderr': bytearray()}
    sizes = dict(stdout=0, stderr=0)
    for name, pipe in [('stdout', p.stdout), ('stderr', p.stderr)]:
        os.set_blocking(pipe.fileno(), False)
        sel.register(pipe, selectors.EVENT_READ, name)
    samples, max_children = [], 0
    reason = None
    term_at = None
    last_sample = -1

    def stop(sig):
        try:
            os.killpg(p.pid, sig)
        except ProcessLookupError:
            pass

    try:
        while True:
            elapsed = time.monotonic() - started
            if elapsed - last_sample >= .25:
                members = group_snapshot(p.pid)
                max_children = max(max_children, max(0, len(members) - 1))
                samples.append(dict(elapsed_seconds=round(elapsed, 6), members=members))
                samples = samples[-12:]
                last_sample = elapsed
                if len(members) > MAX_CHILDREN + 1:
                    reason = reason or 'CHILD_LIMIT'
            if elapsed >= timeout:
                reason = reason or 'DEADLINE'
            if reason and term_at is None:
                stop(signal.SIGTERM)
                term_at = time.monotonic()
            if term_at is not None and time.monotonic() - term_at >= .5:
                stop(signal.SIGKILL)
            for key, _ in sel.select(.025):
                chunk = os.read(key.fileobj.fileno(), 65536)
                if chunk:
                    sizes[key.data] += len(chunk)
                    streams[key.data].extend(chunk)
                    del streams[key.data][:-log_limit]
                    if sum(sizes.values()) > log_limit:
                        reason = reason or 'LOG_LIMIT'
                else:
                    sel.unregister(key.fileobj)
                    key.fileobj.close()
            if p.poll() is not None and not sel.get_map():
                break
            if term_at is not None and time.monotonic() - term_at > 2:
                raise RuntimeError('process/pipe cleanup did not complete within two seconds')
        direct = p.wait(timeout=1)
        remaining = group_snapshot(p.pid)
        if remaining:
            reason = reason or 'CHILD_LEAK'
            stop(signal.SIGTERM)
            until = time.monotonic() + .5
            while time.monotonic() < until and any(m['state'] != 'Z' for m in group_snapshot(p.pid)):
                time.sleep(.01)
            stop(signal.SIGKILL)
        reap_until = time.monotonic() + 1
        while group_snapshot(p.pid) and time.monotonic() < reap_until:
            try:
                while os.waitpid(-p.pid, os.WNOHANG)[0]:
                    pass
            except ChildProcessError:
                pass
            time.sleep(.01)
        orphans = group_snapshot(p.pid)
        if orphans:
            raise RuntimeError('unreaped process group: ' + repr(orphans))
    finally:
        stop(signal.SIGKILL)
        p.wait(timeout=1)
        sel.close()
        for pipe in (p.stdout, p.stderr):
            pipe.close()
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    result = dict(argv=list(map(str, argv)), timeout_seconds=timeout,
                  elapsed_seconds=round(time.monotonic() - started, 6),
                  cpu_seconds=round(after.ru_utime + after.ru_stime - before.ru_utime - before.ru_stime, 6),
                  sampled_group_cpu_seconds=max((sum(m['cpu_ticks'] for m in s['members'])
                                                 for s in samples), default=0) / os.sysconf('SC_CLK_TCK'),
                  python_returncode=direct, shell_exit=128 - direct if direct < 0 else direct,
                  signal=signal.Signals(-direct).name if direct < 0 else 'NONE',
                  termination_reason=reason, child_process_count=max_children,
                  orphan_processes_remaining=0, process_samples=samples)
    for name, data in streams.items():
        result[name] = bytes(data).decode('utf-8', 'replace')
        result[name + '_bytes'] = sizes[name]
        result[name + '_suffix_sha256'] = hashlib.sha256(data).hexdigest()
    result['last_progress_marker'] = (result['stderr'] or result['stdout']).strip()[-300:] or 'NO_OUTPUT'
    return result


if __name__ == '__main__':
    import argparse
    import json
    parser = argparse.ArgumentParser()
    parser.add_argument('--timeout', type=float, default=3)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command or not 0 < args.timeout <= 1800:
        parser.error('a command and a timeout in (0,1800] are required')
    observation = run(command, timeout=args.timeout)
    args.report.write_text(json.dumps(observation, indent=2) + '\n')
    print(json.dumps({k: observation[k] for k in ('elapsed_seconds', 'cpu_seconds',
                     'python_returncode', 'termination_reason', 'last_progress_marker')}))
    raise SystemExit(1 if observation['termination_reason'] else
                     observation['python_returncode'] if observation['python_returncode'] >= 0 else 1)
