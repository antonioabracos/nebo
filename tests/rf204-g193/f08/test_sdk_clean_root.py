#!/usr/bin/env python3
import subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle
with tempfile.TemporaryDirectory() as d:
 b=Path(d)/"sdk"; build_bundle(ROOT,b,ROOT/"build/bin/neboc","sdk")
 assert subprocess.run([b/"bin/neboc","--version"],stdout=subprocess.PIPE).returncode==0
 src=b/"share/examples/hello/main.no"; exe=Path(d)/"app"
 p=subprocess.run([b/"bin/neboc","build",src,"-o",exe],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True); assert p.returncode==0,p.stdout
 run=subprocess.run([exe],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True); assert run.returncode==0 and run.stdout=="",run.stdout
print("RF204-G193-F08=PASS")
