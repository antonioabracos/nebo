#!/usr/bin/env python3
"""Structural migration planner with fail-closed apply and rollback."""
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

@dataclass(frozen=True)
class Conflict:
    rule_id: str
    symbol_id: str
    start: int
    end: int
    legacy_form: str
    reason: str
    disposition: str = "MANUAL_REVIEW"

def tokenize(source: str) -> list[Token]:
    """Tokenize enough structure for migration without parsing Nebo semantics."""
    out=[]; i=0
    while i < len(source):
        c=source[i]
        if c.isspace(): i+=1; continue
        if source.startswith("//", i):
            end=source.find("\n", i); end=len(source) if end < 0 else end
            out.append(Token("comment", source[i:end], i, end)); i=end; continue
        if source.startswith("/*", i):
            marker=source.find("*/", i+2); end=len(source) if marker < 0 else marker+2
            out.append(Token("comment", source[i:end], i, end)); i=end; continue
        if c in "\"'":
            quote=c; j=i+1
            while j < len(source):
                if source[j]=="\\": j=min(j+2,len(source)); continue
                if source[j]==quote: j+=1; break
                j+=1
            out.append(Token("string", source[i:j], i, j)); i=j; continue
        if c.isalpha() or c=="_":
            j=i+1
            while j < len(source) and (source[j].isalnum() or source[j]=="_"): j+=1
            out.append(Token("ident", source[i:j], i, j)); i=j; continue
        if c.isdigit():
            j=i+1
            while j < len(source) and (source[j].isalnum() or source[j] in {"_","."}): j+=1
            out.append(Token("number", source[i:j], i, j)); i=j; continue
        out.append(Token("punct", c, i, i+1)); i+=1
    return out

RULES = {
 "NEBO-MIG-IMPORT-001": ("nebo.legacy.io", "nebo.std.console", "nebo://module/std.console"),
 "NEBO-MIG-OPERATOR-001": ("xor", "⊻", "nebo://operator/xor"),
 "NEBO-MIG-TEXT-001": ("Text.bytes", "Text.utf8", "nebo://std/text/utf8"),
 "NEBO-MIG-SCAN-001": ("Scan.line", "Scan.read_line", "nebo://std/scan/read_line"),
 "NEBO-MIG-API-001": ("legacy_fetch", "fetch", "nebo://api/net/fetch"),
}

CONSOLE_RULE_ID = "NEBO-MIG-CONSOLE-001"
CONSOLE_SYMBOL_ID = "nebo://prelude/console"
OPEN_TO_CLOSE = {"(": ")", "[": "]", "{": "}"}
CLOSE_TO_OPEN = {close: opening for opening, close in OPEN_TO_CLOSE.items()}

def _semantic_tokens(tokens: list[Token]) -> list[Token]:
    return [token for token in tokens if token.kind not in {"comment", "string"}]

def _old_parts(old: str) -> list[str]:
    parts=[]; pos=0
    while pos < len(old):
        if old[pos].isalnum() or old[pos]=="_":
            end=pos+1
            while end < len(old) and (old[end].isalnum() or old[end]=="_"): end+=1
            parts.append(old[pos:end]); pos=end
        else: parts.append(old[pos]); pos+=1
    return parts

def _plan_generic(source: str, all_tokens: list[Token]) -> list[Edit]:
    tokens=_semantic_tokens(all_tokens); values=[token.value for token in tokens]; edits=[]
    for rule,(old,new,symbol) in RULES.items():
        if rule==CONSOLE_RULE_ID: continue
        parts=_old_parts(old)
        for index in range(0,len(tokens)-len(parts)+1):
            if values[index:index+len(parts)]!=parts: continue
            previous=values[index-1] if index else ""
            following_index=index+len(parts)
            following=values[following_index] if following_index<len(values) else ""
            if old=="xor":
                if not previous or not following or previous in {"(","[","{",",",";","="} or following in {")","]","}",",",";"}: continue
            elif old=="nebo.legacy.io":
                if index==0 or previous!="use": continue
            elif old in {"Text.bytes","Scan.line"}:
                if following!="(": continue
            elif old=="legacy_fetch":
                if previous=="." or following!="(": continue
            start=tokens[index].start; end=tokens[index+len(parts)-1].end
            edits.append(Edit(rule,symbol,start,end,source[start:end],new))
    return edits

