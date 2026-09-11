#!/usr/bin/env python3
"""Native token/AST and public interpolation source-to-value observations."""
import json
import struct
import tempfile
from pathlib import Path
from harness import ROOT, Failure, execute, elf, pipeline, reject, release_artifacts
from text_test import document


def token_observation(data, source):
    if len(data)<32: raise Failure('INTERPOLATION_LEX_HEADER')
    status,count,errors,length=struct.unpack_from('<4Q',data)
    if count>2048 or length>4096 or len(data)!=32+48*count+length:
        raise Failure('INTERPOLATION_LEX_SIZE')
    literals=data[32+48*count:]
    tokens=[]
    for index in range(count):
        kind,flags,source_id,start,end,payload=struct.unpack_from('<6Q',data,32+index*48)
        if source_id!=170 or not 0<=start<=end<=len(source):raise Failure('INTERPOLATION_LEX_SPAN')
        value=None
        if flags&16:
            offset,size=payload>>32,payload&0xffffffff
            if offset+size>length:raise Failure('INTERPOLATION_LEX_LITERAL')
            value=literals[offset:offset+size]
        tokens.append(dict(kind=kind,start=start,end=end,payload=payload,value=value))
    return status,errors,tokens


def lexical_cases():
    return [
        ('plain',b'"Nebo"',[4,1],[b'Nebo'],0),
        ('numeric-field-name',b'field7:18',[2,81,3,1],[],0),
        ('reserved-numeric-slice',b'7:18',[3,190,3,1],[],1),
        ('escaped',b'"x=\\${first+29}"',[4,1],[b'x=${first+29}'],0),
        ('one',b'"x=${first+29}"',[192,193,2,60,3,194,195,1],[b'x=',b''],0),
        ('two',b'"${first}${second}"',[192,193,2,194,196,193,2,194,195,1],[b'',b'',b''],0),
        ('nested',b'"${"${17}"}"',[192,193,192,193,3,194,195,194,195,1],[b'',b'',b'',b''],0),
        ('quoted-brace',b'"${"}"}"',[192,193,4,194,195,1],[b'',b'}',b''],0),
        ('comment-brace',b'"${17 /* } */ +29}"',[192,193,3,60,3,194,195,1],[b'',b''],0),
        ('raw',b'r"${first}"',[4,1],[b'${first}'],0),
        ('missing-expression-end',b'"${first',None,None,1),
        ('missing-quote',b'"${first}tail',None,None,1),
    ]


def run_lexer(work):
    binary=ROOT/'build/tests/rf204/G170/interpolation_lexer_native'
    result=execute(['ninja','-j2',str(binary.relative_to(ROOT))],work,timeout=60)
    if result[0]:raise Failure('INTERPOLATION_LEX_BUILD')
    elf(binary)
    rows=[]
    for name,source,kinds,values,errors in lexical_cases():
        try:
            first=execute([binary],work,stdin=source,runtime=True)
            second=execute([binary],work,stdin=source,runtime=True)
            if first!=second or first[0] or first[2]:raise Failure('INTERPOLATION_LEX_REPLAY')
            status,observed_errors,tokens=token_observation(first[1],source)
            if status or observed_errors!=errors:raise Failure('INTERPOLATION_LEX_STATUS')
            if kinds is not None and [t['kind'] for t in tokens]!=kinds:raise Failure('INTERPOLATION_LEX_KINDS')
            if values is not None and [t['value'] for t in tokens if t['value'] is not None]!=values:raise Failure('INTERPOLATION_LEX_BYTES')
            for token in tokens:
                if token['kind']==193 and source[token['start']:token['end']]!=b'${':raise Failure('INTERPOLATION_START_SPAN')
                if token['kind']==194 and source[token['start']:token['end']]!=b'}':raise Failure('INTERPOLATION_END_SPAN')
                if token['kind']==3 and int(source[token['start']:token['end']])!=token['payload']:raise Failure('INTERPOLATION_INT_VALUE')
            rows.append(dict(id='lexer-'+name,result='PASS',category='native-owner'))
        except Failure as error:rows.append(dict(id='lexer-'+name,result='FAIL',failure=str(error),category='native-owner'))
    return rows


