#!/usr/bin/env python3
"""Relocatable offline installer; invoke explicitly with Python 3."""
import sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root))
from compiler.sdk.sdk_lifecycle import main
if __name__=='__main__': raise SystemExit(main())
