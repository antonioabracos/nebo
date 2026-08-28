#!/usr/bin/env python3
"""Fail-closed System V AMD64 stack-state audit for ELF files and objects."""
from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict, deque
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess

LABEL = re.compile(r"^([0-9a-f]+) <([^>]+)>:$")
INSTRUCTION = re.compile(r"^\s*([0-9a-f]+):\s+([a-z][a-z0-9.]*)\s*(.*)$")
DIRECT = re.compile(r"^(?:0x)?([0-9a-f]+)(?:\s+<([^>]+)>)?", re.I)
IMMEDIATE = re.compile(r"^-?(?:0x[0-9a-f]+|[0-9]+)$", re.I)
RSP_ARITHMETIC = re.compile(r"^rsp\s*,\s*(.+)$", re.I)
LEA_RSP = re.compile(r"^rsp\s*,\s*\[\s*rsp\s*([+-])\s*(0x[0-9a-f]+|[0-9]+)\s*\]$", re.I)
TERMINAL = {"ud2", "hlt"}
REPORT_FIELDS = [
    "finding_id", "normalized_call_site_id", "artifact", "artifact_class",
    "function", "function_class", "address", "instruction", "call_kind",
    "target", "rsp_states", "depth_states", "outcome", "reason",
]


@dataclass(frozen=True, order=True)
class State:
    rsp: int
    depth: int | None
    rbp_rsp: int | None = None
    rbp_depth: int | None = None
    red_zone_live: bool = False


@dataclass(frozen=True)
class Insn:
    address: int
    mnemonic: str
    operands: str
    raw: str


@dataclass
class ArtifactResult:
    artifact: str
    artifact_class: str
    functions: int = 0
    calls: int = 0
    direct_calls: int = 0
    indirect_calls: int = 0
    unreachable_calls: int = 0
    returns: int = 0
    tail_jumps: int = 0
    findings: list[dict[str, str]] | None = None


