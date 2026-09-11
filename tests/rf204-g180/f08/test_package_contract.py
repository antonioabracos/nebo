#!/usr/bin/env python3
from __future__ import annotations
import copy, hashlib, json, subprocess, tempfile
from pathlib import Path

root=Path(__file__).resolve().parents[3]; tool=root/"scripts/rf204/package_contract.py"
def put(path, data): path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data); return hashlib.sha256(data).hexdigest()
def run(base, manifest, lock):
    (base/"manifest.json").write_text(json.dumps(manifest, sort_keys=True)); (base/"lock.json").write_text(json.dumps(lock, sort_keys=True))
    return subprocess.run([str(tool),"--manifest",str(base/"manifest.json"),"--lock",str(base/"lock.json"),"--store",str(base/"store")],text=True,capture_output=True)
def fixture(base):
    target="x86_64-systemv-elf-linux"; ni="0"*64
    dep=b"dep"; app=b"app"; dsha=put(base/"store/nebo.std.text/1.0.0"/(hashlib.sha256(dep).hexdigest()+".pkg"),dep); asha=put(base/"store/example.app/1.0.0"/(hashlib.sha256(app).hexdigest()+".pkg"),app)
    manifest={"schema":"NEBO-PACKAGE-MANIFEST-v1","package":"example.app","version":"1.0.0","edition":"1.0","targets":[target],"source_roots":["src"],"modules":["src/main.nebo"],"dependencies":{"nebo.std.text":"1.0.0"},"capabilities":[],"features":[]}
    lock={"schema":"NEBO-PACKAGE-LOCK-v1","root":"example.app","packages":[{"id":"example.app","version":"1.0.0","sha256":asha,"ni_fingerprint":ni,"dependencies":["nebo.std.text"],"target":target,"edition":"1.0"},{"id":"nebo.std.text","version":"1.0.0","sha256":dsha,"ni_fingerprint":ni,"dependencies":[],"target":target,"edition":"1.0"}]}
    return manifest,lock
with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
    aa,bb=Path(a),Path(b); ma,la=fixture(aa); mb,lb=fixture(bb); ra,rb=run(aa,ma,la),run(bb,mb,lb)
    # Opaque payloads and all-zero interface fingerprints are not runtime proof.
    assert ra.returncode==rb.returncode==3
    assert json.loads(ra.stdout)["result"]==json.loads(rb.stdout)["result"]=="REJECT"
    bad=copy.deepcopy(ma); bad["source_roots"]=["../escape"]; assert run(aa,bad,la).returncode==3
    bad=copy.deepcopy(ma); bad["dependencies"]["nebo.std.text"]="^1.0"; assert run(aa,bad,la).returncode==3
    bad=copy.deepcopy(la); bad["packages"][1]["sha256"]="f"*64; assert run(aa,ma,bad).returncode==3
    bad=copy.deepcopy(la); bad["packages"][1]["dependencies"]=["example.app"]; assert run(aa,ma,bad).returncode==3
print("RF204_G180_F08_OPAQUE_FALSE_GREEN_REJECTION=PASS")