def _previous_noncomment(tokens: list[Token], index: int) -> int|None:
    index-=1
    while index>=0:
        if tokens[index].kind!="comment": return index
        index-=1
    return None

def _next_noncomment(tokens: list[Token], index: int) -> int|None:
    index+=1
    while index<len(tokens):
        if tokens[index].kind!="comment": return index
        index+=1
    return None

def _matching_close(tokens: list[Token], opening_index: int) -> tuple[int|None,str|None]:
    stack=[]
    for index in range(opening_index,len(tokens)):
        token=tokens[index]
        if token.kind!="punct": continue
        if token.value in OPEN_TO_CLOSE: stack.append(token.value); continue
        if token.value in CLOSE_TO_OPEN:
            if not stack or stack[-1]!=CLOSE_TO_OPEN[token.value]: return None,"MALFORMED_DELIMITER_NESTING"
            stack.pop()
            if not stack: return index,None
    return None,"UNTERMINATED_LEGACY_CALL"

def _receiver_safe(tokens: list[Token]) -> bool:
    """Return whether postfix .console() binds to the complete argument."""
    code=[token for token in tokens if token.kind!="comment"]
    if not code: return False
    first=code[0]
    if first.kind in {"ident","number","string"}: position=1
    elif first.kind=="punct" and first.value=="(":
        closing,error=_matching_close(code,0)
        if error: return False
        if closing==len(code)-1 and not _receiver_safe(code[1:closing]): return False
        position=closing+1
    else: return False
    while position<len(code):
        token=code[position]
        if token.kind=="punct" and token.value==".":
            if position+1>=len(code) or code[position+1].kind!="ident": return False
            position+=2; continue
        if token.kind=="punct" and token.value in {"(","["}:
            closing,error=_matching_close(code,position)
            if error: return False
            position=closing+1; continue
        return False
    return True

def _requires_lexical_binding(tokens: list[Token]) -> bool:
    """Match only product boundaries that cannot bind .console() directly."""
    code=[token for token in tokens if token.kind!="comment"]
    if not code: return False
    if code[0].kind=="punct" and code[0].value=="(":
        closing,error=_matching_close(code,0)
        if not error and closing==len(code)-1:
            return _requires_lexical_binding(code[1:closing])
    stack=[]; top_level_calls=0
    for index,token in enumerate(code):
        if token.kind!="punct": continue
        if token.value in OPEN_TO_CLOSE:
            if not stack and token.value in {"(","["}: top_level_calls+=1
            stack.append(token.value); continue
        if token.value in CLOSE_TO_OPEN:
            if stack and stack[-1]==CLOSE_TO_OPEN[token.value]: stack.pop()
            continue
        if stack or token.value==".": continue
        if index==0 and token.value in {"+","-","!","~"}: continue
        return True
    return top_level_calls>1

def _render_span(source: str, start: int, end: int, edits: list[Edit]) -> str:
    out=[]; cursor=start
    for edit in sorted(edits,key=lambda item:(item.start,item.end,item.rule_id)):
        if not (start<=edit.start<=edit.end<=end): raise ValueError("NEBO-MIG-0004 edit outside structural span")
        if cursor>edit.start: raise ValueError("NEBO-MIG-0004 overlapping semantic edits")
        if source[edit.start:edit.end]!=edit.before: raise ValueError("NEBO-MIG-0003 stale edit precondition")
        out.extend((source[cursor:edit.start],edit.after)); cursor=edit.end
    out.append(source[cursor:end]); return "".join(out)

def _top_level_commas(tokens: list[Token]) -> int:
    stack=[]; commas=0
    for token in tokens:
        if token.kind!="punct": continue
        if token.value in OPEN_TO_CLOSE: stack.append(token.value)
        elif token.value in CLOSE_TO_OPEN:
            if stack and stack[-1]==CLOSE_TO_OPEN[token.value]: stack.pop()
        elif token.value=="," and not stack: commas+=1
    return commas

def _nested_legacy_call(tokens: list[Token]) -> bool:
    for index,token in enumerate(tokens):
        if token.kind!="ident" or token.value!="print": continue
        previous=_previous_noncomment(tokens,index); following=_next_noncomment(tokens,index)
        if previous is not None and tokens[previous].value==".": continue
        if following is not None and tokens[following].value=="(": return True
    return False

def _console_conflict(source: str, start: int, end: int, reason: str) -> Conflict:
    return Conflict(CONSOLE_RULE_ID,CONSOLE_SYMBOL_ID,start,end,source[start:end],reason)

