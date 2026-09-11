"""Pinned local SDK/package generations selected by one atomic state record.

Only immutable, manifest-owned inputs are admitted. No registry, downloader,
user hook, environment SDK discovery or implicit version selection is used.
"""
from __future__ import annotations
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
from compiler.sdk import package_manager as pkg, sdk_lifecycle as sdk, install_io as io

SCHEMA = 'NEBO-OFFLINE-LIFECYCLE-v1'
STATE = 'state.json'
RECORD = 'generation.json'
MAX_GENERATIONS = 8
MAX_CACHE = 32
MAX_RECORD = io.META_LIMIT
HEX = re.compile('[0-9a-f]{64}')


def require(test, code):
    if not test: raise ValueError('NEBO_OFFLINE_' + code)


def digest(raw): return hashlib.sha256(raw).hexdigest()
def canonical(value): return pkg.canonical(value)


def read(root, name, limit=MAX_RECORD):
    fd = pkg.open_directory(root)
    try: return io.read(fd, name, limit)[0]
    finally: os.close(fd)


def decode(raw):
    require(len(raw) <= MAX_RECORD, 'RECORD_BUDGET')
    try: return json.loads(raw.decode('utf-8'), object_pairs_hook=pkg.unique,
                           parse_constant=lambda _: require(False, 'JSON_NONFINITE'))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as e:
        raise ValueError('NEBO_OFFLINE_JSON') from e


def fields(value, keys): require(type(value) is dict and set(value) == set(keys.split()), 'SCHEMA')
def pin(value): require(isinstance(value, str) and HEX.fullmatch(value), 'PIN')


def root_path(root):
    root = Path(root)
    require('..' not in root.parts and str(root) not in ('.','/'), 'ROOT')
    root = root.absolute()
    pkg.directory(root)
    info = root.stat()
    require(info.st_uid == os.geteuid() and not info.st_mode & 0o022, 'ROOT_OWNERSHIP')
    return root


@contextmanager
def locked(root):
    root = root_path(root)
    with sdk.exclusive(root / 'operation'):
        allowed = {'generations', 'cache', STATE}
        # A killed writer may leave an inactive stage. It is never selected or
        # deleted by pattern; audit reports it for explicit owner recovery.
        require(all(p.name in allowed or re.fullmatch(r'\.stage-[a-z0-9_]+', p.name)
                    for p in root.iterdir()), 'FOREIGN_ROOT_ENTRY')
        for name in ('generations', 'cache'): pkg.directory(root / name)
        yield root


def initialize(root):
    root = sdk.destination('prefix', root)
    with sdk.exclusive(root) as parent:
        require(not os.path.lexists(root), 'ROOT_EXISTS')
        with tempfile.TemporaryDirectory(prefix='.offline-init-', dir=root.parent) as raw:
            stage = Path(raw) / 'root'; stage.mkdir(mode=0o700)
            (stage/'generations').mkdir(mode=0o700); (stage/'cache').mkdir(mode=0o700)
            fd = pkg.open_directory(stage)
            try:
                io.write(fd, STATE, canonical(dict(schema=SCHEMA, active=None, previous=None)))
                io.sync_directories(fd, [STATE, 'generations/x', 'cache/x'])
            finally: os.close(fd)
            io.publish(parent, stage.name if stage.parent == root.parent else os.path.relpath(stage,root.parent), root.name)
    return dict(schema=SCHEMA, active=None, previous=None)


def state(root):
    raw = read(root, STATE); value = decode(raw)
    fields(value, 'schema active previous')
    require(value['schema'] == SCHEMA and raw == canonical(value), 'STATE')
    for key in ('active','previous'):
        if value[key] is not None: pin(value[key])
    require(value['active'] != value['previous'] or value['active'] is None, 'STATE_ALIAS')
    require(value['active'] is not None or value['previous'] is None, 'STATE_ORDER')
    return value


def inventory(root, *, omit=()):
    fd = pkg.open_directory(root); result=[]; total=0
    try:
        for name in io.inventory(fd):
            require(not name.endswith('/'), 'EMPTY_FOREIGN_DIRECTORY')
            if name in omit: continue
            raw, mode = io.read(fd, name)
            total += len(raw)
            require(total <= 2 * 512 * 1024 * 1024 and len(result) < 22000, 'GENERATION_BUDGET')
            require(mode in (0o644,0o755), 'MODE')
            result.append(dict(path=name, size=len(raw), sha256=digest(raw), mode=f'{mode:04o}'))
    finally: os.close(fd)
    return result


