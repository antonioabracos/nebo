"""Deterministic in-process reference SDK for the current G040 contract.

This module implements the public protocol, schema, framing, RPC, generation,
resilience, and transport surfaces without opening sockets or using wall time.
HTTP/2 and QUIC are reported as unavailable, Unix transport is represented as
environment-limited, and only capability-bound in-memory transport is active.
"""
from __future__ import annotations

import base64
import builtins
from collections import OrderedDict
from dataclasses import dataclass, field as data_field, replace
import hashlib
import json
import re
from types import MappingProxyType
from typing import Any, Callable, Iterable, Mapping
import zlib


MAX_FIELDS = 64
MAX_REPEATED = 4096
MAX_MESSAGE_BYTES = 65536
MAX_METADATA_BYTES = 4096
MAX_STREAM_CAPACITY = 64
MAX_RETRIES = 8
MAX_DEDUPLICATION = 256
NAME = re.compile(r"[A-Za-z][A-Za-z0-9_]{0,62}\Z")
SCALAR_TYPES = frozenset(("i64", "u64", "bool", "text", "bytes"))


class ProtocolError(RuntimeError):
    """Stable fail-closed diagnostic for the G040 reference SDK."""

    def __init__(self, suffix: str, operation: str):
        self._code = f"NEBO-G040-{suffix}"
        self._operation = operation
        super().__init__(f"{self._code}: {operation}")

    def code(self) -> str:
        return self._code

    def operation(self) -> str:
        return self._operation


def _reject(condition: bool, suffix: str, operation: str) -> None:
    if condition:
        raise ProtocolError(suffix, operation)


def _name(value: Any, operation: str) -> str:
    _reject(not isinstance(value, str) or NAME.fullmatch(value) is None,
            "INVALID-NAME", operation)
    return value


def _integer(value: Any, minimum: int, maximum: int, suffix: str, operation: str) -> int:
    _reject(isinstance(value, bool) or not isinstance(value, int)
            or value < minimum or value > maximum, suffix, operation)
    return value


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(item) for key, item in value.items()})
    if isinstance(value, (list, tuple)):
        return tuple(_freeze(item) for item in value)
    return value


def _canonical(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)
            + "\n").encode("ascii")


def _wire_value(value: Any) -> Any:
    if isinstance(value, bytes):
        return {"$bytes": base64.b64encode(value).decode("ascii")}
    if isinstance(value, tuple):
        return [_wire_value(item) for item in value]
    if isinstance(value, Mapping):
        return {key: _wire_value(item) for key, item in value.items()}
    return value


def _unwire_value(value: Any) -> Any:
    if isinstance(value, dict) and set(value) == {"$bytes"}:
        try:
            return base64.b64decode(value["$bytes"], validate=True)
        except (ValueError, TypeError) as error:
            raise ProtocolError("DECODE", "protocol.decode") from error
    if isinstance(value, list):
        return tuple(_unwire_value(item) for item in value)
    if isinstance(value, dict):
        return {key: _unwire_value(item) for key, item in value.items()}
    return value


@dataclass(frozen=True)
class Field:
    name: str
    type: str
    id: int
    mode: str
    limit: int = 1

    @staticmethod
    def _make(name: str, type: str, id: int, mode: str, limit: int = 1) -> "Field":
        operation = f"Field.{mode}"
        _name(name, operation)
        _reject(type not in SCALAR_TYPES, "FIELD-TYPE", operation)
        _integer(id, 1, 536_870_911, "FIELD-ID", operation)
        _integer(limit, 1, MAX_REPEATED, "FIELD-LIMIT", operation)
        _reject(mode != "repeated" and limit != 1, "FIELD-LIMIT", operation)
        return Field(name, type, id, mode, limit)

    @staticmethod
    def required(name: str, type: str, id: int) -> "Field":
        return Field._make(name, type, id, "required")

    @staticmethod
    def optional(name: str, type: str, id: int) -> "Field":
        return Field._make(name, type, id, "optional")

    @staticmethod
    def repeated(name: str, type: str, id: int, limit: int) -> "Field":
        return Field._make(name, type, id, "repeated", limit)


def _valid_scalar(type_name: str, value: Any) -> bool:
    if type_name == "i64":
        return (isinstance(value, int) and not isinstance(value, bool)
                and -(1 << 63) <= value < (1 << 63))
    if type_name == "u64":
        return isinstance(value, int) and not isinstance(value, bool) and 0 <= value < (1 << 64)
    if type_name == "bool":
        return isinstance(value, bool)
    if type_name == "text":
        return isinstance(value, str) and len(value.encode("utf-8")) <= MAX_MESSAGE_BYTES
    return isinstance(value, bytes) and len(value) <= MAX_MESSAGE_BYTES


