"""Offline source snapshots, per-artifact inventories and pinned verification.

Integrity pins come from the caller, never from the artifact being admitted.
A local unsigned attestation makes no claim of publisher authentication.
"""
from __future__ import annotations
from contextlib import contextmanager
import argparse, hashlib, io, json, os, re, shutil, stat, subprocess, sys, tarfile, tempfile
from pathlib import Path
from compiler.sdk import sdk_builder as sdk, install_io as fs, package_manager as pkg

SCHEMA='NEBO-SUPPLY-CHAIN-v1'
PROFILES=('source','sdk','docs','tooling','package')
PROVENANCE='SOURCE-PROVENANCE.json'
MAX_ARCHIVE=sdk.MAX_BYTES+sdk.MAX_FILES*2048
LICENSES=('LICENSE','sdk/nebo-1.0/licenses/NeboConsoleMonoAtlas-OFL-1.1.md',
          'sdk/nebo-1.0/licenses/NeboConsoleMonoAtlas-PROVENANCE.md',
          'third_party/fonts/adobe-source-code-pro/PROVENANCE.md')

def require(ok, code):
    if not ok: raise ValueError('NEBO-SUPPLY-'+code)
def sha(raw): return hashlib.sha256(raw).hexdigest()
def hex_digest(value): return isinstance(value,str) and re.fullmatch('[0-9a-f]{64}',value) is not None
def canonical(value): return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=False,allow_nan=False)+'\n').encode()
def decode(raw): return fs.decode(raw)
@contextmanager
def directory(root):
    fd=pkg.open_directory(Path(root).absolute())
    try: yield fd
    finally: os.close(fd)
def read(root,name,limit=sdk.MAX_FILE):
    with directory(root) as fd: return fs.read(fd,name,limit)
def write(root,name,raw,mode=0o644):
    with directory(root) as fd: fs.write(fd,name,raw,mode)
def inventory(root):
    with directory(root) as fd:
        names=fs.inventory(fd);require(not any(n.endswith('/') for n in names),'EMPTY_DIRECTORY')
        rows=[]
        for name in names:
            raw,mode=fs.read(fd,name)
            require(mode in (0o644,0o755),'MODE')
            sdk.scan(raw)
            rows.append(dict(path=name,size=len(raw),sha256=sha(raw),mode=format(mode,'04o')))
    fs.rows(rows)
    return sorted(rows,key=lambda r:r['path'])

def command(args,root):
    p=subprocess.run(args,cwd=root,stdin=subprocess.DEVNULL,capture_output=True,timeout=30,check=True)
    require(len(p.stdout)+len(p.stderr)<=16*1024*1024,'PROCESS_OUTPUT')
    return p.stdout

def source_names(repo,examples,package_workspace=None):
    require(type(examples) is list and 1<=len(examples)<=64 and len(set(examples))==len(examples),'EXAMPLES')
    names=set(sdk.source_inputs(repo))|set(LICENSES)
    for profile in sdk.PROFILES:
        for _,path,_,_ in sdk.component_sources(repo,repo/'build/bin/neboc',profile):
            name=path.relative_to(repo).as_posix()
            if not name.startswith('build/'): names.add(name)
    for name in examples:
        sdk.safe_relative(name);require(name.endswith('.no'),'EXAMPLE_SUFFIX');names.add(name)
    if package_workspace is not None:
        sdk.safe_relative(package_workspace)
        ws=repo/package_workspace
        _,_,manifests,_=pkg.workspace(ws)
        descriptor=decode(read(ws.parent,ws.name)[0]);names.add(package_workspace)
        for member in descriptor['members']:
            base=ws.parent/member
            m=pkg.manifest(decode(read(base,pkg.MANIFEST)[0]))
            names.add((base/pkg.MANIFEST).relative_to(repo).as_posix())
            names.update((base/mod['source']).relative_to(repo).as_posix() for mod in m['modules'])
    for name in names:
        sdk.safe_relative(name)
        require(not any(p.startswith('.') for p in Path(name).parts) and
                not name.startswith(('build/','release/')) and not name.endswith(('.o','.pyc','.pem','.key')),'EXCLUDED_INPUT')
    require(len(names)<=sdk.MAX_FILES,'INPUT_BUDGET')
    return sorted(names)

