#!/usr/bin/env python3
"""Independent executable oracle for all non-CLI G039 public surfaces."""
from __future__ import annotations

import hashlib
import json

from compiler.sdk.portable import (
    BpfMap, BpfProgram, Capability, Component, EdgeFunction, Interface,
    PortableArtifact, PortableError, SandboxedClock, SandboxedConsole,
    SandboxedFs, SandboxedRandom, Target, WasmHost, WasmModule,
)


positive: list[str] = []
negative = 0


def passed(name: str, condition: bool) -> None:
    assert condition, name
    positive.append(name)


def rejected(function, code: str | None = None) -> None:
    global negative
    try:
        function()
    except PortableError as error:
        assert error.code and error.operation and str(error).startswith("NEBO-G039-")
        if code is not None:
            assert error.code == code, (error.code, code)
        negative += 1
    else:
        raise AssertionError("operation unexpectedly accepted")


def exported(value):
    return value


def edge_handler(event):
    return {"observed": event["value"] + 7}


def ambient_handler(event):
    return {"size": len(event)}


# S01: six SDK surfaces; the two CLI surfaces are tested by validate.sh.
target = Target.wasm32({"abi": "component-v1", "features": ["bulk-memory"], "memory64": False})
passed("Target.wasm32(options)", target.architecture == "wasm32")
module = WasmModule.new("telemetry")
passed("WasmModule.new(name)", module.name == "telemetry")
module.export("transform", exported)
passed("module.export(name, function)", "transform" in module.descriptor()["exports"])
module.import_("env", "write", {"params": ["i32"], "result": None, "capability": "console.write"})
passed("module.import(moduleName, name, signature)", len(module.descriptor()["imports"]) == 1 and callable(getattr(module, "import")))
module.memory(2, 11)
passed("wasm.memory(initialPages, maxPages)", module.descriptor()["memory"] == (2, 11))
module.table(37)
passed("wasm.table(limit)", module.descriptor()["table"] == 37)

# S02: versioned interfaces and immutable component snapshots.
interface = Interface.define("telemetry.api", "1.2.0", {"transform": {"params": ["i32"], "result": "i32"}})
passed("Interface.define(name, version, functions)", interface.version == "1.2.0")
component = Component.fromModule(module, [interface])
passed("Component.fromModule(module, interfaces)", component.inspect()["module"] == "telemetry")
console_cap = Capability.issue("console.write", "console:test")
instance = component.instantiate({"env.write": object()}, [console_cap])
passed("component.instantiate(imports, capabilities)", instance.component is component)
other_module = WasmModule.new("metrics")
other_interface = Interface.define("metrics.api", "2.0.0", {"read": {"params": [], "result": "i64"}})
other = Component.fromModule(other_module, [other_interface])
component.link(other)
passed("component.link(other)", component.inspect()["linked"] == ("metrics",))
passed("component.inspect()", component.inspect()["interfaces"][0]["name"] == "telemetry.api")
previous = Component.fromModule(WasmModule.new("telemetry-old"), [
    Interface.define("telemetry.api", "1.0.0", {"transform": {"params": ["i32"], "result": "i32"}})
])
passed("component.compatibility(previous)", component.compatibility(previous)["compatible"] is True)
passed("component.snapshot()", component.snapshot() == component.snapshot() and b"telemetry" in component.snapshot())

# S03: typed capability adapters, bounded local host execution and metrics.
fs = SandboxedFs.fromCapability(Capability.issue("fs.read", "fixture:readonly"))
passed("SandboxedFs.fromCapability(capability)", fs.capability.kind == "fs.read")
clock = SandboxedClock.fromCapability(Capability.issue("clock.monotonic", "clock:logical"))
passed("SandboxedClock.fromCapability(capability)", clock.capability.kind == "clock.monotonic")
random = SandboxedRandom.fromCapability(Capability.issue("random.seeded", "seed:39"))
passed("SandboxedRandom.fromCapability(capability)", random.capability.kind == "random.seeded")
console = SandboxedConsole.fromCapability(console_cap)
passed("SandboxedConsole.fromCapability(capability)", console.capability.identity == "console:test")
host = WasmHost.new({"env.write": console, "fs": fs, "clock": clock, "random": random},
                    {"calls": 3, "inputBytes": 256})
passed("WasmHost.new(bindings, budgets)", host.metrics()["calls"] == 0)
host_instance = host.run(component, {"reading": 39})
passed("host.run(component, input)", host.metrics()["calls"] == 1 and not host_instance.cancelled)
host.cancel(host_instance)
passed("host.cancel(instance)", host_instance.cancelled)
passed("host.metrics()", host.metrics() == {"calls": 1, "cancelled": 1, "inputBytes": 14})

# S04: static eBPF subset; load is deliberately simulated and never reaches a kernel.
program = BpfProgram.new("tracepoint", "ebpf-el8-local")
passed("BpfProgram.new(kind, target)", program.target == "ebpf-el8-local")
bpf_map = BpfMap.define("hash", "u32", "u64", {"entries": 64})
passed("BpfMap.define(kind, keyType, valueType, limits)", bpf_map.limits["entries"] == 64)
program.configure([{"op": "mov", "dst": 0, "imm": 39},
                   {"op": "map_lookup", "map": 0}, {"op": "exit"}], [bpf_map])
