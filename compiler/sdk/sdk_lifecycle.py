#!/usr/bin/env python3
"""Transactional local SDK lifecycle; offline, no-root and manifest-owned."""
from __future__ import annotations
import argparse, hashlib, json, os, shutil, tempfile
from contextlib import contextmanager
from pathlib import Path, PurePosixPath
from compiler.sdk.sdk_builder import verify_bundle

INSTALL_FORMAT="NEBO-INSTALL-MANIFEST-v1"
def sha(path: Path) -> str: return hashlib.sha256(path.read_bytes()).hexdigest()
def safe_rel(value: str) -> PurePosixPath:
    p=PurePosixPath(value)
    if p.is_absolute() or not p.parts or any(x in {"",".",".."} for x in p.parts): raise ValueError("NEBO-INSTALL-0001 unsafe path")
    return p
def _manifest(prefix: Path) -> Path: return prefix/".nebo-sdk/install-manifest.json"
@contextmanager
def exclusive(prefix: Path):
    lock=prefix.parent/("."+prefix.name+".nebo-lock")
    try: lock.mkdir(parents=False)
    except FileExistsError: raise RuntimeError("NEBO-INSTALL-0002 concurrent operation")
    try: yield
    finally: lock.rmdir()
def _copy_bundle(source: Path, stage: Path) -> dict:
    source_manifest=verify_bundle(source); rows=[]
    for row in source_manifest["files"]:
        rel=safe_rel(row["path"]); src=source/rel; dst=stage/rel; dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(src,dst); dst.chmod(int(row["mode"],8)); rows.append(dict(row))
    meta={"format":INSTALL_FORMAT,"source_manifest_sha256":sha(source/"MANIFEST.json"),"version":source_manifest["version"],"profile":source_manifest["profile"],"owned":rows}
    path=stage/".nebo-sdk/install-manifest.json"; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(json.dumps(meta,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    return meta
def install(source: Path,prefix: Path,fail_phase: str|None=None) -> dict:
    source=source.absolute(); prefix=prefix.absolute(); prefix.parent.mkdir(parents=True,exist_ok=True)
    if prefix.exists(): raise FileExistsError("NEBO-INSTALL-0003 prefix exists")
    with exclusive(prefix):
        verify_bundle(source)
        if fail_phase=="validate": raise OSError("injected validate failure")
        stage=Path(tempfile.mkdtemp(prefix="."+prefix.name+".stage-",dir=prefix.parent))
        try:
            meta=_copy_bundle(source,stage)
            if fail_phase=="stage": raise OSError("injected stage failure")
            verify_install(stage)
            if fail_phase=="verify": raise OSError("injected verify failure")
            if fail_phase=="activate": raise OSError("injected activate failure")
            os.replace(stage,prefix)
            return meta
        except BaseException:
            shutil.rmtree(stage,ignore_errors=True); raise
def load(prefix: Path) -> dict:
    path=_manifest(prefix)
    if path.is_symlink() or not path.is_file(): raise ValueError("NEBO-INSTALL-0004 install manifest missing")
    data=json.loads(path.read_text(encoding="utf-8"))
    if data.get("format")!=INSTALL_FORMAT: raise ValueError("NEBO-INSTALL-0005 install manifest format")
    return data
def verify_install(prefix: Path) -> dict:
    data=load(prefix)
    for row in data["owned"]:
        path=prefix/safe_rel(row["path"])
        if path.is_symlink() or not path.is_file() or sha(path)!=row["sha256"]: raise ValueError("NEBO-INSTALL-0006 owned component mismatch")
    return data
def uninstall(prefix: Path) -> dict:
    prefix=prefix.absolute()
    with exclusive(prefix):
        data=load(prefix); removed=[]
        for row in sorted(data["owned"],key=lambda r:len(PurePosixPath(r["path"]).parts),reverse=True):
            path=prefix/safe_rel(row["path"])
            if path.is_file() and not path.is_symlink() and sha(path)==row["sha256"]: path.unlink(); removed.append(row["path"])
        _manifest(prefix).unlink();
        for path in sorted((p for p in prefix.rglob("*") if p.is_dir()),key=lambda p:len(p.parts),reverse=True):
            try: path.rmdir()
            except OSError: pass
        try: prefix.rmdir()
        except OSError: pass
        return {"removed":removed,"leftovers":sorted(p.relative_to(prefix).as_posix() for p in prefix.rglob("*") if p.is_file()) if prefix.exists() else []}
def repair(source: Path,prefix: Path) -> dict:
    source_data=verify_bundle(source); installed=load(prefix); by_path={r["path"]:r for r in source_data["files"]}; repaired=[]
    for row in installed["owned"]:
        rel=safe_rel(row["path"]); path=prefix/rel
        if row["path"] not in by_path or by_path[row["path"]]["sha256"]!=row["sha256"]: raise ValueError("NEBO-INSTALL-0007 source identity mismatch")
        if not path.is_file() or path.is_symlink() or sha(path)!=row["sha256"]:
            path.parent.mkdir(parents=True,exist_ok=True); fd,name=tempfile.mkstemp(prefix=".repair-",dir=path.parent); os.close(fd)
            tmp=Path(name)
            try: shutil.copyfile(source/rel,tmp); tmp.chmod(int(row["mode"],8)); os.replace(tmp,path); repaired.append(row["path"])
            finally:
                if tmp.exists(): tmp.unlink()
    verify_install(prefix); return {"repaired":repaired}
def upgrade(prefix: Path,candidate: Path) -> dict:
    prefix=prefix.absolute(); rollback=prefix.parent/(prefix.name+".nebo-rollback")
    if rollback.exists(): raise FileExistsError("NEBO-INSTALL-0008 rollback point exists")
    verify_install(prefix); verify_bundle(candidate)
    stage=Path(tempfile.mkdtemp(prefix="."+prefix.name+".upgrade-",dir=prefix.parent))
    try:
        _copy_bundle(candidate,stage); verify_install(stage); os.replace(prefix,rollback)
        try: os.replace(stage,prefix)
        except BaseException: os.replace(rollback,prefix); raise
        return {"active":load(prefix)["version"],"rollback":load(rollback)["version"]}
    except BaseException:
        shutil.rmtree(stage,ignore_errors=True); raise
def rollback(prefix: Path) -> dict:
    prefix=prefix.absolute(); old=prefix.parent/(prefix.name+".nebo-rollback"); failed=prefix.parent/(prefix.name+".nebo-failed-candidate")
    verify_install(prefix); verify_install(old)
    if failed.exists(): shutil.rmtree(failed)
    os.replace(prefix,failed)
    try: os.replace(old,prefix); verify_install(prefix)
    except BaseException: os.replace(failed,prefix); raise
    shutil.rmtree(failed); return {"active":load(prefix)["version"]}
def cache_gc(cache: Path,active: set[str]) -> list[str]:
    removed=[]; cache.mkdir(parents=True,exist_ok=True)
    for path in sorted(cache.iterdir()):
        if path.name in active: continue
        if not path.name.isalnum(): raise ValueError("NEBO-CACHE-0001 hostile cache key")
        if path.is_dir() and not path.is_symlink(): shutil.rmtree(path); removed.append(path.name)
    return removed
def main():
    p=argparse.ArgumentParser(prog="nebo-sdk-lifecycle"); s=p.add_subparsers(dest="cmd",required=True)
    for cmd in ("install","repair","upgrade"):
        q=s.add_parser(cmd); q.add_argument("source",type=Path); q.add_argument("prefix",type=Path)
    for cmd in ("verify","uninstall","rollback"):
        q=s.add_parser(cmd); q.add_argument("prefix",type=Path)
    a=p.parse_args()
    functions={"install":install,"repair":repair,"upgrade":upgrade,"verify":verify_install,"uninstall":uninstall,"rollback":rollback}
    fn=functions[a.cmd]; result=fn(a.source,a.prefix) if hasattr(a,"source") else fn(a.prefix); print(json.dumps(result,sort_keys=True))
if __name__=="__main__": main()
