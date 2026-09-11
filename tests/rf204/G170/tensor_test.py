#!/usr/bin/env python3
"""Typed Tensor sources versus independent shapes, values and alias oracles."""
import json, math, tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf


def shape(values):
    return 'Tuple.of('+','.join(map(str,values))+')'


def buffer_cases():
    rows=[]
    def add(name,source,values,dtype,returned=23):
        kinds=[2 if dtype=='Float' else 4]*len(values)
        text=''.join(f'{v:.3f}' if dtype=='Float' else str(v) for v in values).encode()
        rows.append((name,'start(){'+source+f'{returned}.return;}}',returned,dict(kinds=kinds,text=text)))
    for dtype,values in [('Int',[17,29,43,71,83,97]),('Float',[1.5,2.75,3.125,7.25,-4.5,9.75])]:
        def observe(body,dimensions,name='t'):
            import itertools
            for coordinate in itertools.product(*(range(d) for d in dimensions)):
                expression=f'{name}.at({shape(coordinate)})'
                body+=('"${'+expression+':fixed(3)}".console();') if dtype=='Float' else expression+'.console();'
            return body
        for changed in (0,11):
            data=[v+changed for v in values]
            prefix=f'Vector<{dtype}> {data}.b;'
            for strides,expected in [(None,data),([1,2],[data[0],data[2],data[4],data[1],data[3],data[5]]),([0,1],data[:3]*2)]:
                arguments='' if strides is None else ','+shape(strides)
                body=prefix+f'Tensor<{dtype}>.fromBuffer(b,Tuple.of(2,3){arguments}).t;'
                add(f'buffer-{dtype}-{changed}-{strides}',observe(body,[2,3]),expected,dtype)
            base=prefix+f'Tensor<{dtype}>.fromBuffer(b,Tuple.of(2,3)).a;'
            for method,dimensions,expected in [('permute(Tuple.of(1,0))',[3,2],[data[0],data[3],data[1],data[4],data[2],data[5]]),
                                               ('select(0,1)',[3],data[3:]),('narrow(1,1,2)',[2,2],[data[1],data[2],data[4],data[5]]),
                                               ('slice(Tuple.of(1,0,2,2))',[2,2],[data[0],data[2],data[3],data[5]]),('reshape(Tuple.of(3,2))',[3,2],data)]:
                for copied in (False,True):
                    body=base+'a.'+method+('.contiguous()' if copied else '')+'.t;'
                    add(f'buffer-view-{dtype}-{changed}-{method}-{copied}',observe(body,dimensions),expected,dtype)
            body=base+'a.permute(Tuple.of(1,0)).narrow(0,1,2).select(1,1).t;'
            add(f'buffer-view-chain-{dtype}-{changed}',observe(body,[2]),data[4:6],dtype)
        for returned in (0,7,23,29,255):
            body=f'Vector<{dtype}> {values}.b;Tensor<{dtype}>.fromBuffer(b,Tuple.of(2,3)).t;'
            add(f'buffer-return-{dtype}-{returned}',observe(body,[2,3]),values,dtype,returned)
    prefix='Array<Int,6> [17,29,43,71,83,97].owner.mutable;owner.asSlice().s;'
    for name,suffix in [('live',''),('release','s.release();'),('shuffle','Random.seed(17).r;r.shuffle(s);')]:
        add('buffer-slice-'+name,prefix+'Tensor<Int>.fromBuffer(s,Tuple.of(2,3)).t;'+suffix+'t.at(Tuple.of(0,0)).console();t.at(Tuple.of(1,2)).console();',[17,97],'Int')
    for name,shape_arg,strides_arg in [('short',shape([2,4]),''),('long',shape([2,2]),''),('stride-bounds',shape([2,3]),','+shape([4,1])),
                                       ('stride-rank',shape([2,3]),','+shape([1])),('negative-stride',shape([2,3]),',Vector<Int> [-1,1]')]:
        source='start(){Vector<Int> [17,29,43,71,83,97].b;Tensor<Int>.fromBuffer(b,'+shape_arg+strides_arg+');23.return;}'
        rows.append(('buffer-'+name,source,177,{}))
    return rows


