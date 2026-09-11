"""Actual LSP/formatter/rename transformations of executable Nebo sources."""
import json
from pathlib import Path
from harness import ROOT,execute,pipeline,Failure
from text_test import document


def frames(messages):
    out=bytearray()
    for message in messages:
        body=json.dumps(message,ensure_ascii=False,separators=(',',':')).encode()
        out.extend(f'Content-Length: {len(body)}\r\n\r\n'.encode()+body)
    return bytes(out)


def unframe(data):
    rows=[]
    while data:
        end=data.find(b'\r\n\r\n')
        if not 0<=end<=8192:raise Failure('TOOL_LSP_HEADER')
        header=data[:end].decode('ascii');body=data[end+4:]
        if not header.startswith('Content-Length: '):raise Failure('TOOL_LSP_LENGTH')
        size=int(header[len('Content-Length: '):])
        if not 0<=size<=1048576 or len(body)<size:raise Failure('TOOL_LSP_SIZE')
        rows.append(json.loads(body[:size]));data=body[size:]
    return rows


def highlight(path,source,encoding,work):
    uri=path.as_uri()
    messages=[
        dict(jsonrpc='2.0',id=1,method='initialize',params=dict(rootUri=work.as_uri(),capabilities=dict(general=dict(positionEncodings=[encoding])))),
        dict(jsonrpc='2.0',method='textDocument/didOpen',params=dict(textDocument=dict(uri=uri,languageId='nebo',version=1,text=source))),
        dict(jsonrpc='2.0',id=2,method='textDocument/semanticTokens/full',params=dict(textDocument=dict(uri=uri))),
        dict(jsonrpc='2.0',id=3,method='shutdown',params={}),
        dict(jsonrpc='2.0',method='exit',params={}),
    ]
    result=execute(['python3','-B',ROOT/'tools/rf27-lsp.py'],work,stdin=frames(messages),timeout=30)
    if result[0] or result[2]:raise Failure('TOOL_LSP_EXEC:'+repr(result))
    replies={r['id']:r for r in unframe(result[1]) if 'id' in r}
    if any('error' in row for row in replies.values()):raise Failure('TOOL_LSP_ERROR:'+repr(replies))
    legend=replies[1]['result']['capabilities']['semanticTokensProvider']['legend']['tokenTypes']
    values=replies[2]['result']['data']
    if len(values)%5:raise Failure('TOOL_LSP_TOKEN_SIZE')
    line=column=0;decoded=[];lines=source.splitlines(keepends=True)
    codec='utf-8' if encoding=='utf-8' else 'utf-16-le';unit=1 if encoding=='utf-8' else 2
    for index in range(0,len(values),5):
        dl,dc,length,kind,flags=values[index:index+5]
        line+=dl;column=dc if dl else column+dc
        if not 0<=line<len(lines) or not 0<=kind<len(legend):raise Failure('TOOL_LSP_TOKEN_RANGE')
        raw=lines[line].encode(codec)
        spelling=raw[column*unit:(column+length)*unit].decode(codec)
        if not spelling:raise Failure('TOOL_LSP_EMPTY_TOKEN')
        decoded.append((legend[kind],spelling))
    return decoded


