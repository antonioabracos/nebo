"""Exact-pinned offline packages over the native RF166 module/.ni owners.

The directory store is an immutable content-addressed cache, not a registry.
Admission snapshots regular inputs before invoking the compiler. Publication
uses one directory rename; no source supplied executable or build hook runs.
"""
from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / 'build/bin/neboc'
TARGET = 'x86_64-systemv-elf-linux'
MANIFEST = 'nebo.package.json'
LOCK = 'nebo.lock.json'
MANIFEST_SCHEMA = 'NEBO-PACKAGE-MANIFEST-v2'
LOCK_SCHEMA = 'NEBO-PACKAGE-LOCK-v2'
WORKSPACE_SCHEMA = 'NEBO-PACKAGE-WORKSPACE-v1'
MAX_FILE = 16 * 1024 * 1024
MAX_JSON = 64 * 1024
MAX_SOURCE = 4096  # Native interface owner bound, not a new parser limit.
ID = re.compile(r'[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*){1,7}')
VERSION = re.compile(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)')
HEX = re.compile(r'[0-9a-f]{64}')


class PackageError(ValueError):
    """Stable package diagnostic; native diagnostics remain attached."""


def require(condition, code):
    if not condition:
        raise PackageError('NEBO_PACKAGE_' + code)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(',', ':'), allow_nan=False) + '\n').encode()


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'DUPLICATE_FIELD')
        result[key] = value
    return result


def decode(raw):
    require(len(raw) <= MAX_JSON, 'JSON_BUDGET')
    try:
        return json.loads(raw, object_pairs_hook=unique,
                          parse_constant=lambda _: require(False, 'NONFINITE_JSON'))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as exc:
        raise PackageError('NEBO_PACKAGE_JSON') from exc


def fields(value, expected, code):
    require(type(value) is dict and set(value) == set(expected.split()), code)


def relative(value):
    require(isinstance(value, str) and 0 < len(value) <= 200, 'PATH')
    require(not any(c in value for c in ('\\', ':', '\x00')), 'PATH')
    parts = value.split('/')
    require(all(re.fullmatch(r'[A-Za-z0-9_.-]+', p) and p not in ('.', '..') for p in parts), 'PATH')
    require(not PurePosixPath(value).is_absolute(), 'PATH')
    return parts


def directory(path):
    """Explicit local root, with no symlink in any lexical component."""
    path = Path(os.path.abspath(path))
    current = Path(path.anchor)
    for part in path.parts[1:]:
        current /= part
        require(stat.S_ISDIR(current.lstat().st_mode), 'ROOT_NOT_DIRECTORY')
    return path


def open_directory(path):
    path = Path(os.path.abspath(path))
    fd = os.open('/', os.O_RDONLY | os.O_DIRECTORY)
    try:
        for part in path.parts[1:]:
            child = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd)
            fd = child
        return fd
    except BaseException:
        os.close(fd)
        raise


def read(root, name, limit=MAX_FILE):
    """Descriptor-relative traversal prevents intermediate symlink escapes."""
    parts = relative(name)
    fd = open_directory(root)
    try:
        for part in parts[:-1]:
            next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        leaf = os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
        try:
            info = os.fstat(leaf)
            require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1, 'NON_REGULAR_FILE')
            require(info.st_size <= limit, 'FILE_BUDGET')
            with os.fdopen(leaf, 'rb', closefd=False) as stream:
                raw = stream.read(limit + 1)
            require(len(raw) <= limit, 'FILE_BUDGET')
            return raw
        finally:
            os.close(leaf)
    finally:
        os.close(fd)


def write(root, name, raw):
    relative(name)
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(raw)
        os.fchmod(stream.fileno(), 0o644)


def version(value):
    require(isinstance(value, str) and len(value) <= 17 and VERSION.fullmatch(value), 'VERSION')
    result = tuple(map(int, value.split('.')))
    require(max(result) <= 65535, 'VERSION_BUDGET')
    return result


def satisfies(pin, requirement):
    actual = version(pin)
    require(isinstance(requirement, str), 'RANGE')
    prefix = requirement[:1] if requirement[:1] in ('^', '~') else ''
    low = version(requirement[len(prefix):])
    if not prefix:
        return actual == low
    if prefix == '~':
        high = (low[0], low[1] + 1, 0)
    elif low[0]:
        high = (low[0] + 1, 0, 0)
    elif low[1]:
        high = (0, low[1] + 1, 0)
    else:
        high = (0, 0, low[2] + 1)
    return low <= actual < high


