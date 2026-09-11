#!/usr/bin/env python3
"""Offline composition of the current native owners, with bounded local archives."""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import os
import re
import shutil
import stat
import subprocess
import tarfile
import tempfile
from pathlib import Path, PurePosixPath

FORMAT = 'NEBO-SDK-MANIFEST-v1'
# Script entry points and installed modules resolve the same authority.
import sys
if __package__ in (None, ''):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from compiler.sdk.version_identity import VERSION, EDITION, identity
COMPOSITION = 'nebo.sdk-composition.v1'
TARGET = 'linux-x86_64-systemv-elf-static'
PROFILES = ('source', 'sdk', 'docs', 'tooling')
MAX_FILES = 20000
MAX_FILE = 128 * 1024 * 1024
MAX_BYTES = 512 * 1024 * 1024
NATIVE = ('build/bin/neboc', 'build/obj/runtime_core.o',
          'build/obj/runtime_practical_io.o', 'build/bin/nebo-token-scan',
          'build/bin/nebo-comment-scan', 'build/bin/nebo-symbol-format',
          'build/bin/nebo-symbol-index', 'build/bin/nebo-completion', 'build/bin/nebo-doc-examples',
          'build/bin/nebo-doc-record', 'build/bin/nebo-doc-parser',
          'build/bin/nebo-doc-validator', 'build/bin/nebo-docs',
          'build/tests/rf166/g154/interface_codec_probe')
DEPENDENCIES = {
    'compiler': ['runtime', 'tooling', 'prelude'], 'runtime': [],
    'stdlib': ['runtime', 'prelude'], 'prelude': [], 'targets': ['runtime'],
    'toolchain': [], 'docs': [], 'examples': [], 'editor': [],
    'licenses': [], 'tooling': ['compiler'], 'source': [],
    'stdlib-functional-freeze': [], 'metadata': [],
}

PROFILE_COMPONENTS = {
    'source': {'source','licenses','metadata'},
    'docs': {'docs','examples','licenses','metadata','stdlib-functional-freeze'},
    'tooling': {'compiler','runtime','stdlib','prelude','targets','toolchain','tooling','examples','editor','licenses','metadata','stdlib-functional-freeze'},
}
PROFILE_COMPONENTS['sdk'] = PROFILE_COMPONENTS['tooling'] | {'docs'}

def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)+'\n').encode()

def unique(pairs):
    value = {}
    for key, item in pairs:
        if key in value: raise ValueError('NEBO-SDK-0006 duplicate JSON field')
        value[key] = item
    return value

def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return h.hexdigest()

def safe_relative(value: str) -> PurePosixPath:
    if (not isinstance(value, str) or not value or len(value.encode()) > 240
            or value.startswith('/') or any(p in {'', '.', '..'} for p in value.split('/'))
            or any(ord(c) < 32 or ord(c) == 127 for c in value) or '\\' in value or ':' in value):
        raise ValueError('NEBO-SDK-0001 unsafe relative path')
    return PurePosixPath(value)

def regular(path, limit=MAX_FILE):
    path = Path(path).absolute()
    for p in (path, *path.parents):
        if p.is_symlink(): raise ValueError('NEBO-SDK-0002 linked component')
    if not path.is_file() or path.stat().st_size > limit:
        raise ValueError('NEBO-SDK-0002 non-regular or oversized component')
    return path

def prepare_parent(output):
    for parent in (output.parent, *output.parent.parents):
        if parent.is_symlink(): raise ValueError('NEBO-SDK-0002 linked output parent')
    output.parent.mkdir(parents=True,exist_ok=True)

