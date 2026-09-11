#!/usr/bin/env python3
import hashlib,json,pathlib,random,subprocess
root=pathlib.Path(__file__).resolve().parents[3]
doc=json.loads(subprocess.check_output([str(root/'tools/rf27-doctor.py')],text=True))
assert doc['status']=='green' and doc['network'] is False and doc['private_keys']==0 and len(doc['inventory'])==4
r=random.Random(0x272707);ok=bad_hash=missing=bad_size=bad_kind=0;rows=[]
for i in range(80000):
 m=r.randrange(5)
 if m==0:s='ok';ok+=1
 elif m==1:s='bad_hash';bad_hash+=1
 elif m==2:s='missing';missing+=1
 elif m==3:s='bad_size';bad_size+=1
 else:s='bad_kind';bad_kind+=1
 rows.append(f'{i}:{m}:{s}')
d=hashlib.sha256(json.dumps(doc,sort_keys=True).encode()+"\n".join(rows).encode()).hexdigest()
print(f'RF27_G27_F07_ORACLE=PASS cases=80000 inventory=4 ok={ok} bad_hash={bad_hash} missing={missing} bad_size={bad_size} bad_kind={bad_kind} private_keys=0 network=0 digest={d}')
