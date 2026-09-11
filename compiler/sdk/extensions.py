"""Bounded plugins, explicit FFI, and offline distributed execution for G026.

This reference profile loads only local JSON plugin manifests, executes a closed
set of synthetic operations, and models a deterministic in-process cluster.  It
does not dlopen arbitrary libraries, create sockets, ship code, invoke a shell,
and does not claim a strong operating-system sandbox or general consensus.
"""

from __future__ import annotations

import contextvars
import builtins
import hashlib
import hmac
import json
import os
import errno
import stat
import types
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Callable, Mapping, Sequence
from compiler.sdk.package_manager import open_directory


PLUGIN_SCHEMA = 1
PLUGIN_ABI = 1
MAX_MANIFEST_BYTES = 65_536
MAX_EXPORTS = 64
MAX_TRUST_ENTRIES = 32
MAX_MEMORY = 64 * 1024 * 1024
MAX_CALLS = 4096
MAX_DURATION = 1_000_000
MAX_NODES = 16
MAX_TASKS = 64
MAX_PARTITIONS = 1024
MAX_REPLICAS = 3
MAX_RETRIES = 8
MAX_RETRY_DELAY = 1024
KNOWN_CAPABILITIES = frozenset({"compute", "buffer", "callback", "storage", "checkpoint"})
SAFE_TYPES = frozenset({"Void", "Bool", "Int", "Text", "Bytes"})
_BUILTIN_OPERATIONS = frozenset({"add", "multiply", "concat", "identity", "sumBytes", "xor"})