def package_id(value):
    require(isinstance(value, str) and len(value) <= 100 and ID.fullmatch(value), 'IDENTITY')
    return value


def manifest(value):
    fields(value, 'schema package version edition targets source_roots modules dependencies capabilities features build_profiles target_packs metadata', 'MANIFEST_FIELDS')
    require(value['schema'] == MANIFEST_SCHEMA, 'MANIFEST_SCHEMA')
    package_id(value['package'])
    version(value['version'])
    require(value['edition'] == '1' and value['targets'] == [TARGET], 'TARGET_EDITION')
    require(value['features'] in (['interface-units'], ['source-units']), 'FEATURES')
    require(value['capabilities'] == [], 'CAPABILITIES')
    require(value['build_profiles'] == {'default': {'optimization': 'none'}}, 'BUILD_PROFILE')
    require(value['target_packs'] == [TARGET], 'TARGET_PACK')
    roots = value['source_roots']
    require(type(roots) is list and 1 <= len(roots) <= 3, 'SOURCE_ROOTS')
    for item in roots:
        relative(item)
        require(item.split('/')[0] != 'interfaces', 'RESERVED_SOURCE_ROOT')
    require(len(set(roots)) == len(roots), 'SOURCE_ROOTS')
    modules = value['modules']
    require(type(modules) is list and 1 <= len(modules) <= 3, 'MODULES')
    used_roots, logical, paths = set(), set(), set()
    for item in modules:
        fields(item, 'logical source', 'MODULE_FIELDS')
        relative(item['source'])
        require(isinstance(item['logical'], str) and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]{0,63}', item['logical']), 'MODULE_NAME')
        require(item['source'].endswith('.no'), 'SOURCE_SUFFIX')
        matches = [r for r in roots if item['source'].startswith(r + '/')]
        require(len(matches) == 1, 'SOURCE_ROOT_MEMBERSHIP')
        used_roots.update(matches)
        require(item['source'] not in paths and item['logical'] not in logical, 'DUPLICATE_MODULE')
        paths.add(item['source']); logical.add(item['logical'])
    require(used_roots == set(roots), 'UNUSED_SOURCE_ROOT')
    deps = value['dependencies']
    require(type(deps) is dict and len(deps) <= 2, 'DEPENDENCIES')
    for key, dep in deps.items():
        package_id(key)
        fields(dep, 'pin requirement', 'DEPENDENCY_FIELDS')
        require(satisfies(dep['pin'], dep['requirement']), 'RANGE_MISMATCH')
    metadata = value['metadata']
    require(type(metadata) is dict and len(metadata) <= 16, 'METADATA')
    require(all(isinstance(k, str) and isinstance(v, str) and len(k) <= 64 and len(v) <= 256 for k, v in metadata.items()), 'METADATA')
    return value


def graph(manifests, root):
    require(1 <= len(manifests) <= 3 and root in manifests, 'PACKAGE_GRAPH_BOUND')
    require(len({tuple(m['features']) for m in manifests.values()}) == 1, 'FEATURE_CONFLICT')
    state, order = {}, []

    def visit(pid):
        require(state.get(pid) != 1, 'DEPENDENCY_CYCLE')
        if state.get(pid) == 2:
            return
        state[pid] = 1
        for dep, constraint in sorted(manifests[pid]['dependencies'].items()):
            require(dep in manifests and manifests[dep]['version'] == constraint['pin'], 'UNRESOLVED_PIN')
            visit(dep)
        state[pid] = 2
        order.append(pid)

    visit(root)
    require(set(order) == set(manifests), 'UNREACHABLE_PACKAGE')
    return order


