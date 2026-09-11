#!/usr/bin/env python3
"""Explicit-state random distributions checked against an independent model."""
import json, math, tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute

MASK=(1<<64)-1
class SplitMix:
    def __init__(self,seed):self.state=seed&MASK
    def bits(self):
        self.state=(self.state+0x9e3779b97f4a7c15)&MASK
        x=self.state;x=((x^(x>>30))*0xbf58476d1ce4e5b9)&MASK;x=((x^(x>>27))*0x94d049bb133111eb)&MASK
        return (x^(x>>31))&MASK
    def unit(self):return (self.bits()>>11)/(1<<53)
    def integer(self,low,high):
        n=high-low;threshold=(1<<64)%n
        while True:
            x=self.bits()
            if x>=threshold:return low+x%n
    def normal(self,mean,sd):
        u=self.unit()
        while u==0:u=self.unit()
        return mean+sd*math.sqrt(-2*math.log(u))*math.cos(2*math.pi*self.unit())
    def categorical(self,weights):
        value=self.unit()*sum(weights);total=0
        for i,w in enumerate(weights):
            total+=w
            if value<total:return i
        return len(weights)-1
    def shuffle(self,values):
        values=list(values)
        for i in range(len(values)-1,0,-1):
            j=self.integer(0,i+1);values[i],values[j]=values[j],values[i]
        return values
    def sample(self,values,count):
        values=list(values)
        for i in range(count):
            j=self.integer(i,len(values));values[i],values[j]=values[j],values[i]
        return values[:count]

def observe(name,count):
    # Read the public values before formatting; each is observed independently.
    return ''.join(f'{name}.at({i}).v{i};' for i in range(count))+'"'+'/'.join('${v'+str(i)+'}' for i in range(count))+'".console();'


