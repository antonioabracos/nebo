#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,upgrade,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); one=d/"one"; two=d/"two"; active=d/"active"; build_bundle(ROOT,one,ROOT/"build/bin/neboc"); build_bundle(ROOT,two,ROOT/"build/bin/neboc","sdk"); install(one,active); before=verify_install(active)["profile"]
 result=upgrade(active,two); assert result["active"] and verify_install(active)["profile"]=="sdk" and verify_install(d/"active.nebo-rollback")["profile"]==before
print("RF204-G195-F04=PASS")