def toolchain():
    # These are executable/semantic inputs, not the changing repository HEAD.
    names = ['build/bin/neboc', 'build/tests/rf166/g154/interface_codec_probe',
             'build/obj/runtime_practical_io.o']
    names += [p.relative_to(ROOT).as_posix() for base in ('compiler/sdk', 'compiler/stdlib')
              for p in sorted((ROOT / base).glob('*.py'))]
    names += ['tools/' + n for n in ('rf27-package.py', 'rf204-g024.py', 'rf204-g027.py',
                                     'rf204-g048.py', 'rf204-g153.py', 'rf204-g154.py', 'rf204-g163.py')]
    # Catalogs pin public module identity/maturity; they grant no capabilities.
    names += ['sdk/contracts/PRELUDE-CONTRACT.json',
              'sdk/contracts/stdlib/STDLIB-API-ABI-MANIFEST.json',
              'sdk/interfaces/prelude/std.prelude.ni',
              'sdk/interfaces/prelude/stdlib-registry.json']
    result = {name: sha(read(ROOT, name)) for name in sorted(names)}
    for executable in ('/usr/bin/nasm', '/usr/bin/ld', '/usr/bin/python3'):
        # System tool aliases are trusted selections, never package inputs.
        # Pin both the resolved executable and alias identity used by the driver.
        p = Path(executable).resolve(strict=True)
        result[executable] = sha(os.fsencode(str(p)) + b'\0' + read(p.parent, p.name))
    return result


def native(arguments):
    try:
        result = subprocess.run([str(COMPILER), *map(str, arguments)], cwd=ROOT,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=20, check=False,
                                env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'LANG': 'C',
                                     'PYTHONDONTWRITEBYTECODE': '1', 'TZ': 'UTC',
                                     'HOME': str(ROOT)})
    except subprocess.TimeoutExpired as exc:
        raise PackageError('NEBO_PACKAGE_NATIVE_TIMEOUT') from exc
    require(len(result.stdout) + len(result.stderr) <= MAX_JSON, 'NATIVE_OUTPUT_BUDGET')
    require(result.returncode == 0, 'NATIVE: ' + result.stderr.decode('utf-8', 'replace').strip())
    return result.stdout


def arguments(entry, all_sources):
    return [entry, *sum((['--unit', source] for source in all_sources if source != entry), [])]


def materialize_sources(base, payloads):
    for pid, files in payloads.items():
        for name, raw in files.items():
            write(base, pid + '/' + name, raw)


def analyze(base, manifests, entry):
    """Join package identity to native ModuleId, graph, visibility and .ni."""
    all_modules = [(pid, m) for pid, value in sorted(manifests.items()) for m in value['modules']]
    require(len(all_modules) == 3, 'NATIVE_THREE_MODULE_BOUND')
    require(len({m['logical'] for _, m in all_modules}) == 3, 'LOGICAL_MODULE_COLLISION')
    sources = [base / pid / m['source'] for pid, m in all_modules]
    chosen = [p for p, (pid, m) in zip(sources, all_modules) if pid == entry['package'] and m['logical'] == entry['module']]
    require(len(chosen) == 1, 'ENTRY_MODULE')
    main = chosen[0]
    native(['module-check', *arguments(main, sources)])
    native_graph = decode(native(['module-graph', *arguments(main, sources), '--format', 'json']))
    ids, interfaces, infos = {}, {}, {}
    for source, (pid, module) in zip(sources, all_modules):
        info = dict(line.split('=', 1) for line in native(['module-info', *arguments(source, sources)]).decode().splitlines())
        require(info['module.logical'] == module['logical'], 'MODULE_IDENTITY_MISMATCH')
        require(info['graph.snapshot'] == str(native_graph['snapshot']), 'GRAPH_DRIFT')
        require(source == main or info['module.startRefs'] == '0', 'HIDDEN_INITIALIZATION')
        identity = int(info['module.id'])
        require(identity not in ids, 'MODULE_ID_COLLISION')
        ids[identity] = (pid, module['logical'])
        infos[module['logical']] = info
        target = base / pid / 'interfaces' / (module['logical'] + '.ni')
        target.parent.mkdir(exist_ok=True)
        native(['emit-interface', *arguments(source, sources), '-o', target])
        report = decode(native(['interface', 'inspect', target, '--json']))
        require(report['moduleId'] == identity and report['target'] == TARGET and report['edition'] == 1, 'INTERFACE_IDENTITY')
        require(not any(report['capabilities']) and not any(report['effects']), 'INTERFACE_CAPABILITY')
        interfaces[module['logical']] = {key: report[key] for key in
             ('moduleId', 'apiFingerprint', 'abiFingerprint', 'behaviorFingerprint', 'typedHirDigest', 'materialModuleValue', 'exports')}
        interfaces[module['logical']]['sha256'] = sha(read(target.parent, target.name))
    edges = {pid: set() for pid in manifests}
    for dependency, consumer in native_graph['links']:
        require(dependency in ids and consumer in ids, 'NATIVE_GRAPH')
        dep, owner = ids[dependency][0], ids[consumer][0]
        if dep != owner:
            edges[owner].add(dep)
    require(all(edges[pid] == set(m['dependencies']) for pid, m in manifests.items()), 'MODULE_PACKAGE_GRAPH_MISMATCH')
    module_order = [{'package': ids[n][0], 'module': ids[n][1]} for n in native_graph['order']]
    require(len(module_order) == 3 and len({n['module'] for n in module_order}) == 3, 'NATIVE_ORDER')
    return interfaces, module_order, main, sources


