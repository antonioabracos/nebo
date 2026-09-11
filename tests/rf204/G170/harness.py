"""Bounded local runtime observations and independent ELF/Console oracles."""
from pathlib import Path
import ctypes,hashlib,json,os,resource,signal,struct,subprocess,sys,tempfile,time,shutil
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'scripts/rf172'))
from p01_security import _limits

class Failure(RuntimeError): pass

_started=time.monotonic()
_calls=0
# The current ~8,600-case matrix includes two emit/build/run passes per
# public source plus native bit-pattern tests, diagnostics and metadata joins.
# 65,536 is a finite envelope for this expanded group; each process retains
# its own timeout and the independent 900-second campaign deadline.
MAX_CAMPAIGN_CALLS=65536
MAX_CAMPAIGN_SECONDS=900

def campaign_stats():
    return dict(process_calls=_calls,process_limit=MAX_CAMPAIGN_CALLS,
                elapsed_seconds=round(time.monotonic()-_started,3),time_limit_seconds=MAX_CAMPAIGN_SECONDS)

def process_status(returncode):
    """Keep POSIX signal termination distinct from a normal 0..255 exit."""
    if returncode < 0:
        return {'exit': None, 'signal': -returncode, 'classification': 'SIGNAL'}
    return {'exit': returncode, 'signal': None, 'classification': 'EXIT'}

