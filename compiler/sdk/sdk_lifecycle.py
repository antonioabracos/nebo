#!/usr/bin/env python3
"""Transactional offline SDK lifecycle over a controlled, manifest-owned prefix."""
from __future__ import annotations
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import signal
import sys
import tempfile
import uuid
from contextlib import contextmanager
from compiler.sdk import package_manager as safe_io, install_io as io
from compiler.sdk.sdk_builder import verify_bundle, MAX_FILE as SDK_MAX_FILE, restore_archive

INSTALL_FORMAT = 'NEBO-INSTALL-MANIFEST-v1'
META = '.nebo-sdk/install-manifest.json'

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def safe_rel(value):
    try: safe_io.relative(value)
    except ValueError as e: raise io.error('0001', 'unsafe path') from e
    return PurePosixPath(value)
def _manifest(prefix): return prefix / META

def source_manifest(source):
    """Validate both existing SDK archive schemas before assigning ownership."""
    fd = safe_io.open_directory(source)
    try: raw, mode = io.read(fd, 'MANIFEST.json', io.META_LIMIT)
    finally: os.close(fd)
    data = io.decode(raw)
    if not isinstance(data, dict): raise io.error('0005','source manifest object')
    if data.get('schema') == 1 and 'entries' in data:
        from compiler.sdk.toolchain import SdkPackage
        value = SdkPackage.verifyRestored(source)
        result = dict(files=[dict(r) for r in value['entries']], version='current-local-profile', profile=value['host'])
    else:
        value = verify_bundle(source)
        result = dict(value, files=[dict(r) for r in value['files']])
    result['files'].append(dict(path='MANIFEST.json', size=len(raw), sha256=hashlib.sha256(raw).hexdigest(), mode='0644', role='manifest'))
    io.rows(result['files'])
    if mode != 0o644: raise io.error('0006','source manifest mode')
    return result

@contextmanager
def exclusive(prefix):
    """Directory flock leaves no stale lock after a process interruption."""
    fd = safe_io.open_directory(prefix.parent)
    try:
        info = os.fstat(fd)
        if info.st_uid != os.geteuid() or info.st_mode & 0o022:
            raise io.error('0012', 'parent must be owned and not group/world writable')
        # Preserve rejection of the former lock marker; never remove an unknown file.
        if os.path.lexists(prefix.parent / ('.' + prefix.name + '.nebo-lock')):
            raise RuntimeError('NEBO-INSTALL-0002 concurrent operation')
        try: fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as e: raise RuntimeError('NEBO-INSTALL-0002 concurrent operation') from e
        yield fd
    finally: os.close(fd)

def _copy_bundle(source, stage, manifest=None, install_profile='prefix'):
    manifest = manifest or source_manifest(source)
    src = safe_io.open_directory(source); dst = safe_io.open_directory(stage)
    try:
        for row in manifest['files']:
            raw, mode = io.read(src, row['path'])
            if not io.matches(raw, mode, row): raise io.error('0006', 'source changed during staging')
            io.write(dst, row['path'], raw, mode)
        meta = dict(format=INSTALL_FORMAT, source_manifest_sha256=next(r['sha256'] for r in manifest['files'] if r['path']=='MANIFEST.json'),
                    version=manifest['version'], profile=manifest['profile'], owned=manifest['files'], install_profile=install_profile)
        io.write(dst, META, (json.dumps(meta, sort_keys=True, indent=2)+'\n').encode())
        io.sync_directories(dst,[r['path'] for r in manifest['files']]+[META])
        return meta
    finally: os.close(src); os.close(dst)

def destination(profile='user', prefix=None, allow_system_local=False, home=None):
    if profile not in ('user','prefix','system-local'): raise io.error('0012','unknown install profile')
    if profile == 'system-local' and not allow_system_local: raise io.error('0012','explicit system-local policy required')
    if os.geteuid() == 0 and (profile != 'system-local' or not allow_system_local): raise io.error('0012','no-root default')
    if prefix is None:
        if profile != 'user': raise io.error('0012','explicit leaf prefix required')
        prefix = Path(home or Path.home()) / '.local/opt/nebo'
    prefix = Path(prefix)
    if '..' in prefix.parts or any(ord(c)<32 for c in str(prefix)) or str(prefix) in ('.','/'):
        raise io.error('0001','unsafe prefix')
    prefix = prefix.absolute()
    if prefix in (Path('/usr'),Path('/usr/local'),Path('/bin'),Path('/etc'),Path('/opt')):
        raise io.error('0012','shared system directory is not an install prefix')
    return prefix

