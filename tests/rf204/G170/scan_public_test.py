"""Actual public ScanPlan operands, results and independent input/value oracles."""
import json,tempfile,struct
from pathlib import Path
from harness import ROOT,Failure,pipeline,reject,console_trace

def literal(value):return json.dumps(value,ensure_ascii=False)
from text_test import document

MASK=(1<<64)-1
def rol(value,n):return ((value<<n)|(value>>(64-n)))&MASK
def identity(value):
    h=0xcbf29ce484222325
    for b in value.encode():h=((h^b)*0x100000001b3)&MASK
    return h

def trace_record(value=b'',*,request=1,attempt=0,source=1,form='',field=None,view='',panel='',feedback=0,style='',security=0,strength=0,max_attempts=1,choice_count=0,choice_flags=0,error=0,failures=0,mask=0,input_mode=1,max_lines=1,delimiter_length=0,language='',zeroized=0,zero_remaining=0,selections=1):
    """Independent values supplied by each test; never derived from runtime."""
    form_id=identity(form) if form else 0
    view_id=identity(view) if view else 0
    panel_id=identity(panel) if panel else 0
    style_id=(identity(style)&0xffffffff) if style else 0
    field_rows=[] if not field else [field] if isinstance(field,tuple) else field
    fields=len(field_rows)
    field_hash=0
    for key,typ in field_rows:field_hash=rol(field_hash,7)^rol(identity(key),7)^identity(typ)
    plan=[1,form_id,fields,view_id,panel_id,feedback,style_id,input_mode,max_lines,delimiter_length,choice_count,choice_flags,security,strength,max_attempts,15]
    digest=0xcbf29ce484222325
    for v in plan[:-1]:digest=rol(digest^v,7)
    digest^=plan[-1]
    h=0xcbf29ce484222325
    for b in value:h=rol(h^b,5)
    redacted=bool(security&(1|2|4|64))
    return [request,attempt,source,digest,form_id,fields,view_id,panel_id,feedback,style_id,security,input_mode,choice_count,
            2 if error else 1,4 if error else 0,0 if error or redacted else len(value),
            0 if error else 0x7265646163746564 if redacted else h,0 if error else int(redacted),zeroized,failures,error,field_hash,mask,identity(language) if language else 0,zero_remaining,0 if error else selections]

def trace_oracle(records,*,kinds=None,text=b'',publications=None):
    def observe(data,run):
        offset=0
        for expected in records:
            if len(data)<offset+216:raise Failure('SCAN_TRACE_TRUNCATED')
            magic,*values=struct.unpack_from('<8s26Q',data,offset)
            if magic!=b'NEBOSCN1':raise Failure('SCAN_TRACE_MAGIC')
            if values!=expected:raise Failure('SCAN_TRACE_VALUES:'+repr([(i,a,b) for i,(a,b) in enumerate(zip(values,expected)) if a!=b]))
            offset+=216
        if kinds is None:
            if data[offset:]:raise Failure('SCAN_TRACE_TRAILING')
        else:console_trace(data[offset:],kinds,text,publications)
        return data
    return observe

