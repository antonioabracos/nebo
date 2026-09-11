#!/usr/bin/env python3
"""Evaluate a local measurement against a caller-selected baseline and policy."""
import argparse,json,sys
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from compiler.sdk.performance_readiness import compare,MeasurementError,canonical

def load(path):
 p=Path(path)
 if p.is_symlink() or not p.is_file() or p.stat().st_size>16777216:raise MeasurementError('NEBO-PERF-INPUT')
 def pairs(rows):
  out={}
  for k,v in rows:
   if k in out:raise MeasurementError('NEBO-PERF-DUPLICATE')
   out[k]=v
  return out
 def bad(value):raise MeasurementError('NEBO-PERF-NUMBER')
 return json.loads(p.read_bytes(),object_pairs_hook=pairs,parse_constant=bad)

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 for name in ('baseline','current','budgets','waivers','date'):parser.add_argument('--'+name,required=True)
 parser.add_argument('--approved-waiver-sha256',action='append',default=[])
 a=parser.parse_args()
 try:
  result=compare(load(a.baseline),load(a.current),load(a.budgets),load(a.waivers),a.date,a.approved_waiver_sha256)
  sys.stdout.buffer.write(canonical(result));return 1 if result['status']=='BLOCK' else 0
 except (ValueError,OSError,KeyError,TypeError) as e:
  print('NEBO-PERF-INVALID: '+str(e),file=sys.stderr);return 2
if __name__=='__main__':raise SystemExit(main())
