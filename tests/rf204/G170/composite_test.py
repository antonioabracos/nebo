#!/usr/bin/env python3
"""Composite values, pure specialization and source-order runtime oracles."""
import json,tempfile
from pathlib import Path
from harness import ROOT,pipeline,reject,Failure


def cases():
    rows=[]
    for group,expected in [('G005',[17,43,13,46,47,5]),('G006',[11,12,7,5,47,1])]:
        for i,status in enumerate(expected,1):
            source=(ROOT/f'examples/rf204/{group}/RF204-{group}-S{i:02}.no').read_text()
            rows.append((f'{group}-{i:02}',source,status,{}))
            if group=='G006' and i in (3,4,5):
                for returned in (0,7,23,29,255):
                    at=source.rfind('}')
                    rows.append((f'{group}-{i:02}-return-{returned}',source[:at]+f'{returned}.return;'+source[at:],returned,{}))
    for value,delta in ((3,7),(17,7),(3,11)):
        for size in (1,4):
            body=f'Array<Int,{size}>.filled({value}).a;a.map(add).b;b.at({size-1}).console();23.return;'
            source=f'callable add(Int.value) capture none {{(value+{delta}).return;}}start(){{{body}}}'
            rows.append((f'map-observation-{value}-{delta}-{size}',source,23,dict(kinds=[4],text=str(value+delta).encode())))
    for value,tag in (('Idle',0),('Ready',1),('Done',2)):
        source=f'enum State{{Idle,Ready,Done}}start(){{State.sizeOf().size;State.{value}.discriminant().tag;(size+tag).return;}}'
        rows.append((f'nominal-size-and-tag-{value}',source,4+tag,{}))
    for left,right in ((17,29),(71,29),(17,83)):
        source=f'newtype UserId(Int);start(){{UserId({left}).unwrap().left;UserId({right}).unwrap().right;(left+right).return;}}'
        rows.append((f'newtype-two-values-{left}-{right}',source,left+right,{}))
        decl='const generic<N> (Int.value)extent(){N.return;}'
        source=decl+f'start(){{0.extent<{left}>().left;0.extent<{right}>().right;(left+right).return;}}'
        rows.append((f'const-generic-two-values-{left}-{right}',source,left+right,{}))
    for value in (7,23,255):
        decl='const generic<N> (Int.value)extent(){N.return;}'
        rows.append((f'const-generic-adjacent-{value}',decl+f'start(){{0.extent<17>().console();{value}.return;}}',value,dict(kinds=[4],text=b'17')))
    for name,status in [('struct-default',0),('struct-layout',24),('struct-update-a',11),('struct-update-b',11),('struct-two-values',13),
        ('tuple-map',12),('tuple-map-identity',17),('array-map-literal',7),('array-map-empty',0),
        ('range-contains-true',1),('range-contains-false',0),('range-inclusive-length',5),('range-exclusive-length',4),('range-exclusive-equivalent',5),
        ('generic-unconstrained',37),('generic-where-copy',41),('generic-where-comparable',120),('generic-where-hash-eq',43),('generic-inline-copy',41)]:
        rows.append((name,(ROOT/f'tests/rf204/G006/cases/{name}.no').read_text(),status,{}))
    for ordinal,text in enumerate(('Nebo','Olá','Ω雪')):
        source=f'newtype Label(Text);start(){{Label("{text}").unwrap().byteLength().return;}}'
        rows.append((f'newtype-text-{ordinal}',source,len(text.encode()),{}))
    for constraint in ('',' where T: Copy',' where T: Hash + Eq',' where T: Ord'):
        for value in (7,23,255):
            decl=f'generic<T> (T.value)hold(){constraint}{{value.return;}}'
            source=decl+f'start(){{17.hold().a;29.hold().b;(a+b).console();{value}.return;}}'
            label=constraint.replace(' ','').replace(':','').replace('+','') or 'open'
            rows.append((f'generic-compose-{label}-{value}',source,value,dict(kinds=[4],text=b'46')))
    for value in (-17,71,-9223372036854775808):
        source=f'newtype UserId(Int);start(){{UserId({value}).unwrap().return;}}'
        rows.append((f'newtype-signed-{value}',source,value%256,{}))
    for name,status in [('alias-size',8),('newtype-int',42),('newtype-char',65),('enum-unit-discriminant',1),('enum-unit-size',4),('enum-payload-match',42),('enum-text-discriminant',1)]:
        rows.append((name,(ROOT/f'tests/rf27-g06/f06/positive/{name}.no').read_text(),status,{}))
    return rows


