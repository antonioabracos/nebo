#!/usr/bin/env python3
"""Focused positive/negative tests for the corrected and independent oracles."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
ORACLE_PATH = (
    ROOT / "scripts/release/nebo-1.0/prepublication-remediation"
    / "stack_alignment_oracle.py"
)
LEGACY_PATH = ROOT / "scripts/mf056/audit-stack-alignment.py"


def load_oracle():
    spec = importlib.util.spec_from_file_location("nebo_stack_oracle", ORACLE_PATH)
    if spec is None or spec.loader is None:
        raise SystemExit("ORACLE_IMPORT_FAIL")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def build(work: Path, name: str, body: str) -> Path:
    source = work / f"{name}.asm"
    obj = work / f"{name}.o"
    binary = work / name
    source.write_text(body, encoding="utf-8")
    subprocess.run(["nasm", "-f", "elf64", "-Wall", "-Werror", "-o", obj, source],
                   cwd=ROOT, check=True)
    subprocess.run(["ld", "-m", "elf_x86_64", "-nostdlib", "-z", "noexecstack",
                    "--build-id=none", "-o", binary, obj], cwd=ROOT, check=True)
    return binary


def main() -> int:
    oracle = load_oracle()
    modeled, reason = oracle.transfer(
        oracle.Instruction(0, "lea", "rsp,[rsp+0x8]", "lea rsp,[rsp+0x8]"),
        oracle.State(0, None),
    )
    if modeled != oracle.State(8, None) or reason:
        raise SystemExit("INDEPENDENT_ORACLE_LEA_MODEL_FAIL")
    unknown, reason = oracle.transfer(
        oracle.Instruction(0, "add", "rsp,rax", "add rsp,rax"),
        oracle.State(0, None),
    )
    if unknown is not None or reason != "DYNAMIC_RSP_ARITHMETIC_NOT_PROVEN_MULTIPLE_OF_16":
        raise SystemExit("INDEPENDENT_ORACLE_UNKNOWN_FAIL_CLOSED_FAIL")

    common = """bits 64
section .text
global _start
_start:
    call subject
    mov eax,60
    xor edi,edi
    syscall
subject:
{subject}
leaf:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
"""
    with tempfile.TemporaryDirectory(prefix="nebo-stack-oracle-test-") as raw:
        work = Path(raw)
        green = build(
            work, "green",
            common.format(subject="    sub rsp,8\n    call leaf\n    lea rsp,[rsp+8]\n    ret"),
        )
        red = build(
            work, "red",
            common.format(subject="    call leaf\n    ret"),
        )
        good = subprocess.run([sys.executable, "-B", LEGACY_PATH, green],
                              cwd=ROOT, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, check=False)
        bad = subprocess.run([sys.executable, "-B", LEGACY_PATH, red],
                             cwd=ROOT, text=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, check=False)
        if good.returncode != 0 or "MF056_STACK_ALIGNMENT_GREEN" not in good.stdout:
            raise SystemExit(f"CORRECTED_ORACLE_POSITIVE_FAIL {good.stdout!r}")
        if bad.returncode != 1 or "call with rsp mod16=8" not in bad.stdout:
            raise SystemExit(f"CORRECTED_ORACLE_NEGATIVE_FAIL {bad.stdout!r}")
    print("CORRECTED_ORACLE_LEA_RSP=PASS")
    print("INDEPENDENT_ORACLE_UNKNOWN_FAIL_CLOSED=PASS")
    print("ORACLE_POSITIVE_NEGATIVE_FIXTURES=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
