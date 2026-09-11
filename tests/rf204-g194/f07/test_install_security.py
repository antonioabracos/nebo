#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import safe_relative,build_bundle
from compiler.sdk.sdk_lifecycle import install
for hostile in ("../x","/absolute","a/../../b"):
 try: safe_relative(hostile)
 except ValueError: pass
 else: raise AssertionError(hostile)
with tempfile.TemporaryDirectory() as d:
 d=Path(d); src=d/"src"; prefix=d/"prefix"; build_bundle(ROOT,src,ROOT/"build/bin/neboc"); lock=d/".prefix.nebo-lock"; lock.mkdir()
 try: install(src,prefix)
 except RuntimeError: pass
 else: raise AssertionError("concurrent install accepted")
 assert not prefix.exists()
print("RF204-G194-F07=PASS")
