"""Bounded descriptor-relative filesystem operations for the local installer."""
from contextlib import contextmanager
import ctypes
import hashlib
import json
import os
from pathlib import Path
import stat
from compiler.sdk import package_manager as safe
from compiler.sdk.sdk_builder import MAX_FILE, MAX_FILES, MAX_BYTES, unique

META_LIMIT = 16 * 1024 * 1024
MAX_ENTRIES = 4 * MAX_FILES + 128

def error(code, message):
    return ValueError('NEBO-INSTALL-' + code + ' ' + message)

def decode(raw):
    if len(raw) > META_LIMIT:
        raise error('0005', 'manifest budget')
    try:
        return json.loads(raw, object_pairs_hook=unique,
                          parse_constant=lambda _: (_ for _ in ()).throw(error('0005', 'nonfinite JSON')))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as e:
        raise error('0005', 'manifest JSON') from e

@contextmanager
def parent(root, name, create=False, made=None):
    parts = safe.relative(name)
    fd = os.dup(root)
    try:
        current = []
        for part in parts[:-1]:
            current.append(part)
            if create:
                try:
                    os.mkdir(part, 0o755, dir_fd=fd)
                    if made is not None: made.append('/'.join(current))
                except FileExistsError: pass
            child = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd); fd = child
        yield fd, parts[-1]
    finally:
        os.close(fd)

def read(root, name, limit=MAX_FILE):
    with parent(root, name) as (fd, leaf):
        f = os.open(leaf, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
        try:
            info = os.fstat(f)
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_size > limit:
                raise error('0006', 'nonregular, linked or oversized component')
            with os.fdopen(f, 'rb', closefd=False) as stream: raw = stream.read(limit + 1)
            if len(raw) > limit: raise error('0006', 'component budget')
            return raw, info.st_mode & 0o7777
        finally: os.close(f)

def write(root, name, raw, mode=0o644, made=None):
    with parent(root, name, create=True, made=made) as (fd, leaf):
        f = os.open(leaf, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, mode, dir_fd=fd)
        try:
            with os.fdopen(f, 'wb', closefd=False) as stream:
                stream.write(raw); stream.flush(); os.fchmod(f, mode); os.fsync(f)
        finally: os.close(f)

def unlink(root, name):
    with parent(root, name) as (fd, leaf): os.unlink(leaf, dir_fd=fd)

def rename(source, name, destination, target):
    with parent(source, name) as (s, a), parent(destination, target, create=True) as (d, b):
        os.replace(a, b, src_dir_fd=s, dst_dir_fd=d)

def publish(parent_fd, stage, target):
    libc = ctypes.CDLL(None, use_errno=True)
    result = libc.renameat2(parent_fd, os.fsencode(stage), parent_fd, os.fsencode(target), 1)
    if result:
        number = ctypes.get_errno()
        raise OSError(number, 'NEBO-INSTALL-0003 activation collision or failure')
    try:
        os.fsync(parent_fd)
    except OSError:
        # A reported activation failure must not leave an active installation.
        os.rename(target, stage, src_dir_fd=parent_fd, dst_dir_fd=parent_fd)
        raise

def exchange(parent_fd, left, right):
    """Swap complete sibling directories without an absent active pathname."""
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.renameat2(parent_fd, os.fsencode(left), parent_fd, os.fsencode(right), 2):
        raise OSError(ctypes.get_errno(), 'NEBO-INSTALL-0018 atomic exchange failed')
    try:
        os.fsync(parent_fd)
    except OSError:
        if libc.renameat2(parent_fd, os.fsencode(left), parent_fd, os.fsencode(right), 2):
            raise error('0018', 'exchange recovery failed')
        raise

def matches(raw, mode, row):
    return len(raw) == row['size'] and hashlib.sha256(raw).hexdigest() == row['sha256'] and mode == int(row['mode'], 8)

def sync_directories(root, files):
    """Persist newly staged directory entries before the active rename."""
    directories={str(p) for name in files for p in Path(name).parents if str(p)!='.'}
    for name in sorted(directories,key=lambda n:(-n.count('/'),n)):
        with parent(root,name) as (fd,leaf):
            child=os.open(leaf,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW,dir_fd=fd)
            try: os.fsync(child)
            finally: os.close(child)
    os.fsync(root)

def rows(value):
    import re
    if type(value) is not list or not 1 <= len(value) <= MAX_FILES + 1:
        raise error('0005', 'owned rows budget')
    seen = set(); directories = {'.nebo-sdk'}; size = 0
    for row in value:
        if type(row) is not dict or not {'path','size','sha256','mode'} <= set(row) or set(row) - {'path','size','sha256','mode','role','component'}:
            raise error('0005', 'owned row schema')
        try: parts = safe.relative(row['path'])
        except ValueError as e: raise error('0001', 'unsafe owned path') from e
        if len(parts)>64: raise error('0005', 'owned depth budget')
        name = row['path']
        if name in seen or name == '.nebo-sdk' or name.startswith('.nebo-sdk/'):
            raise error('0005', 'duplicate or reserved owned path')
        if type(row['size']) is not int or not 0 <= row['size'] <= MAX_FILE or row['mode'] not in ('0644','0755') or not isinstance(row['sha256'],str) or not re.fullmatch('[0-9a-f]{64}',row['sha256']):
            raise error('0005', 'owned field type or bound')
        if any(not isinstance(row[k],str) or len(row[k]) > 100 for k in ('role','component') if k in row):
            raise error('0005', 'owned metadata')
        seen.add(name); size += row['size']
        directories.update('/'.join(parts[:i]) for i in range(1,len(parts)))
        if len(seen)+len(directories)+1>MAX_ENTRIES:
            raise error('0005', 'owned tree entry budget')
    if size > MAX_BYTES + META_LIMIT: raise error('0005', 'installation byte budget')
    if any(str(p) in seen for name in seen for p in Path(name).parents if str(p) != '.'):
        raise error('0005', 'file directory collision')
    return value

def prune(root, names):
    for name in sorted(set(names), key=lambda p: (-p.count('/'), p)):
        try:
            with parent(root, name) as (fd, leaf): os.rmdir(leaf, dir_fd=fd)
        except OSError: pass

def inventory(root):
    """Report paths without following links, including empty directories."""
    result = []; count = 0
    def visit(fd, base, depth=0):
        nonlocal count
        if depth > 64: raise error('0015', 'leftover depth budget')
        with os.scandir(fd) as entries:
            names=[]
            for entry in entries:
                count += 1
                if count > MAX_ENTRIES: raise error('0015', 'leftover inventory budget')
                names.append(entry.name)
        for name in sorted(names):
            rel = base + name
            info = os.stat(name, dir_fd=fd, follow_symlinks=False)
            if stat.S_ISDIR(info.st_mode):
                child = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
                try:
                    with os.scandir(child) as entries: empty = next(entries, None) is None
                    if empty: result.append(rel + '/')
                    else: visit(child, rel + '/', depth+1)
                finally: os.close(child)
            else: result.append(rel)
            if len(result) > MAX_ENTRIES: raise error('0015', 'leftover inventory budget')
    visit(root, '')
    return result