def _copy(source: Path, destination: Path, mode: int) -> None:
    regular(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    destination.chmod(mode)

def source_inputs(repo):
    p = subprocess.run(['ninja', '-t', 'inputs', *NATIVE], cwd=repo,
                       capture_output=True, text=True, timeout=30, check=True)
    # NASM textual includes may be .asm, .inc or binary assets and may be
    # absent from Ninja's explicit dependency list. Follow their literal closure.
    generated=subprocess.run(['ninja','-t','targets','all'],cwd=repo,
                             capture_output=True,text=True,timeout=30,check=True)
    outputs={line.rsplit(': ',1)[0] for line in generated.stdout.splitlines()}
    # `ninja -t inputs` includes intermediate outputs. Shipping those as
    # sources masks incomplete dependency closure and defeats clean rebuilds.
    names=(set(p.stdout.splitlines())-outputs) | {'build.ninja'}
    pending=list(names)
    while pending:
        name=pending.pop();path=regular(repo/safe_relative(name))
        if path.suffix not in {'.asm','.inc'}: continue
        for match in re.finditer(r"(?im)^\s*(?:%include|%?incbin)\s+['\"]([^'\"]+)['\"]",path.read_text()):
            dependency=str(safe_relative(match[1]))
            regular(repo/dependency)
            if dependency not in names: names.add(dependency);pending.append(dependency)
        if len(names)>MAX_FILES: raise ValueError('NEBO-SDK-0011 source budget')
    names=sorted(names)
    if not names or len(names) > MAX_FILES: raise ValueError('NEBO-SDK-0011 source budget')
    for name in names: regular(repo / safe_relative(name))
    return names

def component_sources(repo: Path, neboc: Path, profile: str):
    if profile not in PROFILES: raise ValueError('NEBO-SDK-0003 unknown profile')
    rows = {}
    def add(rel, source=None, mode=0o644, component='metadata'):
        safe_relative(rel)
        if rel in rows: raise ValueError('NEBO-SDK-0010 duplicate selection')
        path = repo / (source or rel)
        regular(path)
        rows[rel] = (rel, path, mode, component)
    add('LICENSE', component='licenses')
    add('share/nebo/profile.json','sdk/nebo-1.0/profiles/'+profile+'.json')
    add('share/nebo/version/NEBO-VERSION.json', 'version/NEBO-VERSION.json')
    add('share/nebo/version/NEBO-RUNTIME-IDENTITY.json', 'runtime/NEBO-RUNTIME-IDENTITY.json')
    for p in sorted((repo/'sdk/nebo-1.0/licenses').glob('*')):
        add('share/nebo/licenses/'+p.name, p, component='licenses')
    if profile == 'source':
        for rel in source_inputs(repo): add('src/'+rel, rel, component='source')
        # Python compilation hosts are runtime dependencies, not Ninja outputs.
        for directory in ('compiler/sdk', 'compiler/migration', 'compiler/stdlib', 'compiler/compat', 'compiler/docs', 'tools'):
            for p in sorted((repo/directory).glob('*.py')):
                rel=p.relative_to(repo).as_posix()
                if 'src/'+rel not in rows: add('src/'+rel, rel, component='source')
        for rel in ('sdk/interfaces/prelude/std.prelude.ni', 'sdk/interfaces/prelude/stdlib-registry.json',
                    'sdk/contracts/PRELUDE-CONTRACT.json', 'sdk/contracts/stdlib/STDLIB-API-ABI-MANIFEST.json',
                    'docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv',
                    'scripts/rf204/doc_factory.py',
                    'docs/specifications/nebo-language/NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json'):
            add('src/'+rel, rel, component='source')
        return sorted(rows.values())
    if profile in {'sdk', 'tooling'}:
        # Preserve the source-relative identity inputs for installed repacking.
        add('version/NEBO-VERSION.json')
        add('runtime/NEBO-RUNTIME-IDENTITY.json')
        for rel in NATIVE:
            add(rel, neboc if rel == 'build/bin/neboc' else rel,
                0o644 if rel.endswith('.o') else 0o755,
                'runtime' if rel.endswith('.o') else 'compiler' if rel.endswith('/neboc') else 'toolchain')
        # Every native command host derives its root from build/bin/neboc.
        # The public entry therefore delegates through the relocatable launcher.
        add('bin/neboc', 'compiler/sdk/neboc-launcher.sh', 0o755, 'compiler')
        # The public `neboc sdk pack` command can run from an installed SDK.
        # Keep its finite input closure at the same canonical relative paths;
        # the public launcher and documentation aliases are not source inputs.
        add('compiler/sdk/neboc-launcher.sh', component='tooling')
        add('docs/public/v1.0/index.md', component='tooling')
        add('sdk/nebo-1.0/licenses/NeboConsoleMonoAtlas-OFL-1.1.md', component='licenses')
        for name in ('runtime_core.o','runtime_practical_io.o'):
            add('obj/'+name, 'build/obj/'+name, component='runtime')
        for directory in ('compiler/sdk', 'compiler/migration', 'compiler/stdlib', 'compiler/compat', 'compiler/docs', 'tools'):
            for p in sorted((repo/directory).glob('*.py')):
                add(p.relative_to(repo).as_posix(), p, component='stdlib' if directory=='compiler/stdlib' else 'tooling')
        for rel in ('sdk/interfaces/prelude/std.prelude.ni','sdk/interfaces/prelude/stdlib-registry.json'):
            add(rel, component='prelude')
        for rel in ('sdk/contracts/PRELUDE-CONTRACT.json','sdk/contracts/stdlib/STDLIB-API-ABI-MANIFEST.json',
                    'docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv',
                    'docs/specifications/nebo-language/NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json'):
            add(rel, component='stdlib')
        for name in ('SYMBOLID-EXPORT-INVENTORY.tsv','DIAGNOSTIC-COMPATIBILITY-REGISTRY.tsv'):
            add('share/nebo/freeze/'+name, 'sdk/contracts/compatibility/'+name)
        add('sdk/nebo-1.0/sdk-layout.json')
        for p in sorted((repo/'sdk/nebo-1.0/profiles').glob('*.json')): add(p.relative_to(repo).as_posix(),p)
        # `neboc docs factory` and the script entry share this shipped owner.
        for name in ('nebo-new.py','nebo-sdk.py','nebo-sdk-lifecycle.py','neboc-doctor.py','nebo-supply-chain.py','nebo-performance.py','doc_factory.py'):
            add('scripts/rf204/'+name, component='tooling')
        for directory, kind in (('targets','targets'), ('toolchains','toolchain'), ('editor','editor'), ('tooling','editor'), ('templates','examples'), ('install','tooling'), ('shell','tooling'), ('security','tooling')):
            for p in sorted((repo/'sdk/nebo-1.0'/directory).rglob('*')):
                if p.is_symlink(): raise ValueError('NEBO-SDK-0002 linked asset')
                if p.is_file(): add(p.relative_to(repo).as_posix(), p, component=kind)
        for p in sorted((repo/'sdk/nebo-1.0/share').rglob('*')):
            if p.is_symlink(): raise ValueError('NEBO-SDK-0002 linked documentation')
            if p.is_file(): add('share/'+p.relative_to(repo/'sdk/nebo-1.0/share').as_posix(), p, component='tooling')
    if profile in {'sdk', 'docs'}:
        add('share/doc/nebo/index.md','docs/public/v1.0/index.md',component='docs')
        add('share/doc/nebo/offline-site.tar','docs/public/v1.0/offline-site/nebo-docs-v1.0.tar',component='docs')
        add('share/man/man1/nebo-docs.1','docs/public/v1.0/man/nebo-docs.1',component='docs')
        for p in sorted((repo/'docs/public/v1.0/examples/projects').rglob('*')):
            if p.is_file(): add('share/examples/projects/'+p.relative_to(repo/'docs/public/v1.0/examples/projects').as_posix(),p,component='examples')
    # Preserve the authenticated functional-freeze public layout in all consumers.
    from compiler.sdk.stdlib_freeze import FILES, MANIFEST, load
    freeze=repo/'sdk/contracts/stdlib'; load(freeze)
    for name in (*FILES, MANIFEST):
        add('share/nebo/stdlib/'+name, freeze/name, component='stdlib-functional-freeze')
    for p in sorted((repo/'sdk/nebo-1.0/examples').glob('*.no')):
        add('share/examples/sdk/'+p.name,p,component='examples')
    return sorted(rows.values())

def fingerprint_tools():
    result=[]
    for name in ('nasm', 'ld', 'python3', 'ninja'):
        path=shutil.which(name)
        if not path: raise ValueError('NEBO-SDK-0012 missing local tool '+name)
        binary=Path(path).resolve()
        p=subprocess.run([path,'--version'],capture_output=True,timeout=10,check=True)
        result.append(dict(name=name, bundled=False, discovery='PATH',
                           sha256=sha(binary), version=p.stdout.decode().splitlines()[0]))
    return result

def scan(data, roots=()):
    if any(str(p).encode() in data for p in roots):
        raise ValueError('NEBO-SDK-0013 absolute build path')
    # Detect credential payloads, not descriptive mentions or public keys.
    if re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}',data):
        raise ValueError('NEBO-SDK-0014 credential payload')