def _plan_console(source: str, tokens: list[Token], generic_edits: list[Edit]) -> tuple[list[Edit],list[Conflict],list[tuple[int,int]]]:
    # Tombstone: `print` is neither current nor legacy Nebo. Preserve the
    # historical implementation below for traceability, but never dispatch it.
    return [], [], []

    edits=[]; conflicts=[]; owned_spans=[]; covered_until=-1
    occupied={token.value for token in tokens if token.kind=="ident"}; binding_index=0
    for index,token in enumerate(tokens):
        if token.start<covered_until or token.kind!="ident" or token.value!="print": continue
        previous=_previous_noncomment(tokens,index)
        if previous is not None and tokens[previous].value==".": continue
        opening_index=_next_noncomment(tokens,index)
        if opening_index is None or tokens[opening_index].value!="(": continue
        closing_index,delimiter_error=_matching_close(tokens,opening_index)
        if closing_index is None:
            end=len(source); conflicts.append(_console_conflict(source,token.start,end,delimiter_error or "MALFORMED_LEGACY_CALL")); owned_spans.append((token.start,end)); covered_until=end; continue
        opening=tokens[opening_index]; closing=tokens[closing_index]; end=closing.end
        argument_tokens=tokens[opening_index+1:closing_index]
        argument_code=[item for item in argument_tokens if item.kind!="comment"]
        reason=None
        if not argument_code: reason="ZERO_ARGUMENTS"
        elif _top_level_commas(argument_tokens): reason="MULTIPLE_ARGUMENTS"
        elif _nested_legacy_call(argument_tokens): reason="NESTED_LEGACY_CONSOLE_CALL"
        else:
            following=_next_noncomment(tokens,closing_index)
            if following is not None and tokens[following].value=="{": reason="DECLARATION_LIKE_FORM"
            elif following is not None and tokens[following].value==".": reason="CHAINED_LEGACY_RESULT"
        if reason:
            conflicts.append(_console_conflict(source,token.start,end,reason)); owned_spans.append((token.start,end)); covered_until=end; continue
        contained=[edit for edit in generic_edits if opening.end<=edit.start and edit.end<=closing.start]
        migrated_argument=_render_span(source,opening.end,closing.start,contained)
        interstitial=source[token.end:opening.start]
        leading=source[opening.end:argument_code[0].start]
        trailing=source[argument_code[-1].end:closing.start]
        receiver=interstitial+migrated_argument
        postfix_safe=_receiver_safe(argument_tokens)
        requires_binding=_requires_lexical_binding(argument_tokens)
        if not requires_binding:
            needs_grouping=bool(interstitial or leading or trailing)
            needs_grouping=needs_grouping or not postfix_safe
            replacement=f"({receiver}).console()" if needs_grouping else f"{receiver}.console()"
        else:
            while True:
                binding=f"nebo_mig_console_value_{binding_index}"
                binding_index+=1
                if binding not in occupied: break
            occupied.add(binding)
            line_start=source.rfind("\n",0,token.start)+1
            line_prefix=source[line_start:token.start]
            indentation=line_prefix if not line_prefix.strip() else ""
            replacement=f"({receiver}).{binding};\n{indentation}{binding}.console()"
        edits.append(Edit(CONSOLE_RULE_ID,CONSOLE_SYMBOL_ID,token.start,closing.end,source[token.start:closing.end],replacement))
        owned_spans.append((token.start,closing.end)); covered_until=closing.end
    return edits,conflicts,owned_spans

def plan_text_with_conflicts(source: str) -> tuple[list[Edit],list[Conflict]]:
    tokens=tokenize(source)
    # `print` is invalid non-Nebo source, not a migration entry point.  Fail
    # closed for the complete source before any independent rule can produce a
    # partial edit around that invalid token.  Comments and strings are trivia
    # and therefore do not suppress otherwise valid non-print migrations.
    if any(token.kind=="ident" and token.value=="print" for token in _semantic_tokens(tokens)):
        return [],[]
    generic_edits=_plan_generic(source,tokens)
    console_edits,conflicts,owned_spans=_plan_console(source,tokens,generic_edits)
    edits=[edit for edit in generic_edits if not any(start<=edit.start and edit.end<=end for start,end in owned_spans)]
    edits.extend(console_edits); edits.sort(key=lambda item:(item.start,item.end,item.rule_id))
    for left,right in zip(edits,edits[1:]):
        if left.end>right.start: raise ValueError("NEBO-MIG-0004 overlapping semantic edits")
    conflicts.sort(key=lambda item:(item.start,item.end,item.reason))
    return edits,conflicts

