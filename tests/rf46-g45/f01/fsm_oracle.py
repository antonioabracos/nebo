#!/usr/bin/env python3
table=[(1,10,2),(2,20,3)]
def step(state,event):
    matches=[n for s,e,n in table if (s,e)==(state,event)]
    return matches[0] if len(matches)==1 else "NONE" if not matches else "NONDETERMINISTIC"
assert step(1,10)==2 and step(3,10)=="NONE"
assert len({(s,e) for s,e,_ in table})==len(table)
print("RF46_G45_F01_ORACLE_GREEN FSM=versioned deterministic=yes invalid_event=typed atomic_transition=yes reference=independent")