def record(root, key, verify=True):
    pin(key); base=root/'generations'/key
    raw=read(base, RECORD); data=decode(raw)
    fields(data, 'schema sdk_sha256 lock_sha256 cache_key files')
    require(data['schema']==SCHEMA and canonical(data)==raw, 'GENERATION_RECORD')
    for name in ('sdk_sha256','lock_sha256','cache_key'): pin(data[name])
    identity={k:data[k] for k in ('schema','sdk_sha256','lock_sha256')}
    require(digest(canonical(identity))==key, 'GENERATION_ID')
    io.rows(data['files'])
    if verify:
        require(inventory(base, omit=(RECORD,)) == data['files'], 'GENERATION_CORRUPT')
        installed=sdk.verify_install(base/'sdk')
        sdk.require_no_foreign(base/'sdk',installed)
        require(digest(read(base/'sdk','MANIFEST.json'))==data['sdk_sha256'], 'SDK_PIN')
        lock=read(base/'project',pkg.LOCK,pkg.MAX_JSON)
        require(digest(lock)==data['lock_sha256'] and decode(lock)['cache_key']==data['cache_key'], 'LOCK_PIN')
        require(read(base,pkg.LOCK,pkg.MAX_JSON)==lock, 'LOCK_COPY')
        lock_value=decode(lock)
        project_paths={pkg.LOCK,'build.json','bin/program'}|{f'packages/{r["id"]}/{name}' for r in lock_value['packages'] for name in r['files']}
        require({r['path'] for r in inventory(base/'project')}==project_paths,'FOREIGN_PROJECT_ENTRY')
        for item in lock_value['packages']:
            for name, expected in item['files'].items():
                require(digest(read(base/'project',f'packages/{item["id"]}/{name}'))==expected,'PROJECT_INTEGRITY')
        build=decode(read(base/'project','build.json'))
        require(build==dict(packages=len(lock_value['packages']),cache_key=data['cache_key'],
                            lock_sha256=data['lock_sha256'],elf_sha256=digest(read(base/'project','bin/program'))),'PROJECT_BUILD_RECORD')
        require({r['path'] for r in data['files']}=={pkg.LOCK}|{'project/'+p for p in project_paths}|{'sdk/'+r['path'] for r in installed['owned']}|{'sdk/'+sdk.META},'FOREIGN_GENERATION_ENTRY')
    return data


def set_state(root, new):
    """One record commits SDK, project, lock and cache selection together."""
    old=read(root, STATE)
    fd=pkg.open_directory(root)
    with tempfile.TemporaryDirectory(prefix='.stage-',dir=root) as temp:
        stage=Path(temp); s=pkg.open_directory(stage)
        try:
            io.write(s,'new',canonical(new)); io.write(s,'old',old)
            os.replace(stage/'new',root/STATE)
            try: os.fsync(fd)
            except BaseException:
                os.replace(stage/'old',root/STATE); raise
        finally: os.close(s);os.close(fd)


def installed_build(sdk_root, store, raw, lock_pin, output):
    """The staged SDK's compiler revalidates interfaces and builds the project."""
    command=['/usr/bin/python3','-B',str(sdk_root/'tools/rf27-package.py'),'package','build',
             '--store',str(store),'--lock',str(store/pkg.LOCK),'--lock-sha256',lock_pin,'--output',str(output)]
    require(read(store,pkg.LOCK,pkg.MAX_JSON)==raw, 'STORE_LOCK')
    env={'PATH':'/usr/bin:/bin','LC_ALL':'C','LANG':'C','TZ':'UTC',
         'PYTHONDONTWRITEBYTECODE':'1','TMPDIR':str(output.parent),'HOME':str(sdk_root)}
    with tempfile.TemporaryFile(dir=output.parent) as out, tempfile.TemporaryFile(dir=output.parent) as err:
        try:
            p=subprocess.run(command,cwd=sdk_root,stdin=subprocess.DEVNULL,stdout=out,stderr=err,env=env,timeout=60)
        except subprocess.TimeoutExpired as e: raise ValueError('NEBO_OFFLINE_BUILD_TIMEOUT') from e
        out.seek(0);err.seek(0);stdout=out.read(65537);stderr=err.read(65537)
    require(len(stdout)+len(stderr)<=65536, 'BUILD_OUTPUT_BUDGET')
    if p.returncode:
        codes=re.findall(rb'NEBO_PACKAGE_[A-Z_]+',stderr)
        raise ValueError('NEBO_OFFLINE_BUILD_REJECTED'+(' '+codes[0].decode() if codes else ''))
    require(not stderr, 'BUILD_STDERR')
    result=decode(stdout)
    require(result.get('lock_sha256')==lock_pin and result.get('elf_sha256')==digest(read(output,'bin/program')), 'BUILD_IDENTITY')
    return result


