"""Verified native-token migrations with bounded, recoverable local publication.

The native lexer owns spelling, module/.ni owners own project identities, and
identical native executables prove the admitted mechanical transformation.
Preview never publishes. Multi-file apply has a durable undo journal; readers
must not mistake a sequence of atomic file replacements for snapshot isolation.
"""
from __future__ import annotations
import argparse, base64, contextlib, dataclasses, fcntl, hashlib, json, os, secrets, stat, subprocess, sys, tempfile
from pathlib import Path, PurePosixPath
from compiler.sdk.token_tooling import TokenModel, LITERAL_KINDS
from compiler.sdk.operator_tooling import OperatorRegistry
from compiler.sdk.prelude import PreludeMigration, PreludeInterface, PreludeProfile, TARGET

ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / 'build/bin/neboc'
MAX_FILE = 1 << 20
MAX_TOTAL = 4 << 20
MAX_FILES = 32
MAX_JOURNAL = 16 << 20
class MigrationError(ValueError):
    def __init__(self, code, detail=''):
        self.code = 'NEBO_MIG_' + code
        super().__init__(detail or code)
def require(ok, code):
    if not ok: raise MigrationError(code)
def sha(data): return hashlib.sha256(data).hexdigest()
def canonical(obj): return json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode()+b'\n'
def unique(pairs):
    d={}
    for k,v in pairs:
        require(k not in d, 'DUPLICATE_FIELD'); d[k]=v
    return d
def decode(data): return json.loads(data, object_pairs_hook=unique)
def relative(name):
    require(isinstance(name,str) and name and not name.startswith('/') and '\x00' not in name, 'PATH')
    p=PurePosixPath(name)
    require(str(p)==name and all(x not in ('.','..') for x in p.parts), 'PATH')
    return p.parts

@contextlib.contextmanager
def parent_fd(root, name):
    parts=relative(name)
    fd=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
    try:
        for part in parts[:-1]:
            nxt=os.open(part,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW,dir_fd=fd)
            os.close(fd);fd=nxt
        yield fd,parts[-1]
    finally:os.close(fd)
def read_at(fd,name,limit=MAX_FILE):
    child=os.open(name,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK,dir_fd=fd)
    try:
        info=os.fstat(child)
        require(stat.S_ISREG(info.st_mode) and info.st_nlink==1 and info.st_size<=limit,'FILE_BOUND_OR_LINK')
        with os.fdopen(child,'rb',closefd=False) as f:data=f.read(limit+1)
        require(len(data)==info.st_size and len(data)<=limit,'FILE_CHANGED')
        return data,info
    finally:os.close(child)
def read(root,name,limit=MAX_FILE):
    with parent_fd(root,name) as (fd,leaf):return read_at(fd,leaf,limit)
def atomic(fd,name,data,mode,*,exclusive=False):
    tmp='.nebo-migrate-'+secrets.token_hex(12)
    child=os.open(tmp,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,mode,dir_fd=fd)
    try:
        with os.fdopen(child,'wb') as f:
            os.fchmod(f.fileno(),mode); f.write(data); f.flush(); os.fsync(f.fileno())
        if exclusive:
            os.link(tmp,name,src_dir_fd=fd,dst_dir_fd=fd,follow_symlinks=False)
        else:os.replace(tmp,name,src_dir_fd=fd,dst_dir_fd=fd)
        os.fsync(fd)
    finally:
        try:os.unlink(tmp,dir_fd=fd)
        except FileNotFoundError:pass

def native(arguments,code):
    # Bounded output files prevent pipe deadlocks and unbounded capture.
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        p=subprocess.run([str(COMPILER),*map(str,arguments)],cwd=ROOT,stdin=subprocess.DEVNULL,
            stdout=out,stderr=err,timeout=35,env={'PATH':'/usr/bin:/bin','LC_ALL':'C','PYTHONDONTWRITEBYTECODE':'1'})
        require(out.tell()+err.tell()<=MAX_FILE,'COMPILER_OUTPUT_BOUND')
        out.seek(0);err.seek(0);data=out.read();diagnostic=err.read()
    if p.returncode or diagnostic:raise MigrationError(code,diagnostic.decode(errors='replace')[:2048])
    return data

@dataclasses.dataclass(frozen=True)
class Edit:
    rule_id:str; symbol_id:str; start:int; end:int; before:str; after:str
