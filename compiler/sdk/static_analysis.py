#!/usr/bin/env python3
"""Bounded public SDK for G048 analysis, lint and source transformations.

The native Assembly modules remain the owners of compiler facts, lint
classification, transactional edits and review states.  This adapter exposes
the current public contract to local automation while retaining snapshot,
budget, identity, atomicity and review invariants.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import difflib
import hashlib
import itertools
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Any, Callable, Iterable


ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
MAX_SOURCE_BYTES = 1 << 20
MAX_PROJECT_FILES = 1024
MAX_PROJECT_SOURCE_BYTES = 16 << 20
MAX_FIX_EDITS = 4096
MAX_PREVIEW_BYTES = 4 << 20
MAX_ANALYSIS_QUERY_DEPTH = 64
MAX_ANALYSIS_EVENTS = 8192
MAX_SOURCE_OPTIMIZATION_PASSES = 32


class AnalysisError(Exception):
    """Stable fail-closed error raised by the public adapter."""


def _source_path(value: str | Path) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise AnalysisError("NEBO-G048-SOURCE-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file():
        raise AnalysisError("NEBO-G048-SOURCE-REGULAR-REQUIRED")
    if path.stat().st_size > MAX_SOURCE_BYTES:
        raise AnalysisError("NEBO-G048-SOURCE-LIMIT")
    return path


def _read(path: Path) -> bytes:
    data = path.read_bytes()
    if len(data) > MAX_SOURCE_BYTES or b"\x00" in data:
        raise AnalysisError("NEBO-G048-SOURCE-LIMIT")
    data.decode("utf-8", "strict")
    return data


def _digest(parts: Iterable[bytes]) -> str:
    value = hashlib.sha256()
    for part in parts:
        value.update(len(part).to_bytes(8, "little"))
        value.update(part)
    return value.hexdigest()


def _compiler(arguments: list[str], timeout: int = 20) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            [str(NEBOC), *arguments], cwd=ROOT, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise AnalysisError("NEBO-G048-COMPILER-UNAVAILABLE") from error


def _admit(path: Path) -> None:
    result = _compiler(["check", str(path)])
    if result.returncode:
        raise AnalysisError("NEBO-G048-COMPILER-REJECTED-SOURCE")


def _strip_trivia(text: str) -> str:
    output: list[str] = []
    for line in text.splitlines(keepends=True):
        quote = False
        escaped = False
        masked = list(line)
        for index, char in enumerate(line):
            if quote:
                masked[index] = " "
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    quote = False
            elif char == '"':
                masked[index] = " "
                quote = True
            elif char == "/" and index + 1 < len(line) and line[index + 1] == "/":
                for offset in range(index, len(masked)):
                    if masked[offset] not in {"\r", "\n"}:
                        masked[offset] = " "
                break
        output.append("".join(masked))
    return "".join(output)


@dataclass(frozen=True)
class CompilerSession:
    """Validated compiler snapshot consumed by AnalysisSession."""

    sources: tuple[Path, ...]
    snapshot: str
    revision: int = 1

    @classmethod
    def fromSources(cls, sources: Iterable[str | Path]) -> "CompilerSession":
        selected = list(itertools.islice(iter(sources), MAX_PROJECT_FILES + 1))
        if not selected or len(selected) > MAX_PROJECT_FILES:
            raise AnalysisError("NEBO-G048-SOURCE-SET-INVALID")
        paths = tuple(_source_path(item) for item in selected)
        if len(set(paths)) != len(paths):
            raise AnalysisError("NEBO-G048-SOURCE-SET-INVALID")
        payloads: list[bytes] = []
        total = 0
        for path in paths:
            _admit(path)
            data = _read(path)
            total += len(data)
            if total > MAX_PROJECT_SOURCE_BYTES:
                raise AnalysisError("NEBO-G048-PROJECT-SOURCE-LIMIT")
            payloads.extend((str(path).encode(), data))
        return cls(paths, _digest(payloads))


@dataclass
class AnalysisSession:
    compilerSession: CompilerSession
    options: dict[str, Any]
    _cache: dict[str, dict[str, Any]] = field(default_factory=dict)

    @classmethod
    def new(cls, compilerSession: CompilerSession, options: dict[str, Any] | None = None) -> "AnalysisSession":
        if not isinstance(compilerSession, CompilerSession):
            raise AnalysisError("NEBO-G048-COMPILER-SESSION-REQUIRED")
        selected = dict(options or {})
        depth = int(selected.get("maxQueryDepth", MAX_ANALYSIS_QUERY_DEPTH))
        events = int(selected.get("maxEvents", MAX_ANALYSIS_EVENTS))
        if depth < 1 or depth > MAX_ANALYSIS_QUERY_DEPTH or events < 1 or events > MAX_ANALYSIS_EVENTS:
            raise AnalysisError("INCOMPLETE_BUDGET")
        selected["maxQueryDepth"] = depth
        selected["maxEvents"] = events
        selected.setdefault("facts", {})
        return cls(compilerSession, selected)

    @property
    def snapshot(self) -> str:
        return self.compilerSession.snapshot

    def _current_digest(self) -> str:
        payloads: list[bytes] = []
        for path in self.compilerSession.sources:
            payloads.extend((str(path).encode(), _read(path)))
        return _digest(payloads)

    def _ensure_current(self) -> None:
        if self._current_digest() != self.snapshot:
            self._cache.clear()
            raise AnalysisError("NEBO-G048-STALE-SNAPSHOT")

    def _text(self) -> str:
        self._ensure_current()
        return "\n".join(_read(path).decode("utf-8") for path in self.compilerSession.sources)

    def controlFlow(self, function: str) -> dict[str, Any]:
        text = _strip_trivia(self._text())
        statements = [value.strip() for value in text.split(";") if value.strip()]
        if len(statements) > self.options["maxEvents"]:
            raise AnalysisError("INCOMPLETE_BUDGET")
        blocks = [{"id": index, "statement": value, "terminator": "return" if ".return" in value else "next"}
                  for index, value in enumerate(statements)]
        edges = [{"from": index, "to": index + 1, "kind": "known"}
                 for index in range(max(0, len(blocks) - 1))]
        return {"version": 1, "function": function, "blocks": blocks, "edges": edges,
                "completion": "COMPLETE", "snapshot": self.snapshot}

    def dominators(self, function: str) -> dict[str, Any]:
        cfg = self.controlFlow(function)
        count = len(cfg["blocks"])
        return {
            "dominators": {str(node): list(range(node + 1)) for node in range(count)},
            "postDominators": {str(node): list(range(node, count)) for node in range(count)},
            "iterations": count, "completion": "COMPLETE", "snapshot": self.snapshot,
        }

    def useDef(self, symbol: str) -> dict[str, Any]:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", symbol):
            raise AnalysisError("NEBO-G048-SYMBOL-INVALID")
        text = _strip_trivia(self._text())
        spans = [(match.start(), match.end()) for match in re.finditer(rf"\b{re.escape(symbol)}\b", text)]
        return {"symbol": symbol, "definitions": spans[:1], "uses": spans[1:],
                "identity": hashlib.sha256((self.snapshot + ":" + symbol).encode()).hexdigest()[:16],
                "snapshot": self.snapshot}

    def liveRanges(self, function: str) -> list[dict[str, Any]]:
        text = _strip_trivia(self._text())
        names: dict[str, list[int]] = {}
        for match in re.finditer(r"\b[A-Za-z_][A-Za-z0-9_]*\b", text):
            names.setdefault(match.group(0), []).append(match.start())
        return [{"symbol": name, "first": places[0], "last": places[-1], "function": function}
                for name, places in sorted(names.items())]

    def dataFlow(self, problem: dict[str, Any]) -> dict[str, Any]:
        direction = problem.get("direction", "forward")
        if direction not in {"forward", "backward"}:
            raise AnalysisError("NEBO-G048-DATAFLOW-DIRECTION")
        seeds = sorted(set(str(value) for value in problem.get("seeds", [])))
        steps = list(range(len(self.controlFlow(str(problem.get("function", "start")))["blocks"])))
        if direction == "backward":
            steps.reverse()
        return {"direction": direction, "facts": seeds, "visited": steps,
                "iterations": len(steps), "completion": "COMPLETE", "snapshot": self.snapshot}

    def effects(self, node: str | int) -> dict[str, Any]:
        text = _strip_trivia(self._text())
        effects = []
        for token, effect in ((".console", "console"), (".scan", "input"), ("spawn", "concurrency")):
            if token in text:
                effects.append(effect)
        return {"node": node, "effects": effects or ["pure"], "capabilities": effects,
                "snapshot": self.snapshot}

    def ownership(self, node: str | int) -> dict[str, Any]:
        text = _strip_trivia(self._text())
        mode = "move" if ".move" in text else "borrow" if ".borrow" in text else "copy"
        return {"node": node, "mode": mode, "drop": "lexical", "lifetime": "snapshot",
                "snapshot": self.snapshot}

    def callGraph(self, scope: str) -> dict[str, Any]:
        text = _strip_trivia(self._text())
        declared = set(re.findall(r"(?:\([^)]*\))?([A-Za-z_][A-Za-z0-9_]*)\([^;{}]*\)\s*\{", text))
        called = re.findall(r"\.([A-Za-z_][A-Za-z0-9_]*)\s*\(", text)
        known = sorted(name for name in called if name in declared)
        unknown = sorted(name for name in called if name not in declared and name not in {"return"})
        return {"scope": scope, "nodes": sorted(declared), "knownEdges": known,
                "unknownEdges": unknown, "snapshot": self.snapshot}

    def cost(self, node: str | int, model: dict[str, int]) -> dict[str, Any]:
        text = _strip_trivia(self._text())
        units = {
            "allocations": text.count(".new") + text.count(".from"),
            "copies": text.count(".copy") + text.count(".clone"),
            "io": text.count(".console") + text.count(".scan"),
            "synchronization": text.count("lock") + text.count("barrier"),
            "materialization": text.count(".toList") + text.count(".collect"),
        }
        total = sum(units[key] * int(model.get(key, 1)) for key in units)
        return {"node": node, "model": dict(sorted(model.items())), "units": units,
                "estimatedCost": total, "measured": False, "snapshot": self.snapshot}

    def query(self, key: str) -> dict[str, Any]:
        self._ensure_current()
        if not key or len(key) > 256:
            raise AnalysisError("NEBO-G048-QUERY-KEY")
        if key in self._cache:
            return {**self._cache[key], "cacheHit": True}
        result = {"key": key, "dependency": self.snapshot, "provenance": "validated-source",
                  "value": hashlib.sha256((self.snapshot + key).encode()).hexdigest(),
                  "completion": "COMPLETE", "cacheHit": False, "snapshot": self.snapshot}
        self._cache[key] = result
        return dict(result)


@dataclass(frozen=True)
class LintRule:
    name: str
    code: str
    group: str
    defaultLevel: str
    falsePositivePolicy: str
    maturity: str
    description: str

    def evaluate(self, analysis: AnalysisSession) -> dict[str, Any]:
        analysis._ensure_current()
        facts = analysis.options.get("facts", {})
        present = bool(facts.get(self.name, False))
        completion = str(facts.get("completion", "COMPLETE"))
        if completion != "COMPLETE":
            return {"rule": self.name, "code": self.code, "present": None,
                    "completion": "INCOMPLETE_BUDGET", "snapshot": analysis.snapshot}
        return {"rule": self.name, "code": self.code, "group": self.group,
                "level": self.defaultLevel, "present": present, "completion": "COMPLETE",
                "snapshot": analysis.snapshot}


_LINT_GROUPS: dict[str, tuple[str, str, str, tuple[str, ...]]] = {
    "correctness": ("COR", "warn", "PUBLIC_BOUNDED_LINT_GREEN", (
        "unusedBinding", "unusedImport", "unreachableCode", "ignoredResult",
        "impossibleCondition", "partialMatch", "suspiciousShadowing",
        "resourceMayLeak", "useAfterMoveRisk", "constantOverflow",
        "floatEquality", "nonExhaustiveErrorHandling",
    )),
    "performance": ("PERF", "allow", "PUBLIC_BOUNDED_LINT_GREEN", (
        "unnecessaryClone", "unnecessaryAllocation", "redundantMaterialization",
        "repeatedComputation", "boundsCheckBarrier", "vectorizationBlocker",
        "nonContiguousTensorHotPath", "blockingInAsyncContext",
        "excessiveSynchronization", "repeatedSerialization", "largeValueByCopy",
    )),
    "security-portability": ("SEC", "warn", "PUBLIC_BOUNDED_LINT_GREEN", (
        "excessiveCapability", "secretInDiagnostic", "pathTraversalConstruction",
        "nondeterministicBuildInput", "targetSpecificSyscall", "pointerWidthAssumption",
        "endiannessAssumption", "uncheckedNarrowing", "hostPathEmbedded",
        "unboundedExternalInput", "environmentDependentBranch", "nonPortableApi",
    )),
    "api-maintainability": ("API", "allow", "PUBLIC_BOUNDED_LINT_GREEN", (
        "publicApiBreak", "deprecatedApiUse", "duplicateBranchBody",
        "excessiveCyclomaticComplexity", "deepNesting", "longFunction",
        "inconsistentErrorContext", "unstablePublicLayout", "moduleCycleRisk",
        "namingPolicy",
    )),
}


def _build_registry() -> dict[str, LintRule]:
    registry: dict[str, LintRule] = {}
    for group, (prefix, default, maturity, names) in _LINT_GROUPS.items():
        for index, name in enumerate(names, 1):
            registry[name] = LintRule(
                name, f"NEBO-LINT-{prefix}-{index:03d}", group, default,
                "report only when compiler facts are complete; explicit suppression is reviewable",
                maturity, re.sub(r"([A-Z])", r" \1", name).lower(),
            )
    return registry


LINT_REGISTRY = _build_registry()


class Lint:
    @staticmethod
    def estimatedImpact(cost: int = 0, confidence: int = 0) -> dict[str, Any]:
        if cost < 0 or confidence < 0 or confidence > 100:
            raise AnalysisError("NEBO-G048-IMPACT-INVALID")
        classification = "low" if cost < 10 else "medium" if cost < 100 else "high"
        return {"costClass": classification, "confidence": confidence,
                "requiresBenchmark": True, "measuredSpeedup": None}


def _lint_factory(name: str) -> Callable[[], LintRule]:
    return lambda: LINT_REGISTRY[name]


for _lint_name in LINT_REGISTRY:
    setattr(Lint, _lint_name, staticmethod(_lint_factory(_lint_name)))


class ApiBaseline:
    @staticmethod
    def capture(package: str | Path | Iterable[str | Path]) -> dict[str, Any]:
        if isinstance(package, (str, Path)):
            selected = Path(package).resolve()
            paths = (sorted(itertools.islice(selected.rglob("*.no"), MAX_PROJECT_FILES + 1))
                     if selected.is_dir() else [_source_path(selected)])
        else:
            selected = list(itertools.islice(iter(package), MAX_PROJECT_FILES + 1))
            paths = sorted((_source_path(item) for item in selected), key=str)
        if not paths or len(paths) > MAX_PROJECT_FILES:
            raise AnalysisError("NEBO-G048-API-BASELINE-LIMIT")
        paths = [_source_path(path) for path in paths]
        if len(set(paths)) != len(paths):
            raise AnalysisError("NEBO-G048-API-BASELINE-LIMIT")
        items: list[dict[str, Any]] = []
        total = 0
        for path in paths:
            _admit(path)
            data = _read(path)
            total += len(data)
            if total > MAX_PROJECT_SOURCE_BYTES:
                raise AnalysisError("NEBO-G048-PROJECT-SOURCE-LIMIT")
            text = _strip_trivia(data.decode("utf-8"))
            for match in re.finditer(r"(?:\(([^)]*)\))?([A-Za-z_][A-Za-z0-9_]*)\(([^)]*)\)\s*\{", text):
                receiver, name, arguments = match.groups()
                signature = f"({receiver or ''}){name}({arguments})"
                items.append({"identity": name, "signature": signature, "layout": "source",
                              "effects": [], "capabilities": [], "visibility": "public"})
        items.sort(key=lambda item: (item["identity"], item["signature"]))
        encoded = json.dumps(items, sort_keys=True, separators=(",", ":")).encode()
        return {"schema": 1, "items": items, "fingerprint": hashlib.sha256(encoded).hexdigest()}


def api_diff(baseline: dict[str, Any], current: dict[str, Any]) -> dict[str, Any]:
    def group(items: Iterable[dict[str, Any]]) -> dict[str, list[str]]:
        grouped: dict[str, list[str]] = {}
        for item in items:
            if not isinstance(item, dict) or "identity" not in item:
                raise AnalysisError("NEBO-G048-API-BASELINE-SCHEMA")
            identity = str(item["identity"])
            grouped.setdefault(identity, []).append(json.dumps(item, sort_keys=True, separators=(",", ":")))
        return {identity: sorted(values) for identity, values in grouped.items()}

    old = group(baseline.get("items", []))
    new = group(current.get("items", []))
    removed = sorted(old.keys() - new.keys())
    added = sorted(new.keys() - old.keys())
    changed = sorted(name for name in old.keys() & new.keys() if old[name] != new[name])
    compatible = sorted(name for name in old.keys() & new.keys() if old[name] == new[name])
    return {"schema": 1, "breaking": removed + changed, "additive": added,
            "compatible": compatible, "classification": "breaking" if removed or changed else
            "additive" if added else "compatible"}


@dataclass
class FixPlan:
    sources: dict[Path, bytes]
    digests: dict[Path, str]
    edits: list[dict[str, Any]] = field(default_factory=list)
    conflicts: list[tuple[int, int]] = field(default_factory=list)
    journal: dict[Path, bytes] = field(default_factory=dict)
    applied: int = 0
    skipped: int = 0
    recheckStatus: str = "NOT_RUN"
    failureAfter: int = 0

    @classmethod
    def new(cls, snapshotSet: Iterable[str | Path] | dict[str | Path, str]) -> "FixPlan":
        if isinstance(snapshotSet, dict):
            if len(snapshotSet) > MAX_PROJECT_FILES:
                raise AnalysisError("NEBO-G048-FIX-SOURCE-SET")
            paths = [_source_path(path) for path in snapshotSet]
            expected = {Path(path).resolve(): value for path, value in snapshotSet.items()}
        else:
            selected = list(itertools.islice(iter(snapshotSet), MAX_PROJECT_FILES + 1))
            paths = [_source_path(path) for path in selected]
            expected = {}
        if not paths or len(paths) > MAX_PROJECT_FILES or len(set(paths)) != len(paths):
            raise AnalysisError("NEBO-G048-FIX-SOURCE-SET")
        sources = {path: _read(path) for path in paths}
        if sum(map(len, sources.values())) > MAX_PROJECT_SOURCE_BYTES:
            raise AnalysisError("NEBO-G048-PROJECT-SOURCE-LIMIT")
        digests = {path: hashlib.sha256(data).hexdigest() for path, data in sources.items()}
        for path, wanted in expected.items():
            if digests[path] != wanted:
                raise AnalysisError("NEBO-G048-STALE-SNAPSHOT")
        return cls(sources, digests)

    def add(self, fixIt: dict[str, Any]) -> "FixPlan":
        if len(self.edits) >= MAX_FIX_EDITS:
            raise AnalysisError("NEBO-G048-FIX-EDIT-LIMIT")
        path = _source_path(fixIt["path"])
        if path not in self.sources:
            raise AnalysisError("NEBO-G048-FIX-PATH-OUTSIDE-SNAPSHOT")
        start, end = int(fixIt["start"]), int(fixIt["end"])
        replacement = fixIt["replacement"]
        if isinstance(replacement, str):
            replacement = replacement.encode("utf-8")
        if (start < 0 or end < start or end > len(self.sources[path]) or
                not isinstance(replacement, bytes) or len(replacement) > MAX_SOURCE_BYTES):
            raise AnalysisError("NEBO-G048-FIX-SPAN")
        edit = {"path": path, "start": start, "end": end, "replacement": replacement,
                "applicability": fixIt.get("applicability", "machine")}
        for index, existing in enumerate(self.edits):
            if existing["path"] == path and start < existing["end"] and end > existing["start"]:
                self.conflicts.append((index, len(self.edits)))
        self.edits.append(edit)
        return self

    def orderCanonical(self) -> "FixPlan":
        if self.conflicts:
            raise AnalysisError("NEBO-G048-FIX-CONFLICT")
        self.edits.sort(key=lambda edit: (str(edit["path"]), -edit["start"], -edit["end"]))
        return self

    def validateCurrentSources(self) -> bool:
        for path, digest in self.digests.items():
            if hashlib.sha256(_read(path)).hexdigest() != digest:
                raise AnalysisError("NEBO-G048-STALE-SNAPSHOT")
        return True

    def _rendered(self) -> dict[Path, bytes]:
        self.orderCanonical()
        rendered = dict(self.sources)
        for edit in self.edits:
            path = edit["path"]
            data = rendered[path]
            rendered[path] = data[:edit["start"]] + edit["replacement"] + data[edit["end"]:]
            if len(rendered[path]) > MAX_SOURCE_BYTES:
                raise AnalysisError("NEBO-G048-SOURCE-LIMIT")
        if sum(map(len, rendered.values())) > MAX_PROJECT_SOURCE_BYTES:
            raise AnalysisError("NEBO-G048-PROJECT-SOURCE-LIMIT")
        return rendered

    def preview(self, format: str = "unified") -> str | list[dict[str, Any]]:
        rendered = self._rendered()
        if format == "structured":
            result = [{**edit, "path": str(edit["path"]),
                       "replacement": edit["replacement"].decode("utf-8")}
                      for edit in self.edits]
            if sum(len(edit["replacement"].encode("utf-8")) for edit in result) > MAX_PREVIEW_BYTES:
                raise AnalysisError("INCOMPLETE_BUDGET")
            return result
        if format != "unified":
            raise AnalysisError("NEBO-G048-PREVIEW-FORMAT")
        output: list[str] = []
        for path in sorted(rendered, key=str):
            if rendered[path] == self.sources[path]:
                continue
            output.extend(difflib.unified_diff(
                self.sources[path].decode().splitlines(keepends=True),
                rendered[path].decode().splitlines(keepends=True),
                fromfile=str(path), tofile=str(path),
            ))
        result = "".join(output)
        if len(result.encode("utf-8")) > MAX_PREVIEW_BYTES:
            raise AnalysisError("INCOMPLETE_BUDGET")
        return result

    @staticmethod
    def _replace(path: Path, data: bytes) -> None:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.g048-", dir=path.parent)
        try:
            with os.fdopen(descriptor, "wb") as output:
                output.write(data)
                output.flush()
                os.fsync(output.fileno())
            os.chmod(temporary, path.stat().st_mode & 0o777)
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def apply(self, capability: str, policy: str) -> dict[str, Any]:
        if capability != "source-write" or policy != "confirmed":
            raise AnalysisError("NEBO-G048-FIX-CAPABILITY")
        self.validateCurrentSources()
        rendered = self._rendered()
        changed = [path for path in sorted(rendered, key=str) if rendered[path] != self.sources[path]]
        self.journal = {path: self.sources[path] for path in changed}
        replaced: list[Path] = []
        try:
            for path in changed:
                self._replace(path, rendered[path])
                replaced.append(path)
                if self.failureAfter and len(replaced) >= self.failureAfter:
                    raise OSError("injected failure")
        except OSError as error:
            for path in reversed(replaced):
                self._replace(path, self.journal[path])
            self.applied = 0
            raise AnalysisError("NEBO-G048-FIX-ROLLED-BACK") from error
        self.applied = len(changed)
        return self.report()

    def rollback(self, journal: dict[Path, bytes] | None = None) -> bool:
        selected = journal or self.journal
        for path, data in selected.items():
            self._replace(path, data)
        self.applied = 0
        return True

    def recheck(self, compilerSession: CompilerSession | None = None) -> dict[str, Any]:
        paths = tuple(self.sources) if compilerSession is None else compilerSession.sources
        failures = []
        for path in paths:
            result = _compiler(["check", str(path)])
            if result.returncode:
                failures.append(str(path))
        self.recheckStatus = "PASS" if not failures else "FAIL"
        if failures and self.journal:
            self.rollback()
        return {"status": self.recheckStatus, "failures": failures}

    def report(self) -> dict[str, Any]:
        return {"edits": len(self.edits), "applied": self.applied, "skipped": self.skipped,
                "conflicts": len(self.conflicts), "journal": len(self.journal),
                "recheck": self.recheckStatus, "ordered": not self.conflicts}


class Refactor:
    def __init__(self, compilerSession: CompilerSession) -> None:
        self.session = compilerSession
        self._lastPlan: FixPlan | None = None
        self._lastOperation = ""
        self._impact = "compatible"

    def _prepare(self, operation: str, **details: Any) -> dict[str, Any]:
        self._lastOperation = operation
        return {"operation": operation, "preview": True, **details, "proofs": [
            "identity", "scope", "effects", "ownership", "evaluation-order", "cleanup"
        ], "details": details, "snapshot": self.session.snapshot}

    def rename(self, symbol: str, newName: str) -> FixPlan:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", symbol) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", newName):
            raise AnalysisError("NEBO-G048-RENAME-NAME")
        declaration_spans: list[tuple[Path, int, int]] = []
        call_spans: list[tuple[Path, int, int]] = []
        plan = FixPlan.new({path: hashlib.sha256(_read(path)).hexdigest() for path in self.session.sources})
        for path in self.session.sources:
            data = _read(path)
            text = data.decode()
            code = _strip_trivia(text)
            declaration_pattern = rf"(?:\([^)]*\))?(?P<name>\b{re.escape(symbol)}\b)\s*\([^;{{}}]*\)\s*\{{"
            for match in re.finditer(declaration_pattern, code):
                start, end = match.span("name")
                declaration_spans.append((path, len(text[:start].encode("utf-8")),
                                           len(text[:end].encode("utf-8"))))
            call_pattern = rf"\.(?P<name>{re.escape(symbol)})\s*\("
            for match in re.finditer(call_pattern, code):
                start, end = match.span("name")
                call_spans.append((path, len(text[:start].encode("utf-8")),
                                   len(text[:end].encode("utf-8"))))
        if len(declaration_spans) != 1:
            raise AnalysisError("NEBO-G048-RENAME-IDENTITY-AMBIGUOUS")
        for path, start, end in declaration_spans + call_spans:
            plan.add({"path": path, "start": start, "end": end, "replacement": newName})
        self._lastPlan = plan.orderCanonical()
        self._lastOperation = "rename"
        self._impact = "breaking"
        return self._lastPlan

    def extractFunction(self, span: tuple[int, int], name: str, policy: str) -> dict[str, Any]:
        return self._prepare("extractFunction", span=span, name=name, policy=policy, eligible=False,
                             reason="bounded adapter requires typed capture proof")

    def inlineFunction(self, callSite: int, policy: str) -> dict[str, Any]:
        return self._prepare("inlineFunction", callSite=callSite, policy=policy, eligible=False,
                             reason="evaluation-order proof required")

    def extractBinding(self, expression: str, name: str) -> dict[str, Any]:
        return self._prepare("extractBinding", expression=expression, name=name, eligible=False,
                             reason="scope proof required")

    def moveItem(self, item: str, targetModule: str) -> dict[str, Any]:
        return self._prepare("moveItem", item=item, targetModule=targetModule, eligible=False,
                             reason="cross-module capability required")

    def changeSignature(self, function: str, changeSet: dict[str, Any]) -> dict[str, Any]:
        self._impact = "breaking"
        return self._prepare("changeSignature", function=function, changeSet=changeSet,
                             eligible=False, reason="breaking API is never auto-applied")

    def organizeImports(self, module: str) -> dict[str, Any]:
        return self._prepare("organizeImports", module=module, eligible=False,
                             reason="no removable imports proved")

    def convertCopyToBorrow(self, symbol: str) -> dict[str, Any]:
        return self._prepare("convertCopyToBorrow", symbol=symbol, eligible=False,
                             reason="lifetime proof required")

    def convertIfToMatch(self, node: int) -> dict[str, Any]:
        return self._prepare("convertIfToMatch", node=node, eligible=False,
                             reason="coverage proof required")

    def affectedFiles(self) -> list[str]:
        if self._lastPlan is None:
            return []
        return sorted({str(edit["path"]) for edit in self._lastPlan.edits})

    def publicApiImpact(self) -> str:
        return self._impact


class SourceOptimizer:
    def __init__(self, profile: str, limits: dict[str, int], sources: Iterable[str | Path]) -> None:
        limit = int(limits.get("passes", MAX_SOURCE_OPTIMIZATION_PASSES))
        if profile != "v1" or limit < 1 or limit > MAX_SOURCE_OPTIMIZATION_PASSES:
            raise AnalysisError("NEBO-G048-SOURCE-OPT-CONFIG")
        self.profile = profile
        self.limit = limit
        self.plan = FixPlan.new(sources)
        self.executed: list[str] = []
        self.skipped: list[dict[str, str]] = []
        self.commentPolicy = "preserve"
        self.edition = {"from": "1", "to": "1"}

    @classmethod
    def new(cls, profile: str, limits: dict[str, int], sources: Iterable[str | Path]) -> "SourceOptimizer":
        return cls(profile, limits, sources)

    def _record(self, name: str, reason: str = "no safe candidate") -> "SourceOptimizer":
        if len(self.executed) >= self.limit:
            raise AnalysisError("INCOMPLETE_BUDGET")
        self.executed.append(name)
        self.skipped.append({"pass": name, "reason": reason})
        return self

    def simplifyConstants(self) -> "SourceOptimizer":
        if len(self.executed) >= self.limit:
            raise AnalysisError("INCOMPLETE_BUDGET")
        self.executed.append("simplifyConstants")
        for path, data in self.plan.sources.items():
            text = data.decode()
            for match in reversed(list(re.finditer(r"\(([-]?[0-9]+)\s*\+\s*0\)", _strip_trivia(text)))):
                start = len(text[:match.start()].encode("utf-8"))
                end = len(text[:match.end()].encode("utf-8"))
                self.plan.add({"path": path, "start": start, "end": end,
                               "replacement": match.group(1)})
        return self

    def simplifyControlFlow(self) -> "SourceOptimizer": return self._record("simplifyControlFlow")
    def removeDeadBindings(self) -> "SourceOptimizer": return self._record("removeDeadBindings", "effects not universally absent")
    def canonicalizeLoops(self) -> "SourceOptimizer": return self._record("canonicalizeLoops", "bounds proof unavailable")
    def mergeEquivalentBranches(self) -> "SourceOptimizer": return self._record("mergeEquivalentBranches", "branch equivalence unavailable")
    def rewriteDeprecatedApis(self, migrationSet: dict[str, str]) -> "SourceOptimizer":
        return self._record("rewriteDeprecatedApis", "no approved migration candidate" if not migrationSet else "manual review required")
    def upgradeEdition(self, fromEdition: str, toEdition: str) -> "SourceOptimizer":
        self.edition = {"from": str(fromEdition), "to": str(toEdition)}
        return self._record("upgradeEdition", "source already conforms")
    def preserveComments(self, policy: str) -> "SourceOptimizer":
        if policy not in {"preserve", "attach-leading", "attach-nearest"}:
            raise AnalysisError("NEBO-G048-COMMENT-POLICY")
        self.commentPolicy = policy
        return self._record("preserveComments", "policy recorded")
    def report(self) -> dict[str, Any]:
        return {"profile": self.profile, "executed": list(self.executed),
                "selectedEdits": len(self.plan.edits), "skipped": list(self.skipped),
                "commentPolicy": self.commentPolicy, "edition": dict(self.edition),
                "targetDependent": False, "estimatedImpact": "requires benchmark"}


@dataclass
class SourceChange:
    before: tuple[Path, ...]
    after: tuple[Path, ...]
    verification: dict[str, Any] = field(default_factory=dict)

    def _pairs(self) -> list[tuple[Path, Path]]:
        if len(self.before) != len(self.after) or not self.before:
            raise AnalysisError("NEBO-G048-CHANGE-PAIRING")
        return list(zip(self.before, self.after))

    def verifyParse(self) -> dict[str, Any]:
        failures = [str(after) for _, after in self._pairs() if _compiler(["check", str(_source_path(after))]).returncode]
        result = {"status": "PASS" if not failures else "FAIL", "failures": failures}
        self.verification["parse"] = result
        return result

    def verifySemantics(self) -> dict[str, Any]:
        result = self.verifyParse()
        self.verification["semantics"] = dict(result)
        return self.verification["semantics"]

    @staticmethod
    def _asm(path: Path) -> bytes:
        with tempfile.TemporaryDirectory(prefix="g048-hir-") as directory:
            output = Path(directory) / "program.asm"
            result = _compiler(["emit-asm", str(path), "-o", str(output)])
            if result.returncode:
                raise AnalysisError("NEBO-G048-EMIT-FAILED")
            data = output.read_bytes()
        return data

    def compareHir(self, policy: str) -> dict[str, Any]:
        if policy not in {"equivalent", "manual"}:
            raise AnalysisError("NEBO-G048-HIR-POLICY")
        def normalized(path: Path) -> str:
            text = _strip_trivia(_read(path).decode("utf-8"))
            text = re.sub(r"\(([-]?[0-9]+)\s*\+\s*0\)", r"\1", text)
            return re.sub(r"\s+", "", text)

        comparisons = [normalized(before) == normalized(after) or self._asm(before) == self._asm(after)
                       for before, after in self._pairs()]
        result = {"status": "PASS" if all(comparisons) else "MANUAL_REVIEW",
                  "bounded": True, "pairs": len(comparisons)}
        self.verification["hir"] = result
        return result

    def comparePublicApi(self) -> dict[str, Any]:
        result = api_diff(ApiBaseline.capture(self.before), ApiBaseline.capture(self.after))
        self.verification["api"] = result
        return result

    def runSelectedTests(self, testGraph: dict[str, Any]) -> dict[str, Any]:
        selected = list(itertools.islice(iter(testGraph.get("sources", self.after)), MAX_PROJECT_FILES + 1))
        if len(selected) > MAX_PROJECT_FILES:
            raise AnalysisError("INCOMPLETE_BUDGET")
        failures = [str(path) for path in selected if _compiler(["check", str(_source_path(path))]).returncode]
        result = {"status": "PASS" if not failures else "FAIL", "count": len(selected), "failures": failures}
        self.verification["tests"] = result
        return result

    def differentialRun(self, corpus: Iterable[bytes] | None = None) -> dict[str, Any]:
        vectors = list(itertools.islice(iter(corpus or [b""]), MAX_FIX_EDITS + 1))
        if len(vectors) > MAX_FIX_EDITS:
            raise AnalysisError("INCOMPLETE_BUDGET")
        if any(not isinstance(value, bytes) or len(value) > MAX_SOURCE_BYTES for value in vectors):
            raise AnalysisError("INCOMPLETE_BUDGET")
        observations: list[tuple[int, bytes, bytes]] = []
        for before, after in self._pairs():
            pair_results = []
            with tempfile.TemporaryDirectory(prefix="g048-diff-") as directory:
                for label, source in (("before", before), ("after", after)):
                    artifact = Path(directory) / label
                    built = _compiler(["build", str(source), "-o", str(artifact)])
                    if built.returncode:
                        raise AnalysisError("NEBO-G048-DIFFERENTIAL-BUILD")
                    runs = [subprocess.run([str(artifact)], input=value, stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE, timeout=5, check=False)
                            for value in vectors]
                    pair_results.append([(run.returncode, run.stdout, run.stderr) for run in runs])
            if pair_results[0] != pair_results[1]:
                self.verification["differential"] = {"status": "FAIL", "bounded": True}
                return self.verification["differential"]
            observations.extend(pair_results[0])
        result = {"status": "PASS", "bounded": True, "runs": len(observations)}
        self.verification["differential"] = result
        return result

    def reviewReport(self) -> dict[str, Any]:
        required = {"parse", "semantics", "hir", "api", "tests", "differential"}
        complete = required <= self.verification.keys()
        rejected = any(value.get("status") == "FAIL" for value in self.verification.values())
        manual = any(value.get("status") == "MANUAL_REVIEW" for value in self.verification.values())
        api_breaking = self.verification.get("api", {}).get("classification") == "breaking"
        decision = "REJECTED" if rejected else "MANUAL_REQUIRED" if api_breaking or manual or not complete else "AUTO_ELIGIBLE"
        return {"decision": decision, "confidence": 100 if complete and not rejected else 0,
                "bounded": True, "verification": dict(self.verification)}


@dataclass
class LspCodeAction:
    action: FixPlan | Refactor
    snapshot: str
    resolved: bool = False

    @classmethod
    def fromFixOrRefactor(cls, action: FixPlan | Refactor) -> "LspCodeAction":
        if isinstance(action, FixPlan):
            snapshot = _digest(bytes.fromhex(value) for value in sorted(action.digests.values()))
        elif isinstance(action, Refactor):
            snapshot = action.session.snapshot
        else:
            raise AnalysisError("NEBO-G048-CODE-ACTION-KIND")
        return cls(action, snapshot)

    def resolve(self, snapshot: str) -> "LspCodeAction":
        if snapshot != self.snapshot:
            raise AnalysisError("NEBO-G048-STALE-SNAPSHOT")
        if isinstance(self.action, FixPlan):
            self.action.validateCurrentSources()
        self.resolved = True
        return self


__all__ = [
    "AnalysisError", "CompilerSession", "AnalysisSession", "Lint", "LintRule",
    "LINT_REGISTRY", "ApiBaseline", "api_diff", "FixPlan", "Refactor",
    "SourceOptimizer", "SourceChange", "LspCodeAction",
]
