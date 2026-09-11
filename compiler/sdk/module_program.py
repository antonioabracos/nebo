"""Compose material native module exports with the complete typed Program.

Native lexer tokens identify source references. Native module parsing, graph,
visibility/reexports and NI decoding resolve each Int export. Only those typed
constant references are lowered; every remaining source statement goes through
the normal parser, semantic, lowering and codegen owners. Byte spans are kept.
"""
from pathlib import Path
import subprocess
import tempfile
from compiler.sdk.token_tooling import TokenModel
from compiler.sdk.prelude import PreludeError

def project_typed_program(path,source,units,compiler):
    model=TokenModel.scan(source)
    if model.status or model.errors:raise PreludeError('NEBO_PARSE_UNEXPECTED_TOKEN','invalid native token stream')
    tokens=[t for t in model.tokens if t.kind!=1]
    word=lambda t:source[t.start:t.end]
    depth=0;start=None
    for index,token in enumerate(tokens[:-1]):
        text=word(token)
        if depth==0 and text==b'start' and word(tokens[index+1])==b'(':
            start=index;break
        if text==b'{':depth+=1
        elif text==b'}':depth-=1
    if start is None:return None
    if len(units)!=2:raise PreludeError('NEBO_MODULE_UNIT_LIMIT','current material module profile requires three source units')
    # Only module/import declarations belong to the resolver query. Receiver
    # functions before start remain part of the typed program, including their
    # return statements; a method name is never an import alias.
    cursor=0;header_end=0;aliases=set()
    while cursor<start and word(tokens[cursor]) in (b'module',b'import'):
        importing=word(tokens[cursor])==b'import';level=0
        while cursor<start:
            text=word(tokens[cursor])
            if text==b'{':level+=1
            elif text==b'}':level-=1
            if text==b';' and level==0:
                if importing and cursor>=2 and word(tokens[cursor-2])==b'.':
                    aliases.add(word(tokens[cursor-1]))
                header_end=tokens[cursor].end;cursor+=1;break
            cursor+=1
        else:raise PreludeError('NEBO_PARSE_UNEXPECTED_TOKEN','unterminated module declaration')
    prefix=source[:header_end]
    if not aliases:raise PreludeError('NEBO_MODULE_IMPORT_REQUIRED','typed module body requires a material import')
    references=[]
    for i in range(cursor,len(tokens)-2):
        a,b,c=tokens[i:i+3]
        if word(a) in aliases and word(b)==b'.' and c.kind==2:
            references.append((a.start,c.end,source[a.start:c.end]))
        if word(a)==b'.' and word(b) in aliases and word(c) in (b';',b'.'):
            raise PreludeError('NEBO_NAME_SHADOW','module alias cannot be shadowed by a local binding')
    if not references:raise PreludeError('NEBO_MODULE_IMPORT_UNUSED','typed module has no material imported reference')
    if len(references)>128:raise PreludeError('NEBO_LIMIT_EXCEEDED','module reference budget')
    values={}
    with tempfile.TemporaryDirectory(prefix='nebo-module-plan-') as directory:
        query=Path(directory)/'query.no'
        for _,_,reference in references:
            if reference in values:continue
            query.write_bytes(prefix+b'start '+reference+b';\n')
            args=[str(compiler),'module-info',str(query)]
            for unit in units:args.extend(('--unit',str(Path(unit).absolute())))
            result=subprocess.run(args,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=15,check=False)
            if result.returncode:
                raise PreludeError('NEBO_MODULE_REFERENCE_REJECTED',result.stderr.decode().replace(str(query),str(path)).strip())
            fields=dict(line.split('=',1)for line in result.stdout.decode().splitlines())
            if fields.get('graph.units')!='3' or fields.get('module.startRefs')!='1':
                raise PreludeError('NEBO_MODULE_PLAN_INVALID','native resolver did not claim the reference once')
            value=int(fields['module.resolvedInt'])
            if not 0<=value<=255:raise PreludeError('NEBO_MODULE_PLAN_INVALID','native Int export outside material profile')
            values[reference]=str(value).encode()
    projected=bytearray(source)
    for i in range(len(prefix)):
        if projected[i] not in (10,13):projected[i]=32
    for begin,end,reference in references:
        value=values[reference]
        if len(value)>end-begin:raise PreludeError('NEBO_MODULE_SPAN_LIMIT','constant cannot preserve source span')
        projected[begin:end]=value+b' '*(end-begin-len(value))
    return bytes(projected)
