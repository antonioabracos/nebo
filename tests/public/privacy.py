"""Fail-closed privacy checks for explicit public files and archive members.

Findings identify the file and category without printing matched secret bytes.
Caller-supplied private roots are additional deny patterns, never exceptions.
"""
import argparse
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import tarfile
import zipfile

MAX_FILE = 128 * 1024 * 1024
MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_MEMBERS = 20000
MAX_DEPTH = 3


class ScanError(ValueError):
    pass


HOME_PATH = re.compile(rb"""/(?:home|Users)/[^/\x00\r\n"'<>]+(?:/|(?=["'<>\r\n\x00]|$))""")
WINDOWS_HOME = re.compile(rb'[A-Za-z]:(?:\\{1,2}|/)Users(?:\\{1,2}|/)[^\\/\x00\r\n:"<>|]+(?:\\{1,2}|/)', re.IGNORECASE)
INTERNAL_MARKERS = tuple(x.encode() for x in (
    'Nebo' + '_Control', 'Nebo' + '_src', 'Nebolys' + '-Backups',
    'refs' + '/archive',
))
INTERNAL_BRANCH = re.compile(rb'\bfeat/nebo-g[0-9]{3}-g[0-9]{3}[^\s\x00]*')
DATED_TEMP = re.compile(rb'/(?:tmp|var/tmp)/[^\s\x00"\x27<>]*[0-9]{8}T[0-9]{6}Z[^\s\x00"\x27<>]*')
CREDENTIAL = re.compile(
    rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----'
    rb'|github_pat_[A-Za-z0-9_]{30,}|gh[pousr]_[A-Za-z0-9]{30,}'
    rb'|AKIA[0-9A-Z]{16}|https?://[^/\s:@]+:[^/\s@]+@'
)


def relative(name):
    if not isinstance(name, str) or not name or '\\' in name or '\x00' in name:
        raise ScanError('INVALID_PATH')
    path = PurePosixPath(name)
    if path.is_absolute() or str(path) != name or any(p in {'.', '..', '.git'} for p in path.parts):
        raise ScanError('INVALID_PATH')
    return path


def inspect_content(data, name, private_paths=(), depth=0, budget=None):
    if budget is None:
        budget = [0, 0]
    for pattern in (HOME_PATH, WINDOWS_HOME, INTERNAL_BRANCH, DATED_TEMP):
        if pattern.search(data):
            raise ScanError('PRIVATE_PATH: ' + name)
    if any(marker in data for marker in INTERNAL_MARKERS):
        raise ScanError('INTERNAL_REFERENCE: ' + name)
    if any(value.encode() in data for value in private_paths):
        raise ScanError('CONFIGURED_PRIVATE_PATH: ' + name)
    if CREDENTIAL.search(data):
        raise ScanError('CREDENTIAL_PATTERN: ' + name)
    archive_kind = 'zip' if data.startswith(b'PK\x03\x04') or name.endswith('.zip') else 'tar' if name.endswith(('.tar', '.tar.gz', '.tgz', '.tar.xz', '.tar.bz2')) or data[257:262] == b'ustar' else None
    if archive_kind is None:
        return
    if depth >= MAX_DEPTH:
        raise ScanError('ARCHIVE_DEPTH: ' + name)

    def member(member_name, size, read):
        relative(member_name)
        if size < 0 or size > MAX_FILE:
            raise ScanError('ARCHIVE_MEMBER_SIZE: ' + name)
        budget[0] += 1
        budget[1] += size
        if budget[0] > MAX_MEMBERS or budget[1] > MAX_ARCHIVE_BYTES:
            raise ScanError('ARCHIVE_LIMIT: ' + name)
        raw = read(MAX_FILE + 1)
        if len(raw) != size:
            raise ScanError('ARCHIVE_MEMBER_READ: ' + name)
        inspect_content(raw, name + '!' + member_name, private_paths, depth + 1, budget)

    members_before = budget[0]
    try:
        seen = set()
        if archive_kind == 'zip':
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                for info in archive.infolist():
                    relative(info.filename.rstrip('/'))
                    if info.filename in seen or info.flag_bits & 1:
                        raise ScanError('ARCHIVE_DUPLICATE_OR_ENCRYPTED: ' + name)
                    seen.add(info.filename)
                    mode = info.external_attr >> 16
                    if stat.S_ISLNK(mode) or (stat.S_IFMT(mode) and not (stat.S_ISREG(mode) or stat.S_ISDIR(mode))):
                        raise ScanError('ARCHIVE_SPECIAL_FILE: ' + name)
                    if info.is_dir():
                        continue
                    with archive.open(info) as stream:
                        member(info.filename, info.file_size, stream.read)
        else:
            with tarfile.open(fileobj=io.BytesIO(data), mode='r:*') as archive:
                for info in archive:
                    relative(info.name.rstrip('/'))
                    if info.name in seen:
                        raise ScanError('ARCHIVE_DUPLICATE: ' + name)
                    seen.add(info.name)
                    if info.isdir():
                        continue
                    if not info.isfile():
                        raise ScanError('ARCHIVE_SPECIAL_FILE: ' + name)
                    with archive.extractfile(info) as stream:
                        member(info.name, info.size, stream.read)
        if budget[0] == members_before:
            raise ScanError('EMPTY_ARCHIVE: ' + name)
    except (OSError, EOFError, RuntimeError, tarfile.TarError, zipfile.BadZipFile, NotImplementedError) as error:
        raise ScanError('ARCHIVE_READ_ERROR: ' + name) from error


def scan_files(root, names, private_paths=()):
    root = Path(root).resolve(strict=True)
    names = list(names)
    if not names or len(names) != len(set(names)):
        raise ScanError('EMPTY_OR_DUPLICATE_INPUT')
    if any(not isinstance(value, str) or not value for value in private_paths):
        raise ScanError('INVALID_PRIVATE_PATH_CONFIGURATION')
    total = 0
    for name in names:
        path = root / relative(name)
        for parent in path.parents:
            if parent == root:
                break
            if parent.is_symlink():
                raise ScanError('SYMLINK_PARENT: ' + name)
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        try:
            before = os.fstat(fd)
            if not stat.S_ISREG(before.st_mode) or not before.st_mode & 0o444:
                raise ScanError('UNREADABLE_OR_SPECIAL_FILE: ' + name)
            if before.st_size > MAX_FILE:
                raise ScanError('FILE_LIMIT: ' + name)
            with os.fdopen(fd, 'rb', closefd=False) as stream:
                data = stream.read(MAX_FILE + 1)
            after = os.fstat(fd)
            if len(data) != before.st_size or (before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (after.st_size, after.st_mtime_ns, after.st_ctime_ns):
                raise ScanError('FILE_CHANGED_DURING_SCAN: ' + name)
        finally:
            os.close(fd)
        inspect_content(data, name, private_paths)
        total += len(data)
    if not total:
        raise ScanError('EMPTY_CONTENT')
    return {'status': 'PASS', 'files': len(names), 'bytes': total, 'private_paths': 0, 'credential_patterns': 0}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--forbid-path', action='append', default=[])
    parser.add_argument('paths', nargs='+')
    args = parser.parse_args()
    try:
        result = scan_files(args.root, args.paths, args.forbid_path)
    except (OSError, ValueError) as error:
        print(json.dumps({'status': 'FAIL', 'category': type(error).__name__, 'detail': str(error)}))
        return 1
    print(json.dumps(result))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