def binary_cases():
    import itertools
    rows=[]
    for dtype in ('Int','Float'):
        for n,(sa,sb) in enumerate([([2,3],[2,3]),([2,3],[3]),([2,1],[1,3]),([],[2,3]),([2,0,3],[1,3]),([1,2,3],[4,1,1])]):
            aa=[v+1 if dtype=='Int' else (v+1)*0.75 for v in range(math.prod(sa))]
            bb=[v+2 if dtype=='Int' else (v+2)*1.25 for v in range(math.prod(sb))]
            rank=max(len(sa),len(sb));pa=[1]*(rank-len(sa))+sa;pb=[1]*(rank-len(sb))+sb
            target=[b if a==1 else a for a,b in zip(pa,pb)]
            def construct(values,dimensions,name):
                if not values:return f'Tensor<{dtype}>.zeros({shape(dimensions)}).{name};'
                return f'Vector<{dtype}> {values}.v{name};Tensor<{dtype}>.fromBuffer(v{name},{shape(dimensions)}).{name};'
            def value(data,dimensions,coord):
                index=0
                for size,axis in zip(dimensions,coord):index=index*size+(0 if size==1 else axis)
                return data[index]
            for method in ('add','multiply','divide','maximum') if dtype=='Float' else ('add','multiply'):
                body=construct(aa,sa,'a')+construct(bb,sb,'b')+f'a.{method}(b).c;'
                expected=str(len(target))+str(math.prod(target));kinds=[4,4]
                body+='c.rank().console();c.elementCount().console();'
                for coord in itertools.product(*(range(d) for d in target)):
                    a=value(aa,pa,coord);b=value(bb,pb,coord)
                    wanted={'add':lambda:a+b,'multiply':lambda:a*b,'divide':lambda:a/b,'maximum':lambda:max(a,b)}[method]()
                    expression='c.at('+shape(coord)+')'
                    if dtype=='Float':body+='"${'+expression+':fixed(6)}".console();';expected+=f'{wanted:.6f}';kinds.append(2)
                    else:body+=expression+'.console();';expected+=str(wanted);kinds.append(4)
                rows.append((f'binary-{dtype}-{n}-{method}','start(){'+body+'23.return;}',23,dict(kinds=kinds,text=expected.encode())))
    for name,body in [('add-overflow','Tensor<Int>.filled(Tuple.of(2),9223372036854775807).a;Tensor<Int>.filled(Tuple.of(2),1).b;a.add(b);'),
                      ('multiply-overflow','Tensor<Int>.filled(Tuple.of(2),9223372036854775807).a;Tensor<Int>.filled(Tuple.of(2),2).b;a.multiply(b);'),
                      ('binary-shape','Tensor<Float>.zeros(Tuple.of(2,3)).a;Tensor<Float>.zeros(Tuple.of(2,2)).b;a.add(b);'),
                      ('divide-zero','Tensor<Float>.filled(Tuple.of(2,3),1.5).a;Tensor<Float>.zeros(Tuple.of(1,3)).b;a.divide(b);')]:
        rows.append((name,'start(){'+body+'23.return;}',172 if name in ('add-overflow','multiply-overflow') else 177,{}))
    for dtype,value in [('Int','17'),('Float','1.5'),('Bool','true')]:
        body=f'Tensor<{dtype}>.filled(Tuple.of(3),{value}).a;a.broadcastTo(Tuple.of(2,3)).b;b.rank().console();b.elementCount().console();(a.storageId()==b.storageId()).console();'
        rows.append(('broadcast-rank-'+dtype,'start(){'+body+'23.return;}',23,dict(kinds=[4,4,5],text=b'26true')))
    return rows


def selection_cases():
    rows=[]
    for changed in (False,True):
        mask=[0,1,1,0] if not changed else [1,0,0,1]
        for method,dimensions,indices in [('',[2,2],list(range(4))),('.permute(Tuple.of(1,0))',[2,2],[0,2,1,3]),('.contiguous()',[2,2],list(range(4)))]:
            body='Bytes.fromValues('+','.join(map(str,mask))+').maskbytes;Tensor<Bool>.fromBuffer(maskbytes,Tuple.of(2,2))'+method+'.t;'
            expected=''
            import itertools
            for coordinate,index in zip(itertools.product(*(range(d) for d in dimensions)),indices):
                body+='t.at('+shape(coordinate)+').console();'
                expected+='true' if mask[index] else 'false'
            rows.append((f'bool-buffer-{changed}-{method}','start(){'+body+'23.return;}',23,dict(text=expected.encode(),kinds=[5]*4)))
        for returned in (0,7,23,29,255):
            body='Bytes.fromValues('+','.join(map(str,mask))+').maskbytes;Tensor<Bool>.fromBuffer(maskbytes,Tuple.of(2,2)).c;'
            body+='Vector<Float> [1.5,2.75,-4.5,9.75].v;Tensor<Float>.fromBuffer(v,Tuple.of(2,2)).a;Tensor<Float>.filled(Tuple.of(2,2),-17.5).b;a.where(c,b).t;'
            values=[a if cond else -17.5 for a,cond in zip([1.5,2.75,-4.5,9.75],mask)]
            for coordinate in itertools.product(range(2),range(2)):body+='"${t.at('+shape(coordinate)+'):fixed(3)}".console();'
            rows.append((f'where-{changed}-{returned}','start(){'+body+f'{returned}.return;}}',returned,dict(text=''.join(f'{v:.3f}' for v in values).encode(),kinds=[2]*4)))
    for n,(expression,operation) in enumerate([('x*2.0+1.5',lambda x:x*2+1.5),('x*x',lambda x:x*x),('x*0.5-1.25',lambda x:x*0.5-1.25)]):
        for view in ('','.permute(Tuple.of(1,0))'):
            values=[1.5,2.75,3.125,7.25,-4.5,9.75]; order=list(range(6)) if not view else [0,3,1,4,2,5];dimensions=[2,3] if not view else [3,2]
            body='Vector<Float> '+str(values)+'.v;Tensor<Float>.fromBuffer(v,Tuple.of(2,3))'+view+'.a;a.map(kernel).t;'
            for coordinate in itertools.product(*(range(d) for d in dimensions)):body+='"${t.at('+shape(coordinate)+'):fixed(3)}".console();'
            source='(Float.x)kernel(){('+expression+').return;}start(){'+body+'23.return;}'
            rows.append((f'map-{n}-{bool(view)}',source,23,dict(text=''.join(f'{operation(values[i]):.3f}' for i in order).encode(),kinds=[2]*6)))
    rows.extend([
      ('map-effects','(Float.x)kernel(){7.console();(x*2.0).return;}start(){Tensor<Float>.filled(Tuple.of(2),1.5).a;a.map(kernel).t;"${t.at(Tuple.of(1)):fixed(2)}".console();23.return;}',23,dict(text=b'773.00',kinds=[4,4,2])),
      ('map-pure-interpolation','(Float.x)kernel(){(x*2.0).return;}start(){Tensor<Float>.filled(Tuple.of(2),1.5).a;"${a.map(kernel).at(Tuple.of(1)):fixed(2)}".console();23.return;}',23,dict(text=b'3.00',kinds=[2])),
      ('bool-buffer-invalid-value','start(){Bytes.fromValues(0,2,1,0).b;Tensor<Bool>.fromBuffer(b,Tuple.of(4));23.return;}',177,{}),
      ('buffer-empty-negative-stride','start(){Vector<Int> [17].b;Tensor<Int>.fromBuffer(b,Tuple.of(0),Vector<Int> [-1]);23.return;}',177,{}),
      ('where-shape','start(){Tensor<Float>.zeros(Tuple.of(2)).a;Tensor<Float>.zeros(Tuple.of(3)).b;Tensor<Bool>.zeros(Tuple.of(2)).c;a.where(c,b);23.return;}',177,{})
    ])
    return rows


