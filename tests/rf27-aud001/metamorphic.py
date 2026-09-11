#!/usr/bin/env python3
"""ARRAY-VERTICAL-AUD-001 structural-dispatch metamorphic conformance corpus.

The corpus is derived from the authoritative G09-PF005..G20-PF005 public TSVs.
Every source is replayed unchanged and in three token-equivalent forms:
  * leading/trailing blank lines;
  * deliberately expanded token formatting;
  * compact formatting with coherent value-binding renaming.

The executable mode exercises neboc check, emit-asm and build. Positive cases
also execute the static ELF and require byte-identical Assembly/ELF across all
formatting variants. Negative cases must preserve their typed diagnostic and
must not leave an output artifact.
"""
from __future__ import annotations

import argparse
import csv
import dataclasses
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable, Sequence

TOKEN_RE = re.compile(
    r"(?P<ws>\s+)|(?P<comment>//[^\n]*)|"
    r"(?P<float>\d+\.\d+)|(?P<int>\d+)|"
    r"(?P<char>'(?:\\.|[^'\\])')|"
    r'(?P<text>"(?:\\.|[^"\\])*")|'
    r"(?P<identifier>[A-Za-z_][A-Za-z0-9_]*)|"
    r"(?P<operator>=>|==|!=|<=|>=|&&|\|\||[(){}\[\],;.<>:=+\-*/%!])"
)

MULTI_CHAR = {"=>", "==", "!=", "<=", ">=", "&&", "||"}


@dataclasses.dataclass(frozen=True)
class Token:
    kind: str
    text: str


@dataclasses.dataclass(frozen=True)
class Case:
    group: str
    proof_id: str
    source_path: Path
    source_sha256: str
    positive: bool
    expected_exit: int | None
    diagnostic: str | None
    message: str | None


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def tokenize(source: str) -> list[Token]:
    tokens: list[Token] = []
    cursor = 0
    while cursor < len(source):
        match = TOKEN_RE.match(source, cursor)
        if match is None:
            raise ValueError(
                f"unrecognized source byte at offset {cursor}: {source[cursor:cursor + 24]!r}"
            )
        cursor = match.end()
        kind = match.lastgroup
        if kind in {"ws", "comment"}:
            continue
        assert kind is not None
        tokens.append(Token(kind, match.group(0)))
    return tokens


def render_expanded(tokens: Sequence[Token]) -> str:
    lines: list[str] = ["", ""]
    current: list[str] = []
    indent = 0

    def flush() -> None:
        nonlocal current
        if current:
            lines.append("    " * indent + "  ".join(current))
            current = []

    for token in tokens:
        text = token.text
        if text == "}":
            flush()
            indent = max(0, indent - 1)
            current.append(text)
            flush()
            lines.append("")
        elif text == "{":
            current.append(text)
            flush()
            indent += 1
            lines.append("")
        elif text == ";":
            current.append(text)
            flush()
            lines.append("")
        elif text == ",":
            current.append(text)
        else:
            current.append(text)
    flush()
    lines.extend(["", ""])
    return "\n".join(lines)


def needs_separator(left: Token, right: Token) -> bool:
    left_word = left.kind in {"identifier", "int", "float", "char", "text"}
    right_word = right.kind in {"identifier", "int", "float", "char", "text"}
    if left_word and right_word:
        return True
    if left.text == "/" and right.text.startswith("/"):
        return True
    if left.text + right.text in MULTI_CHAR:
        return True
    return False


def render_compact(tokens: Sequence[Token]) -> str:
    if not tokens:
        return "\n"
    parts = [tokens[0].text]
    for left, right in zip(tokens, tokens[1:]):
        if needs_separator(left, right):
            parts.append(" ")
        parts.append(right.text)
    return "".join(parts) + "\n"


def start_body_indices(tokens: Sequence[Token]) -> set[int]:
    inside: set[int] = set()
    start = -1
    for index in range(len(tokens) - 3):
        if (
            tokens[index].text == "start"
            and tokens[index + 1].text == "("
            and tokens[index + 2].text == ")"
            and tokens[index + 3].text == "{"
        ):
            start = index + 3
            break
    if start < 0:
        return inside
    depth = 0
    for index in range(start, len(tokens)):
        text = tokens[index].text
        if text == "{":
            depth += 1
        elif text == "}":
            depth -= 1
        if depth >= 1:
            inside.add(index)
        if depth == 0 and index > start:
            break
    return inside


