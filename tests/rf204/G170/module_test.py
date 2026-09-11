#!/usr/bin/env python3
"""Native module/reexport and source-to-NI consumer parity with binary oracles."""
import hashlib,json,struct,tempfile
from pathlib import Path
from harness import ROOT,Failure,execute,pipeline,diagnostic_span

MASK=(1<<64)-1

def fnv(data):
    value=0xcbf29ce484222325
    for byte in data:value=((value^byte)*0x100000001b3)&MASK
    return value or 1

def qhash(values):return fnv(struct.pack('<'+'Q'*len(values),*values))
def rol(value,bits):return ((value<<bits)|(value>>(64-bits)))&MASK

def sections(data):
    return [struct.unpack_from('<IIQQQ',data,64+32*i) for i in range(struct.unpack_from('<I',data,48)[0])]

def fingerprints(data):
    table={row[0]:row for row in sections(data)}
    e=struct.unpack_from('<8Q',data,table[1][2]);m=struct.unpack_from('<8Q',data,table[2][2])
    target=struct.unpack_from('<Q',data,16)[0]
    return (qhash([*e[:5],e[6],e[7]&~2,m[0],m[1],m[2],m[3]&~(1<<32),m[5],m[6]]),
            qhash([target,e[0],e[2],e[3],e[5],m[0],m[7]]))

def refresh(data):
    for i,(_,_,offset,length,_) in enumerate(sections(data)):
        struct.pack_into('<Q',data,64+32*i+24,fnv(data[offset:offset+length]))
    struct.pack_into('<QQ',data,32,*fingerprints(data))
    # FNV concatenation, excluding the root-digest field itself.
    struct.pack_into('<Q',data,56,fnv(data[:56]+data[64:]))
    return bytes(data)

def ni_oracle(data,name,symbol,value):
    if len(data)!=368 or data[:8]!=b'NEBO.NI\0':raise Failure('NI_LAYOUT')
    if struct.unpack_from('<HHI',data,8)!=(1,64,1):raise Failure('NI_EDITION')
    table=sections(data)
    if [(x[0],x[1],x[3]) for x in table]!=[(1,0,64),(2,0,64),(4,1,80)]:raise Failure('NI_SECTIONS')
    if any(fnv(data[o:o+n])!=h for _,_,o,n,h in table):raise Failure('NI_SECTION_DIGEST')
    if struct.unpack_from('<Q',data,56)[0]!=fnv(data[:56]+data[64:]):raise Failure('NI_CONTENT_DIGEST')
    target,module,api,abi=struct.unpack_from('<4Q',data,16)
    expected_module=rol(rol(fnv(b'workspace'),17)^fnv(name.encode())^9,11)^len(name)
    if target!=fnv(b'x86_64-systemv-elf-linux') or module!=expected_module:raise Failure('NI_IDENTITY')
    if (api,abi)!=fingerprints(data):raise Failure('NI_FINGERPRINT')
    e=struct.unpack_from('<8Q',data,table[0][2])
    sid=fnv(symbol.encode());typ=fnv(b'Int')
    if e!=(sid,sid,3|(1<<32),typ,0,qhash([target,typ,8,8]),qhash([value]),6):raise Failure('NI_TYPED_EXPORT')
    payload=struct.unpack_from('<8sQQQ32sQQ',data,table[2][2])
    if payload!=(b'NEBOMDC1',sid,value,len(name),name.encode().ljust(32,b'\0'),0,0):raise Failure('NI_MATERIAL_CONSTANT')
    return dict(symbol_id=sid,module_id=module,api_fingerprint=api,abi_fingerprint=abi)

def sources(form,value):
    core=f'module core;\nexport public token = {value};\n'
    util='module util;\nexport public delta = 7;\n'
    expected=value
    if form=='simple':body='import "project.core".values;\nstart values.token;'
    elif form=='named':body='import { import "project.core".left; import "project.util".right; }.values;\nstart values.token + values.delta;';expected+=7
    elif form=='anonymous':body='import { import "project.core".left; import "project.util".right; };\nstart left.token + right.delta;';expected+=7
    elif form=='selective':body='import "project.core" { token; }.values;\nstart values.token;'
    elif form=='reexport':
        util='module facade;\nexport import "project.core" { token; }.source;\n'
        body='import "project.facade" { token; }.values;\nstart values.token;'
    elif form=='named-reexport':
        util='module facade;\nexport import "project.core" { token; }.source;\n'
        body='import { import "project.facade".left; }.values;\nstart values.token;'
    else:raise Failure('MODULE_TEST_FORM')
    return ('// Public imports resolve the original declaration and value.\nmodule app;\n'+body+'\n',core,util,expected)