def reduction_cases():
    import itertools
    rows=[]
    for dtype in ('Float','Int'):
        for view in (False,True):
            source_dims=[2,3,2];data=[(i+1)*(-1 if i%3==0 else 1) for i in range(12)]
            if dtype=='Float':data=[v/4 for v in data]
            dimensions=[3,2,2] if view else source_dims
            def value(coord):
                a,b,c=coord
                if view:a,b=b,a
                return data[(a*3+b)*2+c]
            prefix=f'Vector<{dtype}> {data}.v;Tensor<{dtype}>.fromBuffer(v,Tuple.of(2,3,2))'+('.permute(Tuple.of(1,0,2))' if view else '')+'.a;'
            for axes in ([0],[1],[2],[0,2],[2,0],[0,1,2]):
                for keep in (False,True):
                    target=[1 if i in axes else d for i,d in enumerate(dimensions)] if keep else [d for i,d in enumerate(dimensions) if i not in axes]
                    for method in ('sum','mean','min','max') if dtype=='Float' else ('sum',):
                        body=prefix+'a.'+method+'('+shape(axes)+','+str(keep).lower()+').t;t.rank().console();'
                        text=str(len(target));kinds=[4]
                        for i,size in enumerate(target):body+=f't.axisSize({i}).console();';text+=str(size);kinds.append(4)
                        for coordinate in itertools.product(*(range(d) for d in target)):
                            nonreduced=[coordinate[i] for i in range(len(dimensions)) if i not in axes] if keep else coordinate
                            group=[]
                            for input_coordinate in itertools.product(*(range(d) for d in dimensions)):
                                if [input_coordinate[i] for i in range(len(dimensions)) if i not in axes]==list(nonreduced):group.append(value(input_coordinate))
                            expected={'sum':sum,'mean':lambda g:sum(g)/len(g),'min':min,'max':max}[method](group)
                            expression='t.at('+shape(coordinate)+')'
                            if dtype=='Float':body+='"${'+expression+':fixed(6)}".console();';text+=f'{expected:.6f}';kinds.append(2)
                            else:body+=expression+'.console();';text+=str(expected);kinds.append(4)
                        rows.append((f'reduce-{dtype}-{view}-{axes}-{keep}-{method}','start(){'+body+'23.return;}',23,dict(text=text.encode(),kinds=kinds)))
    for dimensions,axis in [([2,3],0),([2,3],1),([2,3,2],1),([2,2,2,2],3),([64,64],0),([1,1,1,1,1,3],5)]:
        data=[float((i*7)%13) for i in range(math.prod(dimensions))]
        target=dimensions[:axis]+dimensions[axis+1:]
        if len(data)<=64:prefix=f'Vector<Float> {data}.v;Tensor<Float>.fromBuffer(v,{shape(dimensions)}).a;'
        else:prefix=f'Tensor<Float>.filled({shape(dimensions)},1.5).a;';data=[1.5]*math.prod(dimensions)
        body=prefix+f'a.argMax({axis}).t;t.contiguous().copy;t.dtype().console();t.rank().console();t.elementCount().console();'
        text='2'+str(len(target))+str(math.prod(target));kinds=[4]*3
        for coordinate in itertools.product(*(range(d) for d in target)):
            values=[]
            for k in range(dimensions[axis]):
                point=list(coordinate);point.insert(axis,k);offset=0
                for size,coord in zip(dimensions,point):offset=offset*size+coord
                values.append(data[offset])
            wanted=max(range(len(values)),key=values.__getitem__)
            body+='copy.at('+shape(coordinate)+').console();';text+=str(wanted);kinds.append(4)
        rows.append((f'argmax-{dimensions}-{axis}','start(){'+body+'23.return;}',23,dict(text=text.encode(),kinds=kinds)))
    for mask in ([0,1,1,0],[1,1,0,0],[0,0,0,0],[1,1,1,1]):
        for axis in (0,1):
            for method,fn in [('all',all),('any',any)]:
                groups=[[mask[i*2+j] for i in range(2)] for j in range(2)] if axis==0 else [mask[:2],mask[2:]]
                body='Bytes.fromValues('+','.join(map(str,mask))+').b;Tensor<Bool>.fromBuffer(b,Tuple.of(2,2)).a;a.'+method+f'({axis}).t;t.at(Tuple.of(0)).console();t.at(Tuple.of(1)).console();'
                rows.append((f'bool-reduce-{mask}-{axis}-{method}','start(){'+body+'23.return;}',23,dict(text=''.join(str(fn(g)).lower() for g in groups).encode(),kinds=[5,5])))
    for name,body in [('reduce-duplicate-axis','Tensor<Float>.filled(Tuple.of(2,3),1.0).a;a.sum(Tuple.of(0,0),false);'),
                      ('reduce-missing-axis','Tensor<Float>.filled(Tuple.of(2,3),1.0).a;a.sum(Tuple.of(),false);'),
                      ('reduce-negative-axis','Tensor<Float>.filled(Tuple.of(2,3),1.0).a;a.sum(Vector<Int> [-1],false);'),
                      ('reduce-axis-range','Tensor<Float>.filled(Tuple.of(2,3),1.0).a;a.sum(Tuple.of(2),false);'),
                      ('reduce-empty','Tensor<Float>.zeros(Tuple.of(0,3)).a;a.sum(Tuple.of(0),false);'),
                      ('reduce-nonfinite','Tensor<Float>.filled(Tuple.of(2),(∞-∞)).a;a.sum(Tuple.of(0),false);'),
                      ('argmax-axis-range','Tensor<Float>.filled(Tuple.of(2),1.0).a;a.argMax(1);'),
                      ('argmax-empty','Tensor<Float>.zeros(Tuple.of(0)).a;a.argMax(0);'),
                      ('all-empty','Tensor<Bool>.zeros(Tuple.of(0)).a;a.all(0);')]:rows.append((name,'start(){'+body+'23.return;}',177,{}))
    rows.append(('sum-int-overflow','start(){Tensor<Int>.filled(Tuple.of(2),9223372036854775807).a;a.sum(Tuple.of(0),false);23.return;}',172,{}))
    return rows


