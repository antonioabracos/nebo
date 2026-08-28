#!/usr/bin/env python3
"""Independent source/CFG and ELF stack-alignment oracle for the Nebo 1.0 rework."""
from __future__ import annotations

import argparse
import csv
from collections import defaultdict, deque
from dataclasses import dataclass
import json
from pathlib import Path
import re
import subprocess

LABEL = re.compile(r"^([0-9a-f]+) <([^>]+)>:$")
INSN = re.compile(r"^\s*([0-9a-f]+):\s+([a-z][a-z0-9.]*)\s*(.*)$")
DIRECT = re.compile(r"^([0-9a-f]+)(?:\s+<([^>]+)>)?")
IMM = re.compile(r"^(?:byte|word|dword|qword)?\s*(?:strict\s+)?(-?(?:0x[0-9a-f]+|[0-9]+))$", re.I)
RSP_IMM = re.compile(r"^rsp\s*,\s*(-?(?:0x[0-9a-f]+|[0-9]+))$", re.I)
LEA_RSP = re.compile(r"^rsp\s*,\s*\[\s*rsp\s*([+-])\s*(0x[0-9a-f]+|[0-9]+)\s*\]$", re.I)
PP_LINE = re.compile(r"^%line\s+([0-9]+)\+([0-9]+)\s+(.+)$")
SOURCE_LABEL = re.compile(r"^([A-Za-z_.$?][A-Za-z0-9_.$?@]*):")
SOURCE_INSN = re.compile(r"^([A-Za-z][A-Za-z0-9.]*)\s*(.*?)\s*$")
TERMINAL = {"ret", "retq", "ud2", "hlt"}
REGS = {"rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rbp", "rsp",
        "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15"}


@dataclass(frozen=True)
class State:
    rsp: int
    rbp: int | None


@dataclass(frozen=True)
class Instruction:
    key: int
    mnemonic: str
    operands: str
    raw: str
    source_path: str = ""
    source_line: int = 0


def run(*args: str, cwd: Path) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True, errors="strict")


def parse_int(text: str) -> int | None:
    match = IMM.match(text.strip())
    return int(match.group(1), 0) if match else None


def transfer(insn: Instruction, state: State) -> tuple[State | None, str]:
    mnemonic = insn.mnemonic
    operands = insn.operands.lower().replace(" ", "")
    rsp, rbp = state.rsp, state.rbp
    if mnemonic in {"push", "pushq", "pushf", "pushfq"}:
        return State((rsp - 8) % 16, rbp), ""
    if mnemonic in {"pop", "popq", "popf", "popfq"}:
        return State((rsp + 8) % 16, rbp), ""
    if mnemonic in {"sub", "add"} and operands.startswith("rsp,"):
        amount = parse_int(operands.split(",", 1)[1])
        if amount is None:
            return None, "DYNAMIC_RSP_ARITHMETIC_NOT_PROVEN_MULTIPLE_OF_16"
        delta = -amount if mnemonic == "sub" else amount
        return State((rsp + delta) % 16, rbp), ""
    if mnemonic == "lea" and operands.startswith("rsp,"):
        match = LEA_RSP.match(insn.operands)
        if not match:
            return None, "UNMODELED_LEA_RSP"
        amount = int(match.group(2), 0) * (1 if match.group(1) == "+" else -1)
        return State((rsp + amount) % 16, rbp), ""
    if mnemonic == "mov":
        fields = [field.strip() for field in operands.split(",", 1)]
        if fields == ["rbp", "rsp"]:
            return State(rsp, rsp), ""
        if fields and fields[0] == "rsp":
            if len(fields) == 2 and fields[1] == "rbp" and rbp is not None:
                return State(rbp, rbp), ""
            return None, "UNPROVEN_MOV_TO_RSP"
    if mnemonic == "leave":
        if rbp is None:
            return None, "LEAVE_WITH_UNKNOWN_RBP"
        return State((rbp + 8) % 16, None), ""
    if mnemonic == "enter":
        fields = [field.strip() for field in operands.split(",")]
        amount = parse_int(fields[0]) if fields else None
        nesting = parse_int(fields[1]) if len(fields) > 1 else None
        if amount is None or nesting not in {0, None}:
            return None, "UNMODELED_ENTER"
        pushed = (rsp - 8) % 16
        return State((pushed - amount) % 16, pushed), ""
    if mnemonic == "and" and operands.startswith("rsp,"):
        amount = parse_int(operands.split(",", 1)[1])
        if amount is not None and (amount & 15) == 0:
            return State(0, rbp), ""
        return None, "UNPROVEN_AND_RSP_RESTORE"
    if mnemonic == "xchg" and "rsp" in {x.strip() for x in operands.split(",")}:
        return None, "UNPROVEN_XCHG_RSP"
    if re.match(r"^rsp(?:,|$)", operands) and mnemonic not in {"cmp", "test"}:
        return None, f"UNMODELED_RSP_MUTATION_{mnemonic.upper()}"
    return state, ""


