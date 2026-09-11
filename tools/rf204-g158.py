#!/usr/bin/env python3
"""G158 executable semantic documentation over G155-G157 authorities."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import stat
import struct
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build" / "bin" / "neboc"
PROBE = ROOT / "build" / "bin" / "nebo-doc-examples"
REQUEST = struct.Struct("<40Q")
RESULT = struct.Struct("<8Q")
MAGIC = 0x38353158434F444E
VERSION = 1
MAX_SOURCE_BYTES = 16_384
MAX_BUDGET = 64
MAX_TIMEOUT_MS = 5_000
MAX_OUTPUT_BYTES = 8_192
PENDING = 0xFFFF_FFFF_FFFF_FFFF
TRI_MODE = 7

OP_PLAN = 1
OP_COMPILE = 2
OP_RUN = 3
OP_LAW = 4
OP_STALENESS = 5
OP_COMPATIBILITY = 6
OP_REDACTION = 7

KIND_EXAMPLE = 1
KIND_LAW = 2
PRIVACY_PUBLIC = 1
PRIVACY_PRIVATE = 2
PRIVACY_SECRET = 3

FLAG_TARGET_SUPPORTED = 1
FLAG_RUNTIME_ALLOWED = 2
FLAG_OLD_PRESENT = 4
FLAG_NEW_PRESENT = 8
FLAG_REFACTOR_MAP = 16
FLAG_PATH_REDACTED = 32

CLASSES = {
    1: "READY", 2: "COMPILED", 3: "MATCH", 4: "LAW_PASS",
    5: "FRESH", 6: "STALE", 7: "PRESERVED", 8: "ADDITIVE",
    9: "COMPATIBLE", 10: "BREAKING", 11: "UNKNOWN",
    12: "PUBLIC", 13: "REDACTED",
}
LABEL = re.compile(r"^(?:(public|private|secret)-)?(?:law-)?exit-([0-9]{1,3})$")


class DocumentationError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.source: str | None = None
        self.primary: tuple[int, int] | None = None


def fnv(data: bytes) -> int:
    value = 0xCBF29CE484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001B3) & 0xFFFF_FFFF_FFFF_FFFF
    return value or 1


def identity(value: object) -> int:
    if isinstance(value, int):
        return value
    try:
        return int(str(value), 0)
    except ValueError as error:
        raise DocumentationError("NEBO-RF166-G158-005", "baseline contains an invalid identity") from error


def relative(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return path.name


def read_regular(raw: str, limit: int = MAX_SOURCE_BYTES) -> tuple[Path, bytes]:
    path = Path(raw).absolute()
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise DocumentationError("NEBO-RF166-G158-IO", "cannot open a requested regular file") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
            raise DocumentationError("NEBO-RF166-G158-IO", "input must be a bounded regular non-symlink file")
        data = b""
        while len(data) <= limit:
            part = os.read(descriptor, min(4096, limit + 1 - len(data)))
            if not part:
                break
            data += part
        if len(data) > limit:
            raise DocumentationError("NEBO-RF166-G158-IO", "input exceeds the executable-documentation bound")
        data.decode("utf-8", "strict")
        return path, data
    except UnicodeDecodeError as error:
        raise DocumentationError("NEBO-RF166-G158-IO", "input is not valid UTF-8") from error
    finally:
        os.close(descriptor)


def sources(values: list[str]) -> list[Path]:
    selected: list[Path] = []
    for raw in values:
        path = Path(raw)
        if path.is_dir() and not path.is_symlink():
            selected.extend(item for item in path.rglob("*.no") if item.is_file() and not item.is_symlink())
        else:
            selected.append(path)
    return sorted({item.absolute() for item in selected}, key=lambda item: relative(item))


def compiler(arguments: list[str], *, timeout: int = 20) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [str(COMPILER), *arguments], stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout,
        check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )


def compiler_json(arguments: list[str], code: str) -> dict[str, object]:
    result = compiler(arguments)
    if result.returncode or result.stderr:
        raise DocumentationError(code, "a prerequisite documentation/compiler stage rejected the source")
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocumentationError(code, "a prerequisite stage returned invalid JSON transport") from error
    if not isinstance(value, dict):
        raise DocumentationError(code, "a prerequisite stage returned the wrong transport shape")
    return value


def request(operation: int, common: dict[str, int], **changes: int) -> list[int]:
    words = [0] * 40
    words[0:9] = [
        MAGIC, VERSION, operation, common["symbol"], common["fixture"],
        common["source"], common["context"], common["snippet"], common["kind"],
    ]
    words[32] = 1
    words[33] = common["timeout"]
    words[35] = common["output_limit"]
    words[36] = FLAG_TARGET_SUPPORTED
    offsets = {
        "requested_modes": 9, "observed_modes": 10,
        "declared_effects": 11, "allowed_effects": 12,
        "declared_capabilities": 13, "granted_capabilities": 14,
        "expected_exit": 15, "observed_exit": 16, "seed": 17,
        "budget": 18, "observed_cases": 19, "observed_failures": 20,
        "current_signature": 21, "previous_signature": 22,
        "old_symbol": 23, "new_symbol": 24, "old_api": 25,
        "new_api": 26, "doc_revision": 27, "old_doc_revision": 28,
        "privacy": 29, "raw_output": 30, "published_output": 31,
        "target": 32, "timeout": 33, "output_bytes": 34,
        "output_limit": 35, "flags": 36,
    }
    for name, value in changes.items():
        words[offsets[name]] = value & 0xFFFF_FFFF_FFFF_FFFF
    return words


def native(words: list[int], code: str, message: str) -> dict[str, object]:
    if len(words) != 40 or not PROBE.is_file():
        raise DocumentationError("NEBO-RF166-G158-IO", "native executable-documentation owner is unavailable")
    result = subprocess.run(
        [str(PROBE)], input=REQUEST.pack(*words), stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=10, check=False, env={},
    )
    if result.returncode or result.stderr or len(result.stdout) != RESULT.size:
        raise DocumentationError(code, message)
    status, operation, symbol, fixture, digest, class_id, expected, observed = RESULT.unpack(result.stdout)
    if status or operation != words[2] or symbol != words[3] or fixture != words[4] or class_id not in CLASSES:
        raise DocumentationError("NEBO-RF166-G158-IO", "native owner returned invalid transport")
    return {
        "operation": operation, "class": CLASSES[class_id],
        "digest": f"0x{digest:016x}", "expected": expected, "observed": observed,
    }


def field_text(ast: dict[str, object], data: bytes) -> dict[str, str]:
    result: dict[str, str] = {}
    try:
        for node in ast["fieldNodes"]:
            start, length = node["payload"]["span"]
            if start < 0 or length < 0 or start + length > len(data):
                raise ValueError
            result[str(node["kind"])] = data[start:start + length].decode("utf-8", "strict")
    except (KeyError, TypeError, ValueError, UnicodeDecodeError) as error:
        raise DocumentationError("NEBO-RF166-G158-001", "canonical DocBlockAst contains an invalid field span") from error
    return result


def policy_mask(value: str, empty: set[str]) -> int:
    values = {item.strip().lower() for item in value.split(";") if item.strip()}
    values -= empty
    mask = 0
    for item in sorted(values):
        mask |= 1 << (fnv(item.encode("utf-8")) % 63)
    return mask


def label_contract(raw: str, kind: str) -> tuple[int, int]:
    match = LABEL.fullmatch(raw)
    if match is None:
        raise DocumentationError("NEBO-RF166-G158-001", f"{kind} label must encode a bounded expected exit")
    expected = int(match.group(2))
    if expected > 255:
        raise DocumentationError("NEBO-RF166-G158-001", f"{kind} expected exit exceeds 255")
    privacy = {None: PRIVACY_PUBLIC, "public": PRIVACY_PUBLIC, "private": PRIVACY_PRIVATE, "secret": PRIVACY_SECRET}[match.group(1)]
    return expected, privacy


def limit_process() -> None:
    resource.setrlimit(resource.RLIMIT_CPU, (5, 5))
    resource.setrlimit(resource.RLIMIT_FSIZE, (MAX_OUTPUT_BYTES, MAX_OUTPUT_BYTES))
    resource.setrlimit(resource.RLIMIT_NOFILE, (16, 16))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def tri_compile(snippet: bytes, kind: str, directory: Path) -> tuple[Path, int]:
    source = directory / f"{kind}.no"
    assembly = directory / f"{kind}.asm"
    artifact = directory / f"{kind}.elf"
    source.write_bytes(snippet)
    modes = (
        ["check", str(source)],
        ["emit-asm", str(source), "-o", str(assembly)],
        ["build", str(source), "-o", str(artifact)],
    )
    observed = 0
    for bit, arguments in zip((1, 2, 4), modes):
        result = compiler(arguments)
        if result.returncode or result.stdout or result.stderr:
            raise DocumentationError("NEBO-RF166-G158-002", f"embedded {kind} failed compiler mode {arguments[0]}")
        observed |= bit
    if not assembly.is_file() or not artifact.is_file():
        raise DocumentationError("NEBO-RF166-G158-002", f"embedded {kind} did not publish compiler artifacts")
    inspected = subprocess.run(
        ["/usr/bin/file", str(artifact)], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=5, check=False, env={"LC_ALL": "C"},
    )
    undefined = subprocess.run(
        ["/usr/bin/nm", "-u", str(artifact)], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=5, check=False, env={"LC_ALL": "C"},
    )
    program_headers = subprocess.run(
        ["/usr/bin/readelf", "-lW", str(artifact)], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=5, check=False, env={"LC_ALL": "C"},
    )
    if (
        inspected.returncode or b"statically linked" not in inspected.stdout
        or undefined.returncode or undefined.stdout or program_headers.returncode
        or b"INTERP" in program_headers.stdout
    ):
        raise DocumentationError("NEBO-RF166-G158-002", f"embedded {kind} is not an isolated static artifact")
    return artifact, observed


def run_artifact(artifact: Path, timeout_ms: int, output_limit: int) -> tuple[int, bytes]:
    out = artifact.with_suffix(".stdout")
    err = artifact.with_suffix(".stderr")
    try:
        with out.open("wb") as stdout, err.open("wb") as stderr:
            result = subprocess.run(
                [str(artifact)], stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                timeout=timeout_ms / 1000, check=False, env={}, preexec_fn=limit_process,
            )
    except subprocess.TimeoutExpired as error:
        raise DocumentationError("NEBO-RF166-G158-003", "embedded execution exceeded its timeout") from error
    payload = out.read_bytes() + err.read_bytes()
    if len(payload) > output_limit:
        raise DocumentationError("NEBO-RF166-G158-007", "embedded execution exceeded its output budget")
    if result.returncode < 0 or result.returncode > 255:
        raise DocumentationError("NEBO-RF166-G158-003", "embedded execution terminated outside the exit contract")
    return result.returncode, payload


def load_json(raw: str | None, label: str) -> dict[str, object]:
    if raw is None:
        return {}
    _, data = read_regular(raw, 262_144)
    try:
        value = json.loads(data)
    except json.JSONDecodeError as error:
        raise DocumentationError("NEBO-RF166-G158-005", f"{label} is not valid JSON") from error
    if not isinstance(value, dict) or value.get("schema") != 1:
        raise DocumentationError("NEBO-RF166-G158-005", f"{label} has an unsupported schema")
    return value


def baseline_entry(baseline: dict[str, object], name: str) -> dict[str, object] | None:
    documents = baseline.get("documents", {})
    if not isinstance(documents, dict):
        raise DocumentationError("NEBO-RF166-G158-005", "baseline documents must be an object")
    value = documents.get(name)
    if value is not None and not isinstance(value, dict):
        raise DocumentationError("NEBO-RF166-G158-005", "baseline document entry must be an object")
    return value


def refactor_target(mapping: dict[str, object], old_symbol: int) -> int | None:
    mappings = mapping.get("mappings", {})
    if not isinstance(mappings, dict):
        raise DocumentationError("NEBO-RF166-G158-005", "refactor mappings must be an object")
    value = mappings.get(f"0x{old_symbol:016x}")
    return identity(value) if value is not None else None


def verify_source(
    path: Path, data: bytes, command: str, seed: int, budget: int,
    timeout_ms: int, output_limit: int, baseline: dict[str, object],
    refactors: dict[str, object],
) -> dict[str, object]:
    name = relative(path)
    ast = compiler_json(["dump", "doc-ast", str(path)], "NEBO-RF166-G158-001")
    if ast.get("parserAuthority") != "native:compiler/parser/doc_lexer.asm":
        raise DocumentationError("NEBO-RF166-G158-001", "executable docs require the canonical DocParser")
    record = compiler_json(["dump", "doc-record", str(path)], "NEBO-RF166-G158-001")
    if command == "docs --verify":
        checked = compiler_json(["check-docs", str(path), "--deny", "warnings", "--report", "json"], "NEBO-RF166-G158-001")
        if checked.get("issueCount") != 0:
            raise DocumentationError("NEBO-RF166-G158-001", "semantic documentation validation failed")
    fields = field_text(ast, data)
    embedded = ast.get("embeddedCode")
    if not isinstance(embedded, list) or any(
        not isinstance(item, dict) or item.get("kind") not in {"example", "law"}
        for item in embedded
    ):
        raise DocumentationError("NEBO-RF166-G158-001", "canonical executable-documentation nodes are invalid")
    if embedded and ("effects" not in fields or "capabilities" not in fields):
        raise DocumentationError(
            "NEBO-RF166-G158-007",
            "embedded execution requires explicit effects and capabilities documentation",
        )
    effects = policy_mask(fields.get("effects", "none"), {"none", "pure"})
    capabilities = policy_mask(fields.get("capabilities", "none"), {"none"})
    if effects or capabilities:
        raise DocumentationError("NEBO-RF166-G158-007", "embedded code requested an ungranted effect or capability")
    symbol = identity(record.get("symbolId"))
    signature = identity(record.get("signatureHash"))
    source_digest = fnv(data)
    context_digest = identity(ast.get("astDigest"))
    document_revision = fnv(json.dumps(record.get("text", {}), sort_keys=True, separators=(",", ":")).encode("utf-8"))
    fixtures: list[dict[str, object]] = []
    for ordinal, item in enumerate(sorted(embedded, key=lambda value: str(value["kind"]))):
        kind = str(item["kind"])
        kind_id = KIND_EXAMPLE if kind == "example" else KIND_LAW
        expected, privacy = label_contract(str(item["name"]), kind)
        start, length = item["span"]
        if start < 0 or length < 1 or start + length > len(data):
            raise DocumentationError("NEBO-RF166-G158-001", "embedded code span is outside its source")
        snippet = data[start:start + length]
        common = {
            "symbol": symbol, "fixture": fnv(f"{name}:{kind}:{ordinal}".encode("utf-8")),
            "source": source_digest, "context": context_digest,
            "snippet": fnv(snippet), "kind": kind_id,
            "timeout": timeout_ms, "output_limit": output_limit,
        }
        plan = native(request(OP_PLAN, common), "NEBO-RF166-G158-001", "native example planning rejected the fixture")
        with tempfile.TemporaryDirectory(prefix="nebo-g158-") as raw_directory:
            artifact, modes = tri_compile(snippet, kind, Path(raw_directory))
            compiled = native(
                request(OP_COMPILE, common, requested_modes=TRI_MODE, observed_modes=modes),
                "NEBO-RF166-G158-002", "native tri-mode evidence rejected the fixture",
            )
            if kind == "example":
                native(
                    request(
                        OP_RUN, common, declared_effects=effects,
                        declared_capabilities=capabilities, expected_exit=expected,
                        observed_exit=PENDING,
                        flags=FLAG_TARGET_SUPPORTED | FLAG_RUNTIME_ALLOWED,
                    ),
                    "NEBO-RF166-G158-007", "execution policy denied the example",
                )
                observed, output = run_artifact(artifact, timeout_ms, output_limit)
                execution = native(
                    request(
                        OP_RUN, common, declared_effects=effects,
                        declared_capabilities=capabilities, expected_exit=expected,
                        observed_exit=observed, output_bytes=len(output), raw_output=fnv(output),
                        flags=FLAG_TARGET_SUPPORTED | FLAG_RUNTIME_ALLOWED,
                    ),
                    "NEBO-RF166-G158-003", "example output or exit did not match its contract",
                )
                cases = 1
            else:
                outputs: list[bytes] = []
                observed_failures = 0
                for _ in range(budget):
                    observed, output = run_artifact(artifact, timeout_ms, output_limit)
                    outputs.append(output)
                    observed_failures += int(observed != expected)
                execution = native(
                    request(
                        OP_LAW, common, seed=seed, budget=budget,
                        observed_cases=budget, observed_failures=observed_failures,
                    ),
                    "NEBO-RF166-G158-004", "bounded law corpus found a counterexample",
                )
                if len({hashlib.sha256(value).digest() for value in outputs}) != 1:
                    raise DocumentationError("NEBO-RF166-G158-008", "law output is nondeterministic for a fixed corpus")
                output = outputs[0]
                cases = budget
            raw_output = fnv(output)
            if privacy == PRIVACY_PUBLIC:
                published_output = raw_output
                redaction_flags = FLAG_TARGET_SUPPORTED
            else:
                published_output = fnv(b"<redacted>")
                redaction_flags = FLAG_TARGET_SUPPORTED | FLAG_PATH_REDACTED
            redaction = native(
                request(
                    OP_REDACTION, common, privacy=privacy, raw_output=raw_output,
                    published_output=published_output, flags=redaction_flags,
                ),
                "NEBO-RF166-G158-007", "output privacy/redaction policy rejected the fixture",
            )
        fixtures.append({
            "kind": kind, "name": item["name"], "expectedExit": expected,
            "cases": cases, "plan": plan["class"], "compile": compiled["class"],
            "execution": execution["class"], "privacy": redaction["class"],
            "snippetSha256": hashlib.sha256(snippet).hexdigest(),
        })

    previous = baseline_entry(baseline, name)
    previous_signature = identity(previous.get("signatureHash")) if previous else 0
    old_symbol = identity(previous.get("symbolId")) if previous else 0
    old_revision = identity(previous.get("docRevision")) if previous else 0
    flags = FLAG_TARGET_SUPPORTED
    mapped = refactor_target(refactors, old_symbol) if previous else None
    if mapped == symbol:
        flags |= FLAG_REFACTOR_MAP
    common = {
        "symbol": symbol, "fixture": fnv(name.encode("utf-8")),
        "source": source_digest, "context": context_digest, "snippet": signature,
        "kind": KIND_EXAMPLE, "timeout": timeout_ms, "output_limit": output_limit,
    }
    staleness = native(
        request(
            OP_STALENESS, common, current_signature=signature,
            previous_signature=previous_signature, old_symbol=old_symbol,
            new_symbol=symbol, doc_revision=document_revision,
            old_doc_revision=old_revision, flags=flags,
        ),
        "NEBO-RF166-G158-005", "native staleness/refactor classification failed",
    )
    compatibility_flags = FLAG_NEW_PRESENT | (FLAG_OLD_PRESENT if previous else 0)
    compatibility = native(
        request(
            OP_COMPATIBILITY, common,
            old_api=identity(previous.get("apiDigest")) if previous else 0,
            new_api=signature, doc_revision=document_revision,
            flags=compatibility_flags,
        ),
        "NEBO-RF166-G158-006", "native compatibility classification failed",
    )
    if staleness["class"] == "STALE":
        raise DocumentationError("NEBO-RF166-G158-005", "documentation is stale for the current SymbolId/signature")
    if compatibility["class"] == "BREAKING":
        raise DocumentationError("NEBO-RF166-G158-006", "documentation compatibility check found a breaking API change")
    return {
        "source": name, "symbolId": f"0x{symbol:016x}",
        "signatureHash": f"0x{signature:016x}",
        "apiDigest": f"0x{signature:016x}",
        "docRevision": f"0x{document_revision:016x}",
        "staleness": staleness["class"], "compatibility": compatibility["class"],
        "fixtures": fixtures,
    }


def render_text(envelope: dict[str, object]) -> str:
    lines = [
        f"{item['source']}: VERIFIED examples={len(item['fixtures'])} "
        f"staleness={item['staleness']} compatibility={item['compatibility']}"
        for item in envelope["documents"]
    ]
    lines.append(
        f"verified={envelope['summary']['documents']} fixtures={envelope['summary']['fixtures']} "
        f"law-cases={envelope['summary']['lawCases']}"
    )
    return "\n".join(lines) + "\n"


def main(arguments: list[str]) -> int:
    if not arguments:
        raise DocumentationError("NEBO-RF166-G158-IO", "expected test-docs or docs --verify")
    if arguments[0] == "test-docs":
        command = "test-docs"
        rest = arguments[1:]
    elif len(arguments) >= 2 and arguments[:2] == ["docs", "--verify"]:
        command = "docs --verify"
        rest = arguments[2:]
    else:
        raise DocumentationError("NEBO-RF166-G158-IO", "expected test-docs or docs --verify")
    parser = argparse.ArgumentParser(prog=f"neboc {command}")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--report", choices=("text", "json"), default="text")
    parser.add_argument("--seed", type=int, default=158)
    parser.add_argument("--budget", type=int, default=8)
    parser.add_argument("--timeout-ms", type=int, default=1_000)
    parser.add_argument("--output-limit", type=int, default=1_024)
    parser.add_argument("--baseline")
    parser.add_argument("--refactor-map")
    options = parser.parse_args(rest)
    if options.seed <= 0 or not 1 <= options.budget <= MAX_BUDGET:
        raise DocumentationError("NEBO-RF166-G158-004", "seed must be positive and budget must be 1..64")
    if not 1 <= options.timeout_ms <= MAX_TIMEOUT_MS or not 1 <= options.output_limit <= MAX_OUTPUT_BYTES:
        raise DocumentationError("NEBO-RF166-G158-007", "timeout/output limits exceed the bounded policy")
    baseline = load_json(options.baseline, "baseline")
    refactors = load_json(options.refactor_map, "refactor map")
    selected = sources(options.paths)
    if not selected:
        raise DocumentationError("NEBO-RF166-G158-IO", "no Nebo sources were selected")
    documents = []
    for path in selected:
        resolved, data = read_regular(str(path))
        before = hashlib.sha256(data).digest()
        try:
            documents.append(
                verify_source(
                    resolved, data, command, options.seed, options.budget,
                    options.timeout_ms, options.output_limit, baseline, refactors,
                )
            )
        except DocumentationError as error:
            error.source = relative(resolved)
            error.primary = (0, max(1, len(data)))
            raise
        _, after = read_regular(str(path))
        if hashlib.sha256(after).digest() != before:
            raise DocumentationError("NEBO-RF166-G158-008", "documentation verification observed source mutation")
    fixtures = sum(len(item["fixtures"]) for item in documents)
    law_cases = sum(
        fixture["cases"] for item in documents for fixture in item["fixtures"]
        if fixture["kind"] == "law"
    )
    envelope = {
        "schema": 1, "command": command, "seed": options.seed,
        "budget": options.budget, "documents": documents,
        "summary": {"documents": len(documents), "fixtures": fixtures, "lawCases": law_cases},
        "sourceMutation": False, "effectsExecutedBeforeAuthorization": False,
        "universalProofClaim": False,
        "owners": {
            "parser": "compiler/parser/doc_lexer.asm",
            "record": "compiler/semantic/docs/doc_record.asm",
            "validation": "compiler/semantic/docs/doc_*validator.asm",
            "execution": "compiler/docs/doc_example_*.asm",
        },
    }
    if options.report == "json":
        print(json.dumps(envelope, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    else:
        sys.stdout.write(render_text(envelope))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (DocumentationError, OSError, subprocess.TimeoutExpired) as error:
        code = error.code if isinstance(error, DocumentationError) else "NEBO-RF166-G158-IO"
        location = ""
        if isinstance(error, DocumentationError) and error.source is not None and error.primary is not None:
            start, length = error.primary
            location = f"; primary={error.source}:byte={start}..{start + length}; related=NONE"
        print(
            f"{code}: {error}{location}; note=no verified documentation artifact was published",
            file=sys.stderr,
        )
        raise SystemExit(1)