def workspace(path):
    path = Path(path)
    base = directory(path.parent)
    value = decode(read(base, path.name, MAX_JSON))
    fields(value, 'schema root entry members', 'WORKSPACE_FIELDS')
    require(value['schema'] == WORKSPACE_SCHEMA, 'WORKSPACE_SCHEMA')
    package_id(value['root'])
    fields(value['entry'], 'package module', 'ENTRY_FIELDS')
    require(value['entry']['package'] == value['root'], 'ENTRY_PACKAGE')
    require(type(value['members']) is list and 1 <= len(value['members']) <= 3, 'MEMBER_BOUND')
    payloads, manifests, locations = {}, {}, []
    for member in value['members']:
        relative(member)
        require(all(not (member == old or member.startswith(old + '/') or old.startswith(member + '/')) for old in locations), 'OVERLAPPING_MEMBERS')
        locations.append(member)
        m = manifest(decode(read(base, member + '/' + MANIFEST, MAX_JSON)))
        pid = m['package']
        require(pid not in manifests, 'DUPLICATE_PACKAGE')
        manifests[pid] = m
        files = {MANIFEST: canonical(m)}
        for mod in m['modules']:
            files[mod['source']] = read(base, member + '/' + mod['source'], MAX_SOURCE)
        payloads[pid] = files
    graph(manifests, value['root'])
    return value['root'], value['entry'], manifests, payloads


def destination(path):
    path = Path(os.path.abspath(path))
    directory(path.parent)
    require(not os.path.lexists(path), 'DESTINATION_EXISTS')
    return path


def publish(source, target):
    """Linux atomic no-replace publication, including a concurrently made root."""
    source_fd, target_fd = open_directory(source.parent), open_directory(target.parent)
    try:
        libc = ctypes.CDLL(None, use_errno=True)
        rename = libc.renameat2
        rename.argtypes = (ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint)
        rename.restype = ctypes.c_int
        result = rename(source_fd, os.fsencode(source.name), target_fd, os.fsencode(target.name), 1)
        if result != 0:
            raise OSError(ctypes.get_errno(), 'package publication failed')
        try:
            os.fsync(target_fd)
        except OSError:
            os.rename(target.name, source.name, src_dir_fd=target_fd, dst_dir_fd=source_fd)
            raise
    finally:
        os.close(source_fd); os.close(target_fd)


def cache_key(lock):
    return sha(canonical({k: v for k, v in lock.items() if k != 'cache_key'}))


def freeze(workspace_path, store):
    """Resolve explicit workspace pins and publish one complete immutable store."""
    store = destination(store)
    root, entry, manifests, payloads = workspace(workspace_path)
    provenance = toolchain()
    with tempfile.TemporaryDirectory(prefix='.nebo-package-', dir=store.parent) as raw:
        scratch = Path(raw)
        source_root = scratch / 'sources'
        materialize_sources(source_root, payloads)
        interfaces, order, _, _ = analyze(source_root, manifests, entry)
        published = scratch / 'published'
        published.mkdir()
        packages = []
        for pid, m in sorted(manifests.items()):
            files = dict(payloads[pid])
            ni = {}
            for module in m['modules']:
                name = 'interfaces/' + module['logical'] + '.ni'
                files[name] = read(source_root / pid, name)
                ni[module['logical']] = interfaces[module['logical']]
            hashes = {n: sha(b) for n, b in sorted(files.items())}
            content = sha(canonical(hashes))
            prefix = f'packages/{pid}/{m["version"]}/{content}/'
            for name, data in files.items():
                write(published, prefix + name, data)
            packages.append({'id': pid, 'version': m['version'], 'content_sha256': content,
                             'files': hashes, 'interfaces': ni,
                             'dependencies': sorted(m['dependencies'])})
        lock = {'schema': LOCK_SCHEMA, 'root': root, 'entry': entry, 'edition': '1', 'target': TARGET,
                'features': manifests[root]['features'], 'toolchain': provenance,
                'packages': packages, 'package_order': graph(manifests, root), 'module_order': order}
        lock['cache_key'] = cache_key(lock)
        require(provenance == toolchain(), 'TOOLCHAIN_CHANGED')
        write(published, LOCK, canonical(lock))
        require(not os.path.lexists(store), 'DESTINATION_EXISTS')
        publish(published, store)
    return {'lock_sha256': sha(canonical(lock)), 'cache_key': lock['cache_key'], 'packages': len(packages)}


