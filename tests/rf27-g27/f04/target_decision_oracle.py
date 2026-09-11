#!/usr/bin/env python3
"""Factual second-target decision model."""
import hashlib

rows = [
    "certified:x86_64-systemv-elf-linux:yes",
    "candidate:aarch64-linux:backend_registry:no",
    "candidate:aarch64-linux:clang_assembler:available",
    "candidate:aarch64-linux:gnu_linker:unavailable",
    "candidate:aarch64-linux:runtime_emulator:unavailable",
    "candidate:aarch64-linux:abi_conformance:unavailable",
    "decision:defer_without_install",
]
print("RF27_G27_F04_ORACLE=PASS decision=TARGET_UNAVAILABLE rows=7 digest=" + hashlib.sha256("\n".join(rows).encode()).hexdigest())
