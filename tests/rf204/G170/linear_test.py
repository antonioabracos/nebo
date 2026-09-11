"""Linear operators: independent Python lane algebra and typed source effects."""
import json
import tempfile
from pathlib import Path
from harness import Failure, pipeline, reject

OPERATORS={'dot':'·','cross':'×','hadamard':'⊙','tensor':'⊗',
           'orthogonal':'⟂','parallel':'∥'}

def vector(values):
    return 'Vector<Int> ['+','.join(map(str,values))+']'

def oracle(name,a,b):
    dot=sum(x*y for x,y in zip(a,b))
    cross=[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]] if len(a)==len(b)==3 else None
    return {'dot':dot,'cross':cross,'hadamard':[x*y for x,y in zip(a,b)],
            'tensor':[x*y for x in a for y in b],'orthogonal':dot==0,
            'parallel':cross==[0,0,0]}[name]

def observation(value):
    values=value if isinstance(value,list) else [value]
    return dict(kinds=[5 if isinstance(x,bool) else 4 for x in values],
                text=''.join(str(x).lower() for x in values).encode())

def cases():
    rows=[]
    for name,symbol in OPERATORS.items():
        for n,(a,b) in enumerate([([2,3,4],[5,6,8]),([7,3,4],[5,6,8]),
                ([2,3,4],[5,11,8]),([-2,3,-4],[5,-6,8]),
                ([3,0,0],[0,5,0]),([2,3,4],[6,9,12]),([0,0,0],[7,11,17])]):
            value=oracle(name,a,b);expr=f'(a {symbol} b)'
            body=vector(a)+'.a;'+vector(b)+'.b;'
            if isinstance(value,list):
                body+=expr+'.out;'+''.join(f'out.at({i}).console();' for i in range(len(value)))
            else:body+=expr+'.console();'
            rows.append((f'{name}-values-{n}','start(){'+body+'23.return;}',23,observation(value)))
        a=[2,3,4];b=[5,6,8];value=oracle(name,a,b)
        body=vector(a)+'.a;'+vector(b)+'.b;'+f'(a {symbol} b)'
        if isinstance(value,list):body+='.at(0)';value=value[0]
        for status in (0,7,23,29,255):
            rows.append((f'{name}-return-{status}','start(){'+body+f'.console();{status}.return;}}',status,observation(value)))
    for size in (1,64):
        a=list(range(1,size+1));b=list(range(3,size+3))
        for name in ('dot','hadamard','orthogonal'):
            value=oracle(name,a,b);body=vector(a)+'.a;'+vector(b)+'.b;'+f'(a {OPERATORS[name]} b)'
            if isinstance(value,list):body+=f'.at({size-1})';value=value[-1]
            rows.append((f'{name}-extent-{size}','start(){'+body+'.console();23.return;}',23,observation(value)))
    for left,right in ((1,64),(8,8),(4,3)):
        a=list(range(2,left+2));b=list(range(5,right+5));value=oracle('tensor',a,b)
        body=vector(a)+'.a;'+vector(b)+'.b;(a ⊗ b).c;'
        positions=(0,len(value)//2,len(value)-1)
        body+=''.join(f'c.at({i}).console();' for i in positions)
        rows.append((f'tensor-shape-{left}-{right}','start(){'+body+'23.return;}',23,observation([value[i] for i in positions])))
    for n,(left,right) in enumerate(((17,29),(43,71))):
        body=f'Vector<Int,3>.filled({left}).a;Vector<Int,3>.filled({right}).b;'
        body+='(a ⊙ b).c;(a × b).d;c.at(1).console();d.at(2).console();a.at(0).console();b.at(0).console();'
        rows.append((f'two-live-{n}','start(){'+body+'23.return;}',23,observation([left*right,0,left,right])))
    body='(Vector<Int> [2,3,4] ⊙ Vector<Int> [5,6,8]).sum().console();23.return;'
    rows.append(('inline-owned-operands','start(){'+body+'}',23,observation(60)))
    body='Vector<Int> [2,3,4].a;Vector<Int> [5,6,8].b;((a ⊙ b) · a).console();23.return;'
    rows.append(('nested-owned-result','start(){'+body+'}',23,observation(202)))
    decl='(Int.x)mark(){x.console();x.return;}'
    body='(Vector<Int> [2.mark(),3.mark(),4.mark()] · Vector<Int> [5.mark(),6.mark(),8.mark()]).console();23.return;'
    rows.append(('operand-effects-once',decl+'start(){'+body+'}',23,observation([2,3,4,5,6,8,60])))
    body='Vector<Int,3>.filled(7).a;Vector<Int,3>.filled(11).b;Dict<Int,Int>.new().d;d.insert(17,(a · b));d.get(17).expect("value").console();23.return;'
    rows.append(('dict-owned-argument','start(){'+body+'}',23,observation(231)))
    body='Vector<Int,3>.filled(7).a;Vector<Int,3>.filled(11).b;0.i.mutable;0.total.mutable;while(i<10000){total+=(a · b);i+=1;}total.console();23.return;'
    rows.append(('loop-temporary-reclamation','start(){'+body+'}',23,observation(2310000)))
    for name,symbol in OPERATORS.items():
        a=[9223372036854775807,9223372036854775807,0];b=[2,3,4]
        body=vector(a)+'.a;'+vector(b)+f'.b;(a {symbol} b).console();23.return;'
        if name in ('cross','hadamard','tensor'):body=body.replace(').console();',').at(0).console();')
        rows.append((f'{name}-overflow','start(){'+body+'}',177,{}))
    return rows

def negatives():
    rows=[]
    for name,symbol in OPERATORS.items():
        for kind,operand in [('scalar','17'),('float','Vector<Float> [1.0,2.0,3.0]'),('bool','true')]:
            source='start(){Vector<Int> [2,3,4].a;'+operand+f'.b;(a {symbol} b).return;}}'
            rows.append((name+'-right-'+kind,source,'NEBO_TYPE_MISMATCH'))
        if name!='tensor':
            rows.append((name+'-shape','start(){Vector<Int> [2,3,4].a;Vector<Int> [5,6].b;'+f'(a {symbol} b).return;}}','NEBO_TYPE_MISMATCH'))
    rows.append(('tensor-capacity','start(){Vector<Int,9>.filled(2).a;Vector<Int,8>.filled(3).b;(a ⊗ b).return;}','NEBO_LIMIT_EXCEEDED'))
    for name in ('cross','parallel'):
        rows.append((name+'-not-three','start(){Vector<Int,2>.filled(2).a;Vector<Int,2>.filled(3).b;'+f'(a {OPERATORS[name]} b).return;}}','NEBO_TYPE_MISMATCH'))
    return rows

def run():
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-linear-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,options in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=pipeline(path,work,status,**options)
            except Failure as error:raise Failure(name+':'+str(error)) from error
            results.append(dict(id=name,result='PASS',category='positive',**proof))
        for name,source,code in negatives():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=reject(path,work,code)
            except Failure as error:raise Failure(name+':'+str(error)) from error
            results.append(dict(id=name,result='PASS',category='negative',**proof))
    return dict(schema=1,oracle='independent-python-checked-lane-algebra',cases=results,
                passed=len(results),total=len(cases())+len(negatives()))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
