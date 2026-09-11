#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,verify_install,repair,uninstall
with tempfile.TemporaryDirectory() as d:
 d=Path(d); source=d/"source"; build_bundle(ROOT,source,ROOT/"build/bin/neboc")
 for i in range(6):
  prefix=d/f"p{i}"; install(source,prefix); verify_install(prefix); (prefix/"bin/neboc").write_bytes(b"bad"); repair(source,prefix); verify_install(prefix); assert not uninstall(prefix)["leftovers"] and not prefix.exists()
print("RF204-G194-F08=PASS")
