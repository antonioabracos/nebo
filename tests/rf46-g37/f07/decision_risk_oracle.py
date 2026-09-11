#!/usr/bin/env python3
import argparse
import struct
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument("--artifact",type=Path)
parser.add_argument("--invalid-artifact",type=Path)
args=parser.parse_args()

def fnv1a(data):
    h=0xCBF29CE484222325
    for byte in data:
        h=((h^byte)*0x100000001B3)&((1<<64)-1)
    return h

def artifact(redacted):
    prefix=struct.pack("<8s6Q",b"NBPRB001",1,redacted,0x37,0x04,42,1)
    return prefix+struct.pack("<Q",fnv1a(prefix))

if args.artifact:
    args.artifact.write_bytes(artifact(1))
if args.invalid_artifact:
    args.invalid_artifact.write_bytes(artifact(0))
probabilities=[0.25,0.75]
utilities=[[4.0,0.0],[0.0,2.0]]
expected=[sum(p*u for p,u in zip(probabilities,row)) for row in utilities]
assert expected == [1.0,1.5] and max(range(2),key=expected.__getitem__)==1
losses=[1.0,2.0,3.0,10.0]; tail=losses[3:]
assert (losses[3],sum(tail)/len(tail))==(10.0,10.0)
observations=[0.0,1.0]
brier=sum((p-y)**2 for p,y in zip(probabilities,observations))/2
assert brier==0.0625
data=b"RF46-PROB-REPORT-v1;seed=42;raw_observations=redacted"
h=fnv1a(data)
log_score=sum(__import__('math').log(p if y else 1-p) for p,y in zip(probabilities,observations))/2
assert abs(log_score-(-0.2876820724517809))<1e-15
assert 0.125+0.25==0.375
print(f"RF46_G37_F07_ORACLE_PASS decision=1 utility=1.5 brier={brier} log_score={log_score:.16g} uncertainty=0.375 var=10 cvar=10 provenance={h:016x} privacy=redacted")
