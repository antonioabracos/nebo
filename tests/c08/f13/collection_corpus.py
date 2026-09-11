#!/usr/bin/env python3
"""Emit a deterministic bounded native corpus for the four C08 families."""
from __future__ import annotations

import argparse
import random
from pathlib import Path

CAPACITY = 8
STEPS = 32


def call(lines: list[str], symbol: str, expected: str) -> None:
    lines += [f" call {symbol}", f" cmp eax,{expected}", " jne fail"]


def found_check(lines: list[str], present: bool, value: int | None) -> None:
    lines += [f" cmp qword [rel found],{1 if present else 0}", " jne fail"]
    if value is not None:
        lines += [f" cmp qword [rel out],{value}", " jne fail"]
    elif not present:
        lines += [" cmp qword [rel out],-777", " jne fail"]


def preamble(family: str) -> list[str]:
    inc = "ring_core.inc" if family in {"queue", "deque"} else "list_core.inc"
    symbols = {
        "list": ["neboc_list_init", "neboc_list_push", "neboc_list_pop", "neboc_list_set", "neboc_list_remove", "neboc_list_get", "neboc_list_clear"],
        "stack": ["neboc_stack_init", "neboc_stack_push", "neboc_stack_pop", "neboc_stack_peek", "neboc_stack_clear"],
        "queue": ["neboc_queue_init", "neboc_queue_enqueue", "neboc_queue_dequeue", "neboc_queue_front", "neboc_queue_back", "neboc_queue_clear"],
        "deque": ["neboc_deque_init", "neboc_deque_push_front", "neboc_deque_push_back", "neboc_deque_pop_front", "neboc_deque_pop_back", "neboc_deque_front", "neboc_deque_back", "neboc_deque_clear"],
    }[family]
    lines = ["bits 64", "default rel", '%include "compiler/support/status/status_codes.inc"', f'%include "compiler/semantic/collections/{inc}"']
    lines += [f"extern {symbol}" for symbol in symbols]
    lines += ["global _start", "section .text", "_start:", " lea rdi,[rel collection]", " lea rsi,[rel storage]", f" mov edx,{CAPACITY}", " mov ecx,8", " mov r8d,8"]
    if family == "list":
        lines += [" mov r9d,101"]
        call(lines, "neboc_list_init", "NEBOC_STATUS_OK")
    elif family == "stack":
        lines += [" mov r9d,102"]
        call(lines, "neboc_stack_init", "NEBOC_STATUS_OK")
    elif family == "queue":
        lines[-1] = " mov r8d,103"
        call(lines, "neboc_queue_init", "NEBOC_STATUS_OK")
    else:
        lines[-1] = " mov r8d,104"
        call(lines, "neboc_deque_init", "NEBOC_STATUS_OK")
    return lines


