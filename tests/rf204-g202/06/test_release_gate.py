#!/usr/bin/env python3
"""Validate current RC2 proof and independent native effects."""
import subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
subprocess.run([str(ROOT/'tests/rf204/G202/validate.sh'),'--check'],cwd=ROOT,check=True,timeout=600)