def command(*argv: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(argv, cwd=cwd, text=True, errors="strict")


def parse_immediate(text: str) -> int | None:
    value = text.strip().lower()
    if not IMMEDIATE.match(value):
        return None
    return int(value, 0)


def artifact_type(path: Path) -> str:
    header = command("readelf", "-hW", str(path))
    match = re.search(r"^\s*Type:\s+(\S+)", header, re.M)
    return match.group(1) if match else "UNKNOWN"


def artifact_class(path: Path, primary: Path) -> str:
    if path == primary:
        return "FINAL_LINKED_ELF"
    value = path.as_posix()
    if "/runtime/" in value or path.name.startswith("runtime"):
        return "RELEASE_RUNTIME_OBJECT"
    if "/compiler/" in value or "build/obj" in value:
        return "RELEASE_COMPILER_OBJECT"
    if "x11" in value.lower():
        return "X11_LIVE_BACKEND"
    if "sdk" in value.lower():
        return "SDK_EXECUTABLE"
    if "test" in value.lower():
        return "TEST_ONLY"
    return "ADDITIONAL_ELF_OR_OBJECT"


def decode(path: Path) -> tuple[dict[int, Insn], dict[int, str], dict[int, str], str]:
    elf_type = artifact_type(path)
    symbols: dict[int, str] = {}
    # Local `t` symbols in NASM objects also include branch labels. Treating
    # each as a normal callee invents entry states mid-function. Global text
    # symbols are factual object entry contracts; local helpers are resolved
    # and analyzed in the final linked ELF, while their object-only bodies are
    # retained as explicitly classified unreachable instructions.
    accepted = {"T", "W"}
    for line in command("nm", "-n", "--defined-only", str(path)).splitlines():
        fields = line.split()
        if len(fields) >= 3 and fields[1] in accepted:
            symbols.setdefault(int(fields[0], 16), fields[2])
    instructions: dict[int, Insn] = {}
    labels: dict[int, str] = {}
    for line in command("objdump", "-d", "-M", "intel", "--no-show-raw-insn", str(path)).splitlines():
        label = LABEL.match(line)
        if label:
            labels[int(label.group(1), 16)] = label.group(2)
            continue
        match = INSTRUCTION.match(line)
        if match:
            address = int(match.group(1), 16)
            instructions[address] = Insn(address, match.group(2).lower(),
                                         match.group(3).strip(), line.strip())
    if not instructions:
        raise ValueError("no executable instructions decoded")
    return instructions, symbols, labels, elf_type


def direct_target(operands: str) -> int | None:
    match = DIRECT.match(operands.strip())
    return int(match.group(1), 16) if match else None


def target_text(operands: str) -> str:
    match = DIRECT.match(operands.strip())
    if match:
        return match.group(2) or f"0x{int(match.group(1), 16):x}"
    return operands.strip().split()[0] if operands.strip() else "UNKNOWN"


def writes_red_zone(insn: Insn) -> bool:
    if insn.mnemonic in {"cmp", "test", "lea", "prefetch", "prefetcht0", "prefetcht1"}:
        return False
    destination = insn.operands.split(",", 1)[0].replace(" ", "").lower()
    return bool(re.search(r"\[rsp-(?:0x[0-9a-f]+|[0-9]+)\]", destination))


def transfer(insn: Insn, state: State) -> tuple[State | None, str]:
    mnemonic = insn.mnemonic
    operands = insn.operands.strip()
    lowered = operands.lower().replace("ptr ", "")
    red_zone = state.red_zone_live or writes_red_zone(insn)
    if mnemonic in {"push", "pushq", "pushf", "pushfq"}:
        depth = None if state.depth is None else state.depth - 8
        return State((state.rsp - 8) % 16, depth, state.rbp_rsp,
                     state.rbp_depth, red_zone), ""
    if mnemonic in {"pop", "popq", "popf", "popfq"}:
        depth = None if state.depth is None else state.depth + 8
        return State((state.rsp + 8) % 16, depth, state.rbp_rsp,
                     state.rbp_depth, red_zone), ""
    if mnemonic in {"sub", "add"}:
        match = RSP_ARITHMETIC.match(lowered)
        if match:
            amount = parse_immediate(match.group(1))
            if amount is None:
                return None, f"DYNAMIC_{mnemonic.upper()}_RSP_NOT_PROVEN"
            delta = -amount if mnemonic == "sub" else amount
            depth = None if state.depth is None else state.depth + delta
            return State((state.rsp + delta) % 16, depth, state.rbp_rsp,
                         state.rbp_depth, red_zone), ""
    if mnemonic == "lea" and lowered.lower().startswith("rsp"):
        match = LEA_RSP.match(lowered)
        if not match:
            return None, "UNMODELED_LEA_RSP"
        amount = int(match.group(2), 0) * (1 if match.group(1) == "+" else -1)
        depth = None if state.depth is None else state.depth + amount
        return State((state.rsp + amount) % 16, depth, state.rbp_rsp,
                     state.rbp_depth, red_zone), ""
    if mnemonic == "mov":
        fields = [field.strip() for field in lowered.lower().split(",", 1)]
        if fields == ["rbp", "rsp"]:
            return State(state.rsp, state.depth, state.rsp, state.depth, red_zone), ""
        if fields and fields[0] == "rsp":
            if len(fields) == 2 and fields[1] == "rbp" and state.rbp_rsp is not None:
                return State(state.rbp_rsp, state.rbp_depth, state.rbp_rsp,
                             state.rbp_depth, red_zone), ""
            return None, "UNPROVEN_MOV_TO_RSP"
    if mnemonic == "and" and lowered.lower().startswith("rsp"):
        fields = [field.strip() for field in lowered.split(",", 1)]
        mask = parse_immediate(fields[1]) if len(fields) == 2 else None
        if mask is None or (mask & 15) != 0:
            return None, "UNPROVEN_AND_RSP_MASK"
        return State(0, None, state.rbp_rsp, state.rbp_depth, red_zone), ""
    if mnemonic == "xchg" and "rsp" in {field.strip() for field in lowered.lower().split(",")}:
        return None, "UNPROVEN_XCHG_RSP"
    if mnemonic == "enter":
        fields = [field.strip() for field in lowered.split(",")]
        size = parse_immediate(fields[0]) if fields else None
        nesting = parse_immediate(fields[1]) if len(fields) > 1 else 0
        if size is None or nesting != 0:
            return None, "UNMODELED_ENTER"
        pushed_rsp = (state.rsp - 8) % 16
        pushed_depth = None if state.depth is None else state.depth - 8
        depth = None if pushed_depth is None else pushed_depth - size
        return State((pushed_rsp - size) % 16, depth, pushed_rsp,
                     pushed_depth, red_zone), ""
    if mnemonic == "leave":
        if state.rbp_rsp is None:
            return None, "LEAVE_WITH_UNKNOWN_RBP"
        depth = None if state.rbp_depth is None else state.rbp_depth + 8
        return State((state.rbp_rsp + 8) % 16, depth, None, None, red_zone), ""
    destination = lowered.lower().split(",", 1)[0].strip()
    if destination == "rsp":
        return None, f"UNMODELED_RSP_MUTATION_{mnemonic.upper()}"
    return State(state.rsp, state.depth, state.rbp_rsp, state.rbp_depth, red_zone), ""


def successors(keys: list[int], positions: dict[int, int], insn: Insn,
               domain: set[int]) -> tuple[list[int], int | None]:
    position = positions[insn.address]
    following = keys[position + 1] if position + 1 < len(keys) else None
    if insn.mnemonic.startswith("ret") or insn.mnemonic in TERMINAL:
        return [], None
    branch = insn.mnemonic == "jmp" or (
        insn.mnemonic.startswith("j") and insn.mnemonic != "jmp"
    ) or insn.mnemonic.startswith("loop")
    if not branch:
        return ([following] if following in domain else []), None
    destination = direct_target(insn.operands)
    result: list[int] = []
    if destination in domain:
        result.append(destination)
    if insn.mnemonic != "jmp" and following in domain:
        result.append(following)
    tail = destination if insn.mnemonic == "jmp" and destination not in domain else None
    return result, tail


def stable_id(*fields: str) -> str:
    payload = "\0".join(fields).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:24]