def validate_rows(manifest):
    if (not isinstance(manifest,dict) or manifest.get('format')!=FORMAT
        or manifest.get('network_required') is not False or manifest.get('profile') not in PROFILES
        or not isinstance(manifest.get('files'),list) or not 1<=len(manifest['files'])<=MAX_FILES):
        raise ValueError('NEBO-SDK-0006 manifest contract')
    seen=set();total=0
    for row in manifest['files']:
        if not isinstance(row,dict): raise ValueError('NEBO-SDK-0006 row')
        rel=str(safe_relative(row.get('path')))
        if rel=='MANIFEST.json' or rel in seen: raise ValueError('NEBO-SDK-0010 duplicate manifest component')
        seen.add(rel)
        if (not re.fullmatch('[0-9a-f]{64}',str(row.get('sha256')))
            or type(row.get('size')) is not int or not 0<=row['size']<=MAX_FILE
            or row.get('mode') not in ('0644','0755')): raise ValueError('NEBO-SDK-0006 row identity')
        if 'composition' in manifest and (not isinstance(row.get('component'),str)
                or row['component'] not in set(DEPENDENCIES)|{'integrity','provenance'}):
            raise ValueError('NEBO-SDK-0006 component identity')
        total+=row['size']
    if total>MAX_BYTES: raise ValueError('NEBO-SDK-0011 byte budget')
    return seen