def algebra_cases():
    import itertools
    rows=[]
    def index(data,dimensions,coordinate):
        offset=0
        for size,point in zip(dimensions,coordinate):offset=offset*size+point
        return data[offset]
    def tensor(data,dimensions,name):
        return f'Vector<Float> {data}.v{name};Tensor<Float>.fromBuffer(v{name},{shape(dimensions)}).{name};' if data else f'Tensor<Float>.zeros({shape(dimensions)}).{name};'
    def observe(body,dimensions,values,name):
        body+='t.rank().console();t.elementCount().console();';text=str(len(dimensions))+str(math.prod(dimensions));kinds=[4,4]
        for point,value in zip(itertools.product(*(range(d) for d in dimensions)),values):
            body+='"${t.at('+shape(point)+'):fixed(6)}".console();';text+=f'{value:.6f}';kinds.append(2)
        rows.append((name,'start(){'+body+'23.return;}',23,dict(text=text.encode(),kinds=kinds)))
    for changed in (0,3):
        for sa,sb in [([3],[3]),([2,3],[3]),([3],[3,2]),([2,3],[3,2]),([2,2,3],[3,2]),([1,2,3],[2,3,2]),([2,1,2,3],[1,3,2]),([2,0],[0,3]),([0,3],[3,2])]:
            aa=[(i+changed+1)*0.25 for i in range(math.prod(sa))];bb=[(i+2)*(-0.5 if i%3==0 else 0.5) for i in range(math.prod(sb))]
            pa=([1]+sa) if len(sa)==1 else sa;pb=sb+[1] if len(sb)==1 else sb
            rank=max(len(pa),len(pb));pa=[1]*(rank-len(pa))+pa;pb=[1]*(rank-len(pb))+pb
            batches=[max(a,b) for a,b in zip(pa[:-2],pb[:-2])];full=batches+[pa[-2],pb[-1]]
            result=[]
            for point in itertools.product(*(range(d) for d in full)):
                total=0.0
                for k in range(pa[-1]):
                    ca=[0 if d==1 else p for d,p in zip(pa[:-2],point[:-2])]+[point[-2],k]
                    cb=[0 if d==1 else p for d,p in zip(pb[:-2],point[:-2])]+[k,point[-1]]
                    total+=index(aa,pa,ca)*index(bb,pb,cb)
                result.append(total)
            target=full[:-2]+([] if len(sa)==1 else [full[-2]])+([] if len(sb)==1 else [full[-1]])
            observe(tensor(aa,sa,'a')+tensor(bb,sb,'b')+'a.matmul(b).t;',target,result,f'matmul-{changed}-{sa}-{sb}')
    for dimensions,pads in [([],[]),([3],[1,2]),([2,3],[1,0,2,1]),([2,2,2],[0,1,1,0,1,1]),([0,2],[1,1,0,1]),([1,1,1,1,1,1],[0,1]*6)]:
        data=[(i+1)*0.75 for i in range(math.prod(dimensions))]
        target=[d+pads[i*2]+pads[i*2+1] for i,d in enumerate(dimensions)]
        for fill in (-1.5,2.75):
            values=[]
            for point in itertools.product(*(range(d) for d in target)):
                original=[p-pads[i*2] for i,p in enumerate(point)]
                values.append(index(data,dimensions,original) if all(0<=p<d for p,d in zip(original,dimensions)) else fill)
            padding=shape(pads) if len(pads)<=6 else f'Vector<Int> {pads}'
            observe(tensor(data,dimensions,'a')+f'a.pad({padding},{fill}).t;',target,values,f'pad-{dimensions}-{fill}')
    for name,body in [('matmul-shape','Tensor<Float>.zeros(Tuple.of(2,3)).a;Tensor<Float>.zeros(Tuple.of(2,3)).b;a.matmul(b);'),
                      ('matmul-scalar','Tensor<Float>.zeros(Tuple.of()).a;a.matmul(a);'),
                      ('pad-count','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.pad(Tuple.of(1,1),1.0);'),
                      ('pad-negative','Tensor<Float>.zeros(Tuple.of(2)).a;a.pad(Vector<Int> [-1,1],1.0);'),
                      ('pad-bound','Tensor<Float>.zeros(Tuple.of(2)).a;a.pad(Tuple.of(4096,1),1.0);')]:rows.append((name,'start(){'+body+'23.return;}',177,{}))
    return rows


