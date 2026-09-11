#!/usr/bin/env python3
"""Compatibility entry: execute the current real whole-group measurement campaign."""
import runpy,sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tests/rf204/G199'))
runpy.run_path(str(root/'tests/rf204/G199/validate.py'),run_name='__main__')
