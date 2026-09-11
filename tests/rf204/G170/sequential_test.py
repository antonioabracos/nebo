#!/usr/bin/env python3
"""Real sequential native storage with independent sequence/deque oracles."""
import json
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject

def cases():
    result=[]
    for kind in ('List','Stack','Queue','Deque'):
        for value in (0,7,23,29,255):
            result.append((f'{kind}-return-{value}',f'{kind}<Int>.new().items;{value}.return;',value,{}))
        result.append((kind+'-empty',f'{kind}<Int>.new().items;items.length().return;',0,{}))
    for name,values in (('empty',[]),('one',[53]),('many',[17,29,71]),('changed',[-31,7,59])):
        text=','.join(map(str,values))
        body=f'List<Int>.from([{text}]).items;'
        if not values:
            result.append(('from-'+name,body+'items.length().return;',0,{}))
            continue
        body+=''.join(f'items.at({i}).console();' for i in range(len(values)))+'23.return;'
        result.append(('from-'+name,body,23,{'kinds':[4]*len(values),
                       'text':''.join(map(str,values)).encode()} if values else {}))
    result += [
        ('from-expressions',None,36,{'source':
         '(Int.self)value(){self.console();(self+7).return;}start(){'
         'List<Int>.from([17.value(),29.value()]).items;items.at(1).return;}',
         'kinds':[4,4],'text':b'1729'}),
        ('list-capacity','List<Int>.withCapacity(5).items;items.capacity().return;',5,{}),
        ('list-reserve','List<Int>.from([17,29]).items;items.reserve(7);'
         '(items.capacity()+items.at(1)).return;',38,{}),
        ('list-push','List<Int>.new().items;items.push(17);items.push(71);items.at(1).return;',71,{}),
        ('list-pop','List<Int>.from([17,29,71]).items;items.pop().expect("last").return;',71,{}),
        ('list-get-present','List<Int>.from([17,29]).items;items.get(1).expect("v").return;',29,{}),
        ('list-get-absent','List<Int>.from([17,29]).items;items.get(2).unwrapOr(83).return;',83,{}),
        ('list-insert','List<Int>.from([17,29]).items;items.insert(1,71);items.at(1).return;',71,{}),
        ('list-remove','List<Int>.from([17,29,71]).items;items.remove(1).console();'
         'items.at(1).console();23.return;',23,{'kinds':[4,4],'text':b'2971'}),
        ('list-swap-remove','List<Int>.from([17,29,71]).items;items.swapRemove(0).console();'
         'items.at(0).console();23.return;',23,{'kinds':[4,4],'text':b'1771'}),
        ('list-clear','List<Int>.from([17,29]).items;items.clear();items.length().return;',0,{}),
        ('list-two-live','List<Int>.from([17]).a;List<Int>.from([71]).b;a.push(29);'
         '(a.at(1)+b.at(0)).return;',100,{}),
        ('dict-list','Dict<Int,Int>.new().d;List<Int>.from([17,29]).items;d.insert(17,71);'
         '(d.get(17).expect("v")+items.at(1)).return;',100,{}),
        ('stack-lifo','Stack<Int>.new().s;s.push(17);s.push(29);s.peek().console();'
         's.pop().expect("top").console();s.pop().expect("top").console();23.return;',23,{'kinds':[4,4,4],'text':b'292917'}),
        ('queue-fifo','Queue<Int>.new().q;q.enqueue(17);q.enqueue(29);q.peek().console();'
         'q.dequeue().expect("front").console();q.dequeue().expect("front").console();23.return;',23,{'kinds':[4,4,4],'text':b'171729'}),
        ('deque-ends','Deque<Int>.new().d;d.pushBack(29);d.pushFront(17);d.pushBack(71);'
         'd.popBack().console();d.popFront().console();d.popFront().console();23.return;',23,
         {'kinds':[4,4,4],'text':b'711729'}),
        ('queue-wrap','Queue<Int>.new().q;0.i.mutable;while(i<16){q.enqueue(i);i+=1;}'
         '0.sum.mutable;0.j.mutable;while(j<8){sum+=q.dequeue().expect("front");j+=1;}'
         'while(i<24){q.enqueue(i);i+=1;}while(j<24){sum+=q.dequeue().expect("front");j+=1;}sum.return;',
         sum(range(24))%256,{}),
        ('list-boundary','List<Int>.new().a;0.i.mutable;while(i<16){a.push(i);i+=1;}a.at(15).return;',15,{}),
        ('list-runtime-capacity','List<Int>.new().a;0.i.mutable;while(i<17){a.push(i);i+=1;}23.return;',177,{}),
        ('list-runtime-bounds','List<Int>.new().a;a.at(0).return;',177,{}),
    ]
    for kind,put in (('Stack','push'),('Queue','enqueue'),('Deque','pushBack')):
        result.append((kind+'-clear',f'{kind}<Int>.new().a;a.{put}(17);a.clear();a.length().return;',0,{}))
        result.append((kind+'-two-live',f'{kind}<Int>.new().a;{kind}<Int>.new().b;'
                       f'a.{put}(17);b.{put}(71);(a.length()+b.length()).return;',2,{}))
    values=[29,-17,71]
    for name,expr,oracle in (('add','self+7',lambda x:x+7),('subtract','self-3',lambda x:x-3),
                             ('multiply','self*2',lambda x:x*2)):
        mapped=list(map(oracle,values))
        source='(Int.self)transform(){('+expr+').return;}start(){List<Int>.from([29,-17,71]).a;'
        source+='a.map(transform).b;'+''.join(f'b.at({i}).console();' for i in range(3))+'23.return;}'
        result.append(('map-'+name,None,23,{'source':source,'kinds':[4]*3,
                       'text':''.join(map(str,mapped)).encode()}))
    for method in ('filter','retain'):
        for name,expr,choose in (('greater','self>20',lambda x:x>20),('less','self<20',lambda x:x<20)):
            selected=list(filter(choose,values))
            call='a.filter(choose).b;' if method=='filter' else 'a.retain(choose);'
            owner='b' if method=='filter' else 'a'
            source='(Int.self)choose(){('+expr+').return;}start(){List<Int>.from([29,-17,71]).a;'+call
            source+=f'{owner}.length().console();'+''.join(f'{owner}.at({i}).console();' for i in range(len(selected)))+'23.return;}'
            result.append((method+'-'+name,None,23,{'source':source,'kinds':[4]*(1+len(selected)),
                           'text':(str(len(selected))+''.join(map(str,selected))).encode()}))
    for descending in (False,True):
        ordered=sorted(values,reverse=descending)
        source='(Int.self)order(Int.other){('+('other<=>self' if descending else 'self<=>other')+').return;}'
        source+='start(){List<Int>.from([29,-17,71]).a;a.sort(order);'
        source+=''.join(f'a.at({i}).console();' for i in range(3))+'23.return;}'
        result.append(('sort-'+str(descending),None,23,{'source':source,'kinds':[4]*3,
                       'text':''.join(map(str,ordered)).encode()}))
    result += [
        ('find-present',None,1,{'source':'(Int.self)choose(){(self>20).return;}start(){'
         'List<Int>.from([17,29,71]).a;a.find(choose).expect("index").return;}'}),
        ('find-absent',None,83,{'source':'(Int.self)choose(){(self>80).return;}start(){'
         'List<Int>.from([17,29,71]).a;a.find(choose).unwrapOr(83).return;}'}),
        ('contains-present-absent','List<Int>.from([17,29]).a;a.contains(29).console();'
         'a.contains(71).console();23.return;',23,{'kinds':[5,5],'text':b'truefalse'}),
        ('deduplicate-adjacent','List<Int>.from([17,17,29,17]).a;a.deduplicate();'
         'a.length().console();a.at(2).console();23.return;',23,{'kinds':[4,4],'text':b'317'}),
        ('map-effects-once',None,36,{'source':'(Int.self)transform(){self.console();(self+7).return;}'
         'start(){List<Int>.from([17,29]).a;a.map(transform).b;b.at(1).return;}',
         'kinds':[4,4],'text':b'1729'}),
        ('map-empty',None,0,{'source':'(Int.self)transform(){self.console();(self+7).return;}'
         'start(){List<Int>.new().a;a.map(transform).b;b.length().return;}'}),
        ('list-pop-empty','List<Int>.new().a;a.pop().isNone().console();23.return;',23,
         {'kinds':[5],'text':b'true'}),
        ('stack-pop-empty','Stack<Int>.new().a;a.pop().isNone().console();23.return;',23,
         {'kinds':[5],'text':b'true'}),
        ('queue-dequeue-empty','Queue<Int>.new().a;a.dequeue().isNone().console();23.return;',23,
         {'kinds':[5],'text':b'true'}),
        ('iterator-next','List<Int>.from([17,29]).a;a.iterator().i;i.next().expect("v").return;',17,{}),
        ('iterator-empty','List<Int>.new().a;a.iterator().i;i.next().unwrapOr(83).return;',83,{}),
        ('iterator-exhaustion','List<Int>.from([17]).a;a.iterator().i;i.next();'
         'i.next().isNone().console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('iterator-release','List<Int>.from([17]).a;a.iterator().i;i.release();a.push(29);a.at(1).return;',29,{}),
        ('iterator-scope','List<Int>.from([17]).a;if(true){a.iterator().i;i.next();}'
         'a.push(29);a.at(1).return;',29,{}),
        ('iterator-temporary','List<Int>.from([17]).a;a.iterator().next();a.push(29);a.at(1).return;',29,{}),
        ('iterator-skip-take','List<Int>.from([17,29,71]).a;a.iterator().i;i.skip(1);i.take(1);'
         'i.next().expect("v").return;',29,{}),
        ('iterator-take-zero','List<Int>.from([17,29]).a;a.iterator().i;i.take(0);i.next().unwrapOr(83).return;',83,{}),
        ('iterator-skip-past','List<Int>.from([17,29]).a;a.iterator().i;i.skip(9);i.next().unwrapOr(83).return;',83,{}),
        ('iterator-queue','Queue<Int>.new().a;a.enqueue(17);a.enqueue(29);a.iterator().i;'
         'i.next().expect("v").return;',17,{}),
        ('iterator-stack','Stack<Int>.new().a;a.push(17);a.push(29);a.iterator().i;i.next().expect("v").return;',17,{}),
        ('iterator-deque','Deque<Int>.new().a;a.pushBack(29);a.pushFront(17);a.iterator().i;'
         'i.next().expect("v").return;',17,{}),
        ('iterator-mutable','List<Int>.from([17]).a;a.iteratorMutable().i;i.next().expect("v").return;',17,{}),
        ('iterator-collect','List<Int>.from([17,29,71]).a;a.iterator().i;i.skip(1);i.take(2);'
         'i.collect<List<Int>>().b;i.release();b.at(1).return;',71,{}),
        ('iterator-collect-empty','List<Int>.new().a;a.iterator().i;i.collect<List<Int>>().b;b.length().return;',0,{}),
        ('iterator-collect-independent','List<Int>.from([17,29]).a;a.iterator().i;'
         'i.collect<List<Int>>().b;i.release();a.remove(0);b.at(0).return;',17,{}),
        ('iterator-enumerate','List<Int>.from([17,29]).a;a.iterator().i;i.enumerate();'
         'i.next().expect("pair").p;(p.at(0)+p.at(1)).return;',17,{}),
        ('iterator-enumerate-second','List<Int>.from([17,29]).a;a.iterator().i;i.enumerate();i.next();'
         'i.next().expect("pair").p;(p.at(0)+p.at(1)).return;',30,{}),
        ('iterator-enumerate-skip','List<Int>.from([17,29,71]).a;a.iterator().i;i.skip(1);i.enumerate();'
         'i.next().expect("pair").p;(p.at(0)+p.at(1)).return;',30,{}),
        ('iterator-enumerate-empty','List<Int>.new().a;a.iterator().i;i.enumerate();'
         'i.next().isNone().console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('iterator-enumerate-transition','List<Int>.from([17,29]).a;a.iterator().i;i.next();i.enumerate();'
         'i.next().expect("pair").p;(p.at(0)+p.at(1)).return;',30,{}),
        ('iterator-loop-cleanup','List<Int>.new().a;0.n.mutable;while(n<3){a.iterator().i;'
         'i.next();n+=1;continue;}a.push(71);a.at(0).return;',71,{}),
        ('iterator-break-cleanup','List<Int>.new().a;loop{a.iterator().i;i.next();break;}'
         'a.push(71);a.at(0).return;',71,{}),
    ]
    return result

def negatives():
    result=[]
    for kind,method in (('List','push'),('Stack','push'),('Queue','enqueue'),('Deque','pushBack')):
        result += [
            (kind+'-element-type',f'{kind}<Text>.new().a;23.return;','NEBO_TYPE_MISMATCH'),
            (kind+'-wrong-value',f'{kind}<Int>.new().a;a.{method}(true);23.return;','NEBO_TYPE_MISMATCH'),
            (kind+'-copy',f'{kind}<Int>.new().a;a.b;23.return;','NEBO_COPY_UNIQUE'),
            (kind+'-constructor-arity',f'{kind}<Int>.new(17).a;23.return;','NEBO_TYPE_MISMATCH'),
        ]
    result += [
        ('from-mixed','List<Int>.from([17,true]).a;23.return;','NEBO_TYPE_MISMATCH'),
        ('from-over-limit','List<Int>.from(['+','.join(map(str,range(17)))+']).a;23.return;','NEBO_LIMIT_EXCEEDED'),
        ('from-type','List<Int>.from(17).a;23.return;','NEBO_TYPE_MISMATCH'),
        ('stack-list-method','Stack<Int>.new().a;a.at(0);23.return;','NEBO_TYPE_MISMATCH'),
        ('queue-deque-method','Queue<Int>.new().a;a.pushFront(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('deque-list-method','Deque<Int>.new().a;a.insert(0,17);23.return;','NEBO_TYPE_MISMATCH'),
        ('after-return','List<Int>.new().a;23.return;a.push(17);','NEBO_PARSE_UNEXPECTED_TOKEN'),
        *[(f'list-{method}-arity',f'List<Int>.new().a;a.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('length','capacity','pop','clear','deduplicate')],
        *[(f'list-{method}-type',f'List<Int>.new().a;a.{method}(true);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('reserve','at','get','remove','swapRemove','contains','find','map','filter','retain','sort')],
        ('list-insert-type','List<Int>.new().a;a.insert(0,true);23.return;','NEBO_TYPE_MISMATCH'),
        ('iterator-borrow','List<Int>.new().a;a.iterator().i;a.push(17);23.return;','NEBO_BORROW_CONFLICT'),
        ('iterator-second','List<Int>.new().a;a.iterator().i;a.iterator().j;23.return;','NEBO_BORROW_CONFLICT'),
        ('iterator-copy','List<Int>.new().a;a.iterator().i;i.j;23.return;','NEBO_COPY_UNIQUE'),
        ('iterator-released','List<Int>.new().a;a.iterator().i;i.release();i.next();23.return;','NEBO_USE_AFTER_MOVE'),
        ('iterator-unique-read','List<Int>.new().a;a.iteratorMutable().i;a.length().return;','NEBO_BORROW_CONFLICT'),
        ('iterator-take-type','List<Int>.new().a;a.iterator().i;i.take(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('iterator-skip-type','List<Int>.new().a;a.iterator().i;i.skip(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('iterator-collect-type','List<Int>.new().a;a.iterator().i;i.collect<List<Text>>();23.return;','NEBO_TYPE_MISMATCH'),
        ('iterator-enumerate-conditional','List<Int>.new().a;a.iterator().i;if(true){i.enumerate();}23.return;','NEBO_TYPE_MISMATCH'),
        ('iterator-collect-pair-as-int','List<Int>.new().a;a.iterator().i;i.enumerate();i.collect<List<Int>>();23.return;','NEBO_TYPE_MISMATCH'),
    ]
    return result

def callback_negatives():
    body='start(){List<Int>.from([17,29]).a;a.map(transform);23.return;}'
    return [
        ('map-return-type','(Int.self)transform(){true.return;}'+body,'NEBO_TYPE_MISMATCH'),
        ('map-arity','(Int.self)transform(Int.other){other.return;}'+body,'NEBO_TYPE_MISMATCH'),
        ('filter-return-type','(Int.self)choose(){self.return;}start(){List<Int>.new().a;'
         'a.filter(choose);23.return;}','NEBO_TYPE_MISMATCH'),
        ('sort-return-type','(Int.self)order(Int.other){self.return;}start(){List<Int>.new().a;'
         'a.sort(order);23.return;}','NEBO_TYPE_MISMATCH'),
    ]

def run():
    result=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-sequential-',dir='/tmp') as directory:
        root=Path(directory)
        for name,body,expected,options in cases():
            work=root/name;work.mkdir();source=work/'source.no';options=dict(options)
            source.write_text(options.pop('source',None) or 'start(){'+body+'}')
            try: proof=pipeline(source,work,expected,**options)
            except Failure as error: raise Failure(name+':'+str(error)) from error
            result.append(dict(id=name,category='positive',result='PASS',**proof))
        for name,body,code in negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'}')
            try: proof=reject(source,work,code)
            except Failure as error: raise Failure(name+':'+str(error)) from error
            result.append(dict(id=name,category='negative',result='PASS',**proof))
        for name,body,code in callback_negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text(body)
            try: proof=reject(source,work,code)
            except Failure as error: raise Failure(name+':'+str(error)) from error
            result.append(dict(id=name,category='negative',result='PASS',**proof))
    return dict(cases=result,passed=len(result),total=len(cases())+len(negatives())+len(callback_negatives()))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
