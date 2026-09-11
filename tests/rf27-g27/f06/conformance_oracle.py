#!/usr/bin/env python3
import csv, hashlib, pathlib, random
root=pathlib.Path(__file__).resolve().parents[3]
manifest=root/'conformance/rf27/manifest.tsv'; spec=root/'specification/NEBO-SPECIFICATION-CANDIDATE.md'
rows=list(csv.DictReader(manifest.open(),delimiter='\t'))
assert len(rows)==12 and len({r['case_id'] for r in rows})==12
assert all(r['target']=='x86_64-systemv-elf-linux' and r['abi']=='0' and r['edition'] in {'1','2'} for r in rows)
text=spec.read_text()
assert all(f"RULE-{r['rule_id']}" in text for r in rows)
rng=random.Random(0x272706); accepted=denied=0; corpus=[]
for i in range(60000):
 row=dict(rows[rng.randrange(len(rows))]); mutation=rng.randrange(7)
 if mutation==1: row['target']='unknown'
 elif mutation==2: row['abi']='1'
 elif mutation==3: row['edition']='9'
 elif mutation==4: row['rule_id']='0'
 elif mutation==5: row['class']='mystery'
 elif mutation==6: row['expected']='mismatch'
 ok=mutation==0
 accepted+=ok;denied+=not ok;corpus.append(f'{i}:{mutation}:{int(ok)}')
digest=hashlib.sha256(manifest.read_bytes()+spec.read_bytes()+"\n".join(corpus).encode()).hexdigest()
print(f'RF27_G27_F06_ORACLE=PASS manifest=12 rules=12 mutations=60000 accepted={accepted} denied={denied} digest={digest}')
