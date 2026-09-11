#!/usr/bin/env python3
"""Create a project from the selected SDK without ambient fallback."""
from __future__ import annotations
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from compiler.sdk import install_io as io
from compiler.sdk import package_manager as safe

@contextmanager
def directory(path):
    fd = safe.open_directory(path)
    try: yield fd
    finally: os.close(fd)

def create(sdk: Path, output: Path):
    with directory(sdk) as root:
        manifest_raw, _ = io.read(root, 'sdk/nebo-1.0/templates/hello/MANIFEST.json', 16384)
        manifest = io.decode(manifest_raw)
        if set(manifest) != {'format', 'files'} or manifest['format'] != 'NEBO-TEMPLATE-v1':
            raise ValueError('NEBO-NEW-0002 invalid template manifest')
        rows = manifest['files']
        if not isinstance(rows, list) or len(rows) != 2:
            raise ValueError('NEBO-NEW-0002 template inventory')
        files = {}
        for row in rows:
            if set(row) != {'path','sha256'} or row['path'] not in {'main.nebo','nebo.project.json'} or row['path'] in files:
                raise ValueError('NEBO-NEW-0002 template entry')
            raw, _ = io.read(root, 'sdk/nebo-1.0/templates/hello/'+row['path'], 65536)
            if hashlib.sha256(raw).hexdigest() != row['sha256']:
                raise ValueError('NEBO-NEW-0003 template integrity')
            files[row['path']] = raw
    output = output.absolute()
    if output.name in {'', '.', '..'}: raise ValueError('NEBO-NEW-0001 destination')
    # The caller owns the existing parent; no intermediate paths are created.
    with directory(output.parent) as parent:
        stage = Path(tempfile.mkdtemp(prefix='.nebo-new-', dir=output.parent))
        try:
            with directory(stage) as destination:
                for name, raw in sorted(files.items()):
                    io.write(destination, 'main.no' if name == 'main.nebo' else name, raw)
                os.fsync(destination)
            io.publish(parent, stage.name, output.name)
        finally:
            if stage.exists(): shutil.rmtree(stage)
    return {'project': str(output), 'network_used': False, 'files': ['main.no','nebo.project.json']}

def main():
    parser = argparse.ArgumentParser(prog='nebo-new', description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--sdk-root', type=Path, default=ROOT)
    args = parser.parse_args()
    try: print(json.dumps(create(args.sdk_root, args.output), sort_keys=True))
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('NEBO-NEW: '+str(error), file=sys.stderr); return 2
    return 0

if __name__ == '__main__': raise SystemExit(main())