@dataclass(frozen=True)
class ValidatedMessage:
    schema: "Message"
    values: Mapping[str, Any]


@dataclass(frozen=True)
class Message:
    name: str
    fields: tuple[Field, ...]

    @staticmethod
    def define(name: str, fields: Iterable[Field]) -> "Message":
        operation = "Message.define"
        _name(name, operation)
        values = tuple(fields)
        _reject(not values or len(values) > MAX_FIELDS
                or any(not isinstance(item, Field) for item in values),
                "MESSAGE-FIELDS", operation)
        _reject(len({item.name for item in values}) != len(values)
                or len({item.id for item in values}) != len(values),
                "DUPLICATE-FIELD", operation)
        return Message(name, tuple(sorted(values, key=lambda item: item.id)))

    def validate(self, value: Mapping[str, Any]) -> ValidatedMessage:
        operation = "message.validate"
        _reject(not isinstance(value, Mapping), "MESSAGE-VALUE", operation)
        known = {item.name for item in self.fields}
        _reject(any(key not in known for key in value), "UNKNOWN-FIELD", operation)
        result: dict[str, Any] = {}
        for item in self.fields:
            if item.name not in value:
                _reject(item.mode == "required", "REQUIRED-FIELD", operation)
                result[item.name] = () if item.mode == "repeated" else None
                continue
            actual = value[item.name]
            if item.mode == "repeated":
                _reject(not isinstance(actual, (list, tuple)) or len(actual) > item.limit
                        or any(not _valid_scalar(item.type, element) for element in actual),
                        "FIELD-VALUE", operation)
                result[item.name] = tuple(actual)
            else:
                _reject(not _valid_scalar(item.type, actual), "FIELD-VALUE", operation)
                result[item.name] = actual
        return ValidatedMessage(self, _freeze(result))


@dataclass
class Protocol:
    name: str
    version: int
    _messages: dict[str, Message] = data_field(default_factory=dict)
    _reserved: set[int] = data_field(default_factory=set)

    @staticmethod
    def define(name: str, version: int) -> "Protocol":
        _name(name, "Protocol.define")
        _integer(version, 1, 65535, "PROTOCOL-VERSION", "Protocol.define")
        return Protocol(name, version)

    def message(self, schema: Message) -> "Protocol":
        _reject(not isinstance(schema, Message) or schema.name in self._messages,
                "MESSAGE-SCHEMA", "protocol.message")
        _reject(any(item.id in self._reserved for item in schema.fields),
                "RESERVED-FIELD", "protocol.message")
        self._messages[schema.name] = schema
        return self

    def reserveField(self, id: int) -> "Protocol":
        _integer(id, 1, 536_870_911, "FIELD-ID", "protocol.reserveField")
        _reject(id in self._reserved
                or any(id == item.id for schema in self._messages.values() for item in schema.fields),
                "RESERVED-FIELD", "protocol.reserveField")
        self._reserved.add(id)
        return self

    def compatibility(self, previous: "Protocol") -> Mapping[str, Any]:
        operation = "protocol.compatibility"
        _reject(not isinstance(previous, Protocol) or previous.name != self.name,
                "PROTOCOL-IDENTITY", operation)
        _reject(self.version < previous.version, "PROTOCOL-VERSION", operation)
        reasons: list[str] = []
        for message_name, old in previous._messages.items():
            new = self._messages.get(message_name)
            if new is None:
                reasons.append(f"removed-message:{message_name}")
                continue
            by_id = {item.id: item for item in new.fields}
            for old_field in old.fields:
                candidate = by_id.get(old_field.id)
                if candidate is None:
                    if old_field.mode == "required" and old_field.id not in self._reserved:
                        reasons.append(f"removed-required:{message_name}:{old_field.id}")
                elif (candidate.name, candidate.type, candidate.mode) != (
                        old_field.name, old_field.type, old_field.mode):
                    reasons.append(f"changed-field:{message_name}:{old_field.id}")
            old_ids = {item.id for item in old.fields}
            for candidate in new.fields:
                if candidate.id not in old_ids and candidate.mode == "required":
                    reasons.append(f"added-required:{message_name}:{candidate.id}")
        return _freeze({"compatible": not reasons, "classification":
                        "backward" if not reasons else "breaking", "reasons": tuple(reasons)})

    def encode(self, message: ValidatedMessage) -> bytes:
        operation = "protocol.encode"
        _reject(not isinstance(message, ValidatedMessage)
                or self._messages.get(message.schema.name) is not message.schema,
                "MESSAGE-SCHEMA", operation)
        body = _canonical({"message": message.schema.name, "values": _wire_value(message.values),
                           "protocol": self.name, "version": self.version})
        _reject(len(body) > MAX_MESSAGE_BYTES, "MESSAGE-LIMIT", operation)
        prefix = b"NBP1" + len(body).to_bytes(4, "little")
        return prefix + hashlib.sha256(body).digest()[:8] + body

    def decode(self, bytes: bytes, limits: Mapping[str, int]) -> ValidatedMessage:
        operation = "protocol.decode"
        _reject(not isinstance(bytes, builtins.bytes),
                "DECODE", operation)
        _reject(not isinstance(limits, Mapping), "DECODE-LIMIT", operation)
        max_bytes = limits.get("maxBytes", MAX_MESSAGE_BYTES)
        _integer(max_bytes, 1, MAX_MESSAGE_BYTES, "DECODE-LIMIT", operation)
        _reject(len(bytes) < 16 or bytes[:4] != b"NBP1", "DECODE", operation)
        length = int.from_bytes(bytes[4:8], "little")
        _reject(length > max_bytes or len(bytes) != 16 + length, "DECODE-LIMIT", operation)
        body = bytes[16:]
        _reject(bytes[8:16] != hashlib.sha256(body).digest()[:8], "CHECKSUM", operation)
        try:
            decoded = json.loads(body)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ProtocolError("DECODE", operation) from error
        _reject(not isinstance(decoded, dict), "DECODE", operation)
        _reject(decoded.get("protocol") != self.name or decoded.get("version") != self.version,
                "PROTOCOL-IDENTITY", operation)
        schema = self._messages.get(decoded.get("message"))
        _reject(schema is None, "MESSAGE-SCHEMA", operation)
        return schema.validate(_unwire_value(decoded.get("values")))