def install(source, prefix, fail_phase=None, *, profile='prefix', allow_system_local=False):
    source = Path(source).absolute(); prefix = destination(profile,prefix,allow_system_local)
    # No parent directories are implicitly left behind by a failed operation.
    with exclusive(prefix) as parent_fd:
        if os.path.lexists(prefix): raise FileExistsError('NEBO-INSTALL-0003 prefix exists')
        manifest = source_manifest(source)
        if fail_phase == 'validate': raise OSError('injected validate failure')
        stage = Path(tempfile.mkdtemp(prefix='.'+prefix.name+'.stage-',dir=prefix.parent))
        try:
            meta = _copy_bundle(source,stage,manifest,profile)
            if fail_phase == 'stage': raise OSError('injected stage failure')
            verify_install(stage)
            if fail_phase in ('verify','activate'): raise OSError('injected '+fail_phase+' failure')
            io.publish(parent_fd,stage.name,prefix.name)
            return meta
        finally:
            if stage.exists(): shutil.rmtree(stage)

def _load_fd(fd):
    raw, mode = io.read(fd,META,io.META_LIMIT); data = io.decode(raw)
    required = {'format','source_manifest_sha256','version','profile','owned'}
    if type(data) is not dict or not required <= set(data) or set(data)-required-{'install_profile'} or data['format'] != INSTALL_FORMAT:
        raise io.error('0005','install manifest schema')
    if mode != 0o644 or not isinstance(data['source_manifest_sha256'],str) or not re.fullmatch('[0-9a-f]{64}',data['source_manifest_sha256']):
        raise io.error('0005','install manifest identity')
    if any(not isinstance(data[k],str) or not 0<len(data[k])<=100 for k in ('version','profile')) or data.get('install_profile','prefix') not in ('user','prefix','system-local'):
        raise io.error('0005','install metadata')
    io.rows(data['owned'])
    row = [r for r in data['owned'] if r['path']=='MANIFEST.json']
    if len(row)!=1 or row[0]['sha256']!=data['source_manifest_sha256']:
        raise io.error('0005','source manifest ownership')
    # When the original package manifest is intact, ownership cannot silently
    # omit a distribution component or acquire a foreign user file.
    try: original, _ = io.read(fd,'MANIFEST.json',io.META_LIMIT)
    except (OSError,ValueError): original = None
    if original is not None and hashlib.sha256(original).hexdigest()==data['source_manifest_sha256']:
        source = io.decode(original)
        if type(source) is not dict: raise io.error('0005','source manifest object')
        entries = source.get('entries') if source.get('schema')==1 else source.get('files')
        if type(entries) is not list: raise io.error('0005','source inventory')
        expected = [*entries,dict(path='MANIFEST.json',sha256=data['source_manifest_sha256'],size=len(original),mode='0644')]
        io.rows(expected)
        identity=lambda rs:{r['path']:(r['size'],r['sha256'],r['mode']) for r in rs}
        if identity(expected)!=identity(data['owned']): raise io.error('0005','ownership differs from source manifest')
    return data

def load(prefix):
    fd = safe_io.open_directory(prefix)
    try: return _load_fd(fd)
    finally: os.close(fd)

def _verify_fd(fd):
    data = _load_fd(fd)
    for row in data['owned']:
        raw,mode = io.read(fd,row['path'])
        if not io.matches(raw,mode,row): raise io.error('0006','owned component mismatch')
    return data

def verify_install(prefix):
    fd = safe_io.open_directory(prefix)
    try: return _verify_fd(fd)
    finally: os.close(fd)

def require_no_foreign(prefix, data):
    files = {r['path'] for r in data['owned']} | {META}
    fd = safe_io.open_directory(prefix)
    try:
        if any(name not in files for name in io.inventory(fd)):
            raise io.error('0011','rollback would discard unowned data')
    finally: os.close(fd)