def verify_cache(path, raw, lock_pin):
    require(read(path,pkg.LOCK,pkg.MAX_JSON)==raw,'STORE_LOCK')
    lock,_,_=pkg.load_store(path,raw,lock_pin)
    require(lock['cache_key']==path.name,'STALE_CACHE_KEY')
    expected={pkg.LOCK}|{f'packages/{r["id"]}/{r["version"]}/{r["content_sha256"]}/{name}' for r in lock['packages'] for name in r['files']}
    require({r['path'] for r in inventory(path)}==expected,'FOREIGN_CACHE_ENTRY')
    return lock


def import_cache(root, store, raw, lock_pin, *, repair=False):
    lock, manifests, payloads=pkg.load_store(store,raw,lock_pin)
    require(read(store,pkg.LOCK,pkg.MAX_JSON)==raw, 'STORE_LOCK')
    key=lock['cache_key']; target=root/'cache'/key
    require(len(list((root/'cache').iterdir()))<MAX_CACHE or target.exists(), 'CACHE_BUDGET')
    if target.exists() and not repair:
        verify_cache(target,raw,lock_pin)
        return target
    with tempfile.TemporaryDirectory(prefix='.stage-',dir=root) as temp:
        stage=Path(temp)/'cache'; stage.mkdir(mode=0o700)
        pkg.write(stage,pkg.LOCK,raw)
        for item in lock['packages']:
            for name,data in payloads[item['id']].items():
                pkg.write(stage,f'packages/{item["id"]}/{item["version"]}/{item["content_sha256"]}/{name}',data)
        if os.path.lexists(target):
            # Repair may replace damaged bytes only in the exact owned file set.
            require([r['path'] for r in inventory(target)]==[r['path'] for r in inventory(stage)], 'FOREIGN_CACHE_ENTRY')
            old=Path(temp)/'old'; os.rename(target,old)
            try: pkg.publish(stage,target)
            except BaseException: os.rename(old,target);raise
        else: pkg.publish(stage,target)
    return target


def compatibility(old, candidate, raw):
    sdk.compatible_sdk(sdk.verify_install(old/'sdk'),sdk.source_manifest(candidate))
    before=decode(read(old/'project',pkg.LOCK,pkg.MAX_JSON));after=decode(raw)
    for name in ('root','entry','edition','target','features','package_order','module_order'):
        require(before[name]==after[name], 'COMPATIBILITY_'+name.upper())
    # Existing exact package identities must remain; pins may advance only
    # within the same major and every native API/ABI/behavior fingerprint stays.
    require([p['id'] for p in before['packages']]==[p['id'] for p in after['packages']], 'COMPATIBILITY_PACKAGES')
    for b,a in zip(before['packages'],after['packages']):
        bv,av=pkg.version(b['version']),pkg.version(a['version'])
        require(av>=bv and av[0]==bv[0], 'COMPATIBILITY_VERSION')
        require(b['interfaces']==a['interfaces'], 'COMPATIBILITY_INTERFACE')
    return dict(policy='same-major-exact-native-interfaces',migration='materialize-pinned-project-v1',compatible=True)


