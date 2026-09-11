#!/usr/bin/env python3
"""Public ownership source programs with actual native allocation observations."""
import json,struct,tempfile
from pathlib import Path
from harness import ROOT,pipeline,reject,execute,Failure


def oracle(events):
    def observe(data,run):
        if len(data)!=64*len(events):raise Failure('OWNERSHIP_EVENT_COUNT')
        actual=[]
        for pos in range(0,len(data),64):
            magic,*values=struct.unpack('<8s7Q',data[pos:pos+64])
            if magic!=b'NEBOMOW1':raise Failure('OWNERSHIP_EVENT_MAGIC')
            actual.append(tuple(values))
        if actual!=events:raise Failure('OWNERSHIP_RUNTIME_ORACLE:'+repr(actual))
        return data
    return observe


def cases():
    rows=[]
    # operation, source slot, live system blocks, live system bytes,
    # actual arena cursor, actual generation, actual operation size.
    for size in (1,7,64,4096,65536):
        for returned in (0,7,23,29,255):
            source=f'start(){{Allocator.system().a;a.allocate({size}).b;a.deallocate(b).released;{returned}.return;}}'
            events=[(1,1,1,size,0,0,size),(2,1,0,0,0,0,size)]
            rows.append((f'allocate-{size}-return-{returned}',source,returned,events))
    for left,right in ((17,29),(71,29),(17,83)):
        source=f'start(){{Allocator.system().a;a.allocate({left}).x;a.allocate({right}).y;a.deallocate(x).one;a.deallocate(y).two;23.return;}}'
        rows.append((f'independent-{left}-{right}',source,23,[(1,1,1,left,0,0,left),(1,2,2,left+right,0,0,right),(2,1,1,right,0,0,left),(2,2,0,0,0,0,right)]))
    for action in ('drop','deferDrop'):
        source=f'start(){{Allocator.system().a;a.allocate(37).b;b.{action}();23.return;}}'
        rows.append((action,source,23,[(1,1,1,37,0,0,37),(2,1,0,0,0,0,37)]))
    rows.append(('implicit-drop','start(){Allocator.system().a;a.allocate(43).b;23.return;}',23,[(1,1,1,43,0,0,43),(2,1,0,0,0,0,43)]))
    rows.append(('move-block','start(){Allocator.system().a;a.allocate(59).b;b.move().c;a.deallocate(c).released;23.return;}',23,[(1,1,1,59,0,0,59),(7,2,1,59,0,0,59),(2,2,0,0,0,0,59)]))
    rows.append(('clone-block','start(){Allocator.system().a;a.allocate(61).b;b.clone().c;a.deallocate(b).one;a.deallocate(c).two;23.return;}',23,[(1,1,1,61,0,0,61),(8,2,2,122,0,0,61),(2,1,1,61,0,0,61),(2,2,0,0,0,0,61)]))
    for capacity,items in ((128,3),(1024,7),(65536,8192),(1048576,17)):
        source=f'start(){{Arena.withCapacity({capacity}).a;a.allocate<Int>({items}).b;a.reset().r;23.return;}}'
        rows.append((f'arena-{capacity}-{items}',source,23,[(3,0,0,0,0,1,capacity),(4,1,0,0,items*8,1,items*8),(5,0,0,0,0,2,0),(6,0,0,0,0,2,0)]))
    rows.append(('reset-and-reuse','start(){Arena.withCapacity(32).a;a.allocate<Int>(3).x;a.reset().r;a.allocate<Int>(4).y;23.return;}',23,[(3,0,0,0,0,1,32),(4,1,0,0,24,1,24),(5,0,0,0,0,2,0),(4,3,0,0,32,2,32),(6,0,0,0,32,2,0)]))
    rows.append(('two-arenas','start(){Arena.withCapacity(17).a;Arena.withCapacity(32).b;a.allocate<Int>(2).x;b.allocate<Int>(3).y;a.reset().r;23.return;}',23,[(3,0,0,0,0,1,17),(3,1,0,0,0,1,32),(4,2,0,0,16,1,16),(4,3,0,0,24,1,24),(5,0,0,0,0,2,0),(6,1,0,0,24,1,0),(6,0,0,0,0,2,0)]))
    rows.append(('temporary-block','start(){Allocator.system().a;a.allocate(41);23.return;}',23,[(1,1,1,41,0,0,41),(2,1,0,0,0,0,41)]))
    rows.append(('temporary-arena','start(){Arena.withCapacity(127);23.return;}',23,[(3,0,0,0,0,1,127),(6,0,0,0,0,1,0)]))
    rows.append(('early-return','start(){Allocator.system().a;a.allocate(31).b;23.return;a.allocate(79).c;}',23,[(1,1,1,31,0,0,31),(2,1,0,0,0,0,31)]))
    rows.append(('move-arena','start(){Arena.withCapacity(128).a;a.move().b;b.allocate<Int>(3).c;b.reset().r;23.return;}',23,[(3,0,0,0,0,1,128),(7,1,0,0,0,1,128),(4,2,0,0,24,1,24),(5,1,0,0,0,2,0),(6,1,0,0,0,2,0)]))
    rows.append(('move-arena-with-block','start(){Arena.withCapacity(128).a;a.allocate<Int>(3).x;a.move().b;b.reset().r;23.return;}',23,[(3,0,0,0,0,1,128),(4,1,0,0,24,1,24),(7,2,0,0,24,1,128),(5,2,0,0,0,2,0),(6,2,0,0,0,2,0)]))
    rows.append(('clone-arena' ,'start(){Arena.withCapacity(128).a;a.clone().b;b.allocate<Int>(3).c;a.allocate<Int>(7).d;23.return;}',23,[(3,0,0,0,0,1,128),(8,1,0,0,0,1,128),(4,2,0,0,24,1,24),(4,3,0,0,56,1,56),(6,1,0,0,24,1,0),(6,0,0,0,56,1,0)]))
    for i,status in enumerate((1,23,65,2,1,81),1):
        rows.append((f'G004-{i:02}',(ROOT/f'examples/rf204/G004/RF204-G004-S{i:02}.no').read_text(),status,None))
    return rows