def cases():
    rows=[]
    def add(name,expression,value,status=23,**options):
        rows.append((name,'start(){'+expression+'.console();'+str(status)+'.return;}',status,dict(document(value),**options)))
    for n in (0,7,23,29,255,-71,9223372036854775807,-9223372036854775808):
        for returned in (7,23):add(f'int-{n}-return-{returned}','"Age: ".scan(.int(),.mock('+literal(str(n))+'))',n,returned)
    for n in (True,False):add('bool-'+str(n),'"Ready: ".scan(.bool(),.mock('+literal(str(n).lower())+'))',n)
    for text in ('','Nebo','ação Ω','17',' two words '):
        add('text-'+text.encode().hex(),'"Name: ".scan(.text(),.mock('+literal(text)+'))',text)
    for ch in ('Q','x','0',' '):add('char-'+str(ord(ch)),'"Key: ".scan(.char(),.mock('+literal(ch)+')).codepoint()',ord(ch))
    for text in (' Nebo ','\tHeLLo\t',' ação ','x\r\n'):
        add('trim-'+text.encode().hex(),'"Input".scan(.text(),.trim(),.mock('+literal(text)+'))',text.removesuffix('\n').removesuffix('\r').strip(' \t'))
    for text in ('HeLLo','Nebo Ω','123'):
        add('lower-'+text.encode().hex(),'"Input".scan(.text(),.lower(),.mock('+literal(text)+'))',text.translate(str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')))
        add('upper-'+text.encode().hex(),'"Input".scan(.text(),.upper(),.mock('+literal(text)+'))',text.translate(str.maketrans('abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')))
    for value in ('','17','83'):
        add('optional-'+(value or 'empty'),'"Age".scan(.int(),.optional(),.mock('+literal(value)+')).unwrapOr(71)',int(value) if value else 71)
        add('some-'+(value or 'empty'),'"Age".scan(.int(),.optional(),.mock('+literal(value)+')).isSome()',bool(value))
        add('none-'+(value or 'empty'),'"Age".scan(.int(),.optional(),.mock('+literal(value)+')).isNone()',not value)
    add('minlen-exact','"Input".scan(.text(),.minLen(2),.mock("ab"))','ab')
    add('maxlen-exact','"Input".scan(.text(),.maxLen(2),.mock("ab"))','ab')
    add('explicit-chomp','"Input".scan(.text(),.chomp(),.mock("Nebo\\r\\n"))','Nebo')
    for value in (17,29,83):add('range-'+str(value),'"Age".scan(.int(),.min(17),.max(83),.mock('+literal(str(value))+'))',value)
    for size in (0,1,4096):add('capacity-'+str(size),'"Input".scan(.text(),.allowEmpty(),.mock('+literal('x'*size)+')).byteLength()',size)
    for values in (['red','green','blue'],['ação','Nebo','Ω'],['','next'],['same','same'],[str(i) for i in range(32)]):
        for i,value in enumerate(values):
            source_values='['+','.join(literal(x) for x in values)+']'
            name=str(len(values))+'-'+str(i)+'-'+value.encode().hex()
            add('choice-'+name,'"Choice".scan(.choice('+source_values+'),.mock('+literal(value)+'))',value)
            if value:add('index-'+name,'"Choice".scan(.indexChoice('+source_values+'),.mock('+literal(value)+'))',values.index(value))
    rows.append(('choice-absent','start(){"Choice".scan(.choice(["red","blue"]),.mock("green"));23.return;}',174,{}))
    rows.append(('choice-empty-absent','start(){"Choice".scan(.choice(["red","blue"]),.mock(""));23.return;}',174,{}))
    rows.append(('choice-arguments-once','(Int.x)mark(){x.console();x.return;}start(){"Choice".scan(.choice([17.mark().toText(),83.mark().toText()]),.mock("83")).console();23.return;}',23,dict(kinds=[4,4,2],text=b'178383')))
    for kind,source,value in [('int','71\n',71),('bool','true\n',True),('text','Nebo\n','Nebo')]:
        add('stdin-'+kind,'"Prompt: ".scan(.'+kind+'())',value,stdin=source.encode(),prompt=b'Prompt: ')
    rows += [
        ('two-int-values','start(){"First".scan(.int(),.mock("17")).a;"Second".scan(.int(),.mock("83")).b;a.console();b.console();a.console();23.return;}',23,dict(kinds=[4,4,4],text=b'178317')),
        ('two-text-values','start(){"First".scan(.text(),.mock("Nebo")).a;"Second".scan(.text(),.mock("Language")).b;a.console();b.console();a.console();23.return;}',23,dict(kinds=[2,2,2],text=b'NeboLanguageNebo')),
        ('dynamic-input','start(){"29".input;17.min;83.max;"Age".scan(.int(),.min(min),.max(max),.mock(input)).console();23.return;}',23,document(29)),
        ('scalar-loop','start(){0.i.mutable;while(i<10000){"Age".scan(.int(),.mock("29"));i+=1;}23.return;}',23,{}),
    ]
    for kind,value,default in [('int',17,71),('bool',False,True),('char','Q','X'),('text','Nebo','fallback')]:
        fallback=literal(default) if kind=='text' else "'"+default+"'" if kind=='char' else str(default).lower()
        value_text=str(value).lower() if isinstance(value,bool) else str(value)
        for valid in (True,False):
            source='"Input".scan(.'+kind+'(),.result(),.mock('+literal(value_text if valid else ('bad' if kind!='text' else ''))+')'+(', .required()' if False else '')+')'
            # Text validation is tested with a real required constraint.
            if kind=='text':source='"Input".scan(.text(),.required(),.result(),.mock('+literal(value_text if valid else '')+'))'
            add(f'result-tag-{kind}-{valid}',source+'.isOk()',valid)
            add(f'result-error-{kind}-{valid}',source+'.isErr()',not valid)
            observed=value if valid else default
            add(f'result-value-{kind}-{valid}',source+'.unwrapOr('+fallback+')'+('.codepoint()' if kind=='char' else ''),ord(observed) if kind=='char' else observed)
    for kind,default in [('int','71'),('bool','true'),('text','"fallback"'),('char',"'X'")]:
        expression='"Input".scan(.'+kind+'(),.eofAs('+default+'))'
        add('eof-fallback-'+kind,expression+('.codepoint()' if kind=='char' else ''),{'int':71,'bool':True,'text':'fallback','char':88}[kind],prompt=b'Input')
    for name,source,inputs,expected in [('eof','',b'',False),('value','17',b'17\n',True)]:
        add('eof-option-'+name,'"Input".scan(.int(),.eofAsNone()).isSome()',expected,stdin=inputs,prompt=b'Input')
        add('eof-option-value-'+name,'"Input".scan(.int(),.eofAsNone()).unwrapOr(71)',17 if expected else 71,stdin=inputs,prompt=b'Input')
    for text in ('cancel','stop','17'):
        add('cancel-result-'+text,'"Input".scan(.int(),.cancelOn("cancel"),.result(),.mock('+literal(text)+')).isErr()',text!='17')
        add('cancel-fallback-'+text,'"Input".scan(.int(),.cancelOn('+literal(text)+'),.onCancel(83),.mock('+literal(text)+'))',83)
    add('replay-eof-result','"Input".scan(.int(),.result(),.replay("answers.txt")).isErr()',True,inputs={'answers.txt':b''})
    add('replay-io-result','"Input".scan(.int(),.result(),.replay("absent.txt")).isErr()',True)
    add('result-retry-success','"Input".scan(.int(),.result(),.retry(),.replay("answers.txt")).unwrapOr(71)',29,inputs={'answers.txt':b'invalid\n29\n'})
    add('result-retry-failure','"Input".scan(.int(),.result(),.retry(),.replay("answers.txt")).unwrapOr(71)',71,inputs={'answers.txt':b'invalid\n'})
    rows.append(('two-results-live','start(){"A".scan(.int(),.result(),.mock("17")).a;"B".scan(.int(),.result(),.mock("bad")).b;a.unwrapOr(0).console();b.unwrapOr(83).console();a.unwrapOr(0).console();23.return;}',23,dict(kinds=[4,4,4],text=b'178317')))
    rows.append(('eof-option-empty-is-invalid','start(){"Input".scan(.int(),.eofAsNone(),.mock(""));23.return;}',174,{}))
    rows.append(('cancel-prevents-binding','start(){17.value.mutable;value="Input".scan(.int(),.cancelOn("cancel"),.mock("cancel"));value.console();23.return;}',174,{}))
    for value in ('!accepted','Nebo','Ω',''):
        expr='"Input".scan(.text(),.console(),.mock('+literal(value)+'))'
        doc=document(value)
        rows.append(('console-adapter-'+value.encode().hex(),'start(){'+expr+'.console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([trace_record(value.encode())],**doc))))
    for form,field,view,panel,style in [('profile',('age','Int'),'entry','main','blue'),('settings',('enabled','Bool'),'switch','side','green')]:
        opts='.form('+literal(form)+'),.field('+literal(field[0])+','+literal(field[1])+'),.view('+literal(view)+'),.panel('+literal(panel)+'),.feedback(),.style('+literal(style)+')'
        rec=trace_record(b'29',form=form,field=field,view=view,panel=panel,feedback=1,style=style)
        doc=document(29)
        rows.append(('console-metadata-'+form,'start(){"Age".scan(.int(),.console(),'+opts+',.mock("29")).console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    for count in (2,7,29):
        fields=[('field'+str(i),'Int') for i in range(count)]
        opts=','.join('.field('+literal(name)+','+literal(typ)+')' for name,typ in fields)
        rec=trace_record(b'29',field=fields);doc=document(29)
        rows.append(('console-fields-'+str(count),'start(){"Age".scan(.int(),.console(),'+opts+',.mock("29")).console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    for message in ('Again: ','Retry Ω: ',''):
        doc=document(29)
        add('retry-message-'+message.encode().hex(),'"Input".scan(.int(),.retry('+literal(message)+'),.replay("answers.txt"))',29,inputs={'answers.txt':b'invalid\n29\n'},prompt=message.encode())
    for feedback in ('inline','summary'):
        rec=trace_record(b'29',feedback=identity(feedback)&0xffffffff);doc=document(29)
        rows.append(('console-feedback-'+feedback,'start(){"Age".scan(.int(),.console(),.feedback('+literal(feedback)+'),.mock("29")).console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    for policy,flags,strength in [('.secret()',93,1),('.password()',95,1),('.redact()',4,0),('.sensitive()',64,0),('.noHistory()',8,0),('.noEcho()',16,0),('.untrusted()',256,0),('.secret(),.mask("*")',605,1),('.secret(),.minStrength(4)',93,4)]:
        for value in ('Aa7!','Nebo_29!'):
            rec=trace_record(value.encode(),security=flags,strength=strength,mask=42 if '.mask(' in policy else 0)
            doc=document(len(value))
            rows.append(('security-'+str(flags)+'-'+str(strength)+'-'+str(len(value)),'start(){"Synthetic input".scan(.text(),.console(),'+policy+',.mock('+literal(value)+')).byteLength().console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    retry_records=[trace_record(request=1,attempt=0,source=2,max_attempts=3,error=4,failures=1),trace_record(b'29',request=2,attempt=1,source=2,max_attempts=3,failures=1)]
    doc=document(29)
    rows.append(('console-retry-events','start(){"Input".scan(.int(),.console(),.retry(),.maxAttempts(3),.replay("answers.txt")).console();23.return;}',23,dict(**doc,inputs={'answers.txt':b'invalid\n29\n'},scan_trace=True,observation=trace_oracle(retry_records,**doc))))
    for name,opts,data,error in [('eof','.eofAs(71)',b'',7),('cancel','.cancelOn("cancel"),.onCancel(71)',b'cancel\n',8)]:
        rec=trace_record(source=2,error=error,failures=1)
        doc=document(71)
        rows.append(('console-'+name+'-event','start(){"Input".scan(.int(),.console(),'+opts+',.replay("answers.txt")).console();23.return;}',23,dict(**doc,inputs={'answers.txt':data},scan_trace=True,observation=trace_oracle([rec],**doc))))
    for name,policy,value in [('weak-secret','.secret(),.minStrength(4)','lowercase'),('mask-empty','.secret(),.mask("")','Aa7!'),('mask-long','.secret(),.mask("**")','Aa7!'),('strength-zero','.secret(),.minStrength(0)','Aa7!'),('strength-five','.secret(),.minStrength(5)','Aa7!'),('strength-no-secret','.minStrength(2)','Aa7!'),('metadata-empty','.form("")','Aa7!')]:
        rows.append((name,'start(){"Input".scan(.text(),.console(),'+policy+',.mock('+literal(value)+'));23.return;}',174,{}))
    for mode,option,content,expected in [
        ('multiline','.multiline()','first\nsecond\n','first\nsecond'),
        ('paragraph','.paragraph()','first\nsecond\n\nignored\n','first\nsecond'),
        ('block','.block("END")','first\nsecond\nEND\nignored\n','first\nsecond'),
        ('until','.multiline(),.until("STOP")','first\nsecond\nSTOP\nignored\n','first\nsecond'),
        ('markdown','.markdown()','# Heading\n**body**\n','# Heading\n**body**'),
        ('code','.code("nebo")','start(){\n23.return;\n}\n','start(){\n23.return;\n}'),
        ('json','.jsonBlock()','{\n"value": 29\n}\n','{\n"value": 29\n}'),
        ('raw','.rawBlock()','first\nsecond\n','first\nsecond\n'),
    ]:
        for provider in ('mock','replay','stdin'):
            tail=',.mock('+literal(content)+')' if provider=='mock' else ',.replay("answers.txt")' if provider=='replay' else ''
            opts={'inputs':{'answers.txt':content.encode()}} if provider=='replay' else {'stdin':content.encode(),'prompt':b'Input'} if provider=='stdin' else {}
            add('multiline-'+mode+'-'+provider,'"Input".scan('+option+tail+')',expected,**opts)
    rows.append(('block-preserves-next-stdin','start(){"Block".scan(.block("END")).a;"Next".scan(.int()).b;a.console();b.console();23.return;}',23,dict(kinds=[2,4],text=b'first29',prompt=b'BlockNext',stdin=b'first\nEND\n29\n')))
    for mode,option,input_mode,content,expected,delimiter,language in [
        ('multiline','.multiline()',2,'first\nsecond','first\nsecond',0,''),
        ('paragraph','.paragraph()',3,'first\n\nignored','first',0,''),
        ('block','.block("END")',4,'first\nEND','first',3,''),
        ('markdown','.markdown()',5,'# Title','# Title',0,''),
        ('code-nebo','.code("nebo")',6,'23.return;','23.return;',0,'nebo'),
        ('code-other','.code("python")',6,'print(23)','print(23)',0,'python'),
        ('json','.jsonBlock()',7,'{"value":29}','{"value":29}',0,''),
        ('raw','.rawBlock()',8,'raw\n','raw\n',0,''),
    ]:
        doc=document(expected)
        record=trace_record(expected.encode(),input_mode=input_mode,max_lines=256,delimiter_length=delimiter,language=language)
        rows.append(('multiline-trace-'+mode,'start(){"Input".scan('+option+',.console(),.mock('+literal(content)+')).console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([record],**doc))))
    for lines in (1,2,255,256):
        value='\n'.join(['line']*lines)
        add('multiline-line-limit-'+str(lines),'"Input".scan(.multiline(),.maxLines('+str(lines)+'),.mock('+literal(value)+')).byteLength()',len(value))
    for name,option,value in [('missing-terminator','.block("END")','first\nsecond'),('empty-delimiter','.until("")','first'),('bad-json','.jsonBlock()','{"value":'),('duplicate-json','.jsonBlock()','{"x":1,"x":2}'),('too-many-lines','.multiline(),.maxLines(1)','first\nsecond'),('maxlines-zero','.multiline(),.maxLines(0)','first'),('maxlines-over','.multiline(),.maxLines(257)','first')]:
        rows.append(('multiline-'+name,'start(){"Input".scan('+option+',.mock('+literal(value)+'));23.return;}',174,{}))
    for first,second in [('Synthetic7!','Synthetic7!'),('Synthetic7!','Different9!'),('a','a'),('a','ab')]:
        for provider in ('replay','stdin'):
            data=(first+'\n'+second+'\n').encode()
            tail=',.replay("answers.txt")' if provider=='replay' else ''
            options={'inputs':{'answers.txt':data}} if provider=='replay' else {'stdin':data,'prompt':b'InputInput'}
            add('confirm-'+provider+'-'+first+'-'+second,'"Input".scan(.text(),.secret(),.confirmSecret(),.result()'+tail+').isOk()',first==second,**options)
    for second in ('Synthetic7!','Different9!'):
        flags=125
        records=[trace_record(b'Synthetic7!',security=flags,strength=1),
                 trace_record(b'Synthetic7!' if second=='Synthetic7!' else b'',request=2,security=flags,strength=1,error=0 if second=='Synthetic7!' else 5,failures=0 if second=='Synthetic7!' else 1)]
        for rec in records:rec[2]=2
        doc=document(second=='Synthetic7!')
        rows.append(('confirm-trace-'+second,'start(){"Input".scan(.text(),.console(),.secret(),.confirmSecret(),.result(),.replay("answers.txt")).isOk().console();23.return;}',23,dict(**doc,inputs={'answers.txt':('Synthetic7!\n'+second+'\n').encode()},scan_trace=True,observation=trace_oracle(records,**doc))))
    add('confirm-eof-result','"Input".scan(.text(),.secret(),.confirmSecret(),.result(),.replay("answers.txt")).isErr()',True,inputs={'answers.txt':b'Synthetic7!\n'})
    add('confirm-retry-pair','"Input".scan(.text(),.secret(),.confirmSecret(),.retry(),.result(),.replay("answers.txt")).unwrapOr("fallback")','Second9!',inputs={'answers.txt':b'First7!\nWrong8!\nSecond9!\nSecond9!\n'})
    rows.append(('confirm-binding-failure','start(){"Input".scan(.text(),.secret(),.confirmSecret(),.replay("answers.txt")).value;value.console();23.return;}',174,dict(inputs={'answers.txt':b'First7!\nWrong8!\n'})))
    rows.append(('confirm-needs-secret','start(){"Input".scan(.text(),.confirmSecret(),.mock("Synthetic7!"));23.return;}',174,{}))
    rows.append(('mask-needs-secret','start(){"Input".scan(.text(),.mask("*"),.mock("Synthetic7!"));23.return;}',174,{}))
    for value in ('Synthetic7!','Different9!','a'*4096):
        add('forget-value-'+str(len(value))+'-'+value[0],'"Input".scan(.text(),.secret(),.forgetAfterUse(),.mock('+literal(value)+')).byteLength()',len(value))
        flags=221;doc=document(len(value))
        rec=trace_record(value.encode(),security=flags,strength=1,zeroized=1)
        rows.append(('forget-trace-'+str(len(value))+'-'+value[0],'start(){"Input".scan(.text(),.console(),.secret(),.forgetAfterUse(),.mock('+literal(value)+')).byteLength().console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    for same in (True,False):
        flags=253;second='Synthetic7!' if same else 'Different9!'
        records=[trace_record(b'Synthetic7!',source=2,security=flags,strength=1),trace_record(b'Synthetic7!' if same else b'',request=2,source=2,security=flags,strength=1,error=0 if same else 5,failures=0 if same else 1,zeroized=1)]
        doc=document(same)
        rows.append(('forget-confirm-'+str(same),'start(){"Input".scan(.text(),.console(),.secret(),.confirmSecret(),.forgetAfterUse(),.result(),.replay("answers.txt")).isOk().console();23.return;}',23,dict(**doc,inputs={'answers.txt':('Synthetic7!\n'+second+'\n').encode()},scan_trace=True,observation=trace_oracle(records,**doc))))
    add('forget-retry-preserves-tail','"Input".scan(.text(),.secret(),.minStrength(4),.forgetAfterUse(),.retry(),.replay("answers.txt"))','Valid9!',inputs={'answers.txt':b'weak\nValid9!\n'})
    rows.append(('forget-two-live-values','start(){"A".scan(.text(),.secret(),.forgetAfterUse(),.mock("First7!")).a;"B".scan(.text(),.secret(),.forgetAfterUse(),.mock("Second9!")).b;a.byteLength().console();b.byteLength().console();a.byteLength().console();23.return;}',23,dict(kinds=[4,4,4],text=b'787')))
    rows.append(('forget-needs-secret','start(){"Input".scan(.text(),.forgetAfterUse(),.mock("Synthetic7!"));23.return;}',174,{}))
    for name,flag in [('oneOf',2),('menu',4),('select',8),('enum',256)]:
        for value in ('red','blue','green'):
            array='["red","blue"]'
            valid=value!='green'
            expression='"Choice".scan(.console(),.'+name+'('+array+'),.mock('+literal(value)+'))'
            if valid:
                doc=document(value);rec=trace_record(value.encode(),choice_count=2,choice_flags=flag)
                rows.append(('choice-variant-'+name+'-'+value,'start(){'+expression+'.console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
            else:rows.append(('choice-variant-'+name+'-absent','start(){'+expression+';23.return;}',174,{}))
    for name in ('yesNo','confirm'):
        for value in ('yes','YES','y','Y','no','NO','n','N','maybe'):
            if value!='maybe':add('choice-'+name+'-'+value,'"Choice".scan(.'+name+'(),.mock('+literal(value)+'))',value.lower() in ('yes','y'))
            else:rows.append(('choice-'+name+'-invalid','start(){"Choice".scan(.'+name+'(),.mock("maybe"));23.return;}',174,{}))
    for values,prefix,result in [(['Portugal','France'],'Port','Portugal'),(['Portuguese','France'],'Port','Portuguese'),(['Portugal','France'],'Fra','France'),(['ação','Nebo'],'a','ação')]:
        array='['+','.join(literal(x) for x in values)+']'
        add('autocomplete-'+prefix+'-'+result,'"Choice".scan(.autocomplete('+array+'),.mock('+literal(prefix)+'))',result)
    for name,values,prefix in [('ambiguous',['Portugal','Portuguese'],'Port'),('absent',['Portugal','France'],'Ge'),('empty',['Portugal','France'],'')]:
        array='['+','.join(literal(x) for x in values)+']'
        rows.append(('autocomplete-'+name,'start(){"Choice".scan(.autocomplete('+array+'),.mock('+literal(prefix)+'));23.return;}',174,{}))
    for values,selected in [(['red','green','blue'],['red']),(['red','green','blue'],['blue']),(['red','green','blue'],['red','blue']),(['red','green','blue'],['blue','green','red']),(['ação','Nebo','Ω'],['ação','Ω']),([str(i) for i in range(32)],['0','17','31'])]:
        mask=sum(1<<values.index(x) for x in selected)
        array='['+','.join(literal(x) for x in values)+']';value=','.join(selected)
        doc=document(mask);rec=trace_record(value.encode(),choice_count=len(values),choice_flags=16,selections=len(selected))
        rows.append(('multi-select-'+str(len(values))+'-'+value,'start(){"Choice".scan(.console(),.multiSelect('+array+'),.mock('+literal(value)+')).console();23.return;}',23,dict(**doc,scan_trace=True,observation=trace_oracle([rec],**doc))))
    for name,value in [('duplicate','red,red'),('absent','red,green'),('empty',''),('empty-first',',red'),('empty-last','red,')]:
        rows.append(('multi-select-'+name,'start(){"Choice".scan(.multiSelect(["red","blue"]),.mock('+literal(value)+'));23.return;}',174,{}))
    for value in (17,29,83):
        for attempts in (1,2,8):
            answers=(('invalid\n'*(attempts-1))+str(value)+'\n').encode()
            add(f'replay-retry-{value}-{attempts}','"Age".scan(.int(),.replay("answers.txt"),.retry(),.maxAttempts('+str(attempts)+'))',value,inputs={'answers.txt':answers})
            add(f'stdin-retry-{value}-{attempts}','"Age".scan(.int(),.retry(),.maxAttempts('+str(attempts)+'))',value,stdin=answers,prompt=b'Age'*attempts)
        add(f'replay-no-newline-{value}','"Age".scan(.int(),.replay("answers.txt"))',value,inputs={'answers.txt':str(value).encode()})
    add('replay-relative-subdir','"Name".scan(.text(),.replay("inputs/answer.txt"))','Nebo Ω',inputs={'inputs/answer.txt':'Nebo Ω\n'.encode()})
    add('mock-empty-is-answer','"Name".scan(.text(),.mock(""))','')
    rows.append(('stdin-two-lines','start(){"A".scan(.int()).a;"B".scan(.int()).b;a.console();b.console();23.return;}',23,dict(kinds=[4,4],text=b'1783',prompt=b'AB',stdin=b'17\n83\n')))
    for name,opts,data in [
        ('retry-disabled','.int(),.maxAttempts(8)',b'invalid\n29\n'),
        ('retry-exhausted','.int(),.retry(),.maxAttempts(2)',b'invalid\ninvalid\n29\n'),
        ('retry-default-exhausted','.int(),.retry()',b'invalid\n'*8+b'29\n'),
        ('retry-default-eighth','.int(),.retry()',b'invalid\n'*7+b'29\n'),
        ('replay-eof','.int()',b''),('replay-invalid-utf8','.text()',b'\xff'),
        ('replay-limit','.text()',b'x'*4097),('replay-empty-line','.int()',b'\n'),
    ]:
        expression='"Input".scan('+opts+',.replay("answers.txt"))'
        expected=29 if name=='retry-default-eighth' else 174
        rows.append((name,'start(){'+expression+('.return;' if expected==29 else ';23.return;')+'}',expected,dict(inputs={'answers.txt':data})))
    for name,path in [('replay-missing','absent.txt'),('replay-empty-path',''),('replay-path-limit','x'*257),('replay-parent','../escape.txt'),('replay-absolute','/not-authorized')]:
        rows.append((name,'start(){"Input".scan(.int(),.replay('+literal(path)+'));23.return;}',174,{}))
    for name,options in [
        ('attempts-zero','.int(),.retry(),.maxAttempts(0),.mock("29")'),('attempts-nine','.int(),.retry(),.maxAttempts(9),.mock("29")'),('int-overflow','.int(),.mock("9223372036854775808")'),('int-invalid','.int(),.mock("29x")'),
        ('bool-invalid','.bool(),.mock("yes")'),('char-empty','.char(),.mock("")'),('char-utf8','.char(),.mock("Ω")'),
        ('required-empty','.text(),.required(),.mock("")'),('lower-bound','.int(),.min(17),.mock("16")'),('upper-bound','.int(),.max(83),.mock("84")'),
        ('unordered-bounds','.int(),.min(83),.max(17),.mock("29")'),('minimum-length','.text(),.minLen(3),.mock("ab")'),
        ('maximum-length','.text(),.maxLen(2),.mock("abc")'),('negative-length','.text(),.maxLen(-1),.mock("abc")'),
        ('too-long','.text(),.mock('+literal('x'*4097)+')'),('empty-int','.int(),.mock("")')]:
        rows.append((name,'start(){"Input".scan('+options+');23.return;}',174,{}))
    return rows

def negatives():
    rows=[]
    for name,options in [('result-optional-conflict','.int(),.optional(),.result()'),('eof-fallback-type','.int(),.eofAs(true)'),('cancel-fallback-type','.text(),.onCancel(17)'),('eof-policy-conflict','.int(),.eofAsNone(),.eofAs(17)'),('field-key-type','.console(),.field(17,"Int")'),('field-value-type','.console(),.field("age",17)'),('field-arity','.console(),.field("age")'),('secret-arity','.secret(1)'),('metadata-type','.console(),.form(17)'),('replay-type','.replay(29)'),('source-conflict','.mock("29"),.replay("answers.txt")'),('attempts-type','.maxAttempts(true)'),('retry-arity','.retry(29)'),('int-arity','.int(17)'),('mock-type','.int(),.mock(29)'),('bound-type','.int(),.min(true)'),('duplicate-kind','.int(),.bool()'),('duplicate-mock','.mock("a"),.mock("b")'),('unknown','.unknown()'),('optional-type','.text(),.optional()'),('numeric-on-text','.text(),.min(17)'),('empty-conflict','.int(),.optional(),.required()'),('case-conflict','.text(),.lower(),.upper()'),('choice-type','.choice([17,29])'),('choice-arity','.choice()'),('choice-nonlist','.choice("red")'),('choice-empty','.choice([])'),('choice-bound','.choice(['+','.join('"x"' for _ in range(33))+'])'),('choice-kind','.int(),.choice(["17"])')]:
        rows.append((name,'start(){"Input".scan('+options+');23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('text','bool','char','trim','lower','upper','chomp','required','allowEmpty','optional','retry','eofAsNone','result','console','feedback','secret','redact','noHistory','noEcho','sensitive','untrusted','password'):
        rows.append(('option-arity-'+name,'start(){"Input".scan(.'+name+'(17));23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('form','view','panel','style','mask','cancelOn'):
        rows.append(('option-type-'+name,'start(){"Input".scan(.'+name+'(17));23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('minLen','maxLen','minStrength'):
        rows.append(('option-type-'+name,'start(){"Input".scan(.'+name+'(true));23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('block','until','code'):
        rows.append(('multiline-type-'+name,'start(){"Input".scan(.'+name+'(17));23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('multiline-type-conflict','start(){"Input".scan(.int(),.multiline());23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('multiline-mode-conflict','start(){"Input".scan(.multiline(),.rawBlock());23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('confirmSecret','forgetAfterUse'):
        rows.append(('security-arity-'+name,'start(){"Input".scan(.text(),.secret(),.'+name+'(17));23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('menu','select','oneOf','multiSelect','enum','autocomplete'):
        rows.append(('choice-type-'+name,'start(){"Choice".scan(.console(),.'+name+'([17,29]));23.return;}','NEBO_TYPE_MISMATCH'))
    for name in ('oneOf','enum'):
        rows.append(('choice-context-'+name,'start(){"Choice".scan(.'+name+'(["red","blue"]));23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('choice-conflicting-variants','start(){"Choice".scan(.choice(["red"]),.menu(["red"]));23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('legacy-seed-eclipse','start(){ScanPlan;2501;adapter.scan(.console());23.return;}','NEBO_BEHAVIOR_NOT_SUPPORTED'))
    rows.append(('print-route','start(){"Input".scan(.print(),.mock("Nebo"));23.return;}','NEBO_TYPE_MISMATCH'))
    rows.append(('invalid-process-type','start(){"Input".scan(.text(),.mock("Nebo")).return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    return rows

def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-scan-public-',dir=ROOT/'build/tmp') as scratch:
        root=Path(scratch)
        for name,source,expected,options in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=pipeline(path,work,expected,**options);row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=reject(path,work,code);row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
    return dict(passed=sum(x['result']=='PASS' for x in rows),total=len(rows),cases=rows)

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