@dataclasses.dataclass(frozen=True)
class Conflict:
    rule_id:str; symbol_id:str; start:int; end:int; legacy_form:str; reason:str
    disposition:str='MANUAL_REVIEW'

def tokens(data):
    m=TokenModel.scan(data)
    require(not m.errors and not m.status,'LEXER')
    return [t for t in m.tokens if t.kind!=1]
# Read-only compatibility projection for provenance consumers; no synthetic APIs.
RULES = {'NEBO-MIG-'+e['id']:(e['lexeme'],e['canonical_ascii'],e['id'])
         for e in OperatorRegistry().entries if e['cls']=='UNICODE_ALIAS'}

def plan_text_with_conflicts(source):
    data=source.encode(); registry=OperatorRegistry(); result=[]
    aliases={e['lexeme']:e for e in registry.entries if e['cls']=='UNICODE_ALIAS'}
    for t in tokens(data):
        if t.kind in LITERAL_KINDS:continue
        spelling=data[t.start:t.end].decode(); e=aliases.get(spelling)
        if e is None:continue
        replacement=e['canonical_ascii']; other=tokens(replacement.encode())
        require(len(other)==1 and other[0].kind==t.kind,'ALIAS_TOKEN_IDENTITY')
        result.append(Edit('NEBO-MIG-'+e['id'],e['id'],t.start,t.end,spelling,replacement))
    return result,[]
def plan_text(source):return plan_text_with_conflicts(source)[0]
def render(source,edits):
    data=source.encode(); out=bytearray(); cursor=0
    for e in sorted(edits,key=lambda e:e.start):
        require(type(e.start) is int and type(e.end) is int and cursor<=e.start<=e.end<=len(data),'EDIT_SPAN')
        require(data[e.start:e.end]==e.before.encode(),'EDIT_STALE')
        out+=data[cursor:e.start]+e.after.encode();cursor=e.end
    return (out+data[cursor:]).decode()
def one_edit(before,after,rule,symbol):
    """Smallest UTF-8 span; no formatting outside the owner-produced edit."""
    if before==after:return []
    a,b=before.decode(),after.decode();left=0;right=0
    while left<min(len(a),len(b)) and a[left]==b[left]:left+=1
    while right<min(len(a)-left,len(b)-left) and a[-right-1]==b[-right-1]:right+=1
    end=len(a)-right; b_end=len(b)-right
    return [Edit(rule,symbol,len(a[:left].encode()),len(a[:end].encode()),a[left:end],b[left:b_end])]

def verification(base,names,profile,workspace=None):
    from compiler.migration.project import graph, workspace_check
    if workspace: workspace_check(base,workspace)
    models={n:tokens((base/n).read_bytes()) for n in names}
    modules=all(ts and (base/n).read_bytes()[ts[0].start:ts[0].end]==b'module' for n,ts in models.items())
    infos=graph(base,names) if modules else {}
    entries=[n for n in names if int(infos[n]['module.startRefs'])] if modules else names
    require(entries and (not modules or len(entries)==1),'ENTRY')
    proofs={}
    with tempfile.TemporaryDirectory(prefix='nebo-migrate-compile-') as directory:
        out=Path(directory)
        for i,name in enumerate(entries):
            args=[base/name]
            if modules:
                for unit in names:
                    if unit!=name:args+=['--unit',base/unit]
            if profile=='no-prelude':args+=['--no-prelude']
            native(['check',*args],'VERIFY_SOURCE')
            asm=out/(str(i)+'.asm');elf=out/(str(i)+'.elf')
            native(['emit-asm',*args,'-o',asm],'VERIFY_EMIT')
            native(['build',*args,'-o',elf],'VERIFY_BUILD')
            payload=elf.read_bytes();require(payload[:4]==b'\x7fELF','VERIFY_ELF')
            proofs[name]={'elf_sha256':sha(payload),'asm_sha256':sha(asm.read_bytes())}
    return proofs