def run(work):
    rows=[]
    def record(name,action):
        case=work/name;case.mkdir()
        try:proof=action(case);row=dict(id=name,category='tooling',result='PASS',**(proof or {}))
        except (Failure,ValueError,KeyError,UnicodeError) as error:row=dict(id=name,category='tooling',result='FAIL',failure=str(error))
        rows.append(row)
    for value in (17,29):
        for encoding in ('utf-8','utf-16'):
            def action(case,value=value,encoding=encoding):
                source=f'start(){{{value}.value;"Ω ${{value:hex(width:4)}} raw \\${{value}}".console();23.return;}}'
                path=case/'source.no';path.write_text(source)
                proof=pipeline(path,case,23,**document('Ω '+format(value,'4x')+' raw ${value}'))
                tokens=highlight(path,source,encoding,case)
                if [s for k,s in tokens if k=='interpolationDelimiter']!=['${','}']:raise Failure('TOOL_LSP_DELIMITERS')
                if ('interpolation','value') not in tokens or ('formatProfile','hex') not in tokens:raise Failure('TOOL_LSP_EXPRESSION_PROFILE')
                if not any(k=='string' and '\\${value}' in s for k,s in tokens):raise Failure('TOOL_LSP_LITERAL_ESCAPE')
                return proof
            record(f'tooling-highlight-{value}-{encoding}',action)
    def literal_action(case):
        source='// ${29} stays a comment\nstart(){r"${29}".console();23.return;}'
        path=case/'source.no';path.write_text(source)
        proof=pipeline(path,case,23,**document('${29}'))
        tokens=highlight(path,source,'utf-16',case)
        if any(k in ('interpolation','interpolationDelimiter','formatProfile') for k,s in tokens):raise Failure('TOOL_LSP_FALSE_INTERPOLATION')
        return proof
    record('tooling-literal-and-comment',literal_action)
    def nested_action(case):
        source='start(){"outer=${"inner=${29}"}".console();23.return;}'
        path=case/'source.no';path.write_text(source)
        proof=pipeline(path,case,23,**document('outer=inner=29'))
        tokens=highlight(path,source,'utf-8',case)
        if [s for k,s in tokens if k=='interpolationDelimiter']!=['${','${','}','}']:raise Failure('TOOL_LSP_NESTED_DELIMITERS')
        return proof
    record('tooling-nested',nested_action)
    def format_action(case):
        source='start(){"Ω  ${17   \n +29} end  ".console();23.return;}   \n'
        path=case/'source.no';path.write_text(source)
        before=case/'before';before.mkdir();pipeline(path,before,23,**document('Ω  46 end  '))
        result=execute(['python3','-B',ROOT/'tools/rf27-format.py','--stdout',path],case,timeout=30)
        wanted=source.replace('17   \n','17\n').replace('}   \n','}\n').encode()
        if result!=(0,wanted,b'') or path.read_text()!=source:raise Failure('TOOL_FORMAT_LITERAL_OR_EXPRESSION')
        after=case/'after.no';after.write_bytes(result[1]);built=case/'after';built.mkdir()
        proof=pipeline(after,built,23,**document('Ω  46 end  '))
        again=execute(['python3','-B',ROOT/'tools/rf27-format.py','--stdout',after],case,timeout=30)
        if again!=result:raise Failure('TOOL_FORMAT_IDEMPOTENCE')
        return proof
    record('tooling-format-source',format_action)
    def invalid_format(case):
        source='start(){"${29".console();23.return;}'
        path=case/'source.no';path.write_text(source)
        result=execute(['python3','-B',ROOT/'tools/rf27-format.py','--write',path],case,timeout=30)
        if result[0]!=2 or result[1] or path.read_text()!=source:raise Failure('TOOL_FORMAT_FAILURE_ATOMICITY')
    record('tooling-format-invalid',invalid_format)
    def rename_action(case):
        source='(Int.value)add(){(value+7).return;}start(){"${29.add()} / literal add \\${29.add()}".console();23.return;}'
        path=case/'source.no';path.write_text(source)
        before=case/'before';before.mkdir();pipeline(path,before,23,**document('36 / literal add ${29.add()}'))
        result=execute(['python3','-B',ROOT/'tools/rf204-g162.py','_lsp','rename',path,str(source.index('29.add')+4),case,'raised'],case,stdin=source.encode(),timeout=30)
        if result[0] or result[2]:raise Failure('TOOL_RENAME_EXEC:'+repr(result))
        report=json.loads(result[1]);edits=report['plan']['edits']
        if len(edits)!=2 or len({e['symbolId'] for e in edits})!=1:raise Failure('TOOL_RENAME_SYMBOL_IDENTITY')
        expected=[(source.index('add()'),source.index('add()')+3),(source.index('29.add')+3,source.index('29.add')+6)]
        if sorted((e['startByte'],e['endByte']) for e in edits)!=expected:raise Failure('TOOL_RENAME_SPANS')
        changed=source.encode()
        for edit in sorted(edits,key=lambda e:e['startByte'],reverse=True):
            changed=changed[:edit['startByte']]+edit['replacement'].encode()+changed[edit['endByte']:]
        wanted=source.replace(')add(){',')raised(){').replace('${29.add()} /','${29.raised()} /').encode()
        if changed!=wanted or path.read_text()!=source:raise Failure('TOOL_RENAME_LITERAL_MUTATION')
        after=case/'after.no';after.write_bytes(changed);built=case/'after';built.mkdir()
        return pipeline(after,built,23,**document('36 / literal add ${29.add()}'))
    record('tooling-rename-source',rename_action)
    def rename_literal(case):
        source='(Int.value)add(){value.return;}start(){"${29.add()} literal add \\${29.add()}".console();23.return;}'
        path=case/'source.no';path.write_text(source)
        result=execute(['python3','-B',ROOT/'tools/rf204-g162.py','_lsp','rename',path,str(source.rindex('29.add')+4),case,'raised'],case,stdin=source.encode(),timeout=30)
        if result[0]!=1 or result[1] or path.read_text()!=source:raise Failure('TOOL_RENAME_LITERAL_ACCEPTED')
    record('tooling-rename-literal',rename_literal)
    def token_limit(case):
        # The source-tool transport has its own 1 MiB input contract. Keep the
        # ordinary program harness's 4096-byte stdin budget unchanged.
        script="import subprocess,sys; r=subprocess.run([sys.argv[1]],input=b' '*(1048576+1),stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=5); sys.exit(0 if (r.returncode,r.stdout,r.stderr)==(1,b'',b'') else 1)"
        result=execute(['python3','-B','-c',script,ROOT/'build/bin/nebo-token-scan'],case,timeout=10)
        if result!=(0,b'',b''):raise Failure('TOOL_TOKEN_SOURCE_LIMIT')
    record('tooling-token-limit',token_limit)
    return rows
