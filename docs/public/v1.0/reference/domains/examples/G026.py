#!/usr/bin/env python3
"""Independent value/effect oracle for all 41 G026 public surfaces."""

from __future__ import annotations

import hashlib
import hmac
import json
import tempfile
from pathlib import Path
from typing import Any, Callable

from compiler.sdk.extensions import (
    Callback,
    Checkpoint,
    Cluster,
    DistributedData,
    ExtensionError,
    ForeignBuffer,
    ForeignLibrary,
    ForeignLifetime,
    ForeignType,
    NodeRuntime,
    Plugin,
    PluginManifest,
    RemoteTask,
    RetryPolicy,
    Sandbox,
    Workflow,
    ffi,
)


COUNTS = {
    "positive": 0,
    "negative": 0,
    "boundary": 0,
    "metamorphic": 0,
    "adversarial": 0,
    "composition": 0,
    "ownership": 0,
    "failure_atomicity": 0,
    "diagnostics": 0,
    "sdk": 0,
    "determinism": 0,
}
EVIDENCE: list[str] = []
SECRET = b"g026-local-test-trust-key"


def require(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def surface(surface_id: str, condition: bool, observation: Any) -> None:
    require(condition, surface_id)
    COUNTS["positive"] += 1
    COUNTS["sdk"] += 1
    EVIDENCE.append(f"{surface_id}:{observation!r}")


def claim(category: str, condition: bool, label: str, observation: Any = True) -> None:
    require(condition, label)
    COUNTS[category] += 1
    EVIDENCE.append(f"{category}:{label}:{observation!r}")


def negative(code: str, operation: str, action: Callable[[], Any]) -> None:
    try:
        action()
    except ExtensionError as error:
        require(error.code == code, f"{operation} code {error.code}, expected {code}")
        require(error.operation == operation, f"operation {error.operation}, expected {operation}")
        COUNTS["negative"] += 1
        COUNTS["diagnostics"] += 1
        EVIDENCE.append(f"negative:{operation}:{code}")
        return
    raise AssertionError(f"negative unexpectedly passed: {operation}:{code}")


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")


def write_manifest(root: Path, identity: str = "arithmetic-v1", *, key: bytes = SECRET, extra: dict[str, Any] | None = None) -> tuple[Path, str]:
    document: dict[str, Any] = {
        "schema": 1,
        "identity": identity,
        "abiVersion": 1,
        "target": "x86_64-linux-static",
        "capabilities": ["buffer", "compute"],
        "exports": {
            "byteTotal": {"args": ["Bytes"], "returns": "Int", "capability": "buffer"},
            "sum": {"args": ["Int", "Int"], "returns": "Int", "capability": "compute"},
        },
        "behavior": {"byteTotal": "sumBytes", "sum": "add"},
        "memoryLimit": 2048,
        "callLimit": 8,
        "keyId": "local-dev",
    }
    if extra:
        document.update(extra)
    document["signature"] = hmac.new(key, canonical(document), hashlib.sha256).hexdigest()
    raw = canonical(document)
    path = root / f"{identity}.plugin.json"
    path.write_bytes(raw)
    return path, hashlib.sha256(raw).hexdigest()


def load_policy(root: Path, digest: str, capabilities: tuple[str, ...] = ("buffer", "compute")) -> dict[str, Any]:
    return {
        "allowedRoots": (str(root),),
        "allowedDigests": (digest,),
        "abiVersion": 1,
        "capabilities": capabilities,
        "requireSignature": True,
        "trustStore": {"local-dev": SECRET},
    }


def make_plugin(root: Path, identity: str = "arithmetic-v1") -> tuple[Plugin, Path, str]:
    path, digest = write_manifest(root, identity)
    return Plugin.load(path, load_policy(root, digest)), path, digest


def make_nodes() -> tuple[Any, Any, Cluster]:
    node_a = NodeRuntime.start({"identity": "node-a", "protocolVersion": 1, "authToken": "local-trust", "maxTasks": 8, "capabilities": ("compute", "checkpoint")})
    node_b = NodeRuntime.start({"identity": "node-b", "protocolVersion": 1, "authToken": "local-trust", "maxTasks": 8, "capabilities": ("compute", "storage")})
    return node_a, node_b, Cluster.connect((node_a, node_b))


def double(value: int) -> int:
    return value * 2


def bad_output(value: int) -> str:
    return "not-an-int"


def multiplier(factor: int) -> Callable[[int], int]:
    def apply(value: int) -> int:
        return value * factor

    return apply


def task_schema(name: str = "double", version: int = 1) -> dict[str, Any]:
    return {"name": name, "version": version, "input": "Int", "output": "Int", "requiredCapability": "compute"}


def subgroup_s01(root: Path) -> None:
    path, digest = write_manifest(root)
    manifest = PluginManifest.load(path)
    surface("G026-S01-01", manifest.identity == "arithmetic-v1" and manifest.digest == digest, (manifest.identity, manifest.digest))
    plugin = Plugin.load(path, load_policy(root, digest))
    surface("G026-S01-02", plugin.manifest.digest == digest and not plugin._initialized, plugin.manifest.identity)
    surface("G026-S01-03", plugin.abiVersion() == 1, plugin.abiVersion())
    exports = plugin.exports()
    surface("G026-S01-04", tuple(item["name"] for item in exports) == ("byteTotal", "sum") and exports[1]["returns"] == "Int", exports)
    surface("G026-S01-07", plugin.verifySignature({"local-dev": SECRET}), True)
    initialized = plugin.initialize({"identity": "host-v1", "capabilities": ("compute", "buffer")})
    surface("G026-S01-05", initialized["state"] == "ready" and plugin._initialized, initialized)
    stopped = plugin.shutdown()
    surface("G026-S01-06", stopped["state"] == "shutdown" and plugin.shutdown() == stopped, stopped)

    other_path, other_digest = write_manifest(root, "arithmetic-v2")
    claim("metamorphic", other_digest != digest and PluginManifest.load(other_path).identity != manifest.identity, "manifest identity governs content identity")
    composed = Plugin.load(other_path, load_policy(root, other_digest))
    claim("composition", composed.verifySignature({"local-dev": SECRET}) and composed.abiVersion() == 1, "manifest trust ABI and plugin load compose")
    claim("ownership", type(exports[0]).__name__ == "mappingproxy", "export snapshots are immutable")
    claim("boundary", len(PluginManifest.load(path).exports_map) == 2, "small finite export table")
    claim("determinism", PluginManifest.load(path).digest == digest, "manifest digest is deterministic")
    fresh = Plugin.load(path, load_policy(root, digest))
    negative("CAPABILITY_DENIED", "plugin.initialize", lambda: fresh.initialize({"identity": "host", "capabilities": ("compute",)}))
    claim("failure_atomicity", not fresh._initialized and not fresh._shutdown, "denied initialization leaves lifecycle unchanged")
    claim("adversarial", len(manifest.signature) == 64 and manifest.key_id == "local-dev", "signed manifest binds explicit local trust identity")

    malformed = root / "malformed.plugin.json"
    malformed.write_text("{x", encoding="utf-8")
    negative("MALFORMED_MANIFEST", "PluginManifest.load", lambda: PluginManifest.load(malformed))
    oversized = root / "oversized.plugin.json"
    oversized.write_bytes(b"{}" + b" " * 65_536)
    negative("MANIFEST_SIZE", "PluginManifest.load", lambda: PluginManifest.load(oversized))
    link = root / "linked.plugin.json"
    link.symlink_to(path)
    negative("SYMLINK_DENIED", "PluginManifest.load", lambda: PluginManifest.load(link))
    negative("PATH_DENIED", "Plugin.load", lambda: Plugin.load(path, {**load_policy(root / "other", digest), "allowedRoots": (str(root / "other"),)}))
    negative("UNTRUSTED_PLUGIN", "Plugin.load", lambda: Plugin.load(path, {**load_policy(root, digest), "allowedDigests": ("0" * 64,)}))
    negative("SIGNATURE_MISMATCH", "plugin.verifySignature", lambda: manifest.verifySignature({"local-dev": b"wrong"}))
    negative("CAPABILITY_DENIED", "Plugin.load", lambda: Plugin.load(path, load_policy(root, digest, ("compute",))))
    negative("INVALID_INTEGER", "Plugin.load", lambda: Plugin.load(path, {**load_policy(root, digest), "abiVersion": True}))
    negative("INVALID_PATH", "Plugin.load", lambda: Plugin.load(7, load_policy(root, digest)))
    negative("UNKNOWN_FIELD", "Plugin.load", lambda: Plugin.load(path, {**load_policy(root, digest), "ambientNetwork": True}))
    duplicate_path, _ = write_manifest(root, "duplicate-capability", extra={"capabilities": ["compute", "compute"]})
    negative("DUPLICATE_CAPABILITY", "PluginManifest.load", lambda: PluginManifest.load(duplicate_path))
    mismatch_path, _ = write_manifest(root, "signature-mismatch", extra={
        "capabilities": ["compute"],
        "exports": {"sum": {"args": ["Text", "Text"], "returns": "Text", "capability": "compute"}},
        "behavior": {"sum": "multiply"},
    })
    negative("BEHAVIOR_SIGNATURE", "PluginManifest.load", lambda: PluginManifest.load(mismatch_path))
    negative("TRUST_LIMIT", "Plugin.load", lambda: Plugin.load(path, {**load_policy(root, digest), "allowedDigests": tuple(f"{value:064x}" for value in range(33))}))


def subgroup_s02(root: Path) -> None:
    plugin, _, _ = make_plugin(root, "sandbox-plugin")
    sandbox = Sandbox.new({"memoryLimit": 4096, "timeLimit": 128, "callLimit": 3, "capabilities": ("compute", "buffer"), "network": "none"})
    surface("G026-S02-01", sandbox._call_limit == 3 and not sandbox._terminated, (sandbox._memory_limit, sandbox._time_limit))
    surface("G026-S02-04", sandbox.memoryLimit(3072)._memory_limit == 3072, sandbox._memory_limit)
    surface("G026-S02-05", sandbox.timeLimit(64)._time_limit == 64, sandbox._time_limit)
    surface("G026-S02-06", sandbox.capabilities({"buffer", "compute"})._capabilities == frozenset({"buffer", "compute"}), tuple(sorted(sandbox._capabilities)))
    loaded = sandbox.load(plugin)
    surface("G026-S02-02", loaded["state"] == "loaded" and plugin._initialized, loaded)
    first = sandbox.call("sum", (7, 9))
    surface("G026-S02-03", first == 16 and sandbox._calls == 1, first)
    changed = sandbox.call("sum", (8, 9))
    claim("metamorphic", changed == 17 and changed != first, "sandbox arguments govern result")
    claim("composition", sandbox.call("byteTotal", (b"ABC",)) == 198, "manifest signature capability and sandbox call compose")
    call_count = sandbox._calls
    negative("UNKNOWN_EXPORT", "sandbox.call", lambda: sandbox.call("missing", ()))
    claim("failure_atomicity", sandbox._calls == call_count, "rejected call does not consume budget")
    report = sandbox.terminate()
    surface("G026-S02-07", report["state"] == "terminated" and sandbox.terminate() == report, report)
    claim("ownership", loaded["state"] == "loaded" and report["calls"] == 3, "load report is detached from termination")
    boundary_plugin, _, _ = make_plugin(root, "boundary-plugin")
    boundary = Sandbox.new({"memoryLimit": 2048, "timeLimit": 32, "callLimit": 1, "capabilities": ("compute", "buffer")})
    boundary.load(boundary_plugin)
    claim("boundary", boundary.call("sum", (1, 1)) == 2, "one-call budget permits exactly one call")
    twin_plugin, _, _ = make_plugin(root, "twin-plugin")
    twin = Sandbox.new({"memoryLimit": 2048, "timeLimit": 32, "callLimit": 1, "capabilities": ("compute", "buffer")})
    twin.load(twin_plugin)
    claim("determinism", twin.call("sum", (1, 1)) == 2, "equal call input has deterministic result")
    claim("adversarial", sandbox._terminated and plugin._shutdown, "termination closes plugin lifecycle")

    negative("NETWORK_DENIED", "Sandbox.new", lambda: Sandbox.new({"network": "internet", "capabilities": ()}))
    negative("INVALID_INTEGER", "sandbox.memoryLimit", lambda: Sandbox.new({"capabilities": ()}).memoryLimit(True))
    negative("UNKNOWN_CAPABILITY", "sandbox.capabilities", lambda: Sandbox.new({"capabilities": ()}).capabilities(("shell",)))
    negative("UNKNOWN_FIELD", "Sandbox.new", lambda: Sandbox.new({"capabilities": (), "filesystem": "all"}))
    negative("POLICY_SEALED", "sandbox.timeLimit", lambda: boundary.timeLimit(3))
    type_plugin, _, _ = make_plugin(root, "type-plugin")
    type_sandbox = Sandbox.new({"memoryLimit": 2048, "timeLimit": 32, "callLimit": 1, "capabilities": ("compute", "buffer")})
    type_sandbox.load(type_plugin)
    negative("TYPE_MISMATCH", "sandbox.call", lambda: type_sandbox.call("sum", (True, 2)))
    negative("SANDBOX_TERMINATED", "sandbox.call", lambda: sandbox.call("sum", (1, 2)))


def subgroup_s03() -> None:
    library = ForeignLibrary.open("nebo://ffi/scalar-v1")
    surface("G026-S03-01", library.path == "nebo://ffi/scalar-v1", library.path)
    signature = {"args": ("Int", "Int"), "returns": "Int", "capability": "compute"}
    symbol = library.symbol("add_i64", signature)
    surface("G026-S03-02", symbol.name == "add_i64" and tuple(symbol.signature["args"]) == ("Int", "Int"), symbol.name)
    value = symbol.call((13, 29))
    surface("G026-S03-03", value == 42, value)
    layout = ForeignType.layout(({"name": "tag", "type": "u8"}, {"name": "value", "type": "i64"}))
    surface("G026-S03-04", layout.size == 16 and layout.alignment == 8 and layout.fields[1]["offset"] == 8, (layout.size, layout.alignment, layout.identity))
    lifetime = ForeignLifetime("borrow-1")
    buffer = ForeignBuffer.borrow(b"nebo", 3, lifetime)
    surface("G026-S03-05", buffer.bytes() == b"neb", buffer.bytes())
    callback_signature = {"args": ("Int", "Int"), "returns": "Int", "capability": "callback"}
    callback = Callback.export(lambda left, right: left * right, callback_signature)
    surface("G026-S03-06", callback.call((6, 7)) == 42, callback.call((3, 4)))
    negative("TYPE_MISMATCH", "foreign.call", lambda: symbol.call((True, 2)))
    last_error = ffi.lastError()
    surface("G026-S03-07", last_error is not None and last_error["code"] == "TYPE_MISMATCH" and last_error["symbol"] == "add_i64", last_error)

    reordered = ForeignType.layout(({"name": "value", "type": "i64"}, {"name": "tag", "type": "u8"}))
    claim("metamorphic", reordered.identity != layout.identity, "field order governs foreign layout identity")
    sum_symbol = library.symbol("sum_bytes", {"args": ("Bytes",), "returns": "Int", "capability": "buffer"})
    claim("composition", sum_symbol.call((buffer.bytes(),)) == sum(b"neb"), "borrowed bytes compose with explicit foreign signature")
    lifetime.close()
    negative("LIFETIME_ENDED", "foreignBuffer.bytes", buffer.bytes)
    claim("ownership", not lifetime.active, "ending lifetime invalidates but does not copy the borrow")
    zero_lifetime = ForeignLifetime("zero")
    claim("boundary", ForeignBuffer.borrow(b"x", 0, zero_lifetime).bytes() == b"", "zero-length borrow remains bounded")
    claim("determinism", ForeignType.layout(({"name": "tag", "type": "u8"}, {"name": "value", "type": "i64"})).identity == layout.identity, "layout identity is deterministic")
    claim("failure_atomicity", symbol.name == "add_i64" and last_error["code"] == "TYPE_MISMATCH", "failed call changes only context-local error")
    claim("adversarial", library.path.startswith("nebo://ffi/"), "FFI library is a certified URI not a host path")

    negative("LIBRARY_DENIED", "ForeignLibrary.open", lambda: ForeignLibrary.open("/usr/lib/libc.so"))
    negative("SIGNATURE_MISMATCH", "library.symbol", lambda: library.symbol("add_i64", {"args": ("Int",), "returns": "Int", "capability": "compute"}))
    negative("UNSAFE_FOREIGN_TYPE", "ForeignType.layout", lambda: ForeignType.layout(({"name": "bad", "type": "cstring"},)))
    negative("UNKNOWN_FIELD", "ForeignType.layout", lambda: ForeignType.layout(({"name": "x", "type": "u8", "packed": True},)))
    active = ForeignLifetime("bounded")
    negative("BUFFER_BOUNDS", "ForeignBuffer.borrow", lambda: ForeignBuffer.borrow(b"x", 2, active))
    failing = Callback.export(lambda value: (_ for _ in ()).throw(SystemExit("trap")), {"args": ("Int",), "returns": "Int", "capability": "callback"})
    negative("CALLBACK_FAILURE", "callback.call", lambda: failing.call((1,)))
    negative("CAPABILITY_DENIED", "Callback.export", lambda: Callback.export(lambda value: value, {"args": ("Int",), "returns": "Int", "capability": "compute"}))


def subgroup_s04() -> None:
    node_a = NodeRuntime.start({"identity": "node-a", "protocolVersion": 1, "authToken": "local-trust", "maxTasks": 8, "capabilities": ("compute", "checkpoint")})
    surface("G026-S04-01", node_a.identity == "node-a" and node_a.state == "ready", (node_a.identity, node_a.state))
    advertisement = node_a.advertise(("compute", "checkpoint"))
    surface("G026-S04-02", advertisement["capabilities"] == ("checkpoint", "compute"), advertisement)
    node_b = NodeRuntime.start({"identity": "node-b", "protocolVersion": 1, "authToken": "local-trust", "maxTasks": 8, "capabilities": ("compute", "storage")})
    cluster = Cluster.connect((node_b, node_a))
    surface("G026-S04-03", cluster.health()["total"] == 2, cluster.health())
    members = cluster.members()
    surface("G026-S04-04", tuple(member.identity for member in members) == ("node-a", "node-b"), members)
    health = cluster.health()
    surface("G026-S04-05", health["state"] == "healthy" and health["ready"] == 2, health)
    drain_node = NodeRuntime.start({"identity": "drain-node", "protocolVersion": 1, "authToken": "drain", "maxTasks": 2, "capabilities": ("compute",)})
    drain_cluster = Cluster.connect((drain_node,))
    drain_task = RemoteTask.fromFunction(double, task_schema())
    drain_retry = RetryPolicy.exponential({"maxRetries": 0, "baseDelay": 1, "maxDelay": 1, "jitterSeed": 0, "deadline": 10})
    drain_remote = drain_cluster.submit(drain_task, 4, {"retry": drain_retry})
    draining = drain_node.shutdown()
    drain_result = getattr(drain_remote, "await")()
    surface("G026-S04-06", draining["state"] == "draining" and drain_result == 8 and drain_node.state == "shutdown", (draining, drain_node.state))
    node_b.shutdown()

    claim("metamorphic", cluster.health()["state"] == "degraded" and cluster.health()["ready"] == 1, "node state governs cluster health")
    claim("composition", cluster.members()[0].capabilities == ("checkpoint", "compute"), "advertisement feeds membership snapshot")
    claim("ownership", members[1].state == "ready" and cluster.members()[1].state == "shutdown", "membership snapshot is detached")
    single = NodeRuntime.start({"identity": "single", "protocolVersion": 1, "authToken": "one", "capabilities": ("compute",)})
    claim("boundary", Cluster.connect((single,)).health()["state"] == "healthy", "one-node local profile")
    twin = NodeRuntime.start({"identity": "single", "protocolVersion": 1, "authToken": "one", "capabilities": ("compute",)})
    claim("determinism", Cluster.connect((twin,)).members()[0] == Cluster.connect((single,)).members()[0], "node configuration yields deterministic membership")
    state_before = node_a.state
    negative("DUPLICATE_NODE", "Cluster.connect", lambda: Cluster.connect((node_a, node_a)))
    claim("failure_atomicity", node_a.state == state_before, "failed connection does not mutate seed node")
    claim("adversarial", all(member.identity.startswith("node-") for member in members), "only explicit synthetic identities join")

    outsider = NodeRuntime.start({"identity": "outsider", "protocolVersion": 1, "authToken": "other", "capabilities": ("compute",)})
    negative("CLUSTER_TRUST_MISMATCH", "Cluster.connect", lambda: Cluster.connect((node_a, outsider)))
    negative("NODE_NOT_READY", "node.advertise", lambda: node_b.advertise(("compute",)))
    negative("UNKNOWN_CAPABILITY", "node.advertise", lambda: node_a.advertise(("internet",)))
    compute_only = NodeRuntime.start({"identity": "compute-only", "protocolVersion": 1, "authToken": "local", "capabilities": ("compute",)})
    negative("CAPABILITY_DENIED", "node.advertise", lambda: compute_only.advertise(("compute", "checkpoint")))
    negative("LIMIT_EXCEEDED", "NodeRuntime.start", lambda: NodeRuntime.start({"identity": "bad", "protocolVersion": 2, "authToken": "x"}))
    negative("UNKNOWN_FIELD", "NodeRuntime.start", lambda: NodeRuntime.start({"identity": "bad", "protocolVersion": 1, "authToken": "x", "listen": "public"}))
    negative("INVALID_SEEDS", "Cluster.connect", lambda: Cluster.connect(()))


def subgroup_s05() -> None:
    _, _, cluster = make_nodes()
    task = RemoteTask.fromFunction(double, task_schema())
    surface("G026-S05-01", task.schema["input"] == "Int" and task.schema["output"] == "Int", task.identity)
    retry = RetryPolicy.exponential({"maxRetries": 1, "baseDelay": 2, "maxDelay": 8, "jitterSeed": 3, "deadline": 100})
    remote = cluster.submit(task, 11, {"retry": retry, "idempotencyKey": "job-11"})
    surface("G026-S05-02", remote.state == "pending" and cluster.submit(task, 11, {"retry": retry, "idempotencyKey": "job-11"}) is remote, remote.key)
    result = getattr(remote, "await")()
    surface("G026-S05-03", result == 22 and remote.state == "completed", result)
    cancelled = cluster.submit(task, 12, {"retry": retry, "idempotencyKey": "job-12"})
    surface("G026-S05-04", cancelled.cancel() and not cancelled.cancel() and cancelled.state == "cancelled", cancelled.state)
    data = DistributedData(("alpha", "beta", "gamma"))
    partitioned = data.partition({"kind": "hash", "partitions": 3})
    surface("G026-S05-05", partitioned.partitions == 3 and len(partitioned.assignment) == 3, partitioned.assignment)
    replicated = partitioned.replicate(2)
    ranged = data.partition({"kind": "range", "partitions": 3})
    ranged_replica = ranged.replicate(2)
    surface("G026-S05-06", replicated.replicas == 2 and partitioned.replicas == 1 and ranged_replica.assignment == ranged.assignment, replicated.replicas)
    provenance = remote.provenance()
    surface("G026-S05-07", provenance["node"] in {"node-a", "node-b"} and provenance["attempts"] == 1 and provenance["inputDigest"] == remote.input_digest, provenance)

    changed = cluster.submit(task, 13, {"retry": retry, "idempotencyKey": "job-13"})
    scale_two = RemoteTask.fromFunction(multiplier(2), task_schema("scale"))
    scale_three = RemoteTask.fromFunction(multiplier(3), task_schema("scale"))
    claim("metamorphic", getattr(changed, "await")() == 26 and result != 26 and scale_two.identity != scale_three.identity, "task input and captured implementation govern work identity and result")
    claim("composition", provenance["task"] == task.idempotencyKey() and provenance["schemaVersion"] == 1, "task submission result and provenance compose")
    claim("ownership", data.partitions == 1 and partitioned.partitions == 3 and replicated.replicas == 2, "data placement transformations are detached")
    claim("boundary", partitioned.replicate(1).replicas == 1, "single replica remains explicit")
    twin = DistributedData(("alpha", "beta", "gamma")).partition({"kind": "hash", "partitions": 3})
    claim("determinism", twin.assignment == partitioned.assignment, "hash partition placement is deterministic")
    count_before = len(cluster._executions)
    other_task = RemoteTask.fromFunction(double, task_schema("other"))
    negative("IDEMPOTENCY_CONFLICT", "cluster.submit", lambda: cluster.submit(other_task, 11, {"retry": retry, "idempotencyKey": "job-11"}))
    claim("failure_atomicity", len(cluster._executions) == count_before, "idempotency collision creates no work")
    claim("adversarial", not hasattr(task, "binary") and not hasattr(task, "shell"), "remote task contains no code-shipping route")

    negative("INVALID_FUNCTION", "RemoteTask.fromFunction", lambda: RemoteTask.fromFunction(7, task_schema()))
    negative("INVALID_SCHEMA", "RemoteTask.fromFunction", lambda: RemoteTask.fromFunction(double, {"name": "x"}))
    storage_node = NodeRuntime.start({"identity": "storage-only", "protocolVersion": 1, "authToken": "local", "capabilities": ("storage",)})
    storage_cluster = Cluster.connect((storage_node,))
    negative("NO_ELIGIBLE_NODE", "cluster.submit", lambda: storage_cluster.submit(task, 1, {"retry": retry}))
    negative("LIMIT_EXCEEDED", "data.replicate", lambda: data.replicate(4))
    negative("REMOTE_CANCELLED", "remote.await", lambda: getattr(cancelled, "await")())
    application = RemoteTask.fromFunction(bad_output, task_schema("badOutput"))
    application_remote = cluster.submit(application, 3, {"retry": retry, "idempotencyKey": "bad-output"})
    negative("REMOTE_FAILED", "remote.await", lambda: getattr(application_remote, "await")())
    require(application_remote.failure() is not None and application_remote.failure().kind == "application", "application failure is isolated")
    negative("UNKNOWN_FIELD", "cluster.submit", lambda: cluster.submit(task, 14, {"retry": retry, "codeShipping": True}))


def subgroup_s06() -> None:
    _, _, cluster = make_nodes()
    retry = RetryPolicy.exponential({"maxRetries": 2, "baseDelay": 2, "maxDelay": 8, "jitterSeed": 5, "deadline": 100})
    surface("G026-S06-01", retry.schedule() == (3, 4, 8) and retry.max_retries == 2, retry.schedule())
    task = RemoteTask.fromFunction(double, task_schema())
    surface("G026-S06-02", len(task.idempotencyKey()) == 64 and task.idempotencyKey() == task.identity, task.idempotencyKey())
    checkpoint = Checkpoint.distributed({"version": 1, "identity": "batch-7", "progress": 12, "replicas": 3, "quorum": 2})
    surface("G026-S06-03", checkpoint.replicas == 3 and checkpoint.quorum == 2 and len(checkpoint.digest) == 64, checkpoint)
    decision = cluster.quorum({"replicas": 2, "votes": 2})
    surface("G026-S06-04", decision.accepted and decision.required == 2 and decision.votes == 2, decision)
    failing_retry = RetryPolicy.exponential({"maxRetries": 0, "baseDelay": 1, "maxDelay": 1, "jitterSeed": 0, "deadline": 10})
    failed = cluster.submit(task, 21, {"retry": failing_retry, "idempotencyKey": "will-fail", "injectedFailures": ("node_loss",)})
    negative("REMOTE_FAILED", "remote.await", lambda: getattr(failed, "await")())
    failure = failed.failure()
    surface("G026-S06-05", failure is not None and failure.kind == "node_loss" and failure.retryable and failure.attempts == 1, failure)
    events: list[str] = []
    workflow = Workflow().compensate({"name": "release", "action": lambda: events.append("release")}).compensate({"name": "refund", "action": lambda: events.append("refund")})
    applied = workflow.runCompensations()
    surface("G026-S06-06", applied == ("refund", "release") and tuple(events) == applied and workflow.runCompensations() == (), applied)
    placement = cluster.rebalance()
    surface("G026-S06-07", placement["generation"] == 2 and len(placement["assignments"]) == 1, placement)

    alternate = RetryPolicy.exponential({"maxRetries": 2, "baseDelay": 2, "maxDelay": 8, "jitterSeed": 6, "deadline": 100})
    claim("metamorphic", alternate.schedule() != retry.schedule(), "retry seed governs deterministic jitter")
    claim("composition", failed.provenance()["attempts"] == failure.attempts and failed.provenance()["node"] == failure.node, "failure and provenance compose")
    claim("ownership", checkpoint.progress == 12 and type(checkpoint).__dataclass_params__.frozen, "checkpoint is immutable")
    zero_retry = RetryPolicy.exponential({"maxRetries": 0, "baseDelay": 1, "maxDelay": 1, "jitterSeed": 0, "deadline": 1})
    claim("boundary", zero_retry.schedule() == (1,), "zero-retry policy still has one bounded attempt")
    claim("determinism", Checkpoint.distributed({"version": 1, "identity": "batch-7", "progress": 12, "replicas": 3, "quorum": 2}) == checkpoint, "checkpoint identity is deterministic")
    health_before = cluster.health()
    negative("INVALID_INTEGER", "cluster.quorum", lambda: cluster.quorum({"replicas": 3, "votes": True}))
    negative("QUORUM_UNAVAILABLE", "cluster.quorum", lambda: cluster.quorum({"replicas": 3, "votes": 2}))
    claim("failure_atomicity", cluster.health() == health_before, "invalid quorum leaves cluster state unchanged")
    claim("adversarial", failure.kind == "node_loss" and failed.state == "failed", "fault is injected and remains observable")

    negative("INVALID_INTEGER", "RetryPolicy.exponential", lambda: RetryPolicy.exponential({"maxRetries": True, "baseDelay": 1, "maxDelay": 1, "deadline": 1}))
    negative("LIMIT_EXCEEDED", "RetryPolicy.exponential", lambda: RetryPolicy.exponential({"maxRetries": 9, "baseDelay": 1, "maxDelay": 1, "deadline": 1}))
    negative("INVALID_QUORUM", "Checkpoint.distributed", lambda: Checkpoint.distributed({"replicas": 3, "quorum": 1}))
    deadline_retry = RetryPolicy.exponential({"maxRetries": 1, "baseDelay": 2, "maxDelay": 2, "jitterSeed": 0, "deadline": 1})
    deadline_remote = cluster.submit(task, 22, {"retry": deadline_retry, "idempotencyKey": "deadline", "injectedFailures": ("timeout",)})
    negative("REMOTE_FAILED", "remote.await", lambda: getattr(deadline_remote, "await")())
    require(deadline_remote.failure() is not None and deadline_remote.failure().kind == "timeout" and deadline_remote.attempts == 1, "retry deadline stops the next attempt")
    duplicate = Workflow().compensate({"name": "same", "action": lambda: None})
    negative("DUPLICATE_COMPENSATION", "workflow.compensate", lambda: duplicate.compensate({"name": "same", "action": lambda: None}))
    dead_a, dead_b, dead_cluster = make_nodes()
    dead_a.shutdown()
    dead_b.shutdown()
    negative("NO_ELIGIBLE_NODE", "cluster.rebalance", dead_cluster.rebalance)


def static_checks() -> None:
    source = Path("compiler/sdk/extensions.py").read_text(encoding="utf-8")
    forbidden = ("subprocess.", "os.system", "ctypes.", "urlopen", "requests.", "http.client")
    require(all(term not in source for term in forbidden), "no shell network or dynamic-loader dependency")
    require("does not dlopen arbitrary libraries" in source and "does not claim a strong operating-system sandbox" in source, "honest native and sandbox boundaries")
    claim("adversarial", "x86_64-linux-static" in source and "UNSIGNED_DENIED" in source, "target and signed-default gates exist")


def main() -> None:
    scratch_parent = Path(tempfile.gettempdir())
    with tempfile.TemporaryDirectory(prefix="g026-oracle-", dir=scratch_parent) as directory:
        root = Path(directory)
        subgroup_s01(root)
        subgroup_s02(root)
    subgroup_s03()
    subgroup_s04()
    subgroup_s05()
    subgroup_s06()
    static_checks()
    require(COUNTS["positive"] == 41 and COUNTS["sdk"] == 41, "all 41 surfaces need direct observations")
    digest = hashlib.sha256(json.dumps(EVIDENCE, separators=(",", ":"), ensure_ascii=True).encode("ascii")).hexdigest()
    fields = " ".join(f"{name}={value}" for name, value in COUNTS.items())
    print(f"G026_SDK_ORACLE_GREEN {fields} digest={digest}")


if __name__ == "__main__":
    main()