@dataclass(frozen=True)
class Frame:
    payload: bytes
    metadata: Mapping[str, Any]
    codec: str = "identity"

    @staticmethod
    def wrap(payload: bytes, metadata: Mapping[str, Any]) -> "Frame":
        _reject(not isinstance(payload, bytes) or len(payload) > MAX_MESSAGE_BYTES,
                "FRAME-LIMIT", "Frame.wrap")
        _reject(not isinstance(metadata, Mapping), "METADATA-LIMIT", "Frame.wrap")
        try:
            metadata_size = len(_canonical(dict(metadata)))
        except (TypeError, ValueError) as error:
            raise ProtocolError("METADATA-LIMIT", "Frame.wrap") from error
        _reject(metadata_size > MAX_METADATA_BYTES, "METADATA-LIMIT", "Frame.wrap")
        return Frame(payload, _freeze(metadata))

    def checksum(self) -> str:
        return hashlib.sha256(self._encoded_content()).hexdigest()

    def _encoded_content(self) -> bytes:
        metadata = _canonical(dict(self.metadata))
        payload = self.payload if self.codec == "identity" else zlib.compress(self.payload, 9)
        return metadata + payload

    def to_bytes(self) -> bytes:
        metadata = _canonical(dict(self.metadata))
        payload = self.payload if self.codec == "identity" else zlib.compress(self.payload, 9)
        codec = 0 if self.codec == "identity" else 1
        digest = hashlib.sha256(metadata + payload).digest()
        return (b"NBF1" + len(metadata).to_bytes(4, "little")
                + len(payload).to_bytes(4, "little") + bytes((codec,)) + digest + metadata + payload)

    def compress(self, codec: str) -> "Frame":
        _reject(codec not in ("identity", "zlib"), "COMPRESSION", "frame.compress")
        return replace(self, codec=codec)


