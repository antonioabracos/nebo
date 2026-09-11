#!/usr/bin/env python3
"""Typed Matrix source values versus independent shape/element oracles."""
import json, re, tempfile, math, statistics
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf

def function_cases():
    rows=[]
    for dtype,values in [('Int',[7,11,23]),('Float',[1.5,2.75,-7.25])]:
        for value in values:
            for returned in (0,7,23,29,255):
                source=f'({dtype}.x)make(){{Matrix<{dtype}>.filled(2,3,x).return;}}start(){{({value}).make().a;({value+1}).make().b;(a.sum()+b.sum()).v;'
                source+=('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();')+f'{returned}.return;}}'
                wanted=6*(2*value+1)
                rows.append((f'{dtype}-function-return-{value}-{returned}',source,returned,dict(kinds=[4 if dtype=='Int' else 2],text=(str(wanted) if dtype=='Int' else f'{wanted:.2f}').encode())))
        for transposed in (False,True):
            view='.transposeView()' if transposed else ''
            value=values[0]
            source=f'(Matrix<{dtype}>.x)copy(){{x.return;}}start(){{Matrix<{dtype}>.filled(2,3,{value}){view}.m;m.copy().a;a.sum().v;'
            source+=('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();')+'a.rows().console();23.return;}'
            wanted=(str(6*value) if dtype=='Int' else f'{6*value:.2f}')+str(3 if transposed else 2)
            rows.append((f'{dtype}-function-borrow-return-{transposed}',source,23,dict(kinds=[4 if dtype=='Int' else 2,4],text=wanted.encode())))
            source=f'(Int.x)read(Matrix<{dtype}>.m){{m.sum().return;}}start(){{Matrix<{dtype}>.filled(2,3,{value}){view}.m;0.read(m).v;'
            source+=('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();')+'23.return;}'
            rows.append((f'{dtype}-function-parameter-{transposed}',source,23,dict(kinds=[4 if dtype=='Int' else 2],text=(str(6*value) if dtype=='Int' else f'{6*value:.2f}').encode())))
        zero='0' if dtype=='Int' else '0.0';one='1' if dtype=='Int' else '1.0'
        source=f'(Matrix<{dtype}>.x)copy(){{x.return;}}start(){{Matrix<{dtype}>.filled(2,2,{one}).m;m.copy().a;Matrix<{dtype}>.zeros(2,2).z;z.matmulInto(z,m);(a.sum()=={4 if dtype=="Int" else 4.0}).console();(m.sum()=={zero}).console();23.return;}}'
        rows.append((dtype+'-function-copy-independent',source,23,dict(kinds=[5,5],text=b'truetrue')))
        source=f'(Int.x)choose(){{if(x>0){{Matrix<{dtype}>.zeros(2,3).return;}}else{{Matrix<{dtype}>.zeros(3,2).return;}}}}start(){{7.choose().a;(-1).choose().b;a.rows().console();b.rows().console();23.return;}}'
        rows.append((dtype+'-function-branch-return',source,23,dict(kinds=[4,4],text=b'23')))
        source=f'(Matrix<{dtype}>.x)copy(){{x.return;}}(Matrix<{dtype}>.x)forward(){{x.copy().return;}}start(){{Matrix<{dtype}>.zeros(2,3).m;m.forward().a;a.columns().console();23.return;}}'
        rows.append((dtype+'-function-forward-result',source,23,dict(kinds=[4],text=b'3')))
        source=f'(Int.x)empty(){{Matrix<{dtype}>.zeros(0,3).return;}}start(){{0.empty().a;a.rows().console();a.columns().console();23.return;}}'
        rows.append((dtype+'-function-empty-return',source,23,dict(kinds=[4,4],text=b'03')))
    source='(Int.x)make(Int.a,Float.b,Matrix<Int>.m,Int.c,Int.d){Matrix<Int>.filled(1,1,x+a+b.floor()+m.sum()+c+d).return;}start(){7.make(11,1.5,Matrix<Int>.filled(2,2,13),17,19).out;out.at(0,0).console();23.return;}'
    rows.append(('function-six-source-arguments',source,23,dict(kinds=[4],text=b'107')))
    source='(Int.x)mark(){x.console();x.return;}(Int.x)make(Int.a,Int.b,Int.c,Int.d,Int.e){Matrix<Int>.filled(1,1,x+a+b+c+d+e).return;}start(){7.mark().make(11.mark(),13.mark(),17.mark(),19.mark(),Matrix<Int>.filled(1,1,23.mark()).sum()).out;out.sum().console();23.return;}'
    rows.append(('function-sret-effect-order',source,23,dict(kinds=[4]*7,text=b'7111317192390')))
    for dtype,value in [('Int','7'),('Float','1.5')]:
        source=f'({dtype}.x)make(){{Matrix<{dtype}>.filled(2,3,x).return;}}start(){{0.i.mutable;0.total.mutable;while(i<10000){{({value}).make().rows().r;total=total+r;i=i+1;}}total.console();23.return;}}'
        rows.append((dtype+'-function-loop-temporaries',source,23,dict(kinds=[4],text=b'20000',stack_bytes=1048576)))
        source=f'(Matrix<{dtype}>.x)copy(){{x.contiguous().return;}}start(){{Matrix<{dtype}>.zeros(2,3).m;m.copy().a;a.columns().console();23.return;}}'
        rows.append((dtype+'-function-copy-borrow-owned',source,23,dict(kinds=[4],text=b'3')))
    return rows