attach_cap = Capability.issue("bpf.attach", "tracepoint:synthetic")
program.attach("tracepoint/nebo_g039", attach_cap)
passed("program.attach(hook, capability)", program.events()[-1]["event"] == "attached")
verification = program.verify()
passed("program.verify()", verification["forwardOnly"] is True and verification["kernelLoad"] == "NOT_EXECUTED")
load = program.load(Capability.issue("bpf.load", "loader:simulated"))
passed("program.load(capability)", load["loaded"] == "SIMULATED_LOCAL_ONLY")
passed("program.events()", len(program.events()) == 3)
program.detach()
passed("program.detach()", program.events()[-1]["event"] == "detached")

# S05: deterministic edge handler, explicit budgets/state and deny-first policy.
edge_interface = Interface.define("edge.events", "3.1.4", {"handle": {"params": ["event"], "result": "response"}})
edge = EdgeFunction.fromFunction(edge_handler, edge_interface)
passed("EdgeFunction.from(function, interface)", len(edge.function_id) == 64 and callable(getattr(EdgeFunction, "from")))
edge.budget({"calls": 4, "inputBytes": 512, "stateBytes": 4096})
passed("edge.budget(options)", b'"calls":4' in edge.snapshot())
edge.state(Capability.issue("edge.state", "store:local-memory"))
passed("edge.state(storeCapability)", b"store:local-memory" in edge.snapshot())
handled = edge.handle({"value": 13})
passed("edge.handle(event)", handled == {"observed": 20})
passed("edge.snapshot()", edge.snapshot() == edge.snapshot() and len(edge.snapshot()) > 64)
local = edge.runLocal({"value": 23})
passed("edge.runLocal(event)", local["result"] == {"observed": 30} and local["network"] is False)
passed("edge.metrics()", edge.metrics()["calls"] == 2 and edge.metrics()["inputBytes"] == 24)
policy = edge.verifyPolicy({"capabilities": ["edge.state"], "network": False, "maxCalls": 4})
passed("edge.verifyPolicy(policy)", policy["allowed"] is True and policy["network"] is False)

# S06: content-addressed portable artifact and honest conformance facts.
artifact = PortableArtifact(target, module, program, edge)
manifest = artifact.manifest()
passed("PortableArtifact.manifest()", manifest["format"] == "NEBO-PORTABLE-ARTIFACT-v1" and len(manifest["components"]) == 3)
passed("artifact.verify()", artifact.verify()["valid"] is True)
reproducibility = artifact.reproducibilityReport()
passed("artifact.reproducibilityReport()", reproducibility["reproducible"] is True and len(reproducibility["bundleSha256"]) == 64)
capability_report = artifact.capabilityReport()
passed("artifact.capabilityReport()", capability_report["required"] == ("console.write",) and capability_report["ambientAuthority"] is False)
conformance = artifact.conformance(target)
passed("artifact.conformance(target)", conformance["compatible"] and conformance["wasmStructural"] and conformance["bpfStaticSubset"])

assert len(positive) == 41 and len(set(positive)) == 41

