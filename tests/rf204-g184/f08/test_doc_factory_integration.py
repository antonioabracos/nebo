#!/usr/bin/env python3
"""Compatibility entry point for current, authenticated G184 conformance."""
import runpy, sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
sys.argv=[str(root/'tests/rf204/G184/compatibility.py'),'integration']
runpy.run_path(sys.argv[0],run_name='__main__')