def load_store(store, lock_raw, expected_sha256):
    """Pin the caller's lock before resolving any package path."""
    require(isinstance(expected_sha256, str) and HEX.fullmatch(expected_sha256) and sha(lock_raw) == expected_sha256, 'LOCK_INTEGRITY')
    lock = decode(lock_raw)
    fields(lock, 'schema root entry edition target features toolchain packages package_order module_order cache_key', 'LOCK_FIELDS')
    require(lock['schema'] == LOCK_SCHEMA and canonical(lock) == lock_raw, 'LOCK_SCHEMA_CANONICAL')
    require(lock['edition'] == '1' and lock['target'] == TARGET, 'LOCK_TARGET_EDITION')
    require(lock['cache_key'] == cache_key(lock), 'STALE_CACHE_KEY')
    require(lock['toolchain'] == toolchain(), 'STALE_TOOLCHAIN')
    package_id(lock['root'])
    fields(lock['entry'], 'package module', 'ENTRY_FIELDS')
    require(lock['entry']['package'] == lock['root'], 'ENTRY_PACKAGE')
    require(type(lock['packages']) is list and 1 <= len(lock['packages']) <= 3, 'LOCK_PACKAGE_BOUND')
    payloads, manifests = {}, {}
    for row in lock['packages']:
        fields(row, 'id version content_sha256 files interfaces dependencies', 'LOCK_PACKAGE_FIELDS')
        pid = package_id(row['id']); version(row['version'])
        require(pid not in payloads, 'DUPLICATE_PACKAGE')
        require(isinstance(row['content_sha256'], str) and HEX.fullmatch(row['content_sha256']), 'CONTENT_HASH')
        hashes = row['files']
        require(type(hashes) is dict and 3 <= len(hashes) <= 7, 'LOCK_FILE_BOUND')
        require(sha(canonical(hashes)) == row['content_sha256'], 'CONTENT_HASH')
        prefix = f'packages/{pid}/{row["version"]}/{row["content_sha256"]}/'
        files = {}
        for name, digest in hashes.items():
            relative(name)
            require(isinstance(digest, str) and HEX.fullmatch(digest), 'FILE_HASH')
            data = read(store, prefix + name, MAX_SOURCE if name.endswith('.no') else MAX_JSON)
            require(sha(data) == digest, 'CORRUPT_STORE')
            files[name] = data
        require(MANIFEST in files, 'MISSING_MANIFEST')
        m = manifest(decode(files[MANIFEST]))
        require(files[MANIFEST] == canonical(m), 'MANIFEST_CANONICAL')
        require(m['package'] == pid and m['version'] == row['version'], 'LOCK_MANIFEST_IDENTITY')
        expected_files = {MANIFEST} | {mod['source'] for mod in m['modules']} | {'interfaces/' + mod['logical'] + '.ni' for mod in m['modules']}
        require(set(files) == expected_files, 'PACKAGE_FILE_SET')
        require(row['dependencies'] == sorted(m['dependencies']), 'LOCK_DEPENDENCIES')
        require(m['features'] == lock['features'], 'FEATURE_CONFLICT')
        payloads[pid] = files; manifests[pid] = m
    require([p['id'] for p in lock['packages']] == sorted(manifests), 'LOCK_PACKAGE_ORDER')
    require(lock['package_order'] == graph(manifests, lock['root']), 'PACKAGE_ORDER')
    return lock, manifests, payloads


