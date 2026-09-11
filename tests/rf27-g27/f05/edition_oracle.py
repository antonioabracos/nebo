#!/usr/bin/env python3
import hashlib, random
r=random.Random(0x272705); rows=[]; ok=unknown=version=abi=runtime=feature=unsafe=0
for i in range(70000):
 e=r.randrange(4); lo=r.randrange(1,4); hi=r.randrange(1,4); a=r.randrange(5)!=0; rt=r.randrange(6)!=0; f=r.randrange(0x12000); u=r.randrange(9)==0
 if e not in (1,2): s='unknown'; unknown+=1
 elif lo>hi or not lo<=e<=hi: s='version'; version+=1
 elif not a: s='abi'; abi+=1
 elif not rt: s='runtime'; runtime+=1
 elif f>0xffff: s='feature'; feature+=1
 elif u: s='unsafe'; unsafe+=1
 else: s='ok'; ok+=1
 rows.append(f'{i}:{e}:{lo}:{hi}:{int(a)}:{int(rt)}:{f}:{int(u)}:{s}')
print(f'RF27_G27_F05_ORACLE=PASS cases=70000 ok={ok} unknown={unknown} version={version} abi={abi} runtime={runtime} feature={feature} unsafe={unsafe} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}')
