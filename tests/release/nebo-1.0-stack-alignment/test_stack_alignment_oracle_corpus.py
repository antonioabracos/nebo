#!/usr/bin/env python3
"""Adversarial positive/negative corpus for the permanent stack-state gate."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
AUDIT = ROOT / "scripts/mf056/audit-stack-alignment.py"

POSITIVE = {
    "aligned_leaf": "ret",
    "aligned_non_leaf": "sub rsp,8\n call leaf\n add rsp,8\n ret",
    "nested": "sub rsp,8\n call helper\n add rsp,8\n ret\nhelper:\n sub rsp,8\n call leaf\n add rsp,8\n ret",
    "recursive": "test edi,edi\n jz .done\n dec edi\n sub rsp,8\n call subject\n add rsp,8\n.done:\n ret",
    "odd_saved_registers": "push rbx\n call leaf\n pop rbx\n ret",
    "even_saved_registers": "push rbx\n push r12\n sub rsp,8\n call leaf\n add rsp,8\n pop r12\n pop rbx\n ret",
    "locals": "sub rsp,24\n call leaf\n add rsp,24\n ret",
    "branches": "sub rsp,8\n test edi,edi\n jz .right\n call leaf\n jmp .done\n.right:\n call leaf\n.done:\n add rsp,8\n ret",
    "loops": "sub rsp,8\n mov ecx,2\n.loop:\n call leaf\n loop .loop\n add rsp,8\n ret",
    "indirect_call": "sub rsp,8\n lea rax,[rel leaf]\n call rax\n add rsp,8\n ret",
    "tail_call": "jmp leaf",
    "entrypoint_special": "ret",
    "error_cleanup": "push rbx\n call leaf\n test eax,eax\n jnz .cleanup\n.cleanup:\n pop rbx\n ret",
    "and_rsp_restored": "push rbp\n mov rbp,rsp\n and rsp,-16\n call leaf\n mov rsp,rbp\n pop rbp\n ret",
    "enter_leave": "enter 16,0\n call leaf\n leave\n ret",
    "flags_save_restore": "pushfq\n call leaf\n popfq\n ret",
    "immediate_push": "push 1\n call leaf\n add rsp,8\n ret",
    "unreachable_call_classified": "ret\n.dead:\n call leaf\n ret",
    "x11_live_backend": "sub rsp,8\n call leaf\n add rsp,8\n ret",
}

NEGATIVE = {
    "missing_parity": "call leaf\n ret",
    "even_push_before_call": "push rbx\n push r12\n call leaf\n pop r12\n pop rbx\n ret",
    "branch_merge_conflict": "test edi,edi\n jz .join\n sub rsp,8\n.join:\n call leaf\n add rsp,8\n ret",
    "unbalanced_early_return": "push rbx\n ret",
    "dynamic_stack_unknown": "sub rsp,rax\n ret",
    "and_rsp_without_restore": "and rsp,-16\n ret",
    "indirect_misaligned": "lea rax,[rel leaf]\n call rax\n ret",
    "nested_misaligned": "call helper\n ret\nhelper:\n call leaf\n ret",
    "xchg_rsp_unknown": "xchg rsp,rax\n ret",
    "mov_rsp_unknown": "mov rsp,rax\n ret",
    "ret_imm16": "ret 8",
    "red_zone_across_call": "mov [rsp-16],rax\n push rbx\n call leaf\n pop rbx\n ret",
}


def build(work: Path, name: str, body: str) -> Path:
    source = work / f"{name}.asm"
    obj = work / f"{name}.o"
    binary = work / name
    text = f"""bits 64
default rel
section .text
global _start
global subject
global leaf
_start:
 call subject
 mov eax,60
 xor edi,edi
 syscall
subject:
 {body.replace(chr(10), chr(10) + ' ')}
leaf:
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
"""
    source.write_text(text, encoding="utf-8")
    subprocess.run(["nasm", "-f", "elf64", "-Wall", "-Werror", "-o", obj, source],
                   cwd=ROOT, check=True)
    subprocess.run(["ld", "-m", "elf_x86_64", "-nostdlib", "-z", "noexecstack",
                    "--build-id=none", "-o", binary, obj], cwd=ROOT, check=True)
    return binary


def audit(binary: Path, report_prefix: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-B", AUDIT, binary,
         "--report-tsv", report_prefix.with_suffix(".tsv"),
         "--report-json", report_prefix.with_suffix(".json")],
        cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="nebo-stack-corpus-") as raw:
        work = Path(raw)
        for name, body in POSITIVE.items():
            binary = build(work, "positive_" + name, body)
            first = audit(binary, work / (name + "-run1"))
            second = audit(binary, work / (name + "-run2"))
            if first.returncode or second.returncode:
                raise SystemExit(f"POSITIVE_FIXTURE_REJECTED {name} {first.stdout!r} {second.stdout!r}")
            first_json = json.loads((work / (name + "-run1.json")).read_text())
            second_json = json.loads((work / (name + "-run2.json")).read_text())
            if first_json != second_json:
                raise SystemExit(f"NONDETERMINISTIC_REPORT {name}")
            if first_json["summary"]["duplicate_ids"]:
                raise SystemExit(f"DUPLICATE_NORMALIZED_IDS {name}")
        for name, body in NEGATIVE.items():
            binary = build(work, "negative_" + name, body)
            completed = audit(binary, work / (name + "-negative"))
            if completed.returncode != 1 or "MF056_STACK_ALIGNMENT_FAIL" not in completed.stdout:
                raise SystemExit(f"NEGATIVE_FIXTURE_ACCEPTED {name} {completed.stdout!r}")
        source = build(work, "metamorphic_original", POSITIVE["indirect_call"])
        renamed = work / "unrelated-renamed-program"
        shutil.copy2(source, renamed)
        original = audit(source, work / "metamorphic-original")
        changed = audit(renamed, work / "metamorphic-renamed")
        original_summary = json.loads((work / "metamorphic-original.json").read_text())["summary"]
        changed_summary = json.loads((work / "metamorphic-renamed.json").read_text())["summary"]
        if original.returncode or changed.returncode or original_summary != changed_summary:
            raise SystemExit("FILENAME_METAMORPHIC_SEMANTICS_FAIL")
    print(f"POSITIVE_FIXTURES_ACCEPTED={len(POSITIVE)}_OF_{len(POSITIVE)}")
    print(f"NEGATIVE_FIXTURES_REJECTED={len(NEGATIVE)}_OF_{len(NEGATIVE)}")
    print("FALSE_GREEN_CORPUS=0")
    print("UNKNOWN_ACCEPTED=0")
    print("DETERMINISTIC_REPORT=PASS")
    print("FILENAME_METAMORPHIC_SEMANTICS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