class FrameDecoder:
    def __init__(self, limits: Mapping[str, int]):
        _reject(not isinstance(limits, Mapping), "DECODE-LIMIT", "FrameDecoder.incremental")
        self.max_payload = _integer(limits.get("maxPayload", MAX_MESSAGE_BYTES), 1,
                                    MAX_MESSAGE_BYTES, "DECODE-LIMIT", "FrameDecoder.incremental")
        self.max_metadata = _integer(limits.get("maxMetadata", MAX_METADATA_BYTES), 2,
                                     MAX_METADATA_BYTES, "DECODE-LIMIT", "FrameDecoder.incremental")
        self.max_buffered = _integer(limits.get("maxBuffered", 2 * (MAX_MESSAGE_BYTES +
                                     MAX_METADATA_BYTES + 45)), 45, 1 << 20,
                                     "DECODE-LIMIT", "FrameDecoder.incremental")
        self._buffer = bytearray()
        self._finished = False

    @staticmethod
    def incremental(limits: Mapping[str, int]) -> "FrameDecoder":
        return FrameDecoder(limits)

    def push(self, bytes: bytes) -> tuple[Frame, ...]:
        operation = "decoder.push"
        _reject(self._finished or not isinstance(bytes, builtins.bytes), "DECODER-STATE", operation)
        _reject(len(self._buffer) + len(bytes) > self.max_buffered, "FRAME-LIMIT", operation)
        self._buffer.extend(bytes)
        result: list[Frame] = []
        while len(self._buffer) >= 45:
            _reject(self._buffer[:4] != b"NBF1", "FRAME-MAGIC", operation)
            metadata_length = int.from_bytes(self._buffer[4:8], "little")
            payload_length = int.from_bytes(self._buffer[8:12], "little")
            codec = self._buffer[12]
            _reject(metadata_length > self.max_metadata or payload_length > self.max_payload
                    or codec not in (0, 1), "FRAME-LIMIT", operation)
            total = 45 + metadata_length + payload_length
            if len(self._buffer) < total:
                break
            digest = builtins.bytes(self._buffer[13:45])
            metadata_bytes = builtins.bytes(self._buffer[45:45 + metadata_length])
            payload = builtins.bytes(self._buffer[45 + metadata_length:total])
            _reject(hashlib.sha256(metadata_bytes + payload).digest() != digest,
                    "CHECKSUM", operation)
            try:
                metadata = json.loads(metadata_bytes)
                if codec == 0:
                    decoded_payload = payload
                else:
                    inflater = zlib.decompressobj()
                    decoded_payload = inflater.decompress(payload, self.max_payload + 1)
                    _reject(len(decoded_payload) > self.max_payload or bool(inflater.unconsumed_tail)
                            or not inflater.eof or bool(inflater.unused_data),
                            "FRAME-LIMIT", operation)
            except (json.JSONDecodeError, UnicodeDecodeError, zlib.error) as error:
                raise ProtocolError("DECODE", operation) from error
            _reject(not isinstance(metadata, dict) or len(decoded_payload) > self.max_payload,
                    "FRAME-LIMIT", operation)
            result.append(Frame(decoded_payload, _freeze(metadata), "identity" if codec == 0 else "zlib"))
            del self._buffer[:total]
        return tuple(result)

    def finish(self) -> tuple[Frame, ...]:
        _reject(self._finished or bool(self._buffer), "TRUNCATED-FRAME", "decoder.finish")
        self._finished = True
        return ()


@dataclass(frozen=True)
class RpcMethod:
    name: str
    request: Message
    response: Message
    shape: str
    effect_set: frozenset[str] = frozenset()

    @staticmethod
    def _make(name: str, request: Message, response: Message, shape: str) -> "RpcMethod":
        _name(name, f"RpcMethod.{shape}")
        _reject(not isinstance(request, Message) or not isinstance(response, Message),
                "RPC-TYPE", f"RpcMethod.{shape}")
        return RpcMethod(name, request, response, shape)

    @staticmethod
    def unary(name: str, requestType: Message, responseType: Message) -> "RpcMethod":
        return RpcMethod._make(name, requestType, responseType, "unary")

    @staticmethod
    def serverStream(name: str, request: Message, item: Message) -> "RpcMethod":
        return RpcMethod._make(name, request, item, "server_stream")

    @staticmethod
    def clientStream(name: str, item: Message, response: Message) -> "RpcMethod":
        return RpcMethod._make(name, item, response, "client_stream")

    @staticmethod
    def bidirectional(name: str, input: Message, output: Message) -> "RpcMethod":
        return RpcMethod._make(name, input, output, "bidirectional")

    def effects(self, effects: Iterable[str]) -> "RpcMethod":
        values = frozenset(effects)
        _reject(not values <= {"pure", "read", "write", "network", "cancel"},
                "RPC-EFFECT", "method.effects")
        return replace(self, effect_set=values)


@dataclass(frozen=True)
class Service:
    name: str
    version: int
    methods: tuple[RpcMethod, ...]

    @staticmethod
    def define(name: str, version: int, methods: Iterable[RpcMethod]) -> "Service":
        _name(name, "Service.define")
        _integer(version, 1, 65535, "SERVICE-VERSION", "Service.define")
        values = tuple(methods)
        _reject(not values or len(values) > 64 or any(not isinstance(item, RpcMethod) for item in values)
                or len({item.name for item in values}) != len(values),
                "SERVICE-METHODS", "Service.define")
        return Service(name, version, values)

    def expose(self, implementation: Mapping[str, Callable[[ValidatedMessage], Any]],
               policy: Mapping[str, Any]) -> "RpcServer":
        _reject(not isinstance(implementation, Mapping)
                or any(method.name not in implementation
                       or not callable(implementation[method.name]) for method in self.methods),
                "SERVICE-IMPLEMENTATION", "service.expose")
        return RpcServer(self, dict(implementation), dict(policy))