def uninstall(prefix):
    prefix = Path(prefix).absolute()
    with exclusive(prefix):
        fd = safe_io.open_directory(prefix)
        try:
            data = _load_fd(fd); remove = []; preserved = []
            io.inventory(fd)  # Bound reporting before deleting any owned content.
            # Complete preflight precedes any deletion. Linked parents never escape.
            for row in data['owned']:
                try: raw,mode = io.read(fd,row['path'])
                except FileNotFoundError: continue
                except (ValueError,OSError): preserved.append(row['path']); continue
                if io.matches(raw,mode,row): remove.append(row['path'])
                else: preserved.append(row['path'])
            for name in remove: io.unlink(fd,name)
            io.unlink(fd,META)
            owned_dirs = [str(p) for name in [*remove,META] for p in PurePosixPath(name).parents if str(p)!='.']
            io.prune(fd,owned_dirs)
            leftovers = io.inventory(fd)
        finally: os.close(fd)
        try: prefix.rmdir()
        except OSError: pass
        return dict(removed=remove,leftovers=leftovers,preserved=preserved,cache_policy='preserve-unowned')

def repair(source, prefix):
    """Preflight all identity/paths, stage all repairs, rollback ordinary failures."""
    prefix = Path(prefix).absolute(); source = Path(source).absolute()
    with exclusive(prefix):
        data = source_manifest(source); fd = safe_io.open_directory(prefix); src = safe_io.open_directory(source)
        stage = None; stage_fd = None; changed = []; made = []
        try:
            installed = _load_fd(fd)
            identity = lambda rows: {r['path']:(r['sha256'],r['size'],r['mode']) for r in rows}
            if identity(data['files']) != identity(installed['owned']): raise io.error('0007','source identity mismatch')
            repairs = []
            for row in installed['owned']:
                try:
                    raw,mode = io.read(fd,row['path'])
                    if io.matches(raw,mode,row): continue
                    previous = (raw,mode)
                except FileNotFoundError: previous = None
                except (OSError,ValueError) as e: raise io.error('0001','unsafe repair destination') from e
                # Missing parents are allowed, but an existing link is never followed.
                repairs.append((row,previous))
            if not repairs: return {'repaired':[]}
            stage = Path(tempfile.mkdtemp(prefix='.'+prefix.name+'.repair-',dir=prefix.parent)); stage_fd = safe_io.open_directory(stage)
            for n,(row,previous) in enumerate(repairs):
                raw,mode = io.read(src,row['path'])
                if not io.matches(raw,mode,row): raise io.error('0006','repair source changed')
                io.write(stage_fd,'new'+str(n),raw,mode)
                if previous: io.write(stage_fd,'old'+str(n),*previous)
            try:
                for n,(row,previous) in enumerate(repairs):
                    with io.parent(fd,row['path'],True,made): pass
                    io.rename(stage_fd,'new'+str(n),fd,row['path']); changed.append((n,row,previous))
                _verify_fd(fd)
            except BaseException:
                for n,row,previous in reversed(changed):
                    if previous: io.rename(stage_fd,'old'+str(n),fd,row['path'])
                    else: io.unlink(fd,row['path'])
                io.prune(fd,made)
                raise
            return {'repaired':[row['path'] for row,_ in repairs]}
        finally:
            os.close(fd); os.close(src)
            if stage_fd is not None: os.close(stage_fd)
            if stage is not None: shutil.rmtree(stage)

@contextmanager
def local_source(source, archive_sha256=None):
    source = Path(source).absolute()
    if source.is_dir():
        if archive_sha256: raise io.error('0013','digest option requires an archive')
        yield source; return
    if not archive_sha256: raise io.error('0013','local archive SHA256 required')
    with tempfile.TemporaryDirectory(prefix='.nebo-local-archive-',dir=source.parent) as work:
        restored = Path(work)/'source'
        restore_archive(source,restored,archive_sha256)
        yield restored