class ExtensionError(ValueError):
    """Stable fail-closed error for the bounded G026 profile."""

    def __init__(self, code: str, operation: str, message: str) -> None:
        super().__init__(f"{code}: {operation}: {message}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, message: str) -> None:
    raise ExtensionError(code, operation, message)


def _text(value: Any, operation: str, name: str) -> str:
    if not isinstance(value, str) or not value:
        _fail("INVALID_TEXT", operation, f"{name} must be non-empty text")
    if len(value.encode("utf-8")) > 8192:
        _fail("LIMIT_EXCEEDED", operation, f"{name} exceeds the text budget")
    return value


def _integer(value: Any, operation: str, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        _fail("INVALID_INTEGER", operation, f"{name} must be an integer")
    if value < minimum or value > maximum:
        _fail("LIMIT_EXCEEDED", operation, f"{name} must be in [{minimum}, {maximum}]")
    return value


def _mapping(value: Any, operation: str, name: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail("INVALID_MAPPING", operation, f"{name} must be a mapping")
    return value


def _known_fields(value: Mapping[str, Any], allowed: set[str], operation: str, name: str) -> None:
    unknown = set(value) - allowed
    if unknown:
        _fail("UNKNOWN_FIELD", operation, f"{name} contains unknown fields")


def _sequence(value: Any, operation: str, name: str) -> Sequence[Any]:
    if isinstance(value, (str, bytes, bytearray, memoryview)) or not isinstance(value, Sequence):
        _fail("INVALID_SEQUENCE", operation, f"{name} must be a sequence")
    return value


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(inner) for key, inner in value.items()})
    if isinstance(value, (list, tuple, set, frozenset)):
        return tuple(_freeze(inner) for inner in value)
    return value


def _thaw(value: Any) -> Any:
    if isinstance(value, (bytes, bytearray, memoryview)):
        return {"$bytes": bytes(value).hex()}
    if isinstance(value, Mapping):
        return {str(key): _thaw(inner) for key, inner in value.items()}
    if isinstance(value, (list, tuple)):
        return [_thaw(inner) for inner in value]
    if isinstance(value, (set, frozenset)):
        return sorted(_thaw(inner) for inner in value)
    return value


def _canonical(value: Any, operation: str = "canonicalize") -> bytes:
    try:
        return json.dumps(_thaw(value), sort_keys=True, separators=(",", ":"), ensure_ascii=True, allow_nan=False).encode("ascii")
    except (TypeError, ValueError):
        _fail("NON_CANONICAL_VALUE", operation, "value must be canonical JSON")


def _digest(value: Any) -> str:
    return hashlib.sha256(_canonical(value)).hexdigest()


def _capabilities(value: Any, operation: str, name: str = "capabilities") -> frozenset[str]:
    if isinstance(value, (set, frozenset)):
        items = tuple(sorted(value, key=repr))
    else:
        items = _sequence(value, operation, name)
    names = tuple(_text(item, operation, name) for item in items)
    result = frozenset(names)
    if len(result) != len(names):
        _fail("DUPLICATE_CAPABILITY", operation, f"{name} contains duplicates")
    unknown = result - KNOWN_CAPABILITIES
    if unknown:
        _fail("UNKNOWN_CAPABILITY", operation, "unsupported capability")
    return result


def _validate_value(value: Any, type_name: str, operation: str) -> Any:
    if type_name == "Void":
        if value is not None:
            _fail("TYPE_MISMATCH", operation, "Void requires no value")
    elif type_name == "Bool":
        if not isinstance(value, bool):
            _fail("TYPE_MISMATCH", operation, "Bool argument required")
    elif type_name == "Int":
        if isinstance(value, bool) or not isinstance(value, int) or not -(1 << 63) <= value < (1 << 63):
            _fail("TYPE_MISMATCH", operation, "signed 64-bit Int argument required")
    elif type_name == "Text":
        _text(value, operation, "argument")
    elif type_name == "Bytes":
        if not isinstance(value, (bytes, bytearray, memoryview)):
            _fail("TYPE_MISMATCH", operation, "Bytes argument required")
        value = bytes(value)
    else:
        _fail("UNSAFE_FOREIGN_TYPE", operation, "unsupported foreign type")
    return value


def _signature(value: Any, operation: str) -> Mapping[str, Any]:
    item = dict(_mapping(value, operation, "signature"))
    if set(item) - {"args", "returns", "capability"}:
        _fail("UNKNOWN_FIELD", operation, "signature contains an unknown field")
    args = tuple(_text(arg, operation, "signature.args") for arg in _sequence(item.get("args", ()), operation, "signature.args"))
    returns = _text(item.get("returns", "Void"), operation, "signature.returns")
    capability = _text(item.get("capability"), operation, "signature.capability")
    if len(args) > 6 or any(arg not in SAFE_TYPES - {"Void"} for arg in args) or returns not in SAFE_TYPES:
        _fail("UNSAFE_FOREIGN_TYPE", operation, "signature is outside the safe bounded set")
    if capability not in KNOWN_CAPABILITIES:
        _fail("UNKNOWN_CAPABILITY", operation, "signature capability is unsupported")
    return _freeze({"args": args, "returns": returns, "capability": capability})


def _behavior_matches(name: str, signature: Mapping[str, Any]) -> bool:
    args = tuple(signature["args"])
    returns = signature["returns"]
    if name in {"add", "multiply", "xor"}:
        return args == ("Int", "Int") and returns == "Int"
    if name == "concat":
        return args == ("Text", "Text") and returns == "Text"
    if name == "identity":
        return len(args) == 1 and returns == args[0]
    if name == "sumBytes":
        return args == ("Bytes",) and returns == "Int"
    return False


def _code_constant(value: Any, operation: str) -> Any:
    if isinstance(value, types.CodeType):
        _fail("INVALID_FUNCTION", operation, "nested executable code is outside the bounded task profile")
    if isinstance(value, tuple):
        return tuple(_code_constant(item, operation) for item in value)
    if value is None or isinstance(value, (bool, int, float, str, bytes)):
        _canonical(value, operation)
        return value
    _fail("INVALID_FUNCTION", operation, f"unsupported code constant {type(value).__name__}")


def _function_identity(function: Callable[[Any], Any], operation: str) -> str:
    code = getattr(function, "__code__", None)
    if code is None or code.co_argcount != 1 or code.co_kwonlyargcount or code.co_flags & 0x2AC:
        _fail("INVALID_FUNCTION", operation, "function must be a unary non-generator local function")
    if code.co_names:
        _fail("INVALID_FUNCTION", operation, "task function cannot depend on ambient global names")
    closure = tuple(_code_constant(cell.cell_contents, operation) for cell in (function.__closure__ or ()))
    defaults = tuple(_code_constant(value, operation) for value in (function.__defaults__ or ()))
    identity = {
        "bytecode": code.co_code.hex(),
        "constants": tuple(_code_constant(value, operation) for value in code.co_consts),
        "variables": code.co_varnames[: code.co_nlocals],
        "closureNames": code.co_freevars,
        "closureValues": closure,
        "defaults": defaults,
    }
    return _digest(identity)


class PluginManifest:
    """Validated immutable local plugin identity and ABI descriptor."""

    def __init__(self, path: Path, document: Mapping[str, Any], raw_digest: str) -> None:
        operation = "PluginManifest.load"
        allowed = {
            "schema", "identity", "abiVersion", "target", "capabilities", "exports",
            "behavior", "memoryLimit", "callLimit", "keyId", "signature",
        }
        unknown = set(document) - allowed
        if unknown:
            _fail("UNKNOWN_FIELD", operation, "unknown manifest fields")
        if _integer(document.get("schema"), operation, "schema", 1, 1) != PLUGIN_SCHEMA:
            _fail("SCHEMA_MISMATCH", operation, "unsupported manifest schema")
        self.identity = _text(document.get("identity"), operation, "identity")
        self._abi_version = _integer(document.get("abiVersion"), operation, "abiVersion", 1, PLUGIN_ABI)
        if document.get("target") != "x86_64-linux-static":
            _fail("TARGET_MISMATCH", operation, "only the local static x86-64 target is supported")
        self.capabilities = _capabilities(document.get("capabilities", ()), operation)
        exports = dict(_mapping(document.get("exports"), operation, "exports"))
        if not exports or len(exports) > MAX_EXPORTS:
            _fail("EXPORT_LIMIT", operation, "exports must contain between 1 and 64 entries")
        checked_exports: dict[str, Mapping[str, Any]] = {}
        for name, signature in exports.items():
            checked_exports[_text(name, operation, "export name")] = _signature(signature, operation)
        behavior = dict(_mapping(document.get("behavior"), operation, "behavior"))
        if set(behavior) != set(checked_exports):
            _fail("BEHAVIOR_MISMATCH", operation, "every export needs exactly one local behavior")
        checked_behavior: dict[str, str] = {}
        for name, behavior_name in behavior.items():
            behavior_name = _text(behavior_name, operation, "behavior")
            if behavior_name not in _BUILTIN_OPERATIONS:
                _fail("UNSUPPORTED_BEHAVIOR", operation, "unsupported manifest behavior")
            if not _behavior_matches(behavior_name, checked_exports[name]):
                _fail("BEHAVIOR_SIGNATURE", operation, "behavior and signature disagree")
            checked_behavior[name] = behavior_name
        if not self.capabilities.issuperset(signature["capability"] for signature in checked_exports.values()):
            _fail("CAPABILITY_MISMATCH", operation, "export capability is absent from the manifest")
        self.memory_limit = _integer(document.get("memoryLimit"), operation, "memoryLimit", 1, MAX_MEMORY)
        self.call_limit = _integer(document.get("callLimit"), operation, "callLimit", 1, MAX_CALLS)
        self.key_id = _text(document.get("keyId"), operation, "keyId")
        signature_text = _text(document.get("signature"), operation, "signature")
        if len(signature_text) != 64 or any(character not in "0123456789abcdef" for character in signature_text):
            _fail("INVALID_SIGNATURE", operation, "signature must be lowercase HMAC-SHA256")
        self.signature = signature_text
        self.exports_map = MappingProxyType(checked_exports)
        self.behavior = MappingProxyType(checked_behavior)
        self.path = path
        self.digest = raw_digest
        self._signed_document = MappingProxyType({str(key): _freeze(value) for key, value in document.items() if key != "signature"})

    @classmethod
    def load(cls, path: str | Path) -> "PluginManifest":
        operation = "PluginManifest.load"
        if not isinstance(path, (str, Path)):
            _fail("INVALID_PATH", operation, "path must be text or Path")
        candidate = Path(path).absolute()
        if '..' in candidate.parts:
            _fail("PATH_DENIED", operation, "parent traversal is forbidden")
        # Every directory and the leaf are opened without following symlinks.
        # The file identity, type, size and bytes come from the same descriptor.
        try:
            parent = open_directory(candidate.parent)
            try:
                fd = os.open(candidate.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent)
                try:
                    info = os.fstat(fd)
                    if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                        _fail("MANIFEST_UNAVAILABLE", operation, "single-link regular manifest required")
                    if not 2 <= info.st_size <= MAX_MANIFEST_BYTES:
                        _fail("MANIFEST_SIZE", operation, "manifest exceeds bounded size profile")
                    with os.fdopen(fd, "rb", closefd=False) as stream:
                        raw = stream.read(MAX_MANIFEST_BYTES + 1)
                    if not 2 <= len(raw) <= MAX_MANIFEST_BYTES:
                        _fail("MANIFEST_SIZE", operation, "manifest changed outside bounded size profile")
                finally:
                    os.close(fd)
            finally:
                os.close(parent)
        except OSError as error:
            if error.errno in (errno.ELOOP, errno.ENOTDIR):
                _fail("SYMLINK_DENIED", operation, "linked manifest path denied")
            _fail("MANIFEST_UNAVAILABLE", operation, "manifest is unavailable")
        depth = 0
        quoted = escaped = False
        for byte in raw:
            if quoted:
                if escaped: escaped = False
                elif byte == 92: escaped = True
                elif byte == 34: quoted = False
            elif byte == 34: quoted = True
            elif byte in (91, 123):
                depth += 1
                if depth > 64:
                    _fail("MALFORMED_MANIFEST", operation, "JSON nesting limit")
            elif byte in (93, 125): depth -= 1
        def reject_duplicate_keys(pairs):
            result = {}
            for key, value in pairs:
                if key in result:
                    _fail("DUPLICATE_FIELD", operation, "duplicate manifest field")
                result[key] = value
            return result
        def reject_constant(_):
            _fail("MALFORMED_MANIFEST", operation, "nonfinite JSON value")
        try:
            document = json.loads(raw.decode("utf-8"), object_pairs_hook=reject_duplicate_keys,
                                  parse_constant=reject_constant)
        except (UnicodeError, json.JSONDecodeError, RecursionError):
            _fail("MALFORMED_MANIFEST", operation, "manifest must be bounded UTF-8 JSON")
        if not isinstance(document, dict):
            _fail("INVALID_MANIFEST", operation, "manifest root must be an object")
        return cls(candidate, document, hashlib.sha256(raw).hexdigest())

    def verifySignature(self, trustStore: Mapping[str, Any]) -> bool:
        operation = "plugin.verifySignature"
        store = _mapping(trustStore, operation, "trustStore")
        if self.key_id not in store:
            _fail("UNTRUSTED_SIGNER", operation, "manifest key is absent from the trust store")
        secret = store[self.key_id]
        if isinstance(secret, str):
            secret = secret.encode("utf-8")
        if not isinstance(secret, bytes) or not secret:
            _fail("INVALID_TRUST_KEY", operation, "trust key must be non-empty bytes or text")
        expected = hmac.new(secret, _canonical(self._signed_document), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, self.signature):
            _fail("SIGNATURE_MISMATCH", operation, "manifest signature verification failed")
        return True


class Plugin:
    """Authorized local manifest plus a closed deterministic implementation."""

    def __init__(self, manifest: PluginManifest) -> None:
        self.manifest = manifest
        self._initialized = False
        self._shutdown = False
        self._context: Mapping[str, Any] | None = None
        self._calls = 0

    @classmethod
    def load(cls, path: str | Path, policy: Mapping[str, Any]) -> "Plugin":
        operation = "Plugin.load"
        item = _mapping(policy, operation, "policy")
        _known_fields(item, {"allowedRoots", "allowedDigests", "abiVersion", "capabilities", "requireSignature", "trustStore"}, operation, "policy")
        if not isinstance(path, (str, Path)):
            _fail("INVALID_PATH", operation, "path must be text or Path")
        roots = _sequence(item.get("allowedRoots", ()), operation, "policy.allowedRoots")
        if not roots:
            _fail("CAPABILITY_DENIED", operation, "at least one explicit manifest root is required")
        if len(roots) > MAX_TRUST_ENTRIES:
            _fail("TRUST_LIMIT", operation, "allowed root budget is exhausted")
        source_path = Path(path)
        if source_path.is_symlink():
            _fail("SYMLINK_DENIED", operation, "plugin manifest symlinks are not allowed")
        candidate = source_path.absolute()
        if ".." in candidate.parts:
            _fail("PATH_DENIED", operation, "parent traversal is forbidden")
        resolved_roots: list[Path] = []
        for root in roots:
            if not isinstance(root, (str, Path)):
                _fail("INVALID_PATH", operation, "allowed roots must be text or Path")
            checked_root = Path(root).absolute()
            if ".." in checked_root.parts:
                _fail("PATH_DENIED", operation, "parent traversal is forbidden")
            resolved_roots.append(checked_root)
        if not any(candidate == root or root in candidate.parents for root in resolved_roots):
            _fail("PATH_DENIED", operation, "manifest is outside the allowed roots")
        manifest = PluginManifest.load(candidate)
        if manifest._abi_version != _integer(item.get("abiVersion", PLUGIN_ABI), operation, "policy.abiVersion", 1, PLUGIN_ABI):
            _fail("ABI_MISMATCH", operation, "manifest ABI does not match policy")
        digest_values = _sequence(item.get("allowedDigests", ()), operation, "policy.allowedDigests")
        if not digest_values or len(digest_values) > MAX_TRUST_ENTRIES:
            _fail("TRUST_LIMIT", operation, "digest allowlist must contain 1 to 32 entries")
        allowed_digests = frozenset(_text(value, operation, "policy.allowedDigests") for value in digest_values)
        if any(len(value) != 64 or any(character not in "0123456789abcdef" for character in value) for value in allowed_digests):
            _fail("INVALID_DIGEST", operation, "allowed digests must be lowercase SHA-256 text")
        if manifest.digest not in allowed_digests:
            _fail("UNTRUSTED_PLUGIN", operation, "manifest digest is not allowlisted")
        allowed_caps = _capabilities(item.get("capabilities", ()), operation, "policy.capabilities")
        if not manifest.capabilities.issubset(allowed_caps):
            _fail("CAPABILITY_DENIED", operation, "manifest requests a capability not granted by policy")
        require_signature = item.get("requireSignature", True)
        if not isinstance(require_signature, bool):
            _fail("INVALID_BOOLEAN", operation, "policy.requireSignature must be Bool")
        if not require_signature:
            _fail("UNSIGNED_DENIED", operation, "the bounded profile cannot disable signature verification")
        manifest.verifySignature(_mapping(item.get("trustStore", {}), operation, "policy.trustStore"))
        return cls(manifest)

    def abiVersion(self) -> int:
        return self.manifest._abi_version

    def exports(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(_freeze({"name": name, **dict(signature)}) for name, signature in sorted(self.manifest.exports_map.items()))

    def initialize(self, context: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "plugin.initialize"
        if self._shutdown:
            _fail("PLUGIN_SHUTDOWN", operation, "a shut down plugin cannot be initialized")
        if self._initialized:
            _fail("ALREADY_INITIALIZED", operation, "plugin is already initialized")
        item = _mapping(context, operation, "context")
        _known_fields(item, {"identity", "capabilities"}, operation, "context")
        granted = _capabilities(item.get("capabilities", ()), operation, "context.capabilities")
        if not self.manifest.capabilities.issubset(granted):
            _fail("CAPABILITY_DENIED", operation, "context lacks a manifest capability")
        self._context = _freeze({"identity": _text(item.get("identity"), operation, "context.identity"), "capabilities": sorted(granted)})
        self._initialized = True
        return _freeze({"identity": self.manifest.identity, "state": "ready", "abiVersion": self.abiVersion()})

    def shutdown(self) -> Mapping[str, Any]:
        operation = "plugin.shutdown"
        if self._shutdown:
            return _freeze({"identity": self.manifest.identity, "state": "shutdown", "calls": self._calls})
        self._shutdown = True
        self._initialized = False
        self._context = None
        return _freeze({"identity": self.manifest.identity, "state": "shutdown", "calls": self._calls})

    def verifySignature(self, trustStore: Mapping[str, Any]) -> bool:
        return self.manifest.verifySignature(trustStore)

    def _invoke(self, name: str, args: Sequence[Any]) -> Any:
        operation = "sandbox.call"
        if not self._initialized or self._shutdown:
            _fail("PLUGIN_NOT_READY", operation, "plugin must be initialized")
        if name not in self.manifest.exports_map:
            _fail("UNKNOWN_EXPORT", operation, "unknown export")
        signature = self.manifest.exports_map[name]
        values = _sequence(args, operation, "args")
        if len(values) != len(signature["args"]):
            _fail("ARITY_MISMATCH", operation, "argument count does not match the signature")
        checked = tuple(_validate_value(value, type_name, operation) for value, type_name in zip(values, signature["args"]))
        behavior = self.manifest.behavior[name]
        if behavior == "add":
            result = checked[0] + checked[1]
        elif behavior == "multiply":
            result = checked[0] * checked[1]
        elif behavior == "concat":
            result = checked[0] + checked[1]
        elif behavior == "identity":
            result = checked[0]
        elif behavior == "sumBytes":
            result = sum(bytes(checked[0]))
        elif behavior == "xor":
            result = checked[0] ^ checked[1]
        else:  # validated at manifest load
            _fail("UNSUPPORTED_BEHAVIOR", operation, "behavior is not implemented")
        result = _validate_value(result, signature["returns"], operation)
        self._calls += 1
        return result


class Sandbox:
    """Deny-first logical process policy; not a strong kernel sandbox claim."""

    def __init__(self, policy: Mapping[str, Any]) -> None:
        operation = "Sandbox.new"
        item = _mapping(policy, operation, "policy")
        _known_fields(item, {"memoryLimit", "timeLimit", "callLimit", "capabilities", "network"}, operation, "policy")
        self._memory_limit = _integer(item.get("memoryLimit", MAX_MEMORY), operation, "policy.memoryLimit", 1, MAX_MEMORY)
        self._time_limit = _integer(item.get("timeLimit", MAX_DURATION), operation, "policy.timeLimit", 1, MAX_DURATION)
        self._call_limit = _integer(item.get("callLimit", MAX_CALLS), operation, "policy.callLimit", 1, MAX_CALLS)
        self._capabilities = _capabilities(item.get("capabilities", ()), operation, "policy.capabilities")
        if item.get("network", "none") != "none":
            _fail("NETWORK_DENIED", operation, "this profile provides no socket authority")
        self._plugin: Plugin | None = None
        self._calls = 0
        self._terminated = False

    @classmethod
    def new(cls, policy: Mapping[str, Any]) -> "Sandbox":
        return cls(policy)

    def _configurable(self, operation: str) -> None:
        if self._terminated:
            _fail("SANDBOX_TERMINATED", operation, "sandbox has terminated")
        if self._plugin is not None:
            _fail("POLICY_SEALED", operation, "sandbox policy is sealed after load")

    def memoryLimit(self, bytes: int) -> "Sandbox":
        self._configurable("sandbox.memoryLimit")
        self._memory_limit = _integer(bytes, "sandbox.memoryLimit", "bytes", 1, MAX_MEMORY)
        return self

    def timeLimit(self, duration: int) -> "Sandbox":
        self._configurable("sandbox.timeLimit")
        self._time_limit = _integer(duration, "sandbox.timeLimit", "duration", 1, MAX_DURATION)
        return self

    def capabilities(self, set: Sequence[str]) -> "Sandbox":
        self._configurable("sandbox.capabilities")
        self._capabilities = _capabilities(set, "sandbox.capabilities")
        return self

    def load(self, plugin: Plugin) -> Mapping[str, Any]:
        operation = "sandbox.load"
        self._configurable(operation)
        if not isinstance(plugin, Plugin):
            _fail("INVALID_PLUGIN", operation, "plugin must be an authorized Plugin")
        if plugin.manifest.memory_limit > self._memory_limit:
            _fail("MEMORY_LIMIT", operation, "plugin memory budget exceeds sandbox policy")
        if not plugin.manifest.capabilities.issubset(self._capabilities):
            _fail("CAPABILITY_DENIED", operation, "sandbox capability set is insufficient")
        result = plugin.initialize({"identity": "g026-sandbox", "capabilities": sorted(self._capabilities)})
        self._plugin = plugin
        return _freeze({"plugin": result["identity"], "state": "loaded", "memoryLimit": self._memory_limit})

    def call(self, export: str, args: Sequence[Any]) -> Any:
        operation = "sandbox.call"
        if self._terminated:
            _fail("SANDBOX_TERMINATED", operation, "sandbox has terminated")
        if self._plugin is None:
            _fail("PLUGIN_NOT_LOADED", operation, "no plugin is loaded")
        name = _text(export, operation, "export")
        if name not in self._plugin.manifest.exports_map:
            _fail("UNKNOWN_EXPORT", operation, "unknown export")
        required = self._plugin.manifest.exports_map[name]["capability"]
        if required not in self._capabilities:
            _fail("CAPABILITY_DENIED", operation, "export capability was not delegated")
        if self._calls >= min(self._call_limit, self._plugin.manifest.call_limit):
            _fail("CALL_LIMIT", operation, "call budget is exhausted")
        encoded = _canonical(args, operation)
        if len(encoded) > self._memory_limit:
            _fail("MEMORY_LIMIT", operation, "encoded call exceeds memory budget")
        logical_cost = len(encoded) + len(name)
        if logical_cost > self._time_limit:
            _fail("TIME_LIMIT", operation, "logical call cost exceeds the duration budget")
        result = self._plugin._invoke(name, args)
        self._calls += 1
        return result

    def terminate(self) -> Mapping[str, Any]:
        if not self._terminated:
            if self._plugin is not None:
                self._plugin.shutdown()
            self._terminated = True
        return _freeze({"state": "terminated", "calls": self._calls})


_LAST_FFI_ERROR: contextvars.ContextVar[Mapping[str, Any] | None] = contextvars.ContextVar("g026_last_ffi_error", default=None)


class _FfiContext:
    def lastError(self) -> Mapping[str, Any] | None:
        return _LAST_FFI_ERROR.get()


ffi = _FfiContext()


_FOREIGN_SYMBOLS: Mapping[str, Mapping[str, Any]] = MappingProxyType({
    "add_i64": _freeze({"args": ("Int", "Int"), "returns": "Int", "capability": "compute", "behavior": "add"}),
    "xor_i64": _freeze({"args": ("Int", "Int"), "returns": "Int", "capability": "compute", "behavior": "xor"}),
    "sum_bytes": _freeze({"args": ("Bytes",), "returns": "Int", "capability": "buffer", "behavior": "sumBytes"}),
})


class ForeignLibrary:
    def __init__(self, path: str) -> None:
        self.path = path

    @classmethod
    def open(cls, path: str) -> "ForeignLibrary":
        operation = "ForeignLibrary.open"
        value = _text(path, operation, "path")
        if value != "nebo://ffi/scalar-v1":
            _fail("LIBRARY_DENIED", operation, "only the certified local Assembly fixture is available")
        return cls(value)

    def symbol(self, name: str, signature: Mapping[str, Any]) -> "ForeignSymbol":
        operation = "library.symbol"
        symbol_name = _text(name, operation, "name")
        if symbol_name not in _FOREIGN_SYMBOLS:
            _fail("UNKNOWN_SYMBOL", operation, f"unknown symbol {symbol_name}")
        requested = _signature(signature, operation)
        actual = _FOREIGN_SYMBOLS[symbol_name]
        if tuple(requested["args"]) != tuple(actual["args"]) or requested["returns"] != actual["returns"] or requested["capability"] != actual["capability"]:
            _fail("SIGNATURE_MISMATCH", operation, "explicit signature does not match the certified symbol")
        return ForeignSymbol(symbol_name, requested, actual["behavior"])


class ForeignSymbol:
    def __init__(self, name: str, signature: Mapping[str, Any], behavior: str) -> None:
        self.name = name
        self.signature = signature
        self.behavior = behavior

    def call(self, args: Sequence[Any]) -> Any:
        operation = "foreign.call"
        try:
            values = _sequence(args, operation, "args")
            if len(values) != len(self.signature["args"]):
                _fail("ARITY_MISMATCH", operation, "argument count does not match signature")
            checked = tuple(_validate_value(value, type_name, operation) for value, type_name in zip(values, self.signature["args"]))
            if self.behavior == "add":
                result = checked[0] + checked[1]
            elif self.behavior == "xor":
                result = checked[0] ^ checked[1]
            elif self.behavior == "sumBytes":
                result = sum(bytes(checked[0]))
            else:
                _fail("UNKNOWN_SYMBOL", operation, "symbol behavior is unavailable")
            result = _validate_value(result, self.signature["returns"], operation)
            _LAST_FFI_ERROR.set(None)
            return result
        except ExtensionError as error:
            _LAST_FFI_ERROR.set(_freeze({"code": error.code, "operation": error.operation, "symbol": self.name}))
            raise


@dataclass(frozen=True)
class ForeignLayout:
    size: int
    alignment: int
    fields: tuple[Mapping[str, Any], ...]
    identity: str


class ForeignType:
    _SIZES = MappingProxyType({"u8": (1, 1), "i32": (4, 4), "i64": (8, 8), "pointer": (8, 8)})

    @classmethod
    def layout(cls, spec: Sequence[Mapping[str, Any]]) -> ForeignLayout:
        operation = "ForeignType.layout"
        fields = _sequence(spec, operation, "spec")
        if not fields or len(fields) > 32:
            _fail("LAYOUT_LIMIT", operation, "layout must contain 1 to 32 fields")
        offset = 0
        max_alignment = 1
        result: list[Mapping[str, Any]] = []
        names: set[str] = set()
        for field in fields:
            item = _mapping(field, operation, "field")
            _known_fields(item, {"name", "type"}, operation, "field")
            name = _text(item.get("name"), operation, "field.name")
            type_name = _text(item.get("type"), operation, "field.type")
            if name in names:
                _fail("DUPLICATE_FIELD", operation, "field names must be unique")
            if type_name not in cls._SIZES:
                _fail("UNSAFE_FOREIGN_TYPE", operation, f"unsupported layout type {type_name}")
            size, alignment = cls._SIZES[type_name]
            offset = (offset + alignment - 1) // alignment * alignment
            result.append(_freeze({"name": name, "type": type_name, "offset": offset, "size": size}))
            names.add(name)
            offset += size
            max_alignment = max(max_alignment, alignment)
        total = (offset + max_alignment - 1) // max_alignment * max_alignment
        frozen = tuple(result)
        return ForeignLayout(total, max_alignment, frozen, _digest({"size": total, "alignment": max_alignment, "fields": frozen}))


class ForeignLifetime:
    def __init__(self, identity: str) -> None:
        self.identity = _text(identity, "ForeignLifetime.new", "identity")
        self.active = True

    def close(self) -> None:
        self.active = False


class ForeignBuffer:
    def __init__(self, view: memoryview, lifetime: ForeignLifetime) -> None:
        self._view = view
        self._lifetime = lifetime

    @classmethod
    def borrow(cls, pointer: Any, length: int, lifetime: ForeignLifetime) -> "ForeignBuffer":
        operation = "ForeignBuffer.borrow"
        if not isinstance(lifetime, ForeignLifetime) or not lifetime.active:
            _fail("INVALID_LIFETIME", operation, "an active explicit lifetime is required")
        if not isinstance(pointer, (bytes, bytearray, memoryview)):
            _fail("INVALID_POINTER", operation, "bounded profile accepts only bytes-like memory")
        view = memoryview(pointer)
        size = _integer(length, operation, "length", 0, MAX_MEMORY)
        if size > len(view):
            _fail("BUFFER_BOUNDS", operation, "borrow length exceeds the backing buffer")
        return cls(view[:size], lifetime)

    def bytes(self) -> bytes:
        if not self._lifetime.active:
            _fail("LIFETIME_ENDED", "foreignBuffer.bytes", "borrowed buffer lifetime has ended")
        return bytes(self._view)


class ForeignCallback:
    def __init__(self, callable_value: Callable[..., Any], signature: Mapping[str, Any]) -> None:
        self._callable = callable_value
        self.signature = signature
        self._active = False

    def call(self, args: Sequence[Any]) -> Any:
        operation = "callback.call"
        if self._active:
            _fail("REENTRANCY_DENIED", operation, "callback reentrancy is denied")
        values = _sequence(args, operation, "args")
        if len(values) != len(self.signature["args"]):
            _fail("ARITY_MISMATCH", operation, "callback argument count does not match")
        checked = tuple(_validate_value(value, type_name, operation) for value, type_name in zip(values, self.signature["args"]))
        self._active = True
        try:
            result = self._callable(*checked)
        except BaseException as error:
            _fail("CALLBACK_FAILURE", operation, type(error).__name__)
        finally:
            self._active = False
        return _validate_value(result, self.signature["returns"], operation)


class Callback:
    @classmethod
    def export(cls, callable: Callable[..., Any], signature: Mapping[str, Any]) -> ForeignCallback:
        operation = "Callback.export"
        if not builtins.callable(callable):
            _fail("INVALID_CALLBACK", operation, "callback must be callable")
        checked = _signature(signature, operation)
        if checked["capability"] != "callback":
            _fail("CAPABILITY_DENIED", operation, "callback signature requires the callback capability")
        return ForeignCallback(callable, checked)


@dataclass(frozen=True, order=True)
class ClusterMember:
    identity: str
    capabilities: tuple[str, ...]
    state: str


class Node:
    def __init__(self, config: Mapping[str, Any]) -> None:
        operation = "NodeRuntime.start"
        item = _mapping(config, operation, "config")
        _known_fields(item, {"identity", "protocolVersion", "authToken", "maxTasks", "capabilities"}, operation, "config")
        self.identity = _text(item.get("identity"), operation, "config.identity")
        self.protocol_version = _integer(item.get("protocolVersion"), operation, "config.protocolVersion", 1, 1)
        self.auth_token = _text(item.get("authToken"), operation, "config.authToken")
        self.max_tasks = _integer(item.get("maxTasks", MAX_TASKS), operation, "config.maxTasks", 1, MAX_TASKS)
        self._authorized_capabilities = _capabilities(item.get("capabilities", ()), operation, "config.capabilities")
        self.capability_set = self._authorized_capabilities
        self.state = "ready"
        self.inflight = 0

    def advertise(self, capabilities: Sequence[str]) -> Mapping[str, Any]:
        operation = "node.advertise"
        if self.state != "ready":
            _fail("NODE_NOT_READY", operation, "only a ready node can advertise")
        advertised = _capabilities(capabilities, operation)
        if not advertised.issubset(self._authorized_capabilities):
            _fail("CAPABILITY_DENIED", operation, "advertisement cannot exceed node authorization")
        self.capability_set = advertised
        return _freeze({"identity": self.identity, "capabilities": sorted(self.capability_set), "protocolVersion": self.protocol_version})

    def shutdown(self) -> Mapping[str, Any]:
        if self.state != "shutdown":
            self.state = "draining" if self.inflight else "shutdown"
        return _freeze({"identity": self.identity, "state": self.state, "inflight": self.inflight})


class NodeRuntime:
    @classmethod
    def start(cls, config: Mapping[str, Any]) -> Node:
        return Node(config)


class Cluster:
    def __init__(self, nodes: Sequence[Node]) -> None:
        self._nodes = tuple(sorted(nodes, key=lambda node: node.identity))
        self._executions: dict[str, RemoteExecution] = {}
        self._task_counter = 0

    @classmethod
    def connect(cls, seedNodes: Sequence[Node]) -> "Cluster":
        operation = "Cluster.connect"
        nodes = tuple(_sequence(seedNodes, operation, "seedNodes"))
        if not nodes or len(nodes) > MAX_NODES or any(not isinstance(node, Node) for node in nodes):
            _fail("INVALID_SEEDS", operation, "cluster requires 1 to 16 local Node values")
        if len({node.identity for node in nodes}) != len(nodes):
            _fail("DUPLICATE_NODE", operation, "node identities must be unique")
        if any(node.state != "ready" for node in nodes):
            _fail("NODE_NOT_READY", operation, "all seed nodes must be ready")
        if len({(node.protocol_version, node.auth_token) for node in nodes}) != 1:
            _fail("CLUSTER_TRUST_MISMATCH", operation, "protocol and trust identity must match")
        return cls(nodes)

    def members(self) -> tuple[ClusterMember, ...]:
        return tuple(ClusterMember(node.identity, tuple(sorted(node.capability_set)), node.state) for node in self._nodes)

    def health(self) -> Mapping[str, Any]:
        ready = sum(node.state == "ready" for node in self._nodes)
        state = "healthy" if ready == len(self._nodes) else "degraded" if ready else "unavailable"
        return _freeze({"state": state, "ready": ready, "total": len(self._nodes), "protocolVersion": 1})

    def submit(self, task: "RemoteTask", input: Any, policy: Mapping[str, Any]) -> "RemoteExecution":
        operation = "cluster.submit"
        if not isinstance(task, RemoteTask):
            _fail("INVALID_TASK", operation, "task must be a RemoteTask")
        item = _mapping(policy, operation, "policy")
        _known_fields(item, {"retry", "idempotencyKey", "injectedFailures"}, operation, "policy")
        checked_input = _validate_value(input, task.schema["input"], operation)
        input_digest = _digest(checked_input)
        supplied_key = item.get("idempotencyKey")
        key = _text(supplied_key, operation, "policy.idempotencyKey") if supplied_key is not None else _digest({"task": task.idempotencyKey(), "input": input_digest})
        if key in self._executions:
            existing = self._executions[key]
            if existing.task.identity != task.identity or existing.input_digest != input_digest:
                _fail("IDEMPOTENCY_CONFLICT", operation, "key already names different work")
            return existing
        if len(self._executions) >= MAX_TASKS:
            _fail("TASK_LIMIT", operation, "cluster task budget is exhausted")
        required = task.schema["requiredCapability"]
        eligible = tuple(node for node in self._nodes if node.state == "ready" and required in node.capability_set and node.inflight < node.max_tasks)
        if not eligible:
            _fail("NO_ELIGIBLE_NODE", operation, "no ready node owns the task capability")
        selected = eligible[int(input_digest[:8], 16) % len(eligible)]
        retry = item.get("retry", RetryPolicy.exponential({"maxRetries": 0, "baseDelay": 1, "maxDelay": 1, "jitterSeed": 0, "deadline": 1}))
        if not isinstance(retry, RetryPolicy):
            _fail("INVALID_RETRY_POLICY", operation, "policy.retry must be a RetryPolicy")
        failures = tuple(_text(value, operation, "policy.injectedFailures") for value in _sequence(item.get("injectedFailures", ()), operation, "policy.injectedFailures"))
        if any(value not in {"timeout", "node_loss", "reject", "application"} for value in failures):
            _fail("INVALID_FAILURE", operation, "injected failure kind is unsupported")
        if len(failures) > retry.max_retries + 1:
            _fail("FAILURE_LIMIT", operation, "injected failures exceed the bounded attempt count")
        execution = RemoteExecution(task, checked_input, input_digest, key, selected, retry, failures)
        selected.inflight += 1
        self._executions[key] = execution
        self._task_counter += 1
        return execution

    def quorum(self, options: Mapping[str, Any]) -> "QuorumDecision":
        operation = "cluster.quorum"
        item = _mapping(options, operation, "options")
        _known_fields(item, {"replicas", "votes"}, operation, "options")
        replicas = _integer(item.get("replicas", len(self._nodes)), operation, "options.replicas", 1, MAX_REPLICAS)
        votes = _integer(item.get("votes"), operation, "options.votes", 0, replicas)
        if replicas > len(self._nodes):
            _fail("QUORUM_UNAVAILABLE", operation, "replica count exceeds live cluster membership")
        required = replicas // 2 + 1
        return QuorumDecision(votes >= required, votes, required, replicas)

    def rebalance(self) -> Mapping[str, Any]:
        operation = "cluster.rebalance"
        ready = tuple(node.identity for node in self._nodes if node.state == "ready")
        if not ready:
            _fail("NO_ELIGIBLE_NODE", operation, "rebalance requires a ready node")
        assignments = tuple((partition, ready[partition % len(ready)]) for partition in range(min(MAX_PARTITIONS, max(1, self._task_counter))))
        return _freeze({"generation": self._task_counter + 1, "assignments": assignments, "readyNodes": ready})


class RemoteTask:
    def __init__(self, function: Callable[[Any], Any], schema: Mapping[str, Any]) -> None:
        self.function = function
        self.schema = schema
        self.identity = _digest({key: value for key, value in schema.items()})

    @classmethod
    def fromFunction(cls, function: Callable[[Any], Any], schema: Mapping[str, Any]) -> "RemoteTask":
        operation = "RemoteTask.fromFunction"
        if not callable(function):
            _fail("INVALID_FUNCTION", operation, "function must be a local callable")
        item = dict(_mapping(schema, operation, "schema"))
        if set(item) != {"name", "version", "input", "output", "requiredCapability"}:
            _fail("INVALID_SCHEMA", operation, "schema fields must be explicit and complete")
        item["name"] = _text(item["name"], operation, "schema.name")
        item["version"] = _integer(item["version"], operation, "schema.version", 1, (1 << 31) - 1)
        item["input"] = _text(item["input"], operation, "schema.input")
        item["output"] = _text(item["output"], operation, "schema.output")
        item["requiredCapability"] = _text(item["requiredCapability"], operation, "schema.requiredCapability")
        if item["input"] not in SAFE_TYPES - {"Void"} or item["output"] not in SAFE_TYPES or item["requiredCapability"] not in KNOWN_CAPABILITIES:
            _fail("INVALID_SCHEMA", operation, "schema type or capability is unsupported")
        item["implementationDigest"] = _function_identity(function, operation)
        return cls(function, _freeze(item))

    def idempotencyKey(self) -> str:
        return self.identity


@dataclass(frozen=True)
class RemoteFailure:
    kind: str
    retryable: bool
    attempts: int
    node: str


class RemoteExecution:
    def __init__(self, task: RemoteTask, input_value: Any, input_digest: str, key: str, node: Node, retry: "RetryPolicy", failures: Sequence[str]) -> None:
        self.task = task
        self.input_value = input_value
        self.input_digest = input_digest
        self.key = key
        self.node = node
        self.retry = retry
        self.failures = tuple(failures)
        self.state = "pending"
        self.result: Any = None
        self._failure: RemoteFailure | None = None
        self.attempts = 0
        self.logical_elapsed = 0

    def _release_node(self) -> None:
        self.node.inflight -= 1
        if self.node.inflight == 0 and self.node.state == "draining":
            self.node.state = "shutdown"

    def await_(self) -> Any:
        operation = "remote.await"
        if self.state == "completed":
            return self.result
        if self.state == "cancelled":
            _fail("REMOTE_CANCELLED", operation, "remote execution was cancelled")
        if self.state == "failed":
            _fail("REMOTE_FAILED", operation, self._failure.kind if self._failure else "unknown")
        while self.attempts <= self.retry.max_retries:
            self.attempts += 1
            injected = self.failures[self.attempts - 1] if self.attempts <= len(self.failures) else None
            if injected is not None:
                retryable = injected in {"timeout", "node_loss", "reject"}
                self._failure = RemoteFailure(injected, retryable, self.attempts, self.node.identity)
                if retryable and self.attempts <= self.retry.max_retries:
                    delay = self.retry.schedule()[self.attempts - 1]
                    if self.logical_elapsed + delay > self.retry.deadline:
                        self._failure = RemoteFailure("timeout", False, self.attempts, self.node.identity)
                        self.state = "failed"
                        self._release_node()
                        _fail("REMOTE_FAILED", operation, "retry deadline exceeded")
                    self.logical_elapsed += delay
                    continue
                self.state = "failed"
                self._release_node()
                _fail("REMOTE_FAILED", operation, injected)
            try:
                value = self.task.function(self.input_value)
                self.result = _validate_value(value, self.task.schema["output"], operation)
            except ExtensionError:
                self._failure = RemoteFailure("application", False, self.attempts, self.node.identity)
                self.state = "failed"
                self._release_node()
                _fail("REMOTE_FAILED", operation, "application")
            except BaseException:
                self._failure = RemoteFailure("application", False, self.attempts, self.node.identity)
                self.state = "failed"
                self._release_node()
                _fail("REMOTE_FAILED", operation, "application")
            self.state = "completed"
            self._failure = None
            self._release_node()
            return self.result
        self.state = "failed"
        self._release_node()
        _fail("REMOTE_FAILED", operation, "retry exhausted")

    def cancel(self) -> bool:
        if self.state == "pending":
            self.state = "cancelled"
            self._failure = RemoteFailure("cancelled", False, self.attempts, self.node.identity)
            self._release_node()
            return True
        return False

    def provenance(self) -> Mapping[str, Any]:
        return _freeze({
            "node": self.node.identity,
            "task": self.task.identity,
            "schemaVersion": self.task.schema["version"],
            "inputDigest": self.input_digest,
            "idempotencyKey": self.key,
            "attempts": self.attempts,
        })

    def failure(self) -> RemoteFailure | None:
        return self._failure


setattr(RemoteExecution, "await", RemoteExecution.await_)


class DistributedData:
    def __init__(self, values: Sequence[Any], partitions: int = 1, strategy: str = "single", replicas: int = 1) -> None:
        items = _sequence(values, "DistributedData.new", "values")
        if len(items) > MAX_PARTITIONS:
            _fail("LIMIT_EXCEEDED", "DistributedData.new", "data item budget is exhausted")
        for value in items:
            _canonical(value, "DistributedData.new")
        self.values = tuple(items)
        self.partitions = partitions
        self.strategy = strategy
        self.replicas = replicas
        self.assignment = tuple(int(_digest(value)[:8], 16) % partitions for value in self.values)

    def partition(self, strategy: Mapping[str, Any] | str) -> "DistributedData":
        operation = "data.partition"
        if isinstance(strategy, str):
            kind, count = strategy, 2
        else:
            item = _mapping(strategy, operation, "strategy")
            _known_fields(item, {"kind", "partitions"}, operation, "strategy")
            kind = _text(item.get("kind"), operation, "strategy.kind")
            count = _integer(item.get("partitions"), operation, "strategy.partitions", 1, MAX_PARTITIONS)
        if kind not in {"hash", "range"}:
            _fail("INVALID_PARTITION", operation, "strategy must be hash or range")
        result = DistributedData(self.values, count, kind, self.replicas)
        if kind == "range":
            ordered_indices = sorted(range(len(self.values)), key=lambda index: _canonical(self.values[index]))
            ranks = {index: rank for rank, index in enumerate(ordered_indices)}
            result.assignment = tuple(min(count - 1, ranks[index] * count // max(1, len(self.values))) for index in range(len(self.values)))
        return result

    def replicate(self, factor: int) -> "DistributedData":
        operation = "data.replicate"
        replicas = _integer(factor, operation, "factor", 1, MAX_REPLICAS)
        result = DistributedData(self.values, self.partitions, self.strategy, replicas)
        result.assignment = self.assignment
        return result


class RetryPolicy:
    def __init__(self, maximum: int, base: int, delay: int, seed: int, deadline: int) -> None:
        self.max_retries = maximum
        self.base_delay = base
        self.max_delay = delay
        self.jitter_seed = seed
        self.deadline = deadline

    @classmethod
    def exponential(cls, options: Mapping[str, Any]) -> "RetryPolicy":
        operation = "RetryPolicy.exponential"
        item = _mapping(options, operation, "options")
        _known_fields(item, {"maxRetries", "baseDelay", "maxDelay", "jitterSeed", "deadline"}, operation, "options")
        maximum = _integer(item.get("maxRetries"), operation, "options.maxRetries", 0, MAX_RETRIES)
        base = _integer(item.get("baseDelay"), operation, "options.baseDelay", 1, MAX_RETRY_DELAY)
        delay = _integer(item.get("maxDelay"), operation, "options.maxDelay", base, MAX_RETRY_DELAY)
        seed = _integer(item.get("jitterSeed", 0), operation, "options.jitterSeed", 0, (1 << 31) - 1)
        deadline = _integer(item.get("deadline"), operation, "options.deadline", 1, MAX_DURATION)
        return cls(maximum, base, delay, seed, deadline)

    def schedule(self) -> tuple[int, ...]:
        return tuple(min(self.max_delay, self.base_delay * (1 << attempt) + ((self.jitter_seed + attempt * 17) % max(1, self.base_delay))) for attempt in range(self.max_retries + 1))


@dataclass(frozen=True)
class DistributedCheckpoint:
    version: int
    identity: str
    digest: str
    replicas: int
    quorum: int
    progress: int


class Checkpoint:
    @classmethod
    def distributed(cls, options: Mapping[str, Any] | None = None) -> DistributedCheckpoint:
        operation = "Checkpoint.distributed"
        item = _mapping(options or {}, operation, "options")
        _known_fields(item, {"version", "identity", "progress", "replicas", "quorum"}, operation, "options")
        version = _integer(item.get("version", 1), operation, "options.version", 1, (1 << 31) - 1)
        identity = _text(item.get("identity", "checkpoint-1"), operation, "options.identity")
        progress = _integer(item.get("progress", 0), operation, "options.progress", 0, (1 << 63) - 1)
        replicas = _integer(item.get("replicas", 1), operation, "options.replicas", 1, MAX_REPLICAS)
        quorum = _integer(item.get("quorum", replicas // 2 + 1), operation, "options.quorum", 1, replicas)
        if quorum < replicas // 2 + 1:
            _fail("INVALID_QUORUM", operation, "checkpoint quorum must be a majority")
        digest = _digest({"version": version, "identity": identity, "progress": progress})
        return DistributedCheckpoint(version, identity, digest, replicas, quorum, progress)


@dataclass(frozen=True)
class QuorumDecision:
    accepted: bool
    votes: int
    required: int
    replicas: int


class Workflow:
    def __init__(self) -> None:
        self._compensations: list[Mapping[str, Any]] = []
        self._applied: list[str] = []

    def compensate(self, step: Mapping[str, Any]) -> "Workflow":
        operation = "workflow.compensate"
        item = _mapping(step, operation, "step")
        _known_fields(item, {"name", "action"}, operation, "step")
        name = _text(item.get("name"), operation, "step.name")
        action = item.get("action")
        if not callable(action):
            _fail("INVALID_COMPENSATION", operation, "step.action must be callable")
        if any(existing["name"] == name for existing in self._compensations):
            _fail("DUPLICATE_COMPENSATION", operation, "compensation names must be unique")
        self._compensations.append(MappingProxyType({"name": name, "action": action}))
        return self

    def runCompensations(self) -> tuple[str, ...]:
        operation = "workflow.compensate"
        applied: list[str] = []
        for step in reversed(self._compensations):
            if step["name"] in self._applied:
                continue
            try:
                step["action"]()
            except BaseException:
                _fail("COMPENSATION_FAILED", operation, f"compensation {step['name']} failed")
            applied.append(step["name"])
            self._applied.append(step["name"])
        return tuple(applied)


__all__ = [
    "Callback", "Checkpoint", "Cluster", "DistributedData", "ExtensionError",
    "ForeignBuffer", "ForeignLibrary", "ForeignLifetime", "ForeignType", "NodeRuntime",
    "Plugin", "PluginManifest", "RemoteTask", "RetryPolicy", "Sandbox", "Workflow", "ffi",
]