def verify_bundle(root: Path) -> dict:
    root=Path(root).absolute()
    if root.is_symlink() or not root.is_dir(): raise ValueError('NEBO-SDK-0005 invalid SDK root')
    mp=regular(root/'MANIFEST.json')
    manifest=json.loads(mp.read_bytes(),object_pairs_hook=unique)
    expected=validate_rows(manifest)
    for row in manifest['files']:
        path=regular(root/safe_relative(row['path']))
        if sha(path)!=row['sha256'] or path.stat().st_size!=row['size']:
            raise ValueError('NEBO-SDK-0008 component digest mismatch')
        if stat.S_IMODE(path.stat().st_mode)!=int(row['mode'],8):
            raise ValueError('NEBO-SDK-0009 component mode mismatch')
    actual=set()
    for p in root.rglob('*'):
        if p.is_symlink() or not (p.is_file() or p.is_dir()): raise ValueError('NEBO-SDK-0007 linked or special entry')
        if p.is_file() and p!=mp: actual.add(p.relative_to(root).as_posix())
    if actual!=expected: raise ValueError('NEBO-SDK-0010 unmanifested component')
    if 'SBOM.json' in expected or 'PROVENANCE.json' in expected:
        if manifest.get('composition')!=COMPOSITION: raise ValueError('NEBO-SDK-0006 composition required')
    if 'composition' in manifest:
        if stat.S_IMODE(mp.stat().st_mode)!=0o644: raise ValueError('NEBO-SDK-0009 manifest mode')
        if manifest['composition']!=COMPOSITION or manifest.get('target')!=TARGET or manifest.get('version')!=identity(root)['version']:
            raise ValueError('NEBO-SDK-0006 composition identity')
        required={'LICENSE','SHA256SUMS','SBOM.json','PROVENANCE.json','share/nebo/profile.json'}
        if manifest['profile']=='source': required.update({'src/build.ninja','src/compiler/driver/cli/linux-x86_64/cli_driver.asm'})
        if manifest['profile'] in {'sdk','tooling'}: required.update(NATIVE);required.update({'bin/neboc','sdk/interfaces/prelude/std.prelude.ni','tools/rf27-lsp.py','tools/rf27-format.py','sdk/nebo-1.0/editor/nebo-vscode/package.json'})
        if manifest['profile'] in {'sdk','docs'}: required.update({'share/doc/nebo/offline-site.tar','share/man/man1/nebo-docs.1'})
        if not required<=expected: raise ValueError('NEBO-SDK-0007 required component absent')
        payload=[r for r in manifest['files'] if r['component'] not in {'integrity','provenance'}]
        components=sorted({r['component'] for r in payload})
        if any(c not in DEPENDENCIES for c in components): raise ValueError('NEBO-SDK-0006 component identity')
        if manifest.get('components')!=components or set(components)!=PROFILE_COMPONENTS[manifest['profile']]:
            raise ValueError('NEBO-SDK-0006 components')
        profile=json.loads((root/'share/nebo/profile.json').read_bytes(),object_pairs_hook=unique)
        if (not isinstance(profile,dict) or profile.get('profile')!=manifest['profile'] or profile.get('target')!=TARGET
            or profile.get('network_required') is not False or profile.get('components')!=components):
            raise ValueError('NEBO-SDK-0006 profile descriptor')
        sums=''.join(f"{r['sha256']}  {r['path']}\n" for r in payload).encode()
        if (root/'SHA256SUMS').read_bytes()!=sums: raise ValueError('NEBO-SDK-0008 checksum inventory')
        sbom=json.loads((root/'SBOM.json').read_bytes(),object_pairs_hook=unique)
        if not isinstance(sbom,dict) or sbom.get('schema')!='nebo.sbom.v1' or sbom.get('files')!=payload or sbom.get('components')!=component_records(components, manifest['version']):
            raise ValueError('NEBO-SDK-0008 SBOM inventory')
        provenance=json.loads((root/'PROVENANCE.json').read_bytes(),object_pairs_hook=unique)
        if (not isinstance(provenance,dict) or provenance.get('schema')!='nebo.sdk-provenance.v1' or provenance.get('trust')!='unsigned-local-integrity'
            or provenance.get('network_required') is not False or provenance.get('independent_bootstrap') is not False
            or not isinstance(provenance.get('tools'),list) or len(provenance['tools'])!=4
            or not isinstance(provenance.get('source_inputs'),list) or not 1<=len(provenance['source_inputs'])<=MAX_FILES):
            raise ValueError('NEBO-SDK-0006 provenance')
        # New product fields are mandatory in the reviewed release line;
        # historical composition manifests retain their original schema.
        product = identity(root)
        required_identity = tuple(map(int, manifest['version'].split('.'))) >= (1, 1, 0)
        for metadata in (sbom, provenance):
            for field in ('version', 'edition'):
                if (required_identity or field in metadata) and metadata.get(field) != product[field]:
                    raise ValueError('NEBO-SDK-0006 product metadata identity')
        runtime_path = root/'share/nebo/version/NEBO-RUNTIME-IDENTITY.json'
        if required_identity or runtime_path.exists():
            runtime = json.loads(runtime_path.read_bytes(), object_pairs_hook=unique)
            if any(runtime.get(k) != product[k] for k in ('version', 'edition', 'target')):
                raise ValueError('NEBO-SDK-0006 runtime product identity')
        tools=provenance['tools']
        if any(not isinstance(t,dict) or not isinstance(t.get('name'),str)
               or t.get('bundled') is not False or t.get('discovery')!='PATH'
               or not isinstance(t.get('version'),str) or not t['version']
               or not re.fullmatch('[0-9a-f]{64}',str(t.get('sha256'))) for t in tools):
            raise ValueError('NEBO-SDK-0006 toolchain fingerprint')
        if {t['name'] for t in tools}!={'nasm','ld','python3','ninja'}:
            raise ValueError('NEBO-SDK-0006 toolchain inventory')
        inputs=[]
        for item in provenance['source_inputs']:
            if not isinstance(item,dict) or not re.fullmatch('[0-9a-f]{64}',str(item.get('sha256'))):
                raise ValueError('NEBO-SDK-0006 source fingerprint')
            name=str(safe_relative(item.get('path')));inputs.append(name)
            if manifest['profile']=='source' and (not (root/'src'/name).is_file() or sha(root/'src'/name)!=item['sha256']):
                raise ValueError('NEBO-SDK-0008 source provenance mismatch')
        if inputs!=sorted(set(inputs)): raise ValueError('NEBO-SDK-0006 source inventory')
        for row in manifest['files']: scan((root/row['path']).read_bytes())
    return manifest