def successors(keys: list[int], position: int, insn: Instruction,
               local_targets: dict[str, int], domain: set[int]) -> list[int]:
    following = keys[position + 1] if position + 1 < len(keys) else None
    mnemonic = insn.mnemonic
    if mnemonic in TERMINAL or mnemonic.startswith("ret"):
        return []
    branch = mnemonic == "jmp" or (
        mnemonic.startswith("j") and mnemonic != "jmp"
    ) or mnemonic.startswith("loop")
    if not branch:
        return [following] if following is not None else []
    target: int | None = None
    direct = DIRECT.match(insn.operands) if insn.operands[:1].isdigit() else None
    if direct:
        target = int(direct.group(1), 16)
    else:
        operand = insn.operands.split()[0].strip()
        target = local_targets.get(operand)
    result: list[int] = []
    if target in domain:
        result.append(target)
    if mnemonic != "jmp" and following is not None:
        result.append(following)
    return result


def analyze_function(function: str, instructions: dict[int, Instruction],
                     initial_rsp: int, local_targets: dict[str, int] | None = None
                     ) -> tuple[dict[int, set[State]], list[dict[str, str]]]:
    keys = sorted(instructions)
    domain = set(keys)
    positions = {key: index for index, key in enumerate(keys)}
    targets = local_targets or {}
    states: dict[int, set[State]] = defaultdict(set)
    queue: deque[tuple[int, State]] = deque([(keys[0], State(initial_rsp, None))])
    findings: list[dict[str, str]] = []
    recorded: set[tuple[int, State, str]] = set()
    while queue:
        key, state = queue.popleft()
        if key not in domain or state in states[key]:
            continue
        states[key].add(state)
        insn = instructions[key]
        if insn.mnemonic == "call":
            outcome = "PASS" if state.rsp == 0 else "CALL_ALIGNMENT_RED"
            marker = (key, state, outcome)
            if marker not in recorded:
                findings.append({"function": function, "key": str(key), "kind": "CALL",
                                 "rsp_before": str(state.rsp), "rsp_after": str(state.rsp),
                                 "outcome": outcome, "instruction": insn.raw,
                                 "source_path": insn.source_path,
                                 "source_line": str(insn.source_line)})
                recorded.add(marker)
        if insn.mnemonic.startswith("ret"):
            outcome = "PASS" if state.rsp == initial_rsp else "UNBALANCED_RETURN_RED"
            marker = (key, state, outcome)
            if marker not in recorded:
                findings.append({"function": function, "key": str(key), "kind": "RETURN",
                                 "rsp_before": str(state.rsp), "rsp_after": str(state.rsp),
                                 "outcome": outcome, "instruction": insn.raw,
                                 "source_path": insn.source_path,
                                 "source_line": str(insn.source_line)})
                recorded.add(marker)
            continue
        next_state, problem = transfer(insn, state)
        if next_state is None:
            marker = (key, state, problem)
            if marker not in recorded:
                findings.append({"function": function, "key": str(key), "kind": "UNKNOWN",
                                 "rsp_before": str(state.rsp), "rsp_after": "UNKNOWN",
                                 "outcome": problem, "instruction": insn.raw,
                                 "source_path": insn.source_path,
                                 "source_line": str(insn.source_line)})
                recorded.add(marker)
            continue
        if re.match(r"^(?:lea|add|sub)\s+rsp", f"{insn.mnemonic} {insn.operands}", re.I):
            marker = (key, state, "STACK_MUTATION")
            if marker not in recorded:
                findings.append({"function": function, "key": str(key), "kind": "STACK_MUTATION",
                                 "rsp_before": str(state.rsp), "rsp_after": str(next_state.rsp),
                                 "outcome": "MODELED", "instruction": insn.raw,
                                 "source_path": insn.source_path,
                                 "source_line": str(insn.source_line)})
                recorded.add(marker)
        for target in successors(keys, positions[key], insn, targets, domain):
            queue.append((target, next_state))
    for key, observed in states.items():
        rsp_states = {state.rsp for state in observed}
        if len(rsp_states) > 1:
            insn = instructions[key]
            findings.append({"function": function, "key": str(key), "kind": "MERGE",
                             "rsp_before": ",".join(map(str, sorted(rsp_states))),
                             "rsp_after": "UNKNOWN", "outcome": "INCOMPATIBLE_CFG_MERGE_RED",
                             "instruction": insn.raw, "source_path": insn.source_path,
                             "source_line": str(insn.source_line)})
    return states, findings


