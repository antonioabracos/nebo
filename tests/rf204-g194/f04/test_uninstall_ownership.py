#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,uninstall
with tempfile.TemporaryDirectory() as d:
 d=Path(d); src=d/"src"; prefix=d/"prefix"; build_bundle(ROOT,src,ROOT/"build/bin/neboc"); install(src,prefix)
 keep=prefix/"user-project.txt"; keep.write_text("mine"); result=uninstall(prefix); assert keep.read_text()=="mine" and result["leftovers"]==["user-project.txt"]
print("RF204-G194-F04=PASS")
