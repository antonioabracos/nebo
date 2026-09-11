"""Deterministic local WebAssembly, eBPF, component, and edge profile for G039.

The module is an executable reference for the current public contract.  It
never loads an operating-system BPF program, opens a network connection, reads
ambient credentials, or claims a strong process sandbox.  Capabilities and
budgets are explicit, artifacts are bounded and content-addressed, and every
unsupported operation fails closed with a stable diagnostic.

This reference does not claim a strong process sandbox; it models the public
capability and resource contract inside one deterministic local process.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import inspect
import json
import re
import struct
from types import MappingProxyType
from typing import Any, Callable, Mapping, Sequence


MAX_SOURCE_BYTES = 1_048_576
MAX_MEMORY_PAGES = 4096
MAX_TABLE_ITEMS = 65_536
MAX_IMPORTS = 128
MAX_EXPORTS = 128
MAX_INTERFACE_FUNCTIONS = 128
MAX_COMPONENTS = 32
MAX_INPUT_BYTES = 1_048_576
MAX_CALLS = 4096
MAX_BPF_INSTRUCTIONS = 4096
MAX_BPF_MAP_ENTRIES = 65_536
MAX_EDGE_STATE_BYTES = 1_048_576
KNOWN_CAPABILITIES = frozenset({
    "console.write", "clock.monotonic", "fs.read", "random.seeded",
    "bpf.attach", "bpf.load", "edge.state",
})


class PortableError(ValueError):
    """Stable fail-closed G039 diagnostic."""

    def __init__(self, code: str, operation: str, detail: str) -> None:
        super().__init__(f"NEBO-G039-{code}: {operation}: {detail}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, detail: str) -> None:
    raise PortableError(code, operation, detail)


def _text(value: Any, operation: str, name: str, maximum: int = 8192) -> str:
    if not isinstance(value, str) or not value or len(value.encode("utf-8")) > maximum:
        _fail("TEXT", operation, f"{name} must be bounded non-empty text")
    return value


def _integer(value: Any, operation: str, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        _fail("INTEGER", operation, f"{name} must be an integer")
    if not minimum <= value <= maximum:
        _fail("LIMIT", operation, f"{name} must be in [{minimum}, {maximum}]")
    return value


def _mapping(value: Any, operation: str, name: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail("MAPPING", operation, f"{name} must be a mapping")
    if not all(isinstance(key, str) for key in value):
        _fail("MAPPING", operation, f"{name} keys must be text")
    return value


def _sequence(value: Any, operation: str, name: str) -> Sequence[Any]:
    if isinstance(value, (str, bytes, bytearray, memoryview)) or not isinstance(value, Sequence):
        _fail("SEQUENCE", operation, f"{name} must be a sequence")
    return value


def _fields(value: Mapping[str, Any], allowed: set[str], operation: str) -> None:
    unknown = set(value) - allowed
    if unknown:
        _fail("UNKNOWN-FIELD", operation, ",".join(sorted(unknown)))


def _plain(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _plain(value[key]) for key in sorted(value)}
    if isinstance(value, (tuple, list)):
        return [_plain(item) for item in value]
    if isinstance(value, (set, frozenset)):
        return sorted(_plain(item) for item in value)
    if isinstance(value, bytes):
        return {"$bytes": value.hex()}
    if isinstance(value, (str, int, bool)) or value is None:
        return value
    _fail("CANONICAL", "canonicalize", f"unsupported {type(value).__name__}")


def _canonical(value: Any) -> bytes:
    return json.dumps(_plain(value), sort_keys=True, separators=(",", ":"),
                      ensure_ascii=True).encode("ascii")


def _digest(value: Any) -> str:
    return hashlib.sha256(value if isinstance(value, bytes) else _canonical(value)).hexdigest()


def _freeze(value: Any) -> Any:
    plain = _plain(value)
    if isinstance(plain, dict):
        return MappingProxyType({key: _freeze(item) for key, item in plain.items()})
    if isinstance(plain, list):
        return tuple(_freeze(item) for item in plain)
    return plain


def _semver(value: Any, operation: str) -> tuple[int, int, int]:
    text = _text(value, operation, "version", 64)
    match = re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", text)
    if match is None:
        _fail("VERSION", operation, "version must be canonical major.minor.patch")
    parts = tuple(int(part) for part in match.groups())
    if any(part > 65535 for part in parts):
        _fail("VERSION", operation, "version component exceeds 65535")
    return parts  # type: ignore[return-value]


def _capability(value: Any, expected: str, operation: str) -> "Capability":
    if not isinstance(value, Capability) or value.kind != expected:
        _fail("CAPABILITY-DENIED", operation, f"requires {expected}")
    return value


def _function_identity(function: Any, operation: str) -> str:
    if not callable(function):
        _fail("FUNCTION", operation, "value must be callable")
    try:
        signature = str(inspect.signature(function))
    except (TypeError, ValueError):
        _fail("FUNCTION", operation, "callable signature is unavailable")
    code = getattr(function, "__code__", None)
    if code is not None and code.co_names:
        _fail("FUNCTION", operation, "callable cannot depend on ambient global names")
    material = {
        "module": getattr(function, "__module__", ""),
        "name": getattr(function, "__qualname__", getattr(function, "__name__", "")),
        "signature": signature,
        "bytecode": code.co_code.hex() if code is not None else "native",
    }
    return _digest(material)


def _uleb(value: int) -> bytes:
    result = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        result.append(byte | (0x80 if value else 0))
        if not value:
            return bytes(result)


@dataclass(frozen=True)
class Capability:
    kind: str
    identity: str

    @staticmethod
    def issue(kind: str, identity: str) -> "Capability":
        operation = "Capability.issue"
        checked = _text(kind, operation, "kind", 128)
        if checked not in KNOWN_CAPABILITIES:
            _fail("CAPABILITY-UNKNOWN", operation, checked)
        return Capability(checked, _text(identity, operation, "identity", 256))


@dataclass(frozen=True)
class Target:
    architecture: str
    options: Mapping[str, Any]

    @staticmethod
    def wasm32(options: Mapping[str, Any]) -> "Target":
        operation = "Target.wasm32"
        values = dict(_mapping(options, operation, "options"))
        _fields(values, {"abi", "features", "memory64"}, operation)
        abi = values.get("abi", "component-v1")
        if abi not in {"core-v1", "component-v1"}:
            _fail("TARGET-ABI", operation, "unsupported ABI")
        if values.get("memory64", False) is not False:
            _fail("TARGET-FEATURE", operation, "memory64 is outside wasm32")
        features = tuple(_sequence(values.get("features", ()), operation, "features"))
        if any(item not in {"bulk-memory", "mutable-globals"} for item in features):
            _fail("TARGET-FEATURE", operation, "unsupported target feature")
        if len(set(features)) != len(features):
            _fail("TARGET-FEATURE", operation, "duplicate target feature")
        return Target("wasm32", _freeze({"abi": abi, "features": sorted(features), "memory64": False}))


class WasmModule:
    def __init__(self, name: str) -> None:
        self.name = _text(name, "WasmModule.new", "name", 256)
        self._exports: dict[str, str] = {}
        self._imports: dict[tuple[str, str], Mapping[str, Any]] = {}
        self._memory: tuple[int, int] | None = None
        self._table_limit: int | None = None

    @staticmethod
    def new(name: str) -> "WasmModule":
        return WasmModule(name)

    def export(self, name: str, function: Callable[..., Any]) -> "WasmModule":
        operation = "module.export"
        checked = _text(name, operation, "name", 256)
        if checked in self._exports or len(self._exports) >= MAX_EXPORTS:
            _fail("EXPORT", operation, "duplicate export or export limit")
        self._exports[checked] = _function_identity(function, operation)
        return self

    def import_(self, module_name: str, name: str, signature: Mapping[str, Any]) -> "WasmModule":
        operation = "module.import"
        key = (_text(module_name, operation, "moduleName", 256),
               _text(name, operation, "name", 256))
        values = dict(_mapping(signature, operation, "signature"))
        _fields(values, {"params", "result", "capability"}, operation)
        params = tuple(_sequence(values.get("params", ()), operation, "params"))
        valid_types = {"i32", "i64", "f32", "f64"}
        if len(params) > 16 or any(item not in valid_types for item in params):
            _fail("SIGNATURE", operation, "invalid parameters")
        result = values.get("result")
        if result not in valid_types | {None}:
            _fail("SIGNATURE", operation, "invalid result")
        capability = _text(values.get("capability"), operation, "capability", 128)
        if capability not in KNOWN_CAPABILITIES:
            _fail("CAPABILITY-UNKNOWN", operation, capability)
        if key in self._imports or len(self._imports) >= MAX_IMPORTS:
            _fail("IMPORT", operation, "duplicate import or import limit")
        self._imports[key] = _freeze({"params": params, "result": result, "capability": capability})
        return self

    def memory(self, initial_pages: int, max_pages: int) -> "WasmModule":
        operation = "wasm.memory"
        initial = _integer(initial_pages, operation, "initialPages", 0, MAX_MEMORY_PAGES)
        maximum = _integer(max_pages, operation, "maxPages", initial, MAX_MEMORY_PAGES)
        if self._memory is not None:
            _fail("MEMORY", operation, "memory already declared")
        self._memory = (initial, maximum)
        return self

    def table(self, limit: int) -> "WasmModule":
        operation = "wasm.table"
        if self._table_limit is not None:
            _fail("TABLE", operation, "table already declared")
        self._table_limit = _integer(limit, operation, "limit", 0, MAX_TABLE_ITEMS)
        return self

    def descriptor(self) -> Mapping[str, Any]:
        return _freeze({
            "name": self.name,
            "exports": self._exports,
            "imports": [{"module": key[0], "name": key[1], **_plain(value)}
                        for key, value in sorted(self._imports.items())],
            "memory": self._memory,
            "table": self._table_limit,
        })

    def emit(self, target: Target) -> bytes:
        if not isinstance(target, Target) or target.architecture != "wasm32":
            _fail("TARGET", "WasmModule.emit", "wasm32 target required")
        payload = _canonical({"module": self.descriptor(), "target": target.options})
        if len(payload) > MAX_SOURCE_BYTES:
            _fail("LIMIT", "WasmModule.emit", "module metadata exceeds limit")
        name = b"nebo.g039"
        custom = _uleb(len(name)) + name + payload
        return b"\0asm\x01\0\0\0" + b"\0" + _uleb(len(custom)) + custom


# Python reserves ``import``; reflection still exposes the exact public spelling.
setattr(WasmModule, "import", WasmModule.import_)
setattr(WasmModule, "importSurface", WasmModule.import_)


@dataclass(frozen=True)
class Interface:
    name: str
    version: str
    functions: Mapping[str, Mapping[str, Any]]

    @staticmethod
    def define(name: str, version: str, functions: Mapping[str, Mapping[str, Any]]) -> "Interface":
        operation = "Interface.define"
        checked_name = _text(name, operation, "name", 256)
        _semver(version, operation)
        values = dict(_mapping(functions, operation, "functions"))
        if not values or len(values) > MAX_INTERFACE_FUNCTIONS:
            _fail("INTERFACE-LIMIT", operation, "functions must be non-empty and bounded")
        checked: dict[str, Mapping[str, Any]] = {}
        for function_name, signature in values.items():
            checked_name_fn = _text(function_name, operation, "function", 256)
            signature_value = dict(_mapping(signature, operation, "signature"))
            _fields(signature_value, {"params", "result"}, operation)
            params = tuple(_sequence(signature_value.get("params", ()), operation, "params"))
            if len(params) > 16 or any(not isinstance(item, str) or not item for item in params):
                _fail("SIGNATURE", operation, "parameters must be bounded named types")
            result = _text(signature_value.get("result"), operation, "result", 256)
            checked[checked_name_fn] = _freeze({"params": params, "result": result})
        return Interface(checked_name, version, MappingProxyType(checked))


class ComponentInstance:
    def __init__(self, component: "Component", imports: Mapping[str, Any], capabilities: Sequence[Capability]) -> None:
        self.component = component
        self.imports = MappingProxyType(dict(imports))
        self.capabilities = tuple(capabilities)
        self.cancelled = False


class Component:
    def __init__(self, module: WasmModule, interfaces: Sequence[Interface]) -> None:
        operation = "Component.fromModule"
        if not isinstance(module, WasmModule):
            _fail("MODULE", operation, "WasmModule required")
        checked = tuple(_sequence(interfaces, operation, "interfaces"))
        if not checked or len(checked) > MAX_COMPONENTS or not all(isinstance(item, Interface) for item in checked):
            _fail("INTERFACE", operation, "bounded interfaces required")
        identities = {(item.name, item.version) for item in checked}
        if len(identities) != len(checked):
            _fail("INTERFACE", operation, "duplicate interface identity")
        self.module = module
        self.interfaces = checked
        self._linked: list[Component] = []

    @staticmethod
    def fromModule(module: WasmModule, interfaces: Sequence[Interface]) -> "Component":
        return Component(module, interfaces)

    def instantiate(self, imports: Mapping[str, Any], capabilities: Sequence[Capability]) -> ComponentInstance:
        operation = "component.instantiate"
        bindings = dict(_mapping(imports, operation, "imports"))
        caps = tuple(_sequence(capabilities, operation, "capabilities"))
        if not all(isinstance(item, Capability) for item in caps):
            _fail("CAPABILITY", operation, "capabilities must be issued tokens")
        provided = {item.kind for item in caps}
        required = {value["capability"] for value in self.module._imports.values()}
        if not required <= provided:
            _fail("CAPABILITY-DENIED", operation, "missing imported capability")
        expected_bindings = {f"{key[0]}.{key[1]}" for key in self.module._imports}
        if set(bindings) != expected_bindings:
            _fail("IMPORT-BINDING", operation, "bindings must match imports exactly")
        return ComponentInstance(self, bindings, caps)

    def link(self, other: "Component") -> "Component":
        operation = "component.link"
        if not isinstance(other, Component) or other is self or len(self._linked) >= MAX_COMPONENTS:
            _fail("LINK", operation, "distinct bounded component required")
        existing = {(item.name, _semver(item.version, operation)[0]) for item in self.interfaces}
        incoming = {(item.name, _semver(item.version, operation)[0]) for item in other.interfaces}
        if existing & incoming:
            _fail("LINK-CONFLICT", operation, "interface major version conflict")
        self._linked.append(other)
        return self

    def inspect(self) -> Mapping[str, Any]:
        return _freeze({
            "module": self.module.name,
            "interfaces": [{"name": item.name, "version": item.version} for item in self.interfaces],
            "linked": [item.module.name for item in self._linked],
        })

    def compatibility(self, previous: "Component") -> Mapping[str, Any]:
        operation = "component.compatibility"
        if not isinstance(previous, Component):
            _fail("COMPONENT", operation, "previous must be a Component")
        old = {item.name: item for item in previous.interfaces}
        current = {item.name: item for item in self.interfaces}
        missing = sorted(set(old) - set(current))
        major_changes = sorted(name for name in old.keys() & current.keys()
                               if _semver(old[name].version, operation)[0] != _semver(current[name].version, operation)[0])
        function_changes: list[str] = []
        for name in sorted(old.keys() & current.keys()):
            old_functions = old[name].functions
            new_functions = current[name].functions
            for function_name in sorted(set(old_functions) - set(new_functions)):
                function_changes.append(f"{name}.{function_name}:removed")
            for function_name in sorted(old_functions.keys() & new_functions.keys()):
                if _plain(old_functions[function_name]) != _plain(new_functions[function_name]):
                    function_changes.append(f"{name}.{function_name}:signature")
        return _freeze({"compatible": not missing and not major_changes and not function_changes,
                        "missing": missing, "majorChanges": major_changes,
                        "functionChanges": function_changes})

    def snapshot(self) -> bytes:
        return _canonical(self.inspect())


class _CapabilityAdapter:
    KIND = ""

    @classmethod
    def fromCapability(cls, capability: Capability) -> "_CapabilityAdapter":
        return cls(_capability(capability, cls.KIND, f"{cls.__name__}.fromCapability"))

    def __init__(self, capability: Capability) -> None:
        self.capability = capability


class SandboxedFs(_CapabilityAdapter):
    KIND = "fs.read"


class SandboxedClock(_CapabilityAdapter):
    KIND = "clock.monotonic"


class SandboxedRandom(_CapabilityAdapter):
    KIND = "random.seeded"


class SandboxedConsole(_CapabilityAdapter):
    KIND = "console.write"


class WasmHost:
    def __init__(self, bindings: Mapping[str, _CapabilityAdapter], budgets: Mapping[str, Any]) -> None:
        operation = "WasmHost.new"
        checked_bindings = dict(_mapping(bindings, operation, "bindings"))
        if not all(isinstance(value, _CapabilityAdapter) for value in checked_bindings.values()):
            _fail("BINDING", operation, "bindings must be sandbox adapters")
        values = dict(_mapping(budgets, operation, "budgets"))
        _fields(values, {"calls", "inputBytes"}, operation)
        self.call_budget = _integer(values.get("calls", 1), operation, "calls", 1, MAX_CALLS)
        self.input_budget = _integer(values.get("inputBytes", 1024), operation, "inputBytes", 0, MAX_INPUT_BYTES)
        self.bindings = MappingProxyType(checked_bindings)
        self._calls = 0
        self._cancelled = 0
        self._input_bytes = 0

    @staticmethod
    def new(bindings: Mapping[str, _CapabilityAdapter], budgets: Mapping[str, Any]) -> "WasmHost":
        return WasmHost(bindings, budgets)

    def run(self, component: Component, input_: Any) -> ComponentInstance:
        operation = "host.run"
        if not isinstance(component, Component):
            _fail("COMPONENT", operation, "component required")
        encoded = _canonical(input_)
        if self._calls >= self.call_budget or len(encoded) > self.input_budget:
            _fail("BUDGET", operation, "call or input budget exceeded")
        caps = tuple(adapter.capability for adapter in self.bindings.values())
        expected = {f"{key[0]}.{key[1]}" for key in component.module._imports}
        imports = {name: self.bindings.get(name) for name in expected}
        if any(value is None for value in imports.values()):
            _fail("IMPORT-BINDING", operation, "host binding missing")
        instance = component.instantiate(imports, caps)
        self._calls += 1
        self._input_bytes += len(encoded)
        return instance

    def cancel(self, instance: ComponentInstance) -> None:
        if not isinstance(instance, ComponentInstance) or instance.cancelled:
            _fail("INSTANCE", "host.cancel", "live instance required")
        instance.cancelled = True
        self._cancelled += 1

    def metrics(self) -> Mapping[str, int]:
        return _freeze({"calls": self._calls, "cancelled": self._cancelled,
                        "inputBytes": self._input_bytes})


@dataclass(frozen=True)
class BpfMap:
    kind: str
    key_type: str
    value_type: str
    limits: Mapping[str, int]

    @staticmethod
    def define(kind: str, keyType: str, valueType: str, limits: Mapping[str, Any]) -> "BpfMap":
        operation = "BpfMap.define"
        if kind not in {"array", "hash"} or keyType not in {"u32", "u64"} or valueType not in {"u32", "u64"}:
            _fail("BPF-MAP", operation, "unsupported map declaration")
        values = dict(_mapping(limits, operation, "limits"))
        _fields(values, {"entries"}, operation)
        entries = _integer(values.get("entries"), operation, "entries", 1, MAX_BPF_MAP_ENTRIES)
        return BpfMap(kind, keyType, valueType, _freeze({"entries": entries}))


class BpfProgram:
    def __init__(self, kind: str, target: str) -> None:
        operation = "BpfProgram.new"
        if kind not in {"socket-filter", "tracepoint"} or target != "ebpf-el8-local":
            _fail("BPF-TARGET", operation, "unsupported kind or target")
        self.kind = kind
        self.target = target
        self.instructions: tuple[Mapping[str, Any], ...] = (
            _freeze({"op": "mov", "dst": 0, "imm": 0}), _freeze({"op": "exit"}),
        )
        self.maps: tuple[BpfMap, ...] = ()
        self._hook: str | None = None
        self._verified = False
        self._loaded = False
        self._events: list[Mapping[str, Any]] = []

    @staticmethod
    def new(kind: str, target: str) -> "BpfProgram":
        return BpfProgram(kind, target)

    def configure(self, instructions: Sequence[Mapping[str, Any]], maps: Sequence[BpfMap] = ()) -> "BpfProgram":
        operation = "BpfProgram.configure"
        checked = tuple(_sequence(instructions, operation, "instructions"))
        checked_maps = tuple(_sequence(maps, operation, "maps"))
        if not checked or len(checked) > MAX_BPF_INSTRUCTIONS or not all(isinstance(item, Mapping) for item in checked):
            _fail("BPF-INSTRUCTIONS", operation, "bounded instruction sequence required")
        if not all(isinstance(item, BpfMap) for item in checked_maps):
            _fail("BPF-MAP", operation, "maps must be BpfMap values")
        self.instructions = tuple(_freeze(item) for item in checked)
        self.maps = checked_maps
        self._verified = False
        return self

    def attach(self, hook: str, capability: Capability) -> "BpfProgram":
        _capability(capability, "bpf.attach", "program.attach")
        checked = _text(hook, "program.attach", "hook", 256)
        if self._hook is not None:
            _fail("BPF-ATTACH", "program.attach", "already attached")
        self._hook = checked
        self._events.append(_freeze({"event": "attached", "hook": checked}))
        return self

    def detach(self) -> None:
        if self._hook is None:
            _fail("BPF-ATTACH", "program.detach", "not attached")
        self._events.append(_freeze({"event": "detached", "hook": self._hook}))
        self._hook = None

    def verify(self) -> Mapping[str, Any]:
        operation = "program.verify"
        allowed = {"mov", "add", "map_lookup", "jump_if", "exit"}
        if self.instructions[-1].get("op") != "exit":
            _fail("BPF-EXIT", operation, "last instruction must exit")
        for index, instruction in enumerate(self.instructions):
            if set(instruction) - {"op", "dst", "src", "imm", "target", "map"}:
                _fail("BPF-FIELD", operation, "unknown instruction field")
            if instruction.get("op") not in allowed:
                _fail("BPF-OPCODE", operation, "unsupported instruction")
            if "dst" in instruction:
                _integer(instruction["dst"], operation, "dst", 0, 10)
            if "src" in instruction:
                _integer(instruction["src"], operation, "src", 0, 10)
            if "imm" in instruction:
                _integer(instruction["imm"], operation, "imm", -(1 << 31), (1 << 31) - 1)
            if instruction.get("op") == "jump_if":
                target = _integer(instruction.get("target"), operation, "target", index + 1, len(self.instructions) - 1)
                if target <= index:
                    _fail("BPF-LOOP", operation, "backward jumps are forbidden")
            if instruction.get("op") == "map_lookup":
                map_index = _integer(instruction.get("map"), operation, "map", 0, max(0, len(self.maps) - 1))
                if not self.maps or map_index >= len(self.maps):
                    _fail("BPF-MAP", operation, "map index is unavailable")
        self._verified = True
        report = {"instructions": len(self.instructions), "maps": len(self.maps),
                  "forwardOnly": True, "kernelLoad": "NOT_EXECUTED"}
        self._events.append(_freeze({"event": "verified", **report}))
        return _freeze(report)

    def load(self, capability: Capability) -> Mapping[str, Any]:
        _capability(capability, "bpf.load", "program.load")
        if not self._verified:
            _fail("BPF-UNVERIFIED", "program.load", "verify before load")
        self._loaded = True
        result = _freeze({"loaded": "SIMULATED_LOCAL_ONLY", "kernelLoad": "NOT_EXECUTED"})
        self._events.append(_freeze({"event": "loaded", **_plain(result)}))
        return result

    def events(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(self._events)

    def emit(self) -> bytes:
        if not self._verified:
            _fail("BPF-UNVERIFIED", "BpfProgram.emit", "verify before emit")
        maps = [{"kind": item.kind, "keyType": item.key_type,
                 "valueType": item.value_type, "limits": item.limits}
                for item in self.maps]
        immediate = int(_digest([self.kind, self.target, self.instructions, maps])[:8], 16)
        return b"\xb7\x00\x00\x00" + struct.pack("<I", immediate) + b"\x95\x00\x00\x00\x00\x00\x00\x00"


class EdgeFunction:
    def __init__(self, function: Callable[[Any], Any], interface: Interface) -> None:
        operation = "EdgeFunction.from"
        if not isinstance(interface, Interface):
            _fail("INTERFACE", operation, "Interface required")
        self.function = function
        self.function_id = _function_identity(function, operation)
        self.interface = interface
        self._budget = {"calls": 1, "inputBytes": 1024, "stateBytes": 0}
        self._store: Capability | None = None
        self._calls = 0
        self._input_bytes = 0
        self._last_digest: str | None = None

    @staticmethod
    def fromFunction(function: Callable[[Any], Any], interface: Interface) -> "EdgeFunction":
        return EdgeFunction(function, interface)

    def handle(self, event: Any) -> Any:
        operation = "edge.handle"
        encoded = _canonical(event)
        if self._calls >= self._budget["calls"] or len(encoded) > self._budget["inputBytes"]:
            _fail("EDGE-BUDGET", operation, "call or input budget exceeded")
        result = self.function(_freeze(event))
        _canonical(result)
        self._calls += 1
        self._input_bytes += len(encoded)
        self._last_digest = _digest(result)
        return result

    def budget(self, options: Mapping[str, Any]) -> "EdgeFunction":
        operation = "edge.budget"
        values = dict(_mapping(options, operation, "options"))
        _fields(values, {"calls", "inputBytes", "stateBytes"}, operation)
        self._budget = {
            "calls": _integer(values.get("calls", 1), operation, "calls", 1, MAX_CALLS),
            "inputBytes": _integer(values.get("inputBytes", 1024), operation, "inputBytes", 0, MAX_INPUT_BYTES),
            "stateBytes": _integer(values.get("stateBytes", 0), operation, "stateBytes", 0, MAX_EDGE_STATE_BYTES),
        }
        return self

    def state(self, storeCapability: Capability) -> "EdgeFunction":
        self._store = _capability(storeCapability, "edge.state", "edge.state")
        if self._budget["stateBytes"] == 0:
            _fail("EDGE-STATE", "edge.state", "positive stateBytes budget required")
        return self

    def snapshot(self) -> bytes:
        return _canonical({"function": self.function_id, "interface": [self.interface.name, self.interface.version],
                           "budget": self._budget, "store": self._store.identity if self._store else None,
                           "metrics": self.metrics()})

    def runLocal(self, event: Any) -> Mapping[str, Any]:
        result = self.handle(event)
        return _freeze({"result": result, "execution": "LOCAL_DETERMINISTIC",
                        "network": False, "digest": self._last_digest})

    def metrics(self) -> Mapping[str, Any]:
        return _freeze({"calls": self._calls, "inputBytes": self._input_bytes,
                        "lastDigest": self._last_digest})

    def verifyPolicy(self, policy: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "edge.verifyPolicy"
        values = dict(_mapping(policy, operation, "policy"))
        _fields(values, {"capabilities", "network", "maxCalls"}, operation)
        capabilities = set(_sequence(values.get("capabilities", ()), operation, "capabilities"))
        if values.get("network", False) is not False or not capabilities <= KNOWN_CAPABILITIES:
            _fail("EDGE-POLICY", operation, "network or unknown capability denied")
        maximum = _integer(values.get("maxCalls", self._budget["calls"]), operation, "maxCalls", 1, MAX_CALLS)
        allowed = maximum >= self._budget["calls"] and (self._store is None or "edge.state" in capabilities)
        return _freeze({"allowed": allowed, "network": False,
                        "capabilities": sorted(capabilities)})


class PortableArtifact:
    def __init__(self, target: Target, module: WasmModule, program: BpfProgram,
                 edge: EdgeFunction) -> None:
        operation = "PortableArtifact.new"
        if not isinstance(target, Target) or not isinstance(module, WasmModule) or not isinstance(program, BpfProgram) or not isinstance(edge, EdgeFunction):
            _fail("ARTIFACT", operation, "target, module, program and edge are required")
        self.target = target
        self.module = module
        self.program = program
        self.edge = edge
        self._components = {"module.wasm": module.emit(target), "program.bpf": program.emit(),
                            "edge.snapshot": edge.snapshot()}
        self._manifest = self._make_manifest()

    def _make_manifest(self) -> Mapping[str, Any]:
        entries = [{"name": name, "bytes": len(data), "sha256": _digest(data)}
                   for name, data in sorted(self._components.items())]
        return _freeze({"format": "NEBO-PORTABLE-ARTIFACT-v1", "target": self.target.architecture,
                        "components": entries, "network": False,
                        "kernelLoad": "NOT_EXECUTED", "wasmRuntime": "STRUCTURAL_LOCAL"})

    def manifest(self) -> Mapping[str, Any]:
        return self._manifest

    def verify(self) -> Mapping[str, Any]:
        expected = {entry["name"]: entry for entry in self._manifest["components"]}
        valid = (set(expected) == set(self._components) and
                 all(entry["bytes"] == len(self._components[name]) and
                     entry["sha256"] == _digest(self._components[name])
                     for name, entry in expected.items()))
        if not valid:
            _fail("ARTIFACT-DIGEST", "artifact.verify", "component mismatch")
        return _freeze({"valid": True, "components": len(expected), "network": False})

    def reproducibilityReport(self) -> Mapping[str, Any]:
        bundle = b"".join(self._components[name] for name in sorted(self._components))
        return _freeze({"reproducible": True, "bundleSha256": _digest(bundle),
                        "canonicalManifestSha256": _digest(_canonical(self._manifest))})

    def capabilityReport(self) -> Mapping[str, Any]:
        imports = sorted({value["capability"] for value in self.module._imports.values()})
        return _freeze({"required": imports, "network": False,
                        "kernelLoad": "NOT_EXECUTED", "ambientAuthority": False})

    def conformance(self, target: Target) -> Mapping[str, Any]:
        if not isinstance(target, Target):
            _fail("TARGET", "artifact.conformance", "Target required")
        compatible = target.architecture == self.target.architecture and target.options == self.target.options
        return _freeze({"compatible": compatible, "target": target.architecture,
                        "wasmStructural": self._components["module.wasm"].startswith(b"\0asm\x01\0\0\0"),
                        "bpfStaticSubset": len(self._components["program.bpf"]) == 16})


# ``from`` is a Nebo surface and a Python keyword; make it available to tools
# that resolve the public name through reflection.
setattr(EdgeFunction, "from", EdgeFunction.fromFunction)


__all__ = [
    "BpfMap", "BpfProgram", "Capability", "Component", "EdgeFunction", "Interface",
    "PortableArtifact", "PortableError", "SandboxedClock", "SandboxedConsole",
    "SandboxedFs", "SandboxedRandom", "Target", "WasmHost", "WasmModule",
]
