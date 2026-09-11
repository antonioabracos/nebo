"""Independent native, archive and filesystem observations for the public SDK."""
import hashlib,json,os,subprocess,sys,tempfile,signal,struct,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT),str(ROOT/'tests/rf204/G170'),str(ROOT/'tests/public')]
from compiler.sdk import supply_chain as chain,sdk_builder as sdk,package_manager as pkg
from harness import pipeline,Failure,elf,reject,_limits
from sandbox import restrict
ROWS=[];VALUES=[41,59,83,107,131,157,181,211]
EXAMPLES=[f'examples/rf204/G198/RF204-G198-S{i:02}.no' for i in range(1,9)]+['examples/rf204/G198/dependencies/core.no','examples/rf204/G198/dependencies/util.no']
WORKSPACE='examples/rf204/G198/package/workspace.json'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def note(name,category,subgroup,**facts):
 assert name not in {r['id'] for r in ROWS},name
 ROWS.append(dict(id=name,category=category,subgroup=subgroup,status='PASS',**facts));print(name,flush=True)
def denied(name,fn,code,subgroup=7,category='negative'):
 try:fn()
 except (ValueError,OSError,KeyError,TypeError) as e:assert code in str(e),(name,str(e))
 else:raise AssertionError('KNOWN_BAD_ACCEPTED '+name)
 note(name,category,subgroup,diagnostic=code)
def process(args,root,expected=0,variant=0,timeout=240,allowed=None):
 root=Path(root);env=dict(PATH='/usr/bin:/bin',HOME=str(root),TMPDIR=str(root),LC_ALL='C' if not variant else 'C.utf8',LANG='C',TZ='UTC' if not variant else 'Pacific/Honolulu',SOURCE_DATE_EPOCH='0' if not variant else '123456789',PYTHONDONTWRITEBYTECODE='1')
 def limits():
  # Product archives include the existing offline docs tar (>64 MiB).
  # Raise only this child's finite file bound to the archive owner's budget.
  import p01_security
  p01_security.MAX_FILE_BYTES=chain.MAX_ARCHIVE
  os.umask(0o022 if not variant else 0o077);_limits(180,False);restrict(allowed or (root,))
 with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
  p=subprocess.Popen([str(a) for a in args],cwd=root,env=env,preexec_fn=limits,stdout=out,stderr=err,stdin=subprocess.DEVNULL,start_new_session=True)
  try:p.wait(timeout=timeout)
  finally:
   try:os.killpg(p.pid,signal.SIGKILL)
   except ProcessLookupError:pass
   p.wait()
  out.seek(0);err.seek(0);a=out.read(4*1024*1024+1);b=err.read(4*1024*1024+1)
  assert len(a)+len(b)<4*1024*1024
  assert p.returncode==expected,(args,p.returncode,a[-2000:],b[-4000:])
  return a,b

def independent(path,expected_profile):
 # Independent tarfile walk, hashlib and POSIX metadata oracle, no owner verifier.
 with tarfile.open(path,'r:') as tar:
  members=tar.getmembers();names=[m.name for m in members]
  assert len(names)==len(set(names))
  assert all(m.isfile() and not (m.mtime or m.uid or m.gid or m.uname or m.gname) and m.mode in (0o644,0o755) for m in members)
  data={m.name:tar.extractfile(m).read() for m in members}
  s=json.loads(data['SBOM.json']);p=json.loads(data['PROVENANCE.json'])
  assert s['profile']==expected_profile and sha(data['PROVENANCE.json'])==s['provenance_sha256']
  assert set(data)=={'SBOM.json','PROVENANCE.json'}|{'payload/'+r['path'] for r in s['files']}
  for r in s['files']:
   raw=data['payload/'+r['path']];assert sha(raw)==r['sha256'] and len(raw)==r['size']
   assert tar.getmember('payload/'+r['path']).mode==int(r['mode'],8)
  assert sha(chain.canonical(p['inputs']))==p['input_digest']
  assert s['licenses']['external_legal_gate']=='RELEASE-LEGAL:PENDING_EXTERNAL'
  assert not p['private_key_read'] and not p['network']
 return s,p