def environment(prefix, shell='sh'):
    prefix = Path(prefix).absolute(); verify_install(prefix)
    if shell not in ('sh','bash'): raise io.error('0014','supported shells: sh, bash')
    root = shlex.quote(str(prefix))
    lines = ['# Opt-in: evaluate explicitly; no shell files are edited.', 'export NEBO_SDK_ROOT='+root,
             'case ":${PATH-}:" in *":${NEBO_SDK_ROOT}/bin:"*) ;; *) export PATH="${NEBO_SDK_ROOT}/bin:${PATH-}" ;; esac',
             'export NEBO_PACKAGE_STORE="${NEBO_PACKAGE_STORE:-${NEBO_SDK_ROOT}/var/packages}"']
    if shell == 'bash': lines.append('complete -W "check emit-asm build doctor --help --version" neboc')
    return '\n'.join(lines)+'\n'
def compatible_sdk(installed, candidate, *, installed_root=None, candidate_root=None):
    """Retain frozen contracts; admit the reviewed same-Edition minor upgrade."""
    if installed.get('profile') != candidate.get('profile'):
        raise io.error('0019', 'SDK profile/version migration required')
    if installed.get('version') != candidate.get('version'):
        from compiler.sdk.version_identity import VERSION, identity
        if installed_root is None or candidate_root is None:
            raise io.error('0019', 'SDK version migration requires verified identities')
        old, new = identity(installed_root), identity(candidate_root)
        before = tuple(map(int, old['version'].split('.')))
        after = tuple(map(int, new['version'].split('.')))
        if (old['version'] != installed['version'] or new['version'] != candidate['version']
            or new['version'] != VERSION or before[0] != after[0] or before < (1, 0, 1)
            or not before < after or old['edition'] != new['edition'] or old['target'] != new['target']):
            raise io.error('0019', 'outside the reviewed same-Edition compatibility window')
        previous = {r['path']: r['sha256'] for r in installed['owned']}
        following = {r['path']: r['sha256'] for r in candidate['files']}
        # These public identities are unchanged by the reviewed minor release.
        # New interfaces may be added; existing serialized interfaces cannot be
        # removed or silently reinterpreted. Rollback retains the original SDK.
        frozen = {'share/nebo/freeze/SYMBOLID-EXPORT-INVENTORY.tsv',
                  'share/nebo/freeze/DIAGNOSTIC-COMPATIBILITY-REGISTRY.tsv'}
        if not frozen <= previous.keys() or any(following.get(p) != previous[p] for p in frozen):
            raise io.error('0019', 'public frozen compatibility inventory changed')
        if any(following.get(p) != h for p,h in previous.items() if p.endswith('.ni')):
            raise io.error('0019', 'existing serialized interface changed')
        return
    def contracts(rows):
        return {r['path']: r['sha256'] for r in rows if r['path'].endswith('.ni')
                or r['path'].endswith(('FREEZE-MANIFEST.json', 'STDLIB-API-ABI-MANIFEST.json',
                                       'NEBO-VERSION.json', 'stdlib-registry.json'))}
    if contracts(installed['owned']) != contracts(candidate['files']):
        raise io.error('0019', 'frozen SDK contract changed')

def upgrade(prefix: Path,candidate: Path) -> dict:
    prefix=prefix.absolute()
    with exclusive(prefix) as parent_fd:
        prefix=prefix.absolute(); rollback=prefix.parent/(prefix.name+".nebo-rollback")
        if os.path.lexists(rollback): raise FileExistsError("NEBO-INSTALL-0008 rollback point exists")
        installed=verify_install(prefix); manifest=source_manifest(candidate)
        compatible_sdk(installed,manifest,installed_root=prefix,candidate_root=candidate)
        stage=Path(tempfile.mkdtemp(prefix="."+prefix.name+".upgrade-",dir=prefix.parent))
        try:
            _copy_bundle(candidate,stage,manifest,installed.get('install_profile','prefix')); verify_install(stage)
            io.exchange(parent_fd,prefix.name,stage.name)
            try: io.publish(parent_fd,stage.name,rollback.name)
            except BaseException: io.exchange(parent_fd,prefix.name,stage.name); raise
            return {"active":load(prefix)["version"],"rollback":load(rollback)["version"]}
        except BaseException:
            shutil.rmtree(stage,ignore_errors=True); raise