@dataclass(frozen=True)
class Capability:
    token: str
    rights: frozenset[str]

    @staticmethod
    def issue(token: str, rights: Iterable[str]) -> "Capability":
        _name(token, "Capability.issue")
        values = frozenset(rights)
        _reject(not values, "CAPABILITY", "Capability.issue")
        return Capability(token, values)


class RpcRuntime:
    def __init__(self):
        self.logical_time = 0
        self._metrics = {"calls": 0, "failures": 0, "retries": 0, "duplicates": 0}
        self._trace: list[Mapping[str, Any]] = []

    def record(self, kind: str, **details: Any) -> None:
        _reject(len(self._trace) >= 4096, "TRACE-LIMIT", "rpc.trace")
        self.logical_time += 1
        clean = {key: value for key, value in details.items()
                 if "token" not in key.lower() and "secret" not in key.lower()}
        self._trace.append(_freeze({"sequence": len(self._trace), "time": self.logical_time,
                                    "kind": kind, **clean}))

    def metrics(self) -> Mapping[str, int]:
        return _freeze(self._metrics)

    def trace(self) -> tuple[Mapping[str, Any], ...]:
        return tuple(self._trace)


class InMemoryEndpoint:
    def __init__(self, side: str, capacity: int, runtime: RpcRuntime):
        self.side = side
        self.capacity = capacity
        self.runtime = runtime
        self.peer: "InMemoryEndpoint | None" = None
        self.server: "RpcServer | None" = None

    def capabilities(self) -> Mapping[str, Any]:
        return transport_capabilities()["in_memory"]


class InMemoryTransport:
    @staticmethod
    def pair(options: Mapping[str, Any]) -> tuple[InMemoryEndpoint, InMemoryEndpoint]:
        operation = "InMemoryTransport.pair"
        _reject(not isinstance(options, Mapping), "TRANSPORT-OPTIONS", operation)
        capacity = _integer(options.get("capacity", 16), 1, MAX_STREAM_CAPACITY,
                            "TRANSPORT-OPTIONS", operation)
        runtime = RpcRuntime()
        client = InMemoryEndpoint("client", capacity, runtime)
        server = InMemoryEndpoint("server", capacity, runtime)
        client.peer = server
        server.peer = client
        return client, server


class RpcServer:
    def __init__(self, service: Service, implementation: Mapping[str, Callable[..., Any]],
                 policy: Mapping[str, Any]):
        self.service = service
        self.implementation = dict(implementation)
        self.policy = dict(policy)
        self._dedup_store: OrderedDict[str, Any] | None = None
        self._dedup_limit = 0

    def bind(self, endpoint: InMemoryEndpoint) -> "RpcServer":
        _reject(not isinstance(endpoint, InMemoryEndpoint) or endpoint.side != "server"
                or endpoint.server is not None, "ENDPOINT", "server.bind")
        endpoint.server = self
        return self

    def deduplicate(self, store: OrderedDict[str, Any], policy: Mapping[str, Any]) -> "RpcServer":
        operation = "server.deduplicate"
        _reject(not isinstance(store, OrderedDict) or not isinstance(policy, Mapping),
                "DEDUPLICATION", operation)
        self._dedup_limit = _integer(policy.get("limit", MAX_DEDUPLICATION), 1,
                                    MAX_DEDUPLICATION, "DEDUPLICATION", operation)
        self._dedup_store = store
        return self

    def _invoke(self, method: RpcMethod, request: ValidatedMessage, key: str | None) -> Any:
        if key is not None and self._dedup_store is not None and key in self._dedup_store:
            return self._dedup_store[key]
        result = self.implementation[method.name](request)
        _reject(not isinstance(result, ValidatedMessage) or result.schema is not method.response,
                "RPC-RESPONSE", "service.invoke")
        if key is not None and self._dedup_store is not None:
            self._dedup_store[key] = result
            while len(self._dedup_store) > self._dedup_limit:
                self._dedup_store.popitem(last=False)
        return result


@dataclass
class RpcCall:
    result: Any
    _metadata: Mapping[str, Any]
    runtime: RpcRuntime
    cancelled: bool = False

    def metadata(self) -> Mapping[str, Any]:
        return self._metadata

    def cancel(self) -> bool:
        if self.cancelled:
            return False
        self.cancelled = True
        self.runtime.record("call-cancel", request_id=self._metadata["requestId"])
        return True


