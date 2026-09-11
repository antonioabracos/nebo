#!/usr/bin/env python3
import json,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle,verify_bundle
from compiler.sdk.sdk_lifecycle import install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); src=d/"src"; build_bundle(ROOT,src,ROOT/"build/bin/neboc"); (src/"bin/neboc").write_bytes(b"bad")
 try: verify_bundle(src)
 except ValueError as e: assert "digest mismatch" in str(e)
 else: raise AssertionError("bad archive accepted")
 try: install(src,d/"active")
 except ValueError: pass
 else: raise AssertionError("corrupt restore accepted")
 assert not (d/"active").exists()
print("RF204-G195-F03=PASS")
