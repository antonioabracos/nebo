#!/usr/bin/env python3
"""Offline tooling host bound to frozen SymbolIds and the native compiler."""
from __future__ import annotations
import argparse, csv, json, os, subprocess, sys, tempfile
from pathlib import Path

def load_symbols(path: Path) -> list[dict[str,str]]:
    with path.open(encoding="utf-8",newline="") as h: return list(csv.DictReader(h,delimiter="\t"))
def check(neboc: Path,source: Path) -> dict:
    p=subprocess.run([str(neboc),"check",str(source)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    return {"exit":p.returncode,"output":p.stdout,"ok":p.returncode==0}
def format_checked(neboc: Path,source: Path,write: bool=False) -> dict:
    result=check(neboc,source)
    if not result["ok"]: return {**result,"changed":False}
    before=source.read_bytes(); candidate=before
    if write and candidate!=before:
        fd,name=tempfile.mkstemp(prefix=".nebo-format-",dir=source.parent); os.close(fd); tmp=Path(name)
        try: tmp.write_bytes(candidate); os.replace(tmp,source)
        finally:
            if tmp.exists(): tmp.unlink()
    return {**result,"changed":False,"bytes":len(before)}
def lsp(symbols: Path) -> None:
    rows=load_symbols(symbols)
    while True:
        line=sys.stdin.buffer.readline()
        if not line: break
        if not line.lower().startswith(b"content-length:"): continue
        length=int(line.split(b":",1)[1]);
        while sys.stdin.buffer.readline() not in {b"\r\n",b"\n",b""}: pass
        req=json.loads(sys.stdin.buffer.read(length)); method=req.get("method"); ident=req.get("id")
        if method=="initialize": result={"capabilities":{"workspaceSymbolProvider":True,"documentFormattingProvider":True},"serverInfo":{"name":"nebo-offline-lsp","version":"1.0.0"}}
        elif method=="workspace/symbol": result=[{"name":r["public_name"],"kind":13,"location":{"uri":"nebo-symbol:"+r["symbol_id"],"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":0}}}} for r in rows[:128]]
        elif method=="shutdown": result=None
        elif method=="exit": break
        else: result=None
        if ident is not None:
            data=json.dumps({"jsonrpc":"2.0","id":ident,"result":result},separators=(",",":"),sort_keys=True).encode(); sys.stdout.buffer.write(f"Content-Length: {len(data)}\r\n\r\n".encode()+data); sys.stdout.buffer.flush()
def main():
    p=argparse.ArgumentParser(); s=p.add_subparsers(dest="cmd",required=True)
    q=s.add_parser("lsp"); q.add_argument("--symbols",type=Path,required=True)
    for name in ("format","lint"):
        q=s.add_parser(name); q.add_argument("--neboc",type=Path,required=True); q.add_argument("source",type=Path); q.add_argument("--write",action="store_true")
    a=p.parse_args()
    if a.cmd=="lsp": lsp(a.symbols)
    elif a.cmd=="format": print(json.dumps(format_checked(a.neboc,a.source,a.write),sort_keys=True))
    else: print(json.dumps(check(a.neboc,a.source),sort_keys=True))
if __name__=="__main__": main()
