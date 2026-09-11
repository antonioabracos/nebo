"""Bounded literal Regex source values; independent Python regular expressions."""
import json,re,tempfile
from pathlib import Path
from harness import ROOT,Failure,pipeline,reject
from text_test import document,literal


def cases():
    rows=[]
    def add(name,body,value,status=23):
        rows.append((name,'import "std.regex" { Regex; }.patterns;\nstart(){'+body+f'{status}.return;}}',status,document(value)))
    for p,pattern in enumerate(('', 'Nebo', 'ação', 'Ω😀', 'a\\.b', '\\(leaf\\)', 'a'*256)):
        for t,text in enumerate(('', 'Nebo', 'xxNebo29', 'uma ação', 'Ω😀 x', 'a.b', '(leaf)', 'a'*256)):
            add(f'match-{p}-{t}',f'Regex.compile({literal(pattern)}).r;r.isMatch({literal(text)}).console();',re.search(pattern,text) is not None)
    for n,text in enumerate(('', 'Nebo','ação Ω','a.b [x] (y) {z} | ^ $ * + ?', '#&~ -','line\nnext\tend','\\')):
        add('escape-'+str(n),f'Regex.escape({literal(text)}).console();',re.escape(text))
        add('escape-compose-'+str(n),f'Regex.compile(Regex.escape({literal(text)})).r;r.isMatch({literal("xx"+text+"yy")}).console();',True)
    for status in (0,7,23,29,255):
        add('return-'+str(status),'Regex.compile("Nebo").r;r.isMatch("Nebo17").console();',True,status)
    add('two-live','Regex.compile("alpha").a;Regex.compile("beta").b;a.isMatch("xxalpha").console();',True)
    add('two-live-miss','Regex.compile("alpha").a;Regex.compile("beta").b;b.isMatch("xxalpha").console();',False)
    add('input-boundary','Regex.compile("end").r;r.isMatch('+literal('x'*4093+'end')+').console();',True)
    for n,pattern in enumerate(('.', 'a*','a+','a?','^a','a$','[ab]','(a)','a|b','a{2}', '\\1','\\d','\\', 'x'*257)):
        rows.append((f'pattern-domain-{n}','import "std.regex" { Regex; }.patterns;\nstart(){Regex.compile('+literal(pattern)+');23.return;}',175,{}))
    rows.append(('text-domain','import "std.regex" { Regex; }.patterns;\nstart(){Regex.compile("x").isMatch('+literal('x'*4097)+');23.return;}',175,{}))
    rows.append(('steps-domain','import "std.regex" { Regex; }.patterns;\nstart(){Regex.compile('+literal('a'*255+'b')+').isMatch('+literal('a'*4096)+');23.return;}',175,{}))
    for n,value in enumerate(('alpha','beta')):
        source='import "std.regex" { Regex; }.patterns;\n(Text.self)matches(){Regex.compile(self).isMatch("alpha").return;}start(){'+literal(value)+'.matches().console();23.return;}'
        rows.append(('function-match-'+str(n),source,23,document(value=='alpha')))
    return rows


def negatives():
    return [(name,'import "std.regex" { Regex; }.patterns;\nstart(){'+body+'}',code) for name,body,code in [
        ('compile-type','Regex.compile(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('compile-arity','Regex.compile();23.return;','NEBO_TYPE_MISMATCH'),
        ('compile-options','Regex.compile("a",17);23.return;','NEBO_TYPE_MISMATCH'),
        ('match-type','Regex.compile("a").isMatch(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('match-arity','Regex.compile("a").isMatch("a","b");23.return;','NEBO_TYPE_MISMATCH'),
        ('escape-type','Regex.escape(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('status-type','Regex.compile("a").return;','NEBO_ENTRYPOINT_INVALID_SIGNATURE')]]


def run():
    rows=[]
    with tempfile.TemporaryDirectory(dir=ROOT/'build/tmp',prefix='nebo-g170-regex-') as directory:
        for name,source,status,opts in cases():
            w=Path(directory)/name;w.mkdir();p=w/'source.no';p.write_text(source)
            try:r=dict(result='PASS',**pipeline(p,w,status,**opts))
            except Failure as error:r=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive' if status!=175 else 'runtime-domain',**r))
        for name,source,code in negatives():
            w=Path(directory)/name;w.mkdir();p=w/'source.no';p.write_text(source)
            try:r=dict(result='PASS',**reject(p,w,code))
            except Failure as error:r=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**r))
    return dict(passed=sum(r['result']=='PASS' for r in rows),total=len(rows),cases=rows)

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