def component_records(components, product_version=VERSION):
    return [dict(id='nebo.'+c,version=product_version,dependencies=['nebo.'+d for d in DEPENDENCIES[c]],
                 license=('LicenseRef-Nebo-Proprietary AND OFL-1.1' if c in {'compiler','runtime','source'}
                          else 'LicenseRef-Nebo-Proprietary' if c!='licenses' else 'see bundled notices')) for c in components]

def build_bundle(repo: Path, output: Path, neboc: Path, profile: str='sdk') -> dict:
    repo=repo.absolute(); neboc=regular(neboc); output=output.absolute()
    if output.exists() or output.is_symlink(): raise FileExistsError('NEBO-SDK-0004 destination exists')
    if identity(repo)['version'] != VERSION: raise ValueError('NEBO-SDK-0015 source product identity')
    rows=component_sources(repo,neboc,profile)
    prepare_parent(output)
    stage=Path(tempfile.mkdtemp(prefix='.nebo-sdk-stage-',dir=output.parent))
    try:
        payload=[]
        def record(rel,mode,component):
            path=stage/rel
            scan(path.read_bytes(),(repo,stage,output))
            payload.append(dict(path=rel,sha256=sha(path),size=path.stat().st_size,mode=format(mode,'04o'),component=component))
        for rel,source,mode,component in rows:
            _copy(source,stage/safe_relative(rel),mode);record(rel,mode,component)
        if profile!='source':
            from compiler.sdk.stdlib_freeze import load
            load(stage/'share/nebo/stdlib')
        components=sorted({r['component'] for r in payload})
        payload.sort(key=lambda r:r['path'])
        generated={
            'SHA256SUMS':(''.join(f"{r['sha256']}  {r['path']}\n" for r in payload).encode(),'integrity'),
            'SBOM.json':(canonical(dict(schema='nebo.sbom.v1',version=VERSION,edition=EDITION,components=component_records(components),files=payload.copy())), 'provenance'),
            'PROVENANCE.json':(canonical(dict(schema='nebo.sdk-provenance.v1',version=VERSION,edition=EDITION,trust='unsigned-local-integrity',
                source_inputs=[dict(path=n,sha256=sha(repo/n)) for n in source_inputs(repo)],
                tools=fingerprint_tools(), network_required=False, independent_bootstrap=False)), 'provenance'),
        }
        for rel,(data,kind) in generated.items():
            (stage/rel).write_bytes(data);(stage/rel).chmod(0o644);record(rel,0o644,kind)
        manifest=dict(format=FORMAT,composition=COMPOSITION,version=VERSION,profile=profile,target=TARGET,
                      network_required=False,components=components,files=payload)
        (stage/'MANIFEST.json').write_bytes(canonical(manifest));(stage/'MANIFEST.json').chmod(0o644)
        verify_bundle(stage)
        from compiler.sdk.package_manager import publish
        publish(stage,output)
        return manifest
    except BaseException:
        shutil.rmtree(stage);raise

