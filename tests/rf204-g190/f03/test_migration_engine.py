#!/usr/bin/env python3
"""Compatibility entrypoint for the repaired transaction campaign."""
import sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tests/rf204/G190'))
from self_test import run
assert run()>=20
print('RF204-G190-F03=PASS')
