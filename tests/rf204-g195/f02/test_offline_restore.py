#!/usr/bin/env python3
import sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
from compiler.sdk.sdk_lifecycle import install,verify_install
with tempfile.TemporaryDirectory() as d:
 d=Path(d); local=d/"local-archive"; active=d/"active"; build_bundle(ROOT,local,ROOT/"build/bin/neboc"); install(local,active); assert verify_install(active)["source_manifest_sha256"]
print("RF204-G195-F02=PASS")
