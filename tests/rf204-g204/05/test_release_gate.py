#!/usr/bin/env python3
"""Require the current audited G204 closure, not artifact existence."""
import subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
subprocess.run([str(ROOT/'tests/rf204/G204/validate.sh'),'--check'],cwd=ROOT,check=True,timeout=900)