def make_archive(root: Path, archive_path: Path) -> str:
    manifest=verify_bundle(root);archive_path=archive_path.absolute()
    if archive_path.exists() or archive_path.is_symlink(): raise FileExistsError('NEBO-SDK-0004 destination exists')
    if archive_path.is_relative_to(root.absolute()): raise ValueError('NEBO-SDK-0004 archive overlaps bundle')
    prepare_parent(archive_path)
    fd,name=tempfile.mkstemp(prefix='.nebo-sdk-archive-',dir=archive_path.parent);os.close(fd);tmp=Path(name)
    try:
        with tarfile.open(tmp,'w',format=tarfile.USTAR_FORMAT) as tar:
            for rel in sorted(['MANIFEST.json']+[r['path'] for r in manifest['files']]):
                path=regular(root/rel);info=tar.gettarinfo(str(path),arcname='nebo-sdk/'+rel)
                info.uid=info.gid=0;info.uname=info.gname='';info.mtime=0
                info.mode=0o755 if path.stat().st_mode&0o111 else 0o644
                with path.open('rb') as f:tar.addfile(info,f)
        tmp.chmod(0o644);os.link(tmp,archive_path);return sha(archive_path)
    finally:tmp.unlink()

def restore_archive(archive_path: Path, output: Path, expected_sha256: str) -> dict:
    limit=MAX_BYTES+MAX_FILES*1024
    archive_path=regular(archive_path,limit);output=output.absolute()
    if output.exists() or output.is_symlink():raise FileExistsError('NEBO-SDK-0004 destination exists')
    # Verify and consume the same bounded byte sequence, even if the caller
    # replaces the input pathname after the digest check.
    from compiler.sdk.package_manager import open_directory
    parent=open_directory(archive_path.parent)
    try:
        fd=os.open(archive_path.name,os.O_RDONLY|os.O_NOFOLLOW,dir_fd=parent)
        with os.fdopen(fd,'rb') as stream:
            if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode): raise ValueError('NEBO-SDK-0016 archive input')
            raw=stream.read(limit+1)
    finally:os.close(parent)
    if len(raw)>limit: raise ValueError('NEBO-SDK-0011 archive budget')
    if not re.fullmatch('[0-9a-f]{64}',expected_sha256) or hashlib.sha256(raw).hexdigest()!=expected_sha256:
        raise ValueError('NEBO-SDK-0015 archive digest mismatch')
    prepare_parent(output)
    stage=Path(tempfile.mkdtemp(prefix='.nebo-sdk-stage-',dir=output.parent))
    try:
        with tarfile.open(fileobj=io.BytesIO(raw),mode='r:') as tar:
            seen=set();total=0
            for member in tar:
                if (not member.isfile() or not member.name.startswith('nebo-sdk/')
                    or member.mode not in (0o644,0o755) or member.uid or member.gid or member.mtime
                    or member.uname or member.gname or member.pax_headers or member.size<0):raise ValueError('NEBO-SDK-0016 archive member')
                rel=str(safe_relative(member.name[len('nebo-sdk/'):]))
                if rel in seen:raise ValueError('NEBO-SDK-0016 duplicate archive member')
                seen.add(rel);total+=member.size
                if len(seen)>MAX_FILES+1 or member.size>MAX_FILE or total>MAX_BYTES+MAX_FILE:
                    raise ValueError('NEBO-SDK-0011 archive budget')
                dest=stage/rel;dest.parent.mkdir(parents=True,exist_ok=True)
                with tar.extractfile(member) as f, dest.open('xb') as out:shutil.copyfileobj(f,out)
                dest.chmod(member.mode)
        manifest=verify_bundle(stage)
        from compiler.sdk.package_manager import publish
        publish(stage,output)
        return manifest
    except BaseException:
        shutil.rmtree(stage);raise

