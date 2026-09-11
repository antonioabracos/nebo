#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); source=d/"source"; build_bundle(ROOT,source,ROOT/"build/bin/neboc"); prefix=d/"prefix"
 for phase in ("validate","stage","verify","activate"):
  try: install(source,prefix,phase)
  except OSError: pass
  else: raise AssertionError(phase)
  assert not prefix.exists() and not list(d.glob(".prefix.stage-*"))
 install(source,prefix); verify_install(prefix)
 try: install(source,prefix)
 except FileExistsError: pass
 else: raise AssertionError("collision accepted")
print("RF204-G194-F02=PASS")
