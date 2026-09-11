"""Current interface/SymbolId/DocRecord joins; no metadata-only runtime claims."""
import copy
import hashlib
import json
import sys
import tempfile
from pathlib import Path
from harness import ROOT, Failure, execute, elf, pipeline, reject
from module_test import documentation, fnv


def declarations(work):
    observed = []
    for _ in range(2):
        code,out,err = execute([ROOT/'build/bin/neboc','prelude-report','--edition','1'],work)
        if code or err:
            raise Failure('PRELUDE_REPORT_PROCESS')
        observed.append(json.loads(out))
    if observed[0] != observed[1]:
        raise Failure('PRELUDE_REPORT_NONDETERMINISM')
    report = observed[0]
    raw = (ROOT/'sdk/interfaces/prelude/std.prelude.ni').read_bytes()
    edition = json.loads(raw)['editions'][0]
    expected = [dict(row, symbolId=f'0x{fnv(("std.prelude:1:"+row["name"]).encode()):016x}',
                     implicitOrigin='PRELUDE') for row in edition['symbols']]
    if (report['symbols'] != expected or report['injected'] != len(expected)
            or report['interfaceHash'] != hashlib.sha256(raw).hexdigest()
            or report['target'] != 'x86_64-systemv-elf-linux'
            or report['capabilitiesGranted'] or report['network']):
        raise Failure('PRELUDE_DECLARATION_IDENTITY')
    registry = json.loads((ROOT/'sdk/interfaces/prelude/stdlib-registry.json').read_text())
    for row in expected:
        owners = [m for m in registry['modules'] if row['name'] in m['exports']]
        if len(owners)!=1 or owners[0]['name']!=row['origin'] or report['target'] not in owners[0]['targets']:
            raise Failure('PRELUDE_UNIQUE_OWNER_TARGET')
    return dict(declarations=len(expected), interface_sha256=report['interfaceHash'], symbol_ids=[x['symbolId'] for x in expected])


def stdlib_profile(work):
    status,out,err=execute([ROOT/'build/bin/neboc','stdlib','modules'],work)
    if status or err:raise Failure('STDLIB_MODULE_PROCESS')
    report=json.loads(out)
    raw=(ROOT/'sdk/interfaces/prelude/stdlib-registry.json').read_bytes()
    records=json.loads(raw)['modules']
    expected=[dict(row,edition='1',target='x86_64-systemv-elf-linux',importGrantsCapabilities=False) for row in records]
    if report['modules']!=expected or report['registryHash']!=hashlib.sha256(raw).hexdigest() or report['network']:
        raise Failure('STDLIB_DECLARATION_OR_CAPABILITY_DRIFT')
    exports=[name for row in records for name in row['exports']]
    if len(exports)!=len(set(exports)):raise Failure('STDLIB_EXPORT_OWNER_AMBIGUOUS')
    return dict(modules=len(records),exports=len(exports),registry_sha256=report['registryHash'],
                imports_grant_capabilities=False,physical_device_accessed=False)


def collision(work):
    if str(ROOT) not in sys.path:sys.path.insert(0,str(ROOT))
    from compiler.sdk.prelude import PreludeInterface,PreludeProfile,Prelude,PreludeError
    profile=PreludeProfile.forEdition('1')
    interface=PreludeInterface.load(profile,'x86_64-systemv-elf-linux')
    resolver={'scan': {'symbolId':'0x1','name':'scan','origin':'app'}}
    before=copy.deepcopy(resolver)
    try:Prelude.inject(resolver,interface,profile)
    except PreludeError as error:
        if str(error.code)!='NEBO-RF166-G163-003' or resolver!=before:
            raise Failure('PRELUDE_COLLISION_ATOMICITY')
    else:raise Failure('PRELUDE_COLLISION_ACCEPTED')
    return dict(rejected=True,resolver_unchanged=True)


def console_live_build(work):
    source=work/'source.no'
    source.write_text('start(){"Input".console().scan().text;23.return;}')
    identities=[]
    for n in range(2):
        assembly=work/f'program-{n}.asm';binary=work/f'program-{n}.elf'
        for mode,path in [('check',None),('emit-asm',assembly),('build',binary)]:
            args=[ROOT/'build/bin/neboc',mode,source]
            if path:args+=['-o',path]
            if execute(args,work)!=(0,b'',b''):raise Failure('CONSOLE_LIVE_ADMISSION')
        elf(binary)
        identities.append((assembly.read_bytes(),binary.read_bytes()))
    if identities[0]!=identities[1]:raise Failure('CONSOLE_LIVE_BUILD_DETERMINISM')
    # Intentionally not a runtime proof: native Console input needs a live
    # frontend. The separate typed mock/replay matrix owns headless behavior.
    return dict(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                asm_sha256=hashlib.sha256(identities[0][0]).hexdigest(),
                elf_sha256=hashlib.sha256(identities[0][1]).hexdigest(),
                runtime_executed=False,classification='TARGET_OR_ENVIRONMENT_JUSTIFIED')


