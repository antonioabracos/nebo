"""Local P01 process and input budgets. Fixtures never supply executable code."""
from __future__ import annotations

import ctypes
import hashlib
import os
from pathlib import Path
import re
import resource
import selectors
import signal
import subprocess
import tempfile
import time

TOTAL_CASE_BUDGET = 8192  # Counts every subprocess, including diagnostic replays.
PER_CASE_WALL_TIMEOUT_SECONDS = 15
TOTAL_WALL_TIMEOUT_SECONDS = 900
MAX_SOURCE_BYTES = 17 * 1024 * 1024
MAX_OUTPUT_BYTES_PER_CASE = 1024 * 1024
MAX_LOG_BYTES = 4 * 1024 * 1024
MAX_MUTATION_COUNT = 192
MAX_FUZZ_SEEDS = 3
MAX_MINIMIZATION_STEPS = 256
MAX_PARALLEL_PROCESSES = 1
MAX_OPEN_FILES = 256
MAX_CHILD_PROCESSES = 64  # RLIMIT_NPROC is per UID, not a cgroup quota.
MAX_MEMORY_BYTES = 268435456
MAX_FILE_BYTES = 32 * 1024 * 1024
_started = time.monotonic()
_calls = 0


def uid_thread_baseline():
    """RLIMIT_NPROC counts the user's existing threads, including the editor.

    Read only numeric process accounting, never argv or environment. Keep a
    finite ceiling; private sessions and campaign calls own our actual work.
    """
    total = 0
    for entry in Path('/proc').iterdir():
        if not entry.name.isdigit():
            continue
        try:
            if entry.stat().st_uid != os.getuid():
                continue
            fields = (entry / 'stat').read_text().rsplit(')', 1)[1].split()
            total += int(fields[17])  # Linux stat field 20: num_threads.
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
    if total > 8192 - MAX_CHILD_PROCESSES:
        raise RuntimeError('UID_PROCESS_BUDGET')
    return total


class BudgetError(RuntimeError):
    pass


def safe_relative(root: Path, name: str) -> Path:
    if (not name or not re.fullmatch(r'[A-Za-z0-9_./-]+', name)
            or name.startswith(('/', '-')) or '..' in Path(name).parts
            or any(part.startswith('-') for part in Path(name).parts)):
        raise ValueError('UNSAFE_PATH')
    path = root / name
    if not path.resolve().is_relative_to(root.resolve()):
        raise ValueError('SYMLINK_ESCAPE')
    return path


def safe_id(value: str) -> str:
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}', value):
        raise ValueError('UNSAFE_CASE_ID')
    return value


def source_bytes(path: Path) -> bytes:
    with path.open('rb') as handle:
        value = handle.read(MAX_SOURCE_BYTES + 1)
    if len(value) > MAX_SOURCE_BYTES:
        raise BudgetError('SOURCE_BUDGET')
    return value


def temporary_directory(prefix: str = 'case'):
    return tempfile.TemporaryDirectory(prefix='nebo-G169-' + safe_id(prefix), dir='/tmp')


def _limits(timeout: float, compiler: bool, *, native_loopback: bool = False, native_x11: bool = False, mmap_failure_threshold=None) -> None:
    # RLIMIT_NPROC includes unrelated threads of this UID. An import-time
    # baseline becomes stale during long campaigns and makes the compiler's
    # fork fail with EAGAIN. Sample in this child immediately before setting
    # its finite hard limit; never change the parent or host limits.
    process_limit = uid_thread_baseline() + MAX_CHILD_PROCESSES
    for kind, limit in ((resource.RLIMIT_CORE, 0), (resource.RLIMIT_NOFILE, MAX_OPEN_FILES),
                        (resource.RLIMIT_NPROC, process_limit),
                        (resource.RLIMIT_FSIZE, MAX_FILE_BYTES),
                        (resource.RLIMIT_AS, MAX_MEMORY_BYTES if compiler else 1024**3),
                        (resource.RLIMIT_CPU, max(1, int(timeout) + 1))):
        _, hard = resource.getrlimit(kind)
        limit = limit if hard == resource.RLIM_INFINITY else min(limit, hard)
        resource.setrlimit(kind, (limit, limit))
    # Linux x86-64 seccomp: refuse all network entry points and attempts to
    # escape process-group cleanup. This only removes privileges.
    if os.uname().machine != 'x86_64':
        raise RuntimeError('NETWORK_FILTER_ARCH_UNSUPPORTED')
    class Filter(ctypes.Structure):
        _fields_ = [('code', ctypes.c_ushort), ('jt', ctypes.c_ubyte),
                    ('jf', ctypes.c_ubyte), ('k', ctypes.c_uint)]
    class Program(ctypes.Structure):
        _fields_ = [('len', ctypes.c_ushort), ('filter', ctypes.POINTER(Filter))]
    instructions = [Filter(0x20, 0, 0, 4), Filter(0x15, 1, 0, 0xc000003e),
                    Filter(0x06, 0, 0, 0x80000000), Filter(0x20, 0, 0, 0)]
    # x32 syscalls are refused too; the filter must not have an ABI bypass.
    instructions += [Filter(0x35, 0, 1, 0x40000000), Filter(0x06, 0, 0, 0x50001)]
    if mmap_failure_threshold is not None:
        if compiler or type(mmap_failure_threshold) is not int or not 1024<=mmap_failure_threshold<=1048576:
            raise RuntimeError('MMAP_FAULT_PROFILE')
        # A real mmap returns ENOMEM before making a mapping; fixture data
        # never selects a code path inside the compiler or allocator.
        instructions += [Filter(0x15,0,6,9),Filter(0x20,0,0,28),
                         Filter(0x15,1,0,0),Filter(0x06,0,0,0x5000c),
                         Filter(0x20,0,0,24),Filter(0x35,0,1,mmap_failure_threshold),
                         Filter(0x06,0,0,0x5000c),Filter(0x20,0,0,0)]
    if (native_loopback or native_x11) and compiler:
        raise RuntimeError('COMPILER_NETWORK_FORBIDDEN')
    if native_loopback and native_x11:
        raise RuntimeError('MIXED_NETWORK_PROFILE_FORBIDDEN')
    # G171's accepted static programs use the native IPv4 loopback capability,
    # which validates each destination. All older campaigns retain total denial.
    # Even this profile forbids Unix/packet/raw sockets and socketpair.
    if native_loopback:
        instructions += [Filter(0x15, 0, 9, 41), Filter(0x20, 0, 0, 16),
                         Filter(0x15, 1, 0, 2), Filter(0x06, 0, 0, 0x50001),
                         Filter(0x20, 0, 0, 24), Filter(0x54, 0, 0, 0xfff7f7ff), Filter(0x15, 2, 0, 1),
                         Filter(0x15, 1, 0, 2), Filter(0x06, 0, 0, 0x50001),
                         Filter(0x20, 0, 0, 0)]
    if native_x11:
        # A runner-owned Xvfb display uses Unix stream sockets only. The
        # accepted runtime source receives a private display and synthetic
        # authority; IPv4, IPv6, packet/raw sockets and socketpair stay denied.
        instructions += [Filter(0x15,0,8,41),Filter(0x20,0,0,16),
                         Filter(0x15,1,0,1),Filter(0x06,0,0,0x50001),
                         Filter(0x20,0,0,24),Filter(0x54,0,0,0xfff7f7ff),
                         Filter(0x15,1,0,1),Filter(0x06,0,0,0x50001),
                         Filter(0x20,0,0,0)]
    denied = ([53] if native_loopback or native_x11 else list(range(41, 56))) + [112, 155, 165, 166, 250, 272, 308]
    for number in denied:
        instructions += [Filter(0x15, 0, 1, number), Filter(0x06, 0, 0, 0x50001)]
    instructions.append(Filter(0x06, 0, 0, 0x7fff0000))
    filters = (Filter * len(instructions))(*instructions)
    program = Program(len(instructions), filters)
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(38, 1, 0, 0, 0) or libc.prctl(22, 2, ctypes.byref(program), 0, 0):
        raise RuntimeError('NETWORK_FILTER_UNAVAILABLE')


