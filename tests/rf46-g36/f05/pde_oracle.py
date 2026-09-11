#!/usr/bin/env python3
def step(a,alpha):
    return [a[0]]+[alpha*a[i-1]+(1-2*alpha)*a[i]+alpha*a[i+1] for i in range(1,len(a)-1)]+[a[-1]]
g=[0.,0.,1.,0.,0.]
g1=step(g,.25)
assert g1==[0.,.25,.5,.25,0.] and sum(g1)==1
g2=step(g1,.25)
assert max(g2)<max(g1) and 0 <= sum(g2) <= sum(g1)
print('RF46_G36_F05_ORACLE_PASS pde=heat1d mass=nonincreasing_dirichlet convergence=smoothing')