def plan_text(source: str) -> list[Edit]:
    edits,_=plan_text_with_conflicts(source); return edits

def render(source: str, edits: list[Edit]) -> str:
    return _render_span(source,0,len(source),edits)

def plan_files(paths: list[Path]) -> list[dict]:
    result=[]
    for path in sorted(paths, key=lambda p:str(p)):
        source=path.read_text(encoding="utf-8"); edits,conflicts=plan_text_with_conflicts(source)
        result.append({"path":str(path), "sha256_before":hashlib.sha256(source.encode()).hexdigest(),
                       "edits":[asdict(e) for e in edits], "conflicts":[asdict(c) for c in conflicts],
                       "candidate":render(source, edits)})
    return result

def _atomic(path: Path, data: str) -> None:
    fd,name=tempfile.mkstemp(prefix=".nebo-migrate-", dir=path.parent)
    try:
        with os.fdopen(fd,"w",encoding="utf-8",newline="") as h: h.write(data); h.flush(); os.fsync(h.fileno())
        os.replace(name,path)
    finally:
        if os.path.exists(name): os.unlink(name)

def apply_plan(plan: list[dict], journal: Path, fail_after: int|None=None) -> None:
    conflict_count=sum(len(item.get("conflicts",[])) for item in plan)
    if conflict_count: raise ValueError("NEBO-MIG-1001 manual review required; zero files changed")
    changed=[item for item in plan if item["edits"]]
    if not changed: return
    if journal.exists(): raise ValueError("NEBO-MIG-0005 rollback journal already exists")
    originals=[]
    for item in changed:
        path=Path(item["path"]); source=path.read_text(encoding="utf-8")
        if hashlib.sha256(source.encode()).hexdigest()!=item["sha256_before"]: raise ValueError("NEBO-MIG-0003 stale file")
        originals.append((path,source))
    def journal_data(state: str) -> dict:
        return {"format":"nebo-migrate-journal-v1","state":state,"files":[{"path":str(p),"sha256":hashlib.sha256(s.encode()).hexdigest(),"content_b64":base64.b64encode(s.encode()).decode()} for p,s in originals]}
    _atomic(journal,json.dumps(journal_data("PREPARED"),sort_keys=True,indent=2)+"\n")
    try:
        for index,item in enumerate(changed):
            if fail_after is not None and index==fail_after: raise OSError("injected apply failure")
            _atomic(Path(item["path"]),item["candidate"])
        _atomic(journal,json.dumps(journal_data("COMMITTED"),sort_keys=True,indent=2)+"\n")
    except BaseException:
        for path,source in originals: _atomic(path,source)
        if journal.exists(): journal.unlink()
        raise

def rollback(journal: Path) -> None:
    data=json.loads(journal.read_text(encoding="utf-8")); originals=[]
    if data.get("format")!="nebo-migrate-journal-v1": raise ValueError("NEBO-MIG-0006 unsupported rollback journal")
    for item in data["files"]: originals.append((Path(item["path"]),base64.b64decode(item["content_b64"]).decode()))
    for path,source in originals: _atomic(path,source)
    journal.unlink()

def main() -> None:
    p=argparse.ArgumentParser(prog="neboc migrate"); p.add_argument("paths",nargs="*",type=Path); p.add_argument("--apply",action="store_true"); p.add_argument("--journal",type=Path,default=Path(".nebo-migrate-journal.json")); p.add_argument("--rollback",action="store_true")
    a=p.parse_args()
    if a.rollback: rollback(a.journal); print(json.dumps({"state":"ROLLED_BACK"},sort_keys=True)); return
    plan=plan_files(a.paths); public=[{k:v for k,v in item.items() if k!="candidate"} for item in plan]
    conflict_count=sum(len(item["conflicts"]) for item in plan)
    print(json.dumps({"mode":"APPLY" if a.apply else "PREVIEW","files":public,"edits":sum(len(x["edits"]) for x in plan),"conflicts":conflict_count,"manual_review_required":bool(conflict_count)},sort_keys=True,indent=2))
    if a.apply:
        if conflict_count: raise SystemExit(2)
        apply_plan(plan,a.journal)
if __name__=="__main__": main()
