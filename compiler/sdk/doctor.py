"""Read-only, bounded local diagnostics; output contains registered statuses only."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import sys
import uuid
from compiler.sdk import install_io as io, package_manager as packages
from compiler.sdk.sdk_builder import TARGET, verify_bundle
from compiler.sdk.sdk_lifecycle import verify_install

REGISTRY = (
 ('sdk.integrity',True), ('compiler.neboc',True), ('toolchain.nasm',True),
 ('toolchain.ld',True), ('toolchain.python3',True), ('targets.host',True),
 ('permissions.prefix',True), ('display.x11',False), ('packages.integrity',False),
 ('network.external',False),
)

def diagnose(root, *, package_store=None, package_lock=None, lock_sha256=None):
    root = Path(root).absolute(); checks = []
    def check(ident, status, required=None):
        required = dict(REGISTRY)[ident] if required is None else required
        checks.append(dict(id=ident,status=status,ok=status=='OK',required=required))
    try:
        fd = packages.open_directory(root)
        try:
            try: io.read(fd,'.nebo-sdk/install-manifest.json',io.META_LIMIT); installed=True
            except FileNotFoundError: installed=False
        finally: os.close(fd)
        verify_install(root) if installed else verify_bundle(root)
        check('sdk.integrity','OK')
    except (ValueError,OSError): check('sdk.integrity','CORRUPT_OR_MISSING')
    try:
        fd=packages.open_directory(root)
        try:
            raw,mode=io.read(fd,'build/bin/neboc')
            launcher,launch_mode=io.read(fd,'bin/neboc')
        finally: os.close(fd)
        valid=raw[:7]==b'\x7fELF\x02\x01\x01' and len(raw)>64 and raw[18:20]==b'>\x00' and mode==0o755 and launch_mode==0o755 and bool(launcher)
        check('compiler.neboc','OK' if valid else 'INVALID_EXECUTABLE')
    except (OSError,ValueError): check('compiler.neboc','CORRUPT_OR_MISSING')
    try:
        fd=packages.open_directory(root)
        try: provenance=io.decode(io.read(fd,'PROVENANCE.json',io.META_LIMIT)[0])
        finally: os.close(fd)
        fingerprints={t['name']:t['sha256'] for t in provenance['tools']}
    except (ValueError,OSError,KeyError,TypeError): fingerprints={}
    for name in ('nasm','ld','python3'):
        path=shutil.which(name)
        # Authenticate against the packaged build fingerprint without executing PATH.
        status='MISSING_EXECUTABLE'
        try:
            if path and os.access(path,os.X_OK):
                binary=Path(path).resolve()
                raw=packages.read(binary.parent,binary.name,64*1024*1024)
                status='OK' if hashlib.sha256(raw).hexdigest()==fingerprints.get(name) else 'FINGERPRINT_MISMATCH'
        except (OSError,ValueError): status='UNSAFE_EXECUTABLE'
        check('toolchain.'+name,status)
    try:
        fd=packages.open_directory(root)
        try:
            raw,_=io.read(fd,'sdk/nebo-1.0/targets/linux-x86_64.json',65536)
        finally: os.close(fd)
        target=io.decode(raw)
        valid=target.get('id')==TARGET and target.get('link')=='static' and target.get('abi')=='System V AMD64' and platform.system()=='Linux' and platform.machine()=='x86_64'
        check('targets.host','OK' if valid else 'UNSUPPORTED_TARGET')
    except (OSError,ValueError,AttributeError): check('targets.host','CORRUPT_OR_MISSING')
    try:
        fd=packages.open_directory(root)
        try: info=os.fstat(fd)
        finally: os.close(fd)
        valid=info.st_uid==os.geteuid() and not info.st_mode & 0o022 and bool(info.st_mode & 0o500 == 0o500)
        check('permissions.prefix','OK' if valid else 'UNSAFE_PERMISSIONS')
    except (OSError,ValueError): check('permissions.prefix','INACCESSIBLE')
    display=os.environ.get('DISPLAY','')
    check('display.x11','NOT_CONFIGURED' if not display else 'CONFIGURED_UNPROBED' if re.fullmatch(r':\d{1,4}(?:\.\d{1,2})?',display) else 'UNSUPPORTED_DISPLAY')
    package_probe_attempted=False
    if any(x is not None for x in (package_store,package_lock,lock_sha256)):
        try:
            if not all(x is not None for x in (package_store,package_lock,lock_sha256)): raise ValueError('incomplete package probe')
            raw=packages.read(Path(package_lock).absolute().parent,Path(package_lock).name,packages.MAX_JSON)
            package_probe_attempted=True
            packages.verify(Path(package_store),raw,lock_sha256)
            check('packages.integrity','OK',True)
        except (OSError,ValueError): check('packages.integrity','CORRUPT_OR_MISSING',True)
    else: check('packages.integrity','NOT_REQUESTED')
    check('network.external','NOT_USED')
    return dict(schema=1,command='doctor',format='NEBO-DOCTOR-v1',sdk_root='<SDK_ROOT>',checks=checks,redacted=True,external_network_used=False,
                status='OK' if all(c['ok'] for c in checks if c['required']) else 'DEGRADED',
                display_connection_attempted=False,toolchain_execution_attempted=package_probe_attempted)

def main(argv=None):
    p=argparse.ArgumentParser(prog='neboc doctor')
    p.add_argument('--sdk-root',type=Path,default=Path(__file__).resolve().parents[2])
    p.add_argument('--output',type=Path);p.add_argument('--package-store',type=Path)
    p.add_argument('--package-lock',type=Path);p.add_argument('--lock-sha256')
    a=p.parse_args(argv)
    report=diagnose(a.sdk_root,package_store=a.package_store,package_lock=a.package_lock,lock_sha256=a.lock_sha256)
    raw=(json.dumps(report,sort_keys=True,indent=2)+'\n').encode()
    if a.output:
        try:
            output=a.output.absolute();fd=packages.open_directory(output.parent)
            temporary='.nebo-doctor-'+uuid.uuid4().hex
            try:
                io.write(fd,temporary,raw,0o600)
                os.link(temporary,output.name,src_dir_fd=fd,dst_dir_fd=fd,follow_symlinks=False)
            finally:
                try: io.unlink(fd,temporary)
                except FileNotFoundError: pass
                os.close(fd)
        except (ValueError,OSError):
            print(json.dumps({'diagnostic':'NEBO-DOCTOR-0001','status':'OUTPUT_REJECTED'}),file=sys.stderr);return 2
    sys.stdout.buffer.write(raw)
    return 0 if report['status']=='OK' else 3

if __name__=='__main__': raise SystemExit(main())