def structural_cases():
    import itertools
    rows=[]
    def observe(body,dimensions,values,name):
        body+='t.rank().console();t.elementCount().console();';text=str(len(dimensions))+str(math.prod(dimensions));kinds=[4,4]
        for point,value in zip(itertools.product(*(range(d) for d in dimensions)),values):
            body+='"${t.at('+shape(point)+'):fixed(3)}".console();';text+=f'{value:.3f}';kinds.append(2)
        rows.append((name,'start(){'+body+'23.return;}',23,dict(text=text.encode(),kinds=kinds)))
    for count in (1,2,6):
        for dimensions in ([2,3],[],[0,2]):
            for view in (False,True) if dimensions==[2,3] else (False,):
                logical=list(reversed(dimensions)) if view else dimensions
                data=[[0.25*(1+i+7*j) for i in range(math.prod(dimensions))] for j in range(count+1)]
                prefix=''
                for j,values in enumerate(data):
                    prefix+=f'Vector<Float> {values}.v{j};Tensor<Float>.fromBuffer(v{j},{shape(dimensions)})'+('.permute(Tuple.of(1,0))' if view else '')+f'.a{j};' if values else f'Tensor<Float>.zeros({shape(dimensions)}).a{j};'
                def value(j,point):
                    point=list(reversed(point)) if view else point;offset=0
                    for size,p in zip(dimensions,point):offset=offset*size+p
                    return data[j][offset]
                for method in ('concatenate','stack'):
                    for axis in range(len(logical)+(method=='stack')):
                        target=list(logical)
                        if method=='stack':target.insert(axis,count+1)
                        else:target[axis]*=count+1
                        expected=[]
                        for point in itertools.product(*(range(d) for d in target)):
                            original=list(point)
                            if method=='stack':j=original.pop(axis)
                            else:j,original[axis]=divmod(original[axis],logical[axis])
                            expected.append(value(j,original))
                        peers='Tuple.of('+','.join('a'+str(j) for j in range(1,count+1))+')'
                        observe(prefix+'a0.'+method+f'({peers},{axis}).t;',target,expected,f'{method}-{count}-{dimensions}-{view}-{axis}')
    for axis,sizes in [(0,[1,1]),(1,[1,2]),(1,[0,1,0,2,0])]:
        for view in (False,True):
            dimensions=[3,2] if view else [2,3]
            if sum(sizes)!=dimensions[axis]:continue
            values=[1.5,2.75,3.125,7.25,-4.5,9.75]
            body='Vector<Float> '+str(values)+'.v;Tensor<Float>.fromBuffer(v,Tuple.of(2,3))'+('.permute(Tuple.of(1,0))' if view else '')+'.a;'
            body+=f'a.split({shape(sizes)},{axis}).parts;parts.length().console();';text=str(len(sizes));kinds=[4];begin=0
            for i,size in enumerate(sizes):
                body+=f'parts.at({i}).p{i};p{i}.axisSize({axis}).console();(p{i}.storageId()==a.storageId()).console();';text+=str(size)+'true';kinds.extend([4,5])
                target=list(dimensions);target[axis]=size
                for point in itertools.product(*(range(d) for d in target)):
                    original=list(point);original[axis]+=begin
                    if view:original.reverse()
                    expected=values[original[0]*3+original[1]]
                    body+='"${p'+str(i)+'.at('+shape(point)+'):fixed(3)}".console();';text+=f'{expected:.3f}';kinds.append(2)
                begin+=size
            rows.append((f'split-{axis}-{sizes}-{view}','start(){'+body+'23.return;}',23,dict(text=text.encode(),kinds=kinds)))
    for name,body in [('join-shape','Tensor<Float>.zeros(Tuple.of(2,3)).a;Tensor<Float>.zeros(Tuple.of(3,2)).b;a.concatenate(Tuple.of(b),0);'),
                      ('join-axis','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.concatenate(Tuple.of(a),2);'),
                      ('stack-axis','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.stack(Tuple.of(a),3);'),
                      ('split-size-sum','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.split(Tuple.of(1,1),1);'),
                      ('split-negative','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.split(Vector<Int> [-1,4],1);'),
                      ('split-axis','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.split(Tuple.of(2),2);'),
                      ('split-index','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.split(Tuple.of(1,2),1).parts;parts.at(2);')]:rows.append((name,'start(){'+body+'23.return;}',177,{}))
    return rows


