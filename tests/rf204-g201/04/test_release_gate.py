#!/usr/bin/env python3
"""Compatibility entry: reconstruct the complete current G201 evidence."""
import subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]

def test_current_group():
    subprocess.run(['bash','tests/rf204/G201/validate.sh','--check'],cwd=ROOT,timeout=600,check=True)

if __name__=='__main__':
    test_current_group()
