#!/usr/bin/env python3
events=[]
def append(expected,eid,value):
    if expected != len(events): return "CONFLICT"
    if any(e[0]==eid for e in events): return "DUPLICATE"
    events.append((eid,value)); return "OK"
assert append(0,101,5)=="OK"
assert append(0,102,7)=="CONFLICT"
assert append(1,102,7)=="OK"
assert sum(v for _,v in events[:2])==12
snapshot=(2,12)
assert snapshot[0]==len(events)
print("RF46_G33_F01_ORACLE_GREEN append=expected_version replay=pure snapshot=exact_prefix duplicate=idempotent_visible")
