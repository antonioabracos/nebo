"""Typed RenderPlan sources against the independent G064 grammar/render oracle."""
import importlib.util,json,tempfile
from pathlib import Path
from harness import ROOT,Failure,pipeline,reject
from text_test import document,literal
spec=importlib.util.spec_from_file_location('g170_slash_reference',ROOT/'tests/rf204/G064/reference_oracle.py')
reference=importlib.util.module_from_spec(spec);spec.loader.exec_module(reference)


def cases():
    rows=[]
    def add(name,text,target='plain',status=23):
        expected=reference.render_target(text,target).decode()
        source='start(){RenderPlan('+literal(text)+').render(.'+target+'()).console();'+str(status)+'.return;}'
        rows.append((name,source,status,document(expected)))
    for name in sorted(reference.KNOWN):
        argument={'color':'(cyan)','bg':'(blue)','align':'(left)','task':'(done)'}.get(name,'')
        value='/'+name+argument+('{Nebo17}' if name in reference.CONTENT else '')
        add('directive-'+name,value)
    for target in ('plain','ansi','markdown','html','console'):
        for status in (0,7,23,29,255):
            value='/title{Case'+str(status)+'}/br/warn{AΩ😀}/space/bold{Nebo}/br/task(open){todo}/space//literal & <text>'
            add('target-'+target+'-'+str(status),value,target,status)
    for n in (1,8,16):add('depth-'+str(n),'/bold{'*n+'leaf'+'}'*n)
    add('input-boundary','x'*4096)
    add('tokens-boundary','/outdent'*255+' x')
    add('empty-content','/bold{}')
    text='/bold{first}';expected=reference.render_plain(text).decode()
    rows.append(('two-live','start(){RenderPlan("/bold{first}").a;RenderPlan("/italic{second}").b;a.render(.plain()).console();23.return;}',23,document(expected)))
    rows.append(('two-live-other','start(){RenderPlan("/bold{first}").a;RenderPlan("/italic{second}").b;b.render(.plain()).console();23.return;}',23,document('second')))
    for name,text in [('unknown','/missing{x}'),('open','/bold{x'),('close','x}'),('empty',''),('depth','/bold{'*17+'x'+'}'*17),
                      ('argument','/color(){}'),('task-state','/task(unknown){x}'),('input','x'*4097),('tokens','/outdent'*256+' x')]:
        rows.append(('domain-'+name,'start(){RenderPlan('+literal(text)+').render(.plain()).console();23.return;}',175,{}))
    for n,value in enumerate(('/bold{Nebo}','/warn{ação}')):
        expected=len(reference.render_plain(value))
        source='(Text.self)renderedLength(){RenderPlan(self).render(.plain()).byteLength().return;}start(){'+literal(value)+'.renderedLength().console();23.return;}'
        rows.append(('function-chain-'+str(n),source,23,document(expected)))
    return rows


def negatives():
    return [(name,'start(){'+body+'}',code) for name,body,code in [
        ('constructor-type','RenderPlan(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('constructor-arity','RenderPlan("a","b");23.return;','NEBO_TYPE_MISMATCH'),
        ('target-type','RenderPlan("a").render(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('target-unknown','RenderPlan("a").render(.unknown());23.return;','NEBO_TYPE_MISMATCH'),
        ('target-arity','RenderPlan("a").render(.plain(17));23.return;','NEBO_TYPE_MISMATCH'),
        ('target-global','RenderPlan("a").render(plain());23.return;','NEBO_PARSE_EXPECTED_TOKEN'),
        ('status-type','RenderPlan("a").return;','NEBO_ENTRYPOINT_INVALID_SIGNATURE')]]


def run():
    rows=[]
    with tempfile.TemporaryDirectory(dir=ROOT/'build/tmp',prefix='nebo-g170-slash-') as directory:
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
