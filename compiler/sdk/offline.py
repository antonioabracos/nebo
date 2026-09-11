"""Deterministic, bounded reference SDK for Nebo G033 offline convergence.

The implementation is deliberately local and dependency-free.  It models the
public contract without sockets, wall clocks, background workers, or hidden
last-writer-wins decisions.  Every mutation is bounded and failures publish no
partial state.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from types import MappingProxyType
from typing import Any, Callable, Iterable, Mapping


MAX_EVENTS = 4096
MAX_CHANGES = 4096
MAX_BYTES = 1_048_576
MAX_BATCH = 256
MAX_REPLICAS = 16
MAX_QUEUE = 256


class OfflineError(RuntimeError):
    """Stable fail-closed diagnostic for the public G033 surface."""

    def __init__(self, suffix: str, operation: str):
        self._code = f"NEBO-G033-{suffix}"
        self._operation = operation
        super().__init__(f"{self._code}: {operation}")

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _reject(condition: bool, suffix: str, operation: str) -> None:
    if condition:
        raise OfflineError(suffix, operation)


def _name(value: Any, suffix: str, operation: str) -> str:
    _reject(not isinstance(value, str) or not value or len(value) > 96
            or any(not (character.isalnum() or character in "-_.:/") for character in value),
            suffix, operation)
    return value


def _integer(value: Any, suffix: str, operation: str, minimum: int = 0,
             maximum: int = 2**63 - 1) -> int:
    _reject(isinstance(value, bool) or not isinstance(value, int)
            or value < minimum or value > maximum, suffix, operation)
    return value


def _plain(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _plain(item) for key, item in value.items()}
    if isinstance(value, (tuple, list)):
        return [_plain(item) for item in value]
    if isinstance(value, (set, frozenset)):
        return sorted(_plain(item) for item in value)
    if isinstance(value, VersionVector):
        return dict(value.items())
    return value


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(item) for key, item in value.items()})
    if isinstance(value, (tuple, list)):
        return tuple(_freeze(item) for item in value)
    if isinstance(value, (set, frozenset)):
        return frozenset(_freeze(item) for item in value)
    return value


def _canonical(value: Any) -> bytes:
    return json.dumps(_plain(value), sort_keys=True, separators=(",", ":"),
                      ensure_ascii=True).encode("ascii")


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


@dataclass(frozen=True)
class Capability:
    kind: str
    operations: frozenset[str]
    root: str = "local"

    @staticmethod
    def issue(kind: str, operations: Iterable[str], root: str = "local") -> "Capability":
        operation = "Capability.issue"
        kind = _name(kind, "CAPABILITY", operation)
        root = _name(root, "CAPABILITY", operation)
        rights = frozenset(operations)
        _reject(not rights or any(not isinstance(item, str) or not item for item in rights),
                "CAPABILITY", operation)
        return Capability(kind, rights, root)

    def require(self, kind: str, right: str, operation: str) -> None:
        _reject(self.kind != kind or right not in self.operations,
                "CAPABILITY-DENIED", operation)


class VersionVector:
    """Bounded vector clock with the four-way partial-order comparison."""

    def __init__(self, values: Mapping[str, int] | None = None):
        self._values: dict[str, int] = {}
        for replica, counter in (values or {}).items():
            self.observe(replica, counter)

    @staticmethod
    def new() -> "VersionVector":
        return VersionVector()

    def observe(self, replicaId: str, counter: int) -> "VersionVector":
        operation = "version.observe"
        replica = _name(replicaId, "REPLICA-ID", operation)
        counter = _integer(counter, "VECTOR-COUNTER", operation)
        _reject(replica not in self._values and len(self._values) >= MAX_REPLICAS,
                "REPLICA-LIMIT", operation)
        _reject(counter < self._values.get(replica, 0), "VECTOR-REGRESSION", operation)
        self._values[replica] = counter
        return self

    def compare(self, other: "VersionVector") -> str:
        _reject(not isinstance(other, VersionVector), "VECTOR", "version.compare")
        less = greater = False
        for replica in set(self._values) | set(other._values):
            left, right = self[replica], other[replica]
            less |= left < right
            greater |= left > right
        if less and greater:
            return "concurrent"
        if less:
            return "before"
        if greater:
            return "after"
        return "equal"

    def copy(self) -> "VersionVector":
        return VersionVector(self._values)

    def items(self) -> tuple[tuple[str, int], ...]:
        return tuple(sorted(self._values.items()))

    def __getitem__(self, replica: str) -> int:
        return self._values.get(replica, 0)

    def __eq__(self, other: object) -> bool:
        return isinstance(other, VersionVector) and self.items() == other.items()

    def __repr__(self) -> str:
        return f"VersionVector({dict(self.items())!r})"


@dataclass(frozen=True)
class LogicalClockCapability:
    identity: str
    maximum: int = 2**63 - 1

    @staticmethod
    def deterministic(identity: str, maximum: int = 2**63 - 1) -> "LogicalClockCapability":
        return LogicalClockCapability(_name(identity, "CLOCK-ID", "LogicalClockCapability.deterministic"),
                                      _integer(maximum, "CLOCK-LIMIT",
                                               "LogicalClockCapability.deterministic", 1))


class HybridLogicalClock:
    def __init__(self, capability: LogicalClockCapability):
        self.capability = capability
        self.physical = 0
        self.logical = 0

    @staticmethod
    def new(clockCapability: LogicalClockCapability) -> "HybridLogicalClock":
        _reject(not isinstance(clockCapability, LogicalClockCapability),
                "CLOCK-CAPABILITY", "HybridLogicalClock.new")
        return HybridLogicalClock(clockCapability)

    def tick(self, physical: int) -> tuple[int, int, str]:
        physical = _integer(physical, "CLOCK-VALUE", "clock.tick", 0,
                            self.capability.maximum)
        if physical > self.physical:
            self.physical, self.logical = physical, 0
        else:
            self.logical += 1
        return self.physical, self.logical, self.capability.identity

    def receive(self, timestamp: tuple[int, int, str], physical: int) -> tuple[int, int, str]:
        operation = "clock.receive"
        _reject(not isinstance(timestamp, tuple) or len(timestamp) != 3,
                "CLOCK-TIMESTAMP", operation)
        remote_physical = _integer(timestamp[0], "CLOCK-TIMESTAMP", operation, 0,
                                   self.capability.maximum)
        remote_logical = _integer(timestamp[1], "CLOCK-TIMESTAMP", operation)
        physical = _integer(physical, "CLOCK-VALUE", operation, 0, self.capability.maximum)
        maximum = max(self.physical, remote_physical, physical)
        if maximum == self.physical == remote_physical:
            logical = max(self.logical, remote_logical) + 1
        elif maximum == self.physical:
            logical = self.logical + 1
        elif maximum == remote_physical:
            logical = remote_logical + 1
        else:
            logical = 0
        self.physical, self.logical = maximum, logical
        return maximum, logical, self.capability.identity


@dataclass(frozen=True)
class DomainEvent:
    stream_id: str
    event_id: str
    actor: str
    sequence: int
    schema: str
    timestamp: tuple[int, int, str]
    payload: Mapping[str, Any]
    parents: tuple[str, ...]
    provenance_record: Mapping[str, Any]
    previous_hash: str
    content_hash: str

    def metadata(self) -> Mapping[str, Any]:
        return _freeze({"id": self.event_id, "stream": self.stream_id, "actor": self.actor,
                        "sequence": self.sequence, "schema": self.schema,
                        "timestamp": self.timestamp, "causalParents": self.parents,
                        "provenance": self.provenance_record,
                        "previousHash": self.previous_hash, "hash": self.content_hash})


@dataclass(frozen=True)
class Snapshot:
    stream_id: str
    version: int
    state: Any
    prefix_hash: str


class Subscription:
    def __init__(self, specification: Mapping[str, Any]):
        operation = "store.subscribe"
        _reject(not isinstance(specification, Mapping), "FILTER", operation)
        self.stream = specification.get("streamId")
        if self.stream is not None:
            self.stream = _name(self.stream, "STREAM-ID", operation)
        self.capacity = _integer(specification.get("capacity", 16), "QUEUE-LIMIT", operation,
                                 1, MAX_QUEUE)
        self._queue: list[DomainEvent] = []

    def matches(self, event: DomainEvent) -> bool:
        return self.stream is None or event.stream_id == self.stream

    def events(self) -> tuple[DomainEvent, ...]:
        result = tuple(self._queue)
        self._queue.clear()
        return result


class EventStore:
    def __init__(self, path: str, options: Mapping[str, Any], capability: Capability):
        self.path, self.capability = path, capability
        self.max_events = _integer(options.get("maxEvents", MAX_EVENTS), "EVENT-LIMIT",
                                   "EventStore.open", 1, MAX_EVENTS)
        self._streams: dict[str, list[DomainEvent]] = {}
        self._ids: dict[str, str] = {}
        self._snapshots: dict[str, Snapshot] = {}
        self._subscriptions: list[Subscription] = []

    @staticmethod
    def open(path: str, options: Mapping[str, Any], capability: Capability) -> "EventStore":
        operation = "EventStore.open"
        path = _name(path, "STORE-PATH", operation)
        _reject(path.startswith("/") or ".." in path.split("/"), "STORE-PATH", operation)
        _reject(not isinstance(options, Mapping) or not isinstance(capability, Capability),
                "STORE-OPTIONS", operation)
        capability.require("event-store", "open", operation)
        return EventStore(path, options, capability)

    def append(self, streamId: str, event: Mapping[str, Any], expectedVersion: int) -> DomainEvent:
        operation = "store.append"
        self.capability.require("event-store", "append", operation)
        stream = _name(streamId, "STREAM-ID", operation)
        expected = _integer(expectedVersion, "EXPECTED-VERSION", operation)
        _reject(not isinstance(event, Mapping), "EVENT", operation)
        current = self._streams.get(stream, [])
        _reject(expected != len(current), "VERSION-CONFLICT", operation)
        _reject(sum(len(items) for items in self._streams.values()) >= self.max_events,
                "EVENT-LIMIT", operation)
        event_id = _name(event.get("id"), "EVENT-ID", operation)
        _reject(event_id in self._ids, "DUPLICATE-EVENT", operation)
        actor = _name(event.get("actor"), "ACTOR", operation)
        schema = _name(event.get("schema"), "SCHEMA", operation)
        timestamp = event.get("timestamp")
        _reject(not isinstance(timestamp, tuple) or len(timestamp) != 3,
                "TIMESTAMP", operation)
        timestamp = (_integer(timestamp[0], "TIMESTAMP", operation),
                     _integer(timestamp[1], "TIMESTAMP", operation),
                     _name(timestamp[2], "TIMESTAMP", operation))
        payload = event.get("payload")
        provenance = event.get("provenance")
        parents = event.get("causalParents", ())
        _reject(not isinstance(payload, Mapping) or not isinstance(provenance, Mapping)
                or not isinstance(parents, (tuple, list)), "EVENT", operation)
        parents = tuple(_name(item, "CAUSAL-PARENT", operation) for item in parents)
        _reject(any(parent not in self._ids for parent in parents), "CAUSAL-GAP", operation)
        previous = current[-1].content_hash if current else "0" * 64
        content = {"stream": stream, "id": event_id, "actor": actor,
                   "sequence": expected + 1, "schema": schema, "timestamp": timestamp,
                   "payload": payload, "parents": parents, "provenance": provenance,
                   "previousHash": previous}
        stored = DomainEvent(stream, event_id, actor, expected + 1, schema, timestamp,
                             _freeze(payload), parents, _freeze(provenance), previous,
                             _digest(content))
        matching = [subscriber for subscriber in self._subscriptions if subscriber.matches(stored)]
        _reject(any(len(subscriber._queue) >= subscriber.capacity for subscriber in matching),
                "BACKPRESSURE", operation)
        self._streams.setdefault(stream, []).append(stored)
        self._ids[event_id] = stream
        for subscriber in matching:
            subscriber._queue.append(stored)
        return stored

    def read(self, streamId: str, range: Mapping[str, int]) -> tuple[DomainEvent, ...]:
        operation = "store.read"
        self.capability.require("event-store", "read", operation)
        stream = _name(streamId, "STREAM-ID", operation)
        _reject(not isinstance(range, Mapping), "READ-RANGE", operation)
        start = _integer(range.get("start", 0), "READ-RANGE", operation)
        end = _integer(range.get("end", len(self._streams.get(stream, ()))),
                       "READ-RANGE", operation)
        _reject(end < start or end - start > self.max_events, "READ-RANGE", operation)
        return tuple(self._streams.get(stream, ()))[start:end]

    def replay(self, streamId: str, reducer: Mapping[str, Any]) -> Any:
        operation = "store.replay"
        _reject(not isinstance(reducer, Mapping) or "initial" not in reducer
                or not callable(reducer.get("apply")), "REDUCER", operation)
        state = reducer["initial"]
        for event in self.read(streamId, {"start": 0, "end": self.max_events}):
            state = reducer["apply"](state, event)
        return state

    def snapshot(self, streamId: str, state: Any) -> Snapshot:
        operation = "store.snapshot"
        self.capability.require("event-store", "snapshot", operation)
        stream = _name(streamId, "STREAM-ID", operation)
        events = self._streams.get(stream, ())
        snapshot = Snapshot(stream, len(events), _freeze(state),
                            events[-1].content_hash if events else "0" * 64)
        self._snapshots[stream] = snapshot
        return snapshot

    def subscribe(self, filter: Mapping[str, Any]) -> Subscription:
        self.capability.require("event-store", "subscribe", "store.subscribe")
        subscriber = Subscription(filter)
        self._subscriptions.append(subscriber)
        return subscriber

    def verify(self) -> Mapping[str, Any]:
        self.capability.require("event-store", "verify", "store.verify")
        checked = 0
        for stream, events in sorted(self._streams.items()):
            previous = "0" * 64
            for index, event in enumerate(events, 1):
                content = {"stream": stream, "id": event.event_id, "actor": event.actor,
                           "sequence": index, "schema": event.schema,
                           "timestamp": event.timestamp, "payload": event.payload,
                           "parents": event.parents, "provenance": event.provenance_record,
                           "previousHash": previous}
                _reject(event.sequence != index or event.previous_hash != previous
                        or event.content_hash != _digest(content), "CORRUPT-LOG", "store.verify")
                previous, checked = event.content_hash, checked + 1
            snapshot = self._snapshots.get(stream)
            if snapshot is not None:
                _reject(snapshot.version > len(events), "CORRUPT-SNAPSHOT", "store.verify")
                expected = events[snapshot.version - 1].content_hash if snapshot.version else "0" * 64
                _reject(snapshot.prefix_hash != expected,
                        "CORRUPT-SNAPSHOT", "store.verify")
        return _freeze({"verified": True, "events": checked,
                        "streams": len(self._streams), "snapshots": len(self._snapshots)})


@dataclass(frozen=True)
class Change:
    id: str
    replica_id: str
    counter: int
    schema: str
    payload: Mapping[str, Any]
    parents: tuple[str, ...]
    provenance_record: Mapping[str, Any]

    def causalParents(self) -> tuple[str, ...]:
        return self.parents

    def encoded_bytes(self) -> bytes:
        return _canonical({"id": self.id, "replica": self.replica_id,
                           "counter": self.counter, "schema": self.schema,
                           "payload": self.payload, "parents": self.parents,
                           "provenance": self.provenance_record})


class _Causal:
    def ready(self, change: Change, version: VersionVector) -> bool:
        _reject(not isinstance(change, Change) or not isinstance(version, VersionVector),
                "CAUSAL-INPUT", "causal.ready")
        for parent in change.parents:
            try:
                replica, counter_text = parent.rsplit(":", 1)
                counter = int(counter_text)
            except (ValueError, AttributeError):
                raise OfflineError("CAUSAL-PARENT", "causal.ready")
            if version[replica] < counter:
                return False
        return version[change.replica_id] + 1 >= change.counter

    def explainOrder(self, a: Change, b: Change) -> Mapping[str, Any]:
        _reject(not isinstance(a, Change) or not isinstance(b, Change),
                "CAUSAL-INPUT", "causal.explainOrder")
        if a.id == b.id:
            relation = "equal"
        elif a.id in b.parents:
            relation = "before"
        elif b.id in a.parents:
            relation = "after"
        elif a.replica_id == b.replica_id:
            relation = "before" if a.counter < b.counter else "after"
        else:
            relation = "concurrent"
        return _freeze({"relation": relation, "a": a.id, "b": b.id,
                        "reason": "causal-parent" if relation in ("before", "after") else relation})


causal = _Causal()


class Replica:
    def __init__(self, identity: str, storage: EventStore | None, policy: Mapping[str, Any]):
        self.identity, self.storage = identity, storage
        schemas = policy.get("schemas", ("state/v1",))
        _reject(not isinstance(schemas, (tuple, list)) or not schemas,
                "REPLICA-POLICY", "Replica.open")
        self.schemas = frozenset(_name(item, "SCHEMA", "Replica.open") for item in schemas)
        self.max_changes = _integer(policy.get("maxChanges", MAX_CHANGES), "CHANGE-LIMIT",
                                    "Replica.open", 1, MAX_CHANGES)
        self.max_bytes = _integer(policy.get("maxBytes", MAX_BYTES), "BYTE-LIMIT",
                                  "Replica.open", 1, MAX_BYTES)
        self._changes: dict[str, Change] = {}
        self._pending: dict[str, Change] = {}
        self._version = VersionVector.new()
        self._peer_versions: dict[str, VersionVector] = {}
        self._base_state: dict[str, Any] = {}
        self._audit: list[Mapping[str, Any]] = []

    @staticmethod
    def open(identity: str, storage: EventStore | None, policy: Mapping[str, Any]) -> "Replica":
        operation = "Replica.open"
        identity = _name(identity, "REPLICA-ID", operation)
        _reject(storage is not None and not isinstance(storage, EventStore), "STORAGE", operation)
        _reject(not isinstance(policy, Mapping), "REPLICA-POLICY", operation)
        return Replica(identity, storage, policy)

    def emit(self, payload: Mapping[str, Any], schema: str = "state/v1",
             parents: Iterable[str] | None = None,
             provenance: Mapping[str, Any] | None = None) -> Change:
        operation = "replica.emit"
        _reject(not isinstance(payload, Mapping), "CHANGE", operation)
        schema = _name(schema, "SCHEMA", operation)
        _reject(schema not in self.schemas, "SCHEMA", operation)
        counter = self._version[self.identity] + 1
        _reject(len(self._changes) >= self.max_changes, "CHANGE-LIMIT", operation)
        if parents is None:
            parents = tuple(f"{replica}:{value}" for replica, value in self._version.items() if value)
        parent_tuple = tuple(_name(item, "CAUSAL-PARENT", operation) for item in parents)
        change = Change(f"{self.identity}:{counter}", self.identity, counter, schema,
                        _freeze(payload), parent_tuple,
                        _freeze(provenance or {"origin": "local", "actor": self.identity}))
        _reject(len(change.encoded_bytes()) > self.max_bytes, "BYTE-LIMIT", operation)
        self._changes[change.id] = change
        self._version.observe(self.identity, counter)
        self._audit.append(_freeze({"action": "emit", "change": change.id,
                                    "origin": change.provenance_record.get("origin", "local")}))
        return change

    def localVersion(self) -> VersionVector:
        return self._version.copy()

    def changesSince(self, version: VersionVector,
                     limits: Mapping[str, int]) -> tuple[Change, ...]:
        operation = "replica.changesSince"
        _reject(not isinstance(version, VersionVector) or not isinstance(limits, Mapping),
                "CHANGE-RANGE", operation)
        maximum_changes = _integer(limits.get("changes", MAX_BATCH), "CHANGE-LIMIT", operation,
                                   1, min(MAX_BATCH, self.max_changes))
        maximum_bytes = _integer(limits.get("bytes", self.max_bytes), "BYTE-LIMIT", operation,
                                 1, self.max_bytes)
        result: list[Change] = []
        used = 0
        for change in sorted(self._changes.values(), key=lambda item: (item.counter, item.replica_id)):
            if change.counter <= version[change.replica_id]:
                continue
            size = len(change.encoded_bytes())
            if len(result) >= maximum_changes or used + size > maximum_bytes:
                break
            result.append(change)
            used += size
        return tuple(result)

    def apply(self, changes: Iterable[Change]) -> Mapping[str, Any]:
        operation = "replica.apply"
        incoming = tuple(changes)
        _reject(len(incoming) > self.max_changes, "CHANGE-LIMIT", operation)
        staged_changes = dict(self._changes)
        staged_pending = dict(self._pending)
        staged_version = self._version.copy()
        for change in incoming:
            _reject(not isinstance(change, Change), "CHANGE", operation)
            _reject(change.schema not in self.schemas or change.counter < 1
                    or change.id != f"{change.replica_id}:{change.counter}"
                    or not isinstance(change.payload, Mapping)
                    or not isinstance(change.provenance_record, Mapping)
                    or not isinstance(change.parents, tuple), "CHANGE", operation)
            if (change.counter <= staged_version[change.replica_id]
                    and change.id not in staged_changes and change.id not in staged_pending):
                continue
            existing = staged_changes.get(change.id) or staged_pending.get(change.id)
            _reject(existing is not None and existing != change, "CHANGE-COLLISION", operation)
            if existing is None:
                staged_pending[change.id] = change
        _reject(len(staged_changes) + len(staged_pending) > self.max_changes,
                "CHANGE-LIMIT", operation)
        progressed = True
        applied = 0
        while progressed:
            progressed = False
            for change in sorted(tuple(staged_pending.values()),
                                 key=lambda item: (item.counter, item.replica_id)):
                if causal.ready(change, staged_version):
                    staged_changes[change.id] = change
                    staged_version.observe(change.replica_id,
                                           max(staged_version[change.replica_id], change.counter))
                    del staged_pending[change.id]
                    applied += 1
                    progressed = True
        total_bytes = sum(len(change.encoded_bytes()) for change in staged_changes.values())
        _reject(total_bytes > self.max_bytes, "BYTE-LIMIT", operation)
        self._changes, self._pending, self._version = staged_changes, staged_pending, staged_version
        self._audit.append(_freeze({"action": "apply", "received": len(incoming),
                                    "applied": applied, "pending": len(staged_pending)}))
        return _freeze({"received": len(incoming), "applied": applied,
                        "pending": len(staged_pending), "atomic": True})

    def pending(self) -> tuple[Change, ...]:
        return tuple(sorted(self._pending.values(), key=lambda item: (item.counter, item.replica_id)))

    def peers(self) -> Mapping[str, Mapping[str, int]]:
        return _freeze({peer: dict(version.items()) for peer, version in sorted(self._peer_versions.items())})

    def _ack_peer(self, peer: str, version: VersionVector) -> None:
        self._peer_versions[_name(peer, "PEER-ID", "replica.peers")] = version.copy()

    def status(self) -> Mapping[str, Any]:
        return _freeze({"identity": self.identity, "changes": len(self._changes),
                        "pending": len(self._pending), "version": dict(self._version.items()),
                        "peers": len(self._peer_versions), "bounded": True})

    def materialized(self) -> Mapping[str, Any]:
        state = dict(self._base_state)
        by_key: dict[str, list[Change]] = {}
        for change in self._changes.values():
            key = change.payload.get("key")
            if isinstance(key, str):
                by_key.setdefault(key, []).append(change)
        def ancestor(left: Change, right: Change, seen: set[str] | None = None) -> bool:
            if left.replica_id == right.replica_id and left.counter < right.counter:
                return True
            if left.id in right.parents:
                return True
            visited = seen or set()
            for parent_id in right.parents:
                if parent_id in visited:
                    continue
                visited.add(parent_id)
                parent = self._changes.get(parent_id)
                if parent is not None and ancestor(left, parent, visited):
                    return True
            return False
        for key, candidates in sorted(by_key.items()):
            maximal = [candidate for candidate in candidates if not any(
                ancestor(candidate, other) for other in candidates if other.id != candidate.id)]
            maximal.sort(key=lambda item: item.id)
            if len(maximal) == 1:
                payload = maximal[0].payload
                if payload.get("delete") is True:
                    state.pop(key, None)
                elif "value" in payload:
                    state[key] = _plain(payload["value"])
            elif maximal:
                state[key] = {"conflict": tuple({"id": item.id,
                                                   "value": _plain(item.payload.get("value")),
                                                   "deleted": item.payload.get("delete") is True,
                                                   "provenance": _plain(item.provenance_record)}
                                                  for item in maximal)}
        return _freeze(state)

    def checkpoint(self) -> Mapping[str, Any]:
        content = {"identity": self.identity, "version": dict(self._version.items()),
                   "state": self.materialized(), "pending": tuple(sorted(self._pending))}
        return _freeze({**content, "hash": _digest(content)})

    def stableVersion(self) -> VersionVector:
        if not self._peer_versions:
            return self._version.copy()
        stable = VersionVector.new()
        replicas = {key for key, _ in self._version.items()}
        for peer_version in self._peer_versions.values():
            replicas.update(key for key, _ in peer_version.items())
        for replica in sorted(replicas):
            stable.observe(replica, min([self._version[replica]]
                                       + [version[replica] for version in self._peer_versions.values()]))
        return stable

    def validateInvariants(self, rules: Iterable[Callable[[Mapping[str, Any]], bool]]) -> Mapping[str, Any]:
        operation = "replica.validateInvariants"
        rule_tuple = tuple(rules)
        _reject(not rule_tuple or any(not callable(rule) for rule in rule_tuple),
                "INVARIANT", operation)
        state = self.materialized()
        results = tuple(bool(rule(state)) for rule in rule_tuple)
        return _freeze({"valid": all(results), "results": results, "stateHash": _digest(state)})

    def repair(self, plan: Mapping[str, Any]) -> Change:
        operation = "replica.repair"
        _reject(not isinstance(plan, Mapping) or not isinstance(plan.get("payload"), Mapping)
                or not isinstance(plan.get("reason"), str) or not plan.get("reason"),
                "REPAIR-PLAN", operation)
        return self.emit(plan["payload"], plan.get("schema", "state/v1"),
                         provenance={"origin": "repair", "reason": plan["reason"],
                                     "actor": self.identity})

    def compactStable(self) -> Mapping[str, Any]:
        operation = "replica.compactStable"
        _reject(bool(self._pending), "CAUSAL-GAP", operation)
        _reject(not self._peer_versions, "STABILITY-UNKNOWN", operation)
        stable = self.stableVersion()
        before_state = self.materialized()
        retained = {identifier: change for identifier, change in self._changes.items()
                    if change.counter > stable[change.replica_id]}
        removed = len(self._changes) - len(retained)
        self._base_state = dict(_plain(before_state))
        self._changes = retained
        self._audit.append(_freeze({"action": "compact", "removed": removed,
                                    "stable": dict(stable.items())}))
        _reject(self.materialized() != before_state, "COMPACTION-STATE", operation)
        return _freeze({"removed": removed, "retained": len(retained),
                        "stable": dict(stable.items()), "stateHash": _digest(before_state)})

    def verifyConvergence(self, peers: Iterable["Replica"]) -> Mapping[str, Any]:
        operation = "replica.verifyConvergence"
        peer_tuple = tuple(peers)
        _reject(any(not isinstance(peer, Replica) for peer in peer_tuple), "PEER", operation)
        hashes = {self.identity: _digest(self.materialized())}
        hashes.update({peer.identity: _digest(peer.materialized()) for peer in peer_tuple})
        return _freeze({"converged": len(set(hashes.values())) == 1,
                        "stateHashes": hashes, "pending": {self.identity: len(self._pending),
                        **{peer.identity: len(peer._pending) for peer in peer_tuple}}})

    def audit(self) -> Mapping[str, Any]:
        timeline = tuple(self._audit)
        return _freeze({"identity": self.identity, "timeline": timeline,
                        "checkpoint": self.checkpoint(), "gaps": tuple(self._pending),
                        "repairs": sum(item["action"] == "emit" and item.get("origin") == "repair"
                                       for item in timeline), "externalNetwork": False})


class _OpCrdt:
    def __init__(self, replica: str):
        self.replica = _name(replica, "REPLICA-ID", "crdt.new")
        self._ops: dict[str, Mapping[str, Any]] = {}
        self._version = VersionVector.new()

    def _record(self, kind: str, data: Mapping[str, Any]) -> Mapping[str, Any]:
        counter = self._version[self.replica] + 1
        context = dict(self._version.items())
        operation = _freeze({"id": f"{self.replica}:{counter}", "replica": self.replica,
                             "counter": counter, "kind": kind, "data": data,
                             "context": context})
        self._ops[operation["id"]] = operation
        self._version.observe(self.replica, counter)
        return operation

    def merge(self, other: "_OpCrdt") -> "_OpCrdt":
        operation = "crdt.merge"
        _reject(type(self) is not type(other) or self._policy_key() != other._policy_key(),
                "CRDT-TYPE", operation)
        staged = dict(self._ops)
        for identifier, item in other._ops.items():
            _reject(identifier in staged and staged[identifier] != item,
                    "CRDT-COLLISION", operation)
            staged[identifier] = item
        self._ops = staged
        for replica, counter in other._version.items():
            self._version.observe(replica, max(self._version[replica], counter))
        return self

    def deltaSince(self, version: VersionVector) -> tuple[Mapping[str, Any], ...]:
        _reject(not isinstance(version, VersionVector), "VECTOR", "crdt.deltaSince")
        return tuple(item for item in self._ordered()
                     if item["counter"] > version[item["replica"]])

    def applyDelta(self, delta: Iterable[Mapping[str, Any]]) -> "_OpCrdt":
        operation = "crdt.applyDelta"
        staged = dict(self._ops)
        staged_vector = self._version.copy()
        for item in tuple(delta):
            _reject(not isinstance(item, Mapping) or set(item) != {
                "id", "replica", "counter", "kind", "data", "context"}, "CRDT-DELTA", operation)
            identifier = item["id"]
            _reject(identifier in staged and staged[identifier] != item,
                    "CRDT-COLLISION", operation)
            staged[identifier] = _freeze(item)
            staged_vector.observe(item["replica"], max(staged_vector[item["replica"]], item["counter"]))
        self._ops, self._version = staged, staged_vector
        return self

    def version(self) -> VersionVector:
        return self._version.copy()

    def _ordered(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(sorted(self._ops.values(), key=lambda item: (item["counter"], item["replica"])))

    def _policy_key(self) -> Any:
        return None


class CrdtCounter(_OpCrdt):
    @staticmethod
    def new(replicaId: str) -> "CrdtCounter":
        return CrdtCounter(replicaId)

    def increment(self, amount: int) -> "CrdtCounter":
        _reject(isinstance(amount, bool) or not isinstance(amount, int) or amount == 0,
                "COUNTER-AMOUNT", "counter.increment")
        self._record("increment", {"amount": amount})
        return self

    def value(self) -> int:
        return sum(item["data"]["amount"] for item in self._ops.values())


def _policy(value: Any, allowed: frozenset[str], operation: str,
            default_replica: str) -> tuple[str, str]:
    if isinstance(value, str):
        mode, replica = value, default_replica
    elif isinstance(value, Mapping):
        mode, replica = value.get("mode"), value.get("replicaId", default_replica)
    else:
        raise OfflineError("CRDT-POLICY", operation)
    _reject(mode not in allowed, "CRDT-POLICY", operation)
    return mode, _name(replica, "REPLICA-ID", operation)


class CrdtSet(_OpCrdt):
    def __init__(self, mode: str, replica: str):
        super().__init__(replica)
        self.mode = mode

    @staticmethod
    def new(policy: str | Mapping[str, Any]) -> "CrdtSet":
        mode, replica = _policy(policy, frozenset(("add_wins", "remove_wins")),
                                "CrdtSet.new", "set-local")
        return CrdtSet(mode, replica)

    def _policy_key(self) -> Any:
        return self.mode

    def add(self, value: Any) -> "CrdtSet":
        self._record("add", {"value": value})
        return self

    def remove(self, value: Any) -> "CrdtSet":
        self._record("remove", {"value": value})
        return self

    def value(self) -> frozenset[Any]:
        result = set()
        adds = [item for item in self._ops.values() if item["kind"] == "add"]
        removals = [item for item in self._ops.values() if item["kind"] == "remove"]
        for add in adds:
            matching = [remove for remove in removals if remove["data"]["value"] == add["data"]["value"]]
            if self.mode == "add_wins":
                removed = any(remove["context"].get(add["replica"], 0) >= add["counter"]
                              for remove in matching)
            else:
                removed = any(add["context"].get(remove["replica"], 0) < remove["counter"]
                              for remove in matching)
            if not removed:
                result.add(add["data"]["value"])
        return frozenset(result)


def _maximal(operations: list[Mapping[str, Any]]) -> list[Mapping[str, Any]]:
    result = []
    for candidate in operations:
        dominated = any(other["context"].get(candidate["replica"], 0) >= candidate["counter"]
                        for other in operations if other["id"] != candidate["id"])
        if not dominated:
            result.append(candidate)
    return result


class CrdtRegister(_OpCrdt):
    def __init__(self, value: Any, mode: str, replica: str):
        super().__init__(replica)
        self.mode = mode
        self.assign(value)

    @staticmethod
    def new(value: Any, policy: str | Mapping[str, Any]) -> "CrdtRegister":
        mode, replica = _policy(policy, frozenset(("multi_value", "lww")),
                                "CrdtRegister.new", "register-local")
        return CrdtRegister(value, mode, replica)

    def _policy_key(self) -> Any:
        return self.mode

    def assign(self, value: Any, timestamp: tuple[int, int, str] = (0, 0, "logical")) -> "CrdtRegister":
        _reject(not isinstance(timestamp, tuple) or len(timestamp) != 3,
                "REGISTER-TIMESTAMP", "register.assign")
        self._record("assign", {"value": value, "timestamp": timestamp})
        return self

    def value(self) -> Any:
        assignments = list(self._ops.values())
        if self.mode == "lww":
            winner = max(assignments, key=lambda item: (tuple(item["data"]["timestamp"]), item["id"]))
            return winner["data"]["value"]
        return tuple(item["data"]["value"] for item in sorted(_maximal(assignments),
                                                               key=lambda item: item["id"]))


class CrdtMap(_OpCrdt):
    def __init__(self, mode: str, replica: str):
        super().__init__(replica)
        self.mode = mode

    @staticmethod
    def new(valuePolicy: str | Mapping[str, Any]) -> "CrdtMap":
        mode, replica = _policy(valuePolicy, frozenset(("multi_value", "lww")),
                                "CrdtMap.new", "map-local")
        return CrdtMap(mode, replica)

    def _policy_key(self) -> Any:
        return self.mode

    def put(self, key: str, value: Any,
            timestamp: tuple[int, int, str] = (0, 0, "logical")) -> "CrdtMap":
        key = _name(key, "MAP-KEY", "map.put")
        _reject(not isinstance(timestamp, tuple) or len(timestamp) != 3,
                "MAP-TIMESTAMP", "map.put")
        self._record("put", {"key": key, "value": value, "timestamp": timestamp})
        return self

    def remove(self, key: str) -> "CrdtMap":
        self._record("remove", {"key": _name(key, "MAP-KEY", "map.remove")})
        return self

    def value(self) -> Mapping[str, Any]:
        result: dict[str, Any] = {}
        keys = {item["data"]["key"] for item in self._ops.values()}
        for key in sorted(keys):
            puts = [item for item in self._ops.values()
                    if item["kind"] == "put" and item["data"]["key"] == key]
            removes = [item for item in self._ops.values()
                       if item["kind"] == "remove" and item["data"]["key"] == key]
            visible = [put for put in puts if not any(
                remove["context"].get(put["replica"], 0) >= put["counter"] for remove in removes)]
            if not visible:
                continue
            if self.mode == "lww":
                result[key] = max(visible, key=lambda item: (
                    tuple(item["data"]["timestamp"]), item["id"]))["data"]["value"]
            else:
                result[key] = tuple(item["data"]["value"] for item in sorted(
                    _maximal(visible), key=lambda item: item["id"]))
        return _freeze(result)


class CrdtList(_OpCrdt):
    @staticmethod
    def new(replicaId: str) -> "CrdtList":
        return CrdtList(replicaId)

    def insert(self, after: str | None, value: Any) -> str:
        operation = "list.insert"
        _reject(after is not None and after not in self._ops, "LIST-POSITION", operation)
        item = self._record("insert", {"after": after, "value": value})
        return item["id"]

    def delete(self, elementId: str) -> "CrdtList":
        operation = "list.delete"
        _reject(elementId not in self._ops or self._ops[elementId]["kind"] != "insert",
                "LIST-ELEMENT", operation)
        self._record("delete", {"element": elementId})
        return self

    def value(self) -> tuple[Any, ...]:
        inserts = {item["id"]: item for item in self._ops.values() if item["kind"] == "insert"}
        deleted = {item["data"]["element"] for item in self._ops.values()
                   if item["kind"] == "delete"}
        children: dict[str | None, list[str]] = {}
        for identifier, item in inserts.items():
            children.setdefault(item["data"]["after"], []).append(identifier)
        result: list[Any] = []
        def visit(parent: str | None) -> None:
            for identifier in sorted(children.get(parent, ())):
                if identifier not in deleted:
                    result.append(inserts[identifier]["data"]["value"])
                visit(identifier)
        visit(None)
        return tuple(result)


class SyncSession:
    def __init__(self, local: Replica, remote: Replica, policy: Mapping[str, Any]):
        self.local, self.remote = local, remote
        endpoint_changes = min(MAX_BATCH, local.max_changes, remote.max_changes)
        endpoint_bytes = min(MAX_BYTES, local.max_bytes, remote.max_bytes)
        self.max_changes = _integer(policy.get("maxChanges", endpoint_changes), "SYNC-LIMIT",
                                    "SyncSession.open", 1, endpoint_changes)
        self.max_bytes = _integer(policy.get("maxBytes", endpoint_bytes), "SYNC-LIMIT",
                                  "SyncSession.open", 1, endpoint_bytes)
        self.max_rounds = _integer(policy.get("maxRounds", 16), "SYNC-LIMIT",
                                   "SyncSession.open", 1, 64)
        self._paused = False
        self._pause_token: str | None = None
        self._fail_next = False
        self._counts = {"pulled": 0, "pushed": 0, "bytes": 0, "rounds": 0,
                        "retries": 0, "conflicts": 0}

    @staticmethod
    def open(local: Replica, remote: Replica, policy: Mapping[str, Any]) -> "SyncSession":
        operation = "SyncSession.open"
        _reject(not isinstance(local, Replica) or not isinstance(remote, Replica)
                or local is remote or local.identity == remote.identity,
                "SYNC-ENDPOINT", operation)
        _reject(not isinstance(policy, Mapping), "SYNC-POLICY", operation)
        return SyncSession(local, remote, policy)

    def exchangeManifest(self) -> Mapping[str, Any]:
        return _freeze({"protocol": "NEBO-SYNC-V1", "local": self.local.checkpoint(),
                        "remote": self.remote.checkpoint(), "limits": {
                            "changes": self.max_changes, "bytes": self.max_bytes,
                            "rounds": self.max_rounds}, "transport": "in_process"})

    def injectFailure(self) -> None:
        self._fail_next = True

    def _transfer(self, sender: Replica, receiver: Replica, direction: str,
                  limit: Mapping[str, int] | None) -> Mapping[str, Any]:
        operation = f"session.{direction}"
        _reject(self._paused, "SYNC-PAUSED", operation)
        limits = limit or {"changes": self.max_changes, "bytes": self.max_bytes}
        _reject(not isinstance(limits, Mapping), "SYNC-LIMIT", operation)
        changes = sender.changesSince(receiver.localVersion(), {
            "changes": min(_integer(limits.get("changes", self.max_changes), "SYNC-LIMIT",
                                    operation, 1, self.max_changes), self.max_changes),
            "bytes": min(_integer(limits.get("bytes", self.max_bytes), "SYNC-LIMIT",
                                  operation, 1, self.max_bytes), self.max_bytes)})
        size = sum(len(change.encoded_bytes()) for change in changes)
        if self._fail_next:
            self._fail_next = False
            self._counts["retries"] += 1
            raise OfflineError("INJECTED-TRANSFER-FAILURE", operation)
        result = receiver.apply(changes)
        sender._ack_peer(receiver.identity, receiver.localVersion())
        receiver._ack_peer(sender.identity, sender.localVersion())
        self._counts["pulled" if direction == "pull" else "pushed"] += len(changes)
        self._counts["bytes"] += size
        return _freeze({"changes": len(changes), "bytes": size,
                        "pending": result["pending"], "atomic": True})

    def pull(self, limit: Mapping[str, int] | None = None) -> Mapping[str, Any]:
        return self._transfer(self.remote, self.local, "pull", limit)

    def push(self, limit: Mapping[str, int] | None = None) -> Mapping[str, Any]:
        return self._transfer(self.local, self.remote, "push", limit)

    def syncBoth(self) -> Mapping[str, Any]:
        operation = "session.syncBoth"
        _reject(self._paused, "SYNC-PAUSED", operation)
        for round_number in range(1, self.max_rounds + 1):
            pushed = self.push()
            pulled = self.pull()
            self._counts["rounds"] += 1
            versions_equal = self.local.localVersion().compare(self.remote.localVersion()) == "equal"
            if (pushed["changes"] == pulled["changes"] == 0 or versions_equal) \
                    and not self.local.pending() and not self.remote.pending():
                return self.report()
        raise OfflineError("SYNC-ROUND-LIMIT", operation)

    def pause(self) -> str:
        _reject(self._paused, "SYNC-PAUSED", "session.pause")
        self._paused = True
        self._pause_token = _digest({"local": self.local.identity,
                                    "remote": self.remote.identity,
                                    "policy": (self.max_changes, self.max_bytes, self.max_rounds)})
        return self._pause_token

    def resume(self) -> bool:
        _reject(not self._paused or self._pause_token is None,
                "SYNC-NOT-PAUSED", "session.resume")
        expected = _digest({"local": self.local.identity, "remote": self.remote.identity,
                            "policy": (self.max_changes, self.max_bytes, self.max_rounds)})
        _reject(self._pause_token != expected, "SYNC-CHECKPOINT", "session.resume")
        self._paused = False
        return True

    def report(self) -> Mapping[str, Any]:
        states = (self.local.materialized(), self.remote.materialized())
        conflicts = max((sum(1 for value in state.values()
                             if isinstance(value, Mapping) and "conflict" in value)
                         for state in states), default=0)
        return _freeze({**self._counts, "conflicts": conflicts, "paused": self._paused,
                        "localPending": len(self.local.pending()),
                        "remotePending": len(self.remote.pending()),
                        "converged": self.local.verifyConvergence((self.remote,))["converged"],
                        "transport": "in_process", "externalNetwork": False})


class Conflict:
    def __init__(self, candidates: Mapping[str, Any], provenance: Mapping[str, Any]):
        operation = "Conflict"
        _reject(not isinstance(candidates, Mapping) or len(candidates) < 2
                or not isinstance(provenance, Mapping), "CONFLICT", operation)
        self._candidates = _freeze(candidates)
        self._provenance = _freeze(provenance)
        self._resolution: Any = None

    def values(self) -> Mapping[str, Any]:
        return self._candidates

    def resolve(self, strategy: str | Callable[[Mapping[str, Any]], Any]) -> Any:
        operation = "conflict.resolve"
        _reject(self._resolution is not None, "CONFLICT-RESOLVED", operation)
        if callable(strategy):
            resolved = strategy(self._candidates)
            strategy_name = getattr(strategy, "__name__", "callable")
        elif isinstance(strategy, str) and strategy.startswith("choose:"):
            identity = strategy.split(":", 1)[1]
            _reject(identity not in self._candidates, "CONFLICT-STRATEGY", operation)
            resolved, strategy_name = self._candidates[identity], strategy
        elif strategy == "set_union":
            resolved = frozenset(item for value in self._candidates.values() for item in value)
            strategy_name = strategy
        else:
            raise OfflineError("CONFLICT-STRATEGY", operation)
        self._resolution = _freeze({"value": resolved, "strategy": strategy_name,
                                    "parents": tuple(sorted(self._candidates))})
        return self._resolution

    def provenance(self) -> Mapping[str, Any]:
        return _freeze({"candidates": self._provenance, "resolution": self._resolution,
                        "visible": self._resolution is None})
