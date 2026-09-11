#!/usr/bin/env python3
"""Typed public Vector values use native numeric storage and scalar oracles."""
import json, math, tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute


def cases():
    rows=[]
    def add(name,body,value,returned=23,**options):
        if isinstance(value,str): expected=dict(kinds=[2],text=value.encode())
        elif isinstance(value,bool): expected=dict(kinds=[5],text=str(value).lower().encode())
        else: expected=dict(kinds=[4],text=str(value).encode())
        expected.update(options)
        rows.append((name,'start(){'+body+f'{returned}.return;}}',returned,expected))
    for t,values in [('Int',(9,17,-29)),('Float',(1.5,-7.25,29.5))]:
        for size in (1,4,64):
            for value in values:
                name=f'filled-{t}-{size}-{value}'
                body=f'Vector<{t},{size}>.filled({value}).a;'
                if t=='Int': body+=f'a.at({size-1}).console();'; wanted=value
                else: body+=f'"${{a.at({size-1}):fixed(2)}}".console();';wanted=f'{value:.2f}'
                add(name,body,wanted)
    for returned in (0,7,23,29,255):
        for t,value,body,wanted in [('Int',9,'a.at(2).console();',9),('Float',1.5,'"${a.at(2):fixed(2)}".console();','1.50')]:
            add(f'return-{t}-{returned}',f'Vector<{t},4>.filled({value}).a;'+body,wanted,returned)
    for t,values in [('Int',[17,29,43]),('Float',[1.5,7.25,-29.5])]:
        for index,value in enumerate(values):
            for extent in ('',',3'):
                body=f'Vector<{t}{extent}> ['+','.join(map(str,values))+'].a;'
                if t=='Int': body+=f'a.at({index}).console();';wanted=value
                else: body+=f'"${{a.at({index}):fixed(2)}}".console();';wanted=f'{value:.2f}'
                add(f'literal-{t}-{index}-{bool(extent)}',body,wanted)
    for first,second in ((17,29),(43,29),(17,71)):
        add(f'two-live-{first}-{second}',f'Vector<Int,4>.filled({first}).a;Vector<Int,4>.filled({second}).b;a.at(1).console();b.at(3).console();a.at(0).console();',str(first)+str(second)+str(first),kinds=[4,4,4],publications=3)
        add(f'add-{first}-{second}',f'Vector<Int,4>.filled({first}).a;Vector<Int,4>.filled({second}).b;a.add(b).c;c.at(2).console();',first+second)
        add(f'dot-{first}-{second}',f'Vector<Int> [{first},{second}].a;Vector<Int> [3,5].b;a.dot(b).console();',first*3+second*5)
        add(f'scale-{first}-{second}',f'Vector<Int> [17,{first},43].a;a.scale({second}).b;b.at(1).console();',first*second)
    for left,right in ((3.0,4.0),(5.0,12.0),(8.0,15.0)):
        prefix=f'Vector<Float> [{left},{right}].a;Vector<Float> [1.0,2.0].b;'
        for method,expr,wanted in [('add','a.add(b).at(1)',right+2),('scale','a.scale(2.0).at(1)',right*2),('dot','a.dot(b)',left+right*2),('norm','a.norm()',math.hypot(left,right)),('normalize','a.normalize().at(0)',left/math.hypot(left,right))]:
            add(f'{method}-Float-{left}-{right}',prefix+'"${'+expr+':fixed(6)}".console();',f'{wanted:.6f}')
    add('source-preserved-after-add','Vector<Int> [17,29].a;Vector<Int> [43,71].b;a.add(b).c;a.at(1).console();b.at(1).console();c.at(1).console();','2971100',kinds=[4,4,4],publications=3)
    add('source-preserved-after-normalize','Vector<Float> [3.0,4.0].a;a.normalize().b;"${a.at(0):fixed(2)}/${b.at(0):fixed(2)}".console();','3.00/0.60')
    add('chained-inline','Vector<Int,4>.filled(17).scale(3).at(2).console();',51)
    add('dynamic-index','Vector<Int> [17,29,43].a;1.i.mutable;a.at(i).console();i=2;a.at(i).console();','2943',kinds=[4,4],publications=2)
    add('vector-dict-composition','Dict<Int,Int>.new().d;d.insert(17,29);Vector<Int,4>.filled(43).a;d.get(17).unwrapOr(0).console();a.at(2).console();','2943',kinds=[4,4],publications=2)
    add('vector-set-composition','Set<Int>.new().s;s.insert(17);Vector<Int,4>.filled(29).a;s.contains(17).console();a.at(0).console();','true29',kinds=[5,4],publications=2)
    add('loop-composition','Vector<Int> [17,29,43].a;0.i.mutable;0.total.mutable;while(i<3){total+=a.at(i);i+=1;}total.console();',89)
    add('scalar-binary-owned-rhs','Vector<Int> [17,29].a;(43+a.at(1)).console();',72)
    add('nested-binary-owned-rhs','Vector<Int> [17,29].a;(43+(7+a.at(1))).console();',79)
    add('float-binary-owned-rhs','Vector<Float> [1.5,2.25].a;"${7.5+a.at(1):fixed(2)}".console();','9.75')
    add('bytes-index-owned-rhs','Bytes.fromValues(17,29,43,71).b;Vector<Int,4>.filled(2).a;b.at(a.at(1)).console();',43)
    add('text-scalar-owned-rhs','17.total.mutable;total+="Nebo".byteLength();total.console();',21)
    add('negative-zero','Vector<Float,4>.filled(-0.0).a;a.at(3).isNegativeZero().console();',True)
    add('zero-lane-index','Vector<Int,1>.filled(17).a;a.at(-0).console();',17)
    for size in (1,64):
        values=list(range(11,11+size));body='Vector<Int> ['+','.join(map(str,values))+f'].a;a.at({size-1}).console();'
        add(f'literal-bound-{size}',body,values[-1])
    for value in (0,7,23,29,255):
        source=f'start(){{Vector<Int,4>.filled({value}).a;a.at(2).return;}}'
        rows.append((f'lane-as-status-{value}',source,value,{}))
    decl='(Int.value)mark(){value.console();value.return;}'
    body='Vector<Int> [17.mark(),29.mark()].a;a.at(1).console();23.return;'
    rows.append(('literal-effects-once',decl+'start(){'+body+'}',23,dict(kinds=[4,4,4],text=b'172929',publications=3)))
    body='Vector<Int,4>.filled(17.mark()).a;a.scale(3.mark()).b;b.at(2.mark()).console();23.return;'
    rows.append(('calls-effects-once',decl+'start(){'+body+'}',23,dict(kinds=[4,4,4,4],text=b'173251',publications=4)))
    decl='(Int.value)lane(){Vector<Int,4>.filled(value).a;a.at(2).return;}'
    rows.append(('ordinary-function-local',decl+'start(){29.lane().console();23.return;}',23,dict(kinds=[4],text=b'29')))
    for constructor in ('Vector<Float,2>.filled(1.5.first(2.75))','Vector<Float> [1.5.first(2.75),7.25.first(11.5)]'):
        value='1.50' if '.filled' in constructor else '7.25'
        source='(Float.x)first(Float.y){x.return;}start(){'+constructor+'.v;v.at(1).x;"${x:fixed(2)}".console();23.return;}'
        rows.append(('float-return-bits-'+('filled' if '.filled' in constructor else 'literal'),source,23,dict(kinds=[2],text=value.encode())))
    return rows