def verify_native(base, lock, manifests, payloads):
    sources = {pid: {n: b for n, b in files.items() if not n.startswith('interfaces/')} for pid, files in payloads.items()}
    materialize_sources(base, sources)
    interfaces, order, main, all_sources = analyze(base, manifests, lock['entry'])
    require(order == lock['module_order'], 'MODULE_ORDER')
    for row in lock['packages']:
        pid = row['id']
        expected = {mod['logical']: interfaces[mod['logical']] for mod in manifests[pid]['modules']}
        require(row['interfaces'] == expected, 'INTERFACE_FINGERPRINT')
        for mod in manifests[pid]['modules']:
            name = 'interfaces/' + mod['logical'] + '.ni'
            require(read(base / pid, name) == payloads[pid][name], 'STALE_INTERFACE')
    require(lock['toolchain'] == toolchain(), 'TOOLCHAIN_CHANGED')
    return main, all_sources


def verify(store, lock_raw, expected_sha256):
    lock, manifests, payloads = load_store(store, lock_raw, expected_sha256)
    with tempfile.TemporaryDirectory(prefix='nebo-package-verify-') as raw:
        verify_native(Path(raw), lock, manifests, payloads)
    return {'packages': len(manifests), 'cache_key': lock['cache_key'], 'lock_sha256': expected_sha256}


def restore(store, lock_raw, expected_sha256, output, *, build=False):
    output = destination(output)
    lock, manifests, payloads = load_store(store, lock_raw, expected_sha256)
    with tempfile.TemporaryDirectory(prefix='.nebo-package-', dir=output.parent) as raw:
        published = Path(raw) / 'project'
        published.mkdir()
        main, sources = verify_native(published / 'packages', lock, manifests, payloads)
        write(published, LOCK, lock_raw)
        result = {'packages': len(manifests), 'cache_key': lock['cache_key'], 'lock_sha256': expected_sha256}
        if build:
            # NI carries material exports; both modes use the normal native linker.
            units = []
            for source in sources:
                if source == main:
                    continue
                pid = source.relative_to(published / 'packages').parts[0]
                mod = next(m for m in manifests[pid]['modules'] if published / 'packages' / pid / m['source'] == source)
                units.append(source if lock['features'] == ['source-units'] else
                             published / 'packages' / pid / 'interfaces' / (mod['logical'] + '.ni'))
            binary = published / 'bin/program'
            binary.parent.mkdir()
            native(['build', main, *sum((['--unit', u] for u in units), []), '-o', binary])
            data = read(binary.parent, binary.name)
            require(data.startswith(b'\x7fELF\x02\x01'), 'NON_NATIVE_ARTIFACT')
            result['elf_sha256'] = sha(data)
            write(published, 'build.json', canonical(result))
        # Restored modes are part of cold/warm identity, independent of umask.
        for path in published.rglob('*'):
            if path.is_file():
                path.chmod(0o755 if path == published / 'bin/program' else 0o644)
        require(lock['toolchain'] == toolchain(), 'TOOLCHAIN_CHANGED')
        require(not os.path.lexists(output), 'DESTINATION_EXISTS')
        publish(published, output)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(prog='neboc package')
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('freeze'); p.add_argument('workspace', type=Path); p.add_argument('--store', type=Path, required=True)
    for command in ('verify', 'restore', 'build'):
        p = sub.add_parser(command)
        p.add_argument('--store', type=Path, required=True)
        p.add_argument('--lock', type=Path, required=True)
        p.add_argument('--lock-sha256', required=True)
        if command != 'verify':
            p.add_argument('--output', type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == 'freeze':
            result = freeze(args.workspace, args.store)
        else:
            raw = read(args.lock.parent, args.lock.name, MAX_JSON)
            if args.command == 'verify':
                result = verify(args.store, raw, args.lock_sha256)
            else:
                result = restore(args.store, raw, args.lock_sha256, args.output, build=args.command == 'build')
    except (OSError, PackageError, KeyError, TypeError, OverflowError) as exc:
        diagnostic = str(exc) if isinstance(exc, PackageError) else 'NEBO_PACKAGE_INPUT: ' + str(exc)
        print(canonical({'diagnostic': diagnostic, 'result': 'REJECT'}).decode(), end='', file=sys.stderr)
        return 3
    print(canonical(result).decode(), end='')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