def restore(root, source, sdk_pin, store, raw, lock_pin, *, upgrade=False, repair=False):
    pin(sdk_pin);pin(lock_pin)
    pkg.require(digest(raw)==lock_pin, 'LOCK_INTEGRITY')
    source=Path(source).absolute();store=Path(store).absolute()
    require(digest(read(source,'MANIFEST.json'))==sdk_pin, 'SDK_PIN')
    manifest=sdk.source_manifest(source)
    require(manifest.get('composition')=='nebo.sdk-composition.v1' and manifest['profile'] in ('sdk','tooling'), 'SDK_COMPOSITION')
    require(manifest.get('target')=='linux-x86_64-systemv-elf-static', 'SDK_TARGET')
    with locked(root) as root:
        current=state(root)
        require(not (upgrade and repair), 'OPERATION')
        require(current['active'] is not None if upgrade or repair else current['active'] is None, 'ACTIVE_STATE')
        identity=dict(schema=SCHEMA,sdk_sha256=sdk_pin,lock_sha256=lock_pin);key=digest(canonical(identity))
        if repair:
            require(key==current['active'], 'REPAIR_IDENTITY')
            record(root,key,False)
        elif current['active']:
            record(root,current['active'])
            require(key!=current['active'], 'IDENTICAL_CANDIDATE')
        generations=root/'generations';target=generations/key
        require(len(list(generations.iterdir()))<MAX_GENERATIONS or target.exists(), 'GENERATION_BUDGET')
        pkg.load_store(store,raw,lock_pin)
        compatible=compatibility(root/'generations'/current['active'],source,raw) if upgrade else None
        cache=import_cache(root,store,raw,lock_pin,repair=repair)
        with tempfile.TemporaryDirectory(prefix='.stage-',dir=root) as temp:
            stage=Path(temp)/'generation';stage.mkdir(mode=0o700)
            sdk.install(source,stage/'sdk')
            require(digest(read(stage/'sdk','MANIFEST.json'))==sdk_pin, 'SDK_CHANGED')
            result=installed_build(stage/'sdk',cache,raw,lock_pin,stage/'project')
            pkg.write(stage,pkg.LOCK,raw)
            if upgrade: result['compatibility']=compatible
            data=dict(identity,cache_key=result['cache_key'],files=inventory(stage))
            pkg.write(stage,RECORD,canonical(data))
            # Fsync every payload and directory before selecting a generation.
            fd=pkg.open_directory(stage)
            try:
                for row in data['files']+[dict(path=RECORD)]:
                    with io.parent(fd,row['path']) as (parent,leaf):
                        f=os.open(leaf,os.O_RDONLY|os.O_NOFOLLOW,dir_fd=parent)
                        try: os.fsync(f)
                        finally: os.close(f)
                io.sync_directories(fd,[r['path'] for r in data['files']]+[RECORD])
            finally: os.close(fd)
            if repair:
                old=record(root,key,False)
                require([r['path'] for r in inventory(target,omit=(RECORD,))]==[r['path'] for r in data['files']], 'FOREIGN_GENERATION_ENTRY')
                # Exchange within a shared parent; the old image remains in a
                # private stage until the new generation has been validated.
                sibling=generations/('.repair-'+key)
                require(not os.path.lexists(sibling),'REPAIR_COLLISION')
                os.rename(stage,sibling); fd=pkg.open_directory(generations)
                try:
                    io.exchange(fd,key,sibling.name)
                    try: record(root,key)
                    except BaseException: io.exchange(fd,key,sibling.name);raise
                finally:
                    os.close(fd)
                    if sibling.exists(): shutil.rmtree(sibling)
            else:
                if os.path.lexists(target):
                    require(record(root,key)==data, 'GENERATION_COLLISION')
                else: pkg.publish(stage,target)
                record(root,key)
                set_state(root,dict(schema=SCHEMA,active=key,previous=current['active']))
            return dict(result,generation=key,sdk_sha256=sdk_pin,network_required=False)


def verify(root):
    with locked(root) as root:
        value=state(root)
        for key in (value['active'],value['previous']):
            if key is None:continue
            data=record(root,key);raw=read(root/'generations'/key,pkg.LOCK,pkg.MAX_JSON)
            verify_cache(root/'cache'/data['cache_key'],raw,data['lock_sha256'])
        return dict(value,inactive_stages=sorted(p.name for p in root.glob('.stage-*')))


def rollback(root):
    with locked(root) as root:
        value=state(root);require(value['previous'] is not None,'NO_ROLLBACK')
        old=value['previous'];data=record(root,old)
        raw=read(root/'generations'/old,pkg.LOCK,pkg.MAX_JSON)
        verify_cache(root/'cache'/data['cache_key'],raw,data['lock_sha256'])
        # Rebuild with the retained SDK; byte identity is independently tested
        # at runtime by the lifecycle consumer, never inferred from exit zero.
        with tempfile.TemporaryDirectory(prefix='.stage-',dir=root) as temp:
            result=installed_build(root/'generations'/old/'sdk',root/'cache'/data['cache_key'],raw,data['lock_sha256'],Path(temp)/'project')
            require(inventory(Path(temp)/'project')==inventory(root/'generations'/old/'project'), 'ROLLBACK_BUILD_MISMATCH')
        set_state(root,dict(schema=SCHEMA,active=old,previous=None))
        return dict(result,generation=old)