def negatives():
    type_error='NEBO_TYPE_MISMATCH';limit='NEBO_LIMIT_EXCEEDED'
    rows=[]
    def add(name,body,code=type_error,marker=None):
        rows.append((name,'start(){'+body+'23.return;}',code,marker))
    for t,value in [('Text','"bad"'),('Bool','true'),('Char',"'A'"),('Unknown','17')]:
        add('element-'+t,f'Vector<{t},4>.filled({value}).a;',marker=f'Vector<{t},4>.filled({value})')
    for t,value in [('Int','true'),('Int','1.5'),('Float','17'),('Float','"bad"')]:
        add('filled-type-'+t+'-'+value,f'Vector<{t},4>.filled({value}).a;')
    for size in (0,65,255):add('extent-'+str(size),f'Vector<Int,{size}>.filled(9).a;',limit)
    for name,body in [('missing-dimension','Vector<Int>.filled(9).a;'),('empty-arguments','Vector<Int,4>.filled().a;'),('extra-arguments','Vector<Int,4>.filled(9,17).a;'),('literal-wrong-type','Vector<Int> [17,true].a;'),('literal-extent-mismatch','Vector<Int,3> [17,29].a;')]:add(name,body)
    add('literal-empty','Vector<Int> [].a;',limit)
    add('literal-over-bound','Vector<Int> ['+','.join(['17']*65)+'].a;','NEBO_PARSE_EXPECTED_TOKEN')
    add('numeric-key-is-not-type','Dict<Int,3>.new().d;','NEBO_PARSE_EXPECTED_TOKEN')
    add('numeric-first-is-not-type','Vector<3,4>.filled(9).a;','NEBO_PARSE_EXPECTED_TOKEN')
    prefix='Vector<Int,4>.filled(17).a;'
    for index in (4,64,-1):add('index-'+str(index),prefix+f'a.at({index}).v;',limit,marker=f'a.at({index})')
    for method,args in [('at','true'),('at','1.5'),('at',''),('at','1,2'),('scale','true'),('scale',''),('dot','17'),('add','17'),('norm',''),('normalize','')]:add('method-'+method+'-'+(args or 'empty'),prefix+f'a.{method}({args}).v;')
    for t,n in [('Int',3),('Float',4)]:
        value='29' if t=='Int' else '1.5'
        for method in ('add','dot'):add(f'shape-{method}-{t}-{n}',prefix+f'Vector<{t},{n}>.filled({value}).b;a.{method}(b).v;')
    prefix='Vector<Float,4>.filled(1.5).a;'
    for method,args in [('scale','2'),('norm','1'),('normalize','1')]:add('float-method-'+method,prefix+f'a.{method}({args}).v;')
    rows.append(('vector-status','start(){Vector<Int,4>.filled(17).a;a.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE',None))
    source='(Int.value)mark(){value.console();value.return;}start(){"${Vector<Int,4>.filled(17.mark()).at(2)}".console();23.return;}'
    rows.append(('interpolation-effectful-constructor',source,'NEBO_INTERPOLATION_EFFECT_FORBIDDEN',None))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-vector-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,options in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try: row=dict(result='PASS',**pipeline(path,work,status,**options))
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code,marker in negatives():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            span=(source.index(marker),source.index(marker)+len(marker)) if marker else None
            try:row=dict(result='PASS',**reject(path,work,code,span=span))
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
        try:
            target=ROOT/'build/tests/rf27-g14/f04/vector_test'
            result=execute(['ninja','-j2',target.relative_to(ROOT)],root,timeout=60)
            if result[0]:raise Failure('NATIVE_VECTOR_BUILD:'+repr(result))
            result=execute([target],root,runtime=True)
            if result!=(0,b'',b''):raise Failure('NATIVE_VECTOR_ORACLE:'+repr(result))
            row=dict(result='PASS',source='tests/rf27-g14/f04/vector_test.asm')
        except Failure as error:row=dict(result='FAIL',failure=str(error))
        rows.append(dict(id='native-storage-failure-atomicity',category='native',**row))
    return dict(cases=rows,passed=sum(x['result']=='PASS' for x in rows),total=len(rows))


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
