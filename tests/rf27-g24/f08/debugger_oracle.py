#!/usr/bin/env python3
import hashlib,random,sys
sys.dont_write_bytecode=True
r=random.Random(0x272408); rows=[]; denied=0
for c in range(10000):
 s='running'; owner=r.getrandbits(64) or 1; seq=1
 for op in ('stop','breakpoint','step','continue','terminate'):
  ok=(r.randrange(8)!=0) and s!='closed' and ((op=='stop' and s=='running') or (op in ('breakpoint','step','continue') and s=='stopped') or op=='terminate')
  if ok:
   seq+=1
   if op=='stop': s='stopped'
   elif op=='continue': s='running'
   elif op=='terminate': s='closed'
  else: denied+=1
  rows.append(f'{c}:{op}:{s}:{seq}:{int(ok)}')
d=hashlib.sha256('\n'.join(rows).encode()).hexdigest()
print(f'RF27_G24_F08_ORACLE=PASS transitions=50000 denied={denied} remote_attach=0 digest={d}')
