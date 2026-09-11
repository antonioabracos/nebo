#!/usr/bin/env python3
"""Typed data values: independent nullable integer-column observations."""
import json
import tempfile
from pathlib import Path
from harness import pipeline, reject, Failure

def cases():
    result=[]
    for value in (0,7,23,29,255):
        result.append(('column-return-'+str(value),'Column<Int>.from([17,29]).c;'+str(value)+'.return;',value,{}))
    for name,values in [('empty',[]),('one',[71]),('many',[17,29,71]),('changed',[-17,83,7]),('limit',list(range(32)))]:
        base='Column<Int>.from(['+','.join(map(str,values))+']).c;'
        result.append(('column-sum-'+name,base+'c.sum().console();23.return;',23,{'kinds':[4],'text':str(sum(values)).encode()}))
        for method,oracle in [('min',min),('max',max)]:
            result.append(('column-'+method+'-'+name,base+f'c.{method}().console();23.return;',23 if values else 177,
                           {'kinds':[4],'text':str(oracle(values)).encode()} if values else {}))
    result += [
        ('column-prefix','Column<Int> [1,2,3,4].c;c.sum().return;',10,{}),
        ('column-prefix-changed','Column<Int> [17,29,71,83].c;c.sum().return;',200,{}),
        ('column-list','List<Int>.from([17,71]).a;Column<Int>.from(a).c;c.sum().return;',88,{}),
        ('column-list-snapshot','List<Int>.from([17,71]).a;Column<Int>.from(a).c;a.remove(0);c.sum().return;',88,{}),
        ('column-get','Column<Int>.from([17,29,71]).c;c.get(1).expect("cell").return;',29,{}),
        ('column-bounds','Column<Int>.from([17]).c;c.get(1);23.return;',177,{}),
        ('column-negative-index','Column<Int>.from([17]).c;c.get(-1);23.return;',177,{}),
        ('column-no-missing','Column<Int>.from([17,71]).c;c.countMissing().return;',0,{}),
        ('column-sum-overflow','Column<Int>.from([9223372036854775807,1]).c;c.sum();23.return;',177,{}),
        ('column-cast-roundtrip','Column<Int>.from([17,71]).c;c.cast<UInt>().u;u.cast<Int>().v;v.sum().return;',88,{}),
        ('column-cast-identity','Column<Int>.from([-17,71]).c;c.cast<Int>().v;v.sum().return;',54,{}),
        ('column-cast-negative','Column<Int>.from([-17,71]).c;c.cast<UInt>();23.return;',177,{}),
        ('column-uint-get-tag','Column<Int>.from([71]).c;c.cast<UInt>().u;u.get(0).isSome().console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('column-two-live','Column<Int>.from([17]).a;Column<Int>.from([71]).b;(a.sum()+b.sum()).return;',88,{}),
        ('column-composition','Dict<Int,Int>.new().d;d.insert(17,71);Column<Int>.from([17,29]).c;'
         '(d.get(17).expect("v")+c.sum()).return;',117,{}),
    ]
    for mask in (0,1,2,3,5,7):
        values=[17,29,71];source='List<Int>.from([17,29,71]).a;Column<Int>.from(['
        source+=','.join(f'a.get({i if not (mask>>i)&1 else 9})' for i in range(3))+']).c;'
        actual=[v for i,v in enumerate(values) if not (mask>>i)&1]
        bits=[bool((mask>>i)&1) for i in range(3)]
        body=source+'c.countMissing().console();c.sum().console();'
        body+=''.join(f'c.isMissing({i}).console();' for i in range(3))+'23.return;'
        result.append(('column-missing-'+str(mask),body,23,{'kinds':[4,4,5,5,5],
                       'text':(str(sum(bits))+str(sum(actual))+''.join(str(v).lower() for v in bits)).encode()}))
        body=source+'c.fillMissing(83);c.countMissing().console();c.sum().console();23.return;'
        result.append(('column-fill-'+str(mask),body,23,{'kinds':[4,4],
                       'text':('0'+str(sum(actual)+sum(bits)*83)).encode()}))
        body=source+'c.dropMissing().d;d.countMissing().console();d.sum().console();23.return;'
        result.append(('column-drop-'+str(mask),body,23,{'kinds':[4,4],'text':('0'+str(sum(actual))).encode()}))
    nullable='List<Int>.from([17,29,71]).a;Column<Int>.from([a.get(0),a.get(9),a.get(2)]).left;'
    result += [
        ('column-missing-get',nullable+'left.get(1).unwrapOr(83).return;',83,{}),
        ('column-missing-extremes',nullable+'left.min().console();left.max().console();23.return;',23,{'kinds':[4,4],'text':b'1771'}),
        ('column-coalesce',nullable+'Column<Int>.from([7,83,11]).right;left.coalesce(right).out;out.sum().return;',171,{}),
        ('column-coalesce-both-missing',nullable+'Column<Int>.from([a.get(9),a.get(9),a.get(0)]).right;'
         'left.coalesce(right).out;out.countMissing().console();out.sum().console();23.return;',23,{'kinds':[4,4],'text':b'188'}),
        ('column-coalesce-length',nullable+'Column<Int>.from([7]).right;left.coalesce(right);23.return;',177,{}),
        ('column-cast-missing',nullable+'left.cast<UInt>().u;u.countMissing().console();u.get(1).isNone().console();'
         'u.cast<Int>().v;v.sum().console();23.return;',23,{'kinds':[4,5,4],'text':b'1true88'}),
    ]
    for kind,old in [('Event',13),('Flow',17)]:
        for value in (old,29,71):
            result.append((f'{kind}-payload-{value}',f'{kind}<Int> {value}.x;x.value().return;',value,{}))
    for value in (0,7,23,29,255):
        result.append((f'stream-return-{value}',f'Stream<Int>.from([17,71]).s;{value}.return;',value,{}))
    result += [
        ('stream-next','Stream<Int>.from([17,71]).s;s.next().expect("v").return;',17,{}),
        ('stream-next-empty','Stream<Int>.from([]).s;s.next().unwrapOr(83).return;',83,{}),
        ('stream-next-exhausted','Stream<Int>.from([17]).s;s.next();s.next().isNone().console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('stream-from-list','List<Int>.from([17,71]).a;Stream<Int>.from(a).s;s.next();s.next().expect("v").return;',71,{}),
        ('stream-list-snapshot','List<Int>.from([17,71]).a;Stream<Int>.from(a).s;a.remove(0);s.next().expect("v").return;',17,{}),
        ('stream-two-live','Stream<Int>.from([17]).a;Stream<Int>.from([71]).b;'
         '(a.next().expect("v")+b.next().expect("v")).return;',88,{}),
    ]
    return result

def callback_cases():
    result=[]
    emit='(Int.self)emit(){self.console();}'
    for name,values in [('empty',[]),('one',[71]),('many',[17,29,71]),('changed',[-17,7,83]),('limit',list(range(64)))]:
        array=','.join(map(str,values));source=emit+'start(){Stream<Int>.from(['+array+']).s;s.sink(emit).return;}'
        options={'kinds':[4]*len(values),'text':''.join(map(str,values)).encode()} if values else {}
        result.append(('stream-sink-'+name,source,len(values),options))
    for method,body,oracle in [('map','(self+7).return;',lambda values:[v+7 for v in values]),
                               ('filter','(self>20).return;',lambda values:[v for v in values if v>20])]:
        for name,values in [('one',[17]),('many',[17,29,71]),('changed',[-17,7,83])]:
            expected=oracle(values);source=f'(Int.self)step(){{{body}}}'+emit+'start(){Stream<Int>.from(['+','.join(map(str,values))+']).s;'
            source+=f's.{method}(step).out;out.sink(emit).return;}}'
            result.append((f'stream-{method}-{name}',source,len(expected),
                           {'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()} if expected else {}))
    definitions='(Int.self)add(){(self+7).return;}(Int.self)double(){(self*2).return;}(Int.self)keep(){(self>25).return;}'+emit
    for chain,expected in [('map(add).filter(keep)',[36,78]),('filter(keep).map(add)',[36,78]),
                           ('map(add).map(double)',[48,72,156]),('map(double).map(add)',[41,65,149])]:
        source=definitions+'start(){Stream<Int>.from([17,29,71]).s;s.'+chain+'.out;out.sink(emit).return;}'
        result.append(('stream-ordered-'+chain.replace('(','-').replace(')','').replace('.','-'),source,len(expected),
                       {'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    # This boundary distinguishes filter(map(x)) from map(filter(x)).
    for chain,expected in [('map(add).filter(keep)',[27]),('filter(keep).map(add)',[])]:
        source=definitions+'start(){Stream<Int>.from([20]).s;s.'+chain+'.out;out.sink(emit).return;}'
        result.append(('stream-order-boundary-'+chain.replace('(','-').replace(')','').replace('.','-'),source,len(expected),
                       {'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()} if expected else {}))
    result += [
        ('stream-lazy','(Int.self)step(){self.console();(self+7).return;}start(){"ready".console();'
         'Stream<Int>.from([17,71]).s;s.map(step).out;23.return;}',23,{'kinds':[2],'text':b'ready'}),
        ('stream-callback-once','(Int.self)step(){self.console();(self+7).return;}'+emit+
         'start(){Stream<Int>.from([17,71]).s;s.map(step).out;out.sink(emit).return;}',2,{'kinds':[4]*4,'text':b'17247178'}),
        ('stream-independent-builders',definitions+'start(){Stream<Int>.from([17]).s;s.map(add).a;s.map(double).b;'
         'a.sink(emit);b.sink(emit);s.sink(emit);23.return;}',23,{'kinds':[4,4,4],'text':b'243417'}),
        ('stream-remaining-cursor',definitions+'start(){Stream<Int>.from([17,29]).s;s.next();s.map(add).out;out.sink(emit).return;}',1,
         {'kinds':[4],'text':b'36'}),
        ('stream-consume-once',emit+'start(){Stream<Int>.from([17,71]).s;s.sink(emit);s.sink(emit).return;}',0,
         {'kinds':[4,4],'text':b'1771'}),
    ]
    source=definitions+'start(){Stream<Int>.from([17]).s;'
    for i in range(16):source+=f'{"s" if i==0 else "s"+str(i-1)}.map(add).s{i};'
    result.append(('stream-stages-16',source+'s15.next().expect("v").return;}',129,{}))
    result.append(('stream-stages-17',source+'s15.map(add);23.return;}',177,{}))
    return result

def stream_negatives():
    return [
        ('batch-sink-scalar-receiver','(Int.self)emit(){self.console();}start(){Stream<Int>.from([17]).s;s.batch(1).b;b.sink(emit);23.return;}','NEBO_TYPE_MISMATCH'),
        ('batch-sink-return-value','(List<Int>.self)emit(){self.length().return;}start(){Stream<Int>.from([17]).s;s.batch(1).b;b.sink(emit);23.return;}','NEBO_TYPE_MISMATCH'),
        ('batch-sink-extra-argument','(List<Int>.self)emit(Int.extra){extra.console();}start(){Stream<Int>.from([17]).s;s.batch(1).b;b.sink(emit);23.return;}','NEBO_TYPE_MISMATCH'),
        ('stream-sink-batch-receiver','(List<Int>.self)emit(){self.length().console();}start(){Stream<Int>.from([17]).s;s.sink(emit);23.return;}','NEBO_TYPE_MISMATCH'),
        ('batch-size-type','start(){Stream<Int>.from([17]).s;s.batch(true);23.return;}','NEBO_TYPE_MISMATCH'),
        ('batch-size-arity','start(){Stream<Int>.from([17]).s;s.batch();23.return;}','NEBO_TYPE_MISMATCH'),
        ('batch-copy','start(){Stream<Int>.from([17]).s;s.batch(1).b;b.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('batch-option-copy','start(){Stream<Int>.from([17]).s;s.batch(1).b;b.next().v;v.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('stream-map-return-type','(Int.self)step(){true.return;}start(){Stream<Int>.from([17]).s;s.map(step);23.return;}','NEBO_TYPE_MISMATCH'),
        ('stream-filter-return-type','(Int.self)step(){17.return;}start(){Stream<Int>.from([17]).s;s.filter(step);23.return;}','NEBO_TYPE_MISMATCH'),
        ('stream-sink-return-type','(Int.self)step(){17.return;}start(){Stream<Int>.from([17]).s;s.sink(step);23.return;}','NEBO_TYPE_MISMATCH'),
        ('stream-map-arity','(Int.self)step(Int.other){other.return;}start(){Stream<Int>.from([17]).s;s.map(step);23.return;}','NEBO_TYPE_MISMATCH'),
    ]

def schema_cases():
    result=[]
    for status in (0,7,23,29,255):
        result.append((f'schema-return-{status}',f'start(){{Schema.new([Tuple.of("age",Int,false)]).s;{status}.return;}}',status,{}))
    for names in [('age',),('age','score'),('score','age'),('changed','other'),('idade','pontuação'),tuple('field'+str(i) for i in range(8))]:
        fields=','.join('Tuple.of('+json.dumps(name,ensure_ascii=False)+',Int,'+str(bool(i%2)).lower()+')' for i,name in enumerate(names))
        source='start(){Schema.new(['+fields+']).s;';expected='';kinds=[]
        for i,name in enumerate(names):
            source+='s.indexOf('+json.dumps(name,ensure_ascii=False)+').expect("index").console();'
            source+='s.field('+json.dumps(name,ensure_ascii=False)+').f'+str(i)+';'
            source+=f'f{i}.at<0>().console();f{i}.at<1>().console();f{i}.at<2>().console();'
            expected+=str(i)+name+'1'+str(bool(i%2)).lower();kinds += [4,2,4,5]
        source+='23.return;}'
        result.append(('schema-ordered-'+'-'.join(names),source,23,{'kinds':kinds,'text':expected.encode()}))
    prefix='start(){Schema.new([Tuple.of("age",Int,false),Tuple.of("score",Int,true)]).s;'
    result += [
        ('schema-missing-name',prefix+'s.indexOf("absent").isNone().console();23.return;}',23,{'kinds':[5],'text':b'true'}),
        ('schema-field-missing',prefix+'s.field("absent");23.return;}',177,{}),
        ('schema-field-description-length',prefix+'s.field("age").length().return;}',3,{}),
        ('schema-two-live',prefix+'Schema.new([Tuple.of("score",Int,false),Tuple.of("age",Int,true)]).t;'
         's.indexOf("score").expect("v").console();t.indexOf("score").expect("v").console();'
         's.field("score").at<2>().console();t.field("score").at<2>().console();23.return;}',23,
         {'kinds':[4,4,5,5],'text':b'10truefalse'}),
        ('schema-field-snapshot',prefix+'s.field("score").a;s.field("age").b;'
         'a.at<0>().console();b.at<0>().console();23.return;}',23,{'kinds':[2,2],'text':b'scoreage'}),
        ('schema-runtime-name','start(){"score".name;true.nullable;Schema.new([Tuple.of(name,Int,nullable)]).s;'
         's.field(name).at<0>().console();s.field(name).at<2>().console();23.return;}',23,{'kinds':[2,5],'text':b'scoretrue'}),
        ('schema-duplicate-name','start(){Schema.new([Tuple.of("age",Int,false),Tuple.of("age",Int,true)]).s;23.return;}',177,{}),
        ('schema-empty-name','start(){Schema.new([Tuple.of("",Int,false)]).s;23.return;}',177,{}),
        ('schema-name-limit','start(){Schema.new([Tuple.of("'+('a'*128)+'",Int,false)]).s;s.indexOf("'+('a'*128)+'").expect("v").return;}',0,{}),
        ('schema-name-over-limit','start(){Schema.new([Tuple.of("'+('a'*129)+'",Int,false)]).s;23.return;}',177,{}),
    ]
    return result

def schema_negatives():
    return [
        ('schema-no-fields','start(){Schema.new([]).s;23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('schema-over-fields','start(){Schema.new(['+','.join('Tuple.of("field'+str(i)+'",Int,false)' for i in range(9))+']).s;23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('schema-wrong-type','start(){Schema.new([Tuple.of("age",Text,false)]).s;23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-wrong-name','start(){Schema.new([Tuple.of(17,Int,false)]).s;23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-wrong-nullability','start(){Schema.new([Tuple.of("age",Int,17)]).s;23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-field-shape','start(){Schema.new([Tuple.of("age",Int)]).s;23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-argument-type','start(){Schema.new(17).s;23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-copy','start(){Schema.new([Tuple.of("age",Int,false)]).s;s.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('schema-index-name-type','start(){Schema.new([Tuple.of("age",Int,false)]).s;s.indexOf(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-field-name-type','start(){Schema.new([Tuple.of("age",Int,false)]).s;s.field(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('schema-field-projection-bound','start(){Schema.new([Tuple.of("age",Int,false)]).s;s.field("age").at<3>();23.return;}','NEBO_LIMIT_EXCEEDED'),
    ]

def row_cases():
    result=[]
    schema='Schema.new([Tuple.of("age",Int,false),Tuple.of("score",Int,true)]).s;'
    for status in (0,7,23,29,255):
        result.append((f'row-return-{status}','start(){'+schema+f'Row.from(s,[17,71]).r;{status}.return;}}',status,{}))
    for a,b in [(17,71),(-31,53),(29,83)]:
        source='start(){'+schema+f'Row.from(s,[{a},{b}]).r;r.get("age").expect("v").console();r.get("score").expect("v").console();23.return;}}'
        result.append((f'row-values-{a}-{b}',source,23,{'kinds':[4,4],'text':(str(a)+str(b)).encode()}))
    for mask in range(4):
        nullable='Schema.new([Tuple.of("age",Int,true),Tuple.of("score",Int,true)]).s;'
        values=[17,71];source='start(){List<Int>.from([17,71]).a;'+nullable+'Row.from(s,['
        source+=','.join('a.get('+str(i if not ((mask>>i)&1) else 9)+')' for i in range(2))+']).r;'
        source+='r.get("age").unwrapOr(83).console();r.get("score").unwrapOr(89).console();r.toTuple().t;'
        source+='t.at<0>().isNone().console();t.at<1>().isNone().console();23.return;}'
        expected=str(83 if mask&1 else 17)+str(89 if mask&2 else 71)+str(bool(mask&1)).lower()+str(bool(mask&2)).lower()
        result.append(('row-missing-'+str(mask),source,23,{'kinds':[4,4,5,5],'text':expected.encode()}))
    prefix='start(){'+schema+'Row.from(s,[17,71]).r;'
    result += [
        ('row-unknown-name',prefix+'r.get("absent");23.return;}',177,{}),
        ('row-too-few','start(){'+schema+'Row.from(s,[17]);23.return;}',177,{}),
        ('row-too-many','start(){'+schema+'Row.from(s,[17,29,71]);23.return;}',177,{}),
        ('row-empty-values','start(){'+schema+'Row.from(s,[]);23.return;}',177,{}),
        ('row-missing-nonnullable','start(){List<Int>.new().a;'+schema+'Row.from(s,[a.get(0),71]);23.return;}',177,{}),
        ('row-two-live',prefix+'Row.from(s,[29,83]).other;r.get("age").expect("v").console();'
         'other.get("age").expect("v").console();r.get("score").expect("v").console();other.get("score").expect("v").console();23.return;}',
         23,{'kinds':[4]*4,'text':b'17297183'}),
        ('row-tuple-order',prefix+'r.toTuple().t;t.length().console();t.at<0>().expect("v").console();t.at<1>().expect("v").console();23.return;}',23,
         {'kinds':[4,4,4],'text':b'21771'}),
        ('row-tuple-index-bound',prefix+'r.toTuple().t;t.at<2>();23.return;}',177,{}),
        ('row-tuple-two-live',prefix+'r.toTuple().t;Row.from(s,[29,83]).other;other.toTuple().u;'
         't.at<1>().expect("v").console();u.at<1>().expect("v").console();23.return;}',23,{'kinds':[4,4],'text':b'7183'}),
        ('row-project-changed-order',prefix+'r.project(["score","age"]).p;p.toTuple().t;'
         't.at<0>().expect("v").console();t.at<1>().expect("v").console();23.return;}',23,{'kinds':[4,4],'text':b'7117'}),
        ('row-project-subset',prefix+'r.project(["score"]).p;p.toTuple().t;t.length().console();p.get("score").expect("v").console();23.return;}',23,
         {'kinds':[4,4],'text':b'171'}),
        ('row-project-removed-name',prefix+'r.project(["score"]).p;p.get("age");23.return;}',177,{}),
        ('row-project-unknown-name',prefix+'r.project(["absent"]);23.return;}',177,{}),
        ('row-project-duplicate-name',prefix+'r.project(["age","age"]);23.return;}',177,{}),
        ('row-project-composition',prefix+'r.project(["score","age"]).p;p.project(["age"]).q;q.get("age").expect("v").return;}',17,{}),
        ('row-project-missing','start(){List<Int>.new().a;'+schema+'Row.from(s,[17,a.get(0)]).r;'
         'r.project(["score","age"]).p;p.toTuple().t;t.at<0>().isNone().console();t.at<1>().expect("v").console();23.return;}',23,
         {'kinds':[5,4],'text':b'true17'}),
        ('row-values-evaluated-once','(Int.self)value(){self.console();(self+7).return;}start(){'+schema+
         'Row.from(s,[17.value(),71.value()]).r;r.get("age").expect("v").console();r.get("score").expect("v").console();23.return;}',23,
         {'kinds':[4]*4,'text':b'17712478'}),
    ]
    fields=','.join('Tuple.of("field'+str(i)+'",Int,false)' for i in range(8))
    source='start(){Schema.new(['+fields+']).s;Row.from(s,['+','.join(str(17+i*7) for i in range(8))+']).r;r.toTuple().t;'
    source+=''.join(f't.at<{i}>().expect("v").console();' for i in range(8))+'23.return;}'
    result.append(('row-eight-fields',source,23,{'kinds':[4]*8,'text':''.join(str(17+i*7) for i in range(8)).encode()}))
    return result

def row_negatives():
    base='Schema.new([Tuple.of("age",Int,false)]).s;'
    row=base+'Row.from(s,[17]).r;'
    return [
        ('row-schema-type','start(){Row.from(17,[71]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-value-type','start(){'+base+'Row.from(s,[true]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-value-float','start(){'+base+'Row.from(s,[2.5]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-value-list','start(){'+base+'Row.from(s,17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-copy','start(){'+row+'r.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('row-get-name-type','start(){'+row+'r.get(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-project-name-type','start(){'+row+'r.project([17]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-project-argument-type','start(){'+row+'r.project(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-project-empty','start(){'+row+'r.project([]);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('row-to-tuple-arity','start(){'+row+'r.toTuple(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('row-tuple-copy','start(){'+row+'r.toTuple().t;t.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('row-tuple-static-bound','start(){'+row+'r.toTuple().t;t.at<8>();23.return;}','NEBO_LIMIT_EXCEEDED'),
    ]

def table_cases():
    result=[]
    for status in (0,7,23,29,255):
        result.append((f'table-return-{status}','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;'+str(status)+'.return;}',status,{}))
    observe='(Row.self)observe(){self.get("age").expect("v").console();self.get("score").expect("v").console();true.return;}'
    for name,rows in [('empty',[]),('one',[(17,71)]),('many',[(17,83),(29,7),(71,53)]),('changed',[(-31,89),(53,11)]),('limit',[(i,83-i) for i in range(32)])]:
        columns=','.join('Tuple.of("'+key+'",Column<Int>.from(['+','.join(str(row[i]) for row in rows)+']))' for i,key in enumerate(['age','score']))
        base='Table.fromColumns(['+columns+']).t;'
        result.append(('table-dimensions-'+name,'start(){'+base+'t.rowCount().console();t.columnCount().console();23.return;}',23,
                       {'kinds':[4,4],'text':(str(len(rows))+'2').encode()}))
        result.append(('table-values-'+name,observe+'start(){'+base+'t.filter(observe);23.return;}',23,
                       {'kinds':[4]*(len(rows)*2),'text':''.join(str(v) for row in rows for v in row).encode()} if rows else {}))
        for threshold in (20,50):
            selected=[row for row in rows if row[0]>threshold]
            keep='(Row.self)keep(){(self.get("age").expect("v")>'+str(threshold)+').return;}'
            source=keep+observe+'start(){'+base+'t.filter(keep).out;out.filter(observe);out.rowCount().return;}'
            result.append((f'table-filter-{name}-{threshold}',source,len(selected),
                           {'kinds':[4]*(len(selected)*2),'text':''.join(str(v) for row in selected for v in row).encode()} if selected else {}))
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([71,17,29])),Tuple.of("score",Column<Int>.from([83,7,53]))]).t;'
    result += [
        ('table-sort-order',observe+'start(){'+base+'t.sortBy(["age"]).out;out.filter(observe);23.return;}',23,
         {'kinds':[4]*6,'text':b'17729537183'}),
        ('table-sort-changed-key',observe+'start(){'+base+'t.sortBy(["score"]).out;out.filter(observe);23.return;}',23,
         {'kinds':[4]*6,'text':b'17729537183'}),
        ('table-sort-source-independent',observe+'start(){'+base+'t.sortBy(["age"]).out;t.filter(observe);23.return;}',23,
         {'kinds':[4]*6,'text':b'71831772953'}),
        ('table-select-order','(Row.self)observe(){self.toTuple().a;a.at<0>().expect("v").console();a.at<1>().expect("v").console();true.return;}'
         'start(){'+base+'t.select(["score","age"]).out;out.filter(observe);23.return;}',23,
         {'kinds':[4]*6,'text':b'83717175329'}),
        ('table-select-subset','(Row.self)observe(){self.get("score").expect("v").console();true.return;}'
         'start(){'+base+'t.select(["score"]).out;out.filter(observe);out.columnCount().return;}',1,
         {'kinds':[4]*3,'text':b'83753'}),
        ('table-select-sort-compose',observe+'start(){'+base+'t.select(["score","age"]).selected;selected.sortBy(["age"]).out;out.filter(observe);23.return;}',23,
         {'kinds':[4]*6,'text':b'17729537183'}),
        ('table-select-unknown-name','start(){'+base+'t.select(["absent"]);23.return;}',177,{}),
        ('table-select-duplicate-name','start(){'+base+'t.select(["age","age"]);23.return;}',177,{}),
        ('table-sort-unknown-name','start(){'+base+'t.sortBy(["absent"]);23.return;}',177,{}),
        ('table-unequal-lengths','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17])),Tuple.of("score",Column<Int>.from([71,83]))]);23.return;}',177,{}),
        ('table-duplicate-name','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17])),Tuple.of("age",Column<Int>.from([71]))]);23.return;}',177,{}),
        ('table-constructor-snapshot','(Row.self)observe(){self.get("age").expect("v").console();true.return;}'
         '(Row.self)missing(){self.get("age").isNone().console();true.return;}'
         'start(){List<Int>.new().a;Column<Int>.from([a.get(0)]).c;Table.fromColumns([Tuple.of("age",c)]).t;c.fillMissing(83);'
         'Table.fromColumns([Tuple.of("age",c)]).other;t.filter(missing);other.filter(observe);t.rowCount().return;}',1,{'kinds':[5,4],'text':b'true83'}),
        ('table-callback-native-local','(Row.self)observe(){List<Int>.from([17,29]).a;a.iterator().it;it.next().expect("v").console();true.return;}'
         'start(){'+base+'t.filter(observe);23.return;}',23,{'kinds':[4]*3,'text':b'171717'}),
        ('table-filter-trap','(Row.self)bad(){self.get("absent").expect("v");true.return;}start(){'+base+'t.filter(bad);23.return;}',177,{}),
    ]
    for keys in ([29,17,29],[71,7,83],[-31,53,11]):
        scores=[17,71,83];order=sorted(range(3),key=lambda i:keys[i])
        source=observe+'start(){Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(map(str,keys))+'])),Tuple.of("score",Column<Int>.from([17,71,83]))]).t;t.sortBy(["age"]).out;out.filter(observe);23.return;}'
        expected=''.join(str(keys[i])+str(scores[i]) for i in order)
        result.append(('table-sort-metamorphic-'+'-'.join(map(str,keys)),source,23,{'kinds':[4]*6,'text':expected.encode()}))
    for mask in (0,1,2,3,5,7):
        keys=[29,17,29];scores=[17,71,83]
        definitions='(Row.self)observe(){self.get("age").unwrapOr(89).console();self.get("score").expect("v").console();true.return;}'
        source=definitions+'start(){List<Int>.from([29,17,29]).a;Table.fromColumns([Tuple.of("age",Column<Int>.from(['
        source+=','.join('a.get('+str(i if not ((mask>>i)&1) else 9)+')' for i in range(3))+'])),Tuple.of("score",Column<Int>.from([17,71,83]))]).t;'
        source+='t.sortBy(["age"]).out;out.select(["score","age"]).selected;selected.filter(observe);23.return;}'
        order=sorted(range(3),key=lambda i:(bool((mask>>i)&1),keys[i] if not ((mask>>i)&1) else 0))
        expected=''.join(str(89 if ((mask>>i)&1) else keys[i])+str(scores[i]) for i in order)
        result.append(('table-sort-missing-'+str(mask),source,23,{'kinds':[4]*6,'text':expected.encode()}))
    columns=','.join('Tuple.of("field'+str(i)+'",Column<Int>.from([17,29]))' for i in range(8))
    result.append(('table-eight-columns','start(){Table.fromColumns(['+columns+']).t;t.columnCount().return;}',8,{}))
    return result

def table_negatives():
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;'
    return [
        ('table-empty-columns','start(){Table.fromColumns([]);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('table-wrong-name','start(){Table.fromColumns([Tuple.of(17,Column<Int>.from([71]))]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-wrong-column','start(){Table.fromColumns([Tuple.of("age",17)]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-copy','start(){'+base+'t.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('table-select-name-type','start(){'+base+'t.select([17]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-select-empty','start(){'+base+'t.select([]);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('table-sort-name-type','start(){'+base+'t.sortBy([17]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-sort-two-keys','start(){'+base+'t.sortBy(["age","age"]);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('table-row-count-arity','start(){'+base+'t.rowCount(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-column-count-arity','start(){'+base+'t.columnCount(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-filter-receiver-type','(Int.self)keep(){true.return;}start(){'+base+'t.filter(keep);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-filter-result-type','(Row.self)keep(){17.return;}start(){'+base+'t.filter(keep);23.return;}','NEBO_TYPE_MISMATCH'),
        ('table-filter-arity','(Row.self)keep(Int.extra){true.return;}start(){'+base+'t.filter(keep);23.return;}','NEBO_TYPE_MISMATCH'),
    ]

def dataset_cases():
    result=[]
    observe='(Row.self)observe(){self.get("age").unwrapOr(89).console();true.return;}'
    consume='(Table.self)consume(){self.rowCount().console();self.filter(observe);}'
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17,29]))]).a;Table.fromColumns([Tuple.of("age",Column<Int>.from([71]))]).b;Dataset.fromTables([a,b]).d;'
    for status in (0,7,23,29,255):
        result.append((f'dataset-return-{status}','start(){'+base+str(status)+'.return;}',status,{}))
    for name,parts in [('empty',[[]]),('one',[[71]]),('many',[[17,29],[71]]),('changed',[[-31],[53,89]]),('eight',[[i*7+17] for i in range(8)]),('row-limit',[list(range(32)) for _ in range(8)])]:
        # The 256-row dataset exceeds the Console's 256-node document budget
        # if every cell and partition count is published. Observe each tail
        # value plus every partition's full row count within that separate limit.
        observer=observe if name!='row-limit' else '(Row.self)observe(){self.get("age").expect("v").v;if(v>=30){v.console();}true.return;}'
        tables=[];source=observer+consume+'start(){'
        for i,values in enumerate(parts):
            source+='Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(map(str,values))+']))]).t'+str(i)+';';tables.append('t'+str(i))
        source+='Dataset.fromTables(['+','.join(tables)+']).d;d.scan().s;s.sink(consume).console();d.partitionCount().return;}'
        expected=[]
        for part in parts:expected += [len(part),*(part if name!='row-limit' else [v for v in part if v>=30])]
        expected.append(len(parts))
        result.append(('dataset-scan-'+name,source,len(parts),{'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    result += [
        ('dataset-schema','start(){'+base+'d.schema().s;s.field("age").at<0>().console();s.indexOf("age").expect("v").console();23.return;}',23,
         {'kinds':[2,4],'text':b'age0'}),
        ('dataset-schema-independent','start(){'+base+'d.schema().s;Schema.new([Tuple.of("other",Int,false)]).other;'
         's.field("age").at<0>().console();other.field("other").at<0>().console();23.return;}',23,{'kinds':[2,2],'text':b'ageother'}),
        ('dataset-schema-mismatch','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).a;'
         'Table.fromColumns([Tuple.of("score",Column<Int>.from([71]))]).b;Dataset.fromTables([a,b]);23.return;}',177,{}),
        ('dataset-schema-order-mismatch','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17])),Tuple.of("score",Column<Int>.from([71]))]).a;'
         'a.select(["score","age"]).b;Dataset.fromTables([a,b]);23.return;}',177,{}),
        ('dataset-scan-next',observe+'start(){'+base+'d.scan().s;s.next().expect("batch").t;t.filter(observe);s.next().expect("batch").u;'
         'u.filter(observe);s.next().isNone().console();23.return;}',23,{'kinds':[4,4,4,5],'text':b'172971true'}),
        ('dataset-scan-two-live',observe+'start(){'+base+'d.scan().s;d.scan().q;s.next().expect("batch").t;q.next().expect("batch").u;'
         't.filter(observe);u.filter(observe);23.return;}',23,{'kinds':[4]*4,'text':b'17291729'}),
        ('dataset-scan-sink-consumed',observe+consume+'start(){'+base+'d.scan().s;s.sink(consume);s.sink(consume).return;}',0,
         {'kinds':[4]*5,'text':b'21729171'}),
        ('dataset-scan-sink-remainder',observe+consume+'start(){'+base+'d.scan().s;s.next();s.sink(consume).return;}',1,
         {'kinds':[4,4],'text':b'171'}),
        ('dataset-scan-option-consumed','start(){'+base+'d.scan().s;s.next().v;v.expect("batch").t;v.isNone().console();t.rowCount().return;}',2,
         {'kinds':[5],'text':b'true'}),
        ('dataset-scan-option-twice','start(){'+base+'d.scan().s;s.next().v;v.expect("batch");v.expect("again");23.return;}',177,{}),
        ('dataset-scan-lazy',observe+consume+'start(){'+base+'d.scan().s;"ready".console();23.return;}',23,{'kinds':[2],'text':b'ready'}),
        ('dataset-scan-callback-trap','(Table.self)bad(){self.select(["absent"]);}start(){'+base+'d.scan().s;s.sink(bad);23.return;}',177,{}),
        ('dataset-scan-missing',observe+consume+'start(){List<Int>.new().a;Table.fromColumns([Tuple.of("age",Column<Int>.from([17,a.get(0)]))]).t;'
         'Dataset.fromTables([t]).d;d.scan().s;s.sink(consume).return;}',1,{'kinds':[4]*3,'text':b'21789'}),
    ]
    return result

def collect_cases():
    result=[]
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17,29]))]).a;Table.fromColumns([Tuple.of("age",Column<Int>.from([71]))]).b;Dataset.fromTables([a,b]).d;'
    for status in (0,7,23,29,255):
        result.append((f'collect-return-{status}','start(){'+base+'d.collect().rows;rows.at(2).get("age").expect("v").console();'+str(status)+'.return;}',status,{'kinds':[4],'text':b'71'}))
    for count in (0,1,3,31,32,33,255,256):
        values=[17+13*i for i in range(count)]
        parts=[values[i:i+32] for i in range(0,count,32)] or [[]]
        source='start(){';names=[]
        for i,part in enumerate(parts):
            names.append('t'+str(i));source+='Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(map(str,part))+']))]).'+names[-1]+';'
        source+='Dataset.fromTables(['+','.join(names)+']).d;d.collect().rows;rows.length().console();0.i.mutable;0.sum.mutable;0.ordered.mutable;'
        source+='while(i<rows.length()){rows.at(i).get("age").expect("cell").v;sum+=v;ordered+=(i+1)*v;i+=1;}sum.console();ordered.console();'
        expected=[count,sum(values),sum((i+1)*v for i,v in enumerate(values))]
        if values:
            source+='rows.at(0).get("age").expect("first").console();rows.at('+str(count-1)+').get("age").expect("last").console();';expected += [values[0],values[-1]]
        source+='23.return;}'
        result.append((f'collect-count-{count}',source,23,{'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    result += [
        ('collect-order','start(){'+base+'d.collect().rows;0.i.mutable;while(i<3){rows.next().expect("row").get("age").expect("v").console();i+=1;}rows.next().isNone().console();23.return;}',23,{'kinds':[4,4,4,5],'text':b'172971true'}),
        ('collect-two-live','start(){'+base+'Dataset.fromTables([b,a]).other;d.collect().left;other.collect().right;left.at(0).get("age").expect("v").console();right.at(0).get("age").expect("v").console();23.return;}',23,{'kinds':[4,4],'text':b'1771'}),
        ('collect-result-independent','start(){'+base+'d.collect().left;d.collect().right;left.next();right.next().expect("r").get("age").expect("v").console();left.next().expect("r").get("age").expect("v").console();23.return;}',23,{'kinds':[4,4],'text':b'1729'}),
        ('collect-row-independent','start(){'+base+'d.collect().rows;rows.at(0).first;rows.at(2).last;last.project(["age"]).p;first.get("age").expect("v").console();p.get("age").expect("v").console();23.return;}',23,{'kinds':[4,4],'text':b'1771'}),
        ('collect-option-consumed','start(){'+base+'d.collect().rows;rows.next().v;v.expect("row").r;v.isNone().console();r.get("age").expect("v").return;}',17,{'kinds':[5],'text':b'true'}),
        ('collect-option-twice','start(){'+base+'d.collect().rows;rows.next().v;v.expect("row");v.expect("again");23.return;}',177,{}),
        ('collect-bound','start(){'+base+'d.collect().rows;rows.at(3);23.return;}',177,{}),
        ('collect-negative-index','start(){'+base+'d.collect().rows;rows.at(-1);23.return;}',177,{}),
        ('collect-empty-next','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([]))]).t;Dataset.fromTables([t]).d;d.collect().rows;rows.next().isNone().console();23.return;}',23,{'kinds':[5],'text':b'true'}),
        ('collect-block-cleanup','start(){'+base+'0.i.mutable;while(i<3){d.collect().rows;rows.next().expect("row").get("age").expect("v").console();i+=1;}d.partitionCount().return;}',2,{'kinds':[4]*3,'text':b'171717'}),
        ('collect-early-return','(Int.self)read(){'+base+'d.collect().rows;rows.at(self).get("age").expect("v").return;}start(){2.read().console();0.read().return;}',17,{'kinds':[4],'text':b'71'}),
        ('collect-break-continue','start(){'+base+'0.i.mutable;while(i<3){d.collect().rows;i+=1;if(i==1){continue;}rows.at(2).get("age").expect("v").console();break;}d.partitionCount().return;}',2,{'kinds':[4],'text':b'71'}),
    ]
    for mask in (0,1,2,3,5,7):
        values=[17,29,71];source='start(){List<Int>.from([17,29,71]).a;Table.fromColumns([Tuple.of("age",Column<Int>.from(['
        source+=','.join('a.get('+str(9 if (mask>>i)&1 else i)+')' for i in range(3))+']))]).t;Dataset.fromTables([t]).d;d.collect().rows;'
        source+=''.join('rows.at('+str(i)+').get("age").unwrapOr(83).console();' for i in range(3))+'23.return;}'
        expected=[83 if (mask>>i)&1 else v for i,v in enumerate(values)]
        result.append(('collect-missing-'+str(mask),source,23,{'kinds':[4]*3,'text':''.join(map(str,expected)).encode()}))
    return result

def repartition_cases():
    result=[]
    counter='(Table.self)count(){self.rowCount().console();}'
    for count in (0,1,3,17,65,256):
        values=[17+13*i for i in range(count)]
        parts=[values[i:i+32] for i in range(0,count,32)] or [[]]
        source=counter+'start(){';names=[]
        for i,part in enumerate(parts):
            names.append('t'+str(i));source+='Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(map(str,part))+']))]).'+names[-1]+';'
        source+='Dataset.fromTables(['+','.join(names)+']).d;'
        for size in (1,7,32):
            sizes=[len(values[i:i+size]) for i in range(0,count,size)] or [0]
            body=source+'d.repartition('+str(size)+').out;'
            if len(sizes)>8:
                result.append((f'repartition-{count}-{size}',body+'23.return;}',177,{}));continue
            body+='out.scan().s;s.sink(count);out.collect().rows;0.i.mutable;0.ordered.mutable;'
            body+='while(i<rows.length()){ordered+=(i+1)*rows.at(i).get("age").expect("v");i+=1;}ordered.console();d.partitionCount().console();23.return;}'
            expected=[*sizes,sum((i+1)*v for i,v in enumerate(values)),len(parts)]
            result.append((f'repartition-{count}-{size}',body,23,{'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17,29,71]))]).t;Dataset.fromTables([t]).d;'
    result += [
        ('repartition-two-live',counter+'start(){'+base+'d.repartition(1).a;d.repartition(2).b;a.scan().s;b.scan().q;s.sink(count);q.sink(count);d.partitionCount().return;}',1,{'kinds':[4]*5,'text':b'11121'}),
        ('repartition-result-schema','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17,29])),Tuple.of("rank",Column<Int>.from([71,83]))]).t;Dataset.fromTables([t]).d;'
         'd.repartition(1).out;out.collect().rows;rows.at(1).r;r.get("age").expect("v").console();r.get("rank").expect("v").console();r.toTuple().at<0>().expect("v").console();23.return;}',23,{'kinds':[4]*3,'text':b'298329'}),
        ('cache-blocks-repartition','start(){'+base+'d.cache(1);d.repartition(2);23.return;}',177,{}),
        ('cache-disable','start(){'+base+'d.cache(1);d.cache(0);d.repartition(2).out;out.partitionCount().return;}',2,{}),
        ('cache-collect','start(){'+base+'d.cache(1);d.collect().rows;rows.at(2).get("age").expect("v").return;}',71,{}),
        ('cache-scan',counter+'start(){'+base+'d.cache(1);d.scan().s;s.sink(count).return;}',1,{'kinds':[4],'text':b'3'}),
        ('cache-two-live','start(){'+base+'Dataset.fromTables([t]).other;d.cache(1);other.repartition(1).out;out.partitionCount().return;}',3,{}),
        ('repartition-explicit-return','start(){'+base+'d.repartition(1);7.return;}',7,{}),
    ]
    for mask in (0,1,3,5,7):
        source='start(){List<Int>.from([17,29,71]).a;Table.fromColumns([Tuple.of("age",Column<Int>.from(['
        source+=','.join('a.get('+str(9 if (mask>>i)&1 else i)+')' for i in range(3))+']))]).t;Dataset.fromTables([t]).d;d.repartition(2).out;out.collect().rows;'
        source+=''.join('rows.at('+str(i)+').get("age").unwrapOr(83).console();' for i in range(3))+'23.return;}'
        expected=[83 if (mask>>i)&1 else v for i,v in enumerate([17,29,71])]
        result.append(('repartition-missing-'+str(mask),source,23,{'kinds':[4]*3,'text':''.join(map(str,expected)).encode()}))
    for size in (-1,0,33):result.append(('repartition-invalid-'+str(size),'start(){'+base+'d.repartition('+str(size)+');23.return;}',177,{}))
    for policy in (-1,2):result.append(('cache-invalid-'+str(policy),'start(){'+base+'d.cache('+str(policy)+');23.return;}',177,{}))
    return result

def group_cases():
    result=[]
    observe='(Row.self)observe(){self.get("key").unwrapOr(89).console();self.get("value").expect("v").console();true.return;}'
    consume='(Table.self)consume(){self.rowCount().console();self.filter(observe);}'
    for name,keys in [('empty',[]),('one',[17]),('many',[29,17,29]),('changed',[71,7,71,83]),('signed',[-31,17,-31]),('limit',list(range(32))),('same',[17]*32)]:
        values=[71+13*i for i in range(len(keys))]
        source=observe+consume+'start(){Table.fromColumns([Tuple.of("key",Column<Int>.from(['+','.join(map(str,keys))+'])),Tuple.of("value",Column<Int>.from(['+','.join(map(str,values))+']))]).t;t.groupBy(["key"]).g;g.length().console();g.sink(consume);g.next().isNone().console();23.return;}'
        groups={}
        for k,v in zip(keys,values):groups.setdefault(k,[]).append(v)
        expected=[len(groups)]
        for k,vs in groups.items():
            expected.append(len(vs))
            for v in vs:expected.extend([k,v])
        result.append(('group-'+name,source,23,{'kinds':[4]*len(expected)+[5],'text':(''.join(map(str,expected))+'true').encode()}))
    base='Table.fromColumns([Tuple.of("key",Column<Int>.from([29,17,29])),Tuple.of("value",Column<Int>.from([71,83,97]))]).t;'
    result += [
        ('group-next',observe+'start(){'+base+'t.groupBy(["key"]).g;g.next().expect("group").a;a.filter(observe);g.next().expect("group").b;b.filter(observe);23.return;}',23,{'kinds':[4]*6,'text':b'297129971783'}),
        ('group-two-live','start(){'+base+'t.groupBy(["key"]).a;t.groupBy(["value"]).b;a.length().console();b.length().console();23.return;}',23,{'kinds':[4,4],'text':b'23'}),
        ('group-independent-cursor',observe+'start(){'+base+'t.groupBy(["key"]).a;t.groupBy(["key"]).b;a.next();b.next().expect("group").first;first.filter(observe);23.return;}',23,{'kinds':[4]*4,'text':b'29712997'}),
        ('group-retained-table',observe+'start(){'+base+'t.groupBy(["key"]).g;g.next().expect("group").a;g.next().expect("group").b;a.filter(observe);23.return;}',23,{'kinds':[4]*4,'text':b'29712997'}),
        ('group-sink-cursor',observe+consume+'start(){'+base+'t.groupBy(["key"]).g;g.next();g.sink(consume).return;}',1,{'kinds':[4]*3,'text':b'11783'}),
        ('group-empty-expect','start(){Table.fromColumns([Tuple.of("key",Column<Int>.from([]))]).t;t.groupBy(["key"]).g;g.next().expect("group");23.return;}',177,{}),
        ('group-missing-name','start(){'+base+'t.groupBy(["absent"]);23.return;}',177,{}),
        ('group-normal-cleanup','start(){'+base+'0.i.mutable;while(i<3){t.groupBy(["key"]).g;g.length().console();i+=1;}23.return;}',23,{'kinds':[4]*3,'text':b'222'}),
    ]
    for mask in (0,1,2,3,5,7):
        keys=[29,17,29];values=[71,83,97]
        source=observe+consume+'start(){List<Int>.from([29,17,29]).a;Table.fromColumns([Tuple.of("key",Column<Int>.from(['
        source+=','.join('a.get('+str(9 if (mask>>i)&1 else i)+')' for i in range(3))+'])),Tuple.of("value",Column<Int>.from([71,83,97]))]).t;t.groupBy(["key"]).g;g.length().console();g.sink(consume);23.return;}'
        groups={}
        for i,(k,v) in enumerate(zip(keys,values)):
            if not (mask>>i)&1:groups.setdefault(k,[]).append(v)
        expected=[len(groups)]
        for k,vs in groups.items():
            expected.append(len(vs))
            for v in vs:expected.extend([k,v])
        result.append(('group-missing-'+str(mask),source,23,{'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    return result

def join_cases():
    result=[]
    observe='(Row.self)observe(){self.get("key").unwrapOr(127).console();self.get("age").expect("v").console();self.get("score").unwrapOr(131).console();true.return;}'
    def table(name,keys,values,value_name):
        return 'Table.fromColumns([Tuple.of("key",Column<Int>.from(['+','.join(map(str,keys))+'])),Tuple.of("'+value_name+'",Column<Int>.from(['+','.join(map(str,values))+']))]).'+name+';'
    cases=[('empty',[],[]),('left-empty',[],[17]),('right-empty',[17],[]),('one',[17],[17]),
           ('many',[17,29,17],[17,17,7]),('changed',[71,7,83],[7,83,83]),('signed',[-31,17],[-31,17]),
           ('unmatched',[17,29],[71,83]),('limit',[17]*8,[17]*4),('over-limit',[17]*9,[17]*4)]
    for name,left,right in cases:
        ages=[71+13*i for i in range(len(left))];scores=[103+17*i for i in range(len(right))]
        base=table('left',left,ages,'age')+table('right',right,scores,'score')
        for kind in (1,2):
            rows=[]
            for k,v in zip(left,ages):
                matches=[w for key,w in zip(right,scores) if k==key]
                if kind==2 and not matches:matches=[131]
                rows.extend((k,v,w) for w in matches)
            source=observe+'start(){'+base+'left.join(right,["key"],'+str(kind)+').out;'
            if len(rows)>32:result.append((f'join-{name}-{kind}',source+'23.return;}',177,{}));continue
            source+='out.rowCount().console();out.columnCount().console();out.filter(observe);23.return;}'
            expected=[len(rows),3,*[v for row in rows for v in row]]
            result.append((f'join-{name}-{kind}',source,23,{'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()}))
    base=table('left',[17,29],[71,83],'age')+table('right',[17],[103],'score')
    result += [
        ('join-kind-once','(Int.self)kind(){self.console();self.return;}'+observe+'start(){'+base+'left.join(right,["key"],2.kind()).out;out.filter(observe);23.return;}',23,{'kinds':[4]*7,'text':b'217711032983131'}),
        ('join-two-live',observe+'start(){'+base+'left.join(right,["key"],1).a;left.join(right,["key"],2).b;a.filter(observe);b.rowCount().console();a.rowCount().console();23.return;}',23,{'kinds':[4]*5,'text':b'177110321'}),
        ('join-explicit-return','start(){'+base+'left.join(right,["key"],1);7.return;}',7,{}),
        ('join-source-preserved','start(){'+base+'left.join(right,["key"],2).out;left.rowCount().console();right.rowCount().console();out.rowCount().return;}',2,{'kinds':[4,4],'text':b'21'}),
        ('join-missing-key-name','start(){'+base+'left.join(right,["absent"],1);23.return;}',177,{}),
        ('join-duplicate-nonkey','start(){'+table('left',[17],[71],'age')+table('right',[17],[103],'age')+'left.join(right,["key"],1);23.return;}',177,{}),
    ]
    for kind in (0,3,-1):result.append(('join-kind-invalid-'+str(kind),'start(){'+base+'left.join(right,["key"],'+str(kind)+');23.return;}',177,{}))
    for left_missing,right_missing in [(False,False),(True,False),(False,True),(True,True)]:
        for kind in (1,2):
            key_left='a.get(9)' if left_missing else 'a.get(0)';key_right='a.get(9)' if right_missing else 'a.get(0)'
            source=observe+'start(){List<Int>.from([17]).a;'+table('left',[key_left],[71],'age')+table('right',[key_right],[103],'score')
            source+='left.join(right,["key"],'+str(kind)+').out;out.filter(observe);out.rowCount().return;}'
            matched=not left_missing and not right_missing;rows=[(127 if left_missing else 17,71,103 if matched else 131)] if matched or kind==2 else []
            values=[v for row in rows for v in row]
            result.append((f'join-missing-{int(left_missing)}-{int(right_missing)}-{kind}',source,len(rows),{'kinds':[4]*len(values),'text':''.join(map(str,values)).encode()} if values else {}))
    return result

def quality_cases():
    result=[]
    observe='(Row.self)observe(){self.get("age").unwrapOr(127).console();self.get("score").unwrapOr(131).console();true.return;}'
    for missing_age,missing_score in [(0,0),(1,0),(0,2),(3,5),(7,7)]:
        for nullable in (0,1,2,3):
            source=observe+'start(){List<Int>.from([17,29,71]).a;List<Int>.from([83,97,103]).b;Table.fromColumns([Tuple.of("age",Column<Int>.from(['
            source+=','.join('a.get('+str(9 if (missing_age>>i)&1 else i)+')' for i in range(3))+'])),Tuple.of("score",Column<Int>.from(['
            source+=','.join('b.get('+str(9 if (missing_score>>i)&1 else i)+')' for i in range(3))+']))]).t;'
            source+='Schema.new([Tuple.of("age",Int,'+str(bool(nullable&1)).lower()+'),Tuple.of("score",Int,'+str(bool(nullable&2)).lower()+')]).rules;'
            source+='t.validate(rules).console();t.invalidRows().bad;bad.rowCount().console();bad.filter(observe);t.rowCount().return;}'
            mask=(missing_age if not nullable&1 else 0)|(missing_score if not nullable&2 else 0)
            rows=[(127 if (missing_age>>i)&1 else age,131 if (missing_score>>i)&1 else score) for i,(age,score) in enumerate(zip([17,29,71],[83,97,103])) if (mask>>i)&1]
            values=[len(rows),*[v for row in rows for v in row]]
            result.append((f'quality-mask-{missing_age}-{missing_score}-{nullable}',source,3,{'kinds':[5]+[4]*len(values),'text':(str(not mask).lower()+''.join(map(str,values))).encode()}))
    base='List<Int>.new().empty;Table.fromColumns([Tuple.of("age",Column<Int>.from([empty.get(0),empty.get(0)]))]).t;Schema.new([Tuple.of("age",Int,false)]).strict;Schema.new([Tuple.of("age",Int,true)]).relaxed;'
    result += [
        ('quality-default','start(){'+base+'t.invalidRows().bad;bad.rowCount().return;}',0,{}),
        ('quality-repeated','start(){'+base+'t.validate(strict).console();t.invalidRows().bad;t.validate(relaxed).console();t.invalidRows().ok;bad.rowCount().console();ok.rowCount().return;}',0,{'kinds':[5,5,4],'text':b'falsetrue2'}),
        ('quality-source-missing-preserved','start(){'+base+'t.validate(strict);t.validate(relaxed);t.validate(strict).console();t.invalidRows().bad;bad.rowCount().return;}',2,{'kinds':[5],'text':b'false'}),
        ('quality-two-live','start(){'+base+'Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).other;t.validate(strict);other.validate(strict).console();other.invalidRows().good;t.invalidRows().bad;good.rowCount().console();bad.rowCount().return;}',2,{'kinds':[5,4],'text':b'true0'}),
        ('quality-schema-name','start(){'+base+'Schema.new([Tuple.of("other",Int,false)]).wrong;t.validate(wrong);23.return;}',177,{}),
        ('quality-schema-count','start(){'+base+'Schema.new([Tuple.of("age",Int,false),Tuple.of("other",Int,false)]).wrong;t.validate(wrong);23.return;}',177,{}),
        ('quality-empty','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([]))]).t;Schema.new([Tuple.of("age",Int,false)]).rules;t.validate(rules).console();t.invalidRows().bad;bad.rowCount().return;}',0,{'kinds':[5],'text':b'true'}),
        ('quality-return','start(){'+base+'t.validate(strict);7.return;}',7,{}),
    ]
    source='start(){List<Int>.new().empty;Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(['empty.get(0)']*32)+']))]).t;Schema.new([Tuple.of("age",Int,false)]).rules;t.validate(rules).console();t.invalidRows().bad;bad.rowCount().return;}'
    result.append(('quality-limit-32',source,32,{'kinds':[5],'text':b'false'}))
    return result

def quality_negatives():
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;'
    return [(name,'start(){'+base+expr+';23.return;}','NEBO_TYPE_MISMATCH') for name,expr in [
        ('quality-constraints-type','t.validate(17)'),('quality-constraints-arity','t.validate()'),
        ('quality-invalid-rows-arity','t.invalidRows(17)')]]

def join_negatives():
    base='Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).a;Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).b;'
    return [(name,'start(){'+base+expr+';23.return;}','NEBO_TYPE_MISMATCH') for name,expr in [
        ('join-other-type','a.join(17,["key"],1)'),('join-keys-type','a.join(b,[17],1)'),('join-bare-key','a.join(b,"key",1)'),
        ('join-keys-empty','a.join(b,[],1)'),('join-keys-multiple','a.join(b,["key","age"],1)'),('join-kind-type','a.join(b,["key"],true)'),('join-arity','a.join(b,["key"])')]]

def group_negatives():
    base='Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).t;'
    result=[(name,'start(){'+base+expr+';23.return;}','NEBO_TYPE_MISMATCH') for name,expr in [
        ('group-key-type','t.groupBy([17])'),('group-key-arity','t.groupBy([])'),('group-key-two','t.groupBy(["key","other"])'),
        ('group-bare-key','t.groupBy("key")'),('group-method-arity','t.groupBy()')]]
    result.append(('group-copy','start(){'+base+'t.groupBy(["key"]).g;g.copy;23.return;}','NEBO_COPY_UNIQUE'))
    result.append(('group-sink-type','(Int.self)consume(){self.console();}start(){'+base+'t.groupBy(["key"]).g;g.sink(consume);23.return;}','NEBO_TYPE_MISMATCH'))
    return result

def repartition_negatives():
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;Dataset.fromTables([t]).d;'
    return [(name,'start(){'+base+expr+';23.return;}','NEBO_TYPE_MISMATCH') for name,expr in [
        ('repartition-size-type','d.repartition(true)'),('repartition-arity','d.repartition()'),
        ('cache-policy-type','d.cache(true)'),('cache-arity','d.cache()')]]

def collect_negatives():
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;Dataset.fromTables([t]).d;d.collect().rows;'
    return [
        ('collect-arity','start(){'+base+'d.collect(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('collect-copy','start(){'+base+'rows.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('collect-at-type','start(){'+base+'rows.at(true);23.return;}','NEBO_TYPE_MISMATCH'),
        ('collect-next-arity','start(){'+base+'rows.next(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('collect-option-copy','start(){'+base+'rows.next().o;o.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('collect-row-not-int','start(){'+base+'rows.at(0).return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
        ('collect-count-257','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from(['+','.join(map(str,range(32)))+']))]).t;Table.fromColumns([Tuple.of("age",Column<Int>.from([71]))]).last;Dataset.fromTables(['+','.join(['t']*8+['last'])+']).d;d.collect();23.return;}','NEBO_LIMIT_EXCEEDED'),
    ]

def dataset_negatives():
    base='Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;Dataset.fromTables([t]).d;'
    return [
        ('dataset-empty-parts','start(){Dataset.fromTables([]);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('dataset-over-parts','start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17]))]).t;Dataset.fromTables(['+','.join(['t']*9)+']);23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('dataset-part-type','start(){Dataset.fromTables([17]);23.return;}','NEBO_TYPE_MISMATCH'),
        ('dataset-copy','start(){'+base+'d.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('dataset-schema-arity','start(){'+base+'d.schema(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('dataset-partition-count-arity','start(){'+base+'d.partitionCount(17);23.return;}','NEBO_TYPE_MISMATCH'),
        ('dataset-scan-copy','start(){'+base+'d.scan().s;s.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('dataset-scan-option-copy','start(){'+base+'d.scan().s;s.next().v;v.copy;23.return;}','NEBO_COPY_UNIQUE'),
        ('dataset-sink-receiver-type','(Int.self)consume(){self.console();}start(){'+base+'d.scan().s;s.sink(consume);23.return;}','NEBO_TYPE_MISMATCH'),
        ('dataset-sink-return-type','(Table.self)consume(){17.return;}start(){'+base+'d.scan().s;s.sink(consume);23.return;}','NEBO_TYPE_MISMATCH'),
        ('dataset-sink-extra-argument','(Table.self)consume(Int.extra){extra.console();}start(){'+base+'d.scan().s;s.sink(consume);23.return;}','NEBO_TYPE_MISMATCH'),
    ]

def batch_cases():
    result=[]
    for name,values in [('empty',[]),('one',[71]),('many',[17,29,71,83,7]),('changed',[-31,53,89]),('limit',list(range(64)))]:
        for size in (1,2,7,64):
            groups=[values[i:i+size] for i in range(0,len(values),size)]
            source='start(){Stream<Int>.from(['+','.join(map(str,values))+']).s;s.batch('+str(size)+').b;'
            source+='0.i.mutable;while(i<'+str(len(groups))+'){b.next().expect("batch").v;v.length().console();'
            source+='0.j.mutable;while(j<v.length()){v.at(j).console();j+=1;}i+=1;}b.next().isNone().console();23.return;}'
            expected=[]
            for group in groups:expected += [len(group),*group]
            result.append((f'batch-{name}-{size}',source,23,{'kinds':[4]*len(expected)+[5],
                          'text':(''.join(map(str,expected))+'true').encode()}))
    prefix='start(){Stream<Int>.from([17,29,71]).s;'
    result += [
        ('batch-source-independent',prefix+'s.batch(2).b;b.next().expect("v").a;s.next().expect("v").console();'
         'a.at(0).console();23.return;}',23,{'kinds':[4,4],'text':b'1717'}),
        ('batch-two-live',prefix+'s.batch(1).b;s.batch(2).c;b.next().expect("v").a;c.next().expect("v").d;'
         'a.length().console();d.length().console();a.at(0).console();d.at(1).console();23.return;}',23,
         {'kinds':[4,4,4,4],'text':b'121729'}),
        ('batch-retained-independent',prefix+'s.batch(1).b;b.next().expect("v").a;b.next().expect("v").c;'
         'a.remove(0);c.at(0).console();b.next().expect("v").d;d.at(0).console();23.return;}',23,
         {'kinds':[4,4],'text':b'2971'}),
        ('batch-remaining-cursor',prefix+'s.next();s.batch(2).b;b.next().expect("v").a;a.at(0).console();a.at(1).console();23.return;}',
         23,{'kinds':[4,4],'text':b'2971'}),
        ('batch-option-consumed',prefix+'s.batch(2).b;b.next().v;v.isSome().console();v.expect("v").a;'
         'v.isNone().console();a.at(0).console();23.return;}',23,{'kinds':[5,5,4],'text':b'truetrue17'}),
        ('batch-option-consumed-twice',prefix+'s.batch(2).b;b.next().v;v.expect("v");v.expect("again");23.return;}',177,{}),
    ]
    for size in (0,-1,65):result.append((f'batch-size-invalid-{size}',prefix+f's.batch({size});23.return;}}',177,{}))
    for status in (0,7,23,29,255):result.append((f'batch-return-{status}',prefix+f's.batch(2).b;b.next().expect("v").a;{status}.return;}}',status,{}))
    definitions='(Int.self)add(){self.console();(self+7).return;}(Int.self)keep(){(self>25).return;}'
    result += [
        ('batch-lazy',definitions+'start(){Stream<Int>.from([17,29,71]).s;s.map(add).filter(keep).out;out.batch(2).b;'
         '"ready".console();23.return;}',23,{'kinds':[2],'text':b'ready'}),
        ('batch-filter-map-values',definitions+'start(){Stream<Int>.from([17,29,71]).s;s.map(add).filter(keep).out;out.batch(2).b;'
         'b.next().expect("v").a;a.length().console();a.at(0).console();a.at(1).console();b.next().isNone().console();23.return;}',
         23,{'kinds':[4]*6+[5],'text':b'17297123678true'}),
        ('batch-owned-list-mutations','start(){Stream<Int>.from(['+','.join(map(str,range(64)))+']).s;s.batch(64).b;'
         'b.next().expect("v").a;a.pop();a.push(83);a.at(63).return;}',83,{}),
        ('batch-owned-list-overflow','start(){Stream<Int>.from(['+','.join(map(str,range(64)))+']).s;s.batch(64).b;'
         'b.next().expect("v").a;a.push(83);23.return;}',177,{}),
        ('batch-owned-list-map','(Int.self)add(){(self+7).return;}start(){Stream<Int>.from(['+','.join(map(str,range(64)))+']).s;'
         's.batch(64).b;b.next().expect("v").a;a.map(add).out;out.at(63).return;}',70,{}),
        ('batch-owned-list-iterator','start(){Stream<Int>.from(['+','.join(map(str,range(64)))+']).s;'
         's.batch(64).b;b.next().expect("v").a;a.iterator().it;it.collect<List<Int>>().out;out.at(63).return;}',63,{}),
    ]
    emit='(List<Int>.self)emit(){self.length().console();0.i.mutable;while(i<self.length()){self.at(i).console();i+=1;}}'
    for name,values in [('empty',[]),('one',[71]),('many',[17,29,71,83,7]),('changed',[-31,53,89]),('limit',list(range(64)))]:
        for size in (2,64):
            groups=[values[i:i+size] for i in range(0,len(values),size)]
            expected=[]
            for group in groups:expected += [len(group),*group]
            source=emit+'start(){Stream<Int>.from(['+','.join(map(str,values))+']).s;s.batch('+str(size)+').b;b.sink(emit).return;}'
            result.append((f'batch-sink-{name}-{size}',source,len(groups),
                           {'kinds':[4]*len(expected),'text':''.join(map(str,expected)).encode()} if expected else {}))
    result += [
        ('batch-sink-consumed',emit+'start(){Stream<Int>.from([17,29,71]).s;s.batch(2).b;b.sink(emit);b.sink(emit).return;}',0,
         {'kinds':[4]*5,'text':b'21729171'}),
        ('batch-sink-trap','(List<Int>.self)emit(){self.at(64).console();}start(){Stream<Int>.from([17]).s;s.batch(1).b;b.sink(emit);23.return;}',177,{}),
        ('list-generic-receiver','(List<Int>.self)first(){self.at(0).return;}start(){List<Int>.from([71]).a;a.first().return;}',71,{}),
        ('list-generic-parameter','(Int.self)add(List<Int>.items){(self+items.at(0)).return;}start(){List<Int>.from([71]).a;17.add(a).return;}',88,{}),
    ]
    return result

def window_cases():
    """Logical Event.sequence timestamps; grouping is independent of payload."""
    result=[]
    emit='(List<Int>.self)emit(){self.length().console();0.i.mutable;while(i<self.length()){self.at(i).console();i+=1;}}'
    for name,values in [('empty',[]),('one',[71]),('many',[17,29,71,83,7]),('changed',[-31,53,89]),('limit',list(range(64)))]:
        for duration in (1,2,7,64,9223372036854775807):
            groups=[values[i:i+duration] for i in range(0,len(values),duration)]
            expected=[item for group in groups for item in [len(group),*group]]
            source=emit+'start(){Stream<Int>.from(['+','.join(map(str,values))+']).s;s.window('+str(duration)+').w;w.sink(emit).return;}'
            result.append((f'window-{name}-{duration}',source,len(groups),dict(kinds=[4]*len(expected),text=''.join(map(str,expected)).encode()) if expected else {}))
    for duration in (1,2,3,7):
        values=[17,29,71,83,7];groups={}
        for timestamp,value in enumerate(values):
            if value>25:groups.setdefault(timestamp//duration,[]).append(value+7)
        expected=[item for group in groups.values() for item in [len(group),*group]]
        source='(Int.self)keep(){(self>25).return;}(Int.self)add(){(self+7).return;}'+emit+'start(){Stream<Int>.from([17,29,71,83,7]).s;s.filter(keep).map(add).mapped;mapped.window('+str(duration)+').w;w.sink(emit).return;}'
        result.append((f'window-filter-map-{duration}',source,len(groups),dict(kinds=[4]*len(expected),text=''.join(map(str,expected)).encode())))
    prefix='start(){Stream<Int>.from([17,29,71]).s;'
    result += [
        ('window-two-live',prefix+'s.window(1).a;s.window(2).b;a.next().expect("v").x;b.next().expect("v").y;x.at(0).console();y.at(1).console();s.next().expect("v").console();23.return;}',23,dict(kinds=[4]*3,text=b'172917')),
        ('window-retained',prefix+'s.window(1).w;w.next().expect("v").a;w.next().expect("v").b;a.remove(0);b.at(0).console();w.next().expect("v").c;c.at(0).console();23.return;}',23,dict(kinds=[4]*2,text=b'2971')),
        ('window-remaining-cursor',prefix+'s.next();s.window(2).w;w.next().expect("v").a;a.length().console();a.at(0).console();w.next().expect("v").b;b.at(0).console();w.next().isNone().console();23.return;}',23,dict(kinds=[4]*3+[5],text=b'12971true')),
        ('window-lazy-no-lookahead','(Int.self)step(){self.console();(self+7).return;}start(){Stream<Int>.from([17,29,71]).s;s.map(step).m;m.window(2).w;"ready".console();w.next().expect("v").a;a.length().console();23.return;}',23,dict(kinds=[2,4,4,4],text=b'ready17292')),
        ('window-filter-empty-buckets','(Int.self)keep(){(self>70).return;}'+emit+'start(){Stream<Int>.from([17,29,71,83,7]).s;s.filter(keep).m;m.window(2).w;w.sink(emit).return;}',1,dict(kinds=[4]*3,text=b'27183')),
        ('window-filter-all-empty','(Int.self)keep(){false.return;}start(){Stream<Int>.from([17,29,71]).s;s.filter(keep).m;m.window(1).w;w.next().isNone().console();23.return;}',23,dict(kinds=[5],text=b'true')),
        ('window-sink-consumed',emit+prefix[0:]+ 's.window(2).w;w.sink(emit);w.sink(emit).return;}',0,dict(kinds=[4]*5,text=b'21729171')),
        ('window-callback-trap','(Int.self)step(){(self/0).return;}start(){Stream<Int>.from([17]).s;s.map(step).m;m.window(2).w;w.next();23.return;}',128+45,{}),
    ]
    for duration in (0,-1,-9223372036854775808):
        result.append((f'window-invalid-duration-{duration}',prefix+f's.window({duration});23.return;}}',177,{}))
    for returned in (0,7,23,29,255):
        result.append((f'window-return-{returned}',prefix+f's.window(2).w;w.next().expect("v").at(1).console();{returned}.return;}}',returned,dict(kinds=[4],text=b'29')))
    return result


def window_negatives():
    prefix='start(){Stream<Int>.from([17,29,71]).s;'
    return [
        ('window-duration-type',prefix+'s.window(true);23.return;}','NEBO_TYPE_MISMATCH'),
        ('window-arity',prefix+'s.window(2,3);23.return;}','NEBO_TYPE_MISMATCH'),
        ('window-missing-duration',prefix+'s.window();23.return;}','NEBO_TYPE_MISMATCH'),
        ('window-copy',prefix+'s.window(2).w;w.other;23.return;}','NEBO_COPY_UNIQUE'),
        ('window-option-copy',prefix+'s.window(2).w;w.next().a;a.b;23.return;}','NEBO_COPY_UNIQUE'),
        ('window-sink-type','(Int.self)emit(){self.console();}'+prefix+'s.window(2).w;w.sink(emit);23.return;}','NEBO_TYPE_MISMATCH'),
    ]


def negatives():
    result=[
        ('stream-element-type','Stream<Text>.from([17]).s;23.return;','NEBO_TYPE_MISMATCH'),
        ('stream-value-type','Stream<Int>.from([true]).s;23.return;','NEBO_TYPE_MISMATCH'),
        ('stream-copy','Stream<Int>.from([17]).s;s.other;23.return;','NEBO_COPY_UNIQUE'),
        ('stream-from-type','Stream<Int>.from(17).s;23.return;','NEBO_TYPE_MISMATCH'),
        ('stream-next-arity','Stream<Int>.from([17]).s;s.next(7);23.return;','NEBO_TYPE_MISMATCH'),
        ('stream-map-type','Stream<Int>.from([17]).s;s.map(7);23.return;','NEBO_TYPE_MISMATCH'),
        ('event-type','Event<Text> 17.x;23.return;','NEBO_TYPE_MISMATCH'),
        ('flow-type','Flow<Text> 17.x;23.return;','NEBO_TYPE_MISMATCH'),
        ('column-uint-process-status','Column<Int>.from([71]).c;c.cast<UInt>().u;u.get(0).expect("v").return;','NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
        ('column-element-type','Column<Text>.from([17]).c;23.return;','NEBO_TYPE_MISMATCH'),
        ('column-value-type','Column<Int>.from([true]).c;23.return;','NEBO_TYPE_MISMATCH'),
        ('column-mixed-type','Column<Int>.from([17,2.5]).c;23.return;','NEBO_TYPE_MISMATCH'),
        ('column-over-limit','Column<Int>.from(['+','.join(map(str,range(33)))+']).c;23.return;','NEBO_LIMIT_EXCEEDED'),
        ('column-copy','Column<Int>.from([17]).c;c.other;23.return;','NEBO_COPY_UNIQUE'),
        ('column-from-type','Column<Int>.from(17).c;23.return;','NEBO_TYPE_MISMATCH'),
        ('column-cast-type','Column<Int>.from([17]).c;c.cast<Text>();23.return;','NEBO_TYPE_MISMATCH'),
        ('column-coalesce-type','Column<Int>.from([17]).c;c.coalesce(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('column-dtype-coalesce','Column<Int>.from([17]).c;c.cast<UInt>().u;c.coalesce(u);23.return;','NEBO_TYPE_MISMATCH'),
        ('column-after-return','Column<Int>.from([17]).c;23.return;c.sum();','NEBO_PARSE_UNEXPECTED_TOKEN'),
    ]
    result += [(f'column-{method}-arity',f'Column<Int>.from([17]).c;c.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
               for method in ('sum','min','max','countMissing','dropMissing')]
    result += [(f'column-{method}-type',f'Column<Int>.from([17]).c;c.{method}(true);23.return;','NEBO_TYPE_MISMATCH')
               for method in ('get','isMissing','fillMissing')]
    return result

def frame_cases():
    """Observe valid owned storage and controlled resource exhaustion.

    All normal statuses and document values are independent source oracles.
    The explicit child stack limits also test the runtime's getrlimit path.
    """
    def body(count):
        return ('Table.fromColumns([Tuple.of("key",Column<Int>.from([17]))]).table;'
                + ''.join(f'table.groupBy(["key"]).g{i};g{i}.length().console();'
                          for i in range(count)))
    result = []
    for stack, count, exhausted in ((8388608,1,False),(8388608,24,False),
                                    (8388608,25,True),(8388608,53,True),
                                    (1048576,2,False),(1048576,3,True),
                                    (2097152,5,False),(2097152,6,True)):
        options = dict(stack_bytes=stack)
        if not exhausted: options.update(kinds=[4]*count, text=b'1'*count)
        result.append((f'owned-frame-{stack}-{count}', 'start(){'+body(count)+'23.return;}',
                       178 if exhausted else 23, options))
    for count in (2,6,7):
        # Declare callees before callers, as required by this bounded profile.
        source = ''.join(f'(Int.self)f{i}(){{'+body(4)
                         +(f'self.f{i+1}().return;' if i+1<count else 'self.return;')+'}'
                         for i in reversed(range(count)))+'start(){23.f0().return;}'
        options = dict(stack_bytes=8388608)
        if count<=6: options.update(kinds=[4]*count*4, text=b'1'*count*4)
        result.append((f'owned-frame-chain-{count}', source, 23 if count<=6 else 178, options))
    return result

def run():
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-data-',dir='/tmp') as directory:
        root=Path(directory)
        for name,body,expected,options in cases():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'}')
            try:proof=pipeline(source,work,expected,**options)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='positive',result='PASS',**proof))
        for name,body,expected,options in callback_cases()+batch_cases()+window_cases()+schema_cases()+row_cases()+table_cases()+dataset_cases()+collect_cases()+repartition_cases()+group_cases()+join_cases()+quality_cases()+frame_cases():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text(body)
            try:proof=pipeline(source,work,expected,**options)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='positive',result='PASS',**proof))
        for name,body,code in stream_negatives()+window_negatives()+schema_negatives()+row_negatives()+table_negatives()+dataset_negatives()+collect_negatives()+repartition_negatives()+group_negatives()+join_negatives()+quality_negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text(body)
            try:proof=reject(source,work,code)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='negative',result='PASS',**proof))
        for name,body,code in negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'}')
            try:proof=reject(source,work,code)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='negative',result='PASS',**proof))
    return dict(cases=results,passed=len(results),total=len(cases())+len(negatives())+len(callback_cases())+len(batch_cases())+len(window_cases())+len(window_negatives())+len(stream_negatives())+len(schema_cases())+len(schema_negatives())+len(row_cases())+len(row_negatives())+len(table_cases())+len(table_negatives())+len(dataset_cases())+len(dataset_negatives())+len(collect_cases())+len(collect_negatives())+len(repartition_cases())+len(repartition_negatives())+len(group_cases())+len(group_negatives())+len(join_cases())+len(join_negatives())+len(quality_cases())+len(quality_negatives())+len(frame_cases()))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