def run_ast(work):
    binary=ROOT/'build/tests/rf204/G170/interpolation_lexer_native'
    cases=[
        ('integer',b'"${17}"',[35,[9],[36,[8,17]],[9]],0),
        ('arithmetic',b'"x=${first+29}"',[35,[9],[36,[12,[7],[8,29]]],[9]],0),
        ('two',b'"${first}${second}"',[35,[9],[36,[7]],[9],[36,[7]],[9]],0),
        ('nested',b'"${"${17}"}"',[35,[9],[36,[35,[9],[36,[8,17]],[9]]],[9]],0),
        ('profile',b'"${17:fixed(2)}"',[35,[9],[36,[8,17],[13,[8,2]]],[9]],0),
        ('named-profile',b'"${17:hex(width:8)}"',[35,[9],[36,[8,17],[13,[34,[8,8]]]],[9]],0),
        ('empty-expression',b'"${}"',None,4),
        ('missing-profile-value',b'"${17:hex(width:)}"',None,4),
        ('unconsumed-token',b'"${17}" 29',None,4),
    ]
    rows=[]
    for name,source,expected,wanted in cases:
        try:
            first=execute([binary,'--ast'],work,stdin=source,runtime=True)
            second=execute([binary,'--ast'],work,stdin=source,runtime=True)
            if first!=second or first[0] or first[2]:raise Failure('INTERPOLATION_AST_REPLAY')
            data=first[1]
            if len(data)<32:raise Failure('INTERPOLATION_AST_HEADER')
            status,count,error,root=struct.unpack_from('<4Q',data)
            if count>1024 or len(data)!=32+count*80:raise Failure('INTERPOLATION_AST_SIZE')
            if status!=wanted or bool(error)!=bool(wanted):raise Failure('INTERPOLATION_AST_STATUS')
            if wanted==0:
                nodes=[struct.unpack_from('<10Q',data,32+i*80) for i in range(count)]
                seen=set()
                def tree(node_id):
                    if not 1<=node_id<=count or node_id in seen:raise Failure('INTERPOLATION_AST_OWNERSHIP')
                    seen.add(node_id);node=nodes[node_id-1]
                    kind,flags,source_id,start,end,first,sibling,nchildren,payload,payload1=node
                    if source_id!=170 or not 0<=start<=end<=len(source):raise Failure('INTERPOLATION_AST_SPAN')
                    value=[kind]
                    if kind==8:
                        if int(source[start:end])!=payload:raise Failure('INTERPOLATION_AST_INTEGER')
                        value.append(payload)
                    child=first
                    for _ in range(nchildren):
                        value.append(tree(child));child=nodes[child-1][6]
                    if child:raise Failure('INTERPOLATION_AST_CHILDREN')
                    return value
                if tree(root)!=expected:raise Failure('INTERPOLATION_AST_SHAPE')
                if nodes[root-1][3:5]!=(0,len(source)):raise Failure('INTERPOLATION_AST_ROOT_SPAN')
            rows.append(dict(id='ast-'+name,result='PASS',category='native-owner'))
        except Failure as error:rows.append(dict(id='ast-'+name,result='FAIL',failure=str(error),category='native-owner'))
    return rows


