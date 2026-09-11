#!/usr/bin/env python3
"""Compatibility entry point for the current installed-tooling behavioral oracle."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
subprocess.run([sys.executable, '-B', str(ROOT / 'tests/rf204/G196/validate.py'),
                '--front', '5'], cwd=ROOT, check=True, timeout=240)