def struct_cases():
    from text_test import document,literal
    rows=[]
    decl='struct User { Text.name; Int.age; }'
    source=(ROOT/'tests/rf204/G170/reproducers/struct-field.no').read_text()
    rows.append(('typed-struct-source',source,23,document('Nebo:29')))
    for name,age in [('Nebo',29),('Lua',29),('Nebo',47),('Ω雪',83),('',0)]:
        fields=f'name: {literal(name)}, age: {age}'
        for returned in (0,7,23,29,255):
            body=f'User {{ {fields} }}.x;"${{x.name}}:${{x.age}}".console();{returned}.return;'
            rows.append((f'typed-struct-value-{age}-{name or "empty"}-{returned}',decl+'start(){'+body+'}',returned,document(f'{name}:{age}')))
    for first,second in [(17,29),(43,29),(17,71)]:
        source=decl+f'start(){{User {{name:"first",age:{first}}}.a;User {{age:{second},name:"second"}}.b;"${{a.name}}:${{a.age}}/${{b.name}}:${{b.age}}".console();23.return;}}'
        rows.append((f'typed-struct-two-{first}-{second}',source,23,document(f'first:{first}/second:{second}')))
    for name,body,wanted in [
        ('text-method','User {name:"Nebo",age:29}.x;x.name.console();','Nebo'),
        ('field-length','User {name:"Ω雪",age:29}.x;x.name.byteLength().console();',5),
        ('nested','Outer {user:User {name:"Ada",age:31},ok:true}.x;"${x.user.name}:${x.user.age}:${x.ok}".console();','Ada:31:true'),
        ('inline','"${User {name:"Nebo",age:29}.age}".console();','29'),
        ('copy-isolation','User {name:"Nebo",age:29}.x;x.copy;User {name:"Lua",age:47}.y;"${copy.name}:${copy.age}/${y.name}:${y.age}".console();','Nebo:29/Lua:47'),
        ('initializer-expression','User {age:(17+29),name:"Nebo"}.x;"${x.age}".console();','46'),
    ]:
        prefix=decl+('struct Outer { User.user; Bool.ok; }' if name=='nested' else '')
        rows.append(('typed-struct-'+name,prefix+'start(){'+body+'23.return;}',23,document(wanted)))
    for value in (0,7,23,29,255):
        source='struct Code { Int.value; }'+f'start(){{Code {{value:{value}}}.code;code.value.return;}}'
        rows.append((f'typed-struct-status-{value}',source,value,{}))
    for char,value in [('A',65),('Ω',937)]:
        source=f'''struct Flag {{ Bool.ok; Char.letter; Int.count; }}start(){{Flag {{letter:'{char}',ok:true,count:29}}.x;"${{x.ok}}:${{x.count}}".console();x.letter.return;}}'''
        rows.append((f'typed-struct-padding-{value}',source,value%256,document('true:29')))
    source=decl+'(Int.value)make(){User {name:"Nebo",age:value}.x;x.age.return;}start(){"${29.make()}".console();23.return;}'
    rows.append(('typed-struct-function-local',source,23,document('29')))
    source=decl+'(Int.value)add(){(value+7).return;}start(){User {age:22.add(),name:"Nebo"}.x;"${x.age}".console();23.return;}'
    rows.append(('typed-struct-call-initializer',source,23,document('29')))
    fields=' '.join(f'Int.f{i};' for i in range(8))
    values=','.join(f'f{i}:{i+11}' for i in reversed(range(8)))
    expr='+'.join(f'x.f{i}' for i in range(8))
    rows.append(('typed-struct-eight-fields',f'struct Wide {{{fields}}}start(){{Wide {{{values}}}.x;"${{{expr}}}".console();23.return;}}',23,document(str(sum(range(11,19))))))
    source='struct Pair { Int.first; Int.second; }(Int.value)mark(){value.console();value.return;}start(){Pair {second:29.mark(),first:17.mark()}.x;"${x.first}:${x.second}".console();23.return;}'
    rows.append(('typed-struct-lexical-effects',source,23,dict(kinds=[4,4,2],text=b'291717:29',publications=3)))
    source=decl+'start(){User {name:"Nebo",age:29}.x;"${x.name:align(right,8)}:${x.age:hex(width:4)}".console();23.return;}'
    rows.append(('typed-struct-profiles',source,23,document('    Nebo:  1d')))
    return rows


