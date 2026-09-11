#!/usr/bin/env python3
import json,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
with tempfile.TemporaryDirectory() as d:
 root=Path(d)/"sdk"; build_bundle(ROOT,root,ROOT/"build/bin/neboc"); p=subprocess.run([sys.executable,ROOT/"scripts/rf204/neboc-doctor.py","--sdk-root",root],stdout=subprocess.PIPE,text=True)
 report=json.loads(p.stdout); assert p.returncode==0 and report["sdk_root"]=="<SDK_ROOT>" and report["external_network_used"] is False
 assert str(root) not in p.stdout
print("RF204-G194-F06=PASS")
