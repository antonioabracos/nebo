#!/usr/bin/env python3
from pathlib import Path
import subprocess,sys
ROOT=Path(__file__).resolve().parents[3]
subprocess.run([sys.executable,'-B',ROOT/'tests/rf204/G191/self_test.py'],check=True,timeout=30)
print("RF204-G191-F08=PASS")
