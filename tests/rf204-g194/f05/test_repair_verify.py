#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,repair,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); src=d/"src"; prefix=d/"prefix"; build_bundle(ROOT,src,ROOT/"build/bin/neboc"); install(src,prefix)
 target=prefix/"bin/neboc"; target.write_bytes(b"corrupt")
 try: verify_install(prefix)
 except ValueError: pass
 else: raise AssertionError("corruption undetected")
 assert repair(src,prefix)["repaired"]==["bin/neboc"]; verify_install(prefix)
print("RF204-G194-F05=PASS")