def tools():
    """Fingerprint the explicit host tools, Python library and rasterizer closure.

    These host dependencies are inventoried, not redistributed or bootstrapped.
    The kernel and CPU are the documented external execution platform.
    """
    import sysconfig
    from PIL import ImageFont
    import PIL
    executables=('nasm','ld','python3','ninja','sh','mkdir','dirname','objcopy','openssl')
    paths=set(); records=[]
    for name in executables:
        path=Path(shutil.which(name) or '/missing').resolve();require(path.is_file(),'MISSING_TOOL')
        paths.add(path)
        if name not in ('sh','mkdir'):
            output=command([str(path),'version' if name=='openssl' else '--version'],Path.cwd()).decode().splitlines()[0]
        else: output='host executable pinned by SHA-256'
        records.append(dict(name=name,version=output,sha256=sha(path.read_bytes())))
    lib=Path(sysconfig.get_path('stdlib'));pil=Path(PIL.__file__).parent
    for root in (lib,pil):
        for base,dirs,files in os.walk(root):
            dirs[:]=sorted(d for d in dirs if d not in {'__pycache__','site-packages','dist-packages','test','tests'})
            for name in sorted(files):
                p=Path(base)/name
                # Site customization outside /usr is denied in the clean room.
                if p.suffix in ('.py','.so') and p.resolve().is_relative_to('/usr'): paths.add(p.resolve())
    # Only locally installed ELF tools/extensions enter ldd, never supplied artifacts.
    for p in list(paths):
        if p.suffix=='.so' or p in {Path(shutil.which(n)).resolve() for n in executables}:
            out=subprocess.run(['/usr/bin/ldd',str(p)],capture_output=True,timeout=10)
            require(out.returncode in (0,1),'TOOL_DEPENDENCIES')
            for name in re.findall(rb'(?:=>\s+|^\s*)(/[^\s()]+)',out.stdout,re.M):
                paths.add(Path(os.fsdecode(name)).resolve())
    require(len(paths)<4096,'TOOL_BUDGET')
    files=[dict(path=str(p),sha256=sha(p.read_bytes()),size=p.stat().st_size) for p in sorted(paths,key=str)]
    return dict(executables=records,files=files,pillow=PIL.__version__,freetype=ImageFont.core.freetype2_version,
                target=sdk.TARGET,bootstrap='EXTERNAL_HOST_TOOLCHAIN',network=False)