def rename_value_bindings(tokens: Sequence[Token]) -> list[Token]:
    result = list(tokens)
    inside = start_body_indices(tokens)
    if not inside:
        return result

    binding_decl_indices: dict[int, str] = {}
    statement_start = min(inside) + 1
    depth = 1
    for index in range(statement_start, len(tokens)):
        if index not in inside:
            continue
        text = tokens[index].text
        if text == "{":
            depth += 1
        elif text == "}":
            depth -= 1
        if text != ";" or depth != 1:
            continue
        statement = [i for i in range(statement_start, index + 1) if i in inside]
        if len(statement) >= 4:
            dot_index = statement[-3]
            name_index = statement[-2]
            if (
                tokens[dot_index].text == "."
                and tokens[name_index].kind == "identifier"
            ):
                prefix = statement[:-3]
                # A bare receiver.member; statement is a field read, not a
                # value-first binding declaration.  A compound expression
                # ending in receiver.member; is also a read.  Do not rename
                # such a member as though it declared a new value binding.
                nesting = 0
                has_top_level_binary = False
                previous_text = ""
                previous_kind = ""
                for prefix_index in prefix:
                    current = tokens[prefix_index]
                    if current.text in {"(", "[", "{"}:
                        nesting += 1
                    elif current.text in {")", "]", "}"}:
                        nesting = max(0, nesting - 1)
                    elif nesting == 0 and current.text in {"+", "*", "/", "%"}:
                        has_top_level_binary = True
                    elif nesting == 0 and current.text == "-":
                        # A leading/minus-after-operator token is unary; a
                        # minus after an expression-ending token is binary.
                        if previous_kind in {
                            "identifier", "int", "float", "char", "text"
                        } or previous_text in {")", "]", "}"}:
                            has_top_level_binary = True
                    previous_text = current.text
                    previous_kind = current.kind
                if (
                    not (
                        len(prefix) == 1
                        and tokens[prefix[0]].kind == "identifier"
                    )
                    and not has_top_level_binary
                ):
                    binding_decl_indices[name_index] = tokens[name_index].text
        statement_start = index + 1

    if not binding_decl_indices:
        return result

    mapping = {
        old: f"audit_binding_{number}"
        for number, old in enumerate(dict.fromkeys(binding_decl_indices.values()), 1)
    }

    for index, token in enumerate(tokens):
        if index not in inside or token.kind != "identifier":
            continue
        old = token.text
        if old not in mapping:
            continue
        previous = tokens[index - 1].text if index else ""
        following = tokens[index + 1].text if index + 1 < len(tokens) else ""
        if index in binding_decl_indices:
            result[index] = Token("identifier", mapping[old])
        elif previous != "." and following != ":":
            result[index] = Token("identifier", mapping[old])
    return result


def variants(source: str) -> dict[str, str]:
    tokens = tokenize(source)
    renamed = rename_value_bindings(tokens)
    return {
        "exact": source,
        "blank-lines": "\n\n\t" + source + "\n\n",
        "expanded": render_expanded(tokens),
        "compact-renamed": render_compact(renamed),
    }


def load_cases(root: Path) -> list[Case]:
    cases: list[Case] = []
    for group_number in range(9, 21):
        group = f"G{group_number:02d}"
        corpus = root / f"tests/goldens/g{group_number:02d}-pf005"
        with (corpus / "public-positive.tsv").open(
            encoding="utf-8", newline=""
        ) as handle:
            for row in csv.DictReader(handle, delimiter="\t"):
                cases.append(
                    Case(
                        group=group,
                        proof_id=row["proof_id"],
                        source_path=root / row["source"],
                        source_sha256=row["source_sha256"],
                        positive=True,
                        expected_exit=int(row["expected_exit"]),
                        diagnostic=None,
                        message=None,
                    )
                )
        with (corpus / "public-diagnostics.tsv").open(
            encoding="utf-8", newline=""
        ) as handle:
            for row in csv.DictReader(handle, delimiter="\t"):
                cases.append(
                    Case(
                        group=group,
                        proof_id=row["proof_id"],
                        source_path=root / row["source"],
                        source_sha256=row["source_sha256"],
                        positive=False,
                        expected_exit=None,
                        diagnostic=row["diagnostic"],
                        message=row["message"],
                    )
                )
    if len(cases) != 128:
        raise SystemExit(f"RF27_AUD001_CORPUS_ERROR expected=128 actual={len(cases)}")
    positives = sum(case.positive for case in cases)
    negatives = len(cases) - positives
    if (positives, negatives) != (50, 78):
        raise SystemExit(
            f"RF27_AUD001_CORPUS_ERROR positives={positives} negatives={negatives}"
        )
    for case in cases:
        actual = sha256_bytes(case.source_path.read_bytes())
        # The STREAM-EVENT-E-PROCESSAMENTO-CONTINUO TSV hashes are historical evidence and already drifted
        # before ARRAY-VERTICAL-AUD-001 through trailing-whitespace normalization.  P1
        # does not rewrite that P2 evidence.  G09-G12 hashes remain exact.
        if actual != case.source_sha256 and int(case.group[1:]) <= 12:
            raise SystemExit(
                f"RF27_AUD001_SOURCE_HASH_ERROR proof={case.proof_id} "
                f"expected={case.source_sha256} actual={actual}"
            )
    return cases