def state_key(state: State) -> tuple[int, int, int, int, int, int, int]:
    return (
        state.rsp, state.depth is None, state.depth or 0,
        state.rbp_rsp is None, state.rbp_rsp or 0,
        state.rbp_depth is None, state.rbp_depth or 0,
    )


def analyze_function(artifact: str, artifact_kind: str, function: str,
                     function_identity: str, function_class: str,
                     block: dict[int, Insn], initial_rsp: int,
                     normal_tail_targets: set[int]
                     ) -> tuple[list[dict[str, str]], int, int]:
    keys = sorted(block)
    positions = {key: index for index, key in enumerate(keys)}
    domain = set(keys)
    states: dict[int, set[State]] = defaultdict(set)
    queue: deque[tuple[int, State]] = deque([(keys[0], State(initial_rsp, 0))])
    unknown: dict[tuple[int, str], State] = {}
    tail_states: dict[int, set[State]] = defaultdict(set)
    state_explosion: set[int] = set()
    while queue:
        address, state = queue.popleft()
        if address not in domain or state in states[address]:
            continue
        if len(states[address]) >= 32:
            state_explosion.add(address)
            continue
        states[address].add(state)
        insn = block[address]
        if insn.mnemonic.startswith("ret"):
            continue
        next_state, problem = transfer(insn, state)
        if next_state is None:
            unknown[(address, problem)] = state
            continue
        following, tail = successors(keys, positions, insn, domain)
        if tail is not None:
            tail_states[address].add(next_state)
        for destination in following:
            queue.append((destination, next_state))

    findings: list[dict[str, str]] = []
    call_addresses = [address for address in keys if block[address].mnemonic == "call"]
    for ordinal, address in enumerate(call_addresses, 1):
        insn = block[address]
        observed = states.get(address, set())
        kind = "DIRECT" if direct_target(insn.operands) is not None else "INDIRECT"
        normalized = stable_id(artifact, function_identity, str(ordinal), kind,
                               target_text(insn.operands))
        if not observed:
            outcome, reason = "UNREACHABLE_CLASSIFIED", "no_CFG_path_from_function_entry"
        else:
            bad_alignment = any(state.rsp != 0 for state in observed)
            red_zone = any(state.red_zone_live for state in observed)
            outcome = "CALL_ALIGNMENT_RED" if bad_alignment or red_zone else "PASS"
            reason = (
                "red_zone_live_across_call" if red_zone else
                "pre_call_rsp_mod16_not_zero" if bad_alignment else
                "pre_call_rsp_mod16_zero"
            )
        findings.append({
            "finding_id": "STACK-" + normalized,
            "normalized_call_site_id": "STACK-SITE-" + normalized,
            "artifact": artifact, "artifact_class": artifact_kind,
            "function": function, "function_class": function_class,
            "address": f"0x{address:x}", "instruction": insn.raw,
            "call_kind": kind, "target": target_text(insn.operands),
            "rsp_states": ",".join(map(str, sorted({state.rsp for state in observed}))) or "UNREACHABLE",
            "depth_states": ",".join("UNKNOWN" if value is None else str(value)
                                       for value in sorted({state.depth for state in observed},
                                                           key=lambda item: (item is None, item or 0))) or "UNREACHABLE",
            "outcome": outcome, "reason": reason,
        })
    for (address, reason), state in sorted(unknown.items()):
        normalized = stable_id(artifact, function_identity, f"0x{address:x}", reason)
        findings.append({
            "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
            "artifact": artifact, "artifact_class": artifact_kind,
            "function": function, "function_class": function_class,
            "address": f"0x{address:x}", "instruction": block[address].raw,
            "call_kind": "", "target": "", "rsp_states": str(state.rsp),
            "depth_states": "UNKNOWN" if state.depth is None else str(state.depth),
            "outcome": "STACK_STATE_UNKNOWN_RED", "reason": reason,
        })
    for address, observed in sorted(states.items()):
        if len(observed) > 1:
            normalized = stable_id(artifact, function_identity, f"0x{address:x}", "MERGE")
            findings.append({
                "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
                "artifact": artifact, "artifact_class": artifact_kind,
                "function": function, "function_class": function_class,
                "address": f"0x{address:x}", "instruction": block[address].raw,
                "call_kind": "", "target": "",
                "rsp_states": ",".join(map(str, sorted({state.rsp for state in observed}))),
                "depth_states": ",".join("UNKNOWN" if state.depth is None else str(state.depth)
                                           for state in sorted(observed, key=state_key)),
                "outcome": "CFG_STACK_MERGE_CONFLICT_RED",
                "reason": "multiple_stack_states_at_CFG_join",
            })
    returns = 0
    for address in keys:
        insn = block[address]
        if not insn.mnemonic.startswith("ret"):
            continue
        observed = states.get(address, set())
        if not observed:
            continue
        returns += 1
        operands = insn.operands.strip()
        if operands and parse_immediate(operands) not in (None, 0):
            normalized = stable_id(artifact, function_identity, f"0x{address:x}", "RETURN-IMM16")
            findings.append({
                "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
                "artifact": artifact, "artifact_class": artifact_kind,
                "function": function, "function_class": function_class,
                "address": f"0x{address:x}", "instruction": insn.raw,
                "call_kind": "", "target": "",
                "rsp_states": ",".join(map(str, sorted({state.rsp for state in observed}))),
                "depth_states": ",".join("UNKNOWN" if state.depth is None else str(state.depth)
                                           for state in sorted(observed, key=state_key)),
                "outcome": "RET_IMM16_CONVENTION_RED",
                "reason": "System_V_AMD64_normal_functions_must_not_pop_caller_arguments",
            })
        bad = [state for state in observed if state.rsp != initial_rsp or state.depth != 0]
        if bad:
            normalized = stable_id(artifact, function_identity, f"0x{address:x}", "RETURN")
            findings.append({
                "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
                "artifact": artifact, "artifact_class": artifact_kind,
                "function": function, "function_class": function_class,
                "address": f"0x{address:x}", "instruction": insn.raw,
                "call_kind": "", "target": "",
                "rsp_states": ",".join(map(str, sorted({state.rsp for state in observed}))),
                "depth_states": ",".join("UNKNOWN" if state.depth is None else str(state.depth)
                                           for state in sorted(observed, key=state_key)),
                "outcome": "UNBALANCED_RETURN_RED",
                "reason": "return_rsp_or_frame_depth_differs_from_entry",
            })
    for address, observed in sorted(tail_states.items()):
        destination = direct_target(block[address].operands)
        if function_class == "PROCESS_ENTRYPOINT" or destination not in normal_tail_targets:
            continue
        bad = [state for state in observed if state.rsp != 8 or state.depth != 0]
        if bad:
            normalized = stable_id(artifact, function_identity, f"0x{address:x}", "TAIL")
            findings.append({
                "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
                "artifact": artifact, "artifact_class": artifact_kind,
                "function": function, "function_class": function_class,
                "address": f"0x{address:x}", "instruction": block[address].raw,
                "call_kind": "TAIL_JUMP", "target": target_text(block[address].operands),
                "rsp_states": ",".join(map(str, sorted({state.rsp for state in observed}))),
                "depth_states": ",".join("UNKNOWN" if state.depth is None else str(state.depth)
                                           for state in sorted(observed, key=state_key)),
                "outcome": "TAIL_JUMP_ALIGNMENT_RED",
                "reason": "tail_target_requires_normal_callee_entry_state",
            })
    for address in sorted(state_explosion):
        normalized = stable_id(artifact, function_identity, f"0x{address:x}", "EXPLOSION")
        findings.append({
            "finding_id": "STACK-" + normalized, "normalized_call_site_id": "",
            "artifact": artifact, "artifact_class": artifact_kind,
            "function": function, "function_class": function_class,
            "address": f"0x{address:x}", "instruction": block[address].raw,
            "call_kind": "", "target": "", "rsp_states": "UNKNOWN",
            "depth_states": "UNKNOWN", "outcome": "STACK_STATE_UNKNOWN_RED",
            "reason": "unbounded_or_nonconvergent_stack_state_loop",
        })
    return findings, returns, len(tail_states)


