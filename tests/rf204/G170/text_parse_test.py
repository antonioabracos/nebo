#!/usr/bin/env python3
"""Typed Text parsing/conversion: independently observed values and errors."""
import hashlib
import json
import tempfile
import re
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf
from text_test import literal, document


def cases():
    rows=[]
    def add(name, expression, expected):
        rows.append((name,'start(){'+expression+'.console();23.return;}',23,document(expected)))
    for value in (0,7,-29,83,9223372036854775807,-9223372036854775808):
        add('parse-int-'+str(value),literal(str(value))+'.parseInt().unwrapOr(17)',value)
    for index,value in enumerate(('', 'x', '17x', '9223372036854775808', '-9223372036854775809', '+17',' 17')):
        add('parse-int-error-'+str(index),literal(value)+'.parseInt().unwrapOr(-31)',-31)
        add('parse-int-tag-'+str(index),literal(value)+'.parseInt().isErr()',True)
    for index,value in enumerate(('true','false','True','FALSE','','0')):
        add('parse-bool-'+str(index),literal(value)+'.parseBool().unwrapOr(true)',value!='false')
        add('parse-bool-tag-'+str(index),literal(value)+'.parseBool().isOk()',value in ('true','false'))
    for index,value in enumerate(('0.0','17.5','-29.25','83.75')):
        add('parse-float-'+str(index),'('+literal(value)+'.parseFloat().unwrapOr(0.0)=='+value+')',True)
    for index,value in enumerate(('', '17,5','1.2.3','1e3','9223372036854775808','1.')):
        add('parse-float-error-'+str(index),literal(value)+'.parseFloat().isErr()',True)
    for index,value in enumerate(('', 'Nebo', 'ação', 'e\u0301')):
        add('text-copy-'+str(index),literal(value)+'.toText()',value)
    for value in (0,17,-29,83,9223372036854775807,-9223372036854775808):
        add('int-text-'+str(value),'('+str(value)+').toText()',str(value))
    for value in (True,False):
        add('bool-text-'+str(value),str(value).lower()+'.toText()',str(value).lower())
    for index,value in enumerate(('a','_','Nebo_17','17Nebo','','a b','ação','start','return','while')):
        add('identifier-'+str(index),literal(value)+'.isNeboIdentifier()',index<3)
    for index,(value,old,new) in enumerate((('a::b','::','/'),('a::a','a','Nebo'),('abc','','X'))):
        add('checked-split-tag-'+str(index),literal(value)+'.splitChecked('+literal(old)+').isOk()',bool(old))
        add('checked-replace-tag-'+str(index),literal(value)+'.replaceAllChecked('+literal(old)+','+literal(new)+').isErr()',not old)
        if old:
            add('checked-split-value-'+str(index),literal(value)+'.splitChecked('+literal(old)+').unwrapOr("fallback".split(",")).join("/")','/'.join(value.split(old)))
            add('checked-replace-value-'+str(index),literal(value)+'.replaceAllChecked('+literal(old)+','+literal(new)+').unwrapOr("fallback")',value.replace(old,new))
    rows.extend([
        ('two-live-results','start(){"17".parseInt().one;"83".parseInt().two;one.unwrapOr(0).console();two.unwrapOr(0).console();one.unwrapOr(0).console();23.return;}',23,dict(kinds=[4,4,4],text=b'178317')),
        ('bound-input','start(){"17".input.mutable;input.parseInt().one;input="83";input.parseInt().two;one.unwrapOr(0).console();two.unwrapOr(0).console();23.return;}',23,dict(kinds=[4,4],text=b'1783')),
        ('bound-conversion','start(){(-29).value;value.toText().text;text.console();23.return;}',23,document('-29')),
        ('fallback-effect-once','(Int.x)fallback(){71.console();x.return;} start(){"17".parseInt().unwrapOr(29.fallback()).console();23.return;}',23,dict(kinds=[4,4],text=b'7117')),
    ])
    for keyword in re.findall(r"^kw_\w+: db '([^']+)'",(ROOT/'compiler/tokens/keyword_table.inc').read_text(),re.M):
        add('keyword-'+keyword,literal(keyword)+'.isNeboIdentifier()',False)
    for returned in (0,7,29,255):
        rows.append(('return-'+str(returned),'start(){"71".parseInt().unwrapOr(0).console();'+str(returned)+'.return;}',returned,document(71)))
    for size in (4095,4096,4097):
        rows.append(('conversion-capacity-'+str(size),'start(){'+literal('x'*size)+'.toText().byteLength().console();23.return;}',23 if size<=4096 else 170,document(size) if size<=4096 else {}))
        add('replace-capacity-'+str(size),literal('x'*size)+'.replaceAllChecked("x","y").isOk()',size<=4096)
    for count in (1,253,254,255):
        value=','.join(['x']*count)
        add('split-capacity-'+str(count),literal(value)+'.splitChecked(",").isOk()',count<=254)
        add('split-fallback-'+str(count),literal(value)+'.splitChecked(",").unwrapOr("fallback".split(",")).join("/")','/'.join(['x']*count) if count<=254 else 'fallback')
    for index,(value,pattern,replacement) in enumerate((('abc','','x'),('x'*4097,'x','y'))):
        add('replace-fallback-'+str(index),literal(value)+'.replaceAllChecked('+literal(pattern)+','+literal(replacement)+').unwrapOr("fallback")','fallback')
    rows.extend([
        ('two-live-checked','start(){"aba".replaceAllChecked("a","Nebo").one;"xyx".replaceAllChecked("x","Lang").two;one.unwrapOr("bad").console();two.unwrapOr("bad").console();one.unwrapOr("bad").console();23.return;}',23,dict(kinds=[2,2,2],text=b'NebobNeboLangyLangNebobNebo')),
        ('two-live-float','start(){"17.5".parseFloat().one;"83.25".parseFloat().two;(one.unwrapOr(0.0)==17.5).console();(two.unwrapOr(0.0)==83.25).console();23.return;}',23,dict(kinds=[5,5],text=b'truetrue')),
        ('float-error-value','start(){("bad".parseFloat().unwrapOr(-29.25)==(-29.25)).console();23.return;}',23,document(True)),
        ('checked-error-preserves-input','start(){"Nebo".value;value.replaceAllChecked("","x").isErr().console();value.console();23.return;}',23,dict(kinds=[5,2],text=b'trueNebo')),
        ('conversion-stack-budget','start(){0.i.mutable;while(i<2048){"Nebo".toText();i+=1;}23.return;}',178,{}),
    ])
    return rows