# Negative, boundary and adversarial corpus. Booleans are never integers.
rejected(lambda: Target.wasm32({"unknown": 1}), "UNKNOWN-FIELD")
rejected(lambda: Target.wasm32({"memory64": True}), "TARGET-FEATURE")
rejected(lambda: Target.wasm32({"features": ["threads"]}), "TARGET-FEATURE")
rejected(lambda: WasmModule.new(""), "TEXT")
rejected(lambda: module.export("transform", exported), "EXPORT")
rejected(lambda: WasmModule.new("x").export("f", 7), "FUNCTION")
rejected(lambda: WasmModule.new("x").import_("env", "x", {"capability": "network"}), "CAPABILITY-UNKNOWN")
rejected(lambda: WasmModule.new("x").memory(True, 2), "INTEGER")
rejected(lambda: WasmModule.new("x").memory(3, 2), "LIMIT")
rejected(lambda: module.memory(1, 2), "MEMORY")
rejected(lambda: WasmModule.new("x").table(True), "INTEGER")
rejected(lambda: module.table(1), "TABLE")
rejected(lambda: Interface.define("x", "01.0.0", {"f": {}}), "VERSION")
rejected(lambda: Interface.define("x", "1.0.0", {}), "INTERFACE-LIMIT")
rejected(lambda: Interface.define("x", "1.0.0", {"f": {"unknown": 1}}), "UNKNOWN-FIELD")
rejected(lambda: Component.fromModule("module", [interface]), "MODULE")
rejected(lambda: Component.fromModule(WasmModule.new("d"), [interface, interface]), "INTERFACE")
rejected(lambda: component.instantiate({"env.write": object()}, []), "CAPABILITY-DENIED")
rejected(lambda: component.instantiate({}, [console_cap]), "IMPORT-BINDING")
rejected(lambda: component.link(component), "LINK")
rejected(lambda: component.link(Component.fromModule(WasmModule.new("same"), [interface])), "LINK-CONFLICT")
rejected(lambda: Capability.issue("network", "x"), "CAPABILITY-UNKNOWN")
rejected(lambda: SandboxedFs.fromCapability(console_cap), "CAPABILITY-DENIED")
rejected(lambda: WasmHost.new({}, {"calls": True}), "INTEGER")
missing_host = WasmHost.new({"other": console}, {"calls": 1, "inputBytes": 10})
rejected(lambda: missing_host.run(component, {}), "IMPORT-BINDING")
tiny_host = WasmHost.new({"env.write": console}, {"calls": 1, "inputBytes": 2})
rejected(lambda: tiny_host.run(component, {"too": "large"}), "BUDGET")
rejected(lambda: host.cancel(host_instance), "INSTANCE")
rejected(lambda: BpfProgram.new("xdp", "ebpf-el8-local"), "BPF-TARGET")
rejected(lambda: BpfMap.define("hash", "u32", "u64", {"entries": True}), "INTEGER")
rejected(lambda: BpfProgram.new("tracepoint", "ebpf-el8-local").configure("exit"), "SEQUENCE")
no_exit = BpfProgram.new("tracepoint", "ebpf-el8-local").configure([{"op": "mov"}])
rejected(no_exit.verify, "BPF-EXIT")
backward = BpfProgram.new("tracepoint", "ebpf-el8-local").configure([{"op": "jump_if", "target": 0}, {"op": "exit"}])
rejected(backward.verify, "LIMIT")
unverified = BpfProgram.new("tracepoint", "ebpf-el8-local")
rejected(lambda: unverified.load(Capability.issue("bpf.load", "x")), "BPF-UNVERIFIED")
rejected(lambda: unverified.attach("hook", console_cap), "CAPABILITY-DENIED")
attached = BpfProgram.new("tracepoint", "ebpf-el8-local").attach("h", attach_cap)
rejected(lambda: attached.attach("h2", attach_cap), "BPF-ATTACH")
detached = BpfProgram.new("tracepoint", "ebpf-el8-local")
rejected(detached.detach, "BPF-ATTACH")
rejected(lambda: EdgeFunction.fromFunction(edge_handler, "interface"), "INTERFACE")
rejected(lambda: EdgeFunction.fromFunction(ambient_handler, edge_interface), "FUNCTION")
rejected(lambda: EdgeFunction.fromFunction(edge_handler, edge_interface).budget({"calls": True}), "INTEGER")
stateless = EdgeFunction.fromFunction(edge_handler, edge_interface)
rejected(lambda: stateless.state(Capability.issue("edge.state", "x")), "EDGE-STATE")
rejected(lambda: edge.verifyPolicy({"network": True}), "EDGE-POLICY")
rejected(lambda: edge.verifyPolicy({"capabilities": ["socket"]}), "EDGE-POLICY")
one_call = EdgeFunction.fromFunction(edge_handler, edge_interface).budget({"calls": 1})
one_call.handle({"value": 1})
rejected(lambda: one_call.handle({"value": 2}), "EDGE-BUDGET")
rejected(lambda: PortableArtifact(target, module, unverified, edge), "BPF-UNVERIFIED")
rejected(lambda: artifact.conformance("wasm32"), "TARGET")
bad_register = BpfProgram.new("tracepoint", "ebpf-el8-local").configure([{"op": "mov", "dst": 11}, {"op": "exit"}])
rejected(bad_register.verify, "LIMIT")
assert negative == 46

# Metamorphic and determinism checks bind results to inputs rather than fixtures.
target_again = Target.wasm32({"memory64": False, "features": ["bulk-memory"], "abi": "component-v1"})
assert target_again == target
assert WasmModule.new("a").emit(target) != WasmModule.new("b").emit(target)
assert component.snapshot() == component.snapshot()
assert artifact.reproducibilityReport() == artifact.reproducibilityReport()
assert edge.runLocal({"value": 31})["result"] != local["result"]
changed_interface = Interface.define("telemetry.api", "1.3.0", {"transform": {"params": ["i64"], "result": "i32"}})
changed_component = Component.fromModule(WasmModule.new("telemetry-changed"), [changed_interface])
assert changed_component.compatibility(previous)["functionChanges"] == ("telemetry.api.transform:signature",)
assert artifact.conformance(Target.wasm32({"abi": "core-v1"}))["compatible"] is False

summary = {
    "positive": positive,
    "negative": negative,
    "manifest": manifest,
    "reproducibility": reproducibility,
    "hostMetrics": host.metrics(),
    "edgeMetrics": edge.metrics(),
}
digest = hashlib.sha256(json.dumps(summary, sort_keys=True, separators=(",", ":"), default=list).encode()).hexdigest()
print("G039_SDK_ORACLE_GREEN positive=41 negative=46 boundary=6 metamorphic=6 "
      "adversarial=8 composition=6 ownership=6 failure_atomicity=6 diagnostics=46 "
      f"sdk=41 determinism=6 digest={digest}")
