"""Actual typed Path/File values versus lexical and private filesystem oracles."""
import json
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject
from text_test import document, literal


def cases():
    rows=[]
    def add(name,body,expected,status=23,**opts):
        source='import "std.fs" { Path; File; }.fs;\nstart(){'+body+f'{status}.return;}}'
        rows.append((name,source,status,dict(document(expected),**opts)))
    for n,(text,filename,absolute) in enumerate([('alpha/./beta.txt','beta.txt',False),
        ('/usr//share/font.txt','font.txt',True),('ação/Ω.dat','Ω.dat',False),
        ('a/b/../last','last',False),('/', '',True),('x'*255,'x'*255,False)]):
        add(f'path-name-{n}',f'Path.parse({literal(text)}).fileName().console();',filename)
        add(f'path-absolute-{n}',f'Path.parse({literal(text)}).isAbsolute().console();',absolute)
    for status in (0,7,23,29,255):
        add(f'path-return-{status}','Path.parse("one.txt").a;Path.parse("two.bin").b;a.fileName().console();', 'one.txt',status)
    add('path-independent','Path.parse("first.txt").a;Path.parse("second.bin").b;a.normalize().fileName().console();','first.txt')
    add('path-join','Path.parse("folder").a;Path.parse("child/../third.txt").b;a.join(b).normalize().fileName().console();','third.txt')
    for n,data in enumerate((b'',b'Nebo17',b'Nebo29', 'ação Ω\n'.encode(),b'x'*4096)):
        add(f'read-{n}','Path.parse("input.txt").p;File.readText(p,utf8,4096).console();',data.decode(),inputs={'input.txt':data})
    for status in (0,7,23,29,255):
        add(f'read-return-{status}','Path.parse("input.txt").p;File.readText(p,utf8,64).console();','Nebo83',status,inputs={'input.txt':b'Nebo83'})
    for name in ('first.txt','second.txt'):
        add('read-path-'+name,f'Path.parse("{name}").p;File.readText(p,utf8,64).console();',
            'alpha' if name=='first.txt' else 'beta',inputs={'first.txt':b'alpha','second.txt':b'beta'})
    for mode in ('truncate','append','atomic'):
        for n,text in enumerate(('', 'Nebo17', 'Nebo29', 'ação\n')):
            existing=b'before' if mode=='append' else b'old'
            final=(existing if mode=='append' else b'')+text.encode()
            expected_files={} if final==existing else {'output.txt':final}
            add(f'write-{mode}-{n}',f'Path.parse("output.txt").p;File.writeText(p,{literal(text)},utf8,{mode});File.readText(p,utf8,64).console();',
                final.decode(),inputs={'output.txt':existing},expected_files=expected_files)
    add('write-created','Path.parse("new.txt").p;File.writeText(p,"Nebo71",utf8,atomic).console();',6,expected_files={'new.txt':b'Nebo71'})
    add('read-close-loop','Path.parse("input.txt").p;0.i.mutable;0.total.mutable;while(i<512){File.readText(p,utf8,8).t;total+=t.byteLength();i+=1;}total.console();',1536,inputs={'input.txt':b'abc'})
    # Valid source, invalid runtime data: no negative-source binary executes.
    for name,text in [('empty',''),('escape','../outside'),('nul','bad\0path'),('component','x'*256),('depth','/'.join(['a']*65))]:
        rows.append(('path-domain-'+name,'import "std.fs" { Path; File; }.fs;\nstart(){Path.parse('+(literal(text) if name!='nul' else '"bad\0path"')+').fileName().console();23.return;}',175,{}))
    for name,body,inputs in [
        ('missing','File.readText(Path.parse("absent.txt"),utf8,64);',{}),
        ('encoding','File.readText(Path.parse("input.txt"),utf8,64);',{'input.txt':b'\xff'}),
        ('bound','File.readText(Path.parse("input.txt"),utf8,3);',{'input.txt':b'abcd'}),
        ('zero','File.readText(Path.parse("input.txt"),utf8,0);',{'input.txt':b'abc'}),
        ('negative','File.readText(Path.parse("input.txt"),utf8,-1);',{'input.txt':b'abc'}),
        ('absolute','File.readText(Path.parse("/unauthorized"),utf8,64);',{})]:
        rows.append(('file-domain-'+name,'import "std.fs" { Path; File; }.fs;\nstart(){'+body+'23.return;}',175,dict(inputs=inputs)))
    for n,path in enumerate(('alpha/x.txt','beta/longer.bin')):
        source='import "std.fs" { Path; File; }.fs;\n(Text.self)nameLength(){Path.parse(self).fileName().byteLength().return;}start(){'+literal(path)+'.nameLength().console();23.return;}'
        rows.append(('function-chain-'+str(n),source,23,document(len(path.rsplit('/',1)[-1].encode()))))
    return rows


def negatives():
    return [(name,'import "std.fs" { Path; File; }.fs;\nstart(){'+body+('' if name=='path-status' else '23.return;')+'}',code) for name,body,code in [
        ('path-type','Path.parse(17);','NEBO_TYPE_MISMATCH'),
        ('path-arity','Path.parse("a","b");','NEBO_TYPE_MISMATCH'),
        ('path-join-type','Path.parse("a").join("b");','NEBO_TYPE_MISMATCH'),
        ('path-method-arity','Path.parse("a").fileName(17);','NEBO_TYPE_MISMATCH'),
        ('path-status','Path.parse("a").return;','NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
        ('read-path-type','File.readText("a",utf8,64);','NEBO_TYPE_MISMATCH'),
        ('read-limit-type','File.readText(Path.parse("a"),utf8,true);','NEBO_TYPE_MISMATCH'),
        ('encoding-policy','File.readText(Path.parse("a"),latin1,64);','NEBO_TYPE_MISMATCH'),
        ('encoding-shadow','17.utf8;File.readText(Path.parse("a"),utf8,64);','NEBO_TYPE_MISMATCH'),
        ('write-value-type','File.writeText(Path.parse("a"),17,utf8,atomic);','NEBO_TYPE_MISMATCH'),
        ('write-mode','File.writeText(Path.parse("a"),"x",utf8,unknown);','NEBO_TYPE_MISMATCH')]]


def run():
    rows=[]
    with tempfile.TemporaryDirectory(dir=ROOT/'build/tmp',prefix='nebo-g170-filesystem-') as directory:
        for name,source,status,opts in cases():
            work=Path(directory)/name;work.mkdir();p=work/'source.no';p.write_text(source)
            try:row=dict(result='PASS',**pipeline(p,work,status,**opts))
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive' if status!=175 else 'runtime-domain',**row))
        for name,source,code in negatives():
            work=Path(directory)/name;work.mkdir();p=work/'source.no';p.write_text(source)
            try:row=dict(result='PASS',**reject(p,work,code))
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
    return dict(passed=sum(r['result']=='PASS' for r in rows),total=len(rows),cases=rows)


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
