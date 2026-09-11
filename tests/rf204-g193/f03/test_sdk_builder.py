#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle,verify_bundle,safe_relative
with tempfile.TemporaryDirectory() as d:
 out=Path(d)/"bundle"; m=build_bundle(ROOT,out,ROOT/"build/bin/neboc","sdk"); assert verify_bundle(out)==m
 assert (out/"bin/neboc").is_file() and not any(str(ROOT) in str(x) for x in m["files"])
 try: safe_relative("../escape")
 except ValueError: pass
 else: raise AssertionError("traversal accepted")
 try: build_bundle(ROOT,out,ROOT/"build/bin/neboc","sdk")
 except FileExistsError: pass
 else: raise AssertionError("overwrite accepted")
print("RF204-G193-F03=PASS")
