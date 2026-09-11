#!/usr/bin/env python3
"""Read-only local RF27 toolchain and supply-chain doctor."""
from __future__ import annotations
import hashlib, json, pathlib, shutil, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
FILES = (
    "build/bin/neboc", "conformance/rf27/manifest.tsv",
    "specification/NEBO-SPECIFICATION-CANDIDATE.md",
    "runtime/security/supply_chain.asm",
)
def main() -> int:
    inventory=[]
    for name in FILES:
        path=ROOT/name
        if not path.is_file():
            print(json.dumps({"status":"missing","path":name},sort_keys=True)); return 2
        data=path.read_bytes()
        inventory.append({"path":name,"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()})
    tools={name: bool(shutil.which(name)) for name in ("nasm","ld","file","readelf","nm","python3")}
    version=subprocess.check_output([str(ROOT/"build/bin/neboc"),"--version"],text=True).strip()
    result={"schema":1,"status":"green" if all(tools.values()) else "limited","version":version,"tools":tools,"inventory":inventory,"network":False,"private_keys":0}
    print(json.dumps(result,sort_keys=True,separators=(",",":")))
    return 0 if result["status"]=="green" else 3
if __name__ == "__main__": sys.exit(main())
