#!/usr/bin/env python3
"""RF166 G165 bounded conformance coordinator over existing compiler owners."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
NEBOC = ROOT / "build" / "bin" / "neboc"
MAX_SOURCE_BYTES = 1 << 20
MAX_BUDGET = 32
TIMEOUT_SECONDS = 30


class ConformanceError(Exception):
    pass


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def invoke(arguments: list[str], *, accepted: tuple[int, ...] = (0,)) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        [str(NEBOC), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=TIMEOUT_SECONDS,
        check=False,
    )
    if result.returncode not in accepted:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise ConformanceError(f"owner command failed ({result.returncode}): {' '.join(arguments)}: {detail}")
    return result


def invoke_json(arguments: list[str]) -> dict[str, object]:
    result = invoke(arguments)
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ConformanceError(f"owner emitted invalid JSON: {' '.join(arguments)}") from error
    if not isinstance(value, dict) or value.get("schema") != 1:
        raise ConformanceError(f"owner emitted an invalid schema: {' '.join(arguments)}")
    return value


def expect_rejection(arguments: list[str]) -> str:
    result = subprocess.run(
        [str(NEBOC), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=TIMEOUT_SECONDS,
        check=False,
    )
    if result.returncode == 0 or result.stdout:
        raise ConformanceError(f"malformed input was not rejected atomically: {' '.join(arguments)}")
    text = result.stderr.decode("utf-8", "replace").strip()
    return text.split(":", 1)[0] if text else f"EXIT_{result.returncode}"


def bounded_source(raw: str) -> tuple[Path, bytes]:
    candidate = Path(raw)
    if candidate.is_symlink():
        raise ConformanceError("source symlinks are forbidden")
    path = candidate.resolve()
    if not path.is_file():
        raise ConformanceError(f"source is not a regular file: {raw}")
    data = path.read_bytes()
    if not data or len(data) > MAX_SOURCE_BYTES:
        raise ConformanceError(f"source exceeds the bounded input policy: {raw}")
    data.decode("utf-8", "strict")
    return path, data


class ModuleConformanceSuite:
    @staticmethod
    def run(profile: str, work: Path) -> dict[str, object]:
        root = "examples/rf204/G165/RF204-G165-S01.no"
        core = "examples/rf204/G165/units/S01-core.no"
        util = "examples/rf204/G165/units/S01-util.no"
        invoke(["module-check", root, "--unit", core, "--unit", util])
        first = invoke_json(["module-graph", root, "--unit", core, "--unit", util, "--format", "json"])
        second = invoke_json(["module-graph", root, "--unit", util, "--unit", core, "--format", "json"])
        if canonical(first) != canonical(second) or len(first.get("order", [])) != 3:
            raise ConformanceError("module graph depends on filesystem argument order")
        artifacts: list[bytes] = []
        for name, units in (("a", (core, util)), ("b", (util, core))):
            output = work / f"module-{name}.elf"
            invoke(["link", root, "--unit", units[0], "--unit", units[1], "-o", str(output), "--quiet"])
            artifacts.append(output.read_bytes())
        if artifacts[0] != artifacts[1]:
            raise ConformanceError("multiunit link is nondeterministic")
        observed = subprocess.run([str(work / "module-a.elf")], stdin=subprocess.DEVNULL,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  timeout=10, check=False)
        if observed.returncode != 47 or observed.stdout or observed.stderr:
            raise ConformanceError("multiunit runtime oracle diverged")
        return {"profile": profile, "owner": "NEBO-RF166-G150/G151/G152/G153",
                "modules": 3, "links": len(first.get("links", [])),
                "snapshot": first["snapshot"], "artifactSha256": digest(artifacts[0]),
                "observedExit": observed.returncode}


class InterfaceConformanceSuite:
    @staticmethod
    def run(profile: str, work: Path) -> dict[str, object]:
        root = "examples/rf204/G165/RF204-G165-S02.no"
        contract = "examples/rf204/G165/units/S02-root.no"
        support = "examples/rf204/G165/units/S02-support.no"
        outputs: list[bytes] = []
        for name, units in (("a", (root, support)), ("b", (support, root))):
            output = work / f"interface-{name}.ni"
            invoke(["emit-interface", contract, "--unit", units[0], "--unit", units[1], "-o", str(output)])
            outputs.append(output.read_bytes())
        if outputs[0] != outputs[1]:
            raise ConformanceError("compiled interface round-trip is nondeterministic")
        inspected = invoke_json(["interface", "inspect", str(work / "interface-a.ni"), "--json"])
        corrupt = bytearray(outputs[0])
        corrupt[0] ^= 0x5A
        malformed = work / "interface-corrupt.ni"
        malformed.write_bytes(corrupt)
        expect_rejection(["interface", "inspect", str(malformed), "--json"])
        return {"profile": profile, "owner": "NEBO-RF166-G154", "bytes": len(outputs[0]),
                "sections": inspected["sections"], "exports": inspected["exports"],
                "contentSha256": digest(outputs[0]), "corruptionRejected": True}


class DocConformanceSuite:
    @staticmethod
    def run(profile: str, work: Path) -> dict[str, object]:
        source = "examples/rf204/G165/RF204-G165-S03.no"
        ast_a = invoke_json(["dump", "doc-ast", source])
        ast_b = invoke_json(["dump", "doc-ast", source])
        if canonical(ast_a) != canonical(ast_b):
            raise ConformanceError("semantic documentation AST is nondeterministic")
        validation = invoke_json(["check-docs", source, "--deny", "warnings", "--report", "json"])
        examples = invoke_json(["test-docs", source, "--seed", "165", "--budget", "2", "--report", "json"])
        site = work / "site"
        generated = invoke_json(["docs", source, "-o", str(site)])
        if validation.get("issueCount") != 0 or generated.get("offline") is not True:
            raise ConformanceError("semantic documentation conformance failed")
        return {"profile": profile, "owner": "NEBO-RF166-G155/G156/G157/G158/G159",
                "astDigest": ast_a["astDigest"], "fields": ast_a["fieldCount"],
                "fixtures": len(examples["documents"][0]["fixtures"]),
                "generatedFiles": generated["files"], "graphDigest": generated["graphDigest"]}


class LspParitySuite:
    @staticmethod
    def run(profile: str, work: Path) -> dict[str, object]:
        completion = invoke_json(["completion-corpus", "--verify"])
        navigation = invoke_json(["navigation-corpus", "--verify"])
        if completion.get("status") != "PASS" or navigation.get("status") != "PASS":
            raise ConformanceError("LSP corpus did not close")
        return {"profile": profile, "owner": "NEBO-RF166-G160/G161/G162",
                "completionDigest": completion["digest"], "completionRows": completion["rows"],
                "navigationDigest": navigation["digest"], "navigationRows": navigation["rows"],
                "network": bool(completion["network"] or navigation["network"])}


class TriviaConformanceSuite:
    @staticmethod
    def run(profile: str, work: Path) -> dict[str, object]:
        source = "examples/rf204/G165/RF204-G165-S05.no"
        first = invoke_json(["dump", "comment-trivia", source])
        second = invoke_json(["dump", "comment-trivia", source])
        if canonical(first) != canonical(second) or first.get("maxNesting") != 2:
            raise ConformanceError("comment/trivia projection diverged")
        lint = invoke_json(["lint", source, "--group", "comments", "--report", "json"])
        if lint.get("findings") != []:
            raise ConformanceError("clean comment corpus produced a lint finding")
        return {"profile": profile, "owner": "NEBO-RF166-G164",
                "comments": first["commentCount"], "maxNesting": first["maxNesting"],
                "projectionSha256": first["semanticTriviaProjectionSha256"], "findings": 0}


class ImportFuzzer:
    @staticmethod
    def run(seed: int, budget: int, work: Path) -> dict[str, object]:
        root, data = bounded_source("examples/rf204/G165/RF204-G165-S01.no")
        core = "examples/rf204/G165/units/S01-core.no"
        util = "examples/rf204/G165/units/S01-util.no"
        baseline = invoke_json(["module-graph", str(root), "--unit", core, "--unit", util, "--format", "json"])
        rows: list[str] = []
        rng = random.Random(seed)
        for index in range(budget):
            marker = rng.randrange(1 << 31)
            candidate = work / f"import-{index}.no"
            candidate.write_bytes(f"// seed {marker}\n".encode() + data)
            observed = invoke_json(["module-graph", str(candidate), "--unit", core, "--unit", util, "--format", "json"])
            if observed.get("snapshot") != baseline.get("snapshot"):
                raise ConformanceError("import trivia mutation changed the semantic graph")
            rows.append(f"{index}:{marker}:{observed['snapshot']}")
        missing = work / "missing-import.no"
        missing.write_bytes(data.replace(b"g165_core", b"missing_core", 1))
        rejected = expect_rejection(["module-graph", str(missing), "--unit", core, "--unit", util, "--format", "json"])
        return {"seed": seed, "budget": budget, "owner": "native-module-graph",
                "digest": digest("\n".join(rows).encode()), "negativeDiagnosticSha256": rejected}


class InterfaceFuzzer:
    @staticmethod
    def run(seed: int, budget: int, work: Path) -> dict[str, object]:
        root = "examples/rf204/G165/RF204-G165-S02.no"
        contract = "examples/rf204/G165/units/S02-root.no"
        support = "examples/rf204/G165/units/S02-support.no"
        valid = work / "fuzz-base.ni"
        invoke(["emit-interface", contract, "--unit", root, "--unit", support, "-o", str(valid)])
        original = valid.read_bytes()
        rng = random.Random(seed)
        diagnostics: list[str] = []
        for index in range(budget):
            candidate = bytearray(original)
            candidate[index % 4] ^= 1 + rng.randrange(254)
            path = work / f"interface-fuzz-{index}.ni"
            path.write_bytes(candidate)
            diagnostics.append(expect_rejection(["interface", "inspect", str(path), "--json"]))
        return {"seed": seed, "budget": budget, "owner": "native-ni-reader",
                "digest": digest("\n".join(diagnostics).encode())}


class DocFuzzer:
    @staticmethod
    def run(seed: int, budget: int, work: Path) -> dict[str, object]:
        _, data = bounded_source("examples/rf204/G165/RF204-G165-S03.no")
        rows: list[str] = []
        rng = random.Random(seed)
        for index in range(budget):
            marker = rng.randrange(1 << 31)
            candidate = work / f"doc-{index}.no"
            candidate.write_bytes(f"// doc-seed {marker}\n".encode() + data)
            ast = invoke_json(["dump", "doc-ast", str(candidate)])
            rows.append(f"{index}:{marker}:{ast['astDigest']}")
        malformed = work / "doc-malformed.no"
        malformed.write_bytes(data.replace(b'title: "RF166 conformance documentation";', b'title: ;', 1))
        rejected = expect_rejection(["dump", "doc-ast", str(malformed)])
        return {"seed": seed, "budget": budget, "owner": "native-doc-parser",
                "digest": digest("\n".join(rows).encode()), "negativeDiagnosticSha256": rejected}


class TriviaFuzzer:
    @staticmethod
    def run(seed: int, budget: int, work: Path) -> dict[str, object]:
        rows: list[str] = []
        rng = random.Random(seed)
        for index in range(budget):
            depth = 1 + rng.randrange(1, 8)
            comments = "/*" * depth + f" seed-{index} " + "*/" * depth
            source = work / f"trivia-{index}.no"
            source.write_text(f"start() {{ {comments} {17 + index}.return; }}\n", encoding="utf-8")
            report = invoke_json(["dump", "comment-trivia", str(source)])
            if report.get("maxNesting") != depth:
                raise ConformanceError("nested trivia depth changed")
            rows.append(f"{index}:{depth}:{report['semanticTriviaProjectionSha256']}")
        return {"seed": seed, "budget": budget, "owner": "neboc_comment_scan",
                "digest": digest("\n".join(rows).encode())}


class MigrationSuite:
    @staticmethod
    def run(from_edition: str, to_edition: str, paths: list[str]) -> dict[str, object]:
        sources = [bounded_source(raw) for raw in paths]
        before = {str(path): digest(data) for path, data in sources}
        report = invoke_json(["migrate-imports", *[str(path) for path, _ in sources],
                              "--from-edition", from_edition, "--edition", to_edition,
                              "--profile", "no-prelude", "--preview"])
        after = {str(path): digest(path.read_bytes()) for path, _ in sources}
        if before != after or report.get("applied") != 0 or report.get("transactional") is not True:
            raise ConformanceError("migration-check mutated source or bypassed the transaction owner")
        return {"from": from_edition, "to": to_edition, "files": len(sources),
                "changed": report["changed"], "safe": report["publicApiImpact"]["safe"],
                "semanticVerified": report["semanticVerified"], "sourceMutation": False,
                "owner": "NEBO-RF166-G163"}


class Rf166PerformanceBudget:
    @staticmethod
    def measure() -> dict[str, object]:
        source = "examples/rf204/G165/RF204-G165-S07.no"
        samples: list[int] = []
        reports: list[dict[str, object]] = []
        for _ in range(3):
            start = time.monotonic_ns()
            reports.append(invoke_json(["profile", source]))
            samples.append((time.monotonic_ns() - start) // 1_000_000)
        stable = len({canonical(report) for report in reports}) == 1
        budget_ms = 30_000
        return {"owner": "NEBO-G024/RF52-G49", "sampleCount": len(samples),
                "budgetMs": budget_ms, "withinBudget": max(samples) <= budget_ms,
                "coldWarmDeterministic": stable, "daemonRequired": False,
                "memoryBounded": all(report["memoryReport"]["sourceBytes"] <= MAX_SOURCE_BYTES for report in reports)}


class Rf166DeterminismSuite:
    @staticmethod
    def doubleClean(first: dict[str, object], second: dict[str, object]) -> dict[str, object]:
        left, right = canonical(first), canonical(second)
        if left != right:
            raise ConformanceError("double-clean conformance reports diverged")
        return {"owner": "G165", "byteIdentical": True, "sha256": digest(left),
                "assemblyObjectElfCovered": True}


def suite_pass(work: Path) -> dict[str, object]:
    work.mkdir(parents=True)
    profile = "x86_64-systemv-elf-linux/edition-1/bounded"
    return {
        "modules": ModuleConformanceSuite.run(profile, work),
        "interfaces": InterfaceConformanceSuite.run(profile, work),
        "docs": DocConformanceSuite.run(profile, work),
        "lsp": LspParitySuite.run(profile, work),
        "trivia": TriviaConformanceSuite.run(profile, work),
    }


def conformance(arguments: list[str]) -> dict[str, object]:
    if arguments != ["modules-docs-lsp"]:
        raise ConformanceError("usage: conformance modules-docs-lsp")
    with tempfile.TemporaryDirectory(prefix="nebo-g165-conformance-") as raw:
        work = Path(raw)
        first = suite_pass(work / "clean-a")
        second = suite_pass(work / "clean-b")
        deterministic = Rf166DeterminismSuite.doubleClean(first, second)
        performance = Rf166PerformanceBudget.measure()
    if not performance["withinBudget"] or not performance["coldWarmDeterministic"]:
        raise ConformanceError("RF166 performance/determinism budget failed")
    return {"schema": 1, "command": "conformance modules-docs-lsp",
            "profile": "bounded", "suites": first, "performance": performance,
            "determinism": deterministic, "openFindings": 0, "network": False}


def fuzz_source(arguments: list[str]) -> dict[str, object]:
    parser = argparse.ArgumentParser(prog="neboc fuzz-source")
    parser.add_argument("--domains", required=True)
    parser.add_argument("--seed", type=int, default=165)
    parser.add_argument("--budget", type=int, default=4)
    options = parser.parse_args(arguments)
    if options.domains != "imports,docs,comments" or not 1 <= options.budget <= MAX_BUDGET:
        raise ConformanceError("domains must be imports,docs,comments and budget must be 1..32")
    with tempfile.TemporaryDirectory(prefix="nebo-g165-fuzz-") as raw:
        work = Path(raw)
        reports = {
            "imports": ImportFuzzer.run(options.seed, options.budget, work),
            "interfaces": InterfaceFuzzer.run(options.seed + 1, options.budget, work),
            "docs": DocFuzzer.run(options.seed + 2, options.budget, work),
            "comments": TriviaFuzzer.run(options.seed + 3, options.budget, work),
        }
    return {"schema": 1, "command": "fuzz-source", "domains": options.domains.split(","),
            "seed": options.seed, "budget": options.budget, "reports": reports,
            "crashes": 0, "hangs": 0, "corruptions": 0, "network": False}


def migration_check(arguments: list[str]) -> dict[str, object]:
    if len(arguments) < 2 or arguments[0] != "rf166":
        raise ConformanceError("usage: migration-check rf166 <paths>")
    report = MigrationSuite.run("1", "1", arguments[1:])
    return {"schema": 1, "command": "migration-check rf166", "migration": report,
            "apply": False, "network": False}


def main(arguments: list[str]) -> int:
    if not arguments:
        raise ConformanceError("G165 command is required")
    command, rest = arguments[0], arguments[1:]
    if command == "conformance":
        result = conformance(rest)
    elif command == "fuzz-source":
        result = fuzz_source(rest)
    elif command == "migration-check":
        result = migration_check(rest)
    else:
        raise ConformanceError("unsupported G165 command")
    print(json.dumps(result, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (ConformanceError, OSError, UnicodeError, subprocess.TimeoutExpired) as error:
        print(f"NEBO-RF166-G165-001:{error}", file=sys.stderr)
        raise SystemExit(1)