def stdlib_source(work,kind,value,status,no_prelude):
    expression=(f'Matrix<Int>.filled(1,1,{value}).at(0,0)' if kind=='Matrix' else
                f'Tensor<Int>.filled(Tuple.of(1),{value}).at(Tuple.of(0))')
    text=(f'import "std.scientific" {{ {kind}; }}.science;\n'
          'import "std.console" { console; }.output;\n'
          f'start(){{{expression}.console();{status}.return;}}')
    source=work/'source.no';source.write_text(text)
    return pipeline(source,work,status,kinds=[4],text=str(value).encode(),no_prelude=no_prelude)


def stdlib_negative(work,variant):
    imports='import "std.scientific" { Matrix; }.science;\n'
    if variant=='body-type':
        source=work/'source.no';source.write_text(imports+'start(){Matrix<Int>.filled(1,1,true);23.return;}')
        return reject(source,work,'NEBO_TYPE_MISMATCH')
    if variant=='return-span':
        source=work/'source.no';source.write_text('// Unicode: é\n'+imports+'start(){Matrix<Int>.filled(1,1,17).a;"bad".return;}')
        return reject(source,work,'NEBO_ENTRYPOINT_INVALID_SIGNATURE')
    code,text,no_prelude={
        'unknown-export':('NEBO-RF166-G163-005','import "std.scientific" { Imaginary; }.science;\nstart(){23.return;}',False),
        'duplicate':('NEBO-RF166-G163-006',imports+imports+'start(){23.return;}',False),
        'hidden-prelude':('NEBO-RF166-G163-002',imports+'start(){Option<Int>(Some(17)).x;x.unwrapOr(7).return;}',True),
    }[variant]
    source=work/'source.no';source.write_text(text)
    observations=[]
    for mode in ('check','emit-asm','build'):
        target=work/(mode+'.artifact');args=[ROOT/'build/bin/neboc',mode,source]
        if no_prelude:args+=['--no-prelude']
        if mode!='check':args+=['-o',target]
        status,out,err=execute(args,work)
        if status!=1 or target.exists() or code.encode()+b':' not in out+err:
            raise Failure('STDLIB_NEGATIVE:'+repr((status,out,err)))
        observations.append(hashlib.sha256(out+err).hexdigest())
    if len(set(observations))!=1:raise Failure('STDLIB_DIAGNOSTIC_PARITY')
    return dict(stages=3,code=code)


def stdlib_layout(work,variant):
    if variant=='same-line':
        text='import "std.scientific" { Matrix; }.science;start(){Matrix<Int>.filled(1,1,29).at(0,0).return;}'
        expected=29
    elif variant=='multiline':
        text='import /* owner */ "std.scientific" {\nMatrix;\n}.science;\nstart(){Matrix<Int>.filled(1,1,7).at(0,0).return;}'
        expected=7
    elif variant=='comment':
        text='/* import "std.scientific" { Nonexistent; }.science; */start(){23.return;}'
        expected=23
    else:
        text='start(){"import \"std.scientific\" { Nonexistent; }.science;".byteLength().console();23.return;}'
        expected=23
    source=work/'source.no';source.write_text(text)
    return pipeline(source,work,expected)


def stdlib_cases():
    cases=[]
    for kind in ('Matrix','Tensor'):
        for value,status in [(17,23),(71,7),(29,255)]:
            for disabled in (False,True):
                cases.append((f'stdlib-{kind}-{value}-{disabled}','composition',
                    lambda work,k=kind,v=value,s=status,n=disabled:stdlib_source(work,k,v,s,n)))
    for name in ('unknown-export','duplicate','hidden-prelude','body-type','return-span'):
        cases.append(('stdlib-'+name,'negative',lambda work,n=name:stdlib_negative(work,n)))
    for name in ("same-line","multiline","comment"):
        cases.append(("stdlib-"+name,"composition",lambda work,n=name:stdlib_layout(work,n)))
    return cases


def run():
    rows=[]
    with tempfile.TemporaryDirectory(dir=ROOT/'build/tmp',prefix='nebo-g170-metadata-') as directory:
        for name,category,action in [('prelude-declarations','metadata',declarations),
                ('prelude-collision','negative',collision),
                ('stdlib-profile','metadata',stdlib_profile),
                ('docrecord-17','composition',lambda work:documentation(work,17)),
                ('docrecord-71','metamorphic',lambda work:documentation(work,71)),
                ('console-live-build','target',console_live_build)]+stdlib_cases():
            work=Path(directory)/name;work.mkdir()
            try:row=dict(result='PASS',**action(work))
            except (Failure,ValueError,KeyError) as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category=category,**row))
    return dict(passed=sum(x['result']=='PASS' for x in rows),total=len(rows),cases=rows)


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