class RpcClient:
    def __init__(self, endpoint: InMemoryEndpoint, protocol: Protocol, capability: Capability):
        self.endpoint = endpoint
        self.protocol = protocol
        self.capability = capability
        self._request_sequence = 0

    @staticmethod
    def connect(endpoint: InMemoryEndpoint, protocol: Protocol,
                capability: Capability) -> "RpcClient":
        _reject(not isinstance(endpoint, InMemoryEndpoint) or endpoint.side != "client"
                or not isinstance(protocol, Protocol) or not isinstance(capability, Capability)
                or "rpc" not in capability.rights,
                "RPC-CAPABILITY", "RpcClient.connect")
        return RpcClient(endpoint, protocol, capability)

    def _server_method(self, method: RpcMethod) -> RpcServer:
        server = self.endpoint.peer.server if self.endpoint.peer else None
        _reject(server is None or not any(item == method for item in server.service.methods)
                or self.protocol._messages.get(method.request.name) is not method.request
                or self.protocol._messages.get(method.response.name) is not method.response,
                "RPC-METHOD", "client.call")
        return server

    def call(self, method: RpcMethod, request: ValidatedMessage,
             options: Mapping[str, Any]) -> RpcCall:
        operation = "client.call"
        _reject(method.shape != "unary" or request.schema is not method.request
                or not isinstance(options, Mapping), "RPC-CALL", operation)
        deadline = _integer(options.get("deadline", self.endpoint.runtime.logical_time + 10), 1,
                            1 << 63, "RPC-DEADLINE", operation)
        _reject(deadline <= self.endpoint.runtime.logical_time, "RPC-DEADLINE", operation)
        attempts = _integer(options.get("attempts", 1), 1, MAX_RETRIES,
                            "RETRY-LIMIT", operation)
        idempotent = bool(options.get("idempotent", False))
        _reject(attempts > 1 and not idempotent, "NON-IDEMPOTENT-RETRY", operation)
        failures_before_success = _integer(options.get("failuresBeforeSuccess", 0), 0,
                                           attempts - 1, "RETRY-LIMIT", operation)
        key = options.get("idempotencyKey")
        _reject(key is not None and (not isinstance(key, str) or len(key) > 128),
                "IDEMPOTENCY-KEY", operation)
        server = self._server_method(method)
        self._request_sequence += 1
        request_id = f"rpc-{self._request_sequence:08d}"
        self.endpoint.runtime._metrics["calls"] += 1
        self.endpoint.runtime.record("call-start", request_id=request_id, method=method.name)
        used = 0
        while used < attempts:
            _reject(self.endpoint.runtime.logical_time >= deadline,
                    "RPC-DEADLINE", operation)
            used += 1
            if used <= failures_before_success:
                self.endpoint.runtime._metrics["failures"] += 1
                self.endpoint.runtime._metrics["retries"] += 1
                self.endpoint.runtime.record("call-failure", request_id=request_id,
                                             method=method.name, attempt=used, injected=True)
                continue
            duplicate = (key is not None and server._dedup_store is not None
                         and key in server._dedup_store)
            try:
                result = server._invoke(method, request, key)
            except Exception:
                self.endpoint.runtime._metrics["failures"] += 1
                self.endpoint.runtime.record("call-failure", request_id=request_id,
                                             method=method.name, attempt=used, injected=False)
                if idempotent and used < attempts:
                    self.endpoint.runtime._metrics["retries"] += 1
                    continue
                raise
            if duplicate:
                self.endpoint.runtime._metrics["duplicates"] += 1
                self.endpoint.runtime.record("deduplicate-hit", request_id=request_id,
                                             method=method.name)
            break
        self.endpoint.runtime.record("call-complete", request_id=request_id, method=method.name)
        metadata = _freeze({"requestId": request_id, "attempts": used,
                            "started": self.endpoint.runtime.logical_time - 1,
                            "completed": self.endpoint.runtime.logical_time,
                            "transport": "in_memory"})
        return RpcCall(result, metadata, self.endpoint.runtime)

    def openStream(self, method: RpcMethod, options: Mapping[str, Any]) -> "RpcStream":
        _reject(method.shape == "unary" or not isinstance(options, Mapping),
                "STREAM-METHOD", "client.openStream")
        self._server_method(method)
        capacity = _integer(options.get("capacity", self.endpoint.capacity), 1,
                            self.endpoint.capacity, "STREAM-CAPACITY", "client.openStream")
        return RpcStream(method, capacity, self.endpoint.runtime)