def struct_negatives():
    decl='struct User { Text.name; Int.age; }'
    rows=[]
    for name,value in [('wrong-text','name:23,age:29'),('wrong-int','name:"Nebo",age:true'),('missing','name:"Nebo"'),('extra','name:"Nebo",age:29,extra:47'),('duplicate','name:"Nebo",name:"Lua"'),('unknown','name:"Nebo",wrong:29')]:
        rows.append(('typed-struct-'+name,decl+'start(){User {'+value+'}.x;"${23}".console();23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('typed-struct-unknown-projection',decl+'start(){User {name:"Nebo",age:29}.x;"${x.unknown}".console();23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('typed-struct-status-text',decl+'start(){User {name:"Nebo",age:29}.x;"${x.age}".console();x.name.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    source='struct Pair { Int.first; Int.second; }(Int.value)mark(){value.console();value.return;}start(){"${Pair {second:29.mark(),first:17}.first}".console();23.return;}'
    rows.append(('typed-struct-interpolation-effects',source,'NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    return rows


def negatives():
    result=[]
    for name,code in [('struct-update-unknown','NEBO_NAME_UNDEFINED'),('struct-update-duplicate','NEBO_NAME_DUPLICATE'),
        ('struct-default-argument','NEBO_PARSE_UNEXPECTED_TOKEN'),('tuple-map-wrong-type','NEBO_TUPLE_INVALID_RECEIVER'),
        ('tuple-to-struct-mismatch','NEBO_TUPLE_INVALID_RECEIVER'),('array-map-wrong-type','NEBO_TYPE_MISMATCH'),
        ('array-map-overflow','NEBO_LIMIT_EXCEEDED'),('array-map-capture','NEBO_PARSE_UNEXPECTED_TOKEN'),
        ('array-map-truncated','NEBO_TYPE_MISMATCH'),('range-zero-step','NEBO_LIMIT_EXCEEDED'),
        ('generic-hash-eq-failure','NEBO_TYPE_MISMATCH'),('generic-const-overflow','NEBO_TYPE_MISMATCH'),
        ('generic-const-truncated','NEBO_TYPE_MISMATCH'),('generic-where-malformed','NEBO_PARSE_UNEXPECTED_TOKEN')]:
        result.append((name,(ROOT/f'tests/rf204/G006/cases/{name}.no').read_text(),code))
    decl='const generic<N> (Int.value)extent(){N.return;}'
    result += [('const-generic-invalid-return',decl+'start(){0.extent<17>();"bad".return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
               ('const-generic-extra-argument',decl+'start(){0.extent<17>(29);}','NEBO_PARSE_UNEXPECTED_TOKEN'),
               ('const-generic-wrong-body',decl.replace('N.return','23.return')+'start(){0.extent<17>();}','NEBO_PARSE_UNEXPECTED_TOKEN')]
    result += [('generic-ord-bool','generic<T> (T.value)hold() where T: Ord {value.return;}start(){true.hold().return;}','NEBO_TYPE_MISMATCH')]
    result += [('newtype-wrong-value', 'newtype UserId(Int);start(){UserId(17).unwrap();UserId(true).unwrap().return;}', 'NEBO_TYPE_MISMATCH'),
               ('newtype-text-status', 'newtype Label(Text);start(){Label("bad").unwrap().return;}', 'NEBO_ENTRYPOINT_INVALID_SIGNATURE')]
    return result


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-composite-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,options in cases()+struct_cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try: proof=pipeline(path,work,status,**options);row=dict(result='PASS',**proof)
            except Failure as error: row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives()+struct_negatives():
            work=root/('negative-'+name);work.mkdir();path=work/'source.no';path.write_text(source)
            try: proof=reject(path,work,code);row=dict(result='PASS',**proof)
            except Failure as error: row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
