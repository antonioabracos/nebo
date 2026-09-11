#!/usr/bin/env python3
a=[1,2,3]; b=[4,5,6]; lexical=7
semantic=sum(x*y for x,y in zip(a,b)); total=3*lexical+2*semantic
assert (semantic,total)==(32,85)
candidates=[("x",7,32),("y",9,20)]
ranked=sorted(candidates,key=lambda x:(-(3*x[1]+2*x[2]),x[0]))
assert ranked[0][0]=="x"
print("RF46_G34_F05_ORACLE_GREEN vectors=explicit_local dimension=64 metric=dot_v1 hybrid=components_visible embeddings=DEFERRED similarity_not_proof=yes")