def gc_plan(root, value):
    live={k for k in (value['active'],value['previous']) if k}
    entries=list((root/'generations').iterdir());require(len(entries)<=MAX_GENERATIONS,'GENERATION_BUDGET')
    records={p.name:record(root,p.name) for p in entries}
    caches=list((root/'cache').iterdir());require(len(caches)<=MAX_CACHE,'CACHE_BUDGET')
    for p in caches:
        pin(p.name);raw=read(p,pkg.LOCK,pkg.MAX_JSON)
        verify_cache(p,raw,digest(raw))
    kept={records[k]['cache_key'] for k in live}
    require(kept<={p.name for p in caches},'MISSING_ACTIVE_CACHE')
    return entries,caches,live,kept


def gc(root):
    with locked(root) as root:
        entries,caches,live,kept=gc_plan(root,state(root))
        removed=[]
        for p in entries:
            if p.name not in live:shutil.rmtree(p);removed.append(p.name)
        evicted=sdk.cache_gc(root/'cache',kept)
        return dict(generations=sorted(removed),cache=evicted,protected=sorted(kept))


def uninstall(root):
    with locked(root) as root:
        entries,caches,_,_=gc_plan(root,state(root))
        require(not list(root.glob('.stage-*')), 'INACTIVE_STAGE_REQUIRES_OWNER_RECOVERY')
        # Complete preflight must succeed before even deactivation can occur.
        set_state(root,dict(schema=SCHEMA,active=None,previous=None))
        for p in entries+caches:shutil.rmtree(p)
        (root/STATE).unlink();(root/'generations').rmdir();(root/'cache').rmdir()
        # Keep the directory lock held through removing the owned root.
        root.rmdir()
    return dict(uninstalled=True,removed=dict(generations=sorted(p.name for p in entries),cache=sorted(p.name for p in caches)))


def main(argv=None):
    parser=argparse.ArgumentParser(prog='nebo-offline')
    sub=parser.add_subparsers(dest='command',required=True)
    for cmd in ('init','verify','rollback','gc','uninstall','restore','upgrade','repair'):
        p=sub.add_parser(cmd);p.add_argument('root',type=Path)
        if cmd in ('restore','upgrade','repair'):
            p.add_argument('--sdk',type=Path,required=True);p.add_argument('--sdk-sha256',required=True)
            p.add_argument('--archive-sha256');p.add_argument('--store',type=Path,required=True)
            p.add_argument('--lock',type=Path,required=True);p.add_argument('--lock-sha256',required=True)
    args=parser.parse_args(argv)
    try:
        if args.command in ('restore','upgrade','repair'):
            raw=read(args.lock.parent,args.lock.name,pkg.MAX_JSON)
            with sdk.local_source(args.sdk,args.archive_sha256) as source:
                result=restore(args.root,source,args.sdk_sha256,args.store,raw,args.lock_sha256,
                               upgrade=args.command=='upgrade',repair=args.command=='repair')
        else: result={'init':initialize,'verify':verify,'rollback':rollback,'gc':gc,'uninstall':uninstall}[args.command](args.root)
    except (OSError,ValueError,RuntimeError,KeyError,TypeError) as e:
        codes=re.findall(r'NEBO_(?:OFFLINE|PACKAGE)_[A-Z_]+|NEBO-(?:SDK|INSTALL)-[0-9]{4}',str(e))
        print(json.dumps(dict(status='rejected',operation=args.command,diagnostic=codes[0] if codes else 'NEBO_OFFLINE_INPUT',
                              cause=codes[1] if len(codes)>1 else None,network_required=False)),file=sys.stderr)
        return 2
    print(canonical(result).decode(),end='');return 0


if __name__=='__main__':
    def stop(*_): raise InterruptedError('NEBO_OFFLINE_INTERRUPTED')
    signal.signal(signal.SIGTERM,stop)
    raise SystemExit(main())