def snapshot(repo,output,examples,environment=None,package_workspace=None):
    repo=Path(repo).absolute();output=Path(output).absolute()
    names=source_names(repo,examples,package_workspace)
    require(not any((repo/name).is_relative_to(output) for name in names),'OUTPUT_OVERLAP')
    require(not output.exists() and not output.is_symlink(),'DESTINATION_EXISTS')
    # Pin the Git baseline and explicitly describe any working-tree overlay.
    commit=command(['git','rev-parse','HEAD'],repo).decode().strip()
    tree=command(['git','rev-parse','HEAD^{tree}'],repo).decode().strip()
    entries=command(['git','ls-tree','-rz','HEAD','--',*names],repo).split(b'\0')
    baseline={}
    for item in entries:
        if item:
            meta,name=item.split(b'\t',1);fields=meta.split()
            baseline[os.fsdecode(name)]=(fields[2].decode(),fields[0].decode())
    sdk.prepare_parent(output)
    with tempfile.TemporaryDirectory(prefix='.nebo-supply-',dir=output.parent) as tmp:
        stage=Path(tmp)/'stage';stage.mkdir();records=[]
        with directory(repo) as fd:
            for name in names:
                raw,mode=fs.read(fd,name);sdk.scan(raw,(repo,output,stage))
                mode=0o755 if mode&0o111 else 0o644
                write(stage,name,raw,mode)
                blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
                original_blob,original_mode=baseline.get(name,(None,None))
                records.append(dict(path=name,size=len(raw),mode=format(mode,'04o'),sha256=sha(raw),
                                    git_baseline_blob=original_blob,git_baseline_mode=original_mode,
                                    matches_baseline=original_blob==blob and original_mode==('100755' if mode==0o755 else '100644'),
                                    role='example' if name in examples else 'generated-asset' if
                                    ('generated' in name or name.endswith('_atlas.inc')) else 'source-or-package-input'))
        provenance=dict(schema=SCHEMA,source_commit=commit,source_tree=tree,inputs=records,
            input_digest=sha(canonical(records)),examples=examples,toolchain=environment or tools(),package_workspace=package_workspace,
            workspace_overlay=any(not r['matches_baseline'] for r in records),
            trust='UNSIGNED_LOCAL_INTEGRITY',network=False,private_key_read=False)
        write(stage,PROVENANCE,canonical(provenance));validate_provenance(provenance)
        require(command(['git','rev-parse','HEAD'],repo).decode().strip()==commit,'BASELINE_CHANGED')
        # Recheck every admitted input before publication; fail closed on edits.
        with directory(repo) as fd:
            for row in records:
                raw,mode=fs.read(fd,row['path'])
                require(sha(raw)==row['sha256'] and ('0755' if mode&0o111 else '0644')==row['mode'],'SOURCE_CHANGED')
        pkg.publish(stage,output)
    return provenance

def validate_provenance(p):
    require(type(p) is dict and set(p)=={'schema','source_commit','source_tree','inputs','input_digest','examples','toolchain','workspace_overlay','trust','network','private_key_read','package_workspace'},'PROVENANCE_FIELDS')
    require(p['schema']==SCHEMA and p['trust']=='UNSIGNED_LOCAL_INTEGRITY' and p['network'] is False and p['private_key_read'] is False,'PROVENANCE_POLICY')
    require(all(isinstance(p[k],str) and re.fullmatch('[0-9a-f]{40}',p[k]) for k in ('source_commit','source_tree')),'GIT_IDENTITY')
    require(type(p['inputs']) is list and 1<=len(p['inputs'])<=sdk.MAX_FILES,'INPUT_BUDGET')
    fields={'path','size','mode','sha256','git_baseline_blob','git_baseline_mode','matches_baseline','role'}
    require(all(type(r) is dict and set(r)==fields for r in p['inputs']),'INPUT_SCHEMA')
    fs.rows([{k:r[k] for k in ('path','size','mode','sha256')} for r in p['inputs']])
    require([r['path'] for r in p['inputs']]==sorted({r['path'] for r in p['inputs']}),'INPUT_ORDER')
    require(p['input_digest']==sha(canonical(p['inputs'])),'INPUT_DIGEST')
    require(p['package_workspace'] is None or isinstance(p['package_workspace'],str) and
            p['package_workspace'] in {r['path'] for r in p['inputs']},'PACKAGE_WORKSPACE')
    require(type(p['examples']) is list and 1<=len(p['examples'])<=64 and len(set(p['examples']))==len(p['examples']) and
            set(p['examples'])=={r['path'] for r in p['inputs'] if r['role']=='example'},'EXAMPLES')
    require(type(p['workspace_overlay']) is bool and p['workspace_overlay']==any(not r['matches_baseline'] for r in p['inputs']),'OVERLAY')
    for row in p['inputs']:
        require(type(row['matches_baseline']) is bool and (row['git_baseline_blob'] is None or
            isinstance(row['git_baseline_blob'],str) and re.fullmatch('[0-9a-f]{40}',row['git_baseline_blob'])),'BASELINE_BLOB')
        require(row['git_baseline_mode'] in (None,'100644','100755') and
                (row['git_baseline_mode'] is None)==(row['git_baseline_blob'] is None),'BASELINE_MODE')
        require(row['role'] in {'example','generated-asset','source-or-package-input'},'INPUT_ROLE')
        require(not row['path'].startswith(('build/','release/')) and not any(s.startswith('.') for s in Path(row['path']).parts),'EXCLUDED_INPUT')
    t=p['toolchain'];require(type(t) is dict and set(t)=={'executables','files','pillow','freetype','target','bootstrap','network'},'TOOL_SCHEMA')
    require(t['target']==sdk.TARGET and t['bootstrap']=='EXTERNAL_HOST_TOOLCHAIN' and t['network'] is False,'TOOL_POLICY')
    require(type(t['executables']) is list and len(t['executables'])==9 and
            {r.get('name') for r in t['executables']}=={'nasm','ld','python3','ninja','sh','mkdir','dirname','objcopy','openssl'},'TOOL_SET')
    require(all(set(r)=={'name','version','sha256'} and hex_digest(r['sha256']) and isinstance(r['version'],str) and r['version'] for r in t['executables']),'TOOL_IDENTITY')
    require(type(t['files']) is list and 1<=len(t['files'])<4096,'TOOL_FILE_BUDGET')
    require(all(type(r) is dict and set(r)=={'path','sha256','size'} and isinstance(r['path'],str) and
            r['path'].startswith('/usr/') and hex_digest(r['sha256']) and type(r['size']) is int and 0<=r['size']<=sdk.MAX_FILE for r in t['files']),'TOOL_FILE_IDENTITY')
    require([r['path'] for r in t['files']]==sorted({r['path'] for r in t['files']}),'TOOL_FILE_ORDER')
    require(all(isinstance(t[k],str) and len(t[k])<64 for k in ('pillow','freetype')),'RASTERIZER_VERSION')
    return p