def function_cases():
    rows=[]
    for dtype,values in [('Int',[17,29]),('Float',[1.5,2.75]),('Bool',['true','false'])]:
        for value in values:
            for returned in (0,7,23,29,255):
                declaration=f'({dtype}.x)make(){{Tensor<{dtype}>.filled(Tuple.of(2,3),x).return;}}'
                body=f'({value}).make().t;t.at(Tuple.of(1,2)).v;'
                if dtype=='Float':body+='"${v:fixed(2)}".console();';wanted=f'{value:.2f}';kind=2
                else:body+='v.console();';wanted=str(value);kind=5 if dtype=='Bool' else 4
                rows.append((f'function-{dtype}-{value}-{returned}',declaration+'start(){'+body+f'{returned}.return;}}',returned,dict(text=wanted.encode(),kinds=[kind])))
        for view in (False,True):
            value=values[0];declaration=f'(Tensor<{dtype}>.x)copy(){{x'+('.permute(Tuple.of(1,0))' if view else '')+'.return;}'
            source=declaration+'start(){'+f'Tensor<{dtype}>.filled(Tuple.of(2,3),{value}).a;a.copy().b;(a.storageId()!=b.storageId()).console();b.axisSize(0).console();23.return;}}'
            rows.append((f'function-copy-{dtype}-{view}',source,23,dict(text=b'true'+(b'3' if view else b'2'),kinds=[5,4])))
        declaration=f'(Tensor<{dtype}>.x)size(Tensor<{dtype}>.y){{(x.elementCount()+y.elementCount()).return;}}'
        source=declaration+'start(){'+f'Tensor<{dtype}>.filled(Tuple.of(2,3),{values[0]}).a;a.size(a).console();23.return;}}'
        rows.append((f'function-borrow-{dtype}',source,23,dict(text=b'12',kinds=[4])))
        declaration=f'({dtype}.x)make(){{Tensor<{dtype}>.filled(Tuple.of(2,3),x).return;}}'
        source=declaration+f'start(){{0.i.mutable;0.total.mutable;while(i<10000){{({values[0]}).make().rank().r;total=total+r;i=i+1;}}total.console();23.return;}}'
        rows.append((f'function-loop-{dtype}',source,23,dict(text=b'20000',kinds=[4],stack_bytes=1048576)))
    source='(Int.a)make(Int.b,Int.c,Int.d,Int.e,Int.f){Tensor<Int>.filled(Tuple.of(2),(a+b+c+d+e+f)).return;}start(){7.make(11,13,17,19,23).t;t.at(Tuple.of(1)).console();23.return;}'
    rows.append(('function-six-arguments',source,23,dict(text=b'90',kinds=[4])))
    source='(Tensor<Float>.a)maximumIndex(){a.argMax(0).return;}start(){Tensor<Float>.filled(Tuple.of(64,64),1.5).a;a.maximumIndex().t;t.at(Tuple.of(63)).console();23.return;}'
    rows.append(('function-large-int-result',source,23,dict(text=b'0',kinds=[4])))
    return rows


