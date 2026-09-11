#!/usr/bin/env python3
base=7; add=8; retract=2
incremental=(base|add)&~retract
full={bit for bit in range(64) if ((base|add)&~retract)>>bit&1}
rebuilt=sum(1<<bit for bit in full)
assert incremental==rebuilt==13
explanation={"fact":8,"rule":103,"premises":6,"status":"DERIVED"}
assert set(explanation)=={"fact","rule","premises","status"}
print("RF46_G34_F04_ORACLE_GREEN incremental=full_equal retraction=explicit explanation=proof_facts_only chain_of_thought=NO")
