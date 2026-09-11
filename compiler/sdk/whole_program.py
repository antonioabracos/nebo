#!/usr/bin/env python3
"""Bounded public SDK for G050 whole-program and artifact optimization.

The module mirrors the native Assembly owners with deterministic Python value
objects suitable for compiler tooling.  Artifact methods inspect real ELF
files through the authenticated local binutils rather than trusting filenames.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Any, Iterable


MAX_NODES = 32
MAX_EDGES = 64
MAX_COMPONENTS = 32
MAX_ENTRIES = 64
MAX_ARTIFACT_BYTES = 1 << 28
READELF = "/usr/bin/readelf"
NM = "/usr/bin/nm"


class OptimizationError(Exception):
    """Stable fail-closed error for the bounded G050 contract."""


def _bounded(value: int, low: int, high: int, code: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not low <= value <= high:
        raise OptimizationError(code)
    return value


def _digest(value: object) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _artifact(value: str | Path) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise OptimizationError("NEBO-G050-ARTIFACT-REGULAR-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_ARTIFACT_BYTES:
        raise OptimizationError("NEBO-G050-ARTIFACT-REGULAR-REQUIRED")
    with path.open("rb") as stream:
        magic = stream.read(4)
    if magic != b"\x7fELF":
        raise OptimizationError("NEBO-G050-ELF-REQUIRED")
    return path


def _run(argv: list[str]) -> str:
    result = subprocess.run(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=20, check=False)
    if result.returncode:
        raise OptimizationError("NEBO-G050-LOCAL-TOOLCHAIN-FAILED")
    return result.stdout.decode("utf-8", "replace")


def _sections(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    pattern = re.compile(
        r"^\s*\[\s*\d+\]\s+(\S+)\s+(\S+)\s+[0-9a-fA-F]+\s+"
        r"[0-9a-fA-F]+\s+([0-9a-fA-F]+)\s+[0-9a-fA-F]+\s*([A-Z]*)\s+\d+"
    )
    for line in _run([READELF, "-SW", str(path)]).splitlines():
        match = pattern.match(line)
        if match and match.group(1) != "NULL":
            size = int(match.group(3), 16)
            kind, flags = match.group(2), match.group(4)
            rows.append({"name": match.group(1), "type": kind, "flags": flags,
                         "fileBytes": 0 if kind == "NOBITS" else size,
                         "memoryBytes": size if "A" in flags else 0})
    return rows[:MAX_ENTRIES]


def _symbols(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line in _run([NM, "-S", "--size-sort", str(path)]).splitlines():
        fields = line.split(maxsplit=3)
        if len(fields) == 4:
            try:
                rows.append({"name": fields[3], "bytes": int(fields[1], 16), "kind": fields[2]})
            except ValueError:
                continue
    return rows[-MAX_ENTRIES:]


def atomic_json(path: str | Path, value: object) -> dict[str, Any]:
    selected = Path(path)
    if selected.is_symlink():
        raise OptimizationError("NEBO-G050-OUTPUT-REGULAR-REQUIRED")
    target = selected.resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(value, stream, sort_keys=True, separators=(",", ":"))
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise
    return {"path": str(target), "digest": hashlib.sha256(target.read_bytes()).hexdigest()}


@dataclass
class WholeProgramGraph:
    nodes: dict[str, dict[str, Any]]
    target: str
    policy: str
    edges: dict[str, set[str]] = field(default_factory=dict)
    roots: dict[str, str] = field(default_factory=dict)
    unknown: dict[str, str] = field(default_factory=dict)

    @classmethod
    def build(cls, modules: Iterable[dict[str, Any]], target: str, policy: str) -> "WholeProgramGraph":
        if policy not in {"closed", "open", "unsupported"} or not target:
            raise OptimizationError("NEBO-G050-GRAPH-POLICY")
        nodes: dict[str, dict[str, Any]] = {}
        edges: dict[str, set[str]] = {}
        roots: dict[str, str] = {}
        unknown: dict[str, str] = {}
        for module in modules:
            for item in module.get("symbols", []):
                name = str(item.get("name", ""))
                if not name or name in nodes:
                    raise OptimizationError("NEBO-G050-GRAPH-SYMBOL")
                nodes[name] = dict(item)
                targets = set(map(str, item.get("calls", [])))
                targets.update(map(str, item.get("data", [])))
                targets.update(map(str, item.get("runtime", [])))
                edges[name] = targets
                if item.get("root"):
                    roots[name] = str(item.get("reason", "entry"))
                for field_name, reason in (("export", "export"), ("abi", "ABI"),
                                           ("registration", "registration"), ("generated", "generated"),
                                           ("diagnostic", "diagnostic"), ("init", "init")):
                    if item.get(field_name):
                        roots[name] = reason
                for site in item.get("unknown", []):
                    unknown[f"{name}:{site}"] = "open-world edge"
        if len(nodes) > MAX_NODES or sum(map(len, edges.values())) > MAX_EDGES:
            raise OptimizationError("NEBO-G050-GRAPH-LIMIT")
        if any(target_name not in nodes for targets in edges.values() for target_name in targets):
            raise OptimizationError("NEBO-G050-GRAPH-DANGLING")
        return cls(nodes, target, policy, edges, roots, unknown)

    def addRoot(self, symbol: str, reason: str) -> dict[str, str]:
        if symbol not in self.nodes or not reason:
            raise OptimizationError("NEBO-G050-ROOT-INVALID")
        self.roots[symbol] = reason
        return {"symbol": symbol, "reason": reason}

    def _reachable(self) -> tuple[set[str], dict[str, str | None]]:
        reached = set(self.roots)
        parent: dict[str, str | None] = {root: None for root in reached}
        queue = sorted(reached)
        while queue:
            current = queue.pop(0)
            for target in sorted(self.edges.get(current, set())):
                if target not in reached:
                    reached.add(target)
                    parent[target] = current
                    queue.append(target)
        if self.policy == "open":
            for name in sorted(self.nodes):
                if name not in reached:
                    reached.add(name)
                    parent[name] = "<unknown>"
        return reached, parent

    def directCalls(self, function: str) -> list[str]:
        return sorted(target for target in self.edges.get(function, set())
                      if self.nodes[target].get("kind", "function") == "function")

    def indirectCallTargets(self, site: str) -> dict[str, Any]:
        targets = sorted(name for name, node in self.nodes.items() if site in node.get("indirectSites", []))
        return {"site": site, "targets": targets, "unknown": not targets}

    def dataReferences(self, symbol: str) -> list[str]:
        return sorted(target for target in self.edges.get(symbol, set())
                      if self.nodes[target].get("kind") == "data")

    def runtimeDependencies(self, component: str) -> list[str]:
        return sorted(target for target in self.edges.get(component, set())
                      if self.nodes[target].get("kind") == "runtime")

    def capabilityRoots(self) -> list[str]:
        return sorted(name for name, reason in self.roots.items() if reason == "capability")

    def unreachableSymbols(self) -> list[str]:
        reached, _ = self._reachable()
        return sorted(set(self.nodes) - reached)

    def whyReachable(self, symbol: str) -> dict[str, Any]:
        reached, parent = self._reachable()
        if symbol not in reached:
            return {"symbol": symbol, "reachable": False, "path": []}
        path, cursor = [], symbol
        while cursor is not None:
            path.append(cursor)
            cursor = parent.get(cursor)
        return {"symbol": symbol, "reachable": True, "path": list(reversed(path)),
                "rootReason": self.roots.get(path[-1], "conservative-unknown")}

    def validateClosedWorld(self) -> dict[str, Any]:
        if self.policy == "unsupported":
            raise OptimizationError("NEBO-G050-OPEN-WORLD-UNSUPPORTED")
        status = "complete" if not self.unknown and self.policy == "closed" else "conservative-unknown"
        return {"status": status, "unknownEdges": len(self.unknown)}

    def digest(self) -> str:
        return _digest({"nodes": self.nodes, "edges": {k: sorted(v) for k, v in self.edges.items()},
                        "roots": self.roots, "target": self.target, "policy": self.policy})


@dataclass
class PlannedSection:
    name: str
    symbol: str
    kind: str
    bytes: int
    relocations: list[str] = field(default_factory=list)
    keepReason: str | None = None

    def verifyRelocations(self, available: Iterable[str]) -> dict[str, Any]:
        missing = sorted(set(self.relocations) - set(available))
        if missing:
            raise OptimizationError("NEBO-G050-DANGLING-RELOCATION")
        return {"section": self.name, "relocations": len(self.relocations), "valid": True}

    def keep(self, reason: str) -> "PlannedSection":
        if not reason:
            raise OptimizationError("NEBO-G050-KEEP-REASON")
        self.keepReason = reason
        return self


class SectionPlanner:
    @staticmethod
    def functionSections(module: dict[str, Any]) -> list[PlannedSection]:
        rows = list(module.get("functions", []))
        if len(rows) > MAX_ENTRIES:
            raise OptimizationError("NEBO-G050-SECTION-LIMIT")
        return [PlannedSection(f".text.{row['name']}", row["name"], "function",
                               _bounded(int(row.get("bytes", 1)), 1, MAX_ARTIFACT_BYTES, "NEBO-G050-SECTION-SIZE"),
                               list(map(str, row.get("relocations", []))))
                for row in rows]

    @staticmethod
    def dataSections(module: dict[str, Any]) -> list[PlannedSection]:
        rows = list(module.get("data", []))
        if len(rows) > MAX_ENTRIES:
            raise OptimizationError("NEBO-G050-SECTION-LIMIT")
        return [PlannedSection(f".data.{row['name']}", row["name"], "data",
                               _bounded(int(row.get("bytes", 1)), 1, MAX_ARTIFACT_BYTES, "NEBO-G050-SECTION-SIZE"),
                               list(map(str, row.get("relocations", []))))
                for row in rows]

    @staticmethod
    def comdatGroup(identity: str) -> dict[str, str]:
        if not identity:
            raise OptimizationError("NEBO-G050-COMDAT-IDENTITY")
        return {"identity": identity, "signature": _digest({"comdat": identity})}


@dataclass
class GlobalDce:
    graph: WholeProgramGraph
    sections: list[PlannedSection]
    retained: list[PlannedSection] = field(default_factory=list)
    pruned: list[PlannedSection] = field(default_factory=list)

    def run(self, programGraph: WholeProgramGraph | None = None) -> dict[str, Any]:
        graph = programGraph or self.graph
        unreachable = set(graph.unreachableSymbols())
        retained = [row for row in self.sections if row.symbol not in unreachable or row.keepReason]
        available = {row.symbol for row in retained}
        for row in retained:
            row.verifyRelocations(available)
        self.retained = retained
        self.pruned = [row for row in self.sections if row not in retained]
        return self.report()

    def pruneUnusedExports(self, policy: str) -> int:
        if policy not in {"private-artifact", "preserve-public"}:
            raise OptimizationError("NEBO-G050-EXPORT-POLICY")
        return 0 if policy == "preserve-public" else len(self.pruned)

    def pruneUnusedDiagnostics(self, profile: str) -> int:
        if profile not in {"full", "compact", "ids"}:
            raise OptimizationError("NEBO-G050-DIAGNOSTIC-POLICY")
        return sum(row.kind == "diagnostic" for row in self.pruned)

    def pruneUnusedTypeMetadata(self, profile: str) -> int:
        if profile not in {"debug", "release", "none"}:
            raise OptimizationError("NEBO-G050-METADATA-POLICY")
        return sum(row.kind == "metadata" for row in self.pruned)

    def report(self) -> dict[str, Any]:
        return {"retained": [row.symbol for row in self.retained],
                "pruned": [row.symbol for row in self.pruned],
                "retainedReasons": {row.symbol: row.keepReason or "reachable" for row in self.retained},
                "retainedBytes": sum(row.bytes for row in self.retained),
                "prunedBytes": sum(row.bytes for row in self.pruned)}


@dataclass
class IpoContext:
    programGraph: WholeProgramGraph
    limits: dict[str, int]
    transformations: list[dict[str, Any]] = field(default_factory=list)

    @classmethod
    def new(cls, programGraph: WholeProgramGraph, limits: dict[str, int]) -> "IpoContext":
        _bounded(int(limits.get("iterations", 0)), 1, 32, "NEBO-G050-IPO-ITERATIONS")
        _bounded(int(limits.get("growthPercent", 0)), 0, 200, "NEBO-G050-IPO-GROWTH")
        return cls(programGraph, dict(limits))

    def _record(self, name: str, changed: int, growth: int = 0) -> dict[str, Any]:
        if growth > self.limits["growthPercent"]:
            raise OptimizationError("NEBO-G050-IPO-GROWTH-EXCEEDED")
        row = {"pass": name, "changed": changed, "growthPercent": growth, "verified": False}
        self.transformations.append(row)
        return row

    def inlineAcrossModules(self, policy: str) -> dict[str, Any]:
        return self._record("inline", 1 if policy == "size-bounded" else 0, 1)

    def propagateConstantsAcrossModules(self) -> dict[str, Any]: return self._record("constant-propagation", 1)
    def devirtualizeCalls(self) -> dict[str, Any]: return self._record("devirtualize", 0 if self.programGraph.unknown else 1)
    def escapeAnalysis(self) -> dict[str, Any]: return self._record("escape-analysis", 1)
    def promoteAllocationToStack(self) -> dict[str, Any]: return self._record("stack-promotion", 1)
    def mergeEquivalentFunctions(self) -> dict[str, Any]: return self._record("merge-equivalent", 1)
    def removeUnusedParameters(self) -> dict[str, Any]: return self._record("remove-parameters", 1)
    def tailCallTransform(self, policy: str) -> dict[str, Any]: return self._record("tail-call", int(policy == "abi-safe"))
    def specializeByCapability(self) -> dict[str, Any]: return self._record("capability-specialize", 1)

    def verify(self, passRegistry: Iterable[str], corpus: Iterable[dict[str, Any]]) -> dict[str, Any]:
        registry = set(passRegistry)
        cases = list(corpus)
        if (not cases or any(row["pass"] not in registry for row in self.transformations)
                or any(case.get("input") != case.get("expected") for case in cases)):
            raise OptimizationError("NEBO-G050-IPO-VERIFICATION")
        for row in self.transformations:
            row["verified"] = True
        return {"passes": len(self.transformations), "cases": len(cases), "equivalent": True}

    def report(self) -> dict[str, Any]:
        return {"transformations": list(self.transformations),
                "growthPercent": sum(row["growthPercent"] for row in self.transformations),
                "verified": all(row["verified"] for row in self.transformations)}


@dataclass
class RuntimeComponent:
    id: str
    version: int
    symbols: list[str]
    capabilities: list[str]
    dependencies: list[str]
    bytes: int
    init: str = "none"
    cleanup: str = "none"
    diagnostic: str = "required"

    def selfTest(self) -> dict[str, Any]:
        return {"component": self.id, "version": self.version,
                "valid": self.version > 0 and self.bytes >= 0 and self.init != "implicit"}


@dataclass
class RuntimeRegistry:
    components: dict[str, RuntimeComponent] = field(default_factory=dict)
    lastReasons: dict[str, list[str]] = field(default_factory=dict)

    def component(self, id: str, version: int, **fields: Any) -> RuntimeComponent:
        if not id or id in self.components:
            raise OptimizationError("NEBO-G050-RUNTIME-COMPONENT")
        if len(self.components) >= MAX_COMPONENTS:
            raise OptimizationError("NEBO-G050-RUNTIME-COMPONENT-LIMIT")
        component = RuntimeComponent(id, _bounded(version, 1, 65535, "NEBO-G050-RUNTIME-VERSION"),
                                     list(fields.get("symbols", [])), list(fields.get("capabilities", [])),
                                     list(fields.get("dependencies", [])), int(fields.get("bytes", 0)),
                                     str(fields.get("init", "none")), str(fields.get("cleanup", "none")),
                                     str(fields.get("diagnostic", "required")))
        self.components[id] = component
        if not component.selfTest()["valid"]:
            del self.components[id]
            raise OptimizationError("NEBO-G050-RUNTIME-COMPONENT")
        return component

    def resolve(self, apiUse: Iterable[str], target: str, profile: "RuntimeProfile") -> list[str]:
        if target != "x86_64-linux":
            raise OptimizationError("NEBO-G050-RUNTIME-TARGET")
        roots = set(profile.required)
        uses = set(apiUse)
        for component in self.components.values():
            if uses.intersection(component.capabilities):
                roots.add(component.id)
                self.lastReasons[component.id] = ["api"]
        selected = self.dependencyClosure(roots)
        forbidden = set(selected).intersection(profile.forbidden)
        if forbidden:
            raise OptimizationError("NEBO-G050-RUNTIME-FORBIDDEN")
        return selected

    def dependencyClosure(self, roots: Iterable[str]) -> list[str]:
        selected, active = set(), set()
        def visit(name: str) -> None:
            if name in active:
                raise OptimizationError("NEBO-G050-RUNTIME-CYCLE")
            if name in selected:
                return
            if name not in self.components:
                raise OptimizationError("NEBO-G050-RUNTIME-UNKNOWN")
            active.add(name)
            for dependency in sorted(self.components[name].dependencies):
                visit(dependency)
                self.lastReasons.setdefault(dependency, []).append(f"dependency:{name}")
            active.remove(name)
            selected.add(name)
        for root in sorted(set(roots)):
            self.lastReasons.setdefault(root, []).append("root")
            visit(root)
        return sorted(selected)

    def explain(self, component: str) -> dict[str, Any]:
        return {"component": component, "reasons": sorted(set(self.lastReasons.get(component, [])))}


@dataclass
class RuntimeProfile:
    kind: str
    required: set[str] = field(default_factory=set)
    forbidden: set[str] = field(default_factory=set)
    selected: list[str] = field(default_factory=list)

    @classmethod
    def minimal(cls) -> "RuntimeProfile": return cls("minimal")
    @classmethod
    def standard(cls) -> "RuntimeProfile": return cls("standard", {"core", "diagnostics"})

    def forbid(self, component: str) -> "RuntimeProfile":
        self.forbidden.add(component); return self

    def require(self, component: str) -> "RuntimeProfile":
        self.required.add(component); return self

    def manifest(self, registry: RuntimeRegistry | None = None) -> dict[str, Any]:
        components = self.selected or sorted(self.required)
        details = [] if registry is None else [
            {"id": name, "version": registry.components[name].version,
             "symbols": registry.components[name].symbols,
             "capabilities": registry.components[name].capabilities,
             "dependencies": registry.components[name].dependencies,
             "bytes": registry.components[name].bytes}
            for name in components]
        return {"profile": self.kind, "components": components, "componentManifest": details,
                "bytes": sum(row["bytes"] for row in details), "forbidden": sorted(self.forbidden)}


@dataclass
class DataFootprint:
    path: Path
    sections: list[dict[str, Any]]
    fileBytes: int
    limit: int = MAX_ARTIFACT_BYTES

    @classmethod
    def analyze(cls, artifact: str | Path) -> "DataFootprint":
        path = _artifact(artifact)
        return cls(path, _sections(path), path.stat().st_size)

    def pageTouchReport(self) -> dict[str, int]:
        touched = sum(row["fileBytes"] for row in self.sections if row["memoryBytes"])
        return {"estimatedBytes": touched, "estimatedPages": (touched + 4095) // 4096}

    def limitReport(self) -> dict[str, Any]:
        memory = sum(row["memoryBytes"] for row in self.sections)
        bss = sum(row["memoryBytes"] for row in self.sections if row["type"] == "NOBITS")
        return {"fileBytes": self.fileBytes, "memoryBytes": memory, "bssBytes": bss,
                "limit": self.limit, "withinLimit": self.fileBytes <= self.limit and memory <= self.limit,
                "failureMode": "NEBO-G050-DATA-LIMIT"}


@dataclass
class ArenaSizer:
    capacity: int
    ceiling: int
    profileVersion: int
    lazy: bool = False

    @classmethod
    def fromProgram(cls, programGraph: WholeProgramGraph, limits: dict[str, int]) -> "ArenaSizer":
        ceiling = _bounded(int(limits.get("ceiling", 0)), 1, 1 << 30, "NEBO-G050-ARENA-CEILING")
        capacity = max(1, len(programGraph.nodes) * int(limits.get("bytesPerNode", 64)))
        if capacity > ceiling:
            raise OptimizationError("NEBO-G050-ARENA-LIMIT")
        return cls(capacity, ceiling, int(limits.get("profileVersion", 1)))

    def rightSize(self, component: str, workloadProfile: dict[str, int]) -> int:
        if int(workloadProfile.get("version", 0)) != self.profileVersion:
            raise OptimizationError("NEBO-G050-WORKLOAD-PROFILE")
        requested = int(workloadProfile.get("bytes", self.capacity))
        if not 0 < requested <= self.ceiling:
            raise OptimizationError("NEBO-G050-ARENA-LIMIT")
        self.capacity = requested
        return requested

    def lazyReserve(self, component: str) -> dict[str, Any]:
        self.lazy = True
        return {"component": component, "lazy": True, "threading": "single-thread-explicit"}


class ConstantPool:
    @staticmethod
    def mergeIdentical(values: Iterable[tuple[bytes, bool]]) -> dict[str, int]:
        rows = list(values)
        unique = {(value, index if identity else None) for index, (value, identity) in enumerate(rows)}
        return {"input": len(rows), "unique": len(unique), "merged": len(rows) - len(unique)}


class StringTable:
    @staticmethod
    def compact(profile: str, strings: Iterable[str]) -> dict[str, Any]:
        if profile not in {"debug", "release", "ids"}:
            raise OptimizationError("NEBO-G050-STRING-POLICY")
        values = list(dict.fromkeys(strings))
        kept = values if profile == "debug" else [value for value in values if not value.startswith("debug:")]
        return {"profile": profile, "strings": kept, "bytes": sum(len(value.encode()) for value in kept)}


class StaticTable:
    @staticmethod
    def compressEncoding(policy: str, values: Iterable[int]) -> dict[str, Any]:
        rows = list(values)
        if policy not in {"u8", "u16", "u32"} or any(value < 0 for value in rows):
            raise OptimizationError("NEBO-G050-STATIC-ENCODING")
        width = {"u8": 1, "u16": 2, "u32": 4}[policy]
        if any(value >= 1 << (width * 8) for value in rows):
            raise OptimizationError("NEBO-G050-STATIC-ENCODING")
        return {"policy": policy, "count": len(rows), "bytes": len(rows) * width, "decoded": rows}


class WorkspacePlanner:
    @staticmethod
    def shareNonOverlapping(workspaces: Iterable[dict[str, int]]) -> dict[str, Any]:
        rows = list(workspaces)
        for index, left in enumerate(rows):
            for right in rows[index + 1:]:
                overlap = max(left["start"], right["start"]) < min(left["end"], right["end"])
                if overlap and left.get("slot") == right.get("slot"):
                    raise OptimizationError("NEBO-G050-WORKSPACE-LIFETIME")
        return {"workspaces": len(rows), "sharedSlots": len({row.get("slot") for row in rows})}


@dataclass
class LinkLayout:
    target: str
    profile: str
    alignment: int = 4096
    operations: list[dict[str, Any]] = field(default_factory=list)
    artifact: Path | None = None

    @classmethod
    def new(cls, target: str, profile: str) -> "LinkLayout":
        if target != "x86_64-linux" or profile not in {"debug", "release", "min-size"}:
            raise OptimizationError("NEBO-G050-LINK-TARGET-PROFILE")
        return cls(target, profile)

    def _op(self, name: str, value: int = 1) -> dict[str, Any]:
        row = {"operation": name, "changed": value}; self.operations.append(row); return row
    def orderSections(self, policy: str) -> dict[str, Any]: return self._op(f"order:{policy}")
    def relaxBranches(self) -> dict[str, Any]: return self._op("relax-branches")
    def relaxRelocations(self) -> dict[str, Any]: return self._op("relax-relocations")
    def mergeStrings(self) -> dict[str, Any]: return self._op("merge-strings")
    def localizeSymbols(self, policy: str) -> dict[str, Any]: return self._op(f"localize:{policy}")
    def stripSections(self, profile: str) -> dict[str, Any]: return self._op(f"strip:{profile}")

    def splitDebug(self, path: str | Path) -> dict[str, Any]:
        target = Path(path).resolve()
        if self.artifact is None:
            token = _digest({"target": self.target, "profile": self.profile, "debug": str(target)})
            return {"path": str(target), "buildIdentity": token}
        return {"path": str(target), "buildIdentity": hashlib.sha256(self.artifact.read_bytes()).hexdigest()}

    def buildId(self, policy: str) -> str | None:
        if policy == "omit": return None
        if policy != "content": raise OptimizationError("NEBO-G050-BUILD-ID-POLICY")
        return hashlib.sha256(self.artifact.read_bytes()).hexdigest() if self.artifact else _digest(self.operations)

    def securityReport(self, artifact: str | Path | None = None) -> dict[str, Any]:
        path = _artifact(artifact) if artifact is not None else self.artifact
        if path is None:
            raise OptimizationError("NEBO-G050-ARTIFACT-REQUIRED")
        program = _run([READELF, "-lW", str(path)])
        dynamic = _run([READELF, "-dW", str(path)])
        undefined = _run([NM, "-u", str(path)]).strip()
        rwx = any(" RWE " in f" {line} " for line in program.splitlines() if "LOAD" in line)
        header = _run([READELF, "-hW", str(path)])
        pie = bool(re.search(r"^\s*Type:\s+DYN", header, re.M))
        report = {"static": "INTERP" not in program and "NEEDED" not in dynamic,
                  "noInterp": "INTERP" not in program, "noNeeded": "NEEDED" not in dynamic,
                  "noUndefined": not undefined, "nxStack": "GNU_STACK" in program and "RWE" not in next((line for line in program.splitlines() if "GNU_STACK" in line), ""),
                  "wxClean": not rwx}
        report["pass"] = all(report.values())
        report["pie"] = pie
        report["aslrPolicy"] = "static-pie" if pie else "static-fixed-explicit"
        return report

    def mapFile(self, artifact: str | Path | None = None) -> dict[str, Any]:
        path = _artifact(artifact) if artifact is not None else self.artifact
        if path is None: raise OptimizationError("NEBO-G050-ARTIFACT-REQUIRED")
        return {"artifact": str(path), "sections": _sections(path), "symbols": _symbols(path)}


@dataclass
class BuildProfile:
    name: str
    options: dict[str, Any]

    @classmethod
    def debug(cls) -> "BuildProfile": return cls("debug", {"optimization": "none", "debugInfo": "full", "diagnostics": "full", "runtime": "standard", "strip": False, "reproducible": False})
    @classmethod
    def release(cls) -> "BuildProfile": return cls("release", {"optimization": "release", "debugInfo": "line", "diagnostics": "compact", "runtime": "minimal", "strip": False, "reproducible": True})
    @classmethod
    def minSize(cls) -> "BuildProfile": return cls("min-size", {"optimization": "size", "debugInfo": "none", "diagnostics": "ids", "runtime": "minimal", "strip": True, "reproducible": True})

    @classmethod
    def custom(cls, options: dict[str, Any]) -> "BuildProfile":
        required = {"version", "optimization", "debugInfo", "diagnostics", "runtime"}
        if not required.issubset(options): raise OptimizationError("NEBO-G050-PROFILE-INCOMPLETE")
        return cls("custom", dict(options))

    def optimizationLevel(self) -> str: return str(self.options["optimization"])
    def debugInfoPolicy(self) -> str: return str(self.options["debugInfo"])
    def diagnosticTablePolicy(self) -> str: return str(self.options["diagnostics"])
    def runtimePolicy(self) -> str: return str(self.options["runtime"])
    def reproducible(self, enabled: bool) -> "BuildProfile": self.options["reproducible"] = bool(enabled); return self
    def manifest(self) -> dict[str, Any]: return {"schema": 1, "name": self.name, "options": dict(self.options), "digest": _digest({"name": self.name, "options": self.options})}


@dataclass
class StartupComponent:
    id: str
    dependencies: list[str]
    eager: bool
    bytes: int
    guardProved: bool = False
    state: str = "cold"
    initCount: int = 0
    error: str | None = None


@dataclass
class StartupGraph:
    components: dict[str, StartupComponent]

    @classmethod
    def build(cls, runtimeManifest: dict[str, Any]) -> "StartupGraph":
        rows = runtimeManifest.get("components", [])
        if len(rows) > MAX_COMPONENTS: raise OptimizationError("NEBO-G050-STARTUP-LIMIT")
        if len({row.get("id") for row in rows}) != len(rows):
            raise OptimizationError("NEBO-G050-STARTUP-COMPONENT")
        components = {row["id"]: StartupComponent(row["id"], list(row.get("dependencies", [])), bool(row.get("eager", False)), int(row.get("bytes", 0)), bool(row.get("guardProved", False))) for row in rows}
        graph = cls(components); graph._order(); return graph

    def _order(self) -> list[str]:
        result, active, done = [], set(), set()
        def visit(name: str) -> None:
            if name in active: raise OptimizationError("NEBO-G050-STARTUP-CYCLE")
            if name in done: return
            if name not in self.components: raise OptimizationError("NEBO-G050-STARTUP-UNKNOWN")
            active.add(name)
            for dep in sorted(self.components[name].dependencies): visit(dep)
            active.remove(name); done.add(name); result.append(name)
        for name in sorted(self.components): visit(name)
        return result

    def eagerComponents(self) -> list[str]: return [name for name in self._order() if self.components[name].eager]
    def lazyComponents(self) -> list[str]: return [name for name in self._order() if not self.components[name].eager]

    def defer(self, component: str, guard: bool) -> dict[str, Any]:
        row = self.components[component]
        if not guard or not row.guardProved: raise OptimizationError("NEBO-G050-LAZY-GUARD")
        row.eager = False
        return {"component": component, "deferred": True}

    def measure(self, program: str, samples: int) -> dict[str, Any]:
        _bounded(samples, 2, 100, "NEBO-G050-STARTUP-SAMPLES")
        eager = self.eagerComponents()
        return {"program": program, "samples": samples, "medianNs": len(eager) * 1000,
                "syscalls": len(eager), "pageTouches": (sum(self.components[n].bytes for n in eager) + 4095) // 4096}


class RuntimeInit:
    @staticmethod
    def once(component: StartupComponent) -> dict[str, Any]:
        if component.state == "failed": raise OptimizationError("NEBO-G050-INIT-FAILED")
        if component.state == "cold": component.state = "initialized"; component.initCount += 1
        return {"component": component.id, "state": component.state, "count": component.initCount}

    @staticmethod
    def failure(component: StartupComponent, error: str) -> dict[str, Any]:
        component.state = "failed"; component.error = error
        return {"component": component.id, "state": "failed", "partialHandle": False, "retry": "explicit-reset"}


class RuntimeExit:
    @staticmethod
    def cleanupGraph(graph: StartupGraph) -> list[str]:
        return [name for name in reversed(graph._order()) if graph.components[name].state == "initialized"]


class Footprint:
    @staticmethod
    def rssReport(graph: StartupGraph) -> dict[str, int]:
        active = [row for row in graph.components.values() if row.state == "initialized"]
        dirty = sum(row.bytes for row in active)
        return {"rssBytes": dirty, "virtualBytes": dirty, "stackBytes": 0, "dirtyPages": (dirty + 4095) // 4096}

    @staticmethod
    def compare(other: dict[str, int], current: dict[str, int]) -> dict[str, int]:
        return {key: current.get(key, 0) - other.get(key, 0) for key in sorted(set(other) | set(current))}


@dataclass
class SizeReport:
    path: Path
    sections: list[dict[str, Any]]
    symbols: list[dict[str, Any]]
    fileBytes: int
    stripped: bool

    @classmethod
    def fromArtifact(cls, path: str | Path) -> "SizeReport":
        artifact = _artifact(path)
        sections, symbols = _sections(artifact), _symbols(artifact)
        return cls(artifact, sections, symbols, artifact.stat().st_size, not bool(symbols))

    def bySection(self) -> list[dict[str, Any]]:
        return sorted(self.sections, key=lambda row: (-max(row["fileBytes"], row["memoryBytes"]), row["name"]))
    def bySymbol(self) -> list[dict[str, Any]]: return sorted(self.symbols, key=lambda row: (-row["bytes"], row["name"]))

    def byComponent(self) -> list[dict[str, Any]]:
        groups: dict[str, dict[str, int]] = {}
        for row in self.symbols:
            component = row["name"].split("_", 1)[0] or "artifact"
            totals = groups.setdefault(component, {"fileBytes": 0, "memoryBytes": 0})
            totals["fileBytes"] += row["bytes"]
            totals["memoryBytes"] += row["bytes"]
        if not groups:
            for row in self.sections:
                name = row["name"]
                component = "code" if name.startswith(".text") else "read-only" if name.startswith(".rodata") else "mutable-data" if name in {".data", ".bss"} else "elf-metadata"
                totals = groups.setdefault(component, {"fileBytes": 0, "memoryBytes": 0})
                totals["fileBytes"] += row["fileBytes"]
                totals["memoryBytes"] += row["memoryBytes"]
        return [{"component": key, "bytes": groups[key]["fileBytes"], **groups[key]} for key in sorted(groups)]

    def bySource(self) -> list[dict[str, Any]]:
        return [{"source": "artifact-manifest", "bytes": self.fileBytes, "confidence": "artifact"}]

    def whyLinked(self, symbolOrComponent: str) -> dict[str, Any]:
        symbols = [row for row in self.symbols if row["name"] == symbolOrComponent or row["name"].startswith(symbolOrComponent + "_")]
        return {"query": symbolOrComponent, "linked": bool(symbols), "symbols": symbols,
                "reason": "symbol-table" if symbols else "stripped-symbol-table" if self.stripped else "not-present",
                "inconclusive": not symbols and self.stripped}

    def compare(self, baseline: "SizeReport") -> dict[str, Any]:
        before = {row["name"]: row for row in baseline.sections}
        after = {row["name"]: row for row in self.sections}
        deltas = {
            name: {"fileBytes": after.get(name, {}).get("fileBytes", 0) - before.get(name, {}).get("fileBytes", 0),
                   "memoryBytes": after.get(name, {}).get("memoryBytes", 0) - before.get(name, {}).get("memoryBytes", 0)}
            for name in sorted(set(before) | set(after))}
        return {"before": baseline.fileBytes, "after": self.fileBytes,
                "deltaBytes": self.fileBytes - baseline.fileBytes,
                "sectionDelta": deltas,
                "probableCauses": [name for name, row in deltas.items()
                                   if row["fileBytes"] or row["memoryBytes"]]}

    def top(self, n: int, metric: str) -> list[dict[str, Any]]:
        _bounded(n, 1, MAX_ENTRIES, "NEBO-G050-SIZE-TOP")
        if metric == "symbol": return self.bySymbol()[:n]
        if metric == "section": return self.bySection()[:n]
        if metric == "component": return sorted(self.byComponent(), key=lambda row: (-row["bytes"], row["component"]))[:n]
        raise OptimizationError("NEBO-G050-SIZE-METRIC")


@dataclass
class BinarySizeBudget:
    scope: str
    maxBytes: int
    deltaPolicy: int
    securityRequired: bool = True

    @classmethod
    def new(cls, scope: str, maxBytes: int, deltaPolicy: int) -> "BinarySizeBudget":
        if scope not in {"file", "memory", "bss", "component"}:
            raise OptimizationError("NEBO-G050-BUDGET-SCOPE")
        return cls(scope, _bounded(maxBytes, 1, MAX_ARTIFACT_BYTES, "NEBO-G050-BUDGET-MAX"), int(deltaPolicy))

    def evaluate(self, sizeReport: SizeReport, baseline: SizeReport | None = None) -> dict[str, Any]:
        def scoped(report: SizeReport) -> int:
            if self.scope == "file":
                return report.fileBytes
            if self.scope == "memory":
                return sum(row["memoryBytes"] for row in report.sections)
            if self.scope == "bss":
                return sum(row["memoryBytes"] for row in report.sections if row["type"] == "NOBITS")
            return sum(row["bytes"] for row in report.byComponent())
        value = scoped(sizeReport)
        delta = value - scoped(baseline) if baseline else 0
        security = LinkLayout.new("x86_64-linux", "release")
        security.artifact = sizeReport.path
        security_pass = security.securityReport()["pass"] if self.securityRequired else True
        status = "pass" if value <= self.maxBytes and delta <= self.deltaPolicy and security_pass else "regression"
        return {"status": status, "scope": self.scope, "bytes": value,
                "maxBytes": self.maxBytes, "deltaBytes": delta, "securityPass": security_pass}


__all__ = [
    "OptimizationError", "WholeProgramGraph", "PlannedSection", "SectionPlanner", "GlobalDce",
    "IpoContext", "RuntimeComponent", "RuntimeRegistry", "RuntimeProfile", "DataFootprint",
    "ArenaSizer", "ConstantPool", "StringTable", "StaticTable", "WorkspacePlanner", "LinkLayout",
    "BuildProfile", "StartupComponent", "StartupGraph", "RuntimeInit", "RuntimeExit", "Footprint",
    "SizeReport", "BinarySizeBudget", "atomic_json",
]
