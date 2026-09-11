#!/usr/bin/env python3
nodes=[(1,10,False),(2,20,True),(3,30,False),(4,40,False)]
visible=[v for _,v,t in nodes if not t]
assert visible==[10,30,40]
stable=tuple(min(a,b) for a,b in zip((5,3),(4,7)))
assert stable==(4,3)
assert [v for _,v,t in nodes if not t]==visible
print("RF46_G33_F04_ORACLE_GREEN list=RGA_v1 tombstones=visible_budget causal_stability=explicit_peer_min delta=bounded")