def negatives():
    rows=[('arity-'+name,'start(){"Nebo".'+name+'(1);23.return;}','NEBO-TEXT-PARSE-ARITY')
            for name in ('parseInt','parseFloat','parseBool','toText','isNeboIdentifier')]
    rows.extend([
        ('arity-splitChecked','start(){"Nebo".splitChecked();23.return;}','NEBO-TEXT-PARSE-ARITY'),
        ('arity-replaceAllChecked','start(){"Nebo".replaceAllChecked("x");23.return;}','NEBO-TEXT-PARSE-ARITY'),
        ('type-splitChecked','start(){"Nebo".splitChecked(17);23.return;}','NEBO-TEXT-TRANSFORM-TEXT-ARGUMENT'),
        ('type-replaceAllChecked','start(){"Nebo".replaceAllChecked("x",false);23.return;}','NEBO-TEXT-TRANSFORM-TEXT-ARGUMENT'),
    ])
    for name,producer,fallback in [('Int','"17".parseInt()','true'),('Bool','"true".parseBool()','17'),('Float','"1.5".parseFloat()','1'),('Text','"abc".replaceAllChecked("a","x")','17'),('Split','"a,b".splitChecked(",")','"fallback"')]:
        rows.append(('fallback-type-'+name,'start(){'+producer+'.unwrapOr('+fallback+');23.return;}','NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-FALLBACK-TYPE-MISMATCH'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-text-parse-') as directory:
        root=Path(directory)
        code,out,err=execute(['ninja','-j2','rf204-g056-adversarial-tests'],root,timeout=90)
        if code or err:raise Failure('TEXT_PARSE_NATIVE_BUILD:'+str(code)+':'+err.decode(errors='replace'))
        for name in ('g056_adversarial_test','g056_api_contract_test'):
            binary=ROOT/'build/tests/rf204/G056'/name
            elf(binary)
            observed=execute([binary],root,runtime=True)
            if observed!=(0,b'',b''):raise Failure('TEXT_PARSE_NATIVE:'+name+':'+str(observed))
            rows.append(dict(id='native-'+name,category='native-control',result='PASS',elf_sha256=hashlib.sha256(binary.read_bytes()).hexdigest()))
        for negative,matrix in ((False,cases()),(True,negatives())):
            for name,source,expected,*options in matrix:
                work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
                try:
                    proof=reject(path,work,expected) if negative else pipeline(path,work,expected,**options[0])
                    row=dict(result='PASS',**proof)
                except Failure as error:row=dict(result='FAIL',failure=str(error))
                rows.append(dict(id=name,category='negative' if negative else 'positive',**row))
    return dict(cases=rows,passed=sum(x['result']=='PASS' for x in rows),total=len(rows))


if __name__=='__main__':
    print(json.dumps(run(),sort_keys=True))
