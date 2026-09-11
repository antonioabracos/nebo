"""Console values, lifecycle and software pixels have independent source oracles.

The bounded software profile is 256x128 BGRA8 with the existing deterministic
synthetic glyph provider. This is not a live-window or font-rendering claim.
"""
import functools
import json
import struct
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, console_trace

BLACK=0xff000000
WHITE=0xffffffff

def rgba(values):
    r,g,b,*alpha=values
    a=alpha[0] if alpha else 255
    return ((r*a+127)//255)<<16 | ((g*a+127)//255)<<8 | ((b*a+127)//255) | a<<24

def text_literal(text):
    return json.dumps(text,ensure_ascii=False)

def entries(values):
    result=[]
    for value in values:
        if isinstance(value,bool):result.append((5,str(value).lower(),None,None))
        elif isinstance(value,int):result.append((4,str(value),None,None))
        else:
            chunks=value.split('\n')
            for i,chunk in enumerate(chunks):
                if i:result.append((3,'\n',None,None))
                if chunk:result.append((2,chunk,None,None))
    return result

@functools.lru_cache(maxsize=256)
def software_oracle(nodes):
    """Rasterize the published finite profile from source values, not traces."""
    width,height=256,128
    pixels=bytearray(struct.pack('<I',BLACK)*(width*height))
    def fill(x,y,w,h,color):
        if x<0 or y<0:raise Failure('ORACLE_UNSUPPORTED_NEGATIVE_GEOMETRY')
        if x>=width or y>=height:return
        w=min(w,width-x);h=min(h,height-y)
        line=struct.pack('<I',color)*w
        for yy in range(y,y+h):pixels[(yy*width+x)*4:(yy*width+x+w)*4]=line
    fill(1,1,254,28,0xff202020)
    fill(0,0,width,1,0xff6b6b6b);fill(0,height-1,width,1,0xff6b6b6b)
    fill(0,0,1,height,0xff6b6b6b);fill(width-1,0,1,height,0xff6b6b6b)
    x,y=13,39;segments=0;backgrounds=0
    for node in nodes:
        kind,text,fg,bg,*position=node
        placement=position[0] if position else None
        delta=None
        if kind==3:x,y=13,y+16;continue
        cursor=0
        while cursor<len(text):
            count=(243-x)//8
            if not count:x,y=13,y+16;continue
            chunk=text[cursor:cursor+count];cursor+=len(chunk);segments+=1
            if placement is not None and delta is None:delta=(placement[0]-x,placement[1]-y)
            dx,dy=delta or (0,0)
            if bg is not None:fill(x+dx,y+dy,len(chunk)*8,16,rgba(bg));backgrounds+=1
            for ch in chunk:
                fill(x+dx,y+dy+3,5,9,WHITE if fg is None else rgba(fg))
                fill(x+dx+(ord(ch)&3)+1,y+dy+5,1,5,BLACK)
                x+=8
    # Native ABI hashes the eight pointer-free surface fields followed by all
    # pixels; the existing profile uses a 64-bit accumulator and FNV32 prime.
    header=struct.pack('<8Q',width,height,width*4,1,1,7,0,0)
    value=2166136261
    for byte in header+pixels:value=((value^byte)*16777619)&((1<<64)-1)
    return segments+2,segments,5+segments+backgrounds,value

def oracle(nodes,*,active=False,closed=False,title='',scroll=0,style=0,publications=None,views=()):
    nodes=tuple(nodes);text=''.join(n[1] for n in nodes).encode()
    kinds=[n[0] for n in nodes]
    pubs=publications if publications is not None else len(kinds)
    boxes,renders,commands,pixel_hash=software_oracle(nodes)
    title=title.encode()
    state=[2 if closed else 1,len(text),text.count(b'\n')+1,style,scroll] if active else [0]*5
    expected=struct.pack('<8s13Q',b'NEBOCST1',*state,len(title),boxes,renders,commands,pixel_hash,256,128,commands)+title
    if views:expected+=struct.pack('<8sQ',b'NEBOVIW1',len(views))+b''.join(struct.pack('<4Q',*view) for view in views)
    def compare(data,index):
        end=32+8*len(kinds)+len(text)
        console_trace(data[:end],kinds,text,pubs)
        if data[end:]!=expected:
            raise Failure('CONSOLE_STATE_OR_SOFTWARE_PIXELS:'+repr((data[end:].hex(),expected.hex())))
        return data[end:]
    return dict(kinds=kinds,text=text,publications=pubs,console_state_trace=True,observation=compare)

def cases():
    result=[]
    def add(name,body,values,*,status=23,**options):
        nodes=entries(values)
        result.append((name,'start(){'+body+str(status)+'.return;}',status,oracle(nodes,**options)))
    for value in ('seed','changed','Olá €',17,-29,True,False):
        literal=text_literal(value) if isinstance(value,str) else str(value).lower()
        add('publish-'+str(value),'('+literal+').console();',[value])
    for title in ('report','changed title','ação','', 'a'*256):
        add('title-'+str(len(title))+'-'+title[:6], '"seed".console().view;view.title('+text_literal(title)+');',['seed'],active=True,title=title)
    add('clear','"seed".console().view;view.clear();',[],active=True,publications=1)
    add('clear-append','"seed".console().view;view.clear();view.append("next");',['next'],active=True,publications=2)
    add('clear-preserves-title','"seed".console().view;view.title("document");view.clear();view.append("next");',['next'],active=True,title='document',publications=2)
    for value in ('next','Nebo €',29,-71,True,False):
        literal=text_literal(value) if isinstance(value,str) else str(value).lower()
        add('append-'+str(value),'"seed".console().view;view.append('+literal+');',['seed',value],active=True)
    for value in ('abc','ação','one\ntwo\nthree'):
        body=text_literal(value)+'.console().view;view.size().s;s.at(0).console();s.at(1).console();'
        add('size-'+str(len(value.encode())),body,[value,len(value.encode()),value.count('\n')+1],active=True,publications=3)
        add('scroll-'+str(len(value.encode())),text_literal(value)+'.console().view;view.scrollToEnd();',[value],active=True,scroll=value.count('\n'),publications=1)
    add('close','"seed".console().view;view.close();',['seed'],active=True,closed=True)
    add('two-handles-one-default','"seed".console().a;"next".console().b;a.title("shared");b.clear();a.append(29);',[29],active=True,title='shared',publications=3)
    for status in (0,7,23,29,255):
        add('return-'+str(status),'"seed".console().view;view.title("return");view.append(71);',['seed',71],active=True,title='return',status=status)
    for size in (1,28,29,56,100):
        text='abCd'*(size//4)+'abCd'[:size%4]
        add('software-wrap-'+str(size),text_literal(text)+'.console();',[text])
    for values in ((17,29,53),(71,83,97),(0,127,255),(255,0,0)):
        r,g,b=values;ctor=f'Color.rgb({r},{g},{b})'
        add('channels-'+str(r),ctor+'.c;c.red().console();c.green().console();c.blue().console();c.alpha().console();',[r,g,b,255])
        for role in ('fg','bg'):
            body='"seed".console(Console.'+role+'('+ctor+'));'
            nodes=((2,'seed',values if role=='fg' else None,values if role=='bg' else None),)
            result.append((role+'-'+str(r),'start(){'+body+'23.return;}',23,oracle(nodes)))
    for alpha in (0,1,113,254,255):
        values=(71,83,97,alpha);ctor='Color.rgba('+','.join(map(str,values))+')'
        add('alpha-'+str(alpha),ctor+'.c;c.alpha().console();c.withAlpha(29).alpha().console();c.isOpaque().console();',[alpha,29,alpha==255])
        result.append(('rgba-pixels-'+str(alpha),'start(){"seed".console(Console.fg('+ctor+'));23.return;}',23,oracle(((2,'seed',values,None),))))
    for r in (17,71):
        nodes=((2,'seed',(r,29,53),(71,83,97)),)
        result.append(('fg-bg-'+str(r),f'start(){{"seed".console(Console.fg({r},29,53),Console.bg(71,83,97));23.return;}}',23,oracle(nodes)))
    nodes=((2,'seed',(17,29,53),None),(2,'next',(71,83,97),None))
    result.append(('two-color-nodes','start(){"seed".console(Console.fg(17,29,53));"next".console(Console.fg(71,83,97));23.return;}',23,oracle(nodes)))
    nodes=((2,'next',None,None),)
    result.append(('clear-removes-color','start(){"seed".console(Console.fg(17,29,53)).v;v.clear();v.append("next");23.return;}',23,oracle(nodes,active=True,publications=2)))
    for n,body in [('close-twice','v.close();v.close();'),('close-publish','v.close();29.console();'),('close-clear','v.close();v.clear();'),('close-title','v.close();v.title("bad");'),('title-limit','v.title('+text_literal('x'*257)+');')]:
        result.append((n,'start(){"seed".console().v;'+body+'23.return;}',174,{}))
    for n,body in [('rgb-low','(-1).channel;Color.rgb(channel,29,53);'),('rgb-high','256.channel;Color.rgb(17,channel,53);'),('rgba-high','256.channel;Color.rgba(17,29,53,channel);'),('alpha-low','(-1).channel;Color.rgb(17,29,53).withAlpha(channel);'),('duplicate-role','"seed".console(Console.fg(17,29,53),Console.fg(71,83,97));')]:
        result.append((n,'start(){'+body+'23.return;}',174,{}))
    for name,body in [('typed-color','Color.c;Color.rgb(17,29,53).c;c.red().console();'),('constant-color','Color.rgb(17,29,53).C;C.red().console();')]:
        add(name,body,[17])
    add('title-loop','"seed".console().v;0.i.mutable;while(i<10000){v.title("loop");i+=1;}',['seed'],active=True,title='loop')
    for label,value,literal,kind in [('text','next','"next"',2),('int','29','29',4),('bool','false','false',5)]:
        nodes=((2,'seed',None,None),(kind,value,(17,29,53),None))
        source='start(){"seed".console().v;v.append('+literal+',Console.fg(17,29,53));23.return;}'
        result.append(('styled-append-'+label,source,23,oracle(nodes,active=True)))
    for x,y in ((17,29),(71,53),(0,0),(255,117)):
        nodes=((2,'seed',(17,29,53),None,(x,y)),)
        source=f'start(){{"seed".console(Position.at({x},{y}),Console.fg(17,29,53));23.return;}}'
        result.append((f'position-{x}-{y}',source,23,oracle(nodes)))
    for x,y in ((-1,29),(256,53),(17,-1),(17,128)):
        result.append((f'position-limit-{x}-{y}',f'start(){{"seed".console(Position.at({x},{y}));23.return;}}',174,{}))
    for a,b,method in ((0,1,'exclusive'),(1,2,'exclusive'),(0,2,'exclusive'),(0,1,'inclusive'),(1,1,'exclusive')):
        end=b+(method=='inclusive')
        nodes=tuple((2,v,(17,29,53) if a<=i<end else None,None) for i,v in enumerate(('seed','next')))
        source=f'start(){{"seed".console().v;"next".console();v.style(Range.{method}({a},{b}),Console.fg(17,29,53));23.return;}}'
        result.append((f'style-{method}-{a}-{b}',source,23,oracle(nodes,active=True)))
    nodes=((2,'seed',None,(17,29,53)),(2,'next',(71,83,97),None))
    source='start(){"seed".console().v;"next".console();0.first;1.last;v.style(Range.exclusive(first,last),Console.bg(17,29,53));v.style(Range.inclusive(1,1),Console.fg(71,83,97));23.return;}'
    result.append(('style-dynamic-endpoints',source,23,oracle(nodes,active=True)))
    nodes=((2,'next',None,None),)
    source='start(){"seed".console().v;v.style(Range.exclusive(0,1),Console.fg(17,29,53));v.clear();v.append("next");23.return;}'
    result.append(('style-clear',source,23,oracle(nodes,active=True,publications=2)))
    for first,last in ((-1,1),(0,3),(2,1)):
        source=f'start(){{"seed".console().v;v.style(Range.exclusive({first},{last}),Console.fg(17,29,53));23.return;}}'
        result.append((f'style-bound-{first}-{last}',source,174,{}))
    for value in (0,7,23,83,255):
        for returned in (0,7,23,29,255):
            result.append((f'visual-summary-{value}-{returned}',f'start(){{visual.summarize({value}).console();{returned}.return;}}',returned,dict(kinds=[4],text=str(value).encode())))
    result.append(('visual-summary-dynamic','start(){17.a.mutable;a+=29;visual.summarize(a).console();23.return;}',23,dict(kinds=[4],text=b'46')))
    result.append(('visual-summary-once','(Int.x)mark(){x.console();x.return;}start(){visual.summarize(17.mark()).console();23.return;}',23,dict(kinds=[4,4],text=b'1717')))
    result.append(('visual-summary-two-values','start(){visual.summarize(17).a;visual.summarize(83).b;a.console();b.console();a.console();23.return;}',23,dict(kinds=[4]*3,text=b'178317')))
    for value in (-1,256):result.append(('visual-summary-range-'+str(value),f'start(){{visual.summarize({value}).console();23.return;}}',174,{}))
    return result

def negatives():
    rows=[]
    for name,call in [('title-type','v.title(17)'),('clear-arity','v.clear(1)'),('size-arity','v.size(1)'),('close-arity','v.close(true)'),('append-float','v.append(2.5)'),('append-missing','v.append()'),('scroll-arity','v.scrollToEnd(1)')]:
        rows.append((name,'start(){"seed".console().v;'+call+';23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('rgb-arity','Color.rgb(17,29);'),('rgb-type','Color.rgb(17,true,53);'),('rgba-type','Color.rgba(17,29,53,"alpha");'),('channel-arity','Color.rgb(17,29,53).red(1);'),('alpha-type','Color.rgb(17,29,53).withAlpha(false);'),('equals-type','Color.rgb(17,29,53).equals(17);'),('fg-type','Console.fg(17);'),('bg-arity','Console.bg();')]:
        rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('bare-color','start(){"seed".console(Color.rgb(17,29,53));23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('position-arity','Position.at(17);'),('position-type','Position.at("x",29);'),('styled-append-type','"seed".console().v;v.append("next",17);'),('styled-append-arity','"seed".console().v;v.append("next",Console.fg(17,29,53),23);')]:
        rows.append((name,'start(){'+body+'23.return;}','NEBO_TYPE_MISMATCH'))
    for name,selection,style in [('selection-type','17','Console.fg(17,29,53)'),('endpoint-type','Range.exclusive(true,1)','Console.fg(17,29,53)'),('selection-arity','Range.exclusive(0)','Console.fg(17,29,53)'),('role-type','Range.exclusive(0,1)','17')]:
        rows.append(('style-'+name,'start(){"seed".console().v;v.style('+selection+','+style+');23.return;}','NEBO_TYPE_MISMATCH'))
    for name,body in [('static-channel-high','Color.rgb(256,29,53);'),('static-channel-low','Color.rgba(-1,29,53,71);'),('static-alpha','Color.rgb(17,29,53).withAlpha(256);'),('invalid-hex','Color.hex("#12G456");'),('hex-arity','Color.hex("#12345");'),('dynamic-hex','"#123456".s;Color.hex(s);'),('result-fallback-type','Color.parseHex("#123456").unwrapOr(17);'),('result-expect-type','Color.parseHex("#123456").expect(17);'),('sugar-arity','Color(17,29);'),('color-status','Color.rgb(17,29,53).return;')]:
        rows.append(('color-'+name,'start(){'+body+('' if name=='color-status' else '23.return;')+'}','NEBO_ENTRYPOINT_INVALID_SIGNATURE' if name=='color-status' else 'NEBO_TYPE_MISMATCH'))
    for name,source,code in [
        ('structured-object-status','struct User {Int.age;}start(){User {age:29}.x;x.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'),
        ('structured-object-field','struct User {Int.age;}start(){User {name:29}.x;x.console();23.return;}','NEBO_TYPE_MISMATCH'),
        ('structured-object-type','struct User {Int.age;}start(){User {age:true}.x;x.console();23.return;}','NEBO_TYPE_MISMATCH'),
        ('structured-table-column','start(){Table.fromColumns([Tuple.of("age",17)]).t;t.console();23.return;}','NEBO_TYPE_MISMATCH'),
        ('structured-tree-value','start(){Tree<Int>.new(true).t;t.console();23.return;}','NEBO_TYPE_MISMATCH'),
        ('color-hash-arity','start(){Color.rgb(17,29,53).hash(1);23.return;}','NEBO_TYPE_MISMATCH'),
        ('color-serialize-arity','start(){Color.rgb(17,29,53).toHex(1);23.return;}','NEBO_TYPE_MISMATCH'),
        ('color-opaque-arity','start(){Color.rgb(17,29,53).isOpaque(1);23.return;}','NEBO_TYPE_MISMATCH'),
    ]:rows.append((name,source,code))
    rows += [('visual-summary-type','start(){visual.summarize(true);23.return;}','NEBO_TYPE_MISMATCH'),
             ('visual-summary-arity','start(){visual.summarize(17,29);23.return;}','NEBO_TYPE_MISMATCH'),
             ('visual-summary-shadow','start(){17.visual;visual.summarize(23);29.return;}','NEBO_CALL_UNDEFINED')]
    return rows

def _run(work):
    proofs=[]
    for name,source,status,options in cases()+structured_cases()+color_cases():
        with tempfile.TemporaryDirectory(prefix='console-',dir=work) as scratch:
            case=Path(scratch);path=case/'case.no';path.write_text(source)
            try:proofs.append(dict(case=name,**pipeline(path,case,status,**options)))
            except Failure as error:raise Failure(name+':'+str(error)) from error
    for name,source,code in negatives():
        with tempfile.TemporaryDirectory(prefix='console-neg-',dir=work) as scratch:
            case=Path(scratch);path=case/'case.no';path.write_text(source)
            try:proofs.append(dict(case=name,**reject(path,case,code)))
            except Failure as error:raise Failure(name+':'+str(error)) from error
    return proofs


def run():
    with tempfile.TemporaryDirectory(prefix='nebo-console-',dir=ROOT/'build/tmp') as directory:
        proofs=_run(Path(directory))
    return dict(passed=len(proofs),total=len(proofs),cases=[dict(id=row['case'],result='PASS',**{key:value for key,value in row.items() if key!='case'}) for row in proofs])


def structured_cases():
    """Native shape receipts and software pixels, derived from source inputs."""
    rows=[]
    def add(name,source,text,views,*,status=23,publications=1,nodes=None,**opts):
        rows.append(('structured-'+name,source,status,oracle(entries([text]) if nodes is None else nodes,publications=publications,views=views,**opts)))
    def table(columns,name='t'):
        return 'Table.fromColumns(['+','.join('Tuple.of('+text_literal(key)+',Column<Int>.from(['+','.join(map(str,values))+']))' for key,values in columns)+']).'+name+';'
    def table_text(columns):
        return 'Table['+' | '.join(k for k,v in columns)+']\n'+''.join(' | '.join(str(v[i]) for k,v in columns)+'\n' for i in range(len(columns[0][1])))
    for names in (('age','score'),('key','value'),('ação','雪')):
        for values in ((17,29,71,83),(-17,29,71,83),(17,97,71,83)):
            columns=[(names[0],values[:2]),(names[1],values[2:])]
            add('table-'+str(names)+'-'+str(values),'start(){'+table(columns)+'t.console();23.return;}',table_text(columns),((4,15,2,2),))
    for size in (0,1,32):
        columns=[('index',list(range(size)))]
        add('table-rows-'+str(size),'start(){'+table(columns)+'t.console();23.return;}',table_text(columns),((4,15,size,1),))
    columns=[('field'+str(i),[i*7+17]) for i in range(8)]
    add('table-eight-columns','start(){'+table(columns)+'t.console();23.return;}',table_text(columns),((4,15,1,8),))
    a=[('age',[17,29])];b=[('score',[71])]
    add('table-two-live','start(){'+table(a,'a')+table(b,'b')+'a.console();b.console();23.return;}',table_text(a)+table_text(b),((4,15,2,1),(4,15,1,1)),publications=2)
    source='start(){List<Int>.new().a;Table.fromColumns([Tuple.of("age",Column<Int>.from([17,a.get(0),29]))]).t;t.console();23.return;}'
    add('table-missing',source,'Table[age]\n17\nnull\n29\n',((4,15,3,1),))
    columns=[('age',[71,17,29])]
    add('table-sorted','start(){'+table(columns)+'t.sortBy(["age"]).sorted;sorted.console();23.return;}','Table[age]\n17\n29\n71\n',((4,15,3,1),))
    for returned in (0,7,23,29,255):
        add('table-return-'+str(returned),'start(){'+table([('age',[17])])+'t.console();'+str(returned)+'.return;}','Table[age]\n17\n',((4,15,1,1),),status=returned)
    for root,first,last in ((17,29,71),(83,29,71),(17,97,71),(17,29,-83)):
        body=f'Tree<Int>.new({root}).t;t.root().r;t.addChild(r,{first}).a;t.addChild(r,{last});t.addChild(a,103);t.console();'
        text=f'Tree\n{root}\n  {first}\n    103\n  {last}\n'
        add('tree-'+str((root,first,last)),'start(){'+body+'23.return;}',text,((6,21,4,3),))
    add('tree-empty','start(){Tree<Int>.new(17).t;t.removeSubtree(t.root());t.console();23.return;}','Tree\n',((6,21,0,0),))
    add('tree-two-live','start(){Tree<Int>.new(17).a;Tree<Int>.new(71).b;a.console();b.console();23.return;}','Tree\n17\nTree\n71\n',((6,21,1,1),(6,21,1,1)),publications=2)
    add('tree-removed','start(){Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).a;t.addChild(r,71);t.removeSubtree(a);t.console();23.return;}','Tree\n17\n  71\n',((6,21,2,2),))
    for count in (1,16,17):
        body='Tree<Int>.new(17).t;t.root().n0;'+''.join(f't.addChild(n{i-1},{i+29}).n{i};' for i in range(1,count))+'t.console();23.return;'
        if count==17:rows.append(('structured-tree-depth-limit','start(){'+body+'}',174,{}))
        else:add('tree-depth-'+str(count),'start(){'+body+'}','Tree\n17\n'+''.join('  '*i+str(i+29)+'\n' for i in range(1,count)),((6,21,count,count),))
    source='start(){Tree<Int>.new(17).t;t.root().r;0.i.mutable;while(i<31){t.addChild(r,i);i+=1;}t.console();23.return;}'
    add('tree-32-nodes',source,'Tree\n17\n'+''.join('  '+str(i)+'\n' for i in range(31)),((6,21,32,2),))
    decl='struct User {Text.name;Int.age;}'
    for name,age in (('Nebo',29),('Lua',29),('Nebo',71),('Ω雪',83),('',-9223372036854775808)):
        source=decl+'start(){User {age:'+str(age)+',name:'+text_literal(name)+'}.x;x.console();23.return;}'
        add('object-'+name+'-'+str(age),source,f'User{{name: {name}, age: {age}}}\n',((3,12,2,0),))
    for flag,ch in ((True,'A'),(False,'Ω'),(True,'🙂')):
        source='struct Flag {Bool.ok;Char.letter;Int.count;}start(){Flag {letter:'+repr(ch)+',ok:'+str(flag).lower()+',count:29}.x;x.console();23.return;}'
        add('object-padding-'+ch,source,f'Flag{{ok: {str(flag).lower()}, letter: {ch}, count: 29}}\n',((3,12,3,0),))
    source=decl+'struct Outer {User.user;Bool.ok;}start(){Outer {user:User {age:29,name:"Nebo"},ok:false}.x;x.console();23.return;}'
    add('object-nested',source,'Outer{user: User{name: Nebo, age: 29}, ok: false}\n',((3,12,2,0),))
    source=decl+'start(){User {name:"first",age:17}.a;User {age:71,name:"second"}.b;a.console();b.console();23.return;}'
    add('object-two-live',source,'User{name: first, age: 17}\nUser{name: second, age: 71}\n',((3,12,2,0),(3,12,2,0)),publications=2)
    source='struct Pair {Int.first;Int.second;}(Int.value)mark(){value.console();value.return;}start(){Pair {second:29.mark(),first:17.mark()}.x;x.console();23.return;}'
    text='Pair{first: 17, second: 29}\n'
    add('object-effects-once',source,'2917'+text,((3,12,2,0),),publications=3,nodes=entries([29,17,text]))
    for returned in (0,7,23,29,255):
        source=decl+'start(){User {name:"Nebo",age:17}.x;x.console();'+str(returned)+'.return;}'
        add('object-return-'+str(returned),source,'User{name: Nebo, age: 17}\n',((3,12,2,0),),status=returned)
    for count in (64,65):
        source='start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([]))]).t;0.i.mutable;while(i<'+str(count)+'){t.console();i+=1;}23.return;}'
        if count==65:rows.append(('structured-view-count-limit',source,174,{}))
        else:add('view-count-64',source,'Table[age]\n'*64,((4,15,0,1),)*64,publications=64)
    return [(name.replace(",","_").replace(" ",""),source,status,options) for name,source,status,options in rows]


def color_cases():
    rows=[]
    def add(name,body,values,*,status=23,implicit=False):
        rows.append(('color-'+name,'start(){'+body+('' if implicit else str(status)+'.return;')+'}',status,oracle(entries(values)) if values else {}))
    def fnv(data):
        value=14695981039346656037
        for b in data:value=((value^b)*1099511628211)&((1<<64)-1)
        return value-(1<<64) if value>>63 else value
    for channels in ((17,29,53,71),(83,29,53,71),(17,97,53,71),(17,29,53,113),(0,255,1,0)):
        r,g,b,a=channels;hexrgb='#'+''.join(f'{v:02X}' for v in channels[:3]);hexrgba=hexrgb+f'{a:02X}'
        for sugar,ctor in [('rgb',f'Color({r},{g},{b})'),('rgba',f'Color({r},{g},{b},{a})'),('hex',f'Color("{hexrgba}")'),('literal',f'Color.hex("{hexrgba}")')]:
            wanted=hexrgb+'FF' if sugar=='rgb' else hexrgba
            add('sugar-'+sugar+'-'+str(channels),ctor+'.c;c.toHex().console();c.toHexWithAlpha().console();',[hexrgb,wanted])
        add('hash-'+str(channels),f'Color.rgba({r},{g},{b},{a}).hash().console();',[fnv(bytes(channels))])
        add('parsed-'+str(channels),f'"{hexrgba}".encoded;Color.parseHex(encoded).p;p.isOk().console();p.isErr().console();p.expect("valid").toHexWithAlpha().console();p.unwrapOr(Color.rgb(1,2,3)).red().console();',[True,False,hexrgba,r])
        add('copied-'+str(channels),f'Color.rgba({r},{g},{b},{a}).original;original.copy;copy.equals(original).console();',[True])
    for invalid in ('','#12G456','#12345','1234567','#123456789','#12345é'):
        add('parse-error-'+invalid,'Color.parseHex('+text_literal(invalid)+').p;p.isOk().console();p.isErr().console();p.unwrapOr(Color.rgb(71,83,97)).toHex().console();',[False,True,'#475361'])
        rows.append(('color-expect-error-'+invalid,'start(){Color.parseHex('+text_literal(invalid)+').expect("invalid");23.return;}',174,{}))
    for value in ('','#6D2A6C9E','Ω雪','changed','a'*4096):
        add('text-hash-'+str(len(value))+value[:5],text_literal(value)+'.hash().console();',[fnv(value.encode())])
    rows.append(('color-text-hash-limit','start(){'+text_literal('x'*4097)+'.hash();23.return;}',174,{}))
    add('implicit-status','Color.rgb(17,29,53).red().console();',[17],status=0,implicit=True)
    add('implicit-standalone','Color(17,29,53);',[],status=0,implicit=True)
    # Current public regressions are self-contained source inputs. They must
    # not depend on the separately excluded historical example campaign.
    for red in (17,7,41,53,67,79,97,109,127,149):
        rgb=f'#{red:02X}2A6C';rgba=rgb+'9E'
        source=(f'start(){{Color.rgb({red},42,108).opaque;'
                'if(!opaque.isOpaque()){1.return;}'
                f'Color.rgba({red},42,108,158).value;'
                'if(value.green()!=42){2.return;}'
                'if(value.blue()!=108){3.return;}'
                'if(value.alpha()!=158){4.return;}'
                f'if(!opaque.toHex().equals("{rgb}")){{5.return;}}'
                f'if(!value.toHexWithAlpha().equals("{rgba}")){{6.return;}}'
                f'Color.parseHex("{rgba}").parsed;'
                'if(!parsed.isOk()){8.return;}'
                'if(!parsed.expect("valid").equals(value)){9.return;}'
                'if(value.hash()==0){10.return;}'
                'if(opaque.withAlpha(158).isOpaque()){11.return;}'
                'value.red().return;}')
        rows.append((f'color-public-composition-{red}',source,red,{}))
    return [(name.replace(',', '_').replace(' ', ''),source,status,options) for name,source,status,options in rows]
