#!/usr/bin/env python3
def classify(valid,support,contra):
    if not valid:return "INVALID"
    if support and contra:return "AMBIGUOUS"
    if support:return "SUPPORTED"
    if contra:return "CONTRADICTED"
    return "UNKNOWN"
assert {classify(1,s,c) for s,c in ((1,0),(0,1),(1,1),(0,0))}=={"SUPPORTED","CONTRADICTED","AMBIGUOUS","UNKNOWN"}
citation={"fact":11,"source":7,"version":3}
assert tuple(citation)==("fact","source","version")
print("RF46_G34_F06_ORACLE_GREEN claims=SUPPORTED_CONTRADICTED_UNKNOWN_AMBIGUOUS_INVALID citations=versioned external_truth=NO group=G34_GREEN")