def rollback(prefix: Path) -> dict:
    prefix=prefix.absolute()
    with exclusive(prefix) as parent_fd:
        prefix=prefix.absolute(); old=prefix.parent/(prefix.name+".nebo-rollback"); failed=prefix.parent/(prefix.name+".nebo-failed-candidate")
        active=verify_install(prefix); verify_install(old);require_no_foreign(prefix,active)
        if failed.exists() or failed.is_symlink(): raise FileExistsError("NEBO-INSTALL-0009 occupied rollback staging path")
        io.exchange(parent_fd,prefix.name,old.name)
        try:
            verify_install(prefix)
            io.publish(parent_fd,old.name,failed.name)
        except BaseException:
            io.exchange(parent_fd,prefix.name,old.name);raise
        shutil.rmtree(failed); return {"active":load(prefix)["version"]}
def cache_gc(cache: Path,active: set[str]) -> list[str]:
    """Low-level owned cache eviction; lifecycle callers derive active from locks."""
    cache=Path(cache).absolute(); removed=[]
    with exclusive(cache/'gc'):
        paths=sorted(cache.iterdir())
        if len(paths)>256 or type(active) is not set or any(not isinstance(k,str) or not k.isascii() or not k.isalnum() for k in active):
            raise ValueError('NEBO-CACHE-0001 cache budget or active keys')
        for path in paths:
            if not path.name.isascii() or not path.name.isalnum(): raise ValueError('NEBO-CACHE-0001 hostile cache key')
            fd=safe_io.open_directory(path)
            try:
                for name in io.inventory(fd):
                    if not name.endswith('/'): io.read(fd,name)
            finally: os.close(fd)
        for path in paths:
            if path.name not in active: shutil.rmtree(path); removed.append(path.name)
    return removed
def main(argv=None):
    def interrupted(signum, frame):
        raise InterruptedError('NEBO-INSTALL-0017 interrupted operation')
    signal.signal(signal.SIGTERM,interrupted)
    p = argparse.ArgumentParser(prog='nebo-sdk-lifecycle'); sub = p.add_subparsers(dest='cmd',required=True)
    for cmd in ('install','repair','upgrade'):
        q=sub.add_parser(cmd);q.add_argument('source',type=Path);q.add_argument('prefix',type=Path,nargs='?' if cmd=='install' else None)
        q.add_argument('--archive-sha256')
        if cmd=='install':
            q.add_argument('--profile',choices=('user','prefix','system-local'),default='user');q.add_argument('--allow-system-local',action='store_true')
    for cmd in ('verify','uninstall','rollback','env'):
        q=sub.add_parser(cmd);q.add_argument('prefix',type=Path)
        if cmd=='env': q.add_argument('--shell',choices=('sh','bash'),default='sh')
    a=p.parse_args(argv)
    try:
        if a.cmd=='env': print(environment(a.prefix,a.shell),end='');return 0
        if hasattr(a,'source'):
            with local_source(a.source,a.archive_sha256) as source:
                if a.cmd=='install': result=install(source,destination(a.profile,a.prefix,a.allow_system_local),profile=a.profile,allow_system_local=a.allow_system_local)
                elif a.cmd=='repair': result=repair(source,a.prefix)
                else: result=upgrade(a.prefix,source)
        else: result={'verify':verify_install,'uninstall':uninstall,'rollback':rollback}[a.cmd](a.prefix)
        print(json.dumps(result,sort_keys=True));return 0
    except (OSError,ValueError,RuntimeError) as e:
        # Paths and user payloads are deliberately excluded from public diagnostics.
        code=re.search(r'NEBO-(?:INSTALL|SDK)-\d{4}',str(e))
        print(json.dumps({'diagnostic':code[0] if code else 'NEBO-INSTALL-0016','operation':a.cmd,'status':'rejected'}),file=sys.stderr)
        return 2

if __name__=='__main__':
    def interrupted(signum, frame): raise InterruptedError('NEBO-INSTALL-0017 interrupted operation')
    signal.signal(signal.SIGTERM,interrupted)
    raise SystemExit(main())