def command(repo: Path, argv: list[str], timeout: float = 60) -> subprocess.CompletedProcess:
    global _calls
    _calls += 1
    remaining = TOTAL_WALL_TIMEOUT_SECONDS - (time.monotonic() - _started)
    if _calls > TOTAL_CASE_BUDGET or remaining <= 0:
        raise BudgetError('TOTAL_CAMPAIGN_BUDGET')
    # Adopt descendants so cancellation can reap native build grandchildren.
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(36, 1, 0, 0, 0):
        raise BudgetError('CHILD_SUBREAPER_UNAVAILABLE')
    compiler = Path(argv[0]).name == 'neboc'
    timeout = min(timeout, remaining, PER_CASE_WALL_TIMEOUT_SECONDS if compiler else 240)
    if compiler:
        source_bytes(Path(argv[2]))
    with temporary_directory('process-') as directory:
        temp = Path(directory)
        env = {'PATH': '/usr/bin:/bin', 'HOME': str(temp), 'TMPDIR': str(temp),
               'LC_ALL': 'C', 'LANG': 'C', 'TZ': 'UTC', 'TERM': 'dumb'}
        proc = subprocess.Popen(argv, cwd=repo, env=env, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                start_new_session=True, close_fds=True,
                                preexec_fn=lambda: _limits(timeout, compiler))
        buffers = [bytearray(), bytearray()]
        digest = hashlib.sha256()
        count = 0
        deadline = time.monotonic() + timeout
        try:
            with selectors.DefaultSelector() as selector:
                for index, stream in enumerate((proc.stdout, proc.stderr)):
                    os.set_blocking(stream.fileno(), False)
                    selector.register(stream, selectors.EVENT_READ, index)
                while selector.get_map():
                    left = deadline - time.monotonic()
                    if left <= 0:
                        raise subprocess.TimeoutExpired(argv, timeout)
                    for key, _ in selector.select(min(left, .05)):
                        data = os.read(key.fd, 65536)
                        if not data:
                            selector.unregister(key.fileobj)
                            continue
                        count += len(data)
                        digest.update(data)
                        if count > MAX_OUTPUT_BYTES_PER_CASE:
                            raise BudgetError('OUTPUT_TRUNCATED_PARTIAL_SHA256=' + digest.hexdigest())
                        buffers[key.data].extend(data)
                proc.wait(timeout=max(.001, deadline - time.monotonic()))
            return subprocess.CompletedProcess(argv, proc.returncode, bytes(buffers[0]), bytes(buffers[1]))
        finally:
            # Ninja may put tools into separate groups in our private session.
            # setsid is denied, so session membership remains a cleanup owner.
            owned = []
            for entry in Path('/proc').iterdir():
                if not entry.name.isdigit():
                    continue
                try:
                    fields = (entry / 'stat').read_text().rsplit(')', 1)[1].split()
                    if int(fields[3]) == proc.pid:
                        pid = int(entry.name)
                        if pid != proc.pid:
                            owned.append(pid)
                        os.kill(pid, signal.SIGKILL)
                except (FileNotFoundError, ProcessLookupError, PermissionError):
                    pass
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait()
            for pid in owned:
                try:
                    os.waitpid(pid, 0)
                except ChildProcessError:
                    pass
            proc.stdout.close()
            proc.stderr.close()
