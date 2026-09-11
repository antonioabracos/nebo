#!/usr/bin/env python3
"""Descriptive statistics: actual typed source and independent scalar models."""
import json, math, statistics, tempfile
from pathlib import Path
from harness import ROOT, Failure, execute, pipeline, reject


def cases():
    rows=[]
    datasets=[[1,2,3,4],[17,29,43,71],[-29,17,43,7],[9,9,9,9]]
    def vector(values,t,name):
        return f'Vector<{t}> ['+','.join(repr(float(x)) if t=='Float' else str(x) for x in values)+f'].{name};'
    def add(name,source,value,returned=23,kinds=None):
        rows.append((name,source,returned,dict(kinds=kinds or [2],text=value.encode())))
    for t in ('Int','Float'):
        for ordinal,values in enumerate(datasets):
            prefix=vector(values,t,'a'); floats=list(map(float,values))
            expected=[('sum','',sum(values)),('mean','',statistics.mean(floats)),
                      ('variance','population',statistics.pvariance(floats)),('variance','sample',statistics.variance(floats)),
                      ('standardDeviation','population',statistics.pstdev(floats)),('standardDeviation','sample',statistics.stdev(floats)),
                      ('median','',statistics.median(floats))]
            for method,args,wanted in expected:
                name=f'{t}-{ordinal}-{method}-{args or "none"}'
                if method=='sum' and t=='Int':observer='a.sum().console();';output=str(wanted);kinds=[4]
                else:observer='"${a.'+method+'('+args+'):fixed(6)}".console();';output=f'{wanted:.6f}';kinds=[2]
                add(name,'start(){'+prefix+observer+'23.return;}',output,kinds=kinds)
            ordered=sorted(floats)
            for q in (0.0,0.25,0.5,0.75,1.0):
                position=(len(ordered)-1)*q;i=int(position);wanted=ordered[i]+((ordered[min(i+1,len(ordered)-1)]-ordered[i])*(position-i))
                source='start(){'+prefix+'"${a.quantile('+str(q)+',linearType7):fixed(6)}".console();23.return;}'
                add(f'{t}-{ordinal}-quantile-{q}',source,f'{wanted:.6f}')
            if len(set(values))>1:
                for changed in (values,[2*x+7 for x in values],[-3*x+29 for x in values],list(reversed(values))):
                    other=vector(changed,t,'b');wanted=statistics.correlation(floats,list(map(float,changed)))
                    name=f'{t}-{ordinal}-correlation-'+str(changed[0])
                    source='start(){'+prefix+other+'"${a.correlation(b):fixed(6)}".console();23.return;}'
                    add(name,source,f'{wanted:.6f}')
    for returned in (0,7,23,29,255):
        source='start(){Vector<Float> [1.0,2.0,3.0,4.0].a;"${a.mean():fixed(2)}".console();'+f'{returned}.return;}}'
        add(f'return-{returned}',source,'2.50',returned)
    for t in ('Int','Float'):
        for n in (1,64):
            prefix=f'Vector<{t},{n}>.filled('+('17' if t=='Int' else '17.5')+').a;'
            value=17.0 if t=='Int' else 17.5
            add(f'extent-{t}-{n}','start(){'+prefix+'"${a.mean():fixed(6)}/${a.median():fixed(6)}".console();23.return;}',f'{value:.6f}/{value:.6f}')
    source='start(){Vector<Int> [71,17,43,29].a;a.median().v;"${v:fixed(2)}/${a.at(0)}/${a.at(1)}/${a.at(2)}/${a.at(3)}".console();23.return;}'
    add('median-preserves-input',source,'36.00/71/17/43/29')
    source='start(){Vector<Float> [71.0,17.0,43.0,29.0].a;a.quantile(0.25,linearType7).v;"${v:fixed(2)}/${a.at(0):fixed(2)}/${a.at(3):fixed(2)}".console();23.return;}'
    add('quantile-preserves-input',source,'26.00/71.00/29.00')
    source='start(){Vector<Int> [17,29].a;Vector<Int> [43,71].b;a.mean().x;b.mean().y;"${x:fixed(2)}/${y:fixed(2)}/${a.sum()}".console();23.return;}'
    add('two-live-statistics',source,'23.00/57.00/46')
    source='start(){Vector<Int> [17,29].a;7.total.mutable;total+=a.sum();(total+a.sum()).console();23.return;}'
    add('scalar-composition',source,'99',kinds=[4])
    source='start(){Vector<Float> [1.0,2.0,3.0,4.0].a;0.25.q.mutable;a.quantile(q,linearType7).first;q=0.75;a.quantile(q,linearType7).second;"${first:fixed(2)}/${second:fixed(2)}".console();23.return;}'
    add('dynamic-quantile',source,'1.75/3.25')
    decl='(Int.value)meanValue(){Vector<Int,4>.filled(value).a;(a.mean()==29.0).return;}'
    rows.append(('ordinary-function',decl+'start(){29.meanValue().console();23.return;}',23,dict(kinds=[5],text=b'true')))
    for value in (7,23,255):
        source=f'start(){{Vector<Int,1>.filled({value}).a;a.sum().return;}}'
        rows.append((f'integer-sum-return-{value}',source,value,{}))
    # These accepted programs have defined native domain/overflow traps.
    # Rejected programs below never produce or execute a binary.
    for name,body,status in [
        ('domain-quantile-low','Vector<Float> [1.0,2.0].a;a.quantile(-0.25,linearType7);',177),
        ('domain-quantile-high','Vector<Float> [1.0,2.0].a;a.quantile(1.25,linearType7);',177),
        ('domain-correlation-constant','Vector<Float> [1.0,1.0].a;a.correlation(a);',177),
        ('checked-int-overflow','Vector<Int> [9223372036854775807,1].a;a.sum();',172),
    ]:
        rows.append((name,'start(){'+body+'23.return;}',status,{}))
    rows.append(('checked-int-exact-limit','start(){Vector<Int> [9223372036854775806,1].a;a.sum().console();23.return;}',23,dict(kinds=[4],text=b'9223372036854775807')))
    for method in ('sum','mean','variance'):
        args='population' if method=='variance' else ''
        source='start(){Vector<Float> [1.0,(∞-∞)].a;a.'+method+'('+args+').isNaN().console();23.return;}'
        rows.append(('nan-propagation-'+method,source,23,dict(kinds=[5],text=b'true')))
    return rows