def elf_functions(root: Path, binary: Path
                  ) -> tuple[dict[str, dict[int, Instruction]], dict[int, str]]:
    globals_: dict[int, str] = {}
    for line in run("nm", "-n", "--defined-only", str(binary), cwd=root).splitlines():
        fields = line.split()
        if len(fields) >= 3 and fields[1] in {"T", "W"}:
            globals_[int(fields[0], 16)] = fields[2]
    instructions: dict[int, Instruction] = {}
    names: dict[int, str] = {}
    for line in run("objdump", "-d", "-M", "intel", "--no-show-raw-insn",
                    str(binary), cwd=root).splitlines():
        label = LABEL.match(line)
        if label:
            names[int(label.group(1), 16)] = label.group(2)
            continue
        match = INSN.match(line)
        if match:
            address = int(match.group(1), 16)
            instructions[address] = Instruction(address, match.group(2).lower(),
                                                match.group(3).strip(), line.strip())
    starts = set(globals_)
    starts.add(min(instructions))
    for insn in instructions.values():
        if insn.mnemonic == "call":
            direct = DIRECT.match(insn.operands)
            if direct and int(direct.group(1), 16) in instructions:
                starts.add(int(direct.group(1), 16))
    ordered = sorted(starts)
    result: dict[str, dict[int, Instruction]] = {}
    address_owner: dict[int, str] = {}
    all_addresses = sorted(instructions)
    for index, start in enumerate(ordered):
        if start not in instructions:
            continue
        end = ordered[index + 1] if index + 1 < len(ordered) else all_addresses[-1] + 16
        name = names.get(start, globals_.get(start, f"sub_{start:x}"))
        owner = f"{name}@0x{start:x}"
        block = {address: instructions[address] for address in all_addresses
                 if start <= address < end}
        result[owner] = block
        for address in block:
            address_owner[address] = owner
    return result, address_owner


def source_function(root: Path, source: str, function: str
                    ) -> tuple[dict[int, Instruction], dict[str, int]]:
    text = run("nasm", "-E", "-I./", source, cwd=root)
    current_path, current_line, increment = source, 1, 1
    in_text = False
    records: list[tuple[str, str, int]] = []
    for raw in text.splitlines():
        line_directive = PP_LINE.match(raw)
        if line_directive:
            current_line = int(line_directive.group(1))
            increment = int(line_directive.group(2))
            current_path = line_directive.group(3)
            continue
        stripped = raw.split(";", 1)[0].strip()
        lowered = stripped.lower().replace(" ", "")
        if lowered in {"[section.text]", "section.text"}:
            in_text = True
        elif stripped.startswith("[section ") or stripped.lower().startswith("section "):
            in_text = ".text" in lowered
        if in_text and stripped:
            records.append((stripped, current_path, current_line))
        current_line += increment
    all_instructions: dict[int, Instruction] = {}
    labels: dict[str, int] = {}
    globals_: set[str] = set()
    instruction_scope: dict[int, str] = {}
    pending_labels: list[str] = []
    scope = ""
    next_key = 0
    for line, path, number in records:
        global_match = re.match(r"^\[?global\s+([A-Za-z_.$?][A-Za-z0-9_.$?@]*)\]?$",
                                line, re.I)
        if global_match:
            globals_.add(global_match.group(1))
            continue
        label = SOURCE_LABEL.match(line)
        if label:
            label_name = label.group(1)
            if label_name.startswith("."):
                canonical = f"{scope}{label_name}"
            else:
                scope = label_name
                canonical = label_name
            pending_labels.append(canonical)
            line = line[label.end():].strip()
            if not line:
                continue
        match = SOURCE_INSN.match(line)
        if not match:
            continue
        mnemonic = match.group(1).lower()
        if mnemonic in {"align", "times", "global", "extern", "section", "bits",
                        "default", "equ", "db", "dw", "dd", "dq", "resb", "resq"}:
            continue
        key = next_key
        next_key += 1
        for label_name in pending_labels:
            labels[label_name] = key
        pending_labels.clear()
        operands = match.group(2).strip()
        if operands.startswith("."):
            token, *rest = operands.split(None, 1)
            operands = f"{scope}{token}" + (f" {rest[0]}" if rest else "")
        all_instructions[key] = Instruction(key, mnemonic, operands, line, path, number)
        instruction_scope[key] = scope
    starts = set(globals_)
    if labels:
        starts.add(min(labels, key=labels.get))
    for insn in all_instructions.values():
        if insn.mnemonic == "call":
            target = insn.operands.split()[0].strip()
            if target in labels:
                starts.add(target)
    requested = function
    if requested not in labels and "." in requested:
        suffix = "." + requested.split(".", 1)[1]
        candidates = [name for name in labels if name.endswith(suffix)]
        if len(candidates) == 1:
            requested = candidates[0]
    if requested not in labels or requested not in starts:
        return {}, {}
    start_key = labels[requested]
    next_starts = sorted(labels[name] for name in starts
                         if name in labels and labels[name] > start_key)
    end_key = next_starts[0] if next_starts else next_key
    instructions = {key: insn for key, insn in all_instructions.items()
                    if start_key <= key < end_key}
    local_targets = {name: key for name, key in labels.items()
                     if start_key <= key < end_key}
    return instructions, local_targets


