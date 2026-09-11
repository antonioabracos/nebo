#!/usr/bin/env python3
"""Structural multidimensional compatibility diff; never hash-only."""
from __future__ import annotations
import argparse, json, sys, csv, subprocess
from pathlib import Path
from compiler.compat import structural
DIMENSIONS=("source","api","abi","data","diagnostics","ownership","effects","capabilities","dependencies","security","target","toolchain")
RANK={"NONE":0,"PATCH":1,"MINOR":2,"MAJOR":3,"SECURITY":4}
def compare(base: dict, candidate: dict) -> dict:
    if 'format' in base or 'format' in candidate:
        return structural.compare_contracts(base,candidate)
    # Compatibility with existing G189 scalar contract consumers. The public
    # release comparator below requires the complete typed contract envelope.
    for value in (base,candidate):
        structural.bounded(value)
        structural.require(isinstance(value,dict) and set(value)<=set(DIMENSIONS),'/', 'unknown compatibility dimension')
        for dimension, records in value.items():
            structural.require(isinstance(records,dict),'/'+dimension,'symbol map required')
            for identity,fields in records.items():
                structural.require(isinstance(fields,dict) and fields,'/'+dimension+'/'+identity,'nonempty contract fields required')
    changes=[]; bump="NONE"
    for dimension in DIMENSIONS:
        before=base.get(dimension,{}); after=candidate.get(dimension,{})
        for identity in sorted(set(before)|set(after)):
            b=before.get(identity); a=after.get(identity)
            if structural.equal(b,a): continue
            if dimension=="security" and a is not None and a.get("revoked") is True: cls,required="SECURITY_REVOKED","SECURITY"
            elif b is None: cls,required="COMPATIBLE","MINOR"
            elif a is None: cls,required="BREAKING","MAJOR"
            elif (dimension=="diagnostics" and structural.compatible_map(b,a)
                  and all(k.startswith('optional.') for k in a.keys()-b.keys())): cls,required="COMPATIBLE","MINOR"
            else: cls,required="BREAKING","MAJOR"
            changes.append({"dimension":dimension,"identity":identity,"classification":cls,"required_bump":required,"before":b,"after":a})
            if RANK[required]>RANK[bump]: bump=required
    return {"format":"nebo-compatibility-vector-v1","dimensions":list(DIMENSIONS),"changes":changes,"required_bump":bump,"blockers":[c for c in changes if c["classification"]!="COMPATIBLE"]}
def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('baseline',type=Path);p.add_argument('candidate',type=Path)
    mode=p.add_mutually_exclusive_group();mode.add_argument('--ni',action='store_true')
    mode.add_argument('--package',action='store_true',help='compare verified native offline package stores')
    mode.add_argument('--freeze-kind',choices=('api','abi','ni','diagnostic','manifest'))
    p.add_argument('--fail-on-breaking',action='store_true',help='exit 2 for breaking, review-required or incomplete comparisons')
    p.add_argument('--policy',type=Path,help='evaluate bounded local CI policy; never publish')
    a=p.parse_args(argv)
    try:
        from compiler.compat.artifacts import compare_ni,compare_freeze,compare_packages
        if a.ni:
            result=compare_ni(structural.read_path(a.baseline),structural.read_path(a.candidate))
        elif a.package:
            result=compare_packages(a.baseline,a.candidate)
        elif a.freeze_kind:
            result=compare_freeze(a.freeze_kind,a.baseline,a.candidate)
        else:
            result=structural.compare_contracts(structural.parse(structural.read_path(a.baseline)),structural.parse(structural.read_path(a.candidate)))
        decision=None
        if a.policy:
            decision=structural.policy(result,structural.parse(structural.read_path(a.policy)))
            result['ci_policy']=decision
        sys.stdout.buffer.write(structural.canonical(result))
        return 2 if (decision is not None and decision['decision']=='BLOCKED') or (a.fail_on_breaking and result['blockers']) else 0
    except (OSError,ValueError,csv.Error,RecursionError,subprocess.TimeoutExpired) as error:
        diagnostic=dict(code='NEBO_COMPAT_INVALID',severity='error',pointer=getattr(error,'pointer','/'),message=str(error),published=False)
        sys.stderr.buffer.write(structural.canonical(diagnostic));return 3
if __name__=="__main__": raise SystemExit(main())
