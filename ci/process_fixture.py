#!/usr/bin/env python3
"""Bounded idle processes for supervisor integration, never compiler workloads."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

from supervisor import identity


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--mode', choices=['normal', 'timeout', 'cancel', 'monitor-exit', 'fail'], required=True)
    p.add_argument('--role', choices=['parent', 'child', 'grandchild'], default='parent')
    a = p.parse_args()
    a.output.mkdir(parents=True, exist_ok=True)
    birth = identity(os.getpid())
    (a.output / (a.role + '.json')).write_text(json.dumps(birth))
    print('fixture ' + a.role + ' started', flush=True)
    if a.mode == 'normal':
        return 0
    if a.mode == 'fail':
        (a.output / 'partial-evidence.txt').write_text('preserve expected fixture failure\n')
        return 42
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    child = None
    if a.role != 'grandchild':
        role = 'child' if a.role == 'parent' else 'grandchild'
        child = subprocess.Popen([sys.executable, '-B', __file__, '--output', str(a.output),
                                  '--mode', a.mode, '--role', role], start_new_session=True)
    if a.mode == 'monitor-exit' and a.role == 'parent':
        end = time.monotonic() + 5
        while not (a.output / 'grandchild.json').exists() and time.monotonic() < end:
            time.sleep(0.02)
        return 72
    # A second independent safety bound even if the systemd test fails.
    end = time.monotonic() + 25
    while time.monotonic() < end:
        time.sleep(0.05)
    if child:
        child.wait(timeout=5)
    return 0


if __name__ == '__main__':
    sys.exit(main())