def analyze_artifact(path: Path, primary: Path, display: str) -> ArtifactResult:
    instructions, symbols, labels, elf_type = decode(path)
    starts = set(symbols)
    starts.add(min(instructions))
    if elf_type != "REL":
        for insn in instructions.values():
            if insn.mnemonic == "call":
                target = direct_target(insn.operands)
                if target in instructions:
                    starts.add(target)
    ordered = sorted(start for start in starts if start in instructions)
    addresses = sorted(instructions)
    kind = artifact_class(path, primary)
    result = ArtifactResult(display, kind, findings=[])
    name_occurrences: Counter[str] = Counter()
    for index, start in enumerate(ordered):
        end = ordered[index + 1] if index + 1 < len(ordered) else addresses[-1] + 16
        block = {address: instructions[address] for address in addresses if start <= address < end}
        if not block:
            continue
        name = labels.get(start, symbols.get(start, f"sub_{start:x}"))
        name_occurrences[name] += 1
        identity = f"{name}#{name_occurrences[name]}"
        function_class = "PROCESS_ENTRYPOINT" if name == "_start" else (
            "LOCAL_LABEL" if symbols.get(start, "").islower() else "NORMAL_CALLEE"
        )
        initial = 0 if function_class == "PROCESS_ENTRYPOINT" else 8
        tail_targets = set(symbols) if elf_type != "REL" else set()
        findings, returns, tails = analyze_function(
            display, kind, name, identity, function_class, block, initial,
            tail_targets,
        )
        result.functions += 1
        result.returns += returns
        result.tail_jumps += tails
        for item in findings:
            if item["call_kind"] in {"DIRECT", "INDIRECT"}:
                result.calls += 1
                result.direct_calls += item["call_kind"] == "DIRECT"
                result.indirect_calls += item["call_kind"] == "INDIRECT"
                result.unreachable_calls += item["outcome"] == "UNREACHABLE_CLASSIFIED"
        result.findings.extend(findings)
    result.findings.sort(key=lambda row: (
        row["artifact"], row["function"], int(row["address"], 16), row["outcome"]
    ))
    return result


