#!/usr/bin/env python3
"""Structural multidimensional compatibility diff; never hash-only."""
from __future__ import annotations
import argparse, json
from pathlib import Path
DIMENSIONS=("source","api","abi","data","diagnostics","ownership","effects","capabilities","dependencies","security","target","toolchain")
RANK={"NONE":0,"PATCH":1,"MINOR":2,"MAJOR":3,"SECURITY":4}
def compare(base: dict, candidate: dict) -> dict:
    changes=[]; bump="NONE"
    for dimension in DIMENSIONS:
        before=base.get(dimension,{}); after=candidate.get(dimension,{})
        for identity in sorted(set(before)|set(after)):
            b=before.get(identity); a=after.get(identity)
            if b==a: continue
            if b is None: cls,required="COMPATIBLE","MINOR"
            elif a is None: cls,required="BREAKING","MAJOR"
            elif dimension=="security" and a.get("revoked",False): cls,required="SECURITY_REVOKED","SECURITY"
            elif isinstance(b,dict) and isinstance(a,dict) and b.items()<=a.items(): cls,required="COMPATIBLE","MINOR"
            else: cls,required="BREAKING","MAJOR"
            changes.append({"dimension":dimension,"identity":identity,"classification":cls,"required_bump":required,"before":b,"after":a})
            if RANK[required]>RANK[bump]: bump=required
    return {"format":"nebo-compatibility-vector-v1","dimensions":list(DIMENSIONS),"changes":changes,"required_bump":bump,"blockers":[c for c in changes if c["classification"]!="COMPATIBLE"]}
def main():
    p=argparse.ArgumentParser(); p.add_argument("baseline",type=Path); p.add_argument("candidate",type=Path); p.add_argument("--fail-on-breaking",action="store_true"); a=p.parse_args()
    report=compare(json.loads(a.baseline.read_text()),json.loads(a.candidate.read_text())); print(json.dumps(report,sort_keys=True,indent=2)); raise SystemExit(2 if a.fail_on_breaking and report["blockers"] else 0)
if __name__=="__main__": main()
