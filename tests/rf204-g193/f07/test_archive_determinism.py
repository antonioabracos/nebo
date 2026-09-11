#!/usr/bin/env python3
import sys,tempfile,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT))
from compiler.sdk.sdk_builder import build_bundle,make_archive
with tempfile.TemporaryDirectory() as d:
 b=Path(d)/"bundle"; build_bundle(ROOT,b,ROOT/"build/bin/neboc","sdk"); a=Path(d)/"a.tar"; z=Path(d)/"z.tar"
 assert make_archive(b,a)==make_archive(b,z); assert a.read_bytes()==z.read_bytes()
 assert str(ROOT).encode() not in a.read_bytes()
print("RF204-G193-F07=PASS")
