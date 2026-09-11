#!/usr/bin/env python3
fact=(1,2,3,4,5)
assert len(fact)==5 and fact[3:]==(4,5)
snapshot=(7,(fact,))
assert snapshot[0]==7 and snapshot[1][0]==fact
print("RF46_G34_F01_ORACLE_GREEN fact_id=stable provenance=source_version graph_snapshot=versioned page_identity=hidden")
