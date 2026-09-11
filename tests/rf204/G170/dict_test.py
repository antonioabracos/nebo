#!/usr/bin/env python3
"""Typed Dict/Set source regressions, with independent Python map oracles."""
import json
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf

HERE = Path(__file__).resolve().parent

def cases():
    result = [('empty', 'Dict<Int,Int>.new().d;d.length().return;', 0, {}),
              ('empty-reproducer', None, 0, {})]
    for value in (0, 7, 23, 29, 255):
        result.append((f'explicit-return-{value}',
                       f'Dict<Int,Int>.new().d;d.insert(17,53);{value}.return;', value, {}))
    for capacity in (8, 16, 32, 64):
        result.append((f'capacity-{capacity}',
                       f'Dict<Int,Int>.withCapacity({capacity}).d;d.capacity().return;', capacity, {}))
    # Key and value inputs are changed independently. Expected values come
    # exclusively from this reference model, before compiling any source.
    for key, value, query in ((17,53,17), (29,53,17), (17,71,17), (-17,83,-17)):
        model = {key: value}
        result.append((f'lookup-{key}-{value}-{query}',
                       f'Dict<Int,Int>.new().d;d.insert({key},{value});'
                       f'd.get({query}).unwrapOr(67).return;', model.get(query,67), {}))
    result += [
        ('present', 'Dict<Int,Int>.new().d;d.insert(17,53);d.get(17).expect("present").return;', 53, {}),
        ('absent', 'Dict<Int,Int>.new().d;d.get(91).unwrapOr(67).return;', 67, {}),
        ('length-one', 'Dict<Int,Int>.new().d;d.insert(17,53);d.length().return;', 1, {}),
        ('length-two', 'Dict<Int,Int>.new().d;d.insert(17,53);d.insert(29,71);d.length().return;', 2, {}),
        ('two-live', 'Dict<Int,Int>.new().a;Dict<Int,Int>.new().b;'
         'a.insert(17,53);b.insert(17,71);'
         '(a.get(17).expect("a")+b.get(17).expect("b")).return;', 124, {}),
        ('scalar-composition', 'Dict<Int,Int>.new().d;(7+11).v;d.insert(v,61);'
         'd.get(18).expect("value").return;', 61, {}),
        ('dict-set', 'Dict<Int,Int>.new().d;Set<Int>.new().s;d.insert(17,53);s.insert(29);'
         '(d.length()+s.length()).return;', 2, {}),
        ('duplicate-old-value', 'Dict<Int,Int>.new().d;d.insert(17,53);'
         'd.insert(17,71).expect("old").return;', 53, {}),
        ('duplicate-new-value', 'Dict<Int,Int>.new().d;d.insert(17,53);d.insert(17,71);'
         'd.get(17).expect("new").return;', 71, {}),
        ('duplicate-length', 'Dict<Int,Int>.new().d;d.insert(17,53);d.insert(17,71);d.length().return;', 1, {}),
        ('remove', 'Dict<Int,Int>.new().d;d.insert(17,53);d.remove(17).expect("old").return;', 53, {}),
        ('remove-absent', 'Dict<Int,Int>.new().d;d.remove(19).unwrapOr(73).return;', 73, {}),
        ('clear', 'Dict<Int,Int>.new().d;d.insert(17,53);d.clear();d.length().return;', 0, {}),
        ('contains', 'Dict<Int,Int>.new().d;d.insert(17,53);'
         'd.containsKey(17).console();d.containsKey(29).console();23.return;', 23,
         {'kinds':[5,5], 'text':b'truefalse'}),
        ('option-tags', 'Dict<Int,Int>.new().d;d.get(19).isNone().console();'
         'd.insert(17,53);d.get(17).isSome().console();23.return;', 23,
         {'kinds':[5,5], 'text':b'truetrue'}),
        ('set-insert-remove', 'Set<Int>.new().s;s.insert(17).console();s.insert(17).console();'
         's.contains(17).console();s.remove(17).console();s.contains(17).console();23.return;', 23,
         {'kinds':[5,5,5,5,5], 'text':b'truefalsetruetruefalse'}),
    ]
    result += [
        ('move', 'Dict<Int,Int>.new().d;d.insert(17,53);d.move().e;e.get(17).expect("e").return;', 53, {}),
        ('moved-query', 'Dict<Int,Int>.new().d;d.move().e;d.isMoved().console();e.isMoved().console();23.return;', 23,
         {'kinds':[5,5], 'text':b'truefalse'}),
        ('drop', 'Dict<Int,Int>.new().d;d.insert(17,53);d.drop();23.return;', 23, {}),
        ('branch', 'Dict<Int,Int>.new().d;d.insert(17,53);if(d.containsKey(17)){23.return;}else{7.return;}', 23, {}),
        ('reserve-retains-value', 'Dict<Int,Int>.new().d;d.insert(17,53);d.reserve(9);'
         '(d.capacity()+d.get(17).expect("retained")).return;', 16+53, {}),
        ('invariants', 'Dict<Int,Int>.new().d;d.validateInvariants().console();'
         'd.insert(17,53);d.validateInvariants().console();23.return;', 23,
         {'kinds':[5,5], 'text':b'truetrue'}),
        # The metric counts visited buckets, including the first bucket.
        ('max-probe', 'Dict<Int,Int>.new().d;d.insert(17,53);d.maxProbeLength().return;', 1, {}),
        ('bound-reference', 'Dict<Int,Int>.new().d;d.insert(17,53);d.get(17).reference;'
         'reference.expect("v").return;', 53, {}),
        ('released-reference-mutation', 'Dict<Int,Int>.new().d;d.insert(17,53);d.get(17).reference;'
         'reference.release();d.insert(19,71);d.get(19).expect("v").return;', 71, {}),
    ]
    sets = ('Set<Int>.new().a;a.insert(17);a.insert(29);'
            'Set<Int>.new().b;b.insert(29);b.insert(53);')
    for method, expected in (('union', {17,29}|{29,53}),
                             ('intersection', {17,29}&{29,53}),
                             ('difference', {17,29}-{29,53})):
        result.append((f'set-{method}', sets+f'a.{method}(b).c;c.length().return;',len(expected),{}))
        result.append((f'set-{method}-membership', sets+f'a.{method}(b).c;'+
                       ''.join(f'c.contains({key}).console();' for key in (17,29,53))+'23.return;',23,
                       {'kinds':[5,5,5], 'text': ''.join(str(key in expected).lower() for key in (17,29,53)).encode()}))
    result.append(('set-subset', sets+'a.intersection(b).i;i.isSubsetOf(a).console();'
                   'a.isSubsetOf(b).console();23.return;',23,{'kinds':[5,5],'text':b'truefalse'}))
    for entries in ([], [(17,53)], [(17,53),(29,71)]):
        expected=len(dict(entries))/8
        result.append((f'load-factor-{len(entries)}','Dict<Int,Int>.new().d;'+
                       ''.join(f'd.insert({k},{v});' for k,v in entries)+
                       f'(d.loadFactor()=={expected}).console();23.return;',23,
                       {'kinds':[5],'text':b'true'}))
    for name, expression in (('add','1.25+2.5==3.75'), ('sub','8.5-1.25==7.25'),
                              ('mul','1.5*2.5==3.75'), ('div','3.0/2.0==1.5'),
                              ('negative','-3.5 < -1.5'), ('unordered','0.0/0.0 != 0.0/0.0')):
        result.append((f'float-composition-{name}',
                       f'Dict<Int,Int>.new().d;({expression}).console();23.return;',23,
                       {'kinds':[5],'text':b'true'}))
    for name, method, expected in (('keys','keys',17),('values','values',53)):
        result.append((f'view-{name}', 'Dict<Int,Int>.new().d;d.insert(17,53);'+
                       f'd.{method}().v;v.next().expect("item").x;v.release();x.return;',expected,{}))
        result.append((f'view-{name}-empty', 'Dict<Int,Int>.new().d;'+
                       f'd.{method}().v;v.next().unwrapOr(73).x;v.release();x.return;',73,{}))
    result += [
        ('entry-view-pair','Dict<Int,Int>.new().d;d.insert(17,53);d.entries().v;'
         'v.next().expect("pair").p;v.release();(p.at(0)+p.at(1)).return;',17+53,{}),
        ('entry-view-empty','Dict<Int,Int>.new().d;d.entries().v;v.next().isNone().console();'
         'v.release();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('view-coexistence','Dict<Int,Int>.new().d;d.insert(17,53);d.keys().k;d.values().v;'
         'k.next().expect("key").a;v.next().expect("value").b;k.release();v.release();(a+b).return;',70,{}),
        ('view-exhaustion','Dict<Int,Int>.new().d;d.insert(17,53);d.values().v;'
         'v.next().expect("first").x;v.next().isNone().console();v.release();x.return;',53,
         {'kinds':[5],'text':b'true'}),
        ('view-release-then-mutate','Dict<Int,Int>.new().d;d.keys().v;v.release();'
         'd.insert(17,53);d.length().return;',1,{}),
        ('reseed-retains','Dict<Int,Int>.new().d;d.insert(17,53);d.insert(29,71);d.reseed();'
         '(d.get(17).expect("a")+d.get(29).expect("b")).return;',124,{}),
        ('repeated-reseed','Dict<Int,Int>.new().d;d.insert(17,53);d.reseed();d.reseed();'
         'd.get(17).expect("a").return;',53,{}),
        ('view-scope-cleanup','Dict<Int,Int>.new().d;if(true){d.keys().v;'
         'v.next().isNone().console();}d.insert(17,53);d.get(17).expect("v").return;',53,
         {'kinds':[5],'text':b'true'}),
        ('view-untaken-branch','Dict<Int,Int>.new().d;if(false){d.keys().v;'
         'v.next().isNone().console();}d.insert(17,53);d.get(17).expect("v").return;',53,{}),
        ('view-early-return','Dict<Int,Int>.new().d;d.insert(17,53);d.values().v;'
         'if(true){v.next().expect("v").return;}7.return;',53,{}),
        ('view-break','Dict<Int,Int>.new().d;loop{d.keys().v;v.next().isNone().console();break;}'
         'd.insert(17,53);d.get(17).expect("v").return;',53,{'kinds':[5],'text':b'true'}),
        ('view-continue','Dict<Int,Int>.new().d;0.i.mutable;while(i<3){d.keys().v;'
         'v.next().isNone().console();i+=1;continue;}d.insert(17,53);d.get(17).expect("v").return;',53,
         {'kinds':[5,5,5],'text':b'truetruetrue'}),
    ]
    # Check full Int64 hashes against FNV-1a over independent byte sequences.
    unique='Dict<Int,Int>.new().d;d.insert(17,53);'
    result += [
        ('unique-read',unique+'d.getMutable(17).r;r.read().return;',53,{}),
        ('unique-write',unique+'d.getMutable(17).r;r.write(71);r.read().return;',71,{}),
        ('unique-release',unique+'d.getMutable(17).r;r.write(71);r.release();'
         'd.get(17).expect("v").return;',71,{}),
        ('unique-scope',unique+'if(true){d.getMutable(17).r;r.write(71);}d.get(17).expect("v").return;',71,{}),
        ('unique-temporary',unique+'d.getMutable(17).write(71);d.get(17).expect("v").return;',71,{}),
        ('unique-missing',unique+'d.getMutable(29).r;r.read().return;',177,{}),
        ('temporary-view','Dict<Int,Int>.new().d;d.keys().next();d.insert(17,53);d.length().return;',1,{}),
        ('entry-new','Dict<Int,Int>.new().d;d.entry(17).e;e.write(53);e.release();'
         'd.get(17).expect("v").return;',53,{}),
        ('entry-update',unique+'d.entry(17).e;e.write(71);e.read().return;',71,{}),
        ('entry-repeated-write','Dict<Int,Int>.new().d;d.entry(17).e;e.write(53);e.write(71);'
         'e.release();(d.length()+d.get(17).expect("v")).return;',72,{}),
        ('entry-absent-read','Dict<Int,Int>.new().d;d.entry(17).e;e.read().return;',177,{}),
        ('entry-temporary','Dict<Int,Int>.new().d;d.entry(17).write(53);d.get(17).expect("v").return;',53,{}),
        ('entry-key-once',None,71,{'kinds':[4],'text':b'17','source':
         '(Int.self)key(){17.console();self.return;}start(){Dict<Int,Int>.new().d;'
         'd.entry(29.key()).e;e.write(53);e.write(71);e.release();d.get(29).expect("v").return;}'}),
        ('sorted-empty','Dict<Int,Int>.new().d;d.toSortedEntries().s;s.length().return;',0,{}),
        ('sorted-snapshot',unique+'d.toSortedEntries().s;d.insert(17,71);s.at(0).at(1).return;',53,{}),
        ('iteration-order','Dict<Int,Int>.new().d;d.iterationOrder().console();23.return;',23,
         {'kinds':[2],'text':b'unspecified'}),
        ('int-equals','17.equals(17).console();17.equals(29).console();23.return;',23,
         {'kinds':[5,5],'text':b'truefalse'}),
        ('int-hash-stable','Int.hashStable().console();23.return;',23,{'kinds':[5],'text':b'true'}),
    ]
    for name, entries, reseed in (
            ('signed',[(29,71),(-17,53)],False),
            ('permuted',[(-17,53),(29,71)],False),
            ('reseed',[(29,71),(-17,53)],True),
            ('changed',[(-31,83),(7,59)],False)):
        pairs=sorted(dict(entries).items())
        body='Dict<Int,Int>.new().d;'+''.join(f'd.insert({k},{v});' for k,v in entries)
        if reseed:body+='d.reseed();'
        body+='d.toSortedEntries().s;'
        body+=''.join(f's.at({i}).at({j}).console();' for i in range(len(pairs)) for j in range(2))+'23.return;'
        result.append(('sorted-'+name,body,23,{'kinds':[4]*(len(pairs)*2),
                       'text':''.join(str(v) for pair in pairs for v in pair).encode()}))
    for name, entries, predicate, choose in (
            ('empty',[], 'key>17',lambda k,v:k>17),
            ('all',[(17,53),(29,71)],'value>0',lambda k,v:v>0),
            ('none',[(17,53),(29,71)],'value<0',lambda k,v:v<0),
            ('key',[(17,53),(29,71)],'key>17',lambda k,v:k>17),
            ('changed-key',[(31,53),(7,71)],'key>17',lambda k,v:k>17),
            ('value',[(17,53),(29,71)],'value<60',lambda k,v:v<60),
            ('changed-value',[(17,83),(29,59)],'value<60',lambda k,v:v<60)):
        kept={k:v for k,v in entries if choose(k,v)}
        body='Dict<Int,Int>.new().d;'+''.join(f'd.insert({k},{v});' for k,v in entries)
        body+='d.retain(keep);d.length().console();'
        body+=''.join(f'd.get({k}).unwrapOr(-1).console();' for k,v in entries)+'23.return;'
        source='(Int.key)keep(Int.value){('+predicate+').return;}start(){'+body+'}'
        result.append(('retain-'+name,None,23,{'source':source,'kinds':[4]*(1+len(entries)),
                       'text':(str(len(kept))+''.join(str(kept.get(k,-1)) for k,v in entries)).encode()}))
    result.append(('retain-effects-once',None,23,{'source':
        '(Int.key)keep(Int.value){1.console();(key>17 && value<80).return;}'
        'start(){Dict<Int,Int>.new().d;d.insert(17,53);d.insert(29,71);d.retain(keep);'
        'd.get(29).expect("kept").console();d.length().console();23.return;}',
        'kinds':[4,4,4,4],'text':b'11711'}))
    result.append(('retain-two-live',None,124,{'source':
        '(Int.key)keep(Int.value){(value>60).return;}start(){Dict<Int,Int>.new().a;'
        'Dict<Int,Int>.new().b;a.insert(17,53);b.insert(17,71);b.retain(keep);'
        '(a.get(17).expect("a")+b.get(17).expect("b")).return;}'}))
    for name,keys in (('empty',[]),('single',[17]),('cluster',[17,25,33])):
        buckets=[None]*8;collisions=0;maximum=0
        for key in keys:
            hashed=14695981039346656037
            for byte in key.to_bytes(8,'little',signed=True):hashed=((hashed^byte)*1099511628211)&((1<<64)-1)
            home=hashed%8;slot=home;probes=1
            while buckets[slot] is not None:slot=(slot+1)%8;probes+=1
            buckets[slot]=key;collisions+=slot!=home;maximum=max(maximum,probes)
        body='Dict<Int,Int>.new().d;'+''.join(f'd.insert({k},{53+i});' for i,k in enumerate(keys))
        body+='d.collisionCount().console();d.maxProbeLength().console();23.return;'
        result.append(('collision-'+name,body,23,{'kinds':[4,4],'text':f'{collisions}{maximum}'.encode()}))
    for name, seed, data, source in (
            ('empty',17,b'', 'Hasher.new(17).h;'),
            ('bytes',29,bytes((17,29,53,71)),
             'Hasher.new(29).h;h.writeBytes(Bytes.fromValues(17,29,53,71));'),
            ('changed-byte',29,bytes((17,29,53,83)),
             'Hasher.new(29).h;h.writeBytes(Bytes.fromValues(17,29,53,83));'),
            ('changed-seed',31,bytes((17,29,53,71)),
             'Hasher.new(31).h;h.writeBytes(Bytes.fromValues(17,29,53,71));'),
            ('bound-bytes',29,bytes((17,29,53,71)),
             'Bytes.fromValues(17,29,53,71).data;Hasher.new(29).h;h.writeBytes(data);'),
            ('dynamic-bytes',29,bytes((17,29,53,71)),
             '17.first;29.second;Hasher.new(29).h;'
             'h.writeBytes(Bytes.fromValues(first,second,first+36,second+42));'),
            ('nested-bytes',29,bytes((17^3,29^5,53^7,71^11)),
             'Hasher.new(29).h;h.writeBytes(Bytes.fromValues(17,29,53,71) xor '
             'Bytes.fromValues(3,5,7,11));'),
            ('two-byte-streams',29,bytes((17,29,53,71,3,5,7,11)),
             'Hasher.new(29).h;h.writeBytes(Bytes.fromValues(17,29,53,71));'
             'h.writeBytes(Bytes.fromValues(3,5,7,11));'),
            ('int',17,(53).to_bytes(8,'little'), 'Hasher.new(17).h;53.hash(h);'),
            ('stream',17,(53).to_bytes(8,'little')+(71).to_bytes(8,'little'),
             'Hasher.new(17).h;53.hash(h);71.hash(h);')):
        value=14695981039346656037 ^ seed
        for byte in data: value=((value^byte)*1099511628211)&((1<<64)-1)
        if value >= 1<<63: value-=1<<64
        result.append(('hasher-'+name,source+'h.finish().console();23.return;',23,
                       {'kinds':[4],'text':str(value).encode()}))
    # Independent live owners retain separate state across owned arguments.
    values=[]
    for seed,data in ((29,(17,29,53,71)),(31,(3,5,7,11))):
        value=14695981039346656037 ^ seed
        for byte in data:value=((value^byte)*1099511628211)&((1<<64)-1)
        values.append(value-(1<<64) if value>=1<<63 else value)
    result.append(('hasher-two-live-owned-arguments',
                   'Hasher.new(29).a;Hasher.new(31).b;'
                   'a.writeBytes(Bytes.fromValues(17,29,53,71));'
                   'b.writeBytes(Bytes.fromValues(3,5,7,11));'
                   'a.finish().console();b.finish().console();23.return;',23,
                   {'kinds':[4,4],'text':''.join(map(str,values)).encode()}))
    return result