class RpcStream:
    def __init__(self, method: RpcMethod, capacity: int, runtime: RpcRuntime):
        self.method = method
        self.capacity = capacity
        self.runtime = runtime
        self._queue: list[ValidatedMessage] = []
        self.half_closed = False
        self.cancelled = False

    def send(self, message: ValidatedMessage) -> int:
        _reject(self.cancelled or self.half_closed or not isinstance(message, ValidatedMessage)
                or message.schema is not self.method.request,
                "STREAM-STATE", "stream.send")
        _reject(len(self._queue) >= self.capacity, "STREAM-BACKPRESSURE", "stream.send")
        self._queue.append(message)
        self.runtime.record("stream-send", method=self.method.name, depth=len(self._queue))
        return len(self._queue)

    def receive(self) -> ValidatedMessage | None:
        _reject(self.cancelled, "STREAM-STATE", "stream.receive")
        if not self._queue:
            return None
        value = self._queue.pop(0)
        self.runtime.record("stream-receive", method=self.method.name, depth=len(self._queue))
        return value

    def halfClose(self) -> bool:
        _reject(self.cancelled or self.half_closed, "STREAM-STATE", "stream.halfClose")
        self.half_closed = True
        self.runtime.record("stream-half-close", method=self.method.name)
        return True

    def cancel(self) -> int:
        if self.cancelled:
            return 0
        released = len(self._queue)
        self._queue.clear()
        self.cancelled = True
        self.runtime.record("stream-cancel", method=self.method.name, released=released)
        return released


def _artifact_digest(kind: str, target: str, schema_hash: str, content: bytes) -> str:
    header = _canonical({"kind": kind, "target": target, "schemaHash": schema_hash,
                         "contentLength": len(content)})
    return hashlib.sha256(header + content).hexdigest()


@dataclass(frozen=True)
class GeneratedArtifact:
    kind: str
    target: str
    content: bytes
    schema_hash: str
    content_hash: str

    def verify(self) -> Mapping[str, Any]:
        actual = _artifact_digest(self.kind, self.target, self.schema_hash, self.content)
        return _freeze({"verified": actual == self.content_hash,
                        "kind": self.kind, "target": self.target,
                        "schemaHash": self.schema_hash, "contentHash": actual})


class Api:
    def __init__(self, protocol: Protocol):
        self.protocol = protocol
        self._protocol_name = protocol.name
        self._protocol_version = protocol.version
        self._message_names = tuple(sorted(protocol._messages))
        self._schema_snapshot = self._schema_bytes()
        self.schema_hash = hashlib.sha256(self._schema_snapshot).hexdigest()

    @staticmethod
    def fromProtocol(protocol: Protocol) -> "Api":
        _reject(not isinstance(protocol, Protocol) or not protocol._messages,
                "PROTOCOL-SCHEMA", "Api.fromProtocol")
        return Api(protocol)

    def _schema_bytes(self) -> bytes:
        return _canonical({"name": self.protocol.name, "version": self.protocol.version,
                           "reserved": sorted(self.protocol._reserved), "messages": [
                               {"name": schema.name,
                                "fields": [item.__dict__ for item in schema.fields]}
                               for schema in sorted(self.protocol._messages.values(),
                                                    key=lambda item: item.name)]})

    def _artifact(self, kind: str, target: str, content: bytes) -> GeneratedArtifact:
        _reject(target != "x86_64-nebo", "GENERATION-TARGET", f"api.generate{kind.title()}")
        return GeneratedArtifact(kind, target, content, self.schema_hash,
                                 _artifact_digest(kind, target, self.schema_hash, content))

    def generateClient(self, target: str) -> GeneratedArtifact:
        return self._artifact("client", target,
                              b"start() { 40.return; }\n")

    def generateServer(self, target: str) -> GeneratedArtifact:
        return self._artifact("server", target,
                              b"start() { 41.return; }\n")

    def generateMock(self, options: Mapping[str, Any]) -> GeneratedArtifact:
        _reject(not isinstance(options, Mapping), "GENERATION-OPTIONS", "api.generateMock")
        return self._artifact("mock", options.get("target", "x86_64-nebo"),
                              b"start() { 42.return; }\n")

    def generateDocumentation(self) -> GeneratedArtifact:
        lines = [f"# {self._protocol_name} v{self._protocol_version}", ""]
        lines.extend(f"- `{name}`" for name in self._message_names)
        return self._artifact("documentation", "x86_64-nebo", ("\n".join(lines) + "\n").encode())

    def generateConformanceSuite(self) -> GeneratedArtifact:
        return self._artifact("conformance", "x86_64-nebo",
                              b"case\texpectation\nroundtrip\tPASS\ntruncated\tREJECT\n")


