#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_lifecycle import cache_gc
with tempfile.TemporaryDirectory() as d:
 c=Path(d); (c/"active123").mkdir(); (c/"stale456").mkdir(); assert cache_gc(c,{"active123"})==["stale456"] and (c/"active123").is_dir()
 (c/"bad-key").mkdir()
 try: cache_gc(c,{"active123"})
 except ValueError: pass
 else: raise AssertionError("hostile key accepted")
print("RF204-G195-F06=PASS")