def token_signature(source: str) -> list[str]:
    return [token.text for token in tokenize(source)]


def self_test(cases: Sequence[Case]) -> dict[str, int]:
    generated = 0
    renamed = 0
    for case in cases:
        source = case.source_path.read_text(encoding="utf-8")
        original_tokens = token_signature(source)
        case_variants = variants(source)
        if set(case_variants) != {"exact", "blank-lines", "expanded", "compact-renamed"}:
            raise SystemExit(f"RF27_AUD001_VARIANT_SET_ERROR proof={case.proof_id}")
        for name, transformed in case_variants.items():
            transformed_tokens = token_signature(transformed)
            if name != "compact-renamed" and transformed_tokens != original_tokens:
                raise SystemExit(
                    f"RF27_AUD001_TOKEN_DRIFT proof={case.proof_id} variant={name}"
                )
            generated += 1
        if case_variants["compact-renamed"] != render_compact(tokenize(source)):
            renamed += 1
    hash_drift = sum(
        sha256_bytes(case.source_path.read_bytes()) != case.source_sha256
        for case in cases
    )
    return {
        "cases": len(cases),
        "generated": generated,
        "renamed": renamed,
        "historical_hash_drift": hash_drift,
    }


def run_command(command: Sequence[str], *, timeout: int = 25) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            list(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise SystemExit(
            f"RF27_AUD001_TIMEOUT command={json.dumps(list(command))} timeout={timeout}"
        ) from error


def require_empty_output(result: subprocess.CompletedProcess[bytes], label: str) -> None:
    if result.stdout or result.stderr:
        raise SystemExit(
            f"RF27_AUD001_UNEXPECTED_OUTPUT {label} "
            f"stdout={result.stdout[:240]!r} stderr={result.stderr[:240]!r}"
        )


def run_positive(
    neboc: Path,
    case: Case,
    variant_name: str,
    source_path: Path,
    work: Path,
) -> tuple[str, str]:
    stem = f"{case.proof_id}-{variant_name}"
    assembly = work / f"{stem}.asm"
    elf = work / f"{stem}.elf"

    result = run_command([str(neboc), "check", str(source_path)])
    if result.returncode != 0:
        raise SystemExit(
            f"RF27_AUD001_POSITIVE_CHECK proof={case.proof_id} variant={variant_name} "
            f"rc={result.returncode} stderr={result.stderr[:400]!r}"
        )
    require_empty_output(result, f"positive-check:{case.proof_id}:{variant_name}")

    result = run_command(
        [str(neboc), "emit-asm", str(source_path), "-o", str(assembly)]
    )
    if result.returncode != 0 or not assembly.is_file():
        raise SystemExit(
            f"RF27_AUD001_POSITIVE_EMIT proof={case.proof_id} variant={variant_name} "
            f"rc={result.returncode} stderr={result.stderr[:400]!r}"
        )
    require_empty_output(result, f"positive-emit:{case.proof_id}:{variant_name}")

    result = run_command([str(neboc), "build", str(source_path), "-o", str(elf)])
    if result.returncode != 0 or not elf.is_file():
        raise SystemExit(
            f"RF27_AUD001_POSITIVE_BUILD proof={case.proof_id} variant={variant_name} "
            f"rc={result.returncode} stderr={result.stderr[:400]!r}"
        )
    require_empty_output(result, f"positive-build:{case.proof_id}:{variant_name}")

    result = run_command([str(elf)], timeout=10)
    expected = case.expected_exit
    assert expected is not None
    if result.returncode != expected:
        raise SystemExit(
            f"RF27_AUD001_NATIVE_EXIT proof={case.proof_id} variant={variant_name} "
            f"actual={result.returncode} expected={expected} "
            f"stdout={result.stdout[:240]!r} stderr={result.stderr[:240]!r}"
        )
    require_empty_output(result, f"positive-native:{case.proof_id}:{variant_name}")
    return sha256_bytes(assembly.read_bytes()), sha256_bytes(elf.read_bytes())


def run_negative(
    neboc: Path,
    case: Case,
    variant_name: str,
    source_path: Path,
    work: Path,
) -> None:
    diagnostic = case.diagnostic
    assert diagnostic is not None
    for mode in ("check", "emit-asm", "build"):
        artifact = work / f"{case.proof_id}-{variant_name}-{mode}.artifact"
        command = [str(neboc), mode, str(source_path)]
        if mode != "check":
            command += ["-o", str(artifact)]
        result = run_command(command)
        if result.returncode != 1:
            raise SystemExit(
                f"RF27_AUD001_NEGATIVE_RC proof={case.proof_id} variant={variant_name} "
                f"mode={mode} rc={result.returncode} stderr={result.stderr[:400]!r}"
            )
        if result.stdout:
            raise SystemExit(
                f"RF27_AUD001_NEGATIVE_STDOUT proof={case.proof_id} "
                f"variant={variant_name} mode={mode} stdout={result.stdout[:240]!r}"
            )
        if diagnostic.encode("utf-8") not in result.stderr:
            raise SystemExit(
                f"RF27_AUD001_NEGATIVE_DIAGNOSTIC proof={case.proof_id} "
                f"variant={variant_name} mode={mode} expected={diagnostic} "
                f"stderr={result.stderr[:500]!r}"
            )
        message = case.message
        assert message is not None
        if message.encode("utf-8") not in result.stderr:
            raise SystemExit(
                f"RF27_AUD001_NEGATIVE_MESSAGE proof={case.proof_id} "
                f"variant={variant_name} mode={mode} expected={message!r} "
                f"stderr={result.stderr[:700]!r}"
            )
        if artifact.exists():
            raise SystemExit(
                f"RF27_AUD001_NEGATIVE_ARTIFACT proof={case.proof_id} "
                f"variant={variant_name} mode={mode} artifact={artifact}"
            )


def execute(root: Path, neboc: Path, output_root: Path) -> dict[str, object]:
    cases = load_cases(root)
    test_summary = self_test(cases)
    output_root.mkdir(parents=True, exist_ok=True)
    sources = output_root / "sources"
    artifacts = output_root / "artifacts"
    sources.mkdir(exist_ok=True)
    artifacts.mkdir(exist_ok=True)

    positive_variants = 0
    negative_variants = 0
    renamed_cases = 0
    per_group: dict[str, dict[str, int]] = {}

    for case in cases:
        source = case.source_path.read_text(encoding="utf-8")
        rendered = variants(source)
        if rendered["compact-renamed"] != render_compact(tokenize(source)):
            renamed_cases += 1
        group_counts = per_group.setdefault(
            case.group, {"positive": 0, "negative": 0, "variants": 0}
        )
        baseline_asm: str | None = None
        baseline_elf: str | None = None
        for variant_name, variant_source in rendered.items():
            case_dir = sources / case.group / case.proof_id
            case_dir.mkdir(parents=True, exist_ok=True)
            source_path = case_dir / f"{variant_name}.no"
            source_path.write_text(variant_source, encoding="utf-8")
            group_counts["variants"] += 1
            if case.positive:
                positive_variants += 1
                group_counts["positive"] += 1
                asm_sha, elf_sha = run_positive(
                    neboc, case, variant_name, source_path, artifacts
                )
                if baseline_asm is None:
                    baseline_asm, baseline_elf = asm_sha, elf_sha
                elif (asm_sha, elf_sha) != (baseline_asm, baseline_elf):
                    raise SystemExit(
                        f"RF27_AUD001_FORMAT_DETERMINISM proof={case.proof_id} "
                        f"variant={variant_name} asm={asm_sha}/{baseline_asm} "
                        f"elf={elf_sha}/{baseline_elf}"
                    )
            else:
                negative_variants += 1
                group_counts["negative"] += 1
                run_negative(neboc, case, variant_name, source_path, artifacts)

    summary: dict[str, object] = {
        "original_cases": len(cases),
        "positive_originals": sum(case.positive for case in cases),
        "negative_originals": sum(not case.positive for case in cases),
        "variants_per_case": 4,
        "generated_cases": positive_variants + negative_variants,
        "positive_variants": positive_variants,
        "negative_variants": negative_variants,
        "renamed_cases": renamed_cases,
        "token_self_test": test_summary,
        "groups": per_group,
    }
    (output_root / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--neboc", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    cases = load_cases(root)
    summary = self_test(cases)
    if args.self_test:
        print(
            "RF27_AUD001_METAMORPHIC_SELFTEST_GREEN "
            f"cases={summary['cases']} generated={summary['generated']} "
            f"renamed={summary['renamed']} "
            f"historical_hash_drift={summary['historical_hash_drift']}"
        )
        return 0
    if args.neboc is None:
        parser.error("--neboc is required unless --self-test is used")
    neboc = args.neboc.resolve()
    if not neboc.is_file():
        raise SystemExit(f"RF27_AUD001_NEBOC_MISSING path={neboc}")
    if args.output is None:
        with tempfile.TemporaryDirectory(prefix="rf27-aud001-") as temporary:
            result = execute(root, neboc, Path(temporary))
    else:
        result = execute(root, neboc, args.output.resolve())
    print(
        "RF27_AUD001_METAMORPHIC_GREEN "
        f"originals={result['original_cases']} generated={result['generated_cases']} "
        f"positive_variants={result['positive_variants']} "
        f"negative_variants={result['negative_variants']} "
        f"renamed_cases={result['renamed_cases']} modes=check_emit_build_native"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