def cases():
    rows=[]
    def add(name,body,expected,kinds,returned=23,**options):
        rows.append((name,'start(){'+body+f'{returned}.return;}}',returned,dict(text=expected.encode(),kinds=kinds,**options)))
    for dtype,value,dtype_id in [('Int','17',2),('Float','1.5',3),('Bool','true',1)]:
        shapes=[[],[0],[1],[2,3],[2,0,3],[2,3,4],[8,8]]
        if dtype!='Int':shapes+=[[1]*6,[64,64]]
        for dimensions in shapes:
            count=math.prod(dimensions);prefix=f'Tensor<{dtype}>.filled({shape(dimensions)},{value}).t;'
            text=str(dtype_id)+'0'+str(len(dimensions))+str(count);kinds=[4]*4
            body=prefix+'t.dtype().console();t.device().console();t.rank().console();t.elementCount().console();'
            strides=[math.prod(dimensions[i+1:]) for i in range(len(dimensions))]
            for i,dimension in enumerate(dimensions):
                body+=f't.shape().at({i}).console();t.axisSize({i}).console();t.strides().at({i}).console();'
                text+=str(dimension)*2+str(strides[i]);kinds +=[4]*3
            if count:
                expression=f't.at({shape([d-1 for d in dimensions])})'
                if dtype=='Float':body+='"${'+expression+':fixed(2)}".console();';text+='1.50';kinds+=[2]
                else:body+=expression+'.console();';text+=value;kinds+=[5 if dtype=='Bool' else 4]
            add(f'filled-{dtype}-{dimensions}',body,text,kinds)
            zero='false' if dtype=='Bool' else '0.00' if dtype=='Float' else '0'
            body=f'Tensor<{dtype}>.zeros({shape(dimensions)}).t;t.elementCount().console();';text=str(count);kinds=[4]
            if count:
                expression=f't.at({shape([0]*len(dimensions))})'
                if dtype=='Float':body+='"${'+expression+':fixed(2)}".console();';kinds+=[2]
                else:body+=expression+'.console();';kinds+=[5 if dtype=='Bool' else 4]
                text+=zero
            add(f'zeros-{dtype}-{dimensions}',body,text,kinds)
        for returned in (0,7,23,29,255):
            add(f'return-{dtype}-{returned}',f'Tensor<{dtype}>.filled(Tuple.of(2,3),{value}).t;t.elementCount().console();','6',[4],returned)
        other='29' if dtype=='Int' else '7.25' if dtype=='Float' else 'false'
        body=f'Tensor<{dtype}>.filled(Tuple.of(2,3),{value}).a;Tensor<{dtype}>.filled(Tuple.of(2,3),{other}).b;'
        body+='(a.storageId()!=b.storageId()).console();(a.storageId()==a.storageId()).console();'
        add('identity-'+dtype,body,'truetrue',[5,5])
        # Rank-preserving and rank-removing views must retain backing identity.
        for name,expr,outshape in [('transpose','a.permute(Tuple.of(1,0))',[3,2]),('reshape','a.reshape(Tuple.of(3,2))',[3,2]),
                                   ('select','a.select(0,1)',[3]),('narrow','a.narrow(1,1,2)',[2,2]),
                                   ('slice','a.slice(Tuple.of(1,0,2,2))',[2,2])]:
            body=f'Tensor<{dtype}>.filled(Tuple.of(2,3),{value}).a;'+expr+'.v;'
            body+='(v.storageId()==a.storageId()).console();v.rank().console();v.elementCount().console();'
            wanted='true'+str(len(outshape))+str(math.prod(outshape));kinds=[5,4,4]
            expression=f'v.at({shape([x-1 for x in outshape])})'
            if dtype=='Float':body+='"${'+expression+':fixed(2)}".console();';wanted+='1.50';kinds+=[2]
            else:body+=expression+'.console();';wanted+=value;kinds+=[5 if dtype=='Bool' else 4]
            body+='v.contiguous().c;(c.storageId()!=v.storageId()).console();c.isContiguous().console();';wanted+='truetrue';kinds+=[5,5]
            add(name+'-'+dtype,body,wanted,kinds)
        body=f'Tensor<{dtype}>.filled(Tuple.of(1,3),{value}).a;a.broadcastTo(Tuple.of(2,3)).b;(a.storageId()==b.storageId()).console();b.elementCount().console();'
        add('broadcast-'+dtype,body,'true6',[5,4])
    for dims in ([2,3],[3,2],[4,1]):
        body=f'Vector<Int> {dims}.s;Tensor<Int>.filled(s,29).a;a.axisSize(0).console();a.axisSize(1).console();a.at(Tuple.of(1,0)).console();'
        add('dynamic-shape-'+str(dims),body,str(dims[0])+str(dims[1])+'29',[4]*3)
    for expression,expected in [('a',True),('a.permute(Tuple.of(0,1))',True),('a.permute(Tuple.of(1,0))',False),
                                ('a.select(0,1)',True),('a.select(1,1)',False),('a.narrow(0,1,1)',True),('a.narrow(1,1,2)',False)]:
        add('contiguity-'+expression,'Tensor<Int>.filled(Tuple.of(2,3),17).a;'+expression+'.isContiguous().console();',str(expected).lower(),[5])
    add('reshape-contiguous-view','Vector<Int> [17,29,43,71,83,97].b;Tensor<Int>.fromBuffer(b,Tuple.of(2,3)).a;a.select(0,1).reshape(Tuple.of(1,3)).v;v.at(Tuple.of(0,2)).console();','97',[4])
    add('bound-tuple-shape','Tuple.of(2,3).s;Tensor<Int>.filled(s,17).a;a.elementCount().console();','6',[4])
    add('source-value-changed','Tensor<Int>.filled(Tuple.of(2,3),29).a;a.at(Tuple.of(1,2)).console();','29',[4])
    rows.append(('effects-once','(Int.x)mark(){x.console();x.return;}start(){Vector<Int> [2.mark(),3.mark()].s;Tensor<Int>.filled(s,17.mark()).a;a.at(Vector<Int> [1.mark(),2.mark()]).console();23.return;}',23,dict(kinds=[4]*6,text=b'23171217')))
    for dtype,value in [('Int','17'),('Float','1.5'),('Bool','true')]:
        source=f'start(){{0.i.mutable;0.n.mutable;while(i<10000){{Tensor<{dtype}>.filled(Tuple.of(2,3),{value}).elementCount().k;n=n+k;i=i+1;}}n.console();23.return;}}'
        rows.append(('loop-'+dtype,source,23,dict(kinds=[4],text=b'60000',stack_bytes=1048576)))
    for name,body in [
        ('negative-dimension','Tensor<Float>.zeros(Vector<Int> [-1,2]);'),
        ('dimension-large','Tensor<Float>.zeros(Tuple.of(4097));'),
        ('dimension-int-limit','Tensor<Int>.zeros(Tuple.of(9));'),
        ('product-limit','Tensor<Float>.zeros(Tuple.of(65,65));'),
        ('product-int-limit','Tensor<Int>.zeros(Tuple.of(8,8,2));'),
        ('int-rank-limit','Tensor<Int>.zeros(Tuple.of(1,1,1,1));'),
        ('rank-dynamic-limit','Tensor<Float>.zeros(Vector<Int> [1,1,1,1,1,1,1]);'),
        ('dimension-overflow','Tensor<Float>.zeros(Tuple.of(9223372036854775807,2));'),
        ('at-rank','Tensor<Int>.zeros(Tuple.of(2,3)).a;a.at(Tuple.of(0));'),
        ('at-bounds','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.at(Tuple.of(2,0));'),
        ('axis-bounds','Tensor<Int>.zeros(Tuple.of(2,3)).a;a.axisSize(-1);'),
        ('at-empty','Tensor<Float>.zeros(Tuple.of(0)).a;a.at(Tuple.of(0));'),
        ('permute-duplicate','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.permute(Tuple.of(1,1));'),
        ('reshape-count','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.reshape(Tuple.of(7));'),
        ('broadcast-shape','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.broadcastTo(Tuple.of(4,3));'),
        ('slice-step-zero','Tensor<Float>.zeros(Tuple.of(2,3)).a;a.slice(Tuple.of(1,0,2,0));')]:
        rows.append((name,'start(){'+body+'23.return;}',172 if name in ('add-overflow','multiply-overflow') else 177,{}))
    return rows+buffer_cases()+binary_cases()+selection_cases()+reduction_cases()+algebra_cases()+structural_cases()+function_cases()