def cases():
    rows=[]
    def add(name,body,text,kind,returned=23):
        rows.append((name,'start(){'+body+f'{returned}.return;}}',returned,dict(kinds=[kind],text=str(text).encode())))
    for seed in (0,17,29,-1):
        prefix=f'Random.seed({seed}).r;'
        for low,high in ((10.0,20.0),(-29.0,43.0),(0.0,1.0)):
            expected=low+(high-low)*SplitMix(seed).unit()
            add(f'uniform-float-{seed}-{low}-{high}',prefix+f'r.uniform({low},{high}).v;"${{v:fixed(6)}}".console();',f'{expected:.6f}',2)
        for low,high in ((0,1),(10,20),(17,1000),(0,9223372036854775807)):
            expected=SplitMix(seed).integer(low,high)
            add(f'uniform-int-{seed}-{low}-{high}',prefix+f'r.uniform({low},{high}).console();',expected,4)
        for mean,sd in ((0.0,1.0),(5.0,2.0),(-17.0,0.5)):
            expected=SplitMix(seed).normal(mean,sd)
            add(f'normal-{seed}-{mean}-{sd}',prefix+f'r.normal({mean},{sd}).v;"${{v:fixed(6)}}".console();',f'{expected:.6f}',2)
        for probability in (0.0,0.3,0.75,1.0):
            expected=SplitMix(seed).unit()<probability
            add(f'bernoulli-{seed}-{probability}',prefix+f'r.bernoulli({probability}).console();',str(expected).lower(),5)
        for weights in ([1.0,2.0,3.0],[0.0,7.0,0.0],[9.0,1.0,2.0],[1.0]):
            expected=SplitMix(seed).categorical(weights)
            body=prefix+'Vector<Float> ['+','.join(map(str,weights))+'].weights;r.categorical(weights).console();'
            add(f'categorical-{seed}-'+str(weights[0])+'-'+str(len(weights)),body,expected,4)
    for seed in (17,29):
        model=SplitMix(seed);values=[model.integer(0,1000) for _ in range(3)]
        body=f'Random.seed({seed}).r;r.uniform(0,1000).a;r.uniform(0,1000).b;r.uniform(0,1000).c;"${{a}}/${{b}}/${{c}}".console();'
        add(f'ordered-state-{seed}',body,'/'.join(map(str,values)),2)
        expected=SplitMix(seed).integer(0,1000)
        body=f'Random.seed({seed}).a;Random.seed({seed}).b;a.uniform(0,1000).x;a.uniform(0,1000);b.uniform(0,1000).y;"${{x}}/${{y}}".console();'
        add(f'two-live-states-{seed}',body,f'{expected}/{expected}',2)
    for returned in (0,7,23,29,255):
        expected=SplitMix(17).integer(10,100)
        add(f'return-{returned}','Random.seed(17).r;r.uniform(10,100).console();',expected,4,returned)
    source='start(){Random.seed(17).r;r.bernoulli(0.3).v;if(v){7.return;}else{23.return;}}'
    rows.append(('bool-control-flow',source,7 if SplitMix(17).unit()<0.3 else 23,{}))
    source='(Int.value)draw(){Random.seed(value).r;r.uniform(10,100).return;}start(){29.draw().console();23.return;}'
    rows.append(('function-local-state',source,23,dict(kinds=[4],text=str(SplitMix(29).integer(10,100)).encode())))
    source='(Int.value)seedValue(){value.console();value.return;}start(){Random.seed(17.seedValue()).r;r.uniform(10,100).console();23.return;}'
    rows.append(('seed-evaluated-once',source,23,dict(kinds=[4,4],text=('17'+str(SplitMix(17).integer(10,100))).encode(),publications=2)))
    for name,call in [('uniform-empty','r.uniform(17,17)'),('uniform-negative','r.uniform(-1,17)'),('uniform-reversed','r.uniform(29.0,17.0)'),('normal-zero','r.normal(0.0,0.0)'),('bernoulli-negative','r.bernoulli(-0.25)'),('bernoulli-high','r.bernoulli(1.25)')]:
        rows.append(('domain-'+name,'start(){Random.seed(17).r;'+call+';23.return;}',177,{}))
    source='start(){Random.seed(17).r;Vector<Float> [1.0,-2.0].w;r.categorical(w);23.return;}'
    rows.append(('domain-negative-weight',source,177,{}))
    for name,call in [('uniform-infinite-high','r.uniform(0.0,∞)'),('uniform-infinite-low','r.uniform((-∞),17.0)'),
                      ('normal-infinite-mean','r.normal(∞,1.0)'),('normal-infinite-sd','r.normal(0.0,∞)'),
                      ('uniform-nan','r.uniform((∞-∞),17.0)'),('normal-nan','r.normal((∞-∞),1.0)'),
                      ('bernoulli-nan','r.bernoulli((∞-∞))')]:
        rows.append(('domain-'+name,'start(){Random.seed(17).r;'+call+';23.return;}',177,{}))
    for name,weights in [('infinite','∞,1.0'),('nan','(∞-∞),1.0'),('zero','0.0,0.0')]:
        rows.append(('domain-weights-'+name,'start(){Random.seed(17).r;Vector<Float> ['+weights+'].w;r.categorical(w);23.return;}',177,{}))
    for seed in (0,17,29,-1):
        for values in ([17],[17,29,43,71],[-31,7,59,101]):
            n=len(values);literal=','.join(map(str,values))
            body=f'Random.seed({seed}).r;Array<Int,{n}> [{literal}].a.mutable;a.asSlice().s;r.shuffle(s);'
            expected=SplitMix(seed).shuffle(values)
            add(f'shuffle-{seed}-{values[0]}-{n}',body+observe('s',n),'/'.join(map(str,expected)),2)
            for count in dict.fromkeys((0,1,n)):
                body=f'Random.seed({seed}).r;Vector<Int> [{literal}].a;r.sample(a,{count}).s;'
                expected=SplitMix(seed).sample(values,count)
                if count:add(f'sample-{seed}-{values[0]}-{n}-{count}',body+observe('s',count),'/'.join(map(str,expected)),2)
                else:add(f'sample-{seed}-{values[0]}-{n}-0',body+'s.length().console();',0,4)
    values=list(range(17,81));literal=','.join(map(str,values))
    body=f'Random.seed(17).r;Vector<Int> [{literal}].a;r.sample(a,16).s;'
    add('sample-boundary-64-16',body+observe('s',16),'/'.join(map(str,SplitMix(17).sample(values,16))),2)
    prefix='Random.seed(17).r;Array<Int,4> [17,29,43,71].a.mutable;a.asSlice().s;'
    add('shuffle-before-later-view',prefix+'r.shuffle(s);a.asSlice().later;'+observe('later',4),'43/17/29/71',2)
    add('shuffle-after-alias-release',prefix+'a.asSlice().old;old.release();r.shuffle(s);'+observe('s',4),'43/17/29/71',2)
    add('shuffle-before-own-release',prefix+'r.shuffle(s);s.release();'+observe('a',4),'43/17/29/71',2)
    add('shuffle-two-live-owners',prefix+'Array<Int,2> [83,97].b.mutable;b.asSlice().t;r.shuffle(s);'+observe('t',2),'83/97',2)
    expected=SplitMix(17).sample([17,29,43,71],2)
    add('sample-slice',prefix+'r.sample(s,2).sampled;'+observe('sampled',2),'/'.join(map(str,expected)),2)
    add('sample-preserves-input',prefix+'r.sample(s,2).sampled;sampled.push(101);'+observe('s',4),'17/29/43/71',2)
    add('sample-two-live-results',prefix+'r.sample(s,2).first;r.sample(s,2).second;first.at(0).console();',expected[0],4)
    for count in (-1,5,17):
        rows.append((f'sample-domain-{count}','start(){'+prefix+f'r.sample(s,{count});23.return;}}',177,{}))
    for returned in (0,7,23,29,255):
        add(f'shuffle-return-{returned}',prefix+'r.shuffle(s);'+observe('s',4),'43/17/29/71',2,returned)
    return rows