def plan_files(paths,*,root=None,profile='keep',from_profile='default',rename=None,module_rename=None,
               workspace=None,package_rename=None,allow_api_change=False):
    require(profile in ('keep','default','no-prelude') and from_profile in ('default','no-prelude'),'PROFILE')
    require(not (rename and module_rename),'RENAME_COMPOSITION')
    paths=list(map(Path,paths))
    if root is None:
        require(paths,'INPUTS');root=Path(os.path.commonpath([str(p.absolute().parent) for p in paths]))
    root=Path(os.path.abspath(root));require(root.resolve()==root,'PATH')
    from compiler.migration.project import project_inputs, project_edits
    if workspace:
        require(not paths,'WORKSPACE_OR_PATHS')
        names,metadata=project_inputs(root,workspace)
    else:
        names=[p.absolute().relative_to(root).as_posix() for p in paths];metadata=[]
    require(1<=len(names)<=MAX_FILES and len(names)==len(set(names)),'INPUTS')
    allnames=sorted([*names,*metadata]);require(len(allnames)==len(set(allnames)),'INPUTS')
    names=sorted(names);original={};modes={};identities=set()
    for n in allnames:
        data,st=read(root,n);identity=(st.st_dev,st.st_ino)
        require(identity not in identities,'DUPLICATE_INPUT');identities.add(identity)
        require(stat.S_IMODE(st.st_mode)<=0o777,'FILE_MODE')
        data.decode('utf-8');original[n]=data;modes[n]=stat.S_IMODE(st.st_mode)
    require(sum(map(len,original.values()))<=MAX_TOTAL,'TOTAL_BOUND')
    settings=dict(profile=profile,from_profile=from_profile,rename=rename,module_rename=module_rename,
        workspace=workspace,package_rename=package_rename,allow_api_change=allow_api_change)
    edits={n:[] for n in allnames};candidate=dict(original);identities_report=[]
    with tempfile.TemporaryDirectory(prefix='nebo-migrate-plan-') as raw:
        stage=Path(raw)
        for n,d in original.items():(stage/n).parent.mkdir(parents=True,exist_ok=True);(stage/n).write_bytes(d)
        input_profile=from_profile
        try:before_proof=verification(stage,names,from_profile,workspace)
        except MigrationError as error:
            if error.code!='NEBO_MIG_VERIFY_SOURCE' or profile=='keep' or profile==from_profile:raise
            # Idempotent profile migration: the target owner must request zero
            # profile edits before a program already under that profile is admitted.
            current=PreludeMigration.plan('1','1',[stage/n for n in names],profile=profile)
            if any(r.collisions or r.before!=r.after for r in current):raise error
            before_proof=verification(stage,names,profile,workspace);input_profile=profile
        if rename or module_rename or package_rename:
            require(allow_api_change,'API_CHANGE_REQUIRES_EXPLICIT_FLAG')
            edits,identities_report=project_edits(stage,names,metadata,rename,module_rename,package_rename,workspace)
            for n in allnames:candidate[n]=render(original[n].decode(),edits[n]).encode()
        else:
            for n in names:
                edits[n]=plan_text(original[n].decode());candidate[n]=render(original[n].decode(),edits[n]).encode()
        # Prelude edits compose after exact aliases, preserving source byte spans.
        for n,d in candidate.items():(stage/n).write_bytes(d)
        if profile!='keep':
            interface=PreludeInterface.load(PreludeProfile.forEdition('1'),TARGET)
            identities_report.extend({'kind':'prelude','symbol_id':r['symbolId'],'name':r['name']} for r in interface.symbol_records)
            rows=PreludeMigration.plan('1','1',[stage/n for n in names],profile=profile)
            require(not any(r.collisions for r in rows),'PRELUDE_COLLISION')
            for n,row in zip(names,rows):
                candidate[n]=row.after
                edits[n]=one_edit(original[n],row.after,'NEBO-MIG-PRELUDE-001','std.prelude:1')
                (stage/n).write_bytes(row.after)
        after_proof=verification(stage,names,from_profile if profile=='keep' else profile,workspace)
        require(before_proof.keys()==after_proof.keys(),'ENTRY_DRIFT')
        require(all(before_proof[n]['elf_sha256']==after_proof[n]['elf_sha256'] for n in before_proof),'SEMANTIC_DRIFT')
    files=[dict(path=n,role='source' if n in names else 'metadata',sha256_before=sha(original[n]),
                sha256_after=sha(candidate[n]),mode=modes[n],edits=[dataclasses.asdict(e) for e in edits[n]],
                candidate=candidate[n].decode()) for n in allnames]
    body=dict(schema=2,root=str(root),settings=settings,files=files,identities=identities_report,
        verification={'before':before_proof,'after':after_proof,'binary_equivalent':True,'executed':False,'input_profile':input_profile,'output_profile':from_profile if profile=='keep' else profile})
    body['plan_id']=sha(canonical(body));return body

