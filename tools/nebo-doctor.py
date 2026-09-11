#!/usr/bin/env python3
"""Relocatable public doctor command host."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compiler.sdk.doctor import main
if __name__ == '__main__': raise SystemExit(main())