def negatives():
    rows=[]
    for name,body in [
        ('dtype','Tensor<Text>.zeros(Tuple.of(2));'),('shape-type','Tensor<Int>.zeros(17);'),
        ('shape-element-type','Tensor<Float>.zeros(Vector<Float> [1.0,2.0]);'),
        ('shape-tuple-type','Tensor<Int>.zeros(Tuple.of(true,2));'),
        ('filled-type','Tensor<Int>.filled(Tuple.of(2),1.5);'),
        ('filled-bool-type','Tensor<Bool>.filled(Tuple.of(2),17);'),
        ('filled-float-type','Tensor<Float>.filled(Tuple.of(2),17);'),
        ('zeros-arity','Tensor<Int>.zeros(Tuple.of(2),0);'),
        ('at-type','Tensor<Int>.zeros(Tuple.of(2)).a;a.at(true);'),
        ('axis-type','Tensor<Int>.zeros(Tuple.of(2)).a;a.axisSize(true);'),
        ('method-arity','Tensor<Int>.zeros(Tuple.of(2)).a;a.rank(1);'),
        ('unknown','Tensor<Int>.zeros(Tuple.of(2)).a;a.missing();'),
    ]:rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('buffer-type','Tensor<Int>.fromBuffer(17,Tuple.of(1));'),
                      ('buffer-dtype','Vector<Float> [1.0,2.0].b;Tensor<Int>.fromBuffer(b,Tuple.of(2));'),
                      ('buffer-stride-type','Vector<Int> [17,29].b;Tensor<Int>.fromBuffer(b,Tuple.of(2),true);'),
                      ('buffer-arity','Vector<Int> [17,29].b;Tensor<Int>.fromBuffer(b);')]:
        rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('buffer-released','start(){Array<Int,2> [17,29].a;a.asSlice().s;s.release();Tensor<Int>.fromBuffer(s,Tuple.of(2));23.return;}','NEBO_USE_AFTER_MOVE'))
    for name,body in [('where-mask-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.where(a,a);'),
                      ('map-result-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.map(wrong);'),
                      ('map-kernel-value','Tensor<Float>.zeros(Tuple.of(2)).a;a.map(17);'),
                      ('bool-buffer-type','Vector<Int> [0,1].v;Tensor<Bool>.fromBuffer(v,Tuple.of(2));')]:
        rows.append((name,'(Float.x)wrong(){17.return;}start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('sum-keep-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.sum(Tuple.of(0),1);'),
                      ('sum-axes-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.sum(true,false);'),
                      ('argmax-axis-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.argMax(true);'),
                      ('all-dtype','Tensor<Float>.zeros(Tuple.of(2)).a;a.all(0);'),
                      ('any-arity','Tensor<Bool>.zeros(Tuple.of(2)).a;a.any();'),
                      ('join-direct-peer','Tensor<Float>.zeros(Tuple.of(2)).a;a.concatenate(a,0);'),
                      ('join-peer-dtype','Tensor<Float>.zeros(Tuple.of(2)).a;Tensor<Int>.zeros(Tuple.of(2)).b;a.concatenate(Tuple.of(b),0);'),
                      ('join-peer-effect','Tensor<Float>.zeros(Tuple.of(2)).a;a.stack(Tuple.of(Tensor<Float>.zeros(Tuple.of(2))),0);'),
                      ('split-size-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.split(true,0);'),
                      ('parts-index-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.split(Tuple.of(1,1),0).p;p.at(true);'),
                      ('pad-value-type','Tensor<Float>.zeros(Tuple.of(2)).a;a.pad(Tuple.of(1,1),17);')]:
        rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('map-effect-interpolation','(Float.x)observe(){7.console();x.return;}start(){Tensor<Float>.filled(Tuple.of(2),1.5).a;"${a.map(observe).rank()}".console();23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    rows.append(('einsum-reserved','start(){Tensor<Float>.zeros(Tuple.of(2,2)).a;a.einsum("ij,jk->ik",Tuple.of(a));23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('status-type' ,'start(){Tensor<Int>.zeros(Tuple.of(2)).return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    return rows


def native_controls(root):
    targets=[ROOT/f'build/tests/rf27-g16/f{i:02d}/tensor_{name}_test' for i,name in enumerate(('contract','core','views','ops','reduce','structural'),1)]
    status,out,err=execute(['ninja','-j2',*[p.relative_to(ROOT) for p in targets]],root,timeout=45)
    if status or err:raise Failure('TENSOR_NATIVE_BUILD:'+repr((status,err)))
    rows=[]
    for p in targets:
        elf(p);result=execute([p],root,runtime=True)
        if result!=(0,b'',b''):raise Failure('TENSOR_NATIVE_CONTROL:'+p.name+':'+repr(result))
        rows.append(dict(id='native-'+p.stem,category='native-control',result='PASS'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-tensor-') as d:
        root=Path(d);rows.extend(native_controls(root))
        for negative,matrix in ((False,cases()),(True,negatives())):
            for number,(name,source,expected,*options) in enumerate(matrix):
                work=root/(('negative-' if negative else 'positive-')+str(number));work.mkdir();path=work/'source.no';path.write_text(source)
                # Edition 1 requires explicit visibility for the optional
                # scientific module in both accepted and rejected programs.
                path.write_text('import "std.scientific" { Tensor; }.scientific;\n'+path.read_text())
                try:proof=reject(path,work,expected) if negative else pipeline(path,work,expected,**options[0]);row=dict(result='PASS',**proof)
                except Failure as error:row=dict(result='FAIL',failure=str(error))
                rows.append(dict(id=name.replace(',','_').replace(' ',''),category='negative' if negative else 'positive',**row))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
