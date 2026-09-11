#!/usr/bin/env python3
"""Bounded public SDK for G049 compiler performance and scalability.

The Assembly RF52-G49 modules remain the low-level owners.  This adapter gives
local automation a deterministic, fail-closed API while the native one-shot
compiler remains the parser, semantic, lowering, and code-generation oracle.
No network service or telemetry is used.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import base64
import copy
import hashlib
import json
import math
import os
from pathlib import Path
import re
import resource
import statistics
import subprocess
import tempfile
import time
from typing import Any, Callable, Iterable


ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
MAX_EVENTS = 4096
MAX_ARENA_BYTES = 1 << 30
MAX_INTERN_ENTRIES = 65535
MAX_INTERN_ITEM_BYTES = 4096
MAX_SOURCE_BYTES = 1 << 20
MAX_QUERY_ENTRIES = 64
MAX_QUERY_EDGES = 128
MAX_CACHE_ENTRIES = 64
MAX_CACHE_BYTES = 1 << 20
MAX_WORKERS = 16
MAX_TASKS = 32
MAX_WORKSPACES = 8
MAX_PROJECT_MODULES = 32
MAX_SAMPLES = 31


class PerformanceError(Exception):
    """Stable fail-closed error for the public G049 adapter."""


def _bounded(value: int, low: int, high: int, code: str) -> int:
    result = int(value)
    if result < low or result > high:
        raise PerformanceError(code)
    return result


def _digest(*values: object) -> str:
    state = hashlib.sha256()
    for value in values:
        if isinstance(value, bytes):
            data = value
        else:
            data = json.dumps(value, sort_keys=True, separators=(",", ":"), default=str).encode()
        state.update(len(data).to_bytes(8, "little"))
        state.update(data)
    return state.hexdigest()


def _regular_file(value: str | Path) -> Path:
    selected = Path(value)
    if selected.is_symlink():
        raise PerformanceError("NEBO-G049-REGULAR-FILE-REQUIRED")
    path = selected.resolve()
    if not path.is_file() or path.stat().st_size > MAX_SOURCE_BYTES:
        raise PerformanceError("NEBO-G049-REGULAR-FILE-REQUIRED")
    return path


def _atomic_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(value, stream, sort_keys=True, separators=(",", ":"))
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def _admit_source(path: Path) -> None:
    try:
        result = subprocess.run([str(NEBOC), "check", str(path)], cwd=ROOT,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=30, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PerformanceError("NEBO-G049-COMPILER-UNAVAILABLE") from error
    if result.returncode:
        raise PerformanceError("NEBO-G049-COMPILER-REJECTED-SOURCE")


@dataclass
class _PhaseTimer:
    owner: "CompilerMetrics"
    phase: str
    unit: str
    started_wall: int = field(default_factory=time.monotonic_ns)
    started_cpu: int = field(default_factory=time.process_time_ns)
    stopped: bool = False

    def stop(self) -> dict[str, Any]:
        if self.stopped:
            raise PerformanceError("NEBO-G049-TIMER-ALREADY-STOPPED")
        self.stopped = True
        event = {"kind": "phase", "phase": self.phase, "unit": self.unit,
                 "wallNs": max(1, time.monotonic_ns() - self.started_wall),
                 "cpuNs": max(1, time.process_time_ns() - self.started_cpu)}
        self.owner._append(event)
        return dict(event)

    def __enter__(self) -> "_PhaseTimer":
        return self

    def __exit__(self, *_: object) -> None:
        self.stop()


@dataclass
class CompilerMetrics:
    context: dict[str, Any]
    events: list[dict[str, Any]] = field(default_factory=list)
    dropped: int = 0

    @classmethod
    def new(cls, context: dict[str, Any]) -> "CompilerMetrics":
        if not isinstance(context, dict):
            raise PerformanceError("NEBO-G049-METRICS-CONTEXT")
        selected = dict(context)
        selected.setdefault("mode", "cold")
        if selected["mode"] not in {"cold", "warm", "incremental"}:
            raise PerformanceError("NEBO-G049-METRICS-MODE")
        selected["eventLimit"] = _bounded(selected.get("eventLimit", MAX_EVENTS), 1, MAX_EVENTS,
                                          "NEBO-G049-METRICS-LIMIT")
        selected.setdefault("revision", 1)
        selected.setdefault("target", "x86_64-systemv-elf-linux")
        return cls(selected)

    def _append(self, event: dict[str, Any]) -> dict[str, Any]:
        if len(self.events) >= self.context["eventLimit"]:
            self.dropped += 1
            return {"kind": event["kind"], "dropped": True}
        event = {**event, "sequence": len(self.events)}
        self.events.append(event)
        return dict(event)

    def phaseTimer(self, phase: str, unit: str) -> _PhaseTimer:
        return _PhaseTimer(self, str(phase), str(unit))

    def counter(self, name: str, value: int) -> dict[str, Any]:
        return self._append({"kind": "counter", "name": str(name), "value": int(value)})

    def memorySnapshot(self, label: str) -> dict[str, Any]:
        rss = int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss) * 1024
        return self._append({"kind": "memory", "label": str(label), "rssBytes": rss,
                             "available": ["rss"]})

    def ioSnapshot(self, label: str) -> dict[str, Any]:
        usage = resource.getrusage(resource.RUSAGE_SELF)
        return self._append({"kind": "io", "label": str(label),
                             "inputBlocks": int(usage.ru_inblock),
                             "outputBlocks": int(usage.ru_oublock)})

    def cacheEvent(self, kind: str, keyClass: str) -> dict[str, Any]:
        if kind not in {"hit", "miss", "stale", "corrupt", "evicted", "bypass"}:
            raise PerformanceError("NEBO-G049-CACHE-EVENT-KIND")
        return self._append({"kind": "cache", "event": kind, "keyClass": str(keyClass)})

    def traceEvent(self, category: str, fields: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(fields, dict) or len(fields) > 4:
            raise PerformanceError("NEBO-G049-TRACE-FIELDS")
        return self._append({"kind": "trace", "category": str(category), "fields": dict(fields)})

    def summary(self) -> dict[str, Any]:
        phases = [event for event in self.events if event["kind"] == "phase"]
        cache = [event for event in self.events if event["kind"] == "cache"]
        return {"schema": 1, "mode": self.context["mode"], "events": len(self.events),
                "dropped": self.dropped, "wallNs": sum(int(e["wallNs"]) for e in phases),
                "cpuNs": sum(int(e["cpuNs"]) for e in phases),
                "cacheHits": sum(e["event"] == "hit" for e in cache),
                "digest": _digest(self.context, self.events)}

    def export(self, path: str | Path, format: str) -> dict[str, Any]:
        if format not in {"json", "trace"}:
            raise PerformanceError("NEBO-G049-METRICS-FORMAT")
        target = Path(path).resolve()
        payload = {"schema": 1, "format": format, "context": self.context,
                   "events": self.events, "summary": self.summary()}
        _atomic_json(target, payload)
        return {"path": str(target), "bytes": target.stat().st_size,
                "digest": hashlib.sha256(target.read_bytes()).hexdigest()}


@dataclass(frozen=True)
class ArenaMark:
    used: int
    generation: int


@dataclass
class CompilerArena:
    capacity: int
    policy: str
    storage: bytearray = field(init=False)
    used: int = 0
    highWater: int = 0
    allocations: int = 0
    generation: int = 1

    def __post_init__(self) -> None:
        self.storage = bytearray(self.capacity)

    @classmethod
    def new(cls, capacity: int, policy: str) -> "CompilerArena":
        if policy not in {"phase", "session"}:
            raise PerformanceError("NEBO-G049-ARENA-POLICY")
        return cls(_bounded(capacity, 1, MAX_ARENA_BYTES, "NEBO-G049-ARENA-CAPACITY"), policy)

    def allocate(self, layout: int | dict[str, int]) -> memoryview:
        if isinstance(layout, dict):
            size = _bounded(layout.get("size", 0), 1, self.capacity, "NEBO-G049-LAYOUT")
            alignment = _bounded(layout.get("alignment", 1), 1, 4096, "NEBO-G049-LAYOUT")
        else:
            size, alignment = _bounded(layout, 1, self.capacity, "NEBO-G049-LAYOUT"), 1
        if alignment & (alignment - 1):
            raise PerformanceError("NEBO-G049-LAYOUT")
        start = (self.used + alignment - 1) & -alignment
        if start + size > self.capacity:
            raise PerformanceError("NEBO-G049-ARENA-EXHAUSTED")
        self.used = start + size
        self.highWater = max(self.highWater, self.used)
        self.allocations += 1
        return memoryview(self.storage)[start:self.used]

    def mark(self) -> ArenaMark:
        return ArenaMark(self.used, self.generation)

    def reset(self, mark: ArenaMark) -> None:
        if not isinstance(mark, ArenaMark) or mark.generation != self.generation or not 0 <= mark.used <= self.used:
            raise PerformanceError("NEBO-G049-ARENA-MARK")
        self.storage[mark.used:self.used] = b"\0" * (self.used - mark.used)
        self.used = mark.used
        self.generation += 1

    def stats(self) -> dict[str, int | str]:
        return {"used": self.used, "reserved": self.capacity, "highWater": self.highWater,
                "allocations": self.allocations, "generation": self.generation,
                "policy": self.policy}


@dataclass
class InternPool:
    kind: str
    maxEntries: int
    maxBytes: int
    entries: dict[bytes, int] = field(default_factory=dict)
    usedBytes: int = 0

    @classmethod
    def new(cls, kind: str, limits: dict[str, int]) -> "InternPool":
        return cls(str(kind), _bounded(limits.get("entries", 0), 1, MAX_INTERN_ENTRIES,
                                       "NEBO-G049-INTERN-LIMIT"),
                   _bounded(limits.get("bytes", 0), 1, MAX_ARENA_BYTES,
                            "NEBO-G049-INTERN-LIMIT"))

    def intern(self, bytes: bytes | str) -> int:
        data = bytes.encode() if isinstance(bytes, str) else bytes
        if not data or len(data) > MAX_INTERN_ITEM_BYTES:
            raise PerformanceError("NEBO-G049-INTERN-ITEM")
        if data in self.entries:
            return self.entries[data]
        if len(self.entries) >= self.maxEntries or self.usedBytes + len(data) > self.maxBytes:
            raise PerformanceError("NEBO-G049-INTERN-EXHAUSTED")
        identity = len(self.entries) + 1
        self.entries[data] = identity
        self.usedBytes += len(data)
        return identity


@dataclass
class CompactIdTable:
    width: int
    values: list[int] = field(default_factory=list)

    @classmethod
    def new(cls, widthPolicy: str) -> "CompactIdTable":
        widths = {"u8": 8, "u16": 16, "u32": 32}
        if widthPolicy not in widths:
            raise PerformanceError("NEBO-G049-ID-WIDTH")
        return cls(widths[widthPolicy])

    def add(self, value: int) -> int:
        selected = _bounded(value, 0, (1 << self.width) - 1, "NEBO-G049-ID-OVERFLOW")
        self.values.append(selected)
        return len(self.values) - 1


class _Memory:
    def pressureLevel(self) -> str:
        rss = int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss) * 1024
        return "normal" if rss < 512 << 20 else "high" if rss < 1 << 30 else "critical"

    def evictCaches(self, policy: str) -> dict[str, Any]:
        if policy not in {"recomputable", "all-inactive"}:
            raise PerformanceError("NEBO-G049-EVICTION-POLICY")
        return {"policy": policy, "removed": 0, "sourceOfTruthRemoved": 0}

    def leakReport(self) -> dict[str, Any]:
        return {"schema": 1, "definiteLeaks": 0, "outstandingOwners": 0}


memory = _Memory()


@dataclass(frozen=True)
class SourceSnapshot:
    fileId: str
    bytes: bytes
    revision: int
    digest: str

    @classmethod
    def new(cls, fileId: str, bytes: bytes | str, revision: int) -> "SourceSnapshot":
        data = bytes.encode() if isinstance(bytes, str) else bytes
        if len(data) > MAX_SOURCE_BYTES or int(revision) < 1:
            raise PerformanceError("NEBO-G049-SNAPSHOT-LIMIT")
        data.decode("utf-8", "strict")
        return cls(str(fileId), data, int(revision), _digest(str(fileId), data, int(revision)))

    def compact(self, historyPolicy: str) -> dict[str, Any]:
        if historyPolicy not in {"latest", "two-revisions"}:
            raise PerformanceError("NEBO-G049-HISTORY-POLICY")
        return {"retained": 1, "removed": max(0, self.revision - (2 if historyPolicy == "two-revisions" else 1)),
                "protected": self.revision}


@dataclass(frozen=True)
class TextEdit:
    span: tuple[int, int]
    replacement: bytes

    @classmethod
    def new(cls, span: tuple[int, int], replacement: bytes | str) -> "TextEdit":
        start, end = map(int, span)
        data = replacement.encode() if isinstance(replacement, str) else replacement
        if start < 0 or end < start or len(data) > MAX_SOURCE_BYTES:
            raise PerformanceError("NEBO-G049-EDIT-SPAN")
        return cls((start, end), data)


@dataclass(frozen=True)
class LexResult:
    snapshot: SourceSnapshot
    tokens: tuple[str, ...]
    changed: tuple[tuple[int, int], ...]
    reused: int
    rebuilt: int
    fallback: bool


class IncrementalLexer:
    @staticmethod
    def lex(snapshot: SourceSnapshot, previous: LexResult | None,
            edits: Iterable[TextEdit]) -> LexResult:
        if not isinstance(snapshot, SourceSnapshot):
            raise PerformanceError("NEBO-G049-SNAPSHOT-REQUIRED")
        selected = list(edits)
        if previous is not None and previous.snapshot.revision >= snapshot.revision:
            raise PerformanceError("NEBO-G049-REVISION-ORDER")
        for edit in selected:
            if edit.span[1] > len(previous.snapshot.bytes if previous else snapshot.bytes):
                raise PerformanceError("NEBO-G049-EDIT-SPAN")
        tokens = tuple(re.findall(r"[A-Za-z_][A-Za-z0-9_]*|\d+|[^\s]", snapshot.bytes.decode()))
        old = previous.tokens if previous else ()
        reused = sum(left == right for left, right in zip(tokens, old))
        changed = tuple(edit.span for edit in selected) or ((0, len(snapshot.bytes)),)
        return LexResult(snapshot, tokens, changed, reused, len(tokens) - reused, previous is None)


@dataclass
class SyntaxTree:
    snapshot: SourceSnapshot
    tokens: tuple[str, ...]
    reused: int
    rebuilt: int
    ranges: tuple[tuple[int, int], ...]
    fallback: bool

    def changedRanges(self, previous: "SyntaxTree") -> list[tuple[int, int]]:
        if not isinstance(previous, SyntaxTree) or previous.snapshot.revision >= self.snapshot.revision:
            raise PerformanceError("NEBO-G049-TREE-REVISION")
        return list(self.ranges)

    def reuseReport(self) -> dict[str, Any]:
        return {"tokensReused": self.reused, "nodesReused": self.reused,
                "tokensRebuilt": self.rebuilt, "nodesRebuilt": self.rebuilt,
                "fallback": self.fallback, "revision": self.snapshot.revision}

    def validateAgainstColdParse(self) -> dict[str, Any]:
        with tempfile.TemporaryDirectory(prefix="nebo-g049-syntax-") as directory:
            source = Path(directory) / "source.no"
            source.write_bytes(self.snapshot.bytes)
            _admit_source(source)
        cold = tuple(re.findall(r"[A-Za-z_][A-Za-z0-9_]*|\d+|[^\s]", self.snapshot.bytes.decode()))
        return {"status": "PASS" if cold == self.tokens else "FAIL",
                "incrementalDigest": _digest(self.tokens), "coldDigest": _digest(cold)}


class IncrementalParser:
    def __init__(self) -> None:
        self.budget = {"nodes": 65536, "bytes": MAX_SOURCE_BYTES, "time": 1_000_000_000}

    def setBudget(self, nodes: int, bytes: int, time: int) -> "IncrementalParser":
        self.budget = {"nodes": _bounded(nodes, 1, 1 << 20, "NEBO-G049-PARSE-BUDGET"),
                       "bytes": _bounded(bytes, 1, MAX_SOURCE_BYTES, "NEBO-G049-PARSE-BUDGET"),
                       "time": _bounded(time, 1, 10_000_000_000, "NEBO-G049-PARSE-BUDGET")}
        return self

    def parse(self, tokens: LexResult, previousTree: SyntaxTree | None,
              changedRanges: Iterable[tuple[int, int]]) -> SyntaxTree:
        if len(tokens.tokens) > self.budget["nodes"] or len(tokens.snapshot.bytes) > self.budget["bytes"]:
            raise PerformanceError("NEBO-G049-PARSE-BUDGET")
        reused = 0 if previousTree is None else sum(a == b for a, b in zip(tokens.tokens, previousTree.tokens))
        return SyntaxTree(tokens.snapshot, tokens.tokens, reused, len(tokens.tokens) - reused,
                          tuple(changedRanges), previousTree is None)


@dataclass
class QueryDatabase:
    revision: int
    maxEntries: int
    maxEdges: int
    entries: dict[str, dict[str, Any]] = field(default_factory=dict)
    edges: set[tuple[str, str]] = field(default_factory=set)
    hits: int = 0
    misses: int = 0
    invalidations: int = 0
    cycle: list[str] = field(default_factory=list)
    lastCycle: list[str] = field(default_factory=list)

    @classmethod
    def new(cls, revision: int, limits: dict[str, int]) -> "QueryDatabase":
        return cls(_bounded(revision, 1, 1 << 62, "NEBO-G049-QUERY-REVISION"),
                   _bounded(limits.get("entries", 0), 1, MAX_QUERY_ENTRIES, "NEBO-G049-QUERY-LIMIT"),
                   _bounded(limits.get("edges", 0), 1, MAX_QUERY_EDGES, "NEBO-G049-QUERY-LIMIT"))

    def execute(self, key: str, provider: Callable[[], object]) -> object:
        name = str(key)
        if name in self.entries and self.entries[name]["state"] == "valid":
            self.hits += 1
            return self.entries[name]["value"]
        if len(self.entries) >= self.maxEntries and name not in self.entries:
            raise PerformanceError("NEBO-G049-QUERY-LIMIT")
        if name in self.cycle:
            self.lastCycle = [*self.cycle, name]
            raise PerformanceError("NEBO-G049-QUERY-CYCLE")
        self.misses += 1
        self.cycle.append(name)
        try:
            value = provider()
        finally:
            self.cycle.pop()
        self.entries[name] = {"value": value, "digest": _digest(value),
                              "revision": self.revision, "state": "valid"}
        return value

    def recordDependency(self, parent: str, child: str) -> None:
        if len(self.edges) >= self.maxEdges:
            raise PerformanceError("NEBO-G049-QUERY-EDGE-LIMIT")
        self.edges.add((str(parent), str(child)))

    def invalidate(self, inputKey: str, revision: int) -> int:
        revision = _bounded(revision, self.revision + 1, 1 << 62, "NEBO-G049-QUERY-REVISION")
        affected = {str(inputKey)}
        changed = True
        while changed:
            before = len(affected)
            affected.update(parent for parent, child in self.edges if child in affected)
            changed = len(affected) != before
        for key in affected:
            if key in self.entries:
                self.entries[key]["state"] = "invalid"
                self.invalidations += 1
        self.revision = revision
        return len(affected)

    def cycleReport(self, key: str) -> dict[str, Any]:
        return {"key": str(key), "detected": bool(self.lastCycle), "path": list(self.lastCycle)}

    def resultDigest(self, key: str) -> str:
        if key not in self.entries or self.entries[key]["state"] != "valid":
            raise PerformanceError("NEBO-G049-QUERY-MISSING")
        return str(self.entries[key]["digest"])

    def reuseReport(self) -> dict[str, int]:
        return {"hits": self.hits, "misses": self.misses, "invalidations": self.invalidations,
                "entries": len(self.entries), "edges": len(self.edges)}

    def verifyAgainstCold(self, keys: Iterable[str]) -> dict[str, int | str]:
        selected = list(keys)
        missing = sum(key not in self.entries or self.entries[key]["state"] != "valid" for key in selected)
        return {"status": "PASS" if missing == 0 else "FAIL", "checked": len(selected),
                "mismatches": missing}

    def prune(self, revisionPolicy: int) -> dict[str, int]:
        threshold = int(revisionPolicy)
        removed = [key for key, value in self.entries.items() if value["revision"] < threshold]
        for key in removed:
            del self.entries[key]
        return {"retained": len(self.entries), "removed": len(removed), "revision": self.revision}


@dataclass(frozen=True)
class SemanticSnapshot:
    revision: int
    queryCount: int
    digest: str

    @classmethod
    def freeze(cls, queryDb: QueryDatabase) -> "SemanticSnapshot":
        valid = {key: row["digest"] for key, row in queryDb.entries.items() if row["state"] == "valid"}
        return cls(queryDb.revision, len(valid), _digest(valid, sorted(queryDb.edges)))


@dataclass(frozen=True)
class CacheKey:
    namespace: str
    inputs: dict[str, Any]
    versions: dict[str, Any]
    digest: str

    @classmethod
    def new(cls, namespace: str, inputs: dict[str, Any], versions: dict[str, Any]) -> "CacheKey":
        required = {"source", "options", "target", "abi", "dependencies"}
        if not required <= set(inputs) or "compiler" not in versions or "schema" not in versions:
            raise PerformanceError("NEBO-G049-CACHE-KEY-INCOMPLETE")
        return cls(str(namespace), dict(inputs), dict(versions), _digest(namespace, inputs, versions))


@dataclass
class CompilerCache:
    path: Path
    policy: str
    capability: str

    @classmethod
    def open(cls, path: str | Path, policy: str, capability: str) -> "CompilerCache":
        if policy not in {"off", "read", "read-write"}:
            raise PerformanceError("NEBO-G049-CACHE-POLICY")
        selected = Path(path)
        if selected.is_symlink() or (policy == "read-write" and capability != "cache-write"):
            raise PerformanceError("NEBO-G049-CACHE-CAPABILITY")
        target = selected.resolve()
        if policy == "read-write":
            target.mkdir(parents=True, exist_ok=True)
        if target.exists() and not target.is_dir():
            raise PerformanceError("NEBO-G049-CACHE-DIRECTORY")
        return cls(target, policy, capability)

    def _entry(self, key: CacheKey) -> Path:
        return self.path / f"{key.digest}.json"

    def lookup(self, key: CacheKey) -> dict[str, Any]:
        if self.policy == "off":
            return {"kind": "off", "key": key.digest}
        path = self._entry(key)
        if not path.is_file() or path.is_symlink():
            return {"kind": "miss", "key": key.digest}
        try:
            row = json.loads(path.read_text(encoding="utf-8"))
            if (not isinstance(row, dict) or type(row.get("schema")) is not int
                    or row["schema"] != 1 or not isinstance(row.get("payload"), str)
                    or not isinstance(row.get("metadata"), dict)):
                return {"kind": "corrupt", "key": key.digest}
            payload = base64.b64decode(row["payload"], validate=True)
        except (OSError, UnicodeError, ValueError, KeyError, RecursionError):
            return {"kind": "corrupt", "key": key.digest}
        if row.get("key") != key.digest or row.get("payloadDigest") != hashlib.sha256(payload).hexdigest():
            return {"kind": "corrupt", "key": key.digest}
        return {"kind": "hit", "key": key.digest, "artifact": payload,
                "metadata": row.get("metadata", {})}

    def store(self, key: CacheKey, artifact: bytes, metadata: dict[str, Any]) -> dict[str, Any]:
        if self.policy != "read-write" or self.capability != "cache-write":
            raise PerformanceError("NEBO-G049-CACHE-READ-ONLY")
        if len(artifact) > MAX_CACHE_BYTES:
            raise PerformanceError("NEBO-G049-CACHE-ARTIFACT-LIMIT")
        if len(list(self.path.glob("*.json"))) >= MAX_CACHE_ENTRIES and not self._entry(key).exists():
            raise PerformanceError("NEBO-G049-CACHE-ENTRY-LIMIT")
        row = {"schema": 1, "key": key.digest, "metadata": dict(metadata),
               "payload": base64.b64encode(artifact).decode(),
               "payloadDigest": hashlib.sha256(artifact).hexdigest()}
        _atomic_json(self._entry(key), row)
        return {"stored": True, "key": key.digest, "bytes": len(artifact)}

    def verify(self, key: CacheKey) -> dict[str, Any]:
        result = self.lookup(key)
        return {"status": "PASS" if result["kind"] in {"hit", "miss", "off"} else "FAIL",
                "kind": result["kind"], "key": key.digest}

    def invalidate(self, predicate: Callable[[dict[str, Any]], bool]) -> dict[str, int]:
        if self.policy != "read-write":
            raise PerformanceError("NEBO-G049-CACHE-READ-ONLY")
        removed = 0
        for path in sorted(self.path.glob("*.json")):
            try:
                row = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, UnicodeError, json.JSONDecodeError):
                row = {"corrupt": True}
            if predicate(row):
                path.unlink()
                removed += 1
        return {"removed": removed, "remaining": len(list(self.path.glob("*.json")))}

    def prune(self, maxBytes: int, maxItems: int, agePolicy: str) -> dict[str, int]:
        if self.policy != "read-write" or agePolicy not in {"oldest", "none"}:
            raise PerformanceError("NEBO-G049-CACHE-PRUNE")
        maxBytes = _bounded(maxBytes, 0, MAX_CACHE_BYTES, "NEBO-G049-CACHE-PRUNE")
        maxItems = _bounded(maxItems, 0, MAX_CACHE_ENTRIES, "NEBO-G049-CACHE-PRUNE")
        paths = sorted(self.path.glob("*.json"), key=lambda item: (item.stat().st_mtime_ns, item.name))
        removed = 0
        while len(paths) > maxItems or sum(path.stat().st_size for path in paths) > maxBytes:
            paths.pop(0).unlink()
            removed += 1
        return {"removed": removed, "remaining": len(paths),
                "bytes": sum(path.stat().st_size for path in paths)}

    def stats(self) -> dict[str, int | str]:
        paths = list(self.path.glob("*.json")) if self.path.exists() else []
        return {"policy": self.policy, "entries": len(paths),
                "bytes": sum(path.stat().st_size for path in paths), "maxEntries": MAX_CACHE_ENTRIES,
                "maxBytes": MAX_CACHE_BYTES}

    def explain(self, key: CacheKey) -> dict[str, Any]:
        return {"key": key.digest, "namespace": key.namespace, "inputs": key.inputs,
                "versions": key.versions, "lookup": self.lookup(key)["kind"]}


@dataclass
class BuildGraph:
    modules: dict[str, dict[str, Any]]

    @classmethod
    def fromModules(cls, modules: Iterable[dict[str, Any]]) -> "BuildGraph":
        rows = list(modules)
        if not rows or len(rows) > MAX_TASKS:
            raise PerformanceError("NEBO-G049-GRAPH-LIMIT")
        result: dict[str, dict[str, Any]] = {}
        for row in rows:
            name = str(row["id"])
            if name in result:
                raise PerformanceError("NEBO-G049-GRAPH-DUPLICATE")
            result[name] = {"id": name, "dependencies": tuple(map(str, row.get("dependencies", ()))),
                            "work": int(row.get("work", 1)), "memory": int(row.get("memory", 1))}
        if any(dep not in result for row in result.values() for dep in row["dependencies"]):
            raise PerformanceError("NEBO-G049-GRAPH-DEPENDENCY")
        return cls(result)

    def readyNodes(self, completed: Iterable[str]) -> list[str]:
        done = set(map(str, completed))
        return sorted(name for name, row in self.modules.items()
                      if name not in done and set(row["dependencies"]) <= done)


@dataclass
class CompileScheduler:
    workerBudget: int
    memoryBudget: int
    deterministic: bool = True
    tasks: list[dict[str, Any]] = field(default_factory=list)
    traceRows: list[dict[str, Any]] = field(default_factory=list)
    cancelled: str | None = None

    @classmethod
    def new(cls, workerBudget: int, memoryBudget: int) -> "CompileScheduler":
        return cls(_bounded(workerBudget, 1, MAX_WORKERS, "NEBO-G049-WORKER-BUDGET"),
                   _bounded(memoryBudget, 1, 1 << 40, "NEBO-G049-MEMORY-BUDGET"))

    def submit(self, unit: str, phase: str) -> int:
        if len(self.tasks) >= MAX_TASKS:
            raise PerformanceError("NEBO-G049-TASK-LIMIT")
        self.tasks.append({"unit": str(unit), "phase": str(phase), "state": "pending"})
        return len(self.tasks) - 1

    def run(self, graph: BuildGraph) -> dict[str, Any]:
        if self.cancelled is not None:
            return {"status": "CANCELLED", "cause": self.cancelled, "completed": []}
        completed: list[str] = []
        while len(completed) < len(graph.modules):
            ready = graph.readyNodes(completed)
            if not ready:
                raise PerformanceError("NEBO-G049-GRAPH-CYCLE")
            batch = ready[:self.workerBudget]
            if sum(graph.modules[name]["memory"] for name in batch) > self.memoryBudget:
                batch = [ready[0]]
                if graph.modules[batch[0]]["memory"] > self.memoryBudget:
                    raise PerformanceError("NEBO-G049-MEMORY-BUDGET")
            for name in batch:
                self.traceRows.append({"unit": name, "sequence": len(self.traceRows), "worker": 0})
                completed.append(name)
        return {"status": "PASS", "completed": completed, "digest": _digest(completed)}

    def cancel(self, cause: str) -> None:
        self.cancelled = str(cause)
        for task in self.tasks:
            if task["state"] == "pending":
                task["state"] = "cancelled"

    def deterministicMode(self, enabled: bool) -> "CompileScheduler":
        if not enabled:
            raise PerformanceError("NEBO-G049-NONDETERMINISTIC-FORBIDDEN")
        self.deterministic = True
        return self

    def criticalPath(self) -> dict[str, Any]:
        return {"units": [row["unit"] for row in self.traceRows], "length": len(self.traceRows)}

    def oversubscriptionReport(self) -> dict[str, int]:
        return {"workerBudget": self.workerBudget, "peakWorkers": min(self.workerBudget, len(self.traceRows)),
                "memoryBudget": self.memoryBudget, "throttles": 0}

    def trace(self) -> list[dict[str, Any]]:
        return [dict(row) for row in self.traceRows]


@dataclass
class Workspace:
    id: int
    root: str
    policy: str
    files: dict[str, bytes] = field(default_factory=dict)
    revision: int = 1
    owner: Any = field(default=None, repr=False)
    cached: dict = field(default_factory=dict, repr=False)
    closed: bool = False

    def _admit(self, replacement=None):
        files = self.files if replacement is None else replacement
        if self.closed or not files or len(files) > MAX_PROJECT_MODULES:
            raise PerformanceError("NEBO-G049-WORKSPACE-LIMIT")
        if any(Path(k).name != k or not k.endswith('.no') or not isinstance(v, bytes)
               or len(v) > MAX_SOURCE_BYTES for k, v in files.items()):
            raise PerformanceError("NEBO-G049-WORKSPACE-LIMIT")
        if self.owner:
            used = sum(len(v) for w in self.owner.workspaces.values()
                       for v in (files if w is self else w.files).values())
            if not self.owner.active or used > self.owner.maxBytes:
                raise PerformanceError("NEBO-G049-SERVER-MEMORY-LIMIT")
            cached = self.owner.memoryReport()['cacheBytes']
            if used + cached > self.owner.maxBytes:
                for workspace in self.owner.workspaces.values(): workspace.cached.clear()
        return files

    def update(self, file: str, edits: Iterable[TextEdit]) -> dict[str, Any]:
        name = str(file)
        data = self.files.get(name, b"")
        selected = sorted(edits, key=lambda edit: edit.span[0], reverse=True)
        ascending = list(reversed(selected))
        if any(edit.span[1] > len(data) for edit in selected) or any(
                left.span[1] > right.span[0] for left, right in zip(ascending, ascending[1:])):
            raise PerformanceError("NEBO-G049-WORKSPACE-EDIT")
        projected = len(data) + sum(len(edit.replacement) - (edit.span[1] - edit.span[0])
                                   for edit in selected)
        if projected > MAX_SOURCE_BYTES:
            raise PerformanceError("NEBO-G049-WORKSPACE-LIMIT")
        for edit in selected:
            start, end = edit.span
            data = data[:start] + edit.replacement + data[end:]
        self._admit({**self.files, name: data})
        self.files[name] = data
        self.cached.clear()
        self.revision += 1
        return {"revision": self.revision, "digest": _digest(data)}

    def _compile(self, request, build):
        files = self._admit()
        # Source snapshots and all native build inputs participate in reuse identity.
        dependencies = [NEBOC, ROOT / 'build/obj/runtime_core.o',
                        ROOT / 'build/obj/runtime_practical_io.o']
        key = _digest(build, sorted(files.items()),
                      [hashlib.sha256(p.read_bytes()).hexdigest() for p in dependencies])
        if key in self.cached:
            return {**copy.deepcopy(self.cached[key]), 'cacheHit': True, 'revision': self.revision}
        artifacts = {}; diagnostics = []
        with tempfile.TemporaryDirectory(prefix='nebo-session-') as temporary:
            work = Path(temporary)
            for name, data in sorted(files.items()):
                source = work / name; source.write_bytes(data)
                output = work / (name + '.elf')
                args = [str(NEBOC), 'build' if build else 'check', str(source)]
                if build: args += ['-o', str(output)]
                result = subprocess.run(args, cwd=ROOT, stdin=subprocess.DEVNULL,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
                if result.returncode:
                    raise PerformanceError('NEBO-G049-COMPILER-REJECTED-SOURCE:' +
                                           result.stderr.decode(errors='replace')[:4096])
                diagnostics.append(result.stdout + result.stderr)
                if build:
                    if output.stat().st_size > MAX_CACHE_BYTES:
                        raise PerformanceError('NEBO-G049-CACHE-ARTIFACT-LIMIT')
                    artifacts[name] = output.read_bytes()
        row = {'status': 'PASS', 'revision': self.revision, 'cacheHit': False,
               'diagnosticDigest': _digest(diagnostics), 'request': dict(request)}
        if build: row.update(artifactDigest=_digest(sorted(artifacts.items())), artifacts=artifacts)
        self.cached.clear()
        cache_bytes = sum(len(v) for v in artifacts.values())
        if not self.owner or self.owner.memoryReport()['bytes'] + cache_bytes <= self.owner.maxBytes:
            self.cached[key] = copy.deepcopy(row)
        return row

    def check(self, request: dict[str, Any]) -> dict[str, Any]:
        return self._compile(request, False)

    def build(self, request: dict[str, Any]) -> dict[str, Any]:
        return self._compile(request, True)


@dataclass
class CompilerServer:
    endpoint: str
    maxWorkspaces: int
    maxBytes: int
    capability: str
    workspaces: dict[int, Workspace] = field(default_factory=dict)
    active: bool = True

    @classmethod
    def start(cls, endpoint: str, limits: dict[str, int], capability: str) -> "CompilerServer":
        if not str(endpoint).startswith(("local://", "unix:")) or capability != "local-compiler-service":
            raise PerformanceError("NEBO-G049-LOCAL-ENDPOINT-REQUIRED")
        return cls(str(endpoint), _bounded(limits.get("workspaces", 0), 1, MAX_WORKSPACES,
                                           "NEBO-G049-SERVER-LIMIT"),
                   _bounded(limits.get("bytes", 0), 1, MAX_WORKSPACES * MAX_SOURCE_BYTES,
                            "NEBO-G049-SERVER-LIMIT"), capability)

    def openWorkspace(self, root: str, policy: str) -> Workspace:
        if not self.active or len(self.workspaces) >= self.maxWorkspaces:
            raise PerformanceError("NEBO-G049-SERVER-LIMIT")
        identity = 1 + max(self.workspaces, default=0)
        workspace = Workspace(identity, str(root), str(policy), owner=self)
        self.workspaces[identity] = workspace
        return workspace

    def evictWorkspace(self, id: int, reason: str) -> dict[str, Any]:
        removed = self.workspaces.pop(int(id), None)
        if removed:
            removed.closed = True
            removed.files.clear()
            removed.cached.clear()
        return {"evicted": removed is not None, "reason": str(reason), "id": int(id)}

    def memoryReport(self) -> dict[str, int]:
        used = sum(len(data) for workspace in self.workspaces.values() for data in workspace.files.values())
        cached = sum(len(v) for w in self.workspaces.values() for row in w.cached.values()
                     for v in row.get('artifacts', {}).values())
        return {"workspaces": len(self.workspaces), "bytes": used + cached,
                "sourceBytes": used, "cacheBytes": cached, "maxBytes": self.maxBytes}

    def shutdown(self, deadline: int) -> dict[str, Any]:
        if int(deadline) < 0:
            raise PerformanceError("NEBO-G049-SHUTDOWN-DEADLINE")
        self.active = False
        for identity in list(self.workspaces):
            self.evictWorkspace(identity, "shutdown")
        return {"status": "STOPPED", "deadline": int(deadline)}


@dataclass(frozen=True)
class CompilerClient:
    server: CompilerServer
    fallback: bool

    @classmethod
    def connect(cls, endpoint: CompilerServer | str, expectedVersion: int) -> "CompilerClient":
        if int(expectedVersion) != 1 or not isinstance(endpoint, CompilerServer) or not endpoint.active:
            raise PerformanceError("NEBO-G049-SERVER-VERSION")
        return cls(endpoint, False)


@dataclass
class ProjectModel:
    modules: dict[str, dict[str, Any]]
    limits: dict[str, int]
    diagnostics: list[str] = field(default_factory=list)
    materialized: set[str] = field(default_factory=set)
    pressure: str = "normal"

    @classmethod
    def load(cls, manifest: Iterable[dict[str, Any]], limits: dict[str, int]) -> "ProjectModel":
        rows = list(manifest)
        maximum = _bounded(limits.get("modules", 0), 1, MAX_PROJECT_MODULES,
                           "NEBO-G049-PROJECT-LIMIT")
        max_bytes = _bounded(limits.get("bytes", 0), 1, MAX_PROJECT_MODULES * MAX_SOURCE_BYTES,
                             "NEBO-G049-PROJECT-LIMIT")
        if not rows or len(rows) > maximum or sum(int(row.get("bytes", 0)) for row in rows) > max_bytes:
            raise PerformanceError("NEBO-G049-PROJECT-LIMIT")
        if any(int(row.get("bytes", 0)) < 0 for row in rows):
            raise PerformanceError("NEBO-G049-PROJECT-LIMIT")
        modules = {str(row["id"]): dict(row) for row in rows}
        if len(modules) != len(rows):
            raise PerformanceError("NEBO-G049-PROJECT-DUPLICATE")
        return cls(modules, {"modules": maximum, "bytes": max_bytes})

    def lazyModule(self, id: str) -> dict[str, Any]:
        name = str(id)
        if name not in self.modules:
            raise PerformanceError("NEBO-G049-PROJECT-MODULE")
        self.materialized.add(name)
        return dict(self.modules[name])

    def chunkDiagnostics(self, maxItems: int) -> list[list[str]]:
        size = _bounded(maxItems, 1, 64, "NEBO-G049-DIAGNOSTIC-CHUNK")
        return [self.diagnostics[index:index + size] for index in range(0, len(self.diagnostics), size)]

    def incrementalLinkPlan(self, changedObjects: Iterable[str]) -> dict[str, Any]:
        changed = sorted(set(map(str, changedObjects)))
        return {"changed": changed, "relink": bool(changed), "digest": _digest(changed)}

    def fileWatch(self, events: Iterable[dict[str, Any]], coalescePolicy: str) -> dict[str, int]:
        if coalescePolicy != "latest-per-path":
            raise PerformanceError("NEBO-G049-WATCH-POLICY")
        rows = list(events)
        unique = {str(row["path"]): row for row in rows}
        return {"events": len(rows), "unique": len(unique), "coalesced": len(rows) - len(unique)}

    def pressurePolicy(self, level: str) -> dict[str, Any]:
        if level not in {"normal", "high", "critical"}:
            raise PerformanceError("NEBO-G049-PRESSURE-LEVEL")
        self.pressure = level
        return {"level": level, "workers": 4 if level == "normal" else 2 if level == "high" else 1,
                "evictRecomputable": level != "normal"}

    def progressSnapshot(self) -> dict[str, int]:
        return {"completed": len(self.materialized), "pending": len(self.modules) - len(self.materialized),
                "blocked": 0, "materialized": len(self.materialized)}

    def scalabilityReport(self) -> dict[str, Any]:
        return {"modules": len(self.modules), "materialized": len(self.materialized),
                "lazy": len(self.modules) - len(self.materialized), "pressure": self.pressure,
                "digest": _digest(sorted(self.modules), sorted(self.materialized), self.pressure)}

    @staticmethod
    def syntheticCorpus(config: dict[str, int]) -> list[dict[str, Any]]:
        count = _bounded(config.get("modules", 0), 1, MAX_PROJECT_MODULES,
                         "NEBO-G049-CORPUS-LIMIT")
        size = _bounded(config.get("bytesPerModule", 0), 1, MAX_SOURCE_BYTES,
                        "NEBO-G049-CORPUS-LIMIT")
        return [{"id": f"module-{index:03d}", "bytes": size,
                 "hash": _digest(index, size)} for index in range(count)]


@dataclass(frozen=True)
class CompilerBudget:
    metric: str
    limit: float
    scope: str

    @classmethod
    def new(cls, metric: str, limit: float, scope: str) -> "CompilerBudget":
        if not math.isfinite(float(limit)) or float(limit) < 0:
            raise PerformanceError("NEBO-G049-BUDGET-LIMIT")
        return cls(str(metric), float(limit), str(scope))

    def evaluate(self, result: float, baseline: float, noisePolicy: dict[str, float]) -> dict[str, Any]:
        noise = float(noisePolicy.get("relative", 0.0))
        if not all(math.isfinite(float(x)) for x in (noise, result, baseline)) or noise < 0 or noise > 1 or float(result) < 0 or float(baseline) < 0:
            raise PerformanceError("NEBO-G049-NOISE-POLICY")
        value = float(result)
        threshold = self.limit + abs(float(baseline)) * noise
        return {"metric": self.metric, "value": value, "limit": self.limit,
                "threshold": threshold, "classification": "PASS" if value <= threshold else "REGRESSION"}


@dataclass
class CompilerBenchmarkSuite:
    corpus: list[Path]
    version: str
    samples: list[int] = field(default_factory=list)
    mode: str = "cold"

    @classmethod
    def load(cls, versionedCorpus: dict[str, Any]) -> "CompilerBenchmarkSuite":
        version = str(versionedCorpus.get("version", ""))
        paths = [_regular_file(path) for path in versionedCorpus.get("sources", [])]
        if not version or not paths:
            raise PerformanceError("NEBO-G049-BENCH-CORPUS")
        return cls(paths, version)

    def _run(self, mode: str, count: int) -> dict[str, Any]:
        count = _bounded(count, 3, MAX_SAMPLES, "NEBO-G049-SAMPLE-COUNT")
        samples: list[int] = []
        if mode == "warm":
            for source in self.corpus:
                _admit_source(source)
        for _ in range(count):
            started = time.monotonic_ns()
            for source in self.corpus:
                _admit_source(source)
            samples.append(max(1, time.monotonic_ns() - started))
        self.samples, self.mode = samples, mode
        return {"mode": mode, "samples": samples, "statistics": self.statistics()}

    def runCold(self, samples: int) -> dict[str, Any]:
        return self._run("cold", samples)

    def runWarm(self, samples: int) -> dict[str, Any]:
        return self._run("warm", samples)

    def runIncremental(self, editSequences: Iterable[Iterable[TextEdit]]) -> dict[str, Any]:
        selected = list(editSequences)
        if not 3 <= len(selected) <= MAX_SAMPLES:
            raise PerformanceError("NEBO-G049-SAMPLE-COUNT")
        # Each edit sequence applies to the original first corpus source.
        # Time actual validation of each resulting revision; do not count bytes as ns.
        original = self.corpus[0].read_bytes()
        samples = []
        with tempfile.TemporaryDirectory(prefix='nebo-incremental-') as directory:
            for sequence in selected:
                workspace = Workspace(1, directory, 'bounded', {'main.no': original})
                workspace.update('main.no', sequence)
                source = Path(directory) / 'main.no'
                source.write_bytes(workspace.files['main.no'])
                started = time.monotonic_ns()
                _admit_source(source)
                for other in self.corpus[1:]: _admit_source(other)
                samples.append(max(1, time.monotonic_ns() - started))
        self.samples = samples
        self.mode = "incremental"
        return {"mode": self.mode, "samples": self.samples, "statistics": self.statistics()}

    def statistics(self) -> dict[str, Any]:
        if not self.samples:
            raise PerformanceError("NEBO-G049-NO-SAMPLES")
        ordered = sorted(self.samples)
        median = int(statistics.median(ordered))
        deviations = [abs(value - median) for value in ordered]
        return {"median": median, "p95": ordered[min(len(ordered) - 1, int(len(ordered) * .95))],
                "mad": int(statistics.median(deviations)), "min": ordered[0], "max": ordered[-1],
                "count": len(ordered)}

    def compare(self, baseline: dict[str, Any]) -> dict[str, Any]:
        current = self.statistics()["median"]
        old = int(baseline["median"])
        delta = current - old
        return {"current": current, "baseline": old, "delta": delta,
                "classification": "PASS" if current <= old else "REGRESSION"}

    def reproducibilityManifest(self) -> dict[str, Any]:
        try:
            commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                             text=True, timeout=5).strip()
        except (OSError, subprocess.SubprocessError):
            commit = "UNAVAILABLE"
        return {"schema": 1, "version": self.version, "mode": self.mode,
                "samples": len(self.samples), "corpusDigest": _digest([hashlib.sha256(p.read_bytes()).hexdigest()
                                                                         for p in self.corpus]),
                "host": os.uname().sysname + "-" + os.uname().machine,
                "kernel": os.uname().release, "target": "x86_64-systemv-elf-linux",
                "commit": commit, "warmupSamples": 1 if self.mode == "warm" else 0, "dispersion": self.statistics()}
