#!/usr/bin/env python3
"""Adversarial checks of the oracle, never executions of corrupt ELF files."""
import struct
import signal
import sys
import os
import tempfile
from pathlib import Path
from harness import Failure, ROOT, console_trace, elf, pipeline, execute, process_status, filesystem_snapshot, filesystem_effects, human_diagnostic, diagnostic_span
from runner import relative

def main(report=True):
    checks = 0
    def rejected(action):
        nonlocal checks
        try:
            action()
        except Failure:
            checks += 1
            return
        raise AssertionError('oracle accepted a corrupt observation')

    with tempfile.TemporaryDirectory(prefix='nebo-G170-', dir='/tmp') as directory:
        work = Path(directory)
        # Budget exhaustion must fail before attempting to spawn the command.
        import harness
        saved_calls=harness._calls
        try:
            harness._calls=harness.MAX_CAMPAIGN_CALLS
            rejected(lambda:execute([work/'must-not-execute'],work))
        finally:harness._calls=saved_calls+1
        saved_started=harness._started
        try:
            harness._started-=harness.MAX_CAMPAIGN_SECONDS+1
            rejected(lambda:execute([work/'must-not-execute'],work))
        finally:harness._started=saved_started
        rc,out,err=execute([sys.executable,'-c','import os;print(os.getcwd())'],work,runtime=True)
        assert rc==0 and out.decode().strip()==str(work) and not err
        checks+=1
        before=filesystem_snapshot(work)
        fixture=work/'data.bin';fixture.write_bytes(b'owned scratch')
        after=filesystem_snapshot(work)
        assert filesystem_effects(before,after,{'data.bin':b'owned scratch'})
        checks+=1
        rejected(lambda:filesystem_effects(before,after,{}))
        rejected(lambda:filesystem_effects(before,after,{'data.bin':b'wrong content'}))
        fixture.unlink()
        assert filesystem_effects(after,filesystem_snapshot(work),{'data.bin':None})
        checks+=1
        fixture.symlink_to(work/'nonexistent-owned-target')
        rejected(lambda:filesystem_snapshot(work));fixture.unlink()
        diagnostic={'note':'checked status contract'}
        lines=[b'source.no:1:1: error NEBO_ENTRYPOINT_INVALID_SIGNATURE: invalid',b'  note: checked status contract']
        human_diagnostic(lines,'NEBO_ENTRYPOINT_INVALID_SIGNATURE',diagnostic);checks+=1
        rejected(lambda:human_diagnostic(lines+[b'  note: unrelated'],'NEBO_ENTRYPOINT_INVALID_SIGNATURE',diagnostic))
        rejected(lambda:human_diagnostic(lines[:1],'NEBO_ENTRYPOINT_INVALID_SIGNATURE',diagnostic))
        for start,end in ((-1,1),(0,5),(2,1),(True,1),(1,2)):
            # The last pair splits a multibyte UTF-8 scalar.
            rejected(lambda:diagnostic_span({'primary':{'sourceId':1,'start':start,'end':end}},'Ωx'.encode()))
        rejected(lambda:diagnostic_span({'primary':{'sourceId':1,'start':0,'end':2}},'Ωx'.encode(),(2,3)))
        source = work / 'control.no'
        source.write_text('start() { 0.return; }\n')
        pipeline(source, work, 0, keep_artifacts=True)
        cleanup_case=work/'bounded-artifacts';cleanup_case.mkdir()
        cleanup_source=cleanup_case/'source.no';cleanup_source.write_text('start(){23.return;}')
        pipeline(cleanup_source,cleanup_case,23)
        assert not (cleanup_case/'root-0').exists() and not (cleanup_case/'root-1').exists();checks+=1
        rejected(lambda:pipeline(cleanup_source,cleanup_case,7))
        assert not (cleanup_case/'root-0').exists() and not (cleanup_case/'root-1').exists();checks+=1
        from control_test import callable_oracle
        observed=callable_oracle(1,7,24)
        for name,offset,replacement in (('callable-not-called',40,0),
                                        ('callable-not-dropped',48,0),
                                        ('callable-double-drop',48,2),
                                        ('callable-not-cleared',16,17)):
            case=work/name;case.mkdir();source=case/'source.no'
            source.write_text('callable work(Int.value) capture copy 17 {sum.return;}'
                              'start(){work.call(7).drop().return;}')
            wrong=bytearray(observed);struct.pack_into('<Q',wrong,offset,replacement)
            rejected(lambda:pipeline(source,case,24,callable_trace=True,stdout=bytes(wrong)))
        from ownership_test import oracle as ownership_oracle
        events=[(1,1,1,64,0,0,64),(2,1,0,0,0,0,64)]
        data=b''.join(struct.pack('<8s7Q',b'NEBOMOW1',*row) for row in events)
        observe=ownership_oracle(events)
        assert observe(data,0)==data;checks+=1
        for wrong in (b'',data[:64],data+data[64:],data[64:]+data[:64],b'WRONGTAG'+data[8:]):
            rejected(lambda:observe(wrong,0))
        for offset in (24,32,56,88,96):
            wrong=bytearray(data);struct.pack_into('<Q',wrong,offset,999)
            rejected(lambda:observe(bytes(wrong),0))
        # Native tagged-value publications must reject altered output even
        # when the explicit process return and all compiler stages are valid.
        for family,ctor,method in [('option','Option<Int>(Some(17))','expect("present")'),('result','Result<Int,Int>(Ok(17))','get()'),('error','Error(17,1,50,2,8,0)','code()')]:
            case=work/('wrong-'+family);case.mkdir();source=case/'source.no'
            source.write_text('start(){'+ctor+'.x;x.'+method+'.console();23.return;}')
            rejected(lambda:pipeline(source,case,23,kinds=[4],text=b'71'))
        # Valid Dict programs with deliberately wrong independent oracles
        # must fail even though checking, assembly and linking succeeded.
        for name, expected, text in (('wrong-value',23,b'71'),
                                      ('wrong-exit',7,b'53')):
            case=work/name;case.mkdir()
            source=case/'source.no'
            source.write_text('start(){Dict<Int,Int>.new().d;d.insert(17,53);'
                              'd.get(17).expect("present").console();23.return;}')
            rejected(lambda: pipeline(source,case,expected,kinds=[4],text=text))
        # Real collected values must reject an independently corrupted order
        # or cell value, even when every compiler/ELF stage succeeds.
        for name,text in [('collect-wrong-order',b'711729'),('collect-wrong-value',b'172983')]:
            case=work/name;case.mkdir();source=case/'source.no'
            source.write_text('start(){Table.fromColumns([Tuple.of("age",Column<Int>.from([17,29]))]).a;'
                'Table.fromColumns([Tuple.of("age",Column<Int>.from([71]))]).b;Dataset.fromTables([a,b]).d;'
                'd.collect().rows;0.i.mutable;while(i<3){rows.at(i).get("age").expect("v").console();i+=1;}23.return;}')
            rejected(lambda:pipeline(source,case,23,kinds=[4,4,4],text=text))
        for name,body,wrong,kinds in [('normalize-wrong-bytes','"é".normalizeNfc()',b'e\xcc\x81',[2]),
                                       ('normalize-lost-line','"a\\n\\nb".normalizeNewlines()',b'a\nb',[2,3,2])]:
            case=work/name;case.mkdir();source=case/'source.no'
            source.write_text('start(){'+body+'.console();23.return;}')
            rejected(lambda:pipeline(source,case,23,kinds=kinds,text=wrong,publications=1))
        for name,body,wrong,kind in [
                ('parsed-value-corrupted','"83".parseInt().unwrapOr(0)',b'17',4),
                ('checked-value-corrupted','"aba".replaceAllChecked("a","Nebo").unwrapOr("bad")',b'aba',2),
                ('parsed-error-tag-corrupted','"bad".parseFloat().isErr()',b'false',5)]:
            case=work/name;case.mkdir();source=case/'source.no'
            source.write_text('start(){'+body+'.console();23.return;}')
            rejected(lambda:pipeline(source,case,23,kinds=[kind],text=wrong))
        for name,body,wrong,kind in [
                ('format-value-corrupted','"%d".format(83)',b'17',2),
                ('format-named-order-corrupted','"%{first:d}/%{second:d}".format(second:29,first:17)',b'29/17',2),
                ('format-error-tag-corrupted','"%z".formatWith(0,29).isErr()',b'false',5),
                ('format-scientific-carry-corrupted','"%.2e".format(9.999)',b'10.00e+00',2),
                ('interpolation-value-corrupted','"${17+29}"',b'17',2),
                ('interpolation-order-corrupted','"${17}/${29}"',b'29/17',2),
                ('interpolation-profile-corrupted','"${29:hex()}"',b'29',2),
                ('interpolation-not-literal','"${17+29}"',b'${17+29}',2)]:
            case=work/name;case.mkdir();source=case/'source.no'
            source.write_text('start(){'+body+'.console();23.return;}')
            rejected(lambda:pipeline(source,case,23,kinds=[kind],text=wrong))
        # A controlled helper restores SIGPIPE's default action. No output
        # pipeline or malformed Nebo binary is involved in this signal test.
        rc, out, err = execute([sys.executable, '-c',
            'import os,signal; signal.signal(signal.SIGPIPE,signal.SIG_DFL); os.kill(os.getpid(),signal.SIGPIPE)'], work)
        assert rc == -signal.SIGPIPE and not out and not err
        assert process_status(rc) == {'exit': None, 'signal': 13, 'classification': 'SIGNAL'}
        checks += 1
        helper = ('import os,time,pathlib; pid=os.fork(); '
                  'os.setpgid(0,0) if pid==0 else None; '
                  'pathlib.Path("' + str(work / 'child.pid') + '").write_text(str(os.getpid())) if pid==0 else None; '
                  'time.sleep(30)')
        rejected(lambda: execute([sys.executable, '-c', helper], work, timeout=1))
        child=int((work/'child.pid').read_text())
        try: os.kill(child,0)
        except ProcessLookupError: checks += 1
        else: raise AssertionError('cancelled descendant survived')
        rc, out, err = execute([sys.executable, '-c', 'raise SystemExit(141)'], work)
        assert process_status(rc) == {'exit': 141, 'signal': None, 'classification': 'EXIT'}
        checks += 1
        valid = (work / 'root-0/program.elf').read_bytes()
        for data in (b'', valid[:63], b'BAD!' + valid[4:]):
            candidate = work / 'mutated.elf'
            candidate.write_bytes(data)
            rejected(lambda: elf(candidate))
        candidate=work/'mutated.elf'
        for fmt,offset,value in [('<I',20,0),('<H',52,0),('<Q',32,1),('<Q',40,len(valid)+64)]:
            data=bytearray(valid);struct.pack_into(fmt,data,offset,value);candidate.write_bytes(data)
            rejected(lambda:elf(candidate))
        phoff = struct.unpack_from('<Q', valid, 32)[0]
        phnum = struct.unpack_from('<H', valid, 56)[0]
        for kind in (2, 3):
            data = bytearray(valid)
            struct.pack_into('<I', data, phoff, kind)
            candidate.write_bytes(data)
            rejected(lambda: elf(candidate))
        for index in range(phnum):
            offset = phoff + 56 * index
            kind, flags = struct.unpack_from('<II', valid, offset)
            if kind == 1 or kind == 0x6474e551:
                data = bytearray(valid)
                struct.pack_into('<I', data, offset + 4, 7)
                candidate.write_bytes(data)
                rejected(lambda: elf(candidate))
        first_load=next(phoff+56*i for i in range(phnum) if struct.unpack_from('<I',valid,phoff+56*i)[0]==1)
        for field,value in ((16,2**64-1),(48,3),(4,0x10004)):
            data=bytearray(valid);struct.pack_into('<I' if field==4 else '<Q',data,first_load+field,value)
            candidate.write_bytes(data);rejected(lambda:elf(candidate))
        data = bytearray(valid)
        struct.pack_into('<Q', data, 24, 0)
        candidate.write_bytes(data)
        rejected(lambda: elf(candidate))
        data = bytearray(valid)
        struct.pack_into('<Q', data, 32, len(data))
        candidate.write_bytes(data)
        rejected(lambda: elf(candidate))

    frame = struct.pack('<8sQQQQ', b'NEBOTRC1', 1, 2, 1, 4) + b'42'
    console_trace(frame, [4], b'42')
    multiline=struct.pack('<8sQQQ3Q',b'NEBOTRC1',3,3,1,2,3,2)+b'a\nb'
    console_trace(multiline,[2,3,2],b'a\nb',1)
    rejected(lambda:console_trace(multiline,[2,3,2],b'a\nb',3))
    rejected(lambda:console_trace(multiline,[2,3,2],b'a\nb',0))
    rejected(lambda:console_trace(multiline,[2,3,2],b'x\ny',1))
    checks += 1
    for corrupt in (b'', frame[:31], frame[:-1], frame + b'x',
                    b'BADMAGIC' + frame[8:], frame[:-2] + b'97'):
        rejected(lambda: console_trace(corrupt, [4], b'42'))
    for offset, value in ((8, 0), (16, 3), (24, 0), (32, 5)):
        data = bytearray(frame)
        struct.pack_into('<Q', data, offset, value)
        rejected(lambda: console_trace(data, [4], b'42'))
    for path in ('../outside.no', '/tmp/outside.no', 'tests/../../outside.no', 'a;command'):
        rejected(lambda: relative(path))
    from hash_policy_test import policy_observation, fnv
    hash_frame=b''.join(struct.pack('<8sQQQ',b'NEBOHSH1',*row)
                        for row in ((57,0,29),(1,0,29),(52,17,fnv(17,53))))
    assert policy_observation(hash_frame,[(57,29)])==[]
    checks+=1
    for offset in (0,8,16,24,40,48,56,72,80,88):
        corrupt=bytearray(hash_frame);corrupt[offset]^=1
        rejected(lambda: policy_observation(bytes(corrupt),[(57,29)]))
    repeated=b''.join(struct.pack('<8sQQQ',b'NEBOHSH1',*row)
                      for row in ((58,1,41),(1,1,41),(52,17^41,fnv(17^41,53))))
    rejected(lambda: policy_observation(repeated,[(58,None)],[41]))
    from console_public_test import oracle as visual_oracle, software_oracle
    visual_nodes=((2,'seed',None,None),)
    visual_options=visual_oracle(visual_nodes,active=True,title='report')
    boxes,nodes,commands,pixels=software_oracle(visual_nodes)
    retained=struct.pack('<8sQQQQ',b'NEBOTRC1',1,4,1,2)+b'seed'
    visual_header=struct.pack('<8s13Q',b'NEBOCST1',1,4,1,0,0,6,boxes,nodes,commands,pixels,256,128,commands)+b'report'
    visual_frame=retained+visual_header
    visual_options['observation'](visual_frame,0)
    checks+=1
    for offset in (0,8,16,24,32,40,48,56,64,72,80,88,96,104,112):
        bad=bytearray(visual_frame);bad[len(retained)+offset]^=1
        rejected(lambda:visual_options['observation'](bytes(bad),0))
    rejected(lambda:visual_options['observation'](visual_frame+b'extra',0))
    rejected(lambda:visual_options['observation'](visual_frame[:-1],0))
    view_bytes=struct.pack('<8sQ4Q',b'NEBOVIW1',1,4,15,1,1)
    view_options=visual_oracle(visual_nodes,active=True,title='report',views=((4,15,1,1),))
    view_frame=visual_frame+view_bytes
    view_options['observation'](view_frame,0);checks+=1
    for offset in (0,8,16,24,32,40):
        bad=bytearray(view_frame);bad[len(visual_frame)+offset]^=1
        rejected(lambda:view_options['observation'](bytes(bad),0))
    from scan_public_test import trace_record,trace_oracle
    scan_expected=trace_record(b'Synthetic7!',security=93,strength=1)
    scan_frame=struct.pack('<8s26Q',b'NEBOSCN1',*scan_expected)
    scan_observe=trace_oracle([scan_expected])
    assert scan_observe(scan_frame,0)==scan_frame;checks+=1
    for offset in range(0,216,8):
        bad=bytearray(scan_frame);bad[offset]^=1
        rejected(lambda:scan_observe(bytes(bad),0))
    for bad in (b'',scan_frame[:-1],scan_frame+scan_frame,scan_frame+b'Synthetic7!'):
        rejected(lambda:scan_observe(bad,0))
    # Even a normal exit with correct input-derived binding must fail if its
    # public event leaks the private secret length or digest.
    for index,value in ((15,11),(16,0x12345678),(17,0)):
        bad=bytearray(scan_frame);struct.pack_into('<Q',bad,8+8*index,value)
        rejected(lambda:scan_observe(bytes(bad),0))
    if report:print(f'G170_ORACLE_SELF_TESTS={checks}/{checks}_PASS')
    return {'passed':checks,'total':checks,'cases':[{'id':'oracle-mutations','result':'PASS'}]}

if __name__ == '__main__':
    main()