def negatives():
    rows=[]
    def add(name,body,code='NEBO_TYPE_MISMATCH'):
        rows.append((name,'start(){Vector<Float> [1.0,2.0,3.0,4.0].a;'+body+'23.return;}',code))
    for method in ('sum','mean','median'):add('arity-'+method,f'a.{method}(17).v;')
    for method in ('variance','standardDeviation'):
        for policy in ('','17','true','"population"','linearType7','wrong','population,sample'):
            add('policy-'+method+'-'+(policy or 'empty'),f'a.{method}({policy}).v;')
        add('shadow-'+method,f'1.population;a.{method}(population).v;')
        rows.append(('sample-too-small-'+method,f'start(){{Vector<Float,1>.filled(1.5).a;a.{method}(sample).v;23.return;}}','NEBO_LIMIT_EXCEEDED'))
    for args in ('','0.25','0.25,wrong','0.25,population','0.25,sample','1,linearType7','true,linearType7','0.25,linearType7,17'):
        add('quantile-'+(args or 'empty'),f'a.quantile({args}).v;')
    add('shadow-quantile','17.linearType7;a.quantile(0.25,linearType7).v;')
    add('correlation-type','a.correlation(17).v;')
    add('correlation-shape','Vector<Float,3>.filled(1.5).b;a.correlation(b).v;')
    add('correlation-dtype','Vector<Int,4>.filled(17).b;a.correlation(b).v;')
    add('correlation-arity','a.correlation().v;')
    rows.append(('float-status','start(){Vector<Float> [1.0,2.0].a;a.mean().return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-statistics-',dir='/tmp') as directory:
        root=Path(directory)
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
        try:
            target=ROOT/'build/tests/rf27-g14/f05/statistics_test'
            result=execute(['ninja','-j2',target.relative_to(ROOT)],root,timeout=60)
            if result[0]:raise Failure('NATIVE_STATISTICS_BUILD:'+repr(result))
            result=execute([target],root,runtime=True)
            if result!=(0,b'',b''):raise Failure('NATIVE_STATISTICS_ORACLE:'+repr(result))
            row=dict(result='PASS')
        except Failure as error:row=dict(result='FAIL',failure=str(error))
        rows.append(dict(id='native-numeric-domain',category='native',**row))
    return dict(cases=rows,passed=sum(x['result']=='PASS' for x in rows),total=len(rows))


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
