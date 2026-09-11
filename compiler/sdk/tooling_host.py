#!/usr/bin/env python3
"""Compatibility entry point delegating to the shipped native tooling owners."""
from __future__ import annotations
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def check(neboc: Path, source: Path) -> dict:
    p = subprocess.run([str(neboc), 'check', str(source)], capture_output=True, timeout=30)
    return {'exit': p.returncode, 'output': (p.stdout+p.stderr).decode('utf-8','replace'),
            'ok': p.returncode == 0}

def format_checked(neboc: Path, source: Path, write: bool = False) -> dict:
    before = source.read_bytes()
    p = subprocess.run([str(neboc), 'format', str(source), '--write' if write else '--stdout'],
                       capture_output=True, timeout=30)
    after = source.read_bytes() if write else p.stdout
    return {'exit': p.returncode, 'ok': p.returncode == 0,
            'changed': p.returncode == 0 and before != after, 'bytes': len(after),
            'output': p.stderr.decode('utf-8','replace')}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='cmd', required=True)
    for name in ('lsp', 'format', 'lint'):
        p = sub.add_parser(name)
        p.add_argument('--neboc', type=Path, default=ROOT/'build/bin/neboc')
        if name == 'lsp':
            p.add_argument('--symbols', type=Path, help='retired: use initialize.rootUri and workspace/symbol')
        else:
            p.add_argument('source', type=Path)
            p.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.cmd == 'lsp':
        if args.symbols: parser.error('--symbols is retired; the server indexes the initialized workspace')
        return subprocess.call([str(args.neboc), 'lsp'])
    if args.cmd == 'lint':
        if args.write: parser.error('lint does not apply edits; use fix/refactor')
        return subprocess.call([str(args.neboc), 'lint', str(args.source), '--report', 'json'])
    report = format_checked(args.neboc, args.source, args.write)
    print(json.dumps(report, sort_keys=True))
    return report['exit']

if __name__ == '__main__': raise SystemExit(main())
