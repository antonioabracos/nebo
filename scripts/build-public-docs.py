#!/usr/bin/env python3
"""Create the deterministic offline documentation artifact from public inputs."""
import argparse
import hashlib
import io
from pathlib import Path
import tarfile

ROOT = Path(__file__).resolve().parents[1]

def build(root):
    docs = root / 'docs/public/v1.0'
    output = docs / 'offline-site'
    output.mkdir(exist_ok=True)
    archive = output / 'nebo-docs-v1.0.tar'
    members = sorted(p for p in docs.rglob('*') if p.is_file() and not p.is_relative_to(output))
    assert members and not any(p.is_symlink() for p in members)
    with tarfile.open(archive, 'w', format=tarfile.USTAR_FORMAT) as bundle:
        for path in members:
            data = path.read_bytes()
            item = tarfile.TarInfo(path.relative_to(docs).as_posix())
            item.size = len(data)
            item.mode = 0o644
            item.mtime = item.uid = item.gid = 0
            item.uname = item.gname = ''
            bundle.addfile(item, io.BytesIO(data))
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / 'ARCHIVE-SHA256').write_text(digest + '  ' + archive.name + '\n')
    print('PUBLIC_OFFLINE_DOCS=PASS files=' + str(len(members)) + ' sha256=' + digest)
    return archive

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=ROOT)
    build(parser.parse_args().root.resolve())