def decomposition_cases():
    # Rational elimination is independent of the runtime's binary64 workspace.
    from fractions import Fraction
    rows=[]
    def add(name,body,text,kinds,returned=23):
        rows.append((name,'start(){'+body+f'{returned}.return;}}',returned,dict(kinds=kinds,text=text.encode())))
    matrices=[[[2,1],[4,3]],[[0,2,1],[1,1,0],[2,0,3]],
              [[7,2,1],[2,9,3],[1,3,11]],[[17]],
              [[1,2,3],[2,7,5],[4,9,13]]]
    for changed,original in enumerate(matrices):
        for transposed in (False,True):
            values=list(map(list,zip(*original))) if transposed else original
            n=len(values);lu=[[Fraction(x) for x in row] for row in values];pivots=list(range(n))
            for k in range(n):
                pivot=max(range(k,n),key=lambda i:abs(lu[i][k]))
                assert lu[pivot][k]
                lu[k],lu[pivot]=lu[pivot],lu[k];pivots[k],pivots[pivot]=pivots[pivot],pivots[k]
                for i in range(k+1,n):
                    lu[i][k]/=lu[k][k]
                    for j in range(k+1,n):lu[i][j]-=lu[i][k]*lu[k][j]
            view='.transposeView()' if transposed else ''
            prefix=f'Matrix<Float>.fromRows({[[float(x) for x in row] for row in original]}){view}.a;a.lu().d;d.0.f;d.at(1).p;'
            body=prefix;wanted='';kinds=[]
            for i in range(n):
                body+=f'p.at({i}).console();';wanted+=str(pivots[i]);kinds.append(4)
                for j in range(n):
                    body+=f'"${{f.at({i},{j}):fixed(6)}}".console();'
                    wanted+=f'{float(lu[i][j]):.6f}';kinds.append(2)
            add(f'lu-factors-{changed}-{transposed}',body,wanted,kinds)
            lower='['+','.join('['+','.join('1.0' if i==j else '0.0' if i<j else f'f.at({i},{j})' for j in range(n))+']' for i in range(n))+']'
            upper='['+','.join('['+','.join('0.0' if i>j else f'f.at({i},{j})' for j in range(n))+']' for i in range(n))+']'
            body=prefix+f'Matrix<Float>.fromRows({lower}).l;Matrix<Float>.fromRows({upper}).u;l.matmul(u).reconstructed;'
            wanted='';kinds=[]
            for i in range(n):
                for j in range(n):
                    body+=f'"${{reconstructed.at({i},{j}):fixed(6)}}".console();'
                    wanted+=f'{values[pivots[i]][j]:.6f}';kinds.append(2)
            add(f'lu-reconstruct-{changed}-{transposed}',body,wanted,kinds)
    matrices=[[[1.0,1.0],[1.0,-1.0],[1.0,1.0]],
              [[2.0,3.0],[5.0,7.0],[11.0,13.0]],
              [[3.0]],[[1.0,0.0,0.0],[0.0,1.0,0.0],[0.0,0.0,1.0]],
              [[4.0,1.0],[1.0,3.0]]]
    for changed,values in enumerate(matrices):
        n=len(values);m=len(values[0])
        for view in (False,True):
            source_values=list(map(list,zip(*values))) if view else values
            prefix=f'Matrix<Float>.fromRows({source_values})'+('.transposeView()' if view else '')+'.a;a.qr().d;d.at(0).q;d.1.r;'
            body=prefix+'q.matmul(r).reconstructed;q.transposeView().matmul(q).gram;'
            wanted='';kinds=[]
            for i in range(n):
                for j in range(m):
                    body+=f'"${{reconstructed.at({i},{j}):fixed(6)}}".console();'
                    wanted+=f'{values[i][j]:.6f}';kinds.append(2)
            for i in range(m):
                for j in range(m):
                    # Compare residual magnitude with a fixed independent bound;
                    # the sign of a tiny rounded zero is not the invariant.
                    wanted_value='1.0' if i==j else '0.0'
                    body+=f'((gram.at({i},{j})-{wanted_value})<0.00000001 && (gram.at({i},{j})-{wanted_value})>(-0.00000001)).console();'
                    wanted+='true';kinds.append(5)
            add(f'qr-reconstruct-{changed}-{view}',body,wanted,kinds)
    for returned in (0,7,23,29,255):
        add('lu-return-'+str(returned),'Matrix<Float>.fromRows([[2.0,1.0],[4.0,3.0]]).a;a.lu().d;d.1.at(0).console();','1',[4],returned)
        add('qr-return-'+str(returned),'Matrix<Float>.fromRows([[1.0,0.0],[0.0,1.0]]).a;a.qr().d;d.0.rows().console();','2',[4],returned)
    for method in ('lu','qr'):
        add(method+'-length',f'Matrix<Float>.fromRows([[2.0,1.0],[4.0,3.0]]).a;a.{method}().length().console();','2',[4])
        add(method+'-two-live',f'Matrix<Float>.fromRows([[2.0,1.0],[4.0,3.0]]).a;Matrix<Float>.fromRows([[7.0,0.0],[0.0,11.0]]).b;a.{method}().x;b.{method}().y;x.0.rows().console();y.1.at(0).console();' if method=='lu' else 'Matrix<Float>.fromRows([[1.0,0.0],[0.0,1.0]]).a;Matrix<Float>.fromRows([[1.0],[2.0],[3.0]]).b;a.qr().x;b.qr().y;x.0.rows().console();y.0.rows().console();','20' if method=='lu' else '23',[4,4])
        for name,value in [('empty','Matrix<Float>.zeros(0,0)'),('too-large','Matrix<Float>.zeros(33,33)'),('singular','Matrix<Float>.fromRows([[1.0,2.0],[2.0,4.0]])'),('wide','Matrix<Float>.filled(1,2,1.0)'),('infinite','Matrix<Float>.filled(1,1,∞)'),('nan','Matrix<Float>.filled(1,1,∞-∞)')]:
            rows.append((method+'-decomposition-'+name,'start(){'+value+f'.a;a.{method}();23.return;}}',177,{}))
        identity=[[1.0 if i==j else 0.0 for j in range(32)] for i in range(32)]
        body=f'Matrix<Float>.fromRows({identity}).a;a.{method}().d;'
        expression='d.0.trace()' if method=='lu' else 'd.0.matmul(d.1).trace()'
        add(method+'-boundary-32',body+'"${'+expression+':fixed(2)}".console();','32.00',[2])
        huge=str(10**308)+'.0'
        source=f'start(){{Matrix<Float>.fromRows([[{huge},{huge}],[(-{huge}),{huge}]]).a;a.{method}();23.return;}}'
        rows.append((method+'-finite-overflow',source,177,{}))
    return rows

