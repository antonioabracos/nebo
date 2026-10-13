#!/usr/bin/env python3
"""Bounded GitHub-hosted process supervision; no Nebo input or credential access.

This adapter tests the cgroup lifecycle required by the private runner guard.
It does not reinterpret a missing thermal sensor as a temperature measurement.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
import uuid


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def remaining_seconds(soft_stop, required):
    remaining = int(soft_stop - time.time())
    if required <= 0 or required > 7200 or remaining < required + 30:
        raise RuntimeError('Insufficient authorized session time')
    return min(required, remaining - 30)


def service_command(unit, argv, directory, maximum):
    if maximum < 1 or maximum > 7200:
        raise ValueError('Service runtime outside authorized bounds')
    return ['sudo', '-n', 'systemd-run', '--quiet', '--wait', '--pipe', '--collect',
            '--unit=' + unit, '--uid=' + str(os.getuid()), '--gid=' + str(os.getgid()),
            '--property=WorkingDirectory=' + str(Path(directory).resolve()),
            '--property=RuntimeMaxSec=' + str(maximum) + 's',
            '--property=TimeoutStopSec=2s', '--property=KillMode=control-group',
            '--property=SendSIGKILL=yes', '--property=OOMPolicy=stop',
            '--property=Nice=10', '--property=UMask=0077', *argv]


def start(argv, directory, maximum, output):
    unit = 'nebo-rev218-smoke-' + uuid.uuid4().hex
    output = Path(output)
    output.mkdir(parents=True, exist_ok=False)
    stdout = (output / 'stdout.txt').open('xb')
    stderr = (output / 'stderr.txt').open('xb')
    command = service_command(unit, argv, directory, maximum)
    try:
        process = subprocess.Popen(command, stdout=stdout, stderr=stderr)
    finally:
        stdout.close()
        stderr.close()
    return unit, process


def stop(unit):
    # Only the unique unit created by start(); never names of other projects.
    if not unit.startswith('nebo-rev218-smoke-') or len(unit) != len('nebo-rev218-smoke-') + 32:
        raise ValueError('Refuse unknown unit')
    return subprocess.run(['sudo', '-n', 'systemctl', 'stop', unit],
                          capture_output=True, timeout=10).returncode


def identity(pid):
    try:
        raw = Path('/proc', str(pid), 'stat').read_text()
    except (FileNotFoundError, ProcessLookupError):
        return None
    tail = raw[raw.rfind(')') + 2:].split()
    return dict(pid=pid, start_ticks=int(tail[19]), state=tail[0])


def wait_no_survivors(identities, timeout=8):
    end = time.monotonic() + timeout
    survivors = []
    while True:
        survivors = []
        for birth in identities:
            observed = identity(birth['pid'])
            if observed and observed['start_ticks'] == birth['start_ticks']:
                survivors.append(observed)
        if not survivors or time.monotonic() >= end:
            return survivors
        time.sleep(0.1)


def write_json(path, value):
    path = Path(path)
    raw = json.dumps(value, indent=2, sort_keys=True) + '\n'
    with path.open('x') as stream:
        stream.write(raw)
