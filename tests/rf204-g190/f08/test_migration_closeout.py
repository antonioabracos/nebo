#!/usr/bin/env python3
"""Current rule inventory and a real source differential gate."""
import runpy,sys
from pathlib import Path
root=Path(__file__).resolve().parents[3];sys.path.insert(0,str(root/'tests/rf204/G190'))
from coverage import historical
assert len(historical())==22726
runpy.run_path(str(root/'tests/rf204-g190/f07/test_migration_verification.py'),run_name='__main__')
print('RF204-G190-F08=PASS')