def cases():
    rows=[]
    def add(name,body,text,kind=4,returned=23):
        rows.append((name,'start(){'+body+f'{returned}.return;}}',returned,dict(kinds=[kind],text=str(text).encode())))
    for dtype,fill in [('Int','17'),('Float','1.5')]:
        shapes=[(0,0),(0,3),(3,0),(1,1),(2,3),(8,8)]
        if dtype=='Float':shapes.append((64,64))
        for r,c in shapes:
            for constructor in ('zeros','filled'):
                args=f'{r},{c}'+(','+fill if constructor=='filled' else '')
                prefix=f'Matrix<{dtype}>.{constructor}({args}).m;'
                for method,value,kind in [('rows',r,4),('columns',c,4),('layout',1,4),('isSquare',str(r==c).lower(),5)]:
                    add(f'{dtype}-{constructor}-{r}-{c}-{method}',prefix+f'm.{method}().console();',value,kind)
                if r and c:
                    value=float(fill) if constructor=='filled' else 0
                    body=prefix+f'm.at({r-1},{c-1}).v;'
                    if dtype=='Float':add(f'{dtype}-{constructor}-{r}-{c}-at',body+'"${v:fixed(2)}".console();',f'{value:.2f}',2)
                    else:add(f'{dtype}-{constructor}-{r}-{c}-at',body+'v.console();',int(value))
        for value in ('29' if dtype=='Int' else '2.75','-31' if dtype=='Int' else '-7.25'):
            prefix=f'Matrix<{dtype}>.filled(2,2,{value}).m;'
            body=prefix+'m.trace().t;'
            if dtype=='Float':add(f'{dtype}-trace-{value}',body+'"${t:fixed(2)}".console();',f'{2*float(value):.2f}',2)
            else:add(f'{dtype}-trace-{value}',body+'t.console();',2*int(value))
    add('two-live','Matrix<Int>.filled(2,3,17).a;Matrix<Int>.filled(3,2,29).b;(a.at(1,2)+b.at(2,1)).console();',46)
    add('bytes-slice-composition','Bytes.fromValues(17,29,43,71).bytes;bytes.slice(1,3).part;Matrix<Int>.filled(1,1,7).m;(part.at(1)+m.at(0,0)).console();',50)
    rows.append(('unused-float-effect','start(){Array<Int,1> [17].owner;Matrix<Float>.filled(1,1,1.0).m;m.divideElements(Matrix<Float>.zeros(1,1)).unused;23.return;}',177,{}))
    add('dynamic-shape','2.r;3.c;Matrix<Int>.filled(r,c,43).m;m.at(r-1,c-1).console();',43)
    for mutable in (False,True):
        for delta in (0,17):
            values=[v+delta for v in [17,29,43,71,83,97]]
            for explicit in (False,True):
                prefix=f'Array<Int,6> {values}.owner'+('.mutable' if mutable else '')+';owner.asSlice().values;'
                prefix+='Matrix<Int>.fromBuffer(values,2,3'+(',rowMajor' if explicit else '')+').m;'
                add(f'fromBuffer-{mutable}-{delta}-{explicit}',prefix+'m.at(1,2).console();',values[-1])
                add(f'fromBuffer-sum-{mutable}-{delta}-{explicit}',prefix+'m.sum().console();',sum(values))
    prefix='Array<Int,6> [17,29,43,71,83,97].owner.mutable;owner.asSlice().s;'
    add('fromBuffer-copy-independent',prefix+'Matrix<Int>.fromBuffer(s,2,3,rowMajor).a;Random.seed(17).r;r.shuffle(s);a.at(0,0).console();',17)
    add('fromBuffer-two-live',prefix+'Matrix<Int>.fromBuffer(s,2,3).a;Matrix<Int>.fromBuffer(s,3,2).b;(a.at(1,2)+b.at(2,1)).console();',194)
    add('fromBuffer-after-source-release',prefix+'Matrix<Int>.fromBuffer(s,2,3).a;s.release();a.at(1,2).console();',97)
    add('fromBuffer-empty','Array<Int,0> [].a;a.asSlice().s;Matrix<Int>.fromBuffer(s,0,3,rowMajor).m;m.sum().console();',0)
    for dtype in ('Int','Float'):
        for delta in (0,17):
            values=[v+delta for v in [17,29,43,71,83,97]]
            if dtype=='Float':values=[v/4 for v in values]
            prefix=f'Vector<{dtype},6> {values}.buffer;Matrix<{dtype}>.fromBuffer(buffer,2,3,rowMajor).m;'
            add(f'{dtype}-fromBuffer-vector-{delta}',prefix+'m.at(1,2).v;'+('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();'),values[-1] if dtype=='Int' else f'{values[-1]:.2f}',4 if dtype=='Int' else 2)
            prefix+='m.scale('+('3' if dtype=='Int' else '3.0')+').other;buffer.at(0).v;'
            add(f'{dtype}-fromBuffer-vector-input-{delta}',prefix+('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();'),values[0] if dtype=='Int' else f'{values[0]:.2f}',4 if dtype=='Int' else 2)
        values=[i+1 for i in range(64)]
        if dtype=='Float':values=[v/4 for v in values]
        prefix=f'Vector<{dtype},64> {values}.buffer;Matrix<{dtype}>.fromBuffer(buffer,8,8).m;m.sum().v;'
        add(dtype+'-fromBuffer-vector-limit',prefix+('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();'),sum(values) if dtype=='Int' else f'{sum(values):.2f}',4 if dtype=='Int' else 2)
    prefix='Array<Int,6> [17,29,43,71,83,97].owner.mutable;owner.asSlice().s;'
    for returned in (0,7,23,29,255):
        add(f'fromBuffer-return-{returned}',prefix+'Matrix<Int>.fromBuffer(s,2,3).m;m.sum().console();',340,returned=returned)
    for name,r,c in [('short',3,3),('long',1,2),('negative',-1,6),('overflow',9223372036854775807,2)]:
        rows.append(('fromBuffer-'+name,'start(){'+prefix+f'Matrix<Int>.fromBuffer(s,{r},{c}).m;23.return;}}',177,{}))
    for dtype,values in [('Int',[[17,29,43],[71,83,97]]),('Float',[[1.5,2.5,3.5],[4.5,5.5,6.5]])]:
        for view in ('','transposeView().','column(1).','row(1).'):
            expected=values[1] if view.startswith('row') else [r[1] for r in values] if view.startswith('column') else sum(values,[])
            body=f'Matrix<{dtype}>.fromRows({values}).m;m.'+view+'sum().v;'
            add(dtype+'-sum-'+view.replace('().','').replace('(1).',''),body+('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();'),sum(expected) if dtype=='Int' else f'{sum(expected):.2f}',4 if dtype=='Int' else 2)
    rows.append(('sum-overflow','start(){Matrix<Int>.filled(1,2,9223372036854775807).m;m.sum();23.return;}',172,{}))
    for dtype in ('Int','Float'):
        values=[[17,29,43],[71,83,97],[101,103,107]]
        if dtype=='Float':values=[[v/4 for v in row] for row in values]
        for name,args in [('scalar','1,2,1,2'),('half-open','1…<3,1…<3'),('inclusive','1…2,1…2'),('exclusive-start','0<…2,0<…2'),('exclusive','0<…<3,0<…<3')]:
            body=f'Matrix<{dtype}>.fromRows({values}).m;m.slice({args}).v;v.at(1,1).x;'
            expected=values[2][2]
            add(f'{dtype}-slice-{name}',body+('x.console();' if dtype=='Int' else '"${x:fixed(2)}".console();'),expected if dtype=='Int' else f'{expected:.2f}',4 if dtype=='Int' else 2)
        body=f'Matrix<{dtype}>.fromRows({values}).m;m.transposeView().slice(0,2,1,2).v;v.contiguous().c;c.at(1,1).x;'
        expected=values[2][1]
        add(dtype+'-slice-transpose-copy',body+('x.console();' if dtype=='Int' else '"${x:fixed(2)}".console();'),expected if dtype=='Int' else f'{expected:.2f}',4 if dtype=='Int' else 2)
        add(dtype+'-slice-empty',f'Matrix<{dtype}>.zeros(2,3).m;m.slice(2,0,3,0).v;v.rows().console();',0)
        for args in ('0,3,0,1','0,1,0,4','-1,1,0,1','0,1,-1,1','1…<0,0…<1'):
            rows.append((re.sub(r'[^A-Za-z0-9_.-]+','-',dtype+'-slice-bounds-'+args),'start(){'+f'Matrix<{dtype}>.zeros(2,3).m;m.slice({args});23.return;}}',177,{}))
    for delta in (0,3):
        a=[[4.0+delta,1.0],[1.0,3.0+delta]];det=a[0][0]*a[1][1]-1.0
        prefix=f'Matrix<Float>.fromRows({a}).a;'
        add(f'determinant-{delta}',prefix+'a.determinant().v;"${v:fixed(3)}".console();',f'{det:.3f}',2)
        inverse=[[a[1][1]/det,-1.0/det],[-1.0/det,a[0][0]/det]]
        for i in range(2):
            for j in range(2):
                add(f'inverse-{delta}-{i}-{j}',prefix+f'a.inverse().b;b.at({i},{j}).v;"${{v:fixed(6)}}".console();',f'{inverse[i][j]:.6f}',2)
        one_norm=max(sum(abs(a[i][j]) for i in range(2)) for j in range(2))
        inverse_norm=max(sum(abs(inverse[i][j]) for i in range(2)) for j in range(2))
        add(f'condition-{delta}',prefix+'a.conditionEstimate().v;"${v:fixed(6)}".console();',f'{one_norm*inverse_norm:.6f}',2)
        add(f'inverse-compose-{delta}',prefix+'a.inverse().b;a.matmul(b).c;c.trace().v;"${v:fixed(3)}".console();','2.000',2)
        add(f'algebra-preserves-input-{delta}',prefix+'a.inverse().b;a.at(0,0).v;"${v:fixed(2)}".console();',f'{a[0][0]:.2f}',2)
    for name,values,expected in [('identity',[[1.0,0.0],[0.0,1.0]],[[1.0,0.0],[0.0,1.0]]),('spd',[[4.0,2.0],[2.0,10.0]],[[2.0,0.0],[1.0,3.0]])]:
        prefix=f'Matrix<Float>.fromRows({values}).a;a.cholesky().b;'
        for i in range(2):
            for j in range(2):
                add(f'cholesky-{name}-{i}-{j}',prefix+f'b.at({i},{j}).v;"${{v:fixed(3)}}".console();',f'{expected[i][j]:.3f}',2)
    add('dotFlattened','Matrix<Float>.fromRows([[1.0,2.0],[3.0,4.0]]).a;Matrix<Float>.fromRows([[5.0,6.0],[7.0,8.0]]).b;a.dotFlattened(b).v;"${v:fixed(2)}".console();','70.00',2)
    add('dotFlattened-strided','Matrix<Float>.fromRows([[1.0,2.0],[3.0,4.0]]).a;a.transposeView().v;a.dotFlattened(v).x;"${x:fixed(2)}".console();','29.00',2)
    for method in ('determinant','inverse','conditionEstimate','cholesky'):
        for name,values in [('singular',[[1.0,1.0],[1.0,1.0]]),('nonsquare',[[1.0,2.0]]),('empty',[])]:
            rows.append((method+'-'+name,f'start(){{Matrix<Float>.fromRows({values}).m;m.{method}();23.return;}}',177,{}))
    rows.append(('cholesky-non-spd','start(){Matrix<Float>.fromRows([[1.0,2.0],[2.0,1.0]]).m;m.cholesky();23.return;}',177,{}))
    rows.append(('cholesky-nonsymmetric','start(){Matrix<Float>.fromRows([[4.0,9.0],[2.0,10.0]]).m;m.cholesky();23.return;}',177,{}))
    for method in ('determinant','inverse','conditionEstimate','cholesky'):
        for name,value in [('infinity','∞'),('negative-infinity','(-∞)'),('nan','(∞-∞)')]:
            rows.append((method+'-'+name,'start(){Matrix<Float>.filled(1,1,'+value+').m;m.'+method+'();23.return;}',177,{}))
    for dtype,values in [('Int',[[17,29,43],[71,83,97]]),('Float',[[1.5,2.5,3.5],[4.5,5.5,6.5]])]:
        literal=str(values).replace(' ','')
        prefix=f'Matrix<{dtype}>.fromRows({literal}).m;'
        transpose=[list(x) for x in zip(*values)]
        transforms=[('original','m',values),('transpose','m.transposeView()',transpose),
                    ('row','m.row(1)',[values[1]]),('column','m.column(2)',[[r[2]] for r in values]),
                    ('contiguous','m.transposeView().contiguous()',transpose)]
        for name,expression,expected in transforms:
            body=prefix+expression+'.v;' if name!='original' else prefix.replace('.m;','.v;')
            parts=[];texts=[]
            for i,row in enumerate(expected):
                for j,value in enumerate(row):
                    key=f'v{i}_{j}';body+=f'v.at({i},{j}).{key};'
                    parts.append('${'+key+(':fixed(2)' if dtype=='Float' else '')+'}')
                    texts.append(f'{value:.2f}' if dtype=='Float' else str(value))
            add(f'{dtype}-fromRows-{name}',body+'"'+'/'.join(parts)+'".console();','/'.join(texts),2)
        for rows_literal,r,c in [('[]',0,0),('[[]]',1,0),('[[],[]]',2,0)]:
            body=f'Matrix<{dtype}>.fromRows({rows_literal}).m;m.rows().r;m.columns().c;"${{r}}/${{c}}".console();'
            add(f'{dtype}-fromRows-empty-{r}',body,f'{r}/{c}',2)
    source='(Int.value)cell(){value.console();value.return;}start(){Matrix<Int>.fromRows([[17.cell(),29.cell()]]).m;m.at(0,1).console();23.return;}'
    rows.append(('fromRows-effects-once',source,23,dict(kinds=[4,4,4],text=b'172929',publications=3)))
    source='(Int.value)cell(){Matrix<Int>.filled(2,3,value).m;m.at(1,2).return;}start(){29.cell().console();23.return;}'
    rows.append(('ordinary-function-local',source,23,dict(kinds=[4],text=b'29')))
    for dtype in ('Int','Float'):
        for delta in (0,17):
            a=[[1+delta,2+delta],[3+delta,4+delta]];b=[[5,6],[7,8]]
            if dtype=='Float':
                a=[[float(x) for x in r] for r in a];b=[[float(x) for x in r] for r in b]
            prefix=f'Matrix<{dtype}>.fromRows({a}).a;Matrix<{dtype}>.fromRows({b}).b;'
            operations=[('add(b)',[[a[i][j]+b[i][j] for j in range(2)] for i in range(2)]),
                        ('subtract(b)',[[a[i][j]-b[i][j] for j in range(2)] for i in range(2)]),
                        ('multiplyElements(b)',[[a[i][j]*b[i][j] for j in range(2)] for i in range(2)]),
                        ('scale('+('3' if dtype=='Int' else '3.0')+')',[[x*3 for x in r] for r in a]),
                        ('matmul(b)',[[sum(a[i][k]*b[k][j] for k in range(2)) for j in range(2)] for i in range(2)])]
            if dtype=='Float':
                operations += [('divideElements(b)',[[a[i][j]/b[i][j] for j in range(2)] for i in range(2)]),
                               ('clamp(1.5,3.5)',[[min(max(x,1.5),3.5) for x in r] for r in a])]
            for call,expected in operations:
                body=prefix+'a.'+call+'.v;';parts=[];texts=[]
                for i,row in enumerate(expected):
                    for j,value in enumerate(row):
                        key=f'v{i}_{j}';body+=f'v.at({i},{j}).{key};'
                        parts.append('${'+key+(':fixed(3)' if dtype=='Float' else '')+'}')
                        texts.append(f'{value:.3f}' if dtype=='Float' else str(value))
                add(f'{dtype}-{call.split("(")[0]}-{delta}',body+'"'+'/'.join(parts)+'".console();','/'.join(texts),2)
    add('operation-preserves-input','Matrix<Int>.fromRows([[17,29],[43,71]]).a;a.scale(3).b;a.at(1,1).console();',71)
    add('matmul-rectangular','Matrix<Int>.fromRows([[1,2,3],[4,5,6]]).a;Matrix<Int>.fromRows([[7,8],[9,10],[11,12]]).b;a.matmul(b).c;c.at(1,1).console();',154)
    rows.append(('checked-overflow','start(){Matrix<Int>.filled(1,1,9223372036854775807).a;a.scale(2);23.return;}',172,{}))
    for dtype,value,fallback in [('Int','17','29'),('Float','1.5','2.75')]:
        prefix=f'Matrix<{dtype}>.filled(2,3,{value}).m;'
        for r,c,present in [(1,2,True),(0,0,True),(2,0,False),(0,3,False),(-1,0,False)]:
            body=prefix+f'm.get({r},{c}).o;'
            add(f'{dtype}-get-some-{r}-{c}',body+'o.isSome().console();',str(present).lower(),5)
            add(f'{dtype}-get-none-{r}-{c}',body+'o.isNone().console();',str(not present).lower(),5)
            body+=f'o.unwrapOr({fallback}).v;'
            expected=value if present else fallback
            if dtype=='Float':add(f'{dtype}-get-value-{r}-{c}',body+'"${v:fixed(2)}".console();',f'{float(expected):.2f}',2)
            else:add(f'{dtype}-get-value-{r}-{c}',body+'v.console();',expected)
        body=prefix+'m.get(1,2).a;m.get(7,9).b;a.expect("present").v;'
        if dtype=='Float':add('Float-get-two-live',body+'"${v:fixed(2)}".console();','1.50',2)
        else:add('Int-get-two-live',body+'v.console();',17)
        rows.append((dtype+'-get-expect-none','start(){'+prefix+'m.get(9,9).expect("absent");23.return;}',177,{}))
    add('Float-get-native-composition','Matrix<Float>.filled(1,1,7.75).m;m.get(0,0).unwrapOr(1.0).round(nearestEven).v;"${v:fixed(2)}".console();','8.00',2)
    for dtype in ('Int','Float'):
        for r,c in ((0,0),(0,3),(3,0)):
            for copy in (False,True):
                body=f'Matrix<{dtype}>.zeros({r},{c}).m;m.transposeView()'+('.contiguous()' if copy else '')+'.v;v.rows().r;v.columns().c;"${r}/${c}".console();'
                add(f'{dtype}-empty-transpose-{r}-{c}-{copy}',body,f'{c}/{r}',2)
    for dtype,n in [('Int',8),('Float',64)]:
        values=[[i*n+j+1 for j in range(n)] for i in range(n)]
        if dtype=='Float':values=[[float(v) for v in row] for row in values]
        body=f'Matrix<{dtype}>.fromRows({values}).m;m.at({n-1},{n-1}).v;'
        add(dtype+'-fromRows-boundary',body+('v.console();' if dtype=='Int' else '"${v:fixed(2)}".console();'),str(n*n) if dtype=='Int' else f'{n*n:.2f}',4 if dtype=='Int' else 2)
    for returned in (0,7,23,29,255):
        add(f'return-{returned}','Matrix<Int>.filled(2,3,71).m;m.at(1,2).console();',71,returned=returned)
    for name,body in [('row-bounds','Matrix<Int>.zeros(2,3).m;m.at(2,0);'),
                      ('column-bounds','Matrix<Float>.zeros(2,3).m;m.at(0,3);'),
                      ('negative-index','Matrix<Int>.zeros(2,3).m;m.at(-1,0);'),
                      ('empty-access','Matrix<Int>.zeros(0,0).m;m.at(0,0);'),
                      ('int-shape-limit','Matrix<Int>.zeros(9,1).m;'),
                      ('float-shape-limit','Matrix<Float>.zeros(65,1).m;'),
                      ('negative-shape','Matrix<Int>.zeros(-1,1).m;'),
                      ('nonsquare-trace','Matrix<Float>.zeros(2,3).m;m.trace();')]:
        rows.append((name,'start(){'+body+'23.return;}',177,{}))
    for dtype in ('Int','Float'):
        for method in ('add','subtract','multiplyElements','matmul'):
            source=f'start(){{Matrix<{dtype}>.zeros(2,3).a;Matrix<{dtype}>.zeros(2,2).b;a.{method}(b);23.return;}}'
            rows.append((dtype+'-shape-mismatch-'+method,source,177,{}))
    rows.append(('divide-zero','start(){Matrix<Float>.filled(2,3,1.0).a;Matrix<Float>.zeros(2,3).b;a.divideElements(b);23.return;}',177,{}))
    for dtype in ('Int','Float'):
        for factor in (2,3):
            values=[[1,3],[7,11]]
            if dtype=='Float':values=[[x/4 for x in r] for r in values]
            scale=str(factor)+('.0' if dtype=='Float' else '')
            declaration=f'({dtype}.x)transform(){{(x*{scale}).return;}}'
            for view in ('','transposeView().'):
                for returned in (7,23,255):
                    prefix=f'Matrix<{dtype}>.fromRows({values}).m;m.'+view+'map(transform).out;'
                    value=values[0][1] if view else values[1][0]
                    body=prefix+'out.at(1,0).v;'+('v.console();' if dtype=='Int' else '"${v:fixed(3)}".console();')
                    text=str(value*factor) if dtype=='Int' else f'{value*factor:.3f}'
                    rows.append((f'{dtype}-map-{factor}-{bool(view)}-{returned}',declaration+'start(){'+body+f'{returned}.return;}}',returned,dict(kinds=[4 if dtype=='Int' else 2],text=text.encode())))
            source=declaration+'start(){'+f'Matrix<{dtype}>.fromRows({values}).m;m.map(transform).a;a.map(transform).b;m.at(1,0).x;a.at(1,0).y;b.at(1,0).z;'
            spec=':fixed(3)' if dtype=='Float' else ''
            source+='"${x'+spec+'}/${y'+spec+'}/${z'+spec+'}".console();23.return;}'
            expected=[values[1][0]*factor**power for power in range(3)]
            text='/'.join(f'{x:.3f}' if dtype=='Float' else str(x) for x in expected)
            rows.append((f'{dtype}-map-two-live-{factor}',source,23,dict(kinds=[2],text=text.encode())))
        if dtype=='Float':effect='"${x:fixed(2)}".console();';values='[[1.5,2.5],[3.5,4.5]]';text=b'1.502.503.504.50';kinds=[2]*4
        else:effect='x.console();';values='[[17,29],[43,71]]';text=b'17294371';kinds=[4]*4
        declaration=f'({dtype}.x)observe(){{'+effect+'x.return;}'
        rows.append((dtype+'-map-effects-once',declaration+'start(){Matrix<'+dtype+'>.fromRows('+values+').m;m.map(observe).out;23.return;}',23,dict(kinds=kinds,text=text,publications=4)))
        rows.append((dtype+'-map-empty-effects',declaration+'start(){Matrix<'+dtype+'>.zeros(0,3).m;m.map(observe).out;out.rows().console();23.return;}',23,dict(kinds=[4],text=b'0')))
        declaration=f'({dtype}.x)identity(){{x.return;}}'
        source=declaration+'start(){Matrix<'+dtype+'>.fromRows('+values+').m;"${m.map(identity).rows()}".console();23.return;}'
        rows.append((dtype+'-map-pure-interpolation',source,23,dict(kinds=[2],text=b'2')))
    rows.append(('map-checked-overflow','(Int.x)twice(){(x*2).return;}start(){Matrix<Int>.filled(1,1,9223372036854775807).m;m.map(twice);23.return;}',172,{}))
    for dtype in ('Int','Float'):
        for changed in (0,13):
            values=[[1+changed,3+changed,7+changed],[11+changed,17+changed,23+changed]]
            if dtype=='Float':values=[[x/4 for x in r] for r in values]
            for view in (False,True):
                logical=[list(x) for x in zip(*values)] if view else values
                prefix=f'Matrix<{dtype}>.fromRows({values}).m;'+('m.transposeView().a;' if view else 'm.a;')
                for axis in (0,1):
                    groups=[list(x) for x in zip(*logical)] if axis==0 else logical
                    for method,fn in [('sum',sum),('mean',statistics.mean),('min',min),('max',max)]:
                        expected=[fn(g) for g in groups];floating=dtype=='Float' or method=='mean'
                        body=prefix+f'{axis}.axis;a.{method}(axis).v;'
                        for i,value in enumerate(expected):
                            tail=f'v.at({i}).x;'+('"${x:fixed(3)}".console();' if floating else 'x.console();')
                            add(f'{dtype}-axis-{method}-{changed}-{view}-{axis}-{i}',body+tail,f'{value:.3f}' if floating else value,2 if floating else 4)
                # Dynamic shape survives Vector methods and a return to Matrix.
                expected=[sum(r) for r in logical]
                body=prefix+'a.sum(1).v;v.scale('+('2' if dtype=='Int' else '2.0')+').w;w.add(v).combined;'
                value=expected[0]*3
                add(f'{dtype}-axis-vector-compose-{changed}-{view}',body+'combined.at(0).x;'+('x.console();' if dtype=='Int' else '"${x:fixed(3)}".console();'),value if dtype=='Int' else f'{value:.3f}',4 if dtype=='Int' else 2)
                body=prefix+'a.sum(1).v;Matrix<'+dtype+f'>.fromBuffer(v,1,{len(expected)}).b;b.at(0,0).x;'
                add(f'{dtype}-axis-fromBuffer-{changed}-{view}',body+('x.console();' if dtype=='Int' else '"${x:fixed(3)}".console();'),expected[0] if dtype=='Int' else f'{expected[0]:.3f}',4 if dtype=='Int' else 2)
        for axis in (0,1):
            for method in ('sum','mean','min','max'):
                rows.append((f'{dtype}-axis-invalid-{method}-{axis}',f'start(){{Matrix<{dtype}>.zeros(2,3).m;m.{method}({axis+2});23.return;}}',177,{}))
            shape=(0,3) if axis==0 else (3,0)
            prefix=f'Matrix<{dtype}>.zeros({shape[0]},{shape[1]}).m;'
            add(f'{dtype}-axis-empty-sum-{axis}',prefix+f'm.sum({axis}).v;v.at(2).x;'+('x.console();' if dtype=='Int' else '"${x:fixed(2)}".console();'),0 if dtype=='Int' else '0.00',4 if dtype=='Int' else 2)
            for method in ('mean','min','max'):
                rows.append((f'{dtype}-axis-empty-{method}-{axis}','start(){'+prefix+f'm.{method}({axis});23.return;}}',177,{}))
        for method in ('add','dot','correlation'):
            for swapped in (False,True):
                prefix=f'Matrix<{dtype}>.zeros(2,3).m;m.sum(0).a;Vector<{dtype},2>.filled('+('1' if dtype=='Int' else '1.0')+').b;'
                body=('b.'+method+'(a)' if swapped else 'a.'+method+'(b)')
                rows.append((f'{dtype}-axis-vector-mismatch-{method}-{swapped}','start(){'+prefix+body+';23.return;}',177,{}))
    rows.append(('Int-axis-overflow','start(){Matrix<Int>.filled(2,1,9223372036854775807).m;m.sum(0);23.return;}',172,{}))
    prefix='Matrix<Float>.fromRows([[1.0,3.0,7.0],[2.0,4.0,8.0]]).m;m.sum(0).v;'
    vals=[3.0,7.0,15.0]
    for name,call,value in [('sum','sum()',sum(vals)),('mean','mean()',statistics.mean(vals)),('variance','variance(sample)',statistics.variance(vals)),('stddev','standardDeviation(population)',statistics.pstdev(vals)),('median','median()',statistics.median(vals)),('quantile','quantile(0.25,linearType7)',5.0),('norm','norm()',math.sqrt(sum(x*x for x in vals))),('dot','dot(v)',sum(x*x for x in vals)),('correlation','correlation(v)',1.0)]:
        add('axis-vector-'+name,prefix+'v.'+call+'.x;"${x:fixed(6)}".console();',f'{value:.6f}',2)
    add('axis-vector-normalize',prefix+'v.normalize().n;n.norm().x;"${x:fixed(6)}".console();','1.000000',2)
    add('axis-random-categorical','Matrix<Float>.fromRows([[0.0,1.0,0.0]]).m;m.sum(0).w;Random.seed(17).r;r.categorical(w).console();',1)
    from random_test import SplitMix
    sampled=SplitMix(17).sample([17,29,43],2)
    add('axis-random-sample','Matrix<Int>.fromRows([[17,29,43]]).m;m.sum(0).v;Random.seed(17).r;r.sample(v,2).s;s.at(0).console();',sampled[0])
    for dtype in ('Int','Float'):
        for changed in (0,11):
            values=[[1+changed,3+changed,7+changed],[11+changed,17+changed,23+changed]]
            if dtype=='Float':values=[[x/4 for x in r] for r in values]
            for transposed in (False,True):
                logical=[list(x) for x in zip(*values)] if transposed else values
                vector=[17,29,43][:len(logical[0])]
                if dtype=='Float':vector=[x/4 for x in vector]
                wanted=[sum(x*y for x,y in zip(row,vector)) for row in logical]
                for dynamic in (False,True):
                    prefix=f'Matrix<{dtype}>.fromRows({values}).m;'+('m.transposeView().a;' if transposed else 'm.a;')
                    prefix+=(f'Matrix<{dtype}>.fromRows([{vector}]).vm;vm.sum(0).v;' if dynamic else f'Vector<{dtype}> {vector}.v;')
                    for index,value in enumerate(wanted):
                        body=prefix+f'a.matvec(v).r;r.at({index}).x;'
                        add(f'{dtype}-matvec-{changed}-{transposed}-{dynamic}-{index}',body+('x.console();' if dtype=='Int' else '"${x:fixed(3)}".console();'),value if dtype=='Int' else f'{value:.3f}',4 if dtype=='Int' else 2)
                    body=prefix+'a.matvec(v).r;v.at(0).x;'
                    add(f'{dtype}-matvec-input-{changed}-{transposed}-{dynamic}',body+('x.console();' if dtype=='Int' else '"${x:fixed(3)}".console();'),vector[0] if dtype=='Int' else f'{vector[0]:.3f}',4 if dtype=='Int' else 2)
            x=[17+changed,29+changed];y=[43,71,83]
            if dtype=='Float':x=[n/4 for n in x];y=[n/4 for n in y]
            for dynamic in (False,True):
                prefix=(f'Matrix<{dtype}>.fromRows([{x}]).xm;xm.sum(0).x;Matrix<{dtype}>.fromRows([{y}]).ym;ym.sum(0).y;' if dynamic else f'Vector<{dtype}> {x}.x;Vector<{dtype}> {y}.y;')
                for ri in range(2):
                    for ci in range(3):
                        value=x[ri]*y[ci]
                        body=prefix+f'x.outer(y).m;m.at({ri},{ci}).v;'
                        add(f'{dtype}-outer-{changed}-{dynamic}-{ri}-{ci}',body+('v.console();' if dtype=='Int' else '"${v:fixed(3)}".console();'),value if dtype=='Int' else f'{value:.3f}',4 if dtype=='Int' else 2)
        for returned in (0,7,23,29,255):
            value='17' if dtype=='Int' else '1.5'
            add(f'{dtype}-product-return-{returned}',f'Vector<{dtype},2>.filled({value}).v;v.outer(v).m;m.matvec(v).out;out.at(0).x;'+('x.console();' if dtype=='Int' else '"${x:fixed(2)}".console();'),9826 if dtype=='Int' else '6.75',4 if dtype=='Int' else 2,returned)
        rows.append((dtype+'-matvec-shape',f'start(){{Matrix<{dtype}>.zeros(2,3).m;Vector<{dtype},2>.filled('+('17' if dtype=='Int' else '1.5')+').v;m.matvec(v);23.return;}',177,{}))
    rows.append(('Int-matvec-overflow','start(){Matrix<Int>.filled(1,1,9223372036854775807).m;Vector<Int,1>.filled(2).v;m.matvec(v);23.return;}',172,{}))
    rows.append(('Int-outer-overflow','start(){Vector<Int,1>.filled(9223372036854775807).x;Vector<Int,1>.filled(2).y;x.outer(y);23.return;}',172,{}))
    for delta in (0.0,3.0):
        matrix=[[4.0+delta,1.0],[1.0,3.0+delta]]
        for expected in ([2.0,1.0],[-3.0,7.0]):
            rhs=[sum(a*b for a,b in zip(row,expected)) for row in matrix]
            for dynamic in (False,True):
                prefix=f'Matrix<Float>.fromRows({matrix}).a;'+(f'Matrix<Float>.fromRows([{rhs}]).bm;bm.sum(0).b;' if dynamic else f'Vector<Float> {rhs}.b;')+'a.solve(b).x;'
                for index,value in enumerate(expected):
                    add(f'solve-{delta}-{expected[0]}-{dynamic}-{index}',prefix+f'x.at({index}).v;"${{v:fixed(6)}}".console();',f'{value:.6f}',2)
                for index,value in enumerate(rhs):
                    add(f'solve-residual-{delta}-{expected[0]}-{dynamic}-{index}',prefix+f'a.matvec(x).reconstructed;reconstructed.at({index}).v;"${{v:fixed(6)}}".console();',f'{value:.6f}',2)
    for name,matrix,vector in [('singular','[[1.0,1.0],[1.0,1.0]]','[1.0,2.0]'),('shape','[[1.0,2.0]]','[1.0,2.0]'),('rhs-length','[[1.0,0.0],[0.0,1.0]]','[1.0]'),('rhs-nan','[[1.0,0.0],[0.0,1.0]]','[1.0,∞-∞]'),('rhs-infinity','[[1.0,0.0],[0.0,1.0]]','[1.0,∞]')]:
        rows.append(('solve-'+name,'start(){Matrix<Float>.fromRows('+matrix+').a;Vector<Float> '+vector+'.b;a.solve(b);23.return;}',177,{}))
    for dtype in ('Int','Float'):
        for delta in (0,13):
            left=[[2+delta,3,5],[7,11+delta,13]]
            right=[[17,19],[23,29],[31,37]]
            if dtype=='Float':
                left=[[x/4 for x in row] for row in left]
                right=[[x/2 for x in row] for row in right]
            expected=[[sum(left[i][k]*right[k][j] for k in range(3)) for j in range(2)] for i in range(2)]
            for transposed in (False,True):
                source_left=list(map(list,zip(*left))) if transposed else left
                source_right=list(map(list,zip(*right))) if transposed else right
                view='.transposeView()' if transposed else ''
                prefix=f'Matrix<{dtype}>.fromRows({source_left}){view}.a;Matrix<{dtype}>.fromRows({source_right}){view}.b;Matrix<{dtype}>.zeros(2,2).out;'
                for returned in (0,7,23,29,255):
                    for i,j in ((0,0),(1,1)):
                        value=expected[i][j]
                        body=prefix+f'a.matmulInto(b,out);out.at({i},{j}).v;'
                        body+='v.console();' if dtype=='Int' else '"${v:fixed(3)}".console();'
                        add(f'{dtype}-into-{delta}-{transposed}-{returned}-{i}-{j}',body,value if dtype=='Int' else f'{value:.3f}',4 if dtype=='Int' else 2,returned)
                body=prefix+f'Matrix<{dtype}>.zeros(2,2).other;a.matmulInto(b,out);a.matmulInto(b,other);'
                body+='(out.at(1,1)==other.at(1,1)).console();'
                add(f'{dtype}-into-two-live-{delta}-{transposed}',body,'true',5)
                body=prefix+f'a.matmulInto(b,out);(a.at(0,0)=={left[0][0]}).console();'
                add(f'{dtype}-into-input-preserved-{delta}-{transposed}',body,'true',5)
        for r,k,c in ((0,0,0),(0,3,2),(3,0,2),(2,3,0),(1,1,1)):
            prefix=f'Matrix<{dtype}>.zeros({r},{k}).a;Matrix<{dtype}>.zeros({k},{c}).b;Matrix<{dtype}>.zeros({r},{c}).out;a.matmulInto(b,out);'
            add(f'{dtype}-into-shape-{r}-{k}-{c}',prefix+'out.rows().console();',r)
        for name,output in [('alias-left','a'),('alias-right','b'),('readonly-view','out.transposeView()'),('wrong-shape',f'Matrix<{dtype}>.zeros(3,3)')]:
            prefix=f'Matrix<{dtype}>.zeros(2,2).a;Matrix<{dtype}>.zeros(2,2).b;Matrix<{dtype}>.zeros(2,2).out;'
            rows.append((dtype+'-into-'+name,'start(){'+prefix+f'a.matmulInto(b,{output});23.return;}}',177,{}))
    rows.append(('Int-into-overflow','start(){Matrix<Int>.filled(2,2,9223372036854775807).a;Matrix<Int>.filled(2,2,2).b;Matrix<Int>.filled(2,2,17).out;a.matmulInto(b,out);23.return;}',172,{}))
    rows.extend(decomposition_cases())
    rows.extend(function_cases())
    # Current Edition visibility requires the public Matrix import. Keep this
    # in the generated Nebo source; the process harness must not inject grants.
    return [(name, 'import "std.scientific" { Matrix; }.scientific;\n'+source, expected, options)
            for name, source, expected, options in rows]