def recompute(plan):
    require(type(plan) is dict and set(plan)=={'schema','root','settings','files','identities','verification','plan_id'} and plan.get('schema')==2,'PLAN_SCHEMA')
    require(type(plan['files']) is list and 1<=len(plan['files'])<=MAX_FILES+4,'PLAN_SCHEMA')
    body={k:v for k,v in plan.items() if k!='plan_id'}
    require(plan.get('plan_id')==sha(canonical(body)),'PLAN_DIGEST')
    names=[r['path'] for r in plan['files'] if r['role']=='source'];root=Path(plan['root'])
    for r in plan['files']:
        data,st=read(root,r['path']);require(sha(data)==r['sha256_before'] and stat.S_IMODE(st.st_mode)==r['mode'],'PLAN_STALE')
    current=plan_files([] if plan['settings']['workspace'] else [root/n for n in names],root=root,**plan['settings'])
    require(current==plan,'PLAN_FORGED_OR_STALE')
    return current

def apply_plan(plan,journal,*,fail_after=None):
    require(type(plan) is dict and isinstance(plan.get('root'),str),'PLAN_SCHEMA')
    root=Path(plan['root']);journal=Path(journal).absolute();name=journal.relative_to(root).as_posix();relative(name)
    require(name not in {r['path'] for r in plan['files']},'JOURNAL_INPUT_COLLISION')
    with contextlib.ExitStack() as stack:
        lock=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
        stack.callback(os.close,lock);fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        plan=recompute(plan)
        changed=[r for r in plan['files'] if r['sha256_before']!=r['sha256_after']]
        if not changed:return 0
        jfd,jleaf=stack.enter_context(parent_fd(root,name))
        try:os.stat(jleaf,dir_fd=jfd,follow_symlinks=False)
        except FileNotFoundError:pass
        else:raise MigrationError('JOURNAL_EXISTS')
        handles={};rows=[]
        for r in plan['files']:
            fd,leaf=stack.enter_context(parent_fd(root,r['path']));data,st=read_at(fd,leaf)
            require(sha(data)==r['sha256_before'] and stat.S_IMODE(st.st_mode)==r['mode'],'PLAN_STALE')
            handles[r['path']]=(fd,leaf)
            if r in changed:rows.append(dict(path=r['path'],mode=r['mode'],before_sha256=sha(data),after_sha256=r['sha256_after'],
                before=base64.b64encode(data).decode(),after=base64.b64encode(r['candidate'].encode()).decode()))
        record={'schema':2,'state':'PREPARED','files':rows}
        atomic(jfd,jleaf,canonical(record),0o600,exclusive=True)
        published=[]
        try:
            for r in changed:
                for other in plan['files']:
                    expected=other['sha256_after'] if other['path'] in published else other['sha256_before']
                    fd,leaf=handles[other['path']];data,st=read_at(fd,leaf)
                    require(sha(data)==expected and stat.S_IMODE(st.st_mode)==other['mode'],'CONCURRENT_EDIT')
                fd,leaf=handles[r['path']];atomic(fd,leaf,r['candidate'].encode(),r['mode']);published.append(r['path'])
                if fail_after==len(published):raise OSError('injected publication failure')
            record['state']='COMMITTED';atomic(jfd,jleaf,canonical(record),0o600)
        except BaseException:
            # Keep PREPARED journal if rollback itself fails or a writer changed an output.
            for r in rows:
                fd,leaf=handles[r['path']];data,_=read_at(fd,leaf)
                require(sha(data) in (r['before_sha256'],r['after_sha256']),'RECOVERY_CONFLICT')
            for r in reversed(rows):
                atomic(*handles[r['path']],base64.b64decode(r['before']),r['mode'])
            os.unlink(jleaf,dir_fd=jfd);os.fsync(jfd);raise
    return len(changed)

