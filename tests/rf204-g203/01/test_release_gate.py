#!/usr/bin/env python3
"""The former existence-only gate now runs the current sealed candidate audit."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[3]
subprocess.run([str(ROOT/'tests/rf204/G203/validate.sh'),'--check'],cwd=ROOT,check=True,timeout=900)
