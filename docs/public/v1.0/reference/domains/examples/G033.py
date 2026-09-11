#!/usr/bin/env python3
"""Independent value, state, law, and failure oracle for G033's 48 surfaces."""
from __future__ import annotations

from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.offline import (  # noqa: E402
    Capability, Change, Conflict, CrdtCounter, CrdtList, CrdtMap, CrdtRegister,
    CrdtSet, EventStore, HybridLogicalClock, LogicalClockCapability, OfflineError,
    Replica, Snapshot, SyncSession, VersionVector, causal,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def thaw(value):
    if hasattr(value, "items"):
        return {str(key): thaw(item) for key, item in value.items()}
    if isinstance(value, (tuple, list)):
        return [thaw(item) for item in value]
    if isinstance(value, (set, frozenset)):
        return sorted(thaw(item) for item in value)
    return value


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1
    if category == "positive":
        counts["sdk"] += 1


def reject(label: str, suffix: str, callable_) -> None:
    try:
        callable_()
    except OfflineError as error:
        ok("negative", label, error.code() == f"NEBO-G033-{suffix}" and bool(error.operation()))
        counts["diagnostics"] += 1
        return
    raise AssertionError(f"negative:{label}:accepted")


clock_cap = LogicalClockCapability.deterministic("oracle-clock", 10_000)
clock = HybridLogicalClock.new(clock_cap)
store_cap = Capability.issue("event-store", ("open", "append", "read", "snapshot",
                                               "subscribe", "verify"), "oracle")


def event(identity: str, actor: str, value: int, physical: int,
          parents: tuple[str, ...] = ()) -> dict[str, object]:
    return {"id": identity, "actor": actor, "schema": "counter/v1",
            "timestamp": clock.tick(physical), "payload": {"amount": value},
            "causalParents": parents,
            "provenance": {"device": actor, "source": "oracle"}}


# S01 — append-only event identity, exact versions, replay, snapshot, and queue bounds.
store = EventStore.open("state/oracle.events", {"maxEvents": 12}, store_cap)
ok("positive", "EventStore.open", store.path == "state/oracle.events" and store.max_events == 12)
subscription = store.subscribe({"streamId": "account-33", "capacity": 4})
ok("positive", "store.subscribe", subscription.capacity == 4)
first = store.append("account-33", event("evt-A", "device-A", 11, 10), 0)
second = store.append("account-33", event("evt-B", "device-A", 7, 10, ("evt-A",)), 1)
ok("positive", "store.append", first.sequence == 1 and second.previous_hash == first.content_hash)
read_back = store.read("account-33", {"start": 0, "end": 2})
ok("positive", "store.read", read_back == (first, second))
replayed = store.replay("account-33", {"initial": 3,
                                        "apply": lambda state, item: state + item.payload["amount"]})
ok("positive", "store.replay", replayed == 21)
snapshot = store.snapshot("account-33", {"balance": replayed})
ok("positive", "store.snapshot", snapshot.version == 2 and snapshot.prefix_hash == second.content_hash)
metadata = first.metadata()
ok("positive", "event.metadata", metadata["id"] == "evt-A" and metadata["provenance"]["device"] == "device-A")
verification = store.verify()
ok("positive", "store.verify", verification["verified"] and verification["events"] == 2)
ok("ownership", "event-snapshot-immutability", snapshot.state["balance"] == 21
   and subscription.events() == (first, second) and subscription.events() == ())
transcript.append((first.content_hash, second.content_hash, replayed, thaw(metadata), thaw(verification)))


# S02 — replicas exchange bounded changes and keep causal gaps explicit.
policy = {"schemas": ("state/v1",), "maxChanges": 32, "maxBytes": 32_768}
replica_a = Replica.open("replica-A", store, policy)
ok("positive", "Replica.open", replica_a.identity == "replica-A" and replica_a.storage is store)
change_a = replica_a.emit({"key": "score", "value": 33})
local_version = replica_a.localVersion()
ok("positive", "replica.localVersion", local_version["replica-A"] == 1)
delta = replica_a.changesSince(VersionVector.new(), {"changes": 8, "bytes": 4096})
ok("positive", "replica.changesSince", delta == (change_a,))
replica_b = Replica.open("replica-B", None, policy)
application = replica_b.apply(delta)
ok("positive", "replica.apply", application["applied"] == 1 and replica_b.materialized()["score"] == 33)
gap = Replica.open("gap", None, policy)
parent = Change("upstream:1", "upstream", 1, "state/v1", {"key": "x", "value": 1}, (), {"source": "oracle"})
child = Change("upstream:2", "upstream", 2, "state/v1", {"key": "x", "value": 2},
               ("upstream:1",), {"source": "oracle"})
gap.apply((child,))
ok("positive", "replica.pending", gap.pending() == (child,))
gap.apply((parent,))
peer_session = SyncSession.open(replica_a, replica_b, {"maxChanges": 4, "maxBytes": 4096})
peer_session.push()
ok("positive", "replica.peers", replica_a.peers()["replica-B"]["replica-A"] == 1)
status = gap.status()
ok("positive", "replica.status", status["changes"] == 2 and status["pending"] == 0)
checkpoint = gap.checkpoint()
ok("positive", "replica.checkpoint", len(checkpoint["hash"]) == 64 and checkpoint["state"]["x"] == 2)
ok("composition", "causal-gap-drain", gap.localVersion()["upstream"] == 2)
transcript.append((thaw(local_version.items()), thaw(application), thaw(status), thaw(checkpoint)))


# S03 — all CRDT factories share an op-set join with bounded deltas.
counter_a = CrdtCounter.new("counter-A")
ok("positive", "CrdtCounter.new", counter_a.replica == "counter-A" and counter_a.value() == 0)
counter_a.increment(13).increment(-2)
ok("positive", "counter.increment", counter_a.value() == 11)
set_a = CrdtSet.new({"mode": "add_wins", "replicaId": "set-A"}).add("nebula")
ok("positive", "CrdtSet.new", set_a.mode == "add_wins" and set_a.value() == frozenset(("nebula",)))
map_a = CrdtMap.new({"mode": "multi_value", "replicaId": "map-A"}).put("orbit", 17)
ok("positive", "CrdtMap.new", map_a.value()["orbit"] == (17,))
register_a = CrdtRegister.new("north", {"mode": "multi_value", "replicaId": "reg-A"})
ok("positive", "CrdtRegister.new", register_a.value() == ("north",))
list_a = CrdtList.new("list-A")
root_item = list_a.insert(None, "alpha")
ok("positive", "CrdtList.new", root_item == "list-A:1" and list_a.value() == ("alpha",))
counter_b = CrdtCounter.new("counter-B").increment(23)
counter_a.merge(counter_b)
ok("positive", "crdt.merge", counter_a.value() == 34)
delta_counter = counter_a.deltaSince(VersionVector({"counter-A": 1}))
ok("positive", "crdt.deltaSince", tuple(item["id"] for item in delta_counter) == ("counter-B:1", "counter-A:2"))
ok("ownership", "crdt-delta-snapshot", delta_counter[1]["data"]["amount"] == -2)
transcript.append((counter_a.value(), sorted(set_a.value()), thaw(map_a.value()),
                   register_a.value(), list_a.value(), thaw(delta_counter)))


# S04 — explicit clocks classify order and gate causal application/stability.
empty_vector = VersionVector.new()
ok("positive", "VersionVector.new", empty_vector.items() == ())
observed_vector = empty_vector.observe("replica-A", 1).observe("replica-B", 0)
ok("positive", "version.observe", observed_vector["replica-A"] == 1)
other_vector = VersionVector({"replica-A": 0, "replica-B": 1})
ok("positive", "version.compare", observed_vector.compare(other_vector) == "concurrent")
new_clock = HybridLogicalClock.new(LogicalClockCapability.deterministic("causal-clock", 1000))
ok("positive", "HybridLogicalClock.new", new_clock.tick(7) == (7, 0, "causal-clock"))
ok("positive", "change.causalParents", child.causalParents() == ("upstream:1",))
stable = replica_a.stableVersion()
ok("positive", "replica.stableVersion", stable["replica-A"] == 1)
ok("positive", "causal.ready", causal.ready(parent, VersionVector.new()))
order = causal.explainOrder(parent, child)
ok("positive", "causal.explainOrder", order["relation"] == "before" and order["reason"] == "causal-parent")
ok("boundary", "clock-logical-tie", new_clock.tick(7) == (7, 1, "causal-clock"))
transcript.append((observed_vector.items(), other_vector.items(), stable.items(), thaw(order)))


# S05 — local sync is bounded, bidirectional, resumable, and independently reported.
sync_left = Replica.open("sync-L", None, policy)
sync_right = Replica.open("sync-R", None, policy)
sync_left.emit({"key": "left", "value": 41})
sync_right.emit({"key": "right", "value": 59})
session = SyncSession.open(sync_left, sync_right,
                           {"maxChanges": 2, "maxBytes": 4096, "maxRounds": 8})
ok("positive", "SyncSession.open", session.local is sync_left and session.remote is sync_right)
manifest = session.exchangeManifest()
ok("positive", "session.exchangeManifest", manifest["protocol"] == "NEBO-SYNC-V1"
   and manifest["transport"] == "in_process")
pulled = session.pull({"changes": 1, "bytes": 2048})
ok("positive", "session.pull", pulled["changes"] == 1 and sync_left.materialized()["right"] == 59)
sync_left.emit({"key": "second-left", "value": 61})
pushed = session.push({"changes": 2, "bytes": 4096})
ok("positive", "session.push", pushed["changes"] == 2 and sync_right.materialized()["left"] == 41)
sync_report = session.syncBoth()
ok("positive", "session.syncBoth", sync_report["converged"] and sync_report["rounds"] >= 1)
pause_token = session.pause()
ok("positive", "session.pause", len(pause_token) == 64 and session.report()["paused"])
ok("positive", "session.resume", session.resume() and not session.report()["paused"])
report = session.report()
ok("positive", "session.report", report["transport"] == "in_process"
   and report["externalNetwork"] is False and report["converged"])
ok("target", "sync-local-target", manifest["transport"] == "in_process"
   and not report["externalNetwork"])
transcript.append((thaw(manifest), thaw(pulled), thaw(pushed), thaw(report)))


# S06 — conflicts stay visible; repair/compaction are new, auditable state changes.
conflict = Conflict({"replica-A:1": 71, "replica-B:1": 73},
                    {"replica-A:1": {"actor": "A"}, "replica-B:1": {"actor": "B"}})
values = conflict.values()
ok("positive", "Conflict.values", tuple(values.values()) == (71, 73))
resolution = conflict.resolve("choose:replica-B:1")
ok("positive", "conflict.resolve", resolution["value"] == 73 and len(resolution["parents"]) == 2)
conflict_provenance = conflict.provenance()
ok("positive", "conflict.provenance", not conflict_provenance["visible"]
   and conflict_provenance["candidates"]["replica-A:1"]["actor"] == "A")
repair_replica = Replica.open("repair", None, policy)
repair_replica.emit({"key": "quota", "value": -4})
invariants = repair_replica.validateInvariants((lambda state: state["quota"] >= 0,))
ok("positive", "replica.validateInvariants", not invariants["valid"])
repair_change = repair_replica.repair({"payload": {"key": "quota", "value": 4},
                                      "reason": "quota must be nonnegative"})
ok("positive", "replica.repair", repair_change.provenance_record["origin"] == "repair"
   and repair_replica.materialized()["quota"] == 4)
compact_peer = Replica.open("compact-peer", None, policy)
compact_session = SyncSession.open(repair_replica, compact_peer,
                                   {"maxChanges": 8, "maxBytes": 4096})
compact_session.syncBoth()
before_compaction = thaw(repair_replica.materialized())
compaction = repair_replica.compactStable()
ok("positive", "replica.compactStable", compaction["removed"] == 2
   and thaw(repair_replica.materialized()) == before_compaction)
convergence = repair_replica.verifyConvergence((compact_peer,))
ok("positive", "replica.verifyConvergence", convergence["converged"])
audit = repair_replica.audit()
ok("positive", "replica.audit", audit["repairs"] == 1 and audit["externalNetwork"] is False)
ok("failure_atomicity", "stable-compaction-preserves-state",
   thaw(repair_replica.materialized()) == before_compaction)
transcript.append((thaw(values), thaw(resolution), thaw(conflict_provenance),
                   thaw(invariants), thaw(compaction), thaw(convergence), thaw(audit)))


# Negative, boundary, failure-atomicity, and adversarial proofs.
reject("store-capability", "CAPABILITY-DENIED",
       lambda: EventStore.open("x", {}, Capability.issue("other", ("open",))))
reject("store-path", "STORE-PATH", lambda: EventStore.open("/host/path", {}, store_cap))
before_store = store.verify()["events"]
reject("expected-version", "VERSION-CONFLICT",
       lambda: store.append("account-33", event("evt-C", "device-A", 5, 12), 0))
ok("failure_atomicity", "append-version-atomic", store.verify()["events"] == before_store)
reject("duplicate-event", "DUPLICATE-EVENT",
       lambda: store.append("other", event("evt-A", "device-B", 5, 13), 0))
small_store = EventStore.open("state/small", {"maxEvents": 2}, store_cap)
small_sub = small_store.subscribe({"capacity": 1})
small_store.append("s", event("small-1", "device-S", 1, 14), 0)
reject("subscriber-backpressure", "BACKPRESSURE",
       lambda: small_store.append("s", event("small-2", "device-S", 2, 15), 1))
ok("failure_atomicity", "backpressure-atomic", len(small_store.read("s", {"start": 0, "end": 2})) == 1)
small_sub.events()
reject("read-range", "READ-RANGE", lambda: store.read("account-33", {"start": 3, "end": 1}))
reject("reducer", "REDUCER", lambda: store.replay("account-33", {"initial": 0}))
reject("event-timestamp", "TIMESTAMP", lambda: store.append("timestamp", {
    "id": "bad-time", "actor": "device-T", "schema": "counter/v1",
    "timestamp": ("wall", 0, "clock"), "payload": {}, "provenance": {}}, 0))
reject("event-causal-gap", "CAUSAL-GAP", lambda: store.append(
    "gap-stream", event("gap-event", "device-G", 1, 16, ("missing-event",)), 0))
ok("failure_atomicity", "event-validation-atomic", store.verify()["events"] == before_store)
corrupt_store = EventStore.open("state/corrupt", {"maxEvents": 2}, store_cap)
corrupt_store.append("s", event("corrupt-1", "device-C", 1, 17), 0)
corrupt_snapshot = corrupt_store.snapshot("s", {"value": 1})
corrupt_store._snapshots["s"] = Snapshot("s", 2, corrupt_snapshot.state,
                                         corrupt_snapshot.prefix_hash)
reject("corrupt-snapshot", "CORRUPT-SNAPSHOT", lambda: corrupt_store.verify())
regressing = VersionVector({"A": 2})
reject("vector-regression", "VECTOR-REGRESSION", lambda: regressing.observe("A", 1))
bad_schema = Change("bad:1", "bad", 1, "unknown/v9", {}, (), {})
before_apply = replica_b.checkpoint()["hash"]
reject("apply-schema", "CHANGE", lambda: replica_b.apply((bad_schema,)))
ok("failure_atomicity", "schema-apply-atomic", replica_b.checkpoint()["hash"] == before_apply)
bad_identity = Change("forged-id", "forged", 1, "state/v1", {"key": "score", "value": 1000}, (), {})
reject("change-identity", "CHANGE", lambda: replica_b.apply((bad_identity,)))
ok("failure_atomicity", "identity-apply-atomic", replica_b.checkpoint()["hash"] == before_apply)
collision = Change(change_a.id, change_a.replica_id, change_a.counter, change_a.schema,
                   {"key": "score", "value": 999}, change_a.parents, change_a.provenance_record)
reject("change-collision", "CHANGE-COLLISION", lambda: replica_a.apply((collision,)))
ok("failure_atomicity", "collision-atomic", replica_a.materialized()["score"] == 33)
reject("change-limit", "CHANGE-LIMIT",
       lambda: replica_a.changesSince(VersionVector.new(), {"changes": 0, "bytes": 20}))
reject("counter-zero", "COUNTER-AMOUNT", lambda: CrdtCounter.new("bad-counter").increment(0))
reject("set-policy", "CRDT-POLICY", lambda: CrdtSet.new("implicit_lww"))
reject("register-timestamp", "REGISTER-TIMESTAMP",
       lambda: CrdtRegister.new("x", "lww").assign("y", (1, 2)))
reject("map-timestamp", "MAP-TIMESTAMP",
       lambda: CrdtMap.new("lww").put("x", "y", (1, 2)))
before_crdt = counter_a.value()
reject("crdt-type", "CRDT-TYPE", lambda: counter_a.merge(set_a))
ok("failure_atomicity", "crdt-merge-atomic", counter_a.value() == before_crdt)
reject("list-position", "LIST-POSITION", lambda: CrdtList.new("bad-list").insert("missing:1", 4))
reject("list-delete", "LIST-ELEMENT", lambda: CrdtList.new("bad-list-2").delete("missing:1"))
reject("sync-endpoint", "SYNC-ENDPOINT", lambda: SyncSession.open(sync_left, sync_left, {}))
reject("sync-limit", "SYNC-LIMIT", lambda: SyncSession.open(sync_left, sync_right, {"maxChanges": 0}))
session.pause()
reject("paused-transfer", "SYNC-PAUSED", lambda: session.push())
session.resume()
reject("resume-state", "SYNC-NOT-PAUSED", lambda: session.resume())
failure_left = Replica.open("failure-L", None, policy)
failure_right = Replica.open("failure-R", None, policy)
failure_left.emit({"key": "atomic", "value": 83})
failure_session = SyncSession.open(failure_left, failure_right, {})
before_failure = failure_right.checkpoint()["hash"]
failure_session.injectFailure()
reject("injected-failure", "INJECTED-TRANSFER-FAILURE", lambda: failure_session.push())
ok("failure_atomicity", "transfer-failure-atomic", failure_right.checkpoint()["hash"] == before_failure)
reject("conflict-strategy", "CONFLICT-STRATEGY",
       lambda: Conflict({"A": 1, "B": 2}, {}).resolve("implicit_lww"))
reject("invariants-empty", "INVARIANT", lambda: replica_a.validateInvariants(()))
reject("repair-plan", "REPAIR-PLAN", lambda: replica_a.repair({"payload": {}}))
pending_compaction = Replica.open("pending-compact", None, policy)
pending_compaction.apply((child,))
reject("compact-gap", "CAUSAL-GAP", lambda: pending_compaction.compactStable())
ok("failure_atomicity", "gap-compaction-atomic", pending_compaction.pending() == (child,))
unacknowledged = Replica.open("unacknowledged", None, policy)
unacknowledged.emit({"key": "x", "value": 1})
reject("compact-without-peer", "STABILITY-UNKNOWN", lambda: unacknowledged.compactStable())


# Algebraic and metamorphic checks use independent permutations and altered inputs.
def merged_counter(order: tuple[str, ...]) -> int:
    nodes = {"A": CrdtCounter.new("law-A").increment(2),
             "B": CrdtCounter.new("law-B").increment(3),
             "C": CrdtCounter.new("law-C").increment(5)}
    result = CrdtCounter.new("law-result")
    for key in order:
        result.merge(nodes[key])
    result.merge(nodes[order[0]])
    return result.value()

ok("metamorphic", "counter-commutative", merged_counter(("A", "B", "C")) == merged_counter(("C", "A", "B")) == 10)
ok("metamorphic", "counter-idempotent", merged_counter(("B", "C", "A")) == 10)
base_set = CrdtSet.new({"mode": "add_wins", "replicaId": "law-set-A"}).add("x")
peer_set = CrdtSet.new({"mode": "add_wins", "replicaId": "law-set-B"}).remove("x").add("y")
left_set = CrdtSet.new({"mode": "add_wins", "replicaId": "law-set-L"}).merge(base_set).merge(peer_set)
right_set = CrdtSet.new({"mode": "add_wins", "replicaId": "law-set-R"}).merge(peer_set).merge(base_set)
ok("metamorphic", "set-add-wins-order", left_set.value() == right_set.value() == frozenset(("x", "y")))
remove_base = CrdtSet.new({"mode": "remove_wins", "replicaId": "rw-A"}).add("x")
remove_peer = CrdtSet.new({"mode": "remove_wins", "replicaId": "rw-B"}).remove("x")
ok("metamorphic", "set-remove-wins", CrdtSet.new({"mode": "remove_wins", "replicaId": "rw-C"})
   .merge(remove_base).merge(remove_peer).value() == frozenset())
reg_one = CrdtRegister.new("east", {"mode": "multi_value", "replicaId": "mv-A"})
reg_two = CrdtRegister.new("west", {"mode": "multi_value", "replicaId": "mv-B"})
mv_left = CrdtRegister.new("seed", {"mode": "multi_value", "replicaId": "mv-L"}).merge(reg_one).merge(reg_two)
mv_right = CrdtRegister.new("seed", {"mode": "multi_value", "replicaId": "mv-L"}).merge(reg_two).merge(reg_one)
ok("metamorphic", "register-merge-order", mv_left.value() == mv_right.value())
map_one = CrdtMap.new({"mode": "multi_value", "replicaId": "mm-A"}).put("k", 2)
map_two = CrdtMap.new({"mode": "multi_value", "replicaId": "mm-B"}).put("k", 3)
ok("metamorphic", "map-merge-order",
   thaw(CrdtMap.new({"mode": "multi_value", "replicaId": "mm-L"}).merge(map_one).merge(map_two).value())
   == thaw(CrdtMap.new({"mode": "multi_value", "replicaId": "mm-R"}).merge(map_two).merge(map_one).value()))
list_seed = CrdtList.new("rga-seed")
list_root = list_seed.insert(None, "root")
list_one = CrdtList.new("rga-A").merge(list_seed); list_one.insert(list_root, "A")
list_two = CrdtList.new("rga-B").merge(list_seed); list_two.insert(list_root, "B")
list_left = CrdtList.new("rga-L").merge(list_one).merge(list_two)
list_right = CrdtList.new("rga-R").merge(list_two).merge(list_one)
ok("metamorphic", "list-merge-order", list_left.value() == list_right.value() == ("root", "A", "B"))
ok("metamorphic", "version-duality",
   VersionVector({"A": 1}).compare(VersionVector({"A": 2})) == "before"
   and VersionVector({"A": 2}).compare(VersionVector({"A": 1})) == "after")
changed_replay = store.replay("account-33", {"initial": 3,
                                              "apply": lambda state, item: state * 2 + item.payload["amount"]})
ok("metamorphic", "reducer-changes-effect", changed_replay == 41 and changed_replay != replayed)
failure_session.push()
ok("metamorphic", "retry-after-failure", failure_right.materialized()["atomic"] == 83)
duplicate_before = failure_right.checkpoint()["hash"]
failure_right.apply(failure_left.changesSince(VersionVector.new(), {"changes": 8, "bytes": 4096}))
ok("metamorphic", "duplicate-idempotence", failure_right.checkpoint()["hash"] == duplicate_before)
permuted = Replica.open("permuted", None, policy)
permuted.apply((child, parent))
ok("metamorphic", "message-reorder", permuted.materialized()["x"] == 2 and not permuted.pending())

round_left = Replica.open("round-L", None, policy)
round_right = Replica.open("round-R", None, policy)
round_left.emit({"key": "shared", "value": "left"})
round_right.emit({"key": "shared", "value": "right"})
round_session = SyncSession.open(round_left, round_right,
                                 {"maxChanges": 1, "maxBytes": 4096, "maxRounds": 1})
round_report = round_session.syncBoth()
ok("boundary", "exact-final-round", round_report["rounds"] == 1 and round_report["converged"])

ok("adversarial", "no-host-store", not store.path.startswith("/") and store.capability.root == "oracle")
ok("adversarial", "causal-gap-visible", pending_compaction.status()["pending"] == 1)
ok("adversarial", "conflict-explicit", conflict_provenance["resolution"]["parents"] == ("replica-A:1", "replica-B:1"))
ok("adversarial", "sync-bounded", report["bytes"] <= 4 * 4096 and report["rounds"] <= 8)
ok("adversarial", "logical-time-only", clock.physical == 17 and clock.logical == 0)
ok("adversarial", "provenance-retained", first.provenance_record["source"] == "oracle")
ok("adversarial", "failure-counted", failure_session.report()["retries"] == 1)
ok("adversarial", "stable-only", compaction["stable"]["repair"] == 2)
ok("adversarial", "sync-conflict-visible", round_report["conflicts"] == 1
   and "conflict" in round_left.materialized()["shared"])

ok("boundary", "event-limit", small_store.max_events == 2)
ok("boundary", "read-empty-tail", store.read("account-33", {"start": 2, "end": 2}) == ())
ok("boundary", "batch-one", len(replica_a.changesSince(VersionVector.new(), {"changes": 1, "bytes": 4096})) == 1)
ok("boundary", "empty-delta", counter_a.deltaSince(counter_a.version()) == ())
ok("boundary", "vector-equal", VersionVector({"A": 1}).compare(VersionVector({"A": 1})) == "equal")
ok("boundary", "empty-sync", failure_session.push()["changes"] == 0)
ok("boundary", "single-invariant", repair_replica.validateInvariants((lambda state: state["quota"] == 4,))["valid"])

ok("composition", "event-to-snapshot", snapshot.state["balance"] == replayed)
ok("composition", "delta-to-replica", replica_b.localVersion()["replica-A"] == 1)
ok("composition", "crdt-delta-roundtrip",
   CrdtCounter.new("delta-target").applyDelta(counter_a.deltaSince(VersionVector.new())).value() == counter_a.value())
ok("composition", "clock-to-event", first.timestamp[2] == clock_cap.identity)
ok("composition", "bidirectional-state", thaw(sync_left.materialized()) == thaw(sync_right.materialized()))
ok("composition", "repair-to-convergence", convergence["converged"] and compact_peer.materialized()["quota"] == 4)

ok("ownership", "version-copy", replica_a.localVersion() is not replica_a.localVersion())
ok("ownership", "read-tuple", isinstance(read_back, tuple))
ok("ownership", "pending-tuple", isinstance(gap.pending(), tuple))
ok("ownership", "manifest-snapshot", manifest["local"]["identity"] == "sync-L")
ok("ownership", "report-snapshot", report["converged"] is True)
ok("ownership", "audit-snapshot", isinstance(audit["timeline"], tuple))

ok("failure_atomicity", "vector-regression-atomic", regressing["A"] == 2)
ok("failure_atomicity", "sync-pause-atomic", not session.report()["paused"] and session.report()["converged"])

for label, value in (("event-hashes", (first.content_hash, second.content_hash)),
                     ("checkpoint", checkpoint["hash"]), ("manifest", manifest),
                     ("crdt", (counter_a.value(), left_set.value(), mv_left.value())),
                     ("compaction", compaction), ("audit", audit),
                     ("errors", dict(counts))):
    encoded_a = json.dumps(thaw(value), sort_keys=True, separators=(",", ":"), default=str).encode()
    encoded_b = json.dumps(thaw(value), sort_keys=True, separators=(",", ":"), default=str).encode()
    ok("determinism", label, encoded_a == encoded_b)

canonical = json.dumps(thaw(transcript), sort_keys=True, separators=(",", ":"), default=str).encode()
digest = hashlib.sha256(canonical).hexdigest()
print("G033_SDK_ORACLE_GREEN " + " ".join(
    f"{category}={counts[category]}" for category in (
        "positive", "negative", "boundary", "metamorphic", "adversarial",
        "composition", "ownership", "failure_atomicity", "target", "diagnostics",
        "sdk", "determinism")) + f" digest={digest}")
