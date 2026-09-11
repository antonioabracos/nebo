#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,upgrade,rollback,uninstall,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); old=d/"old"; new=d/"new"; build_bundle(ROOT,old,ROOT/"build/bin/neboc","sdk"); build_bundle(ROOT,new,ROOT/"build/bin/neboc","sdk")
 for i in range(4):
  active=d/f"active{i}"; install(old,active); verify_install(active); upgrade(active,new); rollback(active); verify_install(active); assert not uninstall(active)["leftovers"]
print("RF204-G195-F07=PASS")