def negatives():
    rows=[]
    for dtype in ('Int','Float'):
        for name,body in [('direct','x.matmulInto(y,x);'),('alias','x.alias;x.matmulInto(y,alias);'),('view','x.transposeView().alias;x.matmulInto(y,alias);')]:
            source=f'(Matrix<{dtype}>.x)write(Matrix<{dtype}>.y){{'+body+f'23.return;}}start(){{Matrix<{dtype}>.zeros(2,2).m;m.write(m);23.return;}}'
            rows.append((dtype+'-function-readonly-'+name,source,'NEBO_BORROW_CONFLICT'))
    prefix='Array<Int,6> [17,29,43,71,83,97].a;a.asSlice().s;'
    for name,call in [('shape-type','Matrix<Int>.fromBuffer(s,true,3)'),('no-buffer','Matrix<Int>.fromBuffer(17,2,3)'),('arity','Matrix<Int>.fromBuffer(s,2)'),('layout','Matrix<Int>.fromBuffer(s,2,3,columnMajor)'),('extra','Matrix<Int>.fromBuffer(s,2,3,rowMajor,7)'),('float-buffer-type','Matrix<Float>.fromBuffer(s,2,3)')]:
        rows.append(('fromBuffer-'+name,'start(){'+prefix+call+'.m;23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('fromBuffer-released','start(){'+prefix+'s.release();Matrix<Int>.fromBuffer(s,2,3).m;23.return;}','NEBO_USE_AFTER_MOVE'))
    rows.append(('fromBuffer-shadowed-layout','start(){'+prefix+'17.rowMajor;Matrix<Int>.fromBuffer(s,2,3,rowMajor).m;23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('fromBuffer-vector-dtype','start(){Vector<Int,2> [17,29].v;Matrix<Float>.fromBuffer(v,1,2).m;23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('sum-arity','start(){Matrix<Int>.zeros(2,3).m;m.sum(true);23.return;}','NEBO_TYPE_MISMATCH'))
    for name,call in [('slice-arity','slice(0,1,2)'),('slice-type','slice(true,1,0,1)'),('slice-range-type','slice(true…<2,0…<2)'),('slice-non-range','slice(0,1)')]:
        rows.append((name,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for method in ('determinant','inverse','conditionEstimate','cholesky'):
        rows.append((method+'-arity',f'start(){{Matrix<Float>.zeros(2,2).m;m.{method}(1);23.return;}}','NEBO_TYPE_MISMATCH'))
        rows.append((method+'-dtype',f'start(){{Matrix<Int>.zeros(2,2).m;m.{method}();23.return;}}','NEBO_TYPE_MISMATCH'))
    for method in ('lu','qr'):
        rows.append((method+'-dtype',f'start(){{Matrix<Int>.zeros(2,2).a;a.{method}();23.return;}}','NEBO_TYPE_MISMATCH'))
        rows.append((method+'-arity',f'start(){{Matrix<Float>.zeros(2,2).a;a.{method}(17);23.return;}}','NEBO_TYPE_MISMATCH'))
        for name,projection in [('index-type','at(true)'),('index-dynamic','at(index)'),('index-large','at(2)'),('positional-large','2')]:
            rows.append((method+'-projection-'+name,f'start(){{0.index;Matrix<Float>.zeros(2,2).a;a.{method}().d;d.{projection};23.return;}}','NEBO_TYPE_MISMATCH' if name in ('index-type','index-dynamic') else 'NEBO_LIMIT_EXCEEDED'))
    rows.append(('dotFlattened-argument-type','start(){Matrix<Float>.zeros(2,2).m;m.dotFlattened(17);23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('element-type','Matrix<Text>.zeros(2,3).m;'),
                      ('type-arity','Matrix<Int,Int>.zeros(2,3).m;'),
                      ('filled-wrong-int','Matrix<Int>.filled(2,3,1.5).m;'),
                      ('filled-wrong-float','Matrix<Float>.filled(2,3,17).m;'),
                      ('shape-type','Matrix<Int>.zeros(true,3).m;'),
                      ('zeros-arity','Matrix<Int>.zeros(2).m;'),
                      ('zeros-extra','Matrix<Int>.zeros(2,3,4).m;'),
                      ('filled-arity','Matrix<Int>.filled(2,3).m;')]:
        rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    for name,call in [('rows-arity','rows(1)'),('at-arity','at(0)'),('at-type','at(true,0)'),('trace-arity','trace(1)'),('layout-arity','layout(1)')]:
        rows.append((name,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('matrix-status','start(){Matrix<Int>.zeros(2,3).m;m.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    for name,call in [('fromRows-ragged','Matrix<Int>.fromRows([[17,29],[43]])'),
                      ('fromRows-mixed','Matrix<Int>.fromRows([[17,true]])'),
                      ('fromRows-flat','Matrix<Int>.fromRows([17,29])'),
                      ('fromRows-float-type','Matrix<Float>.fromRows([[17,29]])'),
                      ('fromRows-arity','Matrix<Int>.fromRows()')]:
        rows.append((name,'start(){'+call+'.m;23.return;}','NEBO_TYPE_MISMATCH'))
    for name,call in [('row-type','row(true)'),('column-arity','column()'),('transpose-arity','transposeView(1)'),('contiguous-arity','contiguous(1)')]:
        rows.append((name,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for name,call in [('columns-arity','columns(1)'),('square-arity','isSquare(1)')]:
        rows.append((name,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for call in ('clamp(1.0)','clamp(1,2)','divideElements(1.0)'):
        rows.append(('Float-type-'+call,'start(){Matrix<Float>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for call in ('add(17)','subtract(true)','multiplyElements(1.0)','matmul(17)','scale(1.0)','scale()'):
        rows.append(('type-'+call,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('mixed-dtype','start(){Matrix<Int>.zeros(2,3).a;Matrix<Float>.zeros(2,3).b;a.add(b);23.return;}','NEBO_TYPE_MISMATCH'))
    for dtype,bad in [('Int','1.5'),('Float','17')]:
        rows.append((dtype+'-get-fallback-type',f'start(){{Matrix<{dtype}>.zeros(2,3).m;m.get(0,0).unwrapOr({bad});23.return;}}','NEBO_TYPE_MISMATCH'))
    for call in ('get(0)','get(true,0)','get(0,0,0)'):
        rows.append(('arity-'+call,'start(){Matrix<Int>.zeros(2,3).m;m.'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for dtype,other in [('Int','Float'),('Float','Int')]:
        prefix=f'Matrix<{dtype}>.zeros(2,2).m;'
        for label,decl,call in [('missing','','map()'),('literal','','map(17)'),('arity',f'({dtype}.x)f(){{x.return;}}','map(f,f)'),('receiver',f'({other}.x)f(){{x.return;}}','map(f)'),('result',f'({dtype}.x)f(){{true.return;}}','map(f)'),('capture',f'({dtype}.x)f(){{outside.return;}}','map(f)')]:
            source=decl+'start(){17.outside;'+prefix+'m.'+call+';23.return;}'
            rows.append((dtype+'-map-invalid-'+label,source,'NEBO_NAME_UNDEFINED' if label=='capture' else 'NEBO_TYPE_MISMATCH'))
        declaration=f'({dtype}.x)observe(){{'+('x.console();' if dtype=='Int' else '"${x:fixed(2)}".console();')+'x.return;}'
        rows.append((dtype+'-map-effect-interpolation',declaration+'start(){'+prefix+'"${m.map(observe).rows()}".console();23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    for method in ('sum','mean','min','max'):
        for name,args in [('type','true'),('float','1.0'),('extra','0,1')]:
            rows.append((f'axis-{method}-{name}',f'start(){{Matrix<Float>.zeros(2,3).m;m.{method}({args});23.return;}}','NEBO_TYPE_MISMATCH'))
    for method,args in [('add','Vector<Int,3>.filled(17)'),('dot','Vector<Int,3>.filled(17)'),('at','true'),('scale','17'),('variance','unknown')]:
        rows.append(('axis-vector-type-'+method,'start(){Matrix<Float>.zeros(2,3).m;m.sum(0).v;v.'+method+'('+args+');23.return;}','NEBO_TYPE_MISMATCH'))
    for method in ('matvec','solve'):
        for name,args in [('arity',''),('type','17'),('dtype','Vector<Int,2>.filled(17)'),('extra','Vector<Float,2>.filled(1.5),7')]:
            rows.append((method+'-argument-'+name,'start(){Matrix<Float>.zeros(2,2).m;m.'+method+'('+args+');23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('solve-Int-dtype','start(){Matrix<Int>.zeros(2,2).m;Vector<Int,2>.filled(17).v;m.solve(v);23.return;}','NEBO_TYPE_MISMATCH'))
    for name,args in [('missing','b'),('extra','b,out,17'),('rhs-type','17,out'),('output-type','b,17'),('mixed-output','b,Matrix<Float>.zeros(2,2)')]:
        rows.append(('into-'+name,'start(){Matrix<Int>.zeros(2,2).a;Matrix<Int>.zeros(2,2).b;Matrix<Int>.zeros(2,2).out;a.matmulInto('+args+');23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('into-interpolation','start(){Matrix<Int>.zeros(2,2).a;Matrix<Int>.zeros(2,2).b;Matrix<Int>.zeros(2,2).out;"${a.matmulInto(b,out)}".console();23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    for name,args in [('arity',''),('type','17'),('dtype','Vector<Int,2>.filled(17)'),('extra','Vector<Float,2>.filled(1.5),7')]:
        rows.append(('outer-argument-'+name,'start(){Vector<Float,2>.filled(1.5).v;v.outer('+args+');23.return;}','NEBO_TYPE_MISMATCH'))
    return [(re.sub(r'[^A-Za-z0-9_.-]+','-',name).strip('-'),'import "std.scientific" { Matrix; }.scientific;\n'+source,code) for name,source,code in rows]

def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-matrix-',dir='/tmp') as directory:
        root=Path(directory)
        for front,stem in ((5,'matrix_lu'),(6,'matrix_factor')):
            target=f'build/tests/rf27-g15/f0{front}/{stem}_test'
            status,out,err=execute(['ninja',target],root,timeout=45)
            if status or err:raise Failure('MATRIX_NATIVE_BUILD:'+target)
            elf(ROOT/target)
            status,out,err=execute([ROOT/target],root,runtime=True,timeout=30)
            rows.append(dict(id='native-'+stem,category='native-control',result='PASS' if (status,out,err)==(0,b'',b'') else 'FAIL',exit=status))
        for name,source,status,options in cases():
            work=root/name;work.mkdir();p=work/'source.no';p.write_text(source)
            try:row=dict(result='PASS',**pipeline(p,work,status,**options))
            except Failure as e:row=dict(result='FAIL',failure=str(e))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives():
            work=root/name;work.mkdir();p=work/'source.no';p.write_text(source)
            try:row=dict(result='PASS',**reject(p,work,code))
            except Failure as e:row=dict(result='FAIL',failure=str(e))
            rows.append(dict(id=name,category='negative',**row))
    return dict(cases=rows,passed=sum(c['result']=='PASS' for c in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
