#!/usr/bin/env python3
"""Public tagged-value and typed-error oracles, independent of owner summaries."""
import json,tempfile
from pathlib import Path
from harness import ROOT,pipeline,reject,Failure


def cases():
    rows=[]
    for value in (17,29,71):
        for returned in (0,7,23,29,255):
            for family,constructor,observer in [('option',f'Option<Int>(Some({value}))','expect("present")'),('result',f'Result<Int,Int>(Ok({value}))','get()'),('error',f'Error({value},1,50,2,8,0)','code()')]:
                source=f'start(){{{constructor}.x;x.{observer}.console();{returned}.return;}}'
                rows.append((f'{family}-value-{value}-return-{returned}',source,returned,dict(kinds=[4],text=str(value).encode())))
    options=[('some','Option<Int>(Some(17))','isSome()',True),('none','Option<Int>(None())','isNone()',True),('contains','Option<Int>(Some(17))','contains(19)',False),('filter-false','Option<Int>(Some(17))','filter(false).isNone()',True),('filter-true','Option<Int>(Some(17))','filter(true).get()',17),('map','Option<Int>(Some(17))','map(31).get()',31),('map-none','Option<Int>(None())','map(31).isNone()',True),('or-else','Option<Int>(None())','orElse(37).get()',37),('lazy-or-else','Option<Int>(Some(17))','orElse(37).get()',17),('and-then','Option<Int>(Some(17))','andThen(Some(41)).get()',41),('and-none','Option<Int>(Some(17))','andThen(None()).isNone()',True)]
    results=[('ok-map','Result<Int,Int>(Ok(19))','map(43).get()',43),('err-map-lazy','Result<Int,Int>(Err(23))','map(43).getErr()',23),('err-map-err','Result<Int,Int>(Err(23))','mapErr(47).getErr()',47),('ok-map-err-lazy','Result<Int,Int>(Ok(19))','mapErr(47).get()',19),('and-ok','Result<Int,Int>(Ok(19))','andThen(Ok(53)).get()',53),('and-err','Result<Int,Int>(Ok(19))','andThen(Err(59)).getErr()',59),('or-else','Result<Int,Int>(Err(23))','orElse(Ok(61)).get()',61),('is-ok','Result<Int,Int>(Ok(19))','isOk()',True),('is-err','Result<Int,Int>(Err(23))','isErr()',True)]
    for family,items in [('option',options),('result',results)]:
        for name,ctor,method,value in items:
            source=f'start(){{{ctor}.x;x.{method}.console();23.return;}}'
            text=(str(value).lower() if isinstance(value,bool) else str(value)).encode()
            rows.append((family+'-'+name,source,23,dict(kinds=[5 if isinstance(value,bool) else 4],text=text)))
    rows.append(('two-options','start(){Option<Int>(Some(17)).a;Option<Int>(Some(71)).b;a.get().console();b.get().console();a.get().console();23.return;}',23,dict(kinds=[4,4,4],text=b'177117')))
    rows.append(('two-results','start(){Result<Int,Int>(Ok(17)).a;Result<Int,Int>(Err(71)).b;a.get().console();b.getErr().console();a.get().console();23.return;}',23,dict(kinds=[4,4,4],text=b'177117')))
    for kind,literal,value in [('Bool','true',1),('Bool','false',0),('Char',"'Ω'",937)]:
        rows.append(('option-payload-'+literal,f'start(){{Option<{kind}>(Some({literal})).x;x.get().return;}}',value%256,{}))
        rows.append(('result-payload-'+literal,f'start(){{Result<{kind},Int>(Ok({literal})).x;x.get().return;}}',value%256,{}))
    for i,status in enumerate((17,43,13,46,47,5),1):
        rows.append((f'G005-{i:02}',(ROOT/f'examples/rf204/G005/RF204-G005-S{i:02}.no').read_text(),status,{}))
    for name,status in [('option-contains-false',0),('option-none-unwrap',61),('option-filter-none',1),('option-zip-first',23),('result-err-unwrap',59),('result-err-or-else',61),('result-ok-or-else-lazy',31),('error-message-length',15),('error-cause-none',0),('error-diagnostic-span',17)]:
        rows.append((name,(ROOT/f'tests/rf204/G005/positive/{name}.no').read_text(),status,{}))
    for category,base in [(0,'error'),(1,'filesystem'),(2,'process'),(3,'network'),(4,'http'),(65535,'error')]:
        for context in ('', 'abc', 'Ω café', 'line\nnext', '"quoted"'):
            ctor=f'Error(7101,{category},50,2,8,0).root;root.withContext({json.dumps(context,ensure_ascii=False)}).contextual;'
            source='start(){'+ctor+'contextual.message().console();23.return;}'
            message=base+(': '+context if context else '')
            rows.append((f'error-message-{category}-{len(context)}',source,23,dict(kinds=[2,3,2] if '\n' in context else [2],text=message.encode(),publications=1)))
    rows.append(('error-message-implicit-return','start(){Error(7101,1,50,2,8,0).root;root.message().console();}',0,dict(kinds=[2],text=b'filesystem')))
    rows.append(('error-two-messages','start(){Error(7101,1,50,2,8,0).root;root.withContext("abc").one;root.withContext("XYZ").two;one.message().console();two.message().console();root.message().console();23.return;}',23,dict(kinds=[2,2,2],text=b'filesystem: abcfilesystem: XYZfilesystem')))
    rows.append(('error-message-pool-boundary','start(){Error(7101,1,50,2,8,0).root;root.withContext("'+('a'*4084)+'").contextual;contextual.message().console();23.return;}',23,dict(kinds=[2],text=b'filesystem: '+b'a'*4084)))
    for family,ctor,observer in [('option','Option<Int>(Some(17))','get()'),('result','Result<Int,Int>(Ok(19))','get()'),('error','Error(7101,1,50,2,8,0)','code()')]:
        value=17 if family=='option' else 19 if family=='result' else 7101
        rows.append((family+'-effect-capacity','start(){'+ctor+'.x;'+('x.'+observer+'.console();')*32+'23.return;}',23,dict(kinds=[4]*32,text=(str(value)*32).encode())))
    return rows