def write_sources(work,form,value):
    a,b,c,expected=sources(form,value)
    paths=[work/name for name in ('app.no','core.no','util.no')]
    for p,s in zip(paths,(a,b,c)):p.write_text(s)
    return (*paths,expected)

def emit_interface(source,units,output,work):
    args=[ROOT/'build/bin/neboc','emit-interface',source]
    for unit in units:args+=['--unit',unit]
    rc,out,err=execute([*args,'-o',output],work)
    if rc or err:raise Failure('NI_EMIT:'+repr((rc,out,err)))
    report=json.loads(out)
    if report['materialModuleValue'] is None:raise Failure('NI_VALUE_ABSENT')
    return output.read_bytes()

def command_json(arguments,work):
    rc,out,err=execute([ROOT/'build/bin/neboc',*arguments],work,timeout=30)
    if rc or err:raise Failure('MODULE_METADATA:'+repr((rc,out,err)))
    return json.loads(out)

def documentation(work,value):
    a,b,c,_=write_sources(work,'simple',value)
    text=(f'doc {{ title: "Runtime documentation"; summary: "A material value"; '
          f'effects {{ pure; }} capabilities {{ none; }} '
          f'example "exit-{value}" {{start(){{{value}.return;}}}} '
          f'law "law-exit-29" {{start(){{29.return;}}}} }}\n')
    a.write_text(text+a.read_text())
    proof=pipeline(a,work,value,units=(b,c))
    ast=command_json(['dump','doc-ast',a],work)
    record=command_json(['dump','doc-record',a],work)
    expected_symbol=fnv(b'app')
    if ast['attachment']['symbolId']!=expected_symbol or record['symbolId']!=expected_symbol:raise Failure('DOC_SYMBOL_ID')
    if record['text']['title']!='Runtime documentation' or record['text']['example']!=f'start(){{{value}.return;}}':raise Failure('DOC_TEXT')
    if record['interface']!={'bytes':4192,'optional':True,'roundTrip':'BYTE_IDENTICAL','schema':1,'sectionKind':3}:raise Failure('DOC_INTERFACE')
    expected_snippets={'example':value,'law':29}
    for item in ast['embeddedCode']:
        begin,length=item['span'];snippet=a.read_bytes()[begin:begin+length]
        expected=expected_snippets[item['kind']]
        if snippet!=f'start(){{{expected}.return;}}'.encode():raise Failure('DOC_SPAN')
        case=work/item['kind'];case.mkdir();source=case/'snippet.no';source.write_bytes(snippet)
        pipeline(source,case,expected)
    report=command_json(['test-docs',a,'--seed','7','--budget','2','--report','json'],work)
    if report['summary']!={'documents':1,'fixtures':2,'lawCases':2}:raise Failure('DOC_EXECUTED_COUNT')
    for item in report['documents'][0]['fixtures']:
        expected=expected_snippets[item['kind']]
        if item['expectedExit']!=expected or item['snippetSha256']!=hashlib.sha256(f'start(){{{expected}.return;}}'.encode()).hexdigest():raise Failure('DOC_RUNTIME_ORACLE')
    return dict(**proof,symbol_id=expected_symbol,doc_examples=2)

def completion(work,text):
    source=work/'text.no';source.write_text('start() {\n    "'+text+'".byteLength().return;\n}\n')
    proof=pipeline(source,work,len(text.encode()))
    # The byte cursor sits just after the receiver dot, before its method.
    column=4+len(text)+3+1
    report=command_json(['completion-debug',str(source)+':2:'+str(column)],work)
    if report['receiver']['type']!='Text' or not report['snapshot']['admitted']:raise Failure('COMPLETION_RECEIVER')
    candidates=report['candidates'];found=[c for c in candidates if c['name']=='byteLength']
    if len(found)!=1:raise Failure('COMPLETION_PUBLIC_METHOD')
    sid=fnv(b'compiler/parser/text_char_bytes_api_contract.asm:Text:byteLength')
    if found[0]['symbolId']!=f'0x{sid:016x}' or found[0]['receiverTypeId']!=report['receiver']['typeId']:raise Failure('COMPLETION_SYMBOL_TYPE')
    return dict(**proof,symbol_id=sid)

