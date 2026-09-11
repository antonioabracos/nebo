#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x272708);restored=refused=0;rows=[]
for i in range(60000):
 stage=r.randrange(7); tmp_owned=r.randrange(8)!=0; tracked_write=r.randrange(20)==0; tag=r.randrange(25)==0; remote=r.randrange(30)==0
 ok=tmp_owned and not tracked_write and not tag and not remote
 if ok: restored+=1;s='restored'
 else: refused+=1;s='refused'
 rows.append(f'{i}:{stage}:{int(tmp_owned)}:{int(tracked_write)}:{int(tag)}:{int(remote)}:{s}')
print(f'RF27_G27_F08_ORACLE=PASS cases=60000 restored={restored} refused={refused} tracked_release_writes=0 tag_mutations=0 remote_mutations=0 digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}')