def negatives():
    rows=[]
    for name,source in [('seed-type','Random.seed(true).r;'),('seed-arity','Random.seed().r;'),('seed-extra','Random.seed(17,29).r;')]:rows.append((name,'start(){'+source+'23.return;}','NEBO_TYPE_MISMATCH'))
    for name,call in [('uniform-type','uniform(1,2.0)'),('uniform-arity','uniform(1.0)'),('uniform-extra','uniform(1.0,2.0,3.0)'),('normal-type','normal(0,1.0)'),('normal-arity','normal(0.0)'),('normal-extra','normal(0.0,1.0,2.0)'),('bernoulli-type','bernoulli(1)'),('bernoulli-arity','bernoulli()'),('bernoulli-extra','bernoulli(0.5,0.25)'),('categorical-type','categorical(17)'),('categorical-arity','categorical()')]:
        rows.append((name,'start(){Random.seed(17).r;r.'+call+'.v;23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('categorical-dtype','start(){Random.seed(17).r;Vector<Int> [1,2].w;r.categorical(w).v;23.return;}','NEBO_TYPE_MISMATCH'))
    for method in ('uniform(0.0,1.0)','bernoulli(0.3)'):
        source='start(){Random.seed(17).r;"${r.'+method+'}".console();23.return;}'
        rows.append(('interpolation-effect-'+method.split('(')[0],source,'NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    rows.append(('state-status','start(){Random.seed(17).r;r.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    prefix='Random.seed(17).r;Array<Int,4> [17,29,43,71].a.mutable;a.asSlice().s;'
    for name,body in [('shuffle-after-release',prefix+'s.release();r.shuffle(s);'),
                      ('shuffle-two-aliases',prefix+'a.asSlice().t;r.shuffle(s);'),
                      ('shuffle-readonly',prefix.replace('.a.mutable','.a')+'r.shuffle(s);'),
                      ('sample-after-release',prefix+'s.release();r.sample(s,1);'),
                      ('shuffle-scalar','Random.seed(17).r;r.shuffle(17);'),
                      ('shuffle-arity',prefix+'r.shuffle();'),
                      ('shuffle-extra',prefix+'r.shuffle(s,s);'),
                      ('sample-count-type',prefix+'r.sample(s,true);'),
                      ('sample-scalar','Random.seed(17).r;r.sample(17,1);'),
                      ('sample-arity',prefix+'r.sample(s);')]:
        code='NEBO_USE_AFTER_MOVE' if name.endswith('after-release') else 'NEBO_BORROW_CONFLICT' if name=='shuffle-two-aliases' else 'NEBO_TYPE_MISMATCH'
        rows.append((name,'start(){'+body+'23.return;}',code))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-random-',dir='/tmp') as directory:
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
            target=ROOT/'build/tests/rf27-g14/f06/distributions_test'
            result=execute(['ninja','-j2',target.relative_to(ROOT)],root,timeout=60)
            if result[0]:raise Failure('NATIVE_DISTRIBUTIONS_BUILD:'+repr(result))
            result=execute([target],root,runtime=True)
            if result!=(0,b'',b''):raise Failure('NATIVE_DISTRIBUTIONS_ORACLE:'+repr(result))
            row=dict(result='PASS')
        except Failure as e:row=dict(result='FAIL',failure=str(e))
        rows.append(dict(id='native-distribution-controls',category='native',**row))
    return dict(cases=rows,passed=sum(c['result']=='PASS' for c in rows),total=len(rows))


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