def execute(argv, work, *, stdin=b'', trace=False, math_trace=False, hash_trace=False, timeout=15, runtime=False, stack_bytes=None, callable_trace=False, ownership_trace=False, console_state_trace=False,scan_trace=False, runtime_environment=None,runtime_loopback=False,mmap_failure_threshold=None):
    global _calls
    _calls+=1
    remaining=MAX_CAMPAIGN_SECONDS-(time.monotonic()-_started)
    if _calls>MAX_CAMPAIGN_CALLS: raise Failure('CAMPAIGN_PROCESS_BUDGET')
    if remaining<=0: raise Failure('CAMPAIGN_TIME_BUDGET')
    timeout=min(timeout,remaining)
    if len(stdin)>4096: raise Failure('INPUT_BUDGET')
    env={'PATH':'/usr/bin:/bin','HOME':str(work),'TMPDIR':str(work),'LANG':'C','LC_ALL':'C','TZ':'UTC'}
    if runtime_environment:
        if not runtime or len(runtime_environment)>16:raise Failure('ENVIRONMENT_PROFILE')
        for key,value in runtime_environment.items():
            if (not isinstance(key,str) or not key.startswith('NEBO_TEST_') or not key.isascii()
                or not key.replace('_','').isalnum() or not isinstance(value,str)
                or '\0' in value or len(value.encode())>4096):raise Failure('ENVIRONMENT_PROFILE')
        if sum(len(k.encode())+len(v.encode())+2 for k,v in runtime_environment.items())>4096:
            raise Failure('ENVIRONMENT_BUDGET')
        env.update(runtime_environment)
    if trace: env['NEBO_CONSOLE_TRACE']='1'
    if math_trace: env['NEBO_MATH_TRACE']='1'
    if hash_trace: env['NEBO_HASH_TRACE']='1'
    if callable_trace: env['NEBO_CALLABLE_TRACE']='1'
    if ownership_trace: env['NEBO_OWNERSHIP_TRACE']='1'
    if console_state_trace: env['NEBO_CONSOLE_STATE_TRACE']='1'
    if scan_trace: env['NEBO_SCAN_TRACE']='1'
    if stack_bytes is not None and (not runtime or not 1048576<=stack_bytes<=8388608):
        raise Failure('STACK_TEST_PROFILE')
    if mmap_failure_threshold is not None and not runtime:raise Failure("MMAP_FAULT_RUNTIME_ONLY")
    if runtime_loopback and not runtime:raise Failure("COMPILER_NETWORK_FORBIDDEN")
    def child_limits():
        # Set only the isolated child's soft limit; the host and hard limit
        # remain unchanged. This makes resource-boundary oracles reproducible.
        if stack_bytes is not None:
            _, hard = resource.getrlimit(resource.RLIMIT_STACK)
            resource.setrlimit(resource.RLIMIT_STACK, (stack_bytes, hard))
        _limits(timeout, False, native_loopback=runtime_loopback,mmap_failure_threshold=mmap_failure_threshold)
    # Adopt and reap descendants; tools may create a different process group
    # inside the private session. The inherited seccomp policy denies setsid.
    if ctypes.CDLL(None, use_errno=True).prctl(36,1,0,0,0):
        raise Failure('CHILD_SUBREAPER_UNAVAILABLE')
    with tempfile.TemporaryFile(dir=work) as out,tempfile.TemporaryFile(dir=work) as err,tempfile.TemporaryFile(dir=work) as inp:
        inp.write(stdin);inp.seek(0)
        p=subprocess.Popen([str(x) for x in argv],cwd=work if runtime else ROOT,env=env,stdin=inp,stdout=out,stderr=err,
                           start_new_session=True,preexec_fn=child_limits)
        try: p.wait(timeout=timeout)
        except subprocess.TimeoutExpired as error: raise Failure('TIMEOUT') from error
        finally:
            owned=[]
            for entry in Path('/proc').iterdir():
                if not entry.name.isdigit(): continue
                try:
                    fields=(entry/'stat').read_text().rsplit(')',1)[1].split()
                    if int(fields[3]) == p.pid:
                        pid=int(entry.name)
                        if pid != p.pid: owned.append(pid)
                        os.kill(pid,signal.SIGKILL)
                except (FileNotFoundError,ProcessLookupError,PermissionError): pass
            try: os.killpg(p.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            p.wait()
            for pid in owned:
                try: os.waitpid(pid,0)
                except ChildProcessError: pass
        out.seek(0);err.seek(0);a=out.read(1048577);b=err.read(1048577)
        if max(len(a),len(b))>1048576: raise Failure('OUTPUT_BUDGET')
        return p.returncode,a,b

def elf(path):
    data=path.read_bytes()
    if len(data)<64 or data[:7]!=b'\x7fELF\x02\x01\x01': raise Failure('ELF_HEADER')
    fields=struct.unpack_from('<HHIQQQIHHHHHH',data,16)
    kind,machine,version,entry,phoff,shoff,flags,ehsize,phsize,phnum,shsize,shnum,shstr=fields
    if kind!=2 or machine!=62 or version!=1 or ehsize!=64 or phsize!=56 or not 1<=phnum<=64: raise Failure('ELF_TARGET')
    if phoff<64 or phoff+phnum*phsize>len(data): raise Failure('ELF_BOUNDS')
    if shnum and (shsize!=64 or shoff<64 or shoff+shnum*shsize>len(data) or shstr>=shnum):raise Failure('ELF_SECTIONS')
    stack=False;stack_count=0;entry_load=False;loads=[]
    for i in range(phnum):
        typ,flg,offset,vaddr,paddr,filesz,memsz,align=struct.unpack_from('<IIQQQQQQ',data,phoff+i*phsize)
        if typ in (2,3): raise Failure('DYNAMIC_ELF')
        if filesz>memsz or offset+filesz>len(data): raise Failure('ELF_SEGMENT')
        if typ==1 and flg&3==3: raise Failure('WRITABLE_EXECUTABLE')
        if typ==1:
            if vaddr+memsz>2**64 or offset+filesz>2**64:raise Failure('ELF_ADDRESS_OVERFLOW')
            if align>1 and (align&(align-1) or (vaddr-offset)%align):raise Failure('ELF_ALIGNMENT')
            if flg&~7 or any(vaddr<end and begin<vaddr+memsz for begin,end in loads):raise Failure('ELF_LOAD_LAYOUT')
            loads.append((vaddr,vaddr+memsz))
            if flg&1 and vaddr<=entry<vaddr+filesz:entry_load=True
        if typ==0x6474e551:
            stack=flg==6;stack_count+=1
    if not stack or stack_count!=1 or not entry_load: raise Failure('ELF_STACK_OR_ENTRY')

def console_trace(data, kinds, text, publications=None):
    if len(data)<32: raise Failure('MISSING_CONSOLE_DOCUMENT')
    magic,count,length,pubs=struct.unpack_from('<8sQQQ',data)
    expected_publications=len(kinds) if publications is None else publications
    if type(expected_publications) is not int or expected_publications<0:raise Failure('CONSOLE_ORACLE_PUBLICATIONS')
    if magic!=b'NEBOTRC1' or count!=len(kinds) or pubs!=expected_publications: raise Failure('CONSOLE_NODE_COUNT')
    if len(data)!=32+8*count+length: raise Failure('CONSOLE_TRACE_LENGTH')
    if list(struct.unpack_from('<'+'Q'*count,data,32))!=kinds: raise Failure('CONSOLE_NODE_TYPES')
    if data[32+8*count:]!=text: raise Failure('CONSOLE_TEXT')

def filesystem_snapshot(work, permitted_links=None):
    """Observe only this case's scratch tree; never follow symlink targets."""
    result={};total=0
    for path in sorted(work.rglob('*')):
        if path.is_symlink():
            name=path.relative_to(work).as_posix()
            target=os.readlink(path)
            if (permitted_links or {}).get(name)!=target:raise Failure('FILESYSTEM_SYMLINK')
            result[name]='SYMLINK:'+hashlib.sha256(target.encode()).hexdigest()
            continue
        if not path.is_file():continue
        size=path.stat().st_size;total+=size
        if size>4194304 or total>16777216 or len(result)>=128:raise Failure('FILESYSTEM_BUDGET')
        result[path.relative_to(work).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    return result

def filesystem_effects(before,after,expected):
    changes={name:after.get(name) for name in before.keys()|after.keys() if before.get(name)!=after.get(name)}
    oracle={name:None if value is None else hashlib.sha256(value).hexdigest() for name,value in expected.items()}
    if changes!=oracle:raise Failure('FILESYSTEM_ORACLE')
    return changes

def human_diagnostic(lines,code,diagnostic):
    if b'error '+code.encode()+b':' not in lines[0]:raise Failure('DIAGNOSTIC_CODE')
    expected=b'  note: '+diagnostic['note'].encode() if diagnostic.get('note') else None
    notes=[line for line in lines[1:] if not line.startswith(b'  related ')]
    if notes != ([expected] if expected else []):raise Failure('UNEXPECTED_DIAGNOSTIC')

def release_artifacts(work):
    """Remove only the two private build directories created for this case."""
    for name in ('root-0','root-1'):
        path=work/name
        if path.is_symlink():raise Failure('ARTIFACT_DIRECTORY_SYMLINK')
        if path.exists():shutil.rmtree(path)


def pipeline(source,work,expected,*,keep_artifacts=False,**options):
    # Retain identities in the proof, not hundreds of executable copies. The
    # few explicit artifact inspections release their pair immediately after.
    if any((work/name).exists() or (work/name).is_symlink() for name in ('root-0','root-1')):
        raise Failure('PREEXISTING_ARTIFACT_DIRECTORY')
    try:return _pipeline(source,work,expected,**options)
    finally:
        if not keep_artifacts:release_artifacts(work)


def _pipeline(source,work,expected,*,stdin=b'',kinds=None,text=b'',prompt=b'',units=(),stdout=b'',math_trace=False,hash_trace=False,observation=None,inputs=None,expected_files=None,stack_bytes=None,callable_trace=False,no_prelude=False,ownership_trace=False,publications=None,console_state_trace=False,scan_trace=False,input_symlinks=None,runtime_arguments=(),runtime_environment=None,runtime_loopback=False,mmap_failure_threshold=None):
    if (len(runtime_arguments)>16 or any(not isinstance(x,str) or '\0' in x for x in runtime_arguments)
        or sum(len(x.encode())+1 for x in runtime_arguments)>4096):raise Failure('ARGUMENT_BUDGET')
    if source.stat().st_size>1048576: raise Failure('SOURCE_BUDGET')
    compiler=ROOT/'build/bin/neboc'
    extra=[x for unit in units for x in ('--unit',unit)]
    if no_prelude:extra.append('--no-prelude')
    check=execute([compiler,'module-check' if units else 'check',source,*extra],work)
    if check!=(0,b'',b''): raise Failure('CHECK:'+repr(check))
    identities=[]
    for n in range(2):
        case=work/f'root-{n}';case.mkdir()
        assembly=case/'program.asm';binary=case/'program.elf'
        for mode,path in [('emit-asm',assembly),('link' if units else 'build',binary)]:
            result=execute([compiler,mode,source,*extra,'-o',path],case)
            if result!=(0,b'',b''): raise Failure(mode+':'+repr(result))
        elf(binary)
        for name,data in (inputs or {}).items():
            target=case/name
            if Path(name).is_absolute() or '..' in Path(name).parts or target.exists():raise Failure('INPUT_FILE_PATH')
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
        for name,target in (input_symlinks or {}).items():
            if (Path(name).is_absolute() or '..' in Path(name).parts or Path(target).is_absolute()
                or '..' in Path(target).parts or (case/name).exists() or target not in (inputs or {})):
                raise Failure('INPUT_SYMLINK_PROFILE')
            (case/name).parent.mkdir(parents=True,exist_ok=True)
            (case/name).symlink_to(target)
        before=filesystem_snapshot(case,input_symlinks)
        value=execute([binary,*runtime_arguments],case,stdin=stdin,trace=kinds is not None,math_trace=math_trace,hash_trace=hash_trace,runtime=True,stack_bytes=stack_bytes,callable_trace=callable_trace,ownership_trace=ownership_trace,console_state_trace=console_state_trace,scan_trace=scan_trace,runtime_environment=runtime_environment,runtime_loopback=runtime_loopback,mmap_failure_threshold=mmap_failure_threshold)
        effects=filesystem_effects(before,filesystem_snapshot(case,input_symlinks),expected_files or {})
        status=process_status(value[0])
        if status['signal'] is not None: raise Failure('RUNTIME_SIGNAL:'+str(status['signal']))
        if value[0]!=expected or value[2]: raise Failure('RUNTIME:'+repr(value))
        compared=value
        if observation is not None:
            # An explicitly nondeterministic public API must still pass a
            # complete domain oracle before its normalized behavior is joined.
            compared=(value[0],observation(value[1],n),value[2])
        elif kinds is None:
            if value[1]!=stdout: raise Failure('UNEXPECTED_STDOUT')
        else:
            if not value[1].startswith(prompt): raise Failure('SCAN_PROMPT')
            console_trace(value[1][len(prompt):],kinds,text,publications)
        identities.append((assembly.read_bytes(),binary.read_bytes(),compared))
    if identities[0]!=identities[1]: raise Failure('NONDETERMINISM')
    a,b,_=identities[0]
    return {'exit':expected,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'asm_sha256':hashlib.sha256(a).hexdigest(),'elf_sha256':hashlib.sha256(b).hexdigest(),
            'elf_bytes':len(b),'runtime_sha256':hashlib.sha256(value[1]+value[2]).hexdigest(),
            'independent_builds':2,'filesystem_effects':effects,
            'oracle_schema':1,'runtime_cwd':'PRIVATE_CASE_SCRATCH',
            'capabilities':{'network':'NATIVE_IPV4_LOOPBACK_ONLY' if runtime_loopback else 'DENIED_BY_SECCOMP','filesystem':'EXPLICIT_SCRATCH_EFFECT_ORACLE',
                            'console':'RETAINED_DOCUMENT' if kinds is not None else 'NO_DOCUMENT_OBSERVER'},
            'runtime_determinism':'DOMAIN_INVARIANTS' if observation else 'BYTE_IDENTICAL'}

def diagnostic_span(diagnostic, source_bytes, expected=None):
    primary=diagnostic.get('primary',{})
    start,end=primary.get('start'),primary.get('end')
    if (primary.get('sourceId')!=1 or type(start) is not int or type(end) is not int
            or not 0<=start<=end<=len(source_bytes)):
        raise Failure('DIAGNOSTIC_SPAN')
    # Offsets are UTF-8 byte boundaries, including a zero-width EOF location.
    try: source_bytes[:start].decode('utf-8');source_bytes[:end].decode('utf-8')
    except UnicodeDecodeError as error: raise Failure('DIAGNOSTIC_SPAN_UTF8') from error
    if expected is not None and (start,end)!=expected:raise Failure('DIAGNOSTIC_CAUSAL_SPAN')

def reject(source,work,code,*,span=None):
    """Never execute a negative program; require stable structured diagnostics."""
    observations=[]
    for mode in ('check','emit-asm','build'):
        target=work/(mode+'.artifact')
        argv=[ROOT/'build/bin/neboc',mode,source]
        if mode=='check': argv+=['--message-format','json-lines','--color','never']
        if mode!='check': argv += ['-o',target]
        rc,out,err=execute(argv,work)
        if rc!=1 or target.exists(): raise Failure('NEGATIVE_ACCEPTANCE_OR_ARTIFACT')
        lines=(out+err).splitlines()
        if not lines or (mode=='check' and len(lines)!=1): raise Failure('DIAGNOSTIC_CARDINALITY')
        if mode!='check':
            human_diagnostic(lines,code,observations[0])
            continue
        try: diagnostic=json.loads(lines[0])
        except (ValueError,TypeError) as error: raise Failure('DIAGNOSTIC_JSON') from error
        if diagnostic.get('code')!=code: raise Failure('DIAGNOSTIC_CODE:'+repr(diagnostic))
        diagnostic_span(diagnostic,source.read_bytes(),span)
        observations.append(diagnostic)
    rc,out,err=execute([ROOT/'build/bin/neboc','check',source,'--message-format','json-lines'],work)
    if rc!=1 or json.loads(out+err)!=observations[0]: raise Failure('DIAGNOSTIC_NONDETERMINISM')
    return {'stages':3,'code':code}