def cases():
    rows=[]
    def add(name,expr,value,prefix='',returned=23):
        rows.append((name,'start(){'+prefix+expr+'.console();'+str(returned)+'.return;}',returned,document(value)))
    for value in (0,7,23,29,255,-83):
        add('identifier-'+str(value),'"v=${number}"','v='+str(value),'('+str(value)+').number;')
    for left,right in ((17,29),(71,29),(17,83)):
        add('arithmetic-'+str(left)+'-'+str(right),'"${first+second}|${first-second}"',str(left+right)+'|'+str(left-right),f'{left}.first;{right}.second;')
    for value in ('Nebo','ação','AΩ😀',''):
        text=json.dumps(value,ensure_ascii=False)
        add('text-'+value.encode().hex(),'"[${text}]"','['+value+']',text+'.text;')
        add('pure-method-'+value.encode().hex(),'"${text.codepointCount()}"',str(len(value)),text+'.text;')
    for value in ('true','false'):
        add('bool-'+value,'"${value}"',value,value+'.value;')
    for value in (0.0,17.5,-29.25):
        add('float-'+str(value),'"${value}"',format(value,'.6f'),'('+str(value)+').value;')
    add('nested','"outer=${"inner=${17+29}"}"','outer=inner=46')
    add('literal-brace','"${"}"}"','}')
    add('comment-brace','"${17 /* } */ +29}"','46')
    add('escaped','"\\${value}"','${value}')
    add('raw','r"${value}"','${value}')
    for returned in (0,7,23,29,255):
        add('explicit-return-'+str(returned),'"${17+29}"','46',returned=returned)
    for value in (17.5,-29.25,0.0):
        for precision in (0,2,6):
            for profile,spec in (('fixed','f'),('scientific','e')):
                add(profile+'-'+str(value)+'-'+str(precision),'"${value:'+profile+'('+str(precision)+')}"',format(value,'.'+str(precision)+spec),'('+str(value)+').value;')
    for value in (7,29,255):
        for profile,spec in (('hex','x'),('octal','o'),('binary','b'),('decimal','d')):
            add(profile+'-'+str(value),'"${value:'+profile+'()}"',format(value,spec),'('+str(value)+').value;')
            add(profile+'-width-'+str(value),'"${value:'+profile+'(width:8)}"',format(value,'8'+spec),'('+str(value)+').value;')
    for value in ('Nebo','ação',''):
        for side in ('left','right','center'):
            n=max(0,9-len(value.encode()));left=0 if side=='left' else n if side=='right' else n//2
            add('align-'+side+'-'+value.encode().hex(),'"[${value:align('+side+',9)}]"','['+' '*left+value+' '*(n-left)+']',json.dumps(value,ensure_ascii=False)+'.value;')
    for profile in ('text','quote','json'):
        value='ação"Nebo'; expected=value if profile=='text' else json.dumps(value,ensure_ascii=False)
        add('profile-'+profile,'"${value:'+profile+'()}"',expected,json.dumps(value,ensure_ascii=False)+'.value;')
    add('nested-profile','"outer=${"${29:hex(width:8)}"}"','outer=      1d')
    add('numeric-method','"${81.sqrt()}"','9')
    for count in (1,32,64):
        add('segments-'+str(count),'"'+''.join('${'+str(i)+'}' for i in range(count))+'"',''.join(map(str,range(count))))
    for depth in (2,8,16):
        expression='17'
        for _ in range(depth):expression='"${'+expression+'}"'
        add('nesting-'+str(depth),expression,'17')
    for length in (4095,4096):
        add('template-bytes-'+str(length),'"'+'x'*(length-5)+'${17}"','x'*(length-5)+'17')
    rows.extend([
        ('pure-transitive','(Int.x)plus(){(x+29).return;}(Int.x)twice(){(x.plus()+7).return;}start(){"${17.twice()}".console();23.return;}',23,document('53')),
        ('pure-text-callee','(Text.x)count(){x.codepointCount().return;}start(){"${"ação".count()}".console();23.return;}',23,document('4')),
        ('pure-binding-callee','(Int.x)plus(){(x+29).value;value.return;}start(){"${17.plus()}".console();23.return;}',23,document('46')),
        ('pure-function','(Int.x)plus(){(x+29).return;}start(){"${17.plus()}".console();23.return;}',23,document('46')),
        ('silent','start(){"${17+29}";23.return;}',23,{}),
        ('two-live','start(){"${17}".one;"${29}".two;one.console();two.console();one.console();23.return;}',23,dict(kinds=[2,2,2],text=b'172917')),
        ('mutable-snapshot','start(){17.value.mutable;"${value}".first;value=29;"${value}".second;first.console();second.console();23.return;}',23,dict(kinds=[2,2],text=b'1729')),
    ])
    return rows