def main():
    p=argparse.ArgumentParser(prog='nebo-sdk');sub=p.add_subparsers(dest='cmd',required=True)
    b=sub.add_parser('build');b.add_argument('--repo',type=Path,required=True);b.add_argument('--neboc',type=Path,required=True);b.add_argument('--output',type=Path,required=True);b.add_argument('--profile',choices=PROFILES,default='sdk')
    v=sub.add_parser('verify');v.add_argument('root',type=Path)
    a=sub.add_parser('archive');a.add_argument('root',type=Path);a.add_argument('output',type=Path)
    r=sub.add_parser('restore');r.add_argument('archive',type=Path);r.add_argument('--output',type=Path,required=True);r.add_argument('--sha256',required=True)
    args=p.parse_args()
    try:
        if args.cmd=='build': result=build_bundle(args.repo,args.output,args.neboc,args.profile)
        elif args.cmd=='verify':result=verify_bundle(args.root)
        elif args.cmd=='archive':result={'sha256':make_archive(args.root,args.output)}
        else:result=restore_archive(args.archive,args.output,args.sha256)
        print(json.dumps(result,sort_keys=True))
    except (ValueError,OSError,KeyError,tarfile.TarError,subprocess.SubprocessError) as e:
        p.exit(2,str(e)+'\n')
if __name__=='__main__':
    import sys
    sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
    main()