def licenses(rows,provenance):
    inputs={r['path']:r['sha256'] for r in provenance['inputs']}
    for source in ('LICENSE',*('sdk/nebo-1.0/licenses/'+n for n in
            ('THIRD-PARTY-NOTICES.md','NeboConsoleMonoAtlas-OFL-1.1.md','NeboConsoleMonoAtlas-PROVENANCE.md'))):
        name=Path(source).name
        require(source in inputs and any(Path(r['path']).name==name and r['sha256']==inputs[source] for r in rows),'LICENSE_NOTICE_GAP')
    return dict(project='LicenseRef-Nebo-Proprietary',font='OFL-1.1',
                external_legal_gate='RELEASE-LEGAL:PENDING_EXTERNAL',
                scope='LOCAL_INVENTORY_NOT_A_LEGAL_OPINION')

def archive(root,output,profile,provenance):
    require(profile in PROFILES,'PROFILE');validate_provenance(provenance)
    root=Path(root).absolute();output=Path(output).absolute()
    require(not output.is_relative_to(root),'OUTPUT_OVERLAP')
    require(not output.exists() and not output.is_symlink(),'DESTINATION_EXISTS')
    rows=inventory(root)
    if profile=='source':
        expected=[{k:r[k] for k in ('path','sha256','size','mode')} for r in provenance['inputs']]
        require([r for r in rows if r['path']!=PROVENANCE]==expected,'SOURCE_INVENTORY')
        require(read(root,PROVENANCE)[0]==canonical(provenance),'SOURCE_PROVENANCE')
    if profile in {'sdk','docs','tooling'}: require(sdk.verify_bundle(root)['profile']==profile,'SDK_PROFILE')
    if profile=='package':
        lock=read(root,'store/'+pkg.LOCK)[0];pkg.load_store(root/'store',lock,sha(lock))
    notices=licenses(rows,provenance)
    sbom=dict(schema=SCHEMA,profile=profile,files=rows,licenses=notices,provenance_sha256=sha(canonical(provenance)))
    meta={'SBOM.json':canonical(sbom),'PROVENANCE.json':canonical(provenance)}
    sdk.prepare_parent(output)
    with tempfile.TemporaryDirectory(prefix='.nebo-supply-',dir=output.parent) as tmp:
        path=Path(tmp)/'archive'
        with tarfile.open(path,'w',format=tarfile.USTAR_FORMAT) as tar:
            def add(name,raw,mode):
                info=tarfile.TarInfo(name);info.size=len(raw);info.mode=mode
                tar.addfile(info,io.BytesIO(raw))
            for name,raw in sorted(meta.items()): add(name,raw,0o644)
            with directory(root) as fd:
                for row in rows:
                    raw,mode=fs.read(fd,row['path']);require(fs.matches(raw,mode,row),'CONTENT_CHANGED')
                    add('payload/'+row['path'],raw,mode)
        raw=path.read_bytes();require(len(raw)<=MAX_ARCHIVE,'ARCHIVE_BUDGET')
        verify_bytes(raw,sha(raw),profile)
        path.chmod(0o644);os.link(path,output)
    return dict(profile=profile,sha256=sha(raw),sbom_sha256=sha(meta['SBOM.json']),files=len(rows),bytes=len(raw))

