"""Public hash policy effects; actual runtime seeds feed an independent FNV oracle."""
import json
import struct
import tempfile
from pathlib import Path
from harness import Failure, pipeline, reject

def fnv(seed, value):
    result=14695981039346656037 ^ seed
    for byte in value.to_bytes(8,'little',signed=True):
        result=((result^byte)*1099511628211)&((1<<64)-1)
    return result

def policy_observation(data, selections, previous=None):
    if len(data)!=32*(len(selections)+2): raise Failure('HASH_TRACE_CARDINALITY')
    rows=[struct.unpack_from('<8sQQQ',data,i) for i in range(0,len(data),32)]
    if any(row[0]!=b'NEBOHSH1' for row in rows): raise Failure('HASH_TRACE_MAGIC')
    random_seeds=[]
    for row,(operation,expected_seed) in zip(rows,selections):
        _,actual,mode,seed=row
        if actual!=operation or mode!=int(operation==58): raise Failure('HASH_POLICY_MODE')
        if expected_seed is not None and seed != expected_seed&((1<<64)-1): raise Failure('HASH_POLICY_SEED')
        if operation==58:
            if not seed: raise Failure('HASH_RANDOM_ZERO')
            random_seeds.append(seed)
    if previous is not None and any(a==b for a,b in zip(previous,random_seeds)):
        raise Failure('HASH_RANDOM_REUSED')
    _,_,mode,seed=rows[len(selections)-1]
    if rows[-2][1:]!=(1,mode,seed): raise Failure('HASH_CONSTRUCTOR_POLICY')
    effective=17^seed if mode else 17
    if rows[-1][1:]!=(52,effective,fnv(effective,53)): raise Failure('HASH_NATIVE_RESULT')
    return random_seeds

def run():
    results=[]
    selections_by_case=[('deterministic-zero',[(57,0)]),('deterministic-seed',[(57,29)]),
                        ('deterministic-signed',[(57,-31)]),('randomized',[(58,None)]),
                        ('reset-deterministic',[(58,None),(57,29)])]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-hash-policy-',dir='/tmp') as directory:
        root=Path(directory)
        for name,selections in selections_by_case:
            work=root/name;work.mkdir();source=work/'source.no'
            calls=''.join('hash.randomized();' if op==58 else f'hash.deterministic({seed});'
                          for op,seed in selections)
            source.write_text('start(){'+calls+'Dict<Int,Int>.new().d;d.insert(29,71);'
                              'Hasher.new(17).h;53.hash(h);h.finish();d.get(29).expect("value").return;}')
            seeds=[]
            def observe(data,index):
                observed=policy_observation(data,selections,seeds[0] if index else None)
                seeds.append(observed)
                return ('policy-selected','constructor-matched','full-FNV-result-verified')
            proof=pipeline(source,work,71,hash_trace=True,observation=observe)
            results.append(dict(id=name,result='PASS',category='positive',
                                capability='OS_RANDOM' if any(op==58 for op,_ in selections) else 'NONE',**proof))
        for name,body in [('seed-type','hash.deterministic("bad");'),
                          ('seed-missing','hash.deterministic();'),
                          ('randomized-arity','hash.randomized(17);')]:
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'23.return;}')
            proof=reject(source,work,'NEBO_TYPE_MISMATCH')
            results.append(dict(id=name,result='PASS',category='negative',**proof))
    return dict(cases=results,passed=len(results),total=len(selections_by_case)+3)

if __name__=='__main__': print(json.dumps(run(),sort_keys=True))