def negatives():
    return [
        ('retain-arity','Dict<Int,Int>.new().d;d.retain();23.return;','NEBO_TYPE_MISMATCH'),
        ('retain-non-callable','Dict<Int,Int>.new().d;d.retain(7);23.return;','NEBO_TYPE_MISMATCH'),
        ('retain-unknown','Dict<Int,Int>.new().d;d.retain(missing);23.return;','NEBO_TYPE_MISMATCH'),
        ('equals-type','17.equals(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('hash-stable-arity','Int.hashStable(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('sorted-arity','Dict<Int,Int>.new().d;d.toSortedEntries(7).s;23.return;','NEBO_TYPE_MISMATCH'),
        ('sorted-index-type','Dict<Int,Int>.new().d;d.toSortedEntries().s;s.at("bad");23.return;','NEBO_TYPE_MISMATCH'),
        ('iteration-order-arity','Dict<Int,Int>.new().d;d.iterationOrder(7);23.return;','NEBO_TYPE_MISMATCH'),
        ('collision-arity','Dict<Int,Int>.new().d;d.collisionCount(7);23.return;','NEBO_TYPE_MISMATCH'),
        ('entry-key-type','Dict<Int,Int>.new().d;d.entry("bad").e;23.return;','NEBO_TYPE_MISMATCH'),
        ('entry-write-type','Dict<Int,Int>.new().d;d.entry(17).e;e.write(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('entry-read-conflict','Dict<Int,Int>.new().d;d.entry(17).e;d.length().return;','NEBO_BORROW_CONFLICT'),
        ('entry-copy','Dict<Int,Int>.new().d;d.entry(17).e;e.f;23.return;','NEBO_COPY_UNIQUE'),
        ('unique-owner-read','Dict<Int,Int>.new().d;d.insert(17,53);d.getMutable(17).r;'
         'd.length().return;','NEBO_BORROW_CONFLICT'),
        ('unique-view','Dict<Int,Int>.new().d;d.insert(17,53);d.getMutable(17).r;'
         'd.keys().v;23.return;','NEBO_BORROW_CONFLICT'),
        ('shared-unique','Dict<Int,Int>.new().d;d.insert(17,53);d.get(17).r;'
         'd.getMutable(17).u;23.return;','NEBO_BORROW_CONFLICT'),
        ('unique-released','Dict<Int,Int>.new().d;d.insert(17,53);d.getMutable(17).r;'
         'r.release();r.read().return;','NEBO_USE_AFTER_MOVE'),
        ('unique-write-type','Dict<Int,Int>.new().d;d.insert(17,53);d.getMutable(17).r;'
         'r.write("bad");23.return;','NEBO_TYPE_MISMATCH'),
        ('unique-key-type','Dict<Int,Int>.new().d;d.getMutable("bad").r;23.return;','NEBO_TYPE_MISMATCH'),
        ('set-new-arity','Set<Int>.new(8).s;23.return;','NEBO_TYPE_MISMATCH'),
        ('set-insert-type','Set<Int>.new().s;s.insert("bad");23.return;','NEBO_TYPE_MISMATCH'),
        ('set-contains-type','Set<Int>.new().s;s.contains("bad");23.return;','NEBO_TYPE_MISMATCH'),
        ('set-remove-type','Set<Int>.new().s;s.remove(true);23.return;','NEBO_TYPE_MISMATCH'),
        *[(f'set-{method}-type',f'Set<Int>.new().s;s.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('union','intersection','difference','isSubsetOf')],
        ('reserve-type','Dict<Int,Int>.new().d;d.reserve("bad");23.return;','NEBO_TYPE_MISMATCH'),
        ('hasher-finish-arity','Hasher.new(17).h;h.finish(19);23.return;','NEBO_TYPE_MISMATCH'),
        ('int-hash-type','Hasher.new(17).h;53.hash(29);23.return;','NEBO_TYPE_MISMATCH'),
        ('int-hash-zero-arity','Hasher.new(17).h;53.hash();23.return;','NEBO_TYPE_MISMATCH'),
        ('int-hash-two-arity','Hasher.new(17).h;53.hash(h,h);23.return;','NEBO_TYPE_MISMATCH'),
        ('view-copy','Dict<Int,Int>.new().d;d.keys().v;v.w;23.return;','NEBO_COPY_UNIQUE'),
        ('view-mutation','Dict<Int,Int>.new().d;d.keys().v;d.insert(17,53);23.return;','NEBO_BORROW_CONFLICT'),
        ('view-reseed','Dict<Int,Int>.new().d;d.values().v;d.reseed();23.return;','NEBO_BORROW_CONFLICT'),
        ('view-released','Dict<Int,Int>.new().d;d.entries().v;v.release();v.next();23.return;','NEBO_USE_AFTER_MOVE'),
        ('hasher-seed-type','Hasher.new("bad").h;23.return;','NEBO_TYPE_MISMATCH'),
        ('hasher-bytes-type','Hasher.new(17).h;h.writeBytes(53);23.return;','NEBO_TYPE_MISMATCH'),
        ('borrow-mutation', 'Dict<Int,Int>.new().d;d.insert(17,53);d.get(17).reference;'
         'd.insert(19,71);23.return;', 'NEBO_BORROW_CONFLICT'),
        ('borrow-move', 'Dict<Int,Int>.new().d;d.get(17).reference;d.move().e;23.return;', 'NEBO_BORROW_CONFLICT'),
        ('released-reference-read', 'Dict<Int,Int>.new().d;d.get(17).reference;reference.release();'
         'reference.expect("v").return;', 'NEBO_USE_AFTER_MOVE'),
        ('use-after-move', 'Dict<Int,Int>.new().d;d.move().e;d.length().return;', 'NEBO_USE_AFTER_MOVE'),
        ('use-after-drop', 'Dict<Int,Int>.new().d;d.drop();d.length().return;', 'NEBO_USE_AFTER_MOVE'),
        ('implicit-copy', 'Dict<Int,Int>.new().d;d.e;d.insert(17,53);e.length().return;', 'NEBO_COPY_UNIQUE'),
        ('key-type', 'Dict<Text,Int>.new().d;0.return;', 'NEBO_TYPE_MISMATCH'),
        ('value-type', 'Dict<Int,Text>.new().d;0.return;', 'NEBO_TYPE_MISMATCH'),
        ('insert-key-type', 'Dict<Int,Int>.new().d;d.insert("bad",31);0.return;', 'NEBO_TYPE_MISMATCH'),
        ('insert-value-type', 'Dict<Int,Int>.new().d;d.insert(17,true);0.return;', 'NEBO_TYPE_MISMATCH'),
        ('constructor-arity', 'Dict<Int,Int>.new(8).d;0.return;', 'NEBO_TYPE_MISMATCH'),
        ('missing-value-type', 'Dict<Int>.new().d;0.return;', 'NEBO_TYPE_MISMATCH'),
        ('missing-type-arguments', 'Dict.new().d;0.return;', 'NEBO_PARSE_EXPECTED_TOKEN'),
        ('capacity-type', 'Dict<Int,Int>.withCapacity("bad").d;0.return;', 'NEBO_TYPE_MISMATCH'),
        *[(f'capacity-invalid-{c}', f'Dict<Int,Int>.withCapacity({c}).d;0.return;',
           'NEBO_LIMIT_EXCEEDED') for c in (0,7,9,128)],
        ('after-return', 'Dict<Int,Int>.new().d;23.return;d.insert(17,53);', 'NEBO_PARSE_UNEXPECTED_TOKEN'),
        ('duplicate-return', 'Dict<Int,Int>.new().d;7.return;23.return;', 'NEBO_PARSE_UNEXPECTED_TOKEN'),
        ('unclaimed-before', 'mystery();Dict<Int,Int>.new().d;0.return;', 'NEBO_PARSE_EXPECTED_TOKEN'),
        ('unclaimed-after', 'Dict<Int,Int>.new().d;mystery();0.return;', 'NEBO_PARSE_EXPECTED_TOKEN'),
    ]

def predicate_negatives():
    body='start(){Dict<Int,Int>.new().d;d.retain(keep);23.return;}'
    return [
        ('retain-key-type','(Text.key)keep(Int.value){true.return;}'+body,'NEBO_TYPE_MISMATCH'),
        ('retain-value-type','(Int.key)keep(Bool.value){value.return;}'+body,'NEBO_TYPE_MISMATCH'),
        ('retain-return-type','(Int.key)keep(Int.value){value.return;}'+body,'NEBO_TYPE_MISMATCH'),
        ('retain-capture','(Int.key)keep(Int.value){(key>outside).return;}'
         'start(){17.outside;Dict<Int,Int>.new().d;d.retain(keep);23.return;}','NEBO_NAME_UNDEFINED'),
        ('retain-borrow','(Int.key)keep(Int.value){true.return;}'
         'start(){Dict<Int,Int>.new().d;d.keys().v;d.retain(keep);23.return;}','NEBO_BORROW_CONFLICT'),
    ]

def run():
    observed=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-dict-',dir='/tmp') as directory:
        root=Path(directory)
        obj=root/'retain-native.o';binary=root/'retain-native.elf'
        for command in ([ 'nasm','-f','elf64','-I',str(ROOT)+'/',
                         str(HERE/'dict_retain_native.asm'),'-o',str(obj)],
                        ['ld','-o',str(binary),str(obj),str(ROOT/'build/obj/dict.o'),
                         str(ROOT/'build/obj/hasher.o')]):
            if execute(command,root)!=(0,b'',b''): raise Failure('RETAIN_NATIVE_BUILD')
        elf(binary)
        for _ in range(2):
            if execute([binary],root)!=(0,b'',b''): raise Failure('RETAIN_NATIVE_ATOMICITY')
        for name, body, expected, options in cases():
            work=root/name;work.mkdir()
            source=work/'arbitrary-name.no'
            options=dict(options)
            source.write_text(options.pop('source',None) or
                              ('start(){'+body+'}\n' if body is not None else
                               (HERE/'reproducers/dict-empty.no').read_text()))
            try:
                proof=pipeline(source,work,expected,keep_artifacts=True,**options)
            except Failure as error:
                raise Failure(name+':'+str(error)) from error
            assembly=(work/'root-0/program.asm').read_text()
            if 'nebo_g008_source_probe' in assembly: raise Failure('WHOLE_FILE_DICT_ECLIPSE')
            from harness import release_artifacts
            release_artifacts(work)
            observed.append(dict(id=name,result='PASS',category='positive',**proof))
        for name,body,diagnostic in negatives():
            work=root/name;work.mkdir();source=work/'source.no'
            source.write_text('start(){'+body+'}\n')
            proof=reject(source,work,diagnostic)
            observed.append(dict(id=name,result='PASS',category='negative',**proof))
        for name,body,diagnostic in predicate_negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text(body)
            proof=reject(source,work,diagnostic)
            observed.append(dict(id=name,result='PASS',category='negative',**proof))
    return dict(schema=1,oracle='python-dict-and-explicit-source-values-v1',cases=observed,
                passed=len(observed),total=len(cases())+len(negatives())+len(predicate_negatives()),
                native_retain_atomicity='PASS',native_retain_controls=7)

if __name__=='__main__':
    print(json.dumps(run(),sort_keys=True))