def negatives():
    cases=[('allocator-deallocate-active-borrow','NEBO-BORROW-MUTABLE-CONFLICT'),('allocator-zero-layout','NEBO-OWNERSHIP-ALLOCATOR-LAYOUT'),('arena-exhausted','NEBO-OWNERSHIP-ARENA-EXHAUSTED'),('arena-reset-active-borrow','NEBO-BORROW-MUTABLE-CONFLICT'),('unique-reborrow-conflict','NEBO-BORROW-MUTABLE-CONFLICT')]
    rows=[(name,(ROOT/f'tests/rf204/G004/negative/{name}.no').read_text(),code) for name,code in cases]
    for name,path,code in [('use-after-move','f02/negative/use-after-move','NEBO-OWNERSHIP-USE-AFTER-MOVE'),('double-drop','f04/negative/double-drop','NEBO-OWNERSHIP-DOUBLE-DROP'),('borrow-escape','f03/negative/borrow-escape-return','NEBO-LIFETIME-ESCAPE'),('leak-owner','f06/negative/leak-owner','NEBO-RESOURCE-LEAK-PATH')]:
        rows.append((name,(ROOT/f'tests/rf27-g04/{path}.no').read_text(),code))
    for name,body,code in [
        ('arena-drop-borrow','Arena.withCapacity(128).a;a.allocate<Int>(3).b;b.borrowShared().v;a.drop();23.return;','NEBO-BORROW-MUTABLE-CONFLICT'),
        ('arena-move-borrow','Arena.withCapacity(128).a;a.allocate<Int>(3).b;b.borrowShared().v;a.move().c;23.return;','NEBO-BORROW-MUTABLE-CONFLICT'),
        ('arena-move-reset','Arena.withCapacity(128).a;a.allocate<Int>(3).b;a.move().c;c.reset().r;b.borrowShared().v;23.return;','NEBO-BORROW-MUTABLE-CONFLICT')]:
        rows.append((name,'start(){'+body+'}',code))
    for value in ('"bad"','1.5','block'):
        rows.append(('invalid-process-'+value.replace('"',''),f'start(){{Allocator.system().a;a.allocate(17).block;{value}.return;}}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-ownership-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,events in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:
                proof=pipeline(path,work,status,ownership_trace=events is not None,observation=oracle(events) if events is not None else None)
                row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives():
            work=root/('negative-'+name);work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=reject(path,work,code);row=dict(result='PASS',**proof)
            except Failure as error:row=dict(result='FAIL',failure=str(error))
            rows.append(dict(id=name,category='negative',**row))
        for name,path in [('system','build/tests/rf204-g004/system_allocator_test'),('arena','build/tests/rf27-g04-f05/bounded_arena_test'),('safety','build/tests/rf27-g04-f06/safety_proof_test'),('report','build/tests/rf204-g004/ownership_report_test')]:
            status,out,err=execute([ROOT/path],root,runtime=True)
            rows.append(dict(id='native-'+name,category='native',result='PASS' if (status,out,err)==(0,b'',b'') else 'FAIL',exit=status))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
