#!/usr/bin/env python3
"""Deterministic, relocatable Nebo SDK composer.

The composer packages already-built owners; it does not implement language
semantics.  All writes use a sibling stage followed by one activation rename.
"""
from __future__ import annotations
import argparse, hashlib, json, os, shutil, stat, tarfile, tempfile
from pathlib import Path, PurePosixPath

FORMAT = "NEBO-SDK-MANIFEST-v1"
VERSION = "1.0.1"

def sha(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda:f.read(1024*1024), b""): h.update(block)
    return h.hexdigest()

def safe_relative(value: str) -> PurePosixPath:
    rel=PurePosixPath(value)
    if rel.is_absolute() or not rel.parts or any(p in {"", ".", ".."} for p in rel.parts):
        raise ValueError("NEBO-SDK-0001 unsafe relative path")
    return rel

def _copy(source: Path, destination: Path, mode: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.is_symlink() or not source.is_file(): raise ValueError("NEBO-SDK-0002 non-regular component")
    shutil.copyfile(source, destination); destination.chmod(mode)

def component_sources(repo: Path, neboc: Path, profile: str) -> list[tuple[str, Path, int, str]]:
    if profile not in {"source", "sdk", "docs", "tooling"}: raise ValueError("NEBO-SDK-0003 unknown profile")
    rows=[]
    if profile in {"sdk", "tooling"}:
        rows.append(("bin/neboc", neboc, 0o755, "compiler"))
        rows.append(("obj/runtime_core.o", repo/"build/obj/runtime_core.o", 0o644, "runtime"))
        rows.append(("obj/runtime_practical_io.o", repo/"build/obj/runtime_practical_io.o", 0o644, "runtime"))
        rows.append(("share/nebo/version/NEBO-VERSION.json", repo/"version/NEBO-VERSION.json", 0o644, "version"))
    fixed=[
      ("share/nebo/freeze/SYMBOLID-EXPORT-INVENTORY.tsv", repo/"docs/implementation/rf204/freeze/nebo-1.0/SYMBOLID-EXPORT-INVENTORY.tsv",0o644,"interfaces"),
      ("share/nebo/freeze/DIAGNOSTIC-COMPATIBILITY-REGISTRY.tsv", repo/"docs/implementation/rf204/freeze/nebo-1.0/DIAGNOSTIC-COMPATIBILITY-REGISTRY.tsv",0o644,"diagnostics"),
      ("share/doc/nebo/index.md",repo/"docs/public/v1.0/index.md",0o644,"docs"),
      ("share/doc/nebo/offline-site.tar",repo/"docs/public/v1.0/offline-site/nebo-docs-v1.0.tar",0o644,"docs"),
      ("share/examples/hello/main.no",repo/"examples/evolution/rf204-g188/project-console/main.no",0o644,"examples"),
    ]
    if profile=="source":
        fixed=[("src/compiler/sdk/offline_sdk.asm",repo/"compiler/sdk/offline_sdk.asm",0o644,"source")]
    elif profile=="docs": fixed=[x for x in fixed if x[3] in {"docs","examples"}]
    rows.extend(fixed)
    assets=repo/"sdk/nebo-1.0"
    if assets.is_dir() and profile in {"sdk","tooling"}:
        for p in sorted(assets.rglob("*")):
            if p.is_file() and not p.is_symlink():
                rows.append(("share/nebo/sdk/"+p.relative_to(assets).as_posix(),p,0o644,"sdk-metadata"))
    if profile in {"sdk", "tooling"}:
        for name in ("nebo-lsp.py","nebo-format.py","nebo-lint.py","nebo-refactor.py","nebo-new.py","neboc-doctor.py"):
            p=repo/"scripts/rf204"/name
            if p.is_file(): rows.append(("libexec/nebo/"+name,p,0o755,"tooling"))
        for rel in ("compiler/sdk/tooling_host.py","compiler/sdk/sdk_builder.py","compiler/sdk/sdk_lifecycle.py","compiler/migration/semantic_migration.py"):
            p=repo/rel
            if p.is_file(): rows.append(("libexec/nebo/modules/"+rel,p,0o644,"tooling-runtime"))
    if profile == "sdk":
        rows.append(("install-nebo-sdk.py", repo/"sdk/nebo-1.0/install/install-nebo-sdk.py", 0o755, "installer"))
    result=[]
    for rel,source,mode,component in rows:
        safe_relative(rel)
        if not source.is_file(): raise FileNotFoundError(source)
        result.append((rel,source,mode,component))
    return sorted(result,key=lambda row:row[0])

def build_bundle(repo: Path, output: Path, neboc: Path, profile: str="sdk") -> dict:
    repo=repo.resolve(); neboc=neboc.resolve(); output=output.absolute()
    if output.exists(): raise FileExistsError("NEBO-SDK-0004 destination exists")
    output.parent.mkdir(parents=True,exist_ok=True)
    stage=Path(tempfile.mkdtemp(prefix=".nebo-sdk-stage-",dir=output.parent))
    try:
        rows=[]
        for rel,source,mode,component in component_sources(repo,neboc,profile):
            destination=stage/safe_relative(rel)
            _copy(source,destination,mode)
            rows.append({"path":rel,"sha256":sha(destination),"size":destination.stat().st_size,"mode":format(mode,"04o"),"component":component})
        sums="".join(f"{row['sha256']}  {row['path']}\n" for row in rows)
        sums_path=stage/"SHA256SUMS"; sums_path.write_text(sums,encoding="utf-8",newline="\n"); sums_path.chmod(0o644)
        rows.append({"path":"SHA256SUMS","sha256":sha(sums_path),"size":sums_path.stat().st_size,"mode":"0644","component":"integrity"})
        manifest={"format":FORMAT,"version":VERSION,"profile":profile,"target":"linux-x86_64-systemv-elf-static","network_required":False,"files":rows}
        data=(json.dumps(manifest,sort_keys=True,indent=2)+"\n").encode()
        (stage/"MANIFEST.json").write_bytes(data); (stage/"MANIFEST.json").chmod(0o644)
        verify_bundle(stage)
        os.replace(stage,output)
        return manifest
    except BaseException:
        shutil.rmtree(stage,ignore_errors=True); raise

def verify_bundle(root: Path) -> dict:
    root=root.absolute()
    if root.is_symlink() or not root.is_dir(): raise ValueError("NEBO-SDK-0005 invalid SDK root")
    manifest=json.loads((root/"MANIFEST.json").read_text(encoding="utf-8"))
    if manifest.get("format")!=FORMAT or manifest.get("network_required") is not False: raise ValueError("NEBO-SDK-0006 manifest contract")
    expected=set()
    for row in manifest.get("files",[]):
        rel=safe_relative(row["path"]); expected.add(rel.as_posix()); path=root/rel
        if path.is_symlink() or not path.is_file(): raise ValueError("NEBO-SDK-0007 missing or linked component")
        if sha(path)!=row["sha256"] or path.stat().st_size!=row["size"]: raise ValueError("NEBO-SDK-0008 component digest mismatch")
        if stat.S_IMODE(path.stat().st_mode)!=int(row["mode"],8): raise ValueError("NEBO-SDK-0009 component mode mismatch")
    actual={p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p.name!="MANIFEST.json"}
    if actual!=expected: raise ValueError("NEBO-SDK-0010 unmanifested component")
    return manifest

def make_archive(root: Path, archive_path: Path) -> str:
    manifest=verify_bundle(root); archive_path.parent.mkdir(parents=True,exist_ok=True)
    temporary=archive_path.with_name("."+archive_path.name+".tmp")
    if temporary.exists(): temporary.unlink()
    with tarfile.open(temporary,"w",format=tarfile.USTAR_FORMAT) as tar:
        paths=[root/"MANIFEST.json"]+[root/safe_relative(r["path"]) for r in manifest["files"]]
        for path in sorted(paths,key=lambda p:p.relative_to(root).as_posix()):
            info=tar.gettarinfo(str(path),arcname=(PurePosixPath("nebo-sdk")/path.relative_to(root).as_posix()).as_posix())
            info.uid=info.gid=0; info.uname=info.gname=""; info.mtime=0
            info.mode=0o755 if stat.S_IMODE(path.stat().st_mode)&0o111 else 0o644
            with path.open("rb") as source: tar.addfile(info,source)
    os.replace(temporary,archive_path); archive_path.chmod(0o644); return sha(archive_path)

def main() -> None:
    p=argparse.ArgumentParser(prog="nebo-sdk"); sub=p.add_subparsers(dest="cmd",required=True)
    b=sub.add_parser("build"); b.add_argument("--repo",type=Path,required=True); b.add_argument("--neboc",type=Path,required=True); b.add_argument("--output",type=Path,required=True); b.add_argument("--profile",choices=("source","sdk","docs","tooling"),default="sdk")
    v=sub.add_parser("verify"); v.add_argument("root",type=Path)
    a=sub.add_parser("archive"); a.add_argument("root",type=Path); a.add_argument("output",type=Path)
    args=p.parse_args()
    if args.cmd=="build": print(json.dumps(build_bundle(args.repo,args.output,args.neboc,args.profile),sort_keys=True))
    elif args.cmd=="verify": print(json.dumps(verify_bundle(args.root),sort_keys=True))
    else: print(json.dumps({"sha256":make_archive(args.root,args.output)},sort_keys=True))
if __name__=="__main__": main()