def ninja_inputs(root: Path, target: str) -> list[Path]:
    output = command("ninja", "-t", "inputs", target, cwd=root)
    return sorted({(root / line.strip()).resolve() for line in output.splitlines()
                   if line.strip().endswith(".o") and (root / line.strip()).is_file()})


def write_tsv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, delimiter="\t", fieldnames=REPORT_FIELDS,
                                lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("--artifact", action="append", type=Path, default=[])
    parser.add_argument("--release-objects", action="append", type=Path, default=[])
    parser.add_argument("--ninja-target", action="append", default=[])
    parser.add_argument("--report-tsv", type=Path)
    parser.add_argument("--report-json", type=Path)
    args = parser.parse_args()
    root = Path.cwd().resolve()
    primary = args.binary.resolve()
    if not primary.is_file():
        raise SystemExit(f"MF056_STACK_ALIGNMENT_FAIL: missing binary {primary}")
    artifacts = {primary}
    artifacts.update(path.resolve() for path in args.artifact)
    for directory in args.release_objects:
        artifacts.update(path.resolve() for path in directory.rglob("*.o"))
    for target in args.ninja_target:
        artifacts.update(ninja_inputs(root, target))
    missing = sorted(str(path) for path in artifacts if not path.is_file())
    if missing:
        raise SystemExit(f"MF056_STACK_ALIGNMENT_FAIL: missing artifacts {missing}")
    results: list[ArtifactResult] = []
    for path in sorted(artifacts, key=lambda item: (item != primary, item.as_posix())):
        try:
            display = path.relative_to(root).as_posix()
        except ValueError:
            display = path.as_posix()
        try:
            results.append(analyze_artifact(path, primary, display))
        except (subprocess.CalledProcessError, ValueError) as error:
            print(f"MF056_STACK_ALIGNMENT_FAIL: {display}: {error}")
            return 1
    rows = [row for result in results for row in (result.findings or [])]
    rows.sort(key=lambda row: (
        row["artifact"], row["function"], int(row["address"], 16), row["outcome"]
    ))
    ids = [row["normalized_call_site_id"] for row in rows
           if row["normalized_call_site_id"]]
    duplicates = sorted(key for key, count in Counter(ids).items() if count > 1)
    failure_outcomes = {
        "CALL_ALIGNMENT_RED", "STACK_STATE_UNKNOWN_RED",
        "CFG_STACK_MERGE_CONFLICT_RED", "UNBALANCED_RETURN_RED",
        "TAIL_JUMP_ALIGNMENT_RED", "RET_IMM16_CONVENTION_RED",
    }
    failures = [row for row in rows if row["outcome"] in failure_outcomes]
    if duplicates:
        failures.append({field: "" for field in REPORT_FIELDS} | {
            "finding_id": "DUPLICATE_NORMALIZED_IDS", "outcome": "DUPLICATE_ID_RED",
            "reason": ",".join(duplicates),
        })
    summary = {
        "artifacts": len(results),
        "functions": sum(result.functions for result in results),
        "calls": sum(result.calls for result in results),
        "direct_calls": sum(result.direct_calls for result in results),
        "indirect_calls": sum(result.indirect_calls for result in results),
        "unreachable_calls": sum(result.unreachable_calls for result in results),
        "returns": sum(result.returns for result in results),
        "tail_jumps": sum(result.tail_jumps for result in results),
        "failures": len(failures),
        "unknown": sum(row["outcome"] == "STACK_STATE_UNKNOWN_RED" for row in failures),
        "merge_conflicts": sum(row["outcome"] == "CFG_STACK_MERGE_CONFLICT_RED" for row in failures),
        "unbalanced_returns": sum(row["outcome"] == "UNBALANCED_RETURN_RED" for row in failures),
        "duplicate_ids": len(duplicates),
    }
    if args.report_tsv:
        write_tsv(args.report_tsv, rows)
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        payload = {"schema": "NEBO-STACK-STATE-REPORT-v1", "summary": summary,
                   "artifacts": [asdict(result) | {"findings": None} for result in results],
                   "findings": rows}
        args.report_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n",
                                    encoding="utf-8")
    if failures:
        for row in failures:
            legacy = ""
            if row.get("outcome") == "CALL_ALIGNMENT_RED":
                legacy = f": call with rsp mod16={row.get('rsp_states')} in {row.get('function')}"
            print(f"MF056_STACK_ALIGNMENT_FAIL: {row.get('artifact')} {row.get('address')} "
                  f"{row.get('outcome')} {row.get('reason')}{legacy}")
        return 1
    print("MF056_STACK_ALIGNMENT_GREEN " + " ".join(
        f"{key}={value}" for key, value in summary.items()
    ))
    print(f"DIRECT_CALLS={summary['direct_calls']} INDIRECT_CALLS={summary['indirect_calls']}")
    print(f"UNREACHABLE_CALLS_CLASSIFIED={summary['unreachable_calls']}")
    print("UNKNOWN_ACCEPTED=0 NORMAL_CALLEE_ENTRY_RSP_MOD16=8 PROCESS_ENTRYPOINT_RSP_POLICY=SEPARATE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
