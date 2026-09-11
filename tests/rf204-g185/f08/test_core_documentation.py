#!/usr/bin/env python3
"""Legacy entry point delegates to the current read-only individual audit."""
from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[3]
raise SystemExit(subprocess.run([sys.executable, '-B', str(root/'tests/rf204/G185/audit.py')], cwd=root).returncode)