def no_prelude_negative(work):
    source=work/'source.no';source.write_text('start(){Option<Int>(Some(17)).item;item.unwrapOr(7).return;}')
    for mode in ('check','emit-asm','build'):
        args=[ROOT/'build/bin/neboc',mode,source,'--no-prelude'];target=work/(mode+'.artifact')
        if mode!='check':args+=['-o',target]
        rc,out,err=execute(args,work)
        if rc!=1 or target.exists() or b'NEBO-RF166-G163-002:' not in out+err:raise Failure('NO_PRELUDE_MISSING_IMPORT')
    return dict(stages=3,code='NEBO-RF166-G163-002')

def reject_units(source,units,work,code,source_id=1):
    observations=[]
    for mode in ('module-check','emit-asm','build'):
        args=[ROOT/'build/bin/neboc',mode,source]
        for unit in units:args+=['--unit',unit]
        target=work/(mode+'.artifact')
        if mode=='module-check':args+=['--message-format','json-lines','--color','never']
        else:args+=['-o',target]
        rc,out,err=execute(args,work)
        if rc!=1 or target.exists():raise Failure('MODULE_NEGATIVE_ACCEPTANCE')
        if mode=='module-check':
            diagnostic=json.loads(out+err)
            if diagnostic['code']!=code:raise Failure('MODULE_DIAGNOSTIC:'+repr(diagnostic))
            primary=diagnostic['primary']
            if primary['sourceId']!=source_id:raise Failure('MODULE_DIAGNOSTIC_UNIT')
            if source_id==1:diagnostic_span(diagnostic,source.read_bytes())
            elif (primary['start'],primary['end'])!=(0,8):raise Failure('NI_HEADER_SPAN')
        elif b'error '+code.encode()+b':' not in out+err:raise Failure('MODULE_DIAGNOSTIC_PARITY')
        observations.append(rc)
    return dict(stages=3,code=code,source_id=source_id)

def mutations(original):
    table={row[0]:row for row in sections(original)};p=table[4][2];e=table[1][2];m=table[2][2]
    for name,offset,value in [('value',p+16,29),('symbol',p+8,71),('name-length',p+24,33),
                              ('name',p+32,0),('padding',p+39,1),('reserved',p+64,1),
                              ('magic',p,0),('type',e+24,fnv(b'Bool')),('layout',e+40,1),
                              ('effects',m+8,1),('capabilities',m+16,1),('visibility',e+16,3|(2<<32))]:
        data=bytearray(original);struct.pack_into('<Q',data,offset,value);yield name,refresh(data)
    yield 'truncated',original[:-1]
    data=bytearray(original);data[-1]^=1;yield 'bad-digest',bytes(data)
    data=bytearray(original[:64])
    for kind,flags,offset,length,digest in sections(original):
        data.extend(struct.pack('<IIQQQ',kind,flags,offset+32,length,digest))
    payload=original[p:p+80]
    data.extend(struct.pack('<IIQQQ',4,1,len(original)+32,80,fnv(payload)))
    data.extend(original[160:]);data.extend(payload)
    struct.pack_into('<II',data,48,4,len(data));yield 'duplicate-value',refresh(data)
    # An old metadata-only V1 file remains readable but cannot supply a value.
    data=bytearray(original[:64])
    for kind,flags,offset,length,digest in sections(original)[:2]:data.extend(struct.pack('<IIQQQ',kind,flags,offset-32,length,digest))
    data.extend(original[160:288]);struct.pack_into('<II',data,48,2,len(data));yield 'missing-value',refresh(data)