def emit_case(path: Path, family: str, seed: int) -> None:
    rng = random.Random(seed)
    model: list[int] = []
    lines = preamble(family)
    for step in range(STEPS):
        value = seed * 100 + step + 1
        if family == "list":
            op = rng.choice(("push", "pop", "set", "remove", "get", "clear"))
            if op == "push":
                lines += [f" mov qword [rel value],{value}", " lea rdi,[rel collection]", " lea rsi,[rel value]"]
                status = "NEBOC_STATUS_LIMIT_EXCEEDED" if len(model) == CAPACITY else "NEBOC_STATUS_OK"
                call(lines, "neboc_list_push", status)
                if len(model) < CAPACITY:
                    model.append(value)
            elif op == "pop":
                lines += [" mov qword [rel out],-777", " mov qword [rel found],-666", " lea rdi,[rel collection]", " lea rsi,[rel out]", " lea rdx,[rel found]"]
                call(lines, "neboc_list_pop", "NEBOC_STATUS_OK")
                expected = model.pop() if model else None
                found_check(lines, expected is not None, expected)
            elif op == "set":
                index = rng.randrange(CAPACITY + 2)
                lines += [f" mov qword [rel value],{value}", " lea rdi,[rel collection]", f" mov esi,{index}", " lea rdx,[rel value]"]
                call(lines, "neboc_list_set", "NEBOC_STATUS_OK" if index < len(model) else "NEBOC_STATUS_INVALID_SOURCE")
                if index < len(model):
                    model[index] = value
            elif op in {"remove", "get"}:
                index = rng.randrange(CAPACITY + 2)
                lines += [" mov qword [rel out],-777", " mov qword [rel found],-666", " lea rdi,[rel collection]", f" mov esi,{index}", " lea rdx,[rel out]", " lea rcx,[rel found]"]
                call(lines, f"neboc_list_{op}", "NEBOC_STATUS_OK")
                if index < len(model):
                    expected = model[index]
                    if op == "remove":
                        model.pop(index)
                    found_check(lines, True, expected)
                else:
                    found_check(lines, False, None)
            else:
                lines += [" lea rdi,[rel collection]"]
                call(lines, "neboc_list_clear", "NEBOC_STATUS_OK")
                model.clear()
        elif family == "stack":
            op = rng.choice(("push", "pop", "peek", "clear"))
            if op == "push":
                lines += [f" mov qword [rel value],{value}", " lea rdi,[rel collection]", " lea rsi,[rel value]"]
                call(lines, "neboc_stack_push", "NEBOC_STATUS_LIMIT_EXCEEDED" if len(model) == CAPACITY else "NEBOC_STATUS_OK")
                if len(model) < CAPACITY:
                    model.append(value)
            elif op in {"pop", "peek"}:
                lines += [" mov qword [rel out],-777", " mov qword [rel found],-666", " lea rdi,[rel collection]", " lea rsi,[rel out]", " lea rdx,[rel found]"]
                call(lines, f"neboc_stack_{op}", "NEBOC_STATUS_OK")
                expected = model[-1] if model else None
                found_check(lines, expected is not None, expected)
                if op == "pop" and model:
                    model.pop()
            else:
                lines += [" lea rdi,[rel collection]"]
                call(lines, "neboc_stack_clear", "NEBOC_STATUS_OK")
                model.clear()
        else:
            if family == "queue":
                op = rng.choice(("enqueue", "dequeue", "front", "back", "clear"))
            else:
                op = rng.choice(("push_front", "push_back", "pop_front", "pop_back", "front", "back", "clear"))
            if op in {"enqueue", "push_front", "push_back"}:
                lines += [f" mov qword [rel value],{value}", " lea rdi,[rel collection]", " lea rsi,[rel value]"]
                call(lines, f"neboc_{family}_{op}", "NEBOC_STATUS_LIMIT_EXCEEDED" if len(model) == CAPACITY else "NEBOC_STATUS_OK")
                if len(model) < CAPACITY:
                    model.insert(0, value) if op == "push_front" else model.append(value)
            elif op in {"dequeue", "pop_front", "pop_back", "front", "back"}:
                lines += [" mov qword [rel out],-777", " mov qword [rel found],-666", " lea rdi,[rel collection]", " lea rsi,[rel out]", " lea rdx,[rel found]"]
                call(lines, f"neboc_{family}_{op}", "NEBOC_STATUS_OK")
                if not model:
                    expected = None
                elif op in {"dequeue", "pop_front", "front"}:
                    expected = model[0]
                else:
                    expected = model[-1]
                found_check(lines, expected is not None, expected)
                if model and op in {"dequeue", "pop_front"}:
                    model.pop(0)
                elif model and op == "pop_back":
                    model.pop()
            else:
                lines += [" lea rdi,[rel collection]"]
                call(lines, f"neboc_{family}_clear", "NEBOC_STATUS_OK")
                model.clear()
        lines += [f" cmp qword [rel collection+NEBOC_LIST_LENGTH_OFFSET],{len(model)}", " jne fail"]
    lines += [" xor edi,edi", " jmp exit", "fail: mov edi,1", "exit: mov eax,60", " syscall", "section .bss", "align 8", "collection: resb 80", "storage: resq 8", "value: resq 1", "out: resq 1", "found: resq 1", "section .note.GNU-stack noalloc noexec nowrite progbits"]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("C08_F13_CORPUS_DESTINATION_EXISTS")
    args.output.mkdir(parents=True)
    rows = ["case_id\tfamily\tcategory\tpath\toperations"]
    counts = {"POSITIVE": 0, "BOUNDARY": 0, "FUZZ": 0}
    for family_index, family in enumerate(("list", "stack", "queue", "deque")):
        for index in range(16):
            category = "POSITIVE" if index < 4 else "BOUNDARY" if index < 8 else "FUZZ"
            case_id = f"{family}-{index:02d}"
            path = args.output / f"{case_id}.asm"
            emit_case(path, family, 8000 + family_index * 100 + index)
            rows.append(f"{case_id}\t{family}\t{category}\t{path.name}\t{STEPS}")
            counts[category] += 1
    (args.output / "MANIFEST.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")
    print(f"C08_F13_CORPUS_GREEN positive={counts['POSITIVE']} boundary={counts['BOUNDARY']} fuzz={counts['FUZZ']} traces=64 operations={64 * STEPS} seed=C08-F13-v1")


if __name__ == "__main__":
    main()