def negatives():
    rows=[]
    for name,code in [('option-expect-none','NEBO_BEHAVIOR_NOT_SUPPORTED'),('option-zip-array','NEBO_TYPE_MISMATCH'),('result-expect-wrong-side','NEBO_BEHAVIOR_NOT_SUPPORTED'),('result-expecterr-wrong-side','NEBO_BEHAVIOR_NOT_SUPPORTED'),('result-or-else-type','NEBO_TYPE_MISMATCH'),('error-invalid-diagnostic-span','NEBO_TYPE_MISMATCH')]:
        rows.append((name,(ROOT/f'tests/rf204/G005/negative/{name}.no').read_text(),code))
    for family,ctor,method in [('option','Option<Int>(Some(17))','get()'),('result','Result<Int,Int>(Ok(19))','get()'),('error','Error(7101,1,50,2,8,0)','code()')]:
        for name,body in [('unreachable',f'x.{method}.return;23.return;'),('extra-console-argument',f'x.{method}.console(7);23.return;'),('terminal-suffix',f'x.{method}.return.console();')]:
            rows.append((family+'-'+name,'start(){'+ctor+'.x;'+body+'}','NEBO_PARSE_UNEXPECTED_TOKEN'))
    for family,ctor,observer in [('option','Option<Int>(Some(17))','get()'),('result','Result<Int,Int>(Ok(19))','get()'),('error','Error(7101,1,50,2,8,0)','code()')]:
        rows.append((family+'-effect-capacity-plus-one','start(){'+ctor+'.x;'+('x.'+observer+'.console();')*33+'23.return;}','NEBO_LIMIT_EXCEEDED'))
    rows.append(('error-message-pool-plus-one','start(){Error(7101,1,50,2,8,0).root;root.withContext("'+('a'*4085)+'").contextual;contextual.message().console();23.return;}','NEBO_LIMIT_EXCEEDED'))
    rows.append(('error-message-extra-argument','start(){Error(7101,1,50,2,8,0).root;root.message(7).console();23.return;}','NEBO_PARSE_UNEXPECTED_TOKEN'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-option-result-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,options in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=pipeline(path,work,status,**options);row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives():
            work=root/('negative-'+name);work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=reject(path,work,code);row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
