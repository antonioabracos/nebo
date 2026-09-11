#!/usr/bin/env python3
"""Current Text/Unicode source methods with independent byte/value oracles."""
import json
import tempfile
import unicodedata
import hashlib
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf


def literal(value):
    return json.dumps(value, ensure_ascii=False)


def document(value):
    if isinstance(value, bool):
        return dict(kinds=[5], text=str(value).lower().encode())
    if isinstance(value, int):
        return dict(kinds=[4], text=str(value).encode())
    # Retained Console splits Text newlines into text and line-break nodes.
    lines=value.split('\n')
    kinds=[]
    for index, line in enumerate(lines):
        if line: kinds.append(2)
        if index+1<len(lines): kinds.append(3)
    return dict(kinds=kinds, text=value.encode(), publications=1)


def cases():
    rows=[]
    def add(name, expression, expected, returned=23):
        rows.append((name, 'start(){'+expression+'.console();'+str(returned)+'.return;}', returned, document(expected)))
    values=('', 'Nebo', 'ação', 'AΩ😀', 'e\u0301x', '👩\u200d👩\u200d👧\u200d👦')
    for index, value in enumerate(values):
        add(f'bytes-{index}', literal(value)+'.byteLength()', len(value.encode()))
        add(f'codepoints-{index}', literal(value)+'.codepointCount()', len(value))
    for index, (value, count) in enumerate((('',0),('Nebo',4),('e\u0301x',2),('a\r\nb',3),('👩\u200d👩\u200d👧\u200d👦',1))):
        add(f'graphemes-{index}', literal(value)+'.graphemeCount()', count)
    # Unicode profile 15.1 supports ASCII and this canonical acute pair.
    for index,value in enumerate(('', 'Nebo', 'e\u0301', 'é', 'Cafe\u0301')):
        for method, form in [('normalizeNfc','NFC'),('normalizeNfd','NFD')]:
            add(f'{method}-{index}', literal(value)+'.'+method+'()', unicodedata.normalize(form,value))
    # Root simple one-to-one Latin-1 folding, not full expanding casefold.
    for index,value in enumerate(('', 'NEBO', 'ÀÉÖ', 'ação', 'AZaz')):
        add(f'caseFold-{index}', literal(value)+'.caseFold()', value.lower())
    for index, (value, start, count) in enumerate((('AΩ😀Z',0,2),('AΩ😀Z',1,2),('AΩ😀Z',3,1),('AΩ😀Z',4,0),('',0,0))):
        add(f'slice-codepoints-{index}', literal(value)+f'.sliceCodepoints({start},{count})',value[start:start+count])
    for index,(clusters,start,count) in enumerate(((['e\u0301','x'],0,1),(['e\u0301','x'],1,1),(['a','\r\n','b'],1,1),(['👩\u200d👩\u200d👧\u200d👦','x'],0,1),(['e\u0301','x'],2,0))):
        add(f'slice-graphemes-{index}',literal(''.join(clusters))+f'.sliceGraphemes({start},{count})',''.join(clusters[start:start+count]))
    for value in ('', 'Nebo', ' ', '123', 'aB9', 'ação'):
        tag=value.encode().hex() or 'empty'
        methods={'isEmpty':not value, 'isAscii':value.isascii(), 'isUtf8':True,
                 'isBlank':all(c in ' \t\r\n' for c in value),
                 'isDigits':bool(value) and value.isascii() and value.isdigit(),
                 'isAlphaAscii':bool(value) and value.isascii() and value.isalpha(),
                 'isAlnumAscii':bool(value) and value.isascii() and value.isalnum()}
        for method, expected in methods.items():
            add(method+'-'+tag,literal(value)+'.'+method+'()',expected)
    for index,(value,needle) in enumerate((('Nebo Nebo','Nebo'),('ação','ç'),('Nebo','absent'),('',''),('Nebo',''))):
        for method,expected in [('contains',needle in value),('startsWith',value.startswith(needle)),('endsWith',value.endswith(needle)),('equals',value==needle),('indexOf',value.encode().find(needle.encode())),('lastIndexOf',value.encode().rfind(needle.encode()))]:
            expression=literal(value)+'.'+method+'('+literal(needle)+')'
            if method in ('indexOf','lastIndexOf'): expression+='.unwrapOr(-1)'
            add(method+'-'+str(index),expression,expected)
    for index,value in enumerate(('  Nebo  ','\tNebo\n','', 'Nebo')):
        for method,expected in [('trim',value.strip(' \t\r\n')),('trimStart',value.lstrip(' \t\r\n')),('trimEnd',value.rstrip(' \t\r\n')),('lower',value.lower()),('upper',value.upper())]:
            add(method+'-'+str(index),literal(value)+'.'+method+'()',expected)
    for index,(left,right) in enumerate((('NEBO','nebo'),('É','é'),('Ab9','aB9'),('',''),('a','ab'))):
        fold=lambda s: bytes(c+32 if 65<=c<=90 else c for c in s.encode())
        add('equals-ascii-'+str(index),literal(left)+'.equalsAsciiIgnoreCase('+literal(right)+')',fold(left)==fold(right))
        add('concat-'+str(index),literal(left)+'.concat('+literal(right)+')',left+right)
    for index,value in enumerate(('A\r\nB\rC',' \tNebo  language\n','', 'a\n\nb')):
        add('newlines-'+str(index),literal(value)+'.normalizeNewlines()',value.replace('\r\n','\n').replace('\r','\n'))
        add('whitespace-'+str(index),literal(value)+'.normalizeWhitespace()',' '.join(value.split()))
    for index,(value,start,end) in enumerate((('AΩ😀Z',0,3),('AΩ😀Z',1,7),('Nebo',1,3),('Nebo',4,4),('',0,0))):
        add('byte-slice-'+str(index),literal(value)+f'.byteSlice({start},{end})',value.encode()[start:end].decode())
    for index,(value,count) in enumerate((('Nebo',0),('Nebo',2),('Nebo',4),('Nebo',7),('',0),('AΩZ',3))):
        for method,expected in [('takeBytes',value.encode()[:count]),('dropBytes',value.encode()[count:])]:
            add(method+'-'+str(index),literal(value)+'.'+method+f'({count})',expected.decode())
    for index,(value,old,new) in enumerate((('Nebo Nebo','Nebo','Lang'),('aaaa','aa','Z'),('ação ação','ação','é'),('Nebo','x','y'),('','a','b'))):
        for method,limit in [('replaceOnce',1),('replaceAll',-1)]:
            add(method+'-'+str(index),literal(value)+'.'+method+'('+literal(old)+','+literal(new)+')',value.replace(old,new,limit))
    for index,(value,separator,joined) in enumerate((('a,b,c',',','/'),('a,,b,',',','|'),('',',','/'),('ação::Nebo','::','é'),('Nebo',',','-'))):
        add('split-join-'+str(index),literal(value)+'.split('+literal(separator)+').join('+literal(joined)+')',joined.join(value.split(separator)))
    for index,(value,width,fill) in enumerate((('Nebo',7,'.'),('Nebo',4,'.'),('Nebo',2,'.'),('',3,'x'),('A',6,'ab'))):
        padding=(fill*((max(0,width-len(value))+len(fill)-1)//len(fill)))[:max(0,width-len(value))]
        add('pad-start-'+str(index),literal(value)+'.padStart('+str(width)+','+literal(fill)+')',padding+value)
        add('pad-end-'+str(index),literal(value)+'.padEnd('+str(width)+','+literal(fill)+')',value+padding)
    rows.extend([
        ('two-live-normalized','start(){"é".normalizeNfc().one;"Nebo".normalizeNfd().two;one.console();two.console();one.console();23.return;}',23,dict(kinds=[2,2,2],text='éNeboé'.encode())),
        ('explicit-return-7','start(){"É".caseFold().console();7.return;}',7,document('é')),
        ('query-live-store','start(){"Nebo".text.mutable;text.contains("N").console();text="Lang";text.contains("N").console();23.return;}',23,dict(kinds=[5,5],text=b'truefalse')),
        ('query-two-live-options','start(){"Nebo".indexOf("N").one;"language".indexOf("g").two;one.unwrapOr(-1).console();two.unwrapOr(-1).console();one.unwrapOr(-1).console();23.return;}',23,dict(kinds=[4,4,4],text=b'030')),
        ('query-runtime-fallback','start(){(-7).fallback.mutable;"Nebo".indexOf("missing").one;one.unwrapOr(fallback).console();fallback=29;one.unwrapOr(fallback).console();23.return;}',23,dict(kinds=[4,4],text=b'-729')),
        ('bound-normalize','start(){"é".text.mutable;text.normalizeNfc().one;text="Nebo";text.normalizeNfd().two;one.console();two.console();23.return;}',23,dict(kinds=[2,2],text='éNebo'.encode())),
        ('bound-split','start(){"a,b".text;text.split(",").parts;parts.join("/").console();23.return;}',23,document('a/b')),
    ])
    for method in ('normalizeNfc','normalizeNfd','caseFold'):
        for size in (4095,4096,4097):
            source='start(){'+literal('x'*size)+'.'+method+'().byteLength().console();23.return;}'
            rows.append((method+'-capacity-'+str(size),source,23 if size<=4096 else 170,document(size) if size<=4096 else {}))
    for returned in (0,7,29,255):
        rows.append(('transform-return-'+str(returned),'start(){"NEBO".lower().console();'+str(returned)+'.return;}',returned,document('nebo')))
    for method in ('sliceCodepoints','sliceGraphemes'):
        rows.append((method+'-bounds','start(){"Nebo".'+method+'(5,1).console();23.return;}',170,{}))
    rows.append(('transform-stack-budget','start(){0.i.mutable;while(i<2048){"Nebo".normalizeNfc();i+=1;}23.return;}',178,{}))
    return rows


def negatives():
    rows=[(name,'start(){'+body+'23.return;}',code) for name,body,code in [
        ('normalize-arity','"é".normalizeNfc(1);','NEBO-TEXT-TRANSFORM-ARITY'),
        ('grapheme-arity','"é".graphemeCount(1);','NEBO-TEXT-TRANSFORM-ARITY'),
        ('slice-start-type','"Nebo".sliceCodepoints(true,1);','NEBO-TEXT-TRANSFORM-INT-ARGUMENT'),
        ('slice-count-type','"Nebo".sliceGraphemes(0,false);','NEBO-TEXT-TRANSFORM-INT-ARGUMENT'),
        ('query-type','"Nebo".contains(17);','NEBO-TEXT-QUERY-ARGUMENT-MUST-BE-TEXT'),
        ('query-arity','"Nebo".contains("N", "e");','NEBO-TEXT-QUERY-ARITY'),
        ('trim-arity','"Nebo".trim(1);','NEBO-TEXT-TRANSFORM-ARITY'),
    ]]
    for method in ('byteLength','codepointCount','isEmpty','isAscii','isUtf8','isBlank','isDigits','isAlphaAscii','isAlnumAscii'):
        rows.append(('arity-'+method,'start(){"Nebo".'+method+'(1);23.return;}','NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-ARGUMENTS-NOT-ALLOWED'))
    for method in ('equals','equalsAsciiIgnoreCase','startsWith','endsWith','contains','indexOf','lastIndexOf'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(17);23.return;}','NEBO-TEXT-QUERY-ARGUMENT-MUST-BE-TEXT'))
    for method in ('trim','trimStart','trimEnd','lower','upper','normalizeNewlines','normalizeWhitespace','normalizeNfc','normalizeNfd','caseFold','graphemeCount'):
        rows.append(('arity-'+method,'start(){"Nebo".'+method+'(1);23.return;}','NEBO-TEXT-TRANSFORM-ARITY'))
    for method in ('concat','split'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(17);23.return;}','NEBO-TEXT-TRANSFORM-TEXT-ARGUMENT'))
    for method in ('replaceOnce','replaceAll'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(17,"x");23.return;}','NEBO-TEXT-TRANSFORM-TEXT-ARGUMENT'))
    for method in ('takeBytes','dropBytes'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(false);23.return;}','NEBO-TEXT-TRANSFORM-INT-ARGUMENT'))
    for method in ('byteSlice','sliceCodepoints','sliceGraphemes'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(false,1);23.return;}','NEBO-TEXT-TRANSFORM-INT-ARGUMENT'))
    for method in ('padStart','padEnd'):
        rows.append(('type-'+method,'start(){"Nebo".'+method+'(false,".");23.return;}','NEBO-TEXT-TRANSFORM-INT-ARGUMENT'))
    rows.append(('type-join','start(){"a,b".split(",").join(17);23.return;}','NEBO-TEXT-TRANSFORM-TEXT-ARGUMENT'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-text-') as directory:
        root=Path(directory)
        targets=['rf204-g054-adversarial-tests','rf204-g055-adversarial-tests','rf204-g057-adversarial-tests']
        code,out,err=execute(['ninja','-j2',*targets],root,timeout=90)
        if code or err:raise Failure('TEXT_NATIVE_BUILD:'+str(code)+':'+err.decode(errors='replace'))
        for group,name in [('G054','g054_adversarial_test'),('G055','g055_adversarial_test'),('G057','g057_adversarial_test'),('G057','g057_api_contract_test')]:
            binary=ROOT/'build/tests/rf204'/group/name
            elf(binary)
            result=execute([binary],root,runtime=True)
            if result!=(0,b'',b''):raise Failure('TEXT_NATIVE_OWNER:'+name+':'+str(result))
            rows.append(dict(id='native-'+name,category='native-control',result='PASS',elf_sha256=hashlib.sha256(binary.read_bytes()).hexdigest()))
        for negative,matrix in ((False,cases()),(True,negatives())):
            for name,source,expected,*options in matrix:
                work=Path(directory)/name;work.mkdir()
                path=work/'source.no';path.write_text(source)
                try:
                    if negative:
                        marker={'slice-start-type':b'true','slice-count-type':b'false','query-type':b'17'}.get(name)
                        offset=source.encode().index(marker) if marker else None
                        proof=reject(path,work,expected,span=(offset,offset+len(marker)) if marker else None)
                    else: proof=pipeline(path,work,expected,**options[0])
                    row=dict(result='PASS',**proof)
                except Failure as error:row=dict(result='FAIL',failure=str(error))
                rows.append(dict(id=name,category='negative' if negative else 'positive',**row))
    return dict(cases=rows,passed=sum(x['result']=='PASS' for x in rows),total=len(rows),unicode_profile='15.1-bounded-acute-and-simple-latin1',oracle_unicode_version=unicodedata.unidata_version)


if __name__=='__main__':
    print(json.dumps(run(),sort_keys=True))
