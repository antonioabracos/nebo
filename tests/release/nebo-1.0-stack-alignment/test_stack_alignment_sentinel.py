#!/usr/bin/env python3
"""Build and exercise the no-libc dynamic stack-alignment sentinel matrix."""
from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
TEST_DIR = Path(__file__).resolve().parent
NAMES = [
    "direct_call", "indirect_call", "nested_call", "recursive_call",
    "call_after_even_pushes", "call_after_odd_pushes", "call_after_local_frame",
    "call_after_spills", "call_in_if_else", "call_in_loop",
    "call_in_early_return", "call_in_error_cleanup", "compiler_driver",
    "runtime", "x11_path", "sdk_neboc",
]
EXPECTED = bytes([1] * len(NAMES))


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="nebo-stack-sentinel-") as raw:
        work = Path(raw)
        sentinel = work / "sentinel.o"
        matrix = work / "matrix.o"
        binary = work / "sentinel-matrix"
        subprocess.run(
            ["nasm", "-f", "elf64", "-Wall", "-Werror", "-o", str(sentinel),
             str(TEST_DIR / "stack_alignment_sentinel.asm")],
            cwd=ROOT, check=True,
        )
        subprocess.run(
            ["nasm", "-f", "elf64", "-Wall", "-Werror", "-o", str(matrix),
             str(TEST_DIR / "stack_alignment_sentinel_matrix.asm")],
            cwd=ROOT, check=True,
        )
        disassembly = subprocess.check_output(
            ["objdump", "-d", "-M", "intel", "--no-show-raw-insn", str(sentinel)],
            cwd=ROOT, text=True,
        )
        body = disassembly.split("<nebo_stack_alignment_sentinel>:", 1)[1]
        first_instruction = next(
            line.strip() for line in body.splitlines() if ":" in line
        )
        if "lea" not in first_instruction or "rax,[rsp+0x8]" not in first_instruction:
            raise SystemExit(f"SENTINEL_FIRST_INSTRUCTION_FAIL {first_instruction!r}")
        subprocess.run(
            ["ld", "-m", "elf_x86_64", "-nostdlib", "-z", "noexecstack",
             "--build-id=none", "-o", str(binary), str(matrix), str(sentinel)],
            cwd=ROOT, check=True,
        )
        completed = subprocess.run([str(binary)], cwd=ROOT, check=False,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if completed.returncode != 0 or completed.stderr or completed.stdout != EXPECTED:
            raise SystemExit(
                "DYNAMIC_SENTINEL_FAIL "
                f"exit={completed.returncode} stdout={completed.stdout.hex()} "
                f"stderr={completed.stderr!r}"
            )
        for name, value, expected in zip(NAMES, completed.stdout, EXPECTED):
            verdict = "ABI_GREEN" if value else "ABI_RED_UNEXPECTED"
            print(f"{name}\t{value}\t{expected}\t{verdict}")
        failures = sum(value == 0 for value in completed.stdout)
        positive = sum(value == 1 for value in completed.stdout)
        print(f"DYNAMIC_SENTINEL_CASES={len(NAMES)}")
        print(f"DYNAMIC_SENTINEL_GREEN_CASES={positive}")
        print(f"DYNAMIC_SENTINEL_FAILURES={failures}")
        print("DYNAMIC_SENTINEL_FIRST_INSTRUCTION_MEASURES_ENTRY=PASS")
        print("STACK_ALIGNMENT_DYNAMIC=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
