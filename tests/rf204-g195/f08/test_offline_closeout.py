#!/usr/bin/env python3
"""Structural gate only; validate.sh owns the complete native lifecycle proof."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tests/rf204/G195'))
from audit import metadata
metadata()
print('OFFLINE_CONTRACT_STRUCTURE=PASS')