def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-modules-',dir='/tmp') as directory:
        root=Path(directory)
        def record(name,category,action):
            work=root/name;work.mkdir()
            try:proof=action(work);row=dict(result='PASS',**proof)
            except (Failure,ValueError,KeyError) as error:row=dict(result='FAIL',failure=str(error).replace(str(root),'<scratch>'))
            rows.append(dict(id=name,category=category,**row))
        for form in ('simple','named','anonymous','selective','reexport','named-reexport'):
            for value in (17,29,71):
                def positive(work,form=form,value=value):
                    a,b,c,expected=write_sources(work,form,value)
                    proof=pipeline(a,work,expected,units=(b,c))
                    other=work/'permuted';other.mkdir()
                    second=pipeline(a,other,expected,units=(c,b))
                    if any(proof[k]!=second[k] for k in ('asm_sha256','elf_sha256','runtime_sha256')):raise Failure('MODULE_UNIT_ORDER')
                    return proof
                record(form+'-'+str(value),'metamorphic',positive)
                def parity(work,form=form,value=value):
                    a,b,c,expected=write_sources(work,form,value)
                    source_work=work/'source';source_work.mkdir()
                    proof=pipeline(a,source_work,expected,units=(b,c))
                    data=emit_interface(b,(a,c),work/'core.ni',work)
                    identities=ni_oracle(data,'core','token',value)
                    # The compiled consumer has no access to its provider source.
                    b.unlink()
                    compiled=work/'compiled';compiled.mkdir()
                    second=pipeline(a,compiled,expected,units=(work/'core.ni',c))
                    if any(proof[k]!=second[k] for k in ('asm_sha256','elf_sha256','runtime_sha256')):raise Failure('SOURCE_NI_PARITY')
                    return dict(**second,**identities,provider_source_absent=True)
                record('ni-'+form+'-'+str(value),'composition',parity)
        for value in (0,255):
            def boundary(work,value=value):
                a,b,c,expected=write_sources(work,'simple',value)
                data=emit_interface(b,(a,c),work/'core.ni',work);ni_oracle(data,'core','token',value);b.unlink()
                return pipeline(a,work,expected,units=(work/'core.ni',c))
            record('ni-boundary-'+str(value),'boundary',boundary)
        for value in (17,71):
            def two_interfaces(work,value=value):
                a,b,c,expected=write_sources(work,'named',value)
                first=work/'core.ni';second=work/'util.ni'
                ni_oracle(emit_interface(b,(a,c),first,work),'core','token',value)
                ni_oracle(emit_interface(c,(a,b),second,work),'util','delta',7)
                b.unlink();c.unlink()
                return pipeline(a,work,expected,units=(second,first))
            record('ni-two-providers-'+str(value),'composition',two_interfaces)
        def unreachable(work):
            a,b,c,expected=write_sources(work,'simple',17)
            before=work/'before';before.mkdir()
            proof=pipeline(a,before,expected,units=(b,c))
            c.write_text('module util;\nexport public delta = 199;\n')
            after=work/'after';after.mkdir()
            changed=pipeline(a,after,expected,units=(b,c))
            if proof['elf_sha256']!=changed['elf_sha256']:raise Failure('UNREACHABLE_CONSTANT_EFFECT')
            return changed
        record('unreachable-constant','metamorphic',unreachable)
        seed=root/'seed';seed.mkdir();a,b,c,_=write_sources(seed,'simple',17)
        original=emit_interface(b,(a,c),seed/'core.ni',seed)
        for name,data in mutations(original):
            def negative(work,data=data):
                a,b,c,_=write_sources(work,'simple',17);b.unlink();ni=work/'core.ni';ni.write_bytes(data)
                return reject_units(a,(ni,c),work,'NEBO-RF166-G154-007',2)
            record('ni-reject-'+name,'adversarial',negative)
        for private in ('private','internal'):
            def visibility(work,private=private):
                a,b,c,_=write_sources(work,'reexport',17)
                b.write_text(b.read_text().replace('public',private))
                return reject_units(a,(b,c),work,'NEBO-RF166-G152-006')
            record('reexport-'+private,'negative',visibility)
        for value in (17,71):
            record('documentation-'+str(value),'composition',lambda work,value=value:documentation(work,value))
            for explicit in (False,True):
                def freestanding(work,value=value,explicit=explicit):
                    source=work/'source.no'
                    if explicit:source.write_text(f'import "std.core" {{ Option; }}.core;\nstart(){{Option<Int>(Some({value})).item;item.unwrapOr(7).return;}}')
                    else:source.write_text(f'start(){{{value}.return;}}')
                    return pipeline(source,work,value,no_prelude=True)
                record('no-prelude-'+str(value)+'-'+str(explicit),'composition',freestanding)
        record('no-prelude-missing','negative',no_prelude_negative)
        for text in ('Nebo','language'):
            record('completion-'+text,'composition',lambda work,text=text:completion(work,text))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