def verify_bytes(raw,pin,profile=None):
    require(hex_digest(pin),'PIN_REQUIRED');require(len(raw)<=MAX_ARCHIVE,'ARCHIVE_BUDGET');require(sha(raw)==pin,'PIN_MISMATCH')
    files={};modes={};total=0;end=0
    try:
        with tarfile.open(fileobj=io.BytesIO(raw),mode='r:') as tar:
            for m in tar:
                sdk.safe_relative(m.name)
                require(m.isfile() and m.mode in (0o644,0o755) and not (m.uid or m.gid or m.uname or m.gname or m.mtime or m.pax_headers or m.linkname),'ARCHIVE_MEMBER')
                require(m.name not in files,'DUPLICATE_MEMBER')
                require(0<=m.size<=sdk.MAX_FILE and len(files)<sdk.MAX_FILES+2,'MEMBER_BUDGET')
                total+=m.size;require(total<=sdk.MAX_BYTES,'BYTE_BUDGET')
                require(m.name in {'SBOM.json','PROVENANCE.json'} or m.name.startswith('payload/'),'ARCHIVE_LAYOUT')
                require(m.offset==end and raw[m.offset:m.offset_data]==m.tobuf(format=tarfile.USTAR_FORMAT),'NONCANONICAL_HEADER')
                files[m.name]=tar.extractfile(m).read();modes[m.name]=m.mode
                end=m.offset_data+((m.size+511)//512)*512
                require(not any(raw[m.offset_data+m.size:end]),'NONZERO_PADDING')
    except (tarfile.TarError,EOFError,UnicodeError) as e: raise ValueError('NEBO-SUPPLY-ARCHIVE_ENCODING') from e
    require(list(files)==sorted(files),'ARCHIVE_ORDER')
    require(len(raw)==((end+1024+10239)//10240)*10240 and not any(raw[end:]),'ARCHIVE_TRAILER')
    require({'SBOM.json','PROVENANCE.json'}<=files.keys(),'METADATA_MISSING')
    require(modes['SBOM.json']==modes['PROVENANCE.json']==0o644,'METADATA_MODE')
    s=decode(files['SBOM.json']);p=validate_provenance(decode(files['PROVENANCE.json']))
    require(type(s) is dict and set(s)=={'schema','profile','files','licenses','provenance_sha256'},'SBOM_FIELDS')
    require(s['schema']==SCHEMA and s['profile'] in PROFILES and (profile is None or s['profile']==profile),'SBOM_PROFILE')
    require(files['SBOM.json']==canonical(s) and files['PROVENANCE.json']==canonical(p),'NONCANONICAL_METADATA')
    fs.rows(s['files']);require([r['path'] for r in s['files']]==sorted({r['path'] for r in s['files']}),'SBOM_ORDER')
    require(set(files)=={'SBOM.json','PROVENANCE.json'}|{'payload/'+r['path'] for r in s['files']},'UNMANIFESTED_INPUT')
    require(s['provenance_sha256']==sha(files['PROVENANCE.json']) and s['licenses']==licenses(s['files'],p),'SBOM_PROVENANCE_LICENSES')
    for r in s['files']:
        name='payload/'+r['path'];require(fs.matches(files[name],modes[name],r),'CONTENT_DRIFT');sdk.scan(files[name])
    if s['profile']=='source':
        require(files.get('payload/'+PROVENANCE)==files['PROVENANCE.json'],'SOURCE_PROVENANCE')
        expected=[{k:r[k] for k in ('path','sha256','size','mode')} for r in p['inputs']]
        require([r for r in s['files'] if r['path']!=PROVENANCE]==expected,'SOURCE_INVENTORY')
        for r in p['inputs']:
            b=files['payload/'+r['path']];blob=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
            require(r['matches_baseline']==(blob==r['git_baseline_blob'] and
                    r['git_baseline_mode']=='100'+r['mode'][1:]),'BASELINE_MATCH')
    return s,p,files

def verify(path,pin,profile=None):
    path=Path(path).absolute();raw=read(path.parent,path.name,MAX_ARCHIVE)[0]
    s,p,_=verify_bytes(raw,pin,profile);return dict(sbom=s,provenance=p,sha256=sha(raw))

def restore(path,output,pin):
    path=Path(path).absolute();output=Path(output).absolute()
    require(not output.exists() and not output.is_symlink(),'DESTINATION_EXISTS')
    s,p,files=verify_bytes(read(path.parent,path.name,MAX_ARCHIVE)[0],pin)
    sdk.prepare_parent(output)
    with tempfile.TemporaryDirectory(prefix='.nebo-supply-',dir=output.parent) as tmp:
        stage=Path(tmp)/'stage';stage.mkdir()
        for row in s['files']: write(stage,row['path'],files['payload/'+row['path']],int(row['mode'],8))
        if s['profile'] in {'sdk','docs','tooling'}: require(sdk.verify_bundle(stage)['profile']==s['profile'],'SDK_PROFILE')
        if s['profile']=='package':
            lock=read(stage,'store/'+pkg.LOCK)[0];pkg.load_store(stage/'store',lock,sha(lock))
        pkg.publish(stage,output)
    return s

def attest(subjects,provenance):
    validate_provenance(provenance)
    require(type(subjects) is list and len(subjects)==5 and {r.get('profile') for r in subjects}==set(PROFILES),'SUBJECT_SET')
    for r in subjects:
        require(set(r)=={'profile','sha256','sbom_sha256','files','bytes'} and hex_digest(r['sha256']) and hex_digest(r['sbom_sha256']) and type(r['files']) is int and 0<r['files']<=sdk.MAX_FILES and type(r['bytes']) is int and 0<r['bytes']<=MAX_ARCHIVE,'SUBJECT_IDENTITY')
    return dict(schema=SCHEMA,statement='UNSIGNED_LOCAL_INTEGRITY',provenance_sha256=sha(canonical(provenance)),
                input_digest=provenance['input_digest'],subjects=sorted(subjects,key=lambda r:r['profile']),
                signing='NOT_PERFORMED',publication='NOT_AUTHORIZED')

def verify_attestation(raw,pin,archives):
    require(hex_digest(pin) and sha(raw)==pin,'ATTESTATION_PIN')
    a=decode(raw);require(type(a) is dict and set(a)=={'schema','statement','provenance_sha256','input_digest','subjects','signing','publication'},'ATTESTATION_FIELDS')
    require(type(archives) is dict and set(archives)==set(PROFILES),'ARCHIVE_SET')
    require(type(a['subjects']) is list and len(a['subjects'])==5,'SUBJECT_SET')
    subjects=[];provenance=None
    for row in a['subjects']:
        require(type(row) is dict and row.get('profile') in archives and hex_digest(row.get('sha256')),'SUBJECT_IDENTITY')
        v=verify(archives[row['profile']],row['sha256'],row['profile']);s=v['sbom'];p=v['provenance']
        require(provenance is None or p==provenance,'CROSS_ARTIFACT_PROVENANCE');provenance=p
        subjects.append(dict(profile=row['profile'],sha256=v['sha256'],sbom_sha256=sha(canonical(s)),files=len(s['files']),bytes=Path(archives[row['profile']]).stat().st_size))
    require(a==attest(subjects,provenance) and raw==canonical(a),'ATTESTATION_DRIFT')
    return a

def verify_signature(message,public_key,signature,*,key_sha256,revoked=False,usage='local-test'):
    """Ed25519 verification only; the API accepts raw public bytes, no key path."""
    require(type(message) is bytes and 1<=len(message)<=16*1024*1024,'MESSAGE_BUDGET')
    require(type(public_key) is bytes and len(public_key)==32 and type(signature) is bytes and len(signature)==64,'PUBLIC_SIGNATURE_FORMAT')
    require(hex_digest(key_sha256) and sha(public_key)==key_sha256,'PUBLIC_KEY_PIN')
    require(revoked is False and usage=='local-test','KEY_POLICY')
    with tempfile.TemporaryDirectory(prefix='nebo-public-verify-') as tmp:
        root=Path(tmp)
        # RFC 8410 SubjectPublicKeyInfo for the Ed25519 OID; no private material.
        (root/'public.der').write_bytes(bytes.fromhex('302a300506032b6570032100')+public_key)
        (root/'signature').write_bytes(signature);(root/'message').write_bytes(message)
        result=subprocess.run(['/usr/bin/openssl','pkeyutl','-verify','-pubin','-keyform','DER',
             '-inkey',str(root/'public.der'),'-rawin','-in',str(root/'message'),'-sigfile',str(root/'signature')],
             stdin=subprocess.DEVNULL,capture_output=True,timeout=10,
             env={'PATH':'/usr/bin:/bin','LC_ALL':'C','OPENSSL_CONF':'/dev/null'})
        require(result.returncode==0,'INVALID_SIGNATURE')
    return dict(algorithm='Ed25519',scope='PUBLIC_TEST_ONLY',key_sha256=key_sha256,verified=True,private_key_read=False)

def main():
    p=argparse.ArgumentParser(prog='nebo-supply-chain');sub=p.add_subparsers(dest='cmd',required=True)
    x=sub.add_parser('snapshot');x.add_argument('--repo',type=Path,required=True);x.add_argument('--output',type=Path,required=True);x.add_argument('--example',action='append',required=True);x.add_argument('--package-workspace')
    x=sub.add_parser('archive');x.add_argument('root',type=Path);x.add_argument('output',type=Path);x.add_argument('--profile',choices=PROFILES,required=True);x.add_argument('--provenance',type=Path,required=True)
    x=sub.add_parser('verify');x.add_argument('archive',type=Path);x.add_argument('--sha256',required=True)
    x=sub.add_parser('restore');x.add_argument('archive',type=Path);x.add_argument('--sha256',required=True);x.add_argument('--output',type=Path,required=True)
    a=p.parse_args()
    try:
        if a.cmd=='snapshot': result=snapshot(a.repo,a.output,a.example,package_workspace=a.package_workspace)
        elif a.cmd=='archive': result=archive(a.root,a.output,a.profile,decode(read(a.provenance.absolute().parent,a.provenance.name)[0]))
        elif a.cmd=='verify': result=verify(a.archive,a.sha256)
        else: result=restore(a.archive,a.output,a.sha256)
        print(json.dumps(result,sort_keys=True))
    except (ValueError,OSError,KeyError,TypeError,subprocess.SubprocessError) as e:p.exit(2,str(e)+'\n')
if __name__=='__main__':main()
