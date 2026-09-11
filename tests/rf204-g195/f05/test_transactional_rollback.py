#!/usr/bin/env python3
import subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,upgrade,rollback,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); old=d/"old"; new=d/"new"; active=d/"active"; build_bundle(ROOT,old,ROOT/"build/bin/neboc","sdk"); build_bundle(ROOT,new,ROOT/"build/bin/neboc","sdk"); install(old,active); original=(active/"bin/neboc").read_bytes(); upgrade(active,new); rollback(active); assert (active/"bin/neboc").read_bytes()==original and verify_install(active)["profile"]=="sdk"
print("RF204-G195-F05=PASS")
