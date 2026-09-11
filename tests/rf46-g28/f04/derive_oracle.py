#!/usr/bin/env python3
import hashlib,random
r=random.Random(0x462804); ok=bad=0; rows=[]
for case in range(60000):
 requested=r.randrange(16); caps=[r.randrange(32) for _ in range(r.randrange(65))]
 eligible=all((not requested&1 or c&1) and (not requested&2 or c&3==3) and (not requested&4 or c&4) and (not requested&8 or c&8) for c in caps)
 ok+=eligible; bad+=not eligible; rows.append(f"{case}:{requested}:{','.join(map(str,caps))}:{int(eligible)}")
assert ok and bad
print(f"RF46_G28_F04_ORACLE=PASS cases=60000 eligible={ok} rejected={bad} digest={hashlib.sha256(chr(10).join(rows).encode()).hexdigest()}")