def rollback(journal,*,root=None):
    journal=Path(journal).absolute();root=Path(root).absolute() if root else journal.parent
    name=journal.relative_to(root).as_posix()
    with contextlib.ExitStack() as stack:
        lock=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW);stack.callback(os.close,lock)
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        jfd,jleaf=stack.enter_context(parent_fd(root,name));raw,_=read_at(jfd,jleaf,MAX_JOURNAL)
        record=decode(raw);require(type(record) is dict and set(record)=={'schema','state','files'} and type(record['schema']) is int and record['schema']==2 and record['state'] in ('PREPARED','COMMITTED'),'JOURNAL_SCHEMA')
        rows=record['files'];require(type(rows) is list and 1<=len(rows)<=MAX_FILES+4,'JOURNAL_BOUND')
        paths=set();prepared=[];total=0
        for r in rows:
            require(type(r) is dict and set(r)=={'path','mode','before_sha256','after_sha256','before','after'},'JOURNAL_SCHEMA')
            require(all(isinstance(r[k],str) for k in ('path','before','after','before_sha256','after_sha256')),'JOURNAL_SCHEMA')
            relative(r['path']);require(r['path'] not in paths and r['path']!=name,'JOURNAL_PATH');paths.add(r['path'])
            require(type(r['mode']) is int and 0<=r['mode']<=0o777,'JOURNAL_MODE')
            before=base64.b64decode(r['before'],validate=True);after=base64.b64decode(r['after'],validate=True)
            total+=len(before)+len(after)
            require(max(len(before),len(after))<=MAX_FILE and total<=2*MAX_TOTAL,'JOURNAL_BOUND')
            require(sha(before)==r['before_sha256'] and sha(after)==r['after_sha256'],'JOURNAL_DIGEST')
            fd,leaf=stack.enter_context(parent_fd(root,r['path']));data,st=read_at(fd,leaf)
            require(data in (before,after) and stat.S_IMODE(st.st_mode)==r['mode'],'ROLLBACK_STALE')
            prepared.append((fd,leaf,before,r['mode']))
        for fd,leaf,before,mode in prepared:atomic(fd,leaf,before,mode)
        os.unlink(jleaf,dir_fd=jfd);os.fsync(jfd)
    return len(prepared)

def main(argv=None):
    parser=argparse.ArgumentParser(prog='neboc migrate',description='Preview verified source edits; --apply publishes a recoverable local transaction.')
    parser.add_argument('paths',nargs='*',type=Path);parser.add_argument('--root',type=Path,default=Path.cwd())
    parser.add_argument('--profile',choices=('keep','default','no-prelude'),default='keep')
    parser.add_argument('--from-profile',choices=('default','no-prelude'),default='default')
    parser.add_argument('--rename',help='native ModuleId:SymbolId:newName (decimal IDs)')
    parser.add_argument('--rename-module');parser.add_argument('--workspace');parser.add_argument('--rename-package')
    parser.add_argument('--allow-api-change',action='store_true');parser.add_argument('--journal',default='.nebo-migrate-journal.json')
    mode=parser.add_mutually_exclusive_group();mode.add_argument('--apply',action='store_true');mode.add_argument('--rollback',action='store_true')
    args=parser.parse_args(argv)
    try:
        require(not Path(args.journal).is_absolute(),'PATH');relative(args.journal)
        journal=args.root/args.journal
        if args.rollback:
            require(not args.paths and not args.workspace and not args.rename and not args.rename_module and not args.rename_package and args.profile=='keep','ROLLBACK_OPTIONS')
            print(canonical(dict(schema=2,mode='rollback',restored=rollback(journal,root=args.root))).decode(),end='');return 0
        paths=[p if p.is_absolute() else args.root/p for p in args.paths]
        plan=plan_files(paths,root=args.root,profile=args.profile,from_profile=args.from_profile,rename=args.rename,
            module_rename=args.rename_module,workspace=args.workspace,package_rename=args.rename_package,allow_api_change=args.allow_api_change)
        applied=apply_plan(plan,journal) if args.apply else 0
        print(canonical(dict(schema=2,mode='apply' if args.apply else 'preview',applied=applied,plan=plan)).decode(),end='');return 0
    except (ValueError,OSError,RuntimeError,subprocess.SubprocessError) as e:
        print(canonical(dict(code=getattr(e,'code','NEBO_MIG_INPUT_OR_OWNER'),phase='migration',message=str(e)[:2048])).decode(),end='',file=sys.stderr);return 2
if __name__=='__main__':raise SystemExit(main())