def source_translation_unit(root: Path, declared_source: str, function: str
                            ) -> tuple[str, dict[int, Instruction], dict[str, int]]:
    candidates = [declared_source]
    for line in (root / "build.ninja").read_text(encoding="utf-8").splitlines():
        if ": nasm " not in line:
            continue
        right = line.split(": nasm ", 1)[1]
        fields = right.replace(" | ", " ").split()
        if declared_source in fields and fields[0] not in candidates:
            candidates.append(fields[0])
    include_directive = f'%include "{declared_source}"'
    if declared_source.endswith(".inc"):
        for directory in (root / "compiler", root / "runtime"):
            for path in sorted(directory.rglob("*.asm")):
                if include_directive in path.read_text(encoding="utf-8", errors="strict"):
                    relative = path.relative_to(root).as_posix()
                    if relative not in candidates:
                        candidates.append(relative)
    for candidate in candidates:
        block, targets = source_function(root, candidate, function)
        if block:
            return candidate, block, targets
    return declared_source, {}, {}


def write_tsv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, delimiter="\t", fieldnames=fields,
                                lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--binary", type=Path, default=Path("build/bin/neboc"))
    parser.add_argument("--inventory", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    binary = (root / args.binary).resolve() if not args.binary.is_absolute() else args.binary
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    original: list[dict[str, str]] = []
    if args.inventory:
        inventory_path = ((root / args.inventory).resolve()
                          if not args.inventory.is_absolute() else args.inventory)
        with inventory_path.open(newline="", encoding="utf-8") as stream:
            original = list(csv.DictReader(stream, delimiter="\t"))
    functions, address_owner = elf_functions(root, binary)
    elf_findings: list[dict[str, str]] = []
    elf_states: dict[int, set[State]] = {}
    function_elf_red: dict[str, bool] = {}
    for owner, block in functions.items():
        name = owner.rsplit("@0x", 1)[0]
        states, findings = analyze_function(owner, block, 0 if name == "_start" else 8)
        elf_states.update(states)
        elf_findings.extend(findings)
        function_elf_red[owner] = any(item["outcome"].endswith("_RED") or
                                      item["outcome"].startswith("UN") for item in findings)
    fields = ["function", "key", "kind", "rsp_before", "rsp_after", "outcome",
              "instruction", "source_path", "source_line"]
    write_tsv(output / "ELF-CFG-OBSERVATIONS.tsv", fields, elf_findings)
    if not original:
        calls = [item for item in elf_findings if item["kind"] == "CALL"]
        returns = [item for item in elf_findings if item["kind"] == "RETURN"]
        unknown_items = [item for item in elf_findings if item["kind"] == "UNKNOWN"]
        merges = [item for item in elf_findings if item["kind"] == "MERGE"]
        misaligned = [item for item in calls if item["outcome"] != "PASS"]
        unbalanced = [item for item in returns if item["outcome"] != "PASS"]
        summary_values = {
            "FUNCTIONS": len(functions), "CALLS": len(calls),
            "MISALIGNED": len(misaligned), "UNKNOWN": len(unknown_items),
            "MERGES": len(merges), "RETURNS": len(returns),
            "UNBALANCED_RETURNS": len(unbalanced),
        }
        oracle_pass = not (misaligned or unknown_items or merges or unbalanced)
        summary = "INDEPENDENT_WHOLE_PROGRAM_ORACLE=" + ("PASS" if oracle_pass else "RED") + "\n"
        summary += "\n".join(f"{key}={value}" for key, value in summary_values.items()) + "\n"
        (output / "ORACLE-SUMMARY.txt").write_text(summary, encoding="utf-8")
        (output / "ORACLE-REPORT.json").write_text(
            json.dumps({"schema": "NEBO-INDEPENDENT-STACK-ORACLE-v1",
                        "summary": summary_values, "findings": elf_findings},
                       indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(summary, end="")
        return 0 if oracle_pass else 1
    missing_addresses = sorted({
        int(row["virtual_address_or_offset"].split("/", 1)[0], 16)
        for row in original
        if int(row["virtual_address_or_offset"].split("/", 1)[0], 16)
        not in address_owner
    })
    if missing_addresses:
        summary = (
            "INDEPENDENT_ORACLE=RED\n"
            f"STALE_BASELINE_ADDRESSES={len(missing_addresses)}\n"
            "REMEDIATION=RUN_WITHOUT_INVENTORY_FOR_CURRENT_WHOLE_PROGRAM_STATE\n"
        )
        (output / "ORACLE-SUMMARY.txt").write_text(summary, encoding="utf-8")
        print(summary, end="")
        return 1
    source_findings: list[dict[str, str]] = []
    source_calls: dict[str, list[dict[str, str]]] = {}
    source_leas: dict[str, list[dict[str, str]]] = {}
    source_cache: dict[tuple[str, str], tuple[dict[int, Instruction], dict[str, int]]] = {}
    affected_groups = sorted({
        (address_owner[int(row["virtual_address_or_offset"].split("/", 1)[0], 16)],
         row["function_symbol"], row["source_path"])
        for row in original
    })
    for owner, function, source in affected_groups:
        translation_unit, block, targets = source_translation_unit(root, source, function)
        source_cache[(source, function)] = (block, targets)
        if not block:
            continue
        _, findings = analyze_function(owner, block, 0 if function == "_start" else 8,
                                       targets)
        source_findings.extend(findings)
        source_calls[owner] = [item for item in findings if item["kind"] == "CALL"]
        source_leas[owner] = [item for item in findings
                              if item["kind"] == "STACK_MUTATION"
                              and item["instruction"].lower().startswith("lea rsp")]
    elf_calls: dict[str, list[dict[str, str]]] = defaultdict(list)
    elf_leas: dict[str, list[dict[str, str]]] = defaultdict(list)
    for item in elf_findings:
        if item["kind"] == "CALL":
            elf_calls[item["function"]].append(item)
        if item["kind"] == "STACK_MUTATION" and "lea    rsp" in item["instruction"].lower():
            elf_leas[item["function"]].append(item)
    source_call_by_address: dict[int, dict[str, str]] = {}
    source_lea_by_address: dict[int, dict[str, str]] = {}
    correspondence_errors: list[str] = []
    for owner, function, _ in affected_groups:
        elf_items = sorted(elf_calls.get(owner, []), key=lambda item: int(item["key"]))
        source_items = sorted(source_calls.get(owner, []), key=lambda item: int(item["key"]))
        if len(elf_items) != len(source_items):
            correspondence_errors.append(
                f"{owner}:call_count elf={len(elf_items)} source={len(source_items)}"
            )
        for elf_item, source_item in zip(elf_items, source_items):
            source_call_by_address[int(elf_item["key"])] = source_item
        elf_items = sorted(elf_leas.get(owner, []), key=lambda item: int(item["key"]))
        source_items = sorted(source_leas.get(owner, []), key=lambda item: int(item["key"]))
        if len(elf_items) != len(source_items):
            correspondence_errors.append(
                f"{owner}:lea_rsp_count elf={len(elf_items)} source={len(source_items)}"
            )
        for elf_item, source_item in zip(elf_items, source_items):
            source_lea_by_address[int(elf_item["key"])] = source_item
    classification: list[dict[str, str]] = []
    unknown = 0
    confirmed = 0
    false_positive = 0
    unreachable = 0
    for row in original:
        address = int(row["virtual_address_or_offset"].split("/", 1)[0], 16)
        owner = address_owner[address]
        state_set = elf_states.get(address, set())
        state_text = ",".join(str(item.rsp) for item in sorted(state_set,
                                                                key=lambda item: item.rsp))
        reason = ""
        source_proof = ""
        dynamic_proof = "R02_SENTINEL_MATRIX"
        if row["call_kind"] in {"DIRECT", "INDIRECT"}:
            source_item = source_call_by_address.get(address)
            source_proof = source_item["rsp_before"] if source_item else "MISSING"
            if state_text == "8" and source_proof == "8":
                if row["reachability_class"] == "FINAL_NEBOC_LINKED_UNREACHABLE":
                    verdict = "UNREACHABLE_RELEASE_OBJECT_BUT_ABI_INVALID"
                    unreachable += 1
                else:
                    verdict = "CONFIRMED_REAL"
                    confirmed += 1
                reason = "source_CFG_and_ELF_agree_pre_call_rsp_mod16_8"
            else:
                verdict = "ORACLE_UNKNOWN_BLOCKER"
                unknown += 1
                reason = f"call_proof_disagrees_elf={state_text}_source={source_proof}"
        else:
            source_item = source_lea_by_address.get(address)
            source_proof = (f"{source_item['rsp_before']}->{source_item['rsp_after']}"
                            if source_item else "MISSING")
            elf_before = state_text
            elf_after = sorted({transfer(functions[owner][address], item)[0].rsp
                                for item in state_set
                                if transfer(functions[owner][address], item)[0]
                                is not None})
            elf_proof = f"{elf_before}->{','.join(map(str, elf_after))}"
            if source_proof != "MISSING" and not function_elf_red.get(owner, True):
                verdict = "FALSE_POSITIVE_PROVEN"
                false_positive += 1
                reason = f"lea_rsp_plus_8_modeled_source={source_proof}_elf={elf_proof}"
            else:
                verdict = "ORACLE_UNKNOWN_BLOCKER"
                unknown += 1
                reason = f"lea_restore_not_fully_proven_source={source_proof}_elf={elf_proof}"
        classification.append({
            "finding_id": row["finding_id"],
            "normalized_call_site_id": row["normalized_call_site_id"],
            "virtual_address": f"0x{address:x}",
            "function_symbol": row["function_symbol"],
            "reachability_class": row["reachability_class"],
            "classification": verdict,
            "elf_rsp_proof": state_text,
            "source_cfg_proof": source_proof,
            "dynamic_proof": dynamic_proof,
            "reason": reason,
            "original_validator_row": row["original_validator_row"],
        })
    write_tsv(output / "SOURCE-CFG-OBSERVATIONS.tsv", fields, source_findings)
    class_fields = ["finding_id", "normalized_call_site_id", "virtual_address",
                    "function_symbol", "reachability_class", "classification",
                    "elf_rsp_proof", "source_cfg_proof", "dynamic_proof", "reason",
                    "original_validator_row"]
    write_tsv(output / "ORIGINAL-ROW-CLASSIFICATION.tsv", class_fields, classification)
    (output / "SOURCE-ELF-CORRESPONDENCE.txt").write_text(
        (
            "\n".join(correspondence_errors) + "\n"
            if correspondence_errors
            else "PASS source/CFG and object/ELF call-site correspondence is exact\n"
        ),
        encoding="utf-8",
    )
    oracle_pass = len(classification) == 733 and unknown == 0 and not correspondence_errors
    summary = (
        f"INDEPENDENT_ORACLE={'PASS' if oracle_pass else 'RED'}\n"
        f"ORIGINAL_733_ROWS_CLASSIFIED={len(classification)}_OF_733\n"
        f"CONFIRMED_REAL={confirmed}\n"
        f"UNREACHABLE_RELEASE_OBJECT_BUT_ABI_INVALID={unreachable}\n"
        f"FALSE_POSITIVE_PROVEN={false_positive}\n"
        f"ORACLE_UNKNOWN_BLOCKERS={unknown}\n"
        f"SOURCE_ELF_CORRESPONDENCE_ERRORS={len(correspondence_errors)}\n"
    )
    (output / "ORACLE-SUMMARY.txt").write_text(summary, encoding="utf-8")
    print(summary, end="")
    return 0 if oracle_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