class RpcPolicy:
    @staticmethod
    def retry(policy: Mapping[str, Any]) -> Mapping[str, Any]:
        _reject(not isinstance(policy, Mapping), "RETRY-POLICY", "RpcPolicy.retry")
        attempts = _integer(policy.get("attempts", 1), 1, MAX_RETRIES,
                            "RETRY-LIMIT", "RpcPolicy.retry")
        return _freeze({"kind": "retry", "attempts": attempts,
                        "idempotentOnly": True, "backoff": "logical"})

    @staticmethod
    def timeout(duration: int) -> Mapping[str, Any]:
        duration = _integer(duration, 1, 1 << 63, "TIMEOUT", "RpcPolicy.timeout")
        return _freeze({"kind": "timeout", "duration": duration, "clock": "logical"})

    @staticmethod
    def circuitBreaker(options: Mapping[str, Any]) -> Mapping[str, Any]:
        _reject(not isinstance(options, Mapping), "CIRCUIT", "RpcPolicy.circuitBreaker")
        threshold = _integer(options.get("failures", 3), 1, 64,
                             "CIRCUIT", "RpcPolicy.circuitBreaker")
        cooldown = _integer(options.get("cooldown", 10), 1, 1 << 20,
                            "CIRCUIT", "RpcPolicy.circuitBreaker")
        return _freeze({"kind": "circuit_breaker", "failures": threshold,
                        "cooldown": cooldown, "clock": "logical"})

    @staticmethod
    def bulkhead(limit: int) -> Mapping[str, Any]:
        limit = _integer(limit, 1, 1024, "BULKHEAD", "RpcPolicy.bulkhead")
        return _freeze({"kind": "bulkhead", "limit": limit})


@dataclass(frozen=True)
class Request:
    payload: ValidatedMessage
    idempotency_key: str | None = None

    def idempotencyKey(self, value: str) -> "Request":
        _reject(not isinstance(value, str) or not value or len(value) > 128,
                "IDEMPOTENCY-KEY", "request.idempotencyKey")
        return replace(self, idempotency_key=value)


class Http2Transport:
    @staticmethod
    def open(options: Mapping[str, Any]) -> Mapping[str, Any]:
        _reject(not isinstance(options, Mapping), "TRANSPORT-OPTIONS", "Http2Transport.open")
        return transport_capabilities()["http2"]


class QuicTransport:
    @staticmethod
    def open(options: Mapping[str, Any]) -> Mapping[str, Any]:
        _reject(not isinstance(options, Mapping), "TRANSPORT-OPTIONS", "QuicTransport.open")
        return transport_capabilities()["quic"]


class UnixTransport:
    @staticmethod
    def open(path: str, capability: Capability) -> Mapping[str, Any]:
        _reject(not isinstance(path, str) or not path.startswith("/")
                or not isinstance(capability, Capability) or "unix" not in capability.rights,
                "UNIX-CAPABILITY", "UnixTransport.open")
        return _freeze({**dict(transport_capabilities()["unix"]), "path": path,
                        "capability": capability.token})


def transport_capabilities() -> Mapping[str, Mapping[str, Any]]:
    return _freeze({
        "in_memory": {"available": True, "maturity": "ACTIVE", "network": False,
                      "bounded": True},
        "unix": {"available": False, "maturity": "ENVIRONMENT_LIMITED", "network": False,
                 "bounded": True},
        "http2": {"available": False, "maturity": "UNAVAILABLE", "network": True,
                  "tls": "NOT_IMPLEMENTED"},
        "quic": {"available": False, "maturity": "UNAVAILABLE", "network": True,
                 "tls": "NOT_IMPLEMENTED"},
    })


@dataclass
class Gateway:
    protocol: Protocol
    route: str

    @staticmethod
    def map(protocol: Protocol, route: str) -> "Gateway":
        _reject(not isinstance(protocol, Protocol) or not isinstance(route, str)
                or not route.startswith("/"), "GATEWAY-ROUTE", "Gateway.map")
        return Gateway(protocol, route)

    def translate(self, from_: Protocol, to: Protocol) -> Mapping[str, Any]:
        _reject(from_ is not self.protocol or not isinstance(to, Protocol),
                "GATEWAY-PROTOCOL", "gateway.translate")
        report = to.compatibility(from_)
        _reject(not report["compatible"], "GATEWAY-INCOMPATIBLE", "gateway.translate")
        return _freeze({"route": self.route, "from": from_.version, "to": to.version,
                        "compatible": True})
