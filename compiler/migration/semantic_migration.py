#!/usr/bin/env python3
"""Semantic-token migration planner with atomic apply and rollback journal."""
from __future__ import annotations
import argparse, base64, hashlib, json, os, tempfile
from dataclasses import dataclass, asdict
from pathlib import Path

@dataclass(frozen=True)
class Token:
    kind: str; value: str; start: int; end: int

@dataclass(frozen=True)
class Edit:
    rule_id: str; symbol_id: str; start: int; end: int; before: str; after: str

def tokenize(source: str) -> list[Token]:
    out=[]; i=0
    while i < len(source):
        c=source[i]
        if c.isspace(): i+=1; continue
        if source.startswith("//", i):
            end=source.find("\n", i); end=len(source) if end < 0 else end
            out.append(Token("comment", source[i:end], i, end)); i=end; continue
        if c in "\"'":
            quote=c; j=i+1
            while j < len(source):
                if source[j]=="\\": j+=2; continue
                if source[j]==quote: j+=1; break
                j+=1
            out.append(Token("string", source[i:j], i, j)); i=j; continue
        if c.isalpha() or c=="_":
            j=i+1
            while j < len(source) and (source[j].isalnum() or source[j]=="_"): j+=1
            out.append(Token("ident", source[i:j], i, j)); i=j; continue
        out.append(Token("punct", c, i, i+1)); i+=1
    return out

RULES = {
 "NEBO-MIG-IMPORT-001": ("nebo.legacy.io", "nebo.std.console", "nebo://module/std.console"),
 "NEBO-MIG-CONSOLE-001": ("print", "console", "nebo://prelude/console"),
 "NEBO-MIG-OPERATOR-001": ("xor", "⊻", "nebo://operator/xor"),
 "NEBO-MIG-TEXT-001": ("Text.bytes", "Text.utf8", "nebo://std/text/utf8"),
 "NEBO-MIG-SCAN-001": ("Scan.line", "Scan.read_line", "nebo://std/scan/read_line"),
 "NEBO-MIG-API-001": ("legacy_fetch", "fetch", "nebo://api/net/fetch"),
}

def _significant(tokens): return [t for t in tokens if t.kind not in {"comment", "string"}]

def plan_text(source: str) -> list[Edit]:
    tokens=_significant(tokenize(source)); edits=[]
    values=[t.value for t in tokens]
    for rule,(old,new,symbol) in RULES.items():
        old_parts=[]; pos=0
        while pos < len(old):
            if old[pos].isalnum() or old[pos]=="_":
                j=pos+1
                while j<len(old) and (old[j].isalnum() or old[j]=="_"): j+=1
                old_parts.append(old[pos:j]); pos=j
            else: old_parts.append(old[pos]); pos+=1
        for i in range(0, len(tokens)-len(old_parts)+1):
            if values[i:i+len(old_parts)] != old_parts: continue
            if old == "print":
                prev=values[i-1] if i else ""
                nxt=values[i+1] if i+1<len(values) else ""
                if prev=="." or nxt!="(": continue
            elif old == "xor":
                prev=values[i-1] if i else ""
                nxt=values[i+1] if i+1<len(values) else ""
                if not prev or not nxt or prev in {"(","[","{",",",";","="} or nxt in {")","]","}",",",";"}: continue
            elif old == "nebo.legacy.io":
                if i == 0 or values[i-1] != "use": continue
            elif old in {"Text.bytes", "Scan.line"}:
                nxt=values[i+len(old_parts)] if i+len(old_parts)<len(values) else ""
                if nxt != "(": continue
            elif old == "legacy_fetch":
                prev=values[i-1] if i else ""
                nxt=values[i+1] if i+1<len(values) else ""
                if prev=="." or nxt!="(": continue
            start=tokens[i].start; end=tokens[i+len(old_parts)-1].end
            edits.append(Edit(rule, symbol, start, end, source[start:end], new))
    edits.sort(key=lambda e:(e.start,e.end,e.rule_id))
    for left,right in zip(edits, edits[1:]):
        if left.end > right.start: raise ValueError("NEBO-MIG-0004 overlapping semantic edits")
    return edits

def render(source: str, edits: list[Edit]) -> str:
    out=[]; cursor=0
    for edit in edits:
        if source[edit.start:edit.end] != edit.before: raise ValueError("NEBO-MIG-0003 stale edit precondition")
        out.extend((source[cursor:edit.start], edit.after)); cursor=edit.end
    out.append(source[cursor:]); return "".join(out)

def plan_files(paths: list[Path]) -> list[dict]:
    result=[]
    for path in sorted(paths, key=lambda p:str(p)):
        source=path.read_text(encoding="utf-8"); edits=plan_text(source)
        result.append({"path":str(path), "sha256_before":hashlib.sha256(source.encode()).hexdigest(),
                       "edits":[asdict(e) for e in edits], "candidate":render(source, edits)})
    return result

def _atomic(path: Path, data: str) -> None:
    fd,name=tempfile.mkstemp(prefix=".nebo-migrate-", dir=path.parent)
    try:
        with os.fdopen(fd,"w",encoding="utf-8",newline="") as h: h.write(data); h.flush(); os.fsync(h.fileno())
        os.replace(name,path)
    finally:
        if os.path.exists(name): os.unlink(name)

def apply_plan(plan: list[dict], journal: Path, fail_after: int|None=None) -> None:
    originals=[]
    for item in plan:
        path=Path(item["path"]); source=path.read_text(encoding="utf-8")
        if hashlib.sha256(source.encode()).hexdigest()!=item["sha256_before"]: raise ValueError("NEBO-MIG-0003 stale file")
        originals.append((path,source))
    journal_data={"format":"nebo-migrate-journal-v1","files":[{"path":str(p),"sha256":hashlib.sha256(s.encode()).hexdigest(),"content_b64":base64.b64encode(s.encode()).decode()} for p,s in originals]}
    try:
        for index,item in enumerate(plan):
            if fail_after is not None and index==fail_after: raise OSError("injected apply failure")
            _atomic(Path(item["path"]),item["candidate"])
        _atomic(journal,json.dumps(journal_data,sort_keys=True,indent=2)+"\n")
    except BaseException:
        for path,source in originals: _atomic(path,source)
        if journal.exists(): journal.unlink()
        raise

def rollback(journal: Path) -> None:
    data=json.loads(journal.read_text(encoding="utf-8")); originals=[]
    for item in data["files"]: originals.append((Path(item["path"]),base64.b64decode(item["content_b64"]).decode()))
    for path,source in originals: _atomic(path,source)
    journal.unlink()

def main() -> None:
    p=argparse.ArgumentParser(prog="neboc migrate"); p.add_argument("paths",nargs="*",type=Path); p.add_argument("--apply",action="store_true"); p.add_argument("--journal",type=Path,default=Path(".nebo-migrate-journal.json")); p.add_argument("--rollback",action="store_true")
    a=p.parse_args()
    if a.rollback: rollback(a.journal); print(json.dumps({"state":"ROLLED_BACK"},sort_keys=True)); return
    plan=plan_files(a.paths); public=[{k:v for k,v in item.items() if k!="candidate"} for item in plan]
    print(json.dumps({"mode":"APPLY" if a.apply else "PREVIEW","files":public,"edits":sum(len(x["edits"]) for x in plan)},sort_keys=True,indent=2))
    if a.apply: apply_plan(plan,a.journal)
if __name__=="__main__": main()