def negatives():
    rows=[]
    def add(name,expr,code='NEBO-FORMAT-003',prefix=''):
        rows.append((name,'start(){'+prefix+'"${'+expr+'}";23.return;}',code))
    add('effect-console','17.console()','NEBO_INTERPOLATION_EFFECT_FORBIDDEN')
    add('effect-nested-console','"${17.console()}"','NEBO_INTERPOLATION_EFFECT_FORBIDDEN')
    add('effect-unknown','17.unknown()','NEBO_INTERPOLATION_EFFECT_FORBIDDEN')
    add('missing-name','absent','NEBO-FORMAT-003')
    for profile,value in [('fixed','17'),('scientific','true'),('hex','"Nebo"'),('align','17')]:
        args='right,8' if profile=='align' else '2'
        add('wrong-type-'+profile,value+':'+profile+'('+args+')')
    add('unknown-profile','17:absent(2)','NEBO-FORMAT-001')
    add('precision-limit','17.5:fixed(7)','NEBO-FORMAT-004')
    add('width-limit','17:hex(width:257)','NEBO-FORMAT-004')
    add('width-type','17:hex(width:true)')
    add('width-name','17:hex(other:8)','NEBO-FORMAT-005')
    add('profile-arity','17.5:fixed()','NEBO-FORMAT-002')
    add('profile-extra','17.5:fixed(2,3)','NEBO-FORMAT-002')
    add('align-side','"Nebo":align(unknown,8)')
    add('align-width','"Nebo":align(right,false)')
    rows.extend([
        ('segments-limit','start(){"'+'${17}'*65+'";23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('template-prefix-limit','start(){"'+'x'*4093+'${17}";23.return;}','NEBO_LIMIT_EXCEEDED'),
        ('template-tail-limit','start(){"${17}'+'x'*4093+'";23.return;}','NEBO_LIMIT_EXCEEDED'),
    ])
    nested='17'
    for _ in range(17):nested='"${'+nested+'}"'
    rows.append(('nesting-limit','start(){'+nested+';23.return;}','NEBO_LIMIT_EXCEEDED'))
    rows.append(('effect-transitive','(Int.x)plus(){x.console();x.return;}(Int.x)twice(){x.plus().return;}start(){"${17.twice()}";23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    rows.append(('effect-mutable','(Int.x)plus(){x.value.mutable;value+=1;value.return;}start(){"${17.plus()}";23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    rows.append(('effect-function','(Int.x)plus(){x.console();(x+29).return;}start(){"${17.plus()}";23.return;}','NEBO_INTERPOLATION_EFFECT_FORBIDDEN'))
    return rows


def run_equivalence(work):
    rows=[]
    pairs=[
        ('decimal','"%d".format(29)','"${29}"','29'),
        ('fixed','"%.2f".format(17.5)','"${17.5:fixed(2)}"','17.50'),
        ('hex','"%8x".format(29)','"${29:hex(width:8)}"','      1d'),
        ('align','"%8s".format("ação")','"${"ação":align(right,8)}"','  ação'),
        ('pure-once','"%d".format(17.plus())','"${17.plus()}"','46'),
    ]
    for name,a,b,value in pairs:
        proof=[]
        try:
            for style,expression in (('A',a),('B',b)):
                case=work/('equivalence-'+name+'-'+style);case.mkdir();path=case/'source.no'
                prefix='(Int.x)plus(){(x+29).return;}' if name=='pure-once' else ''
                path.write_text(prefix+'start(){'+expression+'.console();23.return;}')
                try:
                    result=pipeline(path,case,23,keep_artifacts=True,**document(value))
                    assembly=(case/'root-0/program.asm').read_text()
                    calls=[line.strip() for line in assembly.splitlines() if line.strip().startswith('call ')]
                    if calls.count('call nebo_runtime_textual_format_prepare_plan')!=1:raise Failure('INTERPOLATION_STATIC_PLAN_MISSING')
                    if any(line in calls for line in ('call nebo_runtime_textual_format_prepare','call neboc_percent_compile_request')):
                        raise Failure('INTERPOLATION_STATIC_REPARSED')
                    if name=='pure-once' and calls.count('call nebo_fn_2')!=1:raise Failure('INTERPOLATION_CALL_NOT_ONCE')
                    proof.append(result)
                finally:release_artifacts(case)
            if proof[0]['runtime_sha256']!=proof[1]['runtime_sha256']:raise Failure('INTERPOLATION_AB_EFFECT_MISMATCH')
            rows.append(dict(id='equivalence-'+name,result='PASS',category='metamorphic',variants=proof))
        except Failure as error:rows.append(dict(id='equivalence-'+name,result='FAIL',failure=str(error),category='metamorphic'))
    return rows


def run():
    with tempfile.TemporaryDirectory(prefix='nebo-G170-interpolation-') as directory:
        work=Path(directory)
        rows=run_lexer(work)+run_ast(work)
        source=ROOT/'tests/rf204/G170/reproducers/interpolation-value.no'
        case=work/'source-value';case.mkdir()
        try:
            proof=pipeline(source,case,23,**document('sum=46'))
            rows.append(dict(id='source-value',result='PASS',category='positive',**proof))
        except Failure as error:rows.append(dict(id='source-value',result='FAIL',failure=str(error),category='positive'))
        for negative,matrix in ((False,cases()),(True,negatives())):
            for name,source,expected,*options in matrix:
                case=work/name;case.mkdir();path=case/'source.no';path.write_text(source)
                try:
                    proof=reject(path,case,expected) if negative else pipeline(path,case,expected,**options[0])
                    row=dict(result='PASS',**proof)
                except Failure as error:row=dict(result='FAIL',failure=str(error))
                rows.append(dict(id=name,category='negative' if negative else 'positive',**row))
        rows.extend(run_equivalence(work))
        from interpolation_tooling_test import run as run_tooling
        rows.extend(run_tooling(work))
    return dict(passed=sum(r['result']=='PASS' for r in rows),total=len(rows),cases=rows)


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
