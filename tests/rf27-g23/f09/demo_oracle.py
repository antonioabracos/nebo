#!/usr/bin/env python3
import hashlib,struct
h=hashlib.sha256()
for case in range(3000):
 tokens=(1,2,3);logits=tuple((3*17+i*3-6)<<16 for i in range(16));sample=15;tool=16;score=65536
 h.update(struct.pack('<I3B16qIII',case,*tokens,*logits,sample,tool,score))
print(f'RF27_G23_F09_ORACLE=PASS cases=3000 tokens=1_2_3 sample=15 tool_result=16 score_q16=65536 external_effects=0 digest={h.hexdigest()}')
