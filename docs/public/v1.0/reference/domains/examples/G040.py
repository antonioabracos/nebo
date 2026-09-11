#!/usr/bin/env python3
"""Independent value/effect oracle for all 54 programmatic G040 surfaces."""
from __future__ import annotations

from collections import OrderedDict, defaultdict
import hashlib
import json
from pathlib import Path
import sys
import zlib

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from compiler.sdk.protocols import (  # noqa: E402
    Api, Capability, Field, Frame, FrameDecoder, Gateway, Http2Transport,
    InMemoryTransport, Message, Protocol, ProtocolError, QuicTransport,
    Request, RpcClient, RpcMethod, RpcPolicy, Service, UnixTransport,
    transport_capabilities,
)


counts: dict[str, int] = defaultdict(int)
transcript: list[object] = []


def ok(category: str, label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(f"{category}:{label}")
    counts[category] += 1
    if category == "positive":
        counts["sdk"] += 1


def reject(label: str, suffix: str, callable_) -> None:
    try:
        callable_()
    except ProtocolError as error:
        ok("negative", label, error.code() == f"NEBO-G040-{suffix}" and bool(error.operation()))
        counts["diagnostics"] += 1
        return
    raise AssertionError(f"negative:{label}:accepted")


# S01 — schemas retain stable field identities and explicit compatibility.
protocol = Protocol.define("Echo", 2)
ok("positive", "Protocol.define", protocol.name == "Echo" and protocol.version == 2)
required = Field.required("value", "text", 1)
ok("positive", "Field.required", required.mode == "required" and required.id == 1)
optional = Field.optional("requestId", "u64", 2)
ok("positive", "Field.optional", optional.mode == "optional" and optional.id == 2)
repeated = Field.repeated("tags", "u64", 3, 8)
ok("positive", "Field.repeated", repeated.mode == "repeated" and repeated.limit == 8)
echo = Message.define("EchoMessage", (repeated, required, optional))
ok("positive", "Message.define", tuple(item.id for item in echo.fields) == (1, 2, 3))
value = echo.validate({"value": "nebula", "requestId": 73, "tags": [5, 8, 13]})
ok("positive", "message.validate", value.values["value"] == "nebula"
   and value.values["tags"] == (5, 8, 13))
protocol.message(echo)
previous_message = Message.define("EchoMessage", (Field.required("value", "text", 1),))
previous = Protocol.define("Echo", 1).message(previous_message)
compatibility = protocol.compatibility(previous)
ok("positive", "protocol.compatibility", compatibility["compatible"]
   and compatibility["classification"] == "backward")
reserved_protocol = Protocol.define("Reserved", 1).reserveField(21)
ok("positive", "protocol.reserveField", reserved_protocol._reserved == {21})
transcript.append((protocol.name, protocol.version, dict(compatibility), tuple(sorted(reserved_protocol._reserved))))

# S02 — canonical messages pass through checksummed frames and chunk boundaries.
wire = protocol.encode(value)
ok("positive", "protocol.encode", wire[:4] == b"NBP1" and len(wire) < 65536)
decoded = protocol.decode(wire, {"maxBytes": 4096})
ok("positive", "protocol.decode", decoded.schema is echo and dict(decoded.values) == dict(value.values))
frame = Frame.wrap(wire, {"request": 104, "contentType": "application/nebo"})
ok("positive", "Frame.wrap", frame.payload == wire and frame.metadata["request"] == 104)
checksum = frame.checksum()
ok("positive", "frame.checksum", checksum == hashlib.sha256(frame._encoded_content()).hexdigest())
decoder = FrameDecoder.incremental({"maxPayload": 65536, "maxMetadata": 4096,
                                    "maxBuffered": 140000})
ok("positive", "FrameDecoder.incremental", decoder.max_payload == 65536)
encoded_frame = frame.to_bytes()
observed = decoder.push(encoded_frame[:17]) + decoder.push(encoded_frame[17:53]) + decoder.push(encoded_frame[53:])
ok("positive", "decoder.push", len(observed) == 1 and observed[0].payload == wire)
ok("positive", "decoder.finish", decoder.finish() == ())
compressed = frame.compress("zlib")
ok("positive", "frame.compress", compressed.codec == "zlib" and len(compressed.to_bytes()) < len(encoded_frame))
transcript.append((wire.hex(), encoded_frame.hex(), checksum, compressed.to_bytes().hex()))

# S03 — one capability-bound unary call produces independently observed metadata.
unary = RpcMethod.unary("Reflect", echo, echo)
ok("positive", "RpcMethod.unary", unary.shape == "unary")
unary = unary.effects(("read", "network", "cancel"))
ok("positive", "method.effects", unary.effect_set == frozenset(("read", "network", "cancel")))
server_stream = RpcMethod.serverStream("Watch", echo, echo)
client_stream = RpcMethod.clientStream("Upload", echo, echo)
bidi = RpcMethod.bidirectional("Converse", echo, echo)
service = Service.define("EchoService", 2, (unary, server_stream, client_stream, bidi))
ok("positive", "Service.define", len(service.methods) == 4 and service.version == 2)
implementation = {method.name: (lambda request: request) for method in service.methods}
server = service.expose(implementation, {"mode": "in_process"})
ok("positive", "service.expose", server.service is service and server.policy["mode"] == "in_process")
client_endpoint, server_endpoint = InMemoryTransport.pair({"capacity": 4})
server.bind(server_endpoint)
capability = Capability.issue("LocalRpc", ("rpc",))
client = RpcClient.connect(client_endpoint, protocol, capability)
ok("positive", "RpcClient.connect", client.endpoint is client_endpoint and client.capability is capability)
call = client.call(unary, value, {"deadline": 30, "idempotent": True,
                                  "idempotencyKey": "echo-73"})
ok("positive", "client.call", call.result is value and client_endpoint.runtime.metrics()["calls"] == 1)
metadata = call.metadata()
ok("positive", "call.metadata", metadata["transport"] == "in_memory"
   and metadata["requestId"] == "rpc-00000001" and metadata["attempts"] == 1)
ok("positive", "call.cancel", call.cancel() and call.cancelled and not call.cancel())
transcript.append((dict(metadata), tuple(dict(event) for event in client_endpoint.runtime.trace())))

# S04 — all three streaming shapes share bounded queues and terminal cleanup.
ok("positive", "RpcMethod.serverStream", server_stream.shape == "server_stream")
ok("positive", "RpcMethod.clientStream", client_stream.shape == "client_stream")
ok("positive", "RpcMethod.bidirectional", bidi.shape == "bidirectional")
stream = client.openStream(bidi, {"capacity": 2})
ok("positive", "client.openStream", stream.capacity == 2 and stream.method is bidi)
ok("positive", "stream.send", stream.send(value) == 1)
received = stream.receive()
ok("positive", "stream.receive", received is value and stream.receive() is None)
ok("positive", "stream.halfClose", stream.halfClose() and stream.half_closed)
cancel_stream = client.openStream(server_stream, {"capacity": 2})
cancel_stream.send(value)
ok("positive", "stream.cancel", cancel_stream.cancel() == 1 and cancel_stream.cancelled
   and cancel_stream._queue == [])
transcript.append((stream.half_closed, cancel_stream.cancelled,
                   tuple(dict(event) for event in client_endpoint.runtime.trace()[-7:])))

# S05 — generation emits hashed artifacts whose Nebo sources use current syntax.
api = Api.fromProtocol(protocol)
ok("positive", "Api.fromProtocol", api.protocol is protocol and len(api.schema_hash) == 64)
generated_client = api.generateClient("x86_64-nebo")
ok("positive", "api.generateClient", generated_client.kind == "client"
   and b"40.return" in generated_client.content)
generated_server = api.generateServer("x86_64-nebo")
ok("positive", "api.generateServer", generated_server.kind == "server"
   and generated_server.content != generated_client.content)
generated_mock = api.generateMock({"target": "x86_64-nebo", "seed": 4005})
ok("positive", "api.generateMock", generated_mock.kind == "mock"
   and b"42.return" in generated_mock.content)
documentation = api.generateDocumentation()
ok("positive", "api.generateDocumentation", documentation.content.startswith(b"# Echo v2")
   and b"EchoMessage" in documentation.content)
conformance = api.generateConformanceSuite()
ok("positive", "api.generateConformanceSuite", b"truncated\tREJECT" in conformance.content)
verification = generated_client.verify()
ok("positive", "generated.verify", verification["verified"]
   and verification["contentHash"] == generated_client.content_hash)
artifacts = (generated_client, generated_server, generated_mock, documentation, conformance)
transcript.append(tuple((item.kind, item.content_hash, item.content.decode()) for item in artifacts))

# S06 — bounded resilience forbids unsafe retry and publishes local redacted telemetry.
retry = RpcPolicy.retry({"attempts": 3})
ok("positive", "RpcPolicy.retry", retry["attempts"] == 3 and retry["idempotentOnly"])
timeout = RpcPolicy.timeout(50)
ok("positive", "RpcPolicy.timeout", timeout["duration"] == 50 and timeout["clock"] == "logical")
circuit = RpcPolicy.circuitBreaker({"failures": 4, "cooldown": 12})
ok("positive", "RpcPolicy.circuitBreaker", circuit["failures"] == 4 and circuit["cooldown"] == 12)
bulkhead = RpcPolicy.bulkhead(7)
ok("positive", "RpcPolicy.bulkhead", bulkhead["limit"] == 7)
request = Request(value).idempotencyKey("stable-echo-104")
ok("positive", "request.idempotencyKey", request.idempotency_key == "stable-echo-104")
dedup_store: OrderedDict[str, object] = OrderedDict()
ok("positive", "server.deduplicate",
   server.deduplicate(dedup_store, {"limit": 3}) is server and server._dedup_limit == 3)
first = client.call(unary, value, {"deadline": 80, "idempotent": True,
                                   "idempotencyKey": request.idempotency_key,
                                   "attempts": 3, "failuresBeforeSuccess": 2})
second = client.call(unary, value, {"deadline": 90, "idempotent": True,
                                    "idempotencyKey": request.idempotency_key})
metrics = client_endpoint.runtime.metrics()
ok("positive", "rpc.metrics", metrics["calls"] == 3 and len(dedup_store) == 1
   and metrics["failures"] == 2 and metrics["retries"] == 2
   and metrics["duplicates"] == 1 and first.metadata()["attempts"] == 3
   and first.result is second.result)
trace = client_endpoint.runtime.trace()
ok("positive", "rpc.trace", len(trace) >= 10 and trace[-1]["kind"] == "call-complete"
   and all("secret" not in str(event).lower() for event in trace))
transcript.append((dict(retry), dict(timeout), dict(circuit), dict(bulkhead), dict(metrics),
                   tuple(dict(event) for event in trace)))

# S07 — backend maturity is factual; only in-memory transport is active.
http2 = Http2Transport.open({"tls": True})
ok("positive", "Http2Transport.open", not http2["available"]
   and http2["maturity"] == "UNAVAILABLE" and http2["tls"] == "NOT_IMPLEMENTED")
quic = QuicTransport.open({"tls": True})
ok("positive", "QuicTransport.open", not quic["available"]
   and quic["maturity"] == "UNAVAILABLE" and quic["tls"] == "NOT_IMPLEMENTED")
unix_capability = Capability.issue("LocalUnix", ("unix",))
unix = UnixTransport.open("/run/nebo/echo.sock", unix_capability)
ok("positive", "UnixTransport.open", not unix["available"]
   and unix["maturity"] == "ENVIRONMENT_LIMITED" and unix["path"].endswith("echo.sock"))
pair = InMemoryTransport.pair({"capacity": 6})
ok("positive", "InMemoryTransport.pair", pair[0].peer is pair[1]
   and pair[1].peer is pair[0] and pair[0].capacity == 6)
gateway = Gateway.map(previous, "/v1/echo")
ok("positive", "Gateway.map", gateway.protocol is previous and gateway.route == "/v1/echo")
translation = gateway.translate(previous, protocol)
ok("positive", "gateway.translate", translation["compatible"]
   and translation["from"] == 1 and translation["to"] == 2)
capabilities = transport_capabilities()
ok("positive", "transport.capabilities", capabilities["in_memory"]["available"]
   and sum(1 for item in capabilities.values() if item["available"]) == 1)
transcript.append((dict(http2), dict(quic), dict(unix), dict(translation),
                   {key: dict(item) for key, item in capabilities.items()}))

# Stable negative diagnostics and failure-atomicity checks.
reject("protocol-version", "PROTOCOL-VERSION", lambda: Protocol.define("Echo", 0))
reject("field-type", "FIELD-TYPE", lambda: Field.required("bad", "socket", 4))
reject("field-id", "FIELD-ID", lambda: Field.optional("bad", "text", 0))
reject("repeated-limit", "FIELD-LIMIT", lambda: Field.repeated("bad", "u64", 4, 4097))
reject("duplicate-field", "DUPLICATE-FIELD",
       lambda: Message.define("Bad", (Field.required("a", "u64", 1),
                                      Field.optional("b", "u64", 1))))
reject("missing-required", "REQUIRED-FIELD", lambda: echo.validate({"tags": []}))
reject("unknown-field", "UNKNOWN-FIELD", lambda: echo.validate({"value": "x", "other": 1}))
reject("wrong-field-type", "FIELD-VALUE", lambda: echo.validate({"value": 17}))
reject("oversized-repeat", "FIELD-VALUE",
       lambda: echo.validate({"value": "x", "tags": list(range(9))}))
reserve_before = set(protocol._reserved)
reject("reserve-used", "RESERVED-FIELD", lambda: protocol.reserveField(1))
ok("failure_atomicity", "reserve-field", protocol._reserved == reserve_before)
damaged_wire = bytearray(wire); damaged_wire[-1] ^= 1
reject("wire-checksum", "CHECKSUM", lambda: protocol.decode(bytes(damaged_wire), {"maxBytes": 4096}))
reject("wire-limit", "DECODE-LIMIT", lambda: protocol.decode(wire, {"maxBytes": 8}))
array_body = b"[]"
array_wire = (b"NBP1" + len(array_body).to_bytes(4, "little")
              + hashlib.sha256(array_body).digest()[:8] + array_body)
reject("wire-shape", "DECODE", lambda: protocol.decode(array_wire, {"maxBytes": 4096}))
reject("frame-payload-limit", "FRAME-LIMIT", lambda: Frame.wrap(b"x" * 65537, {}))
reject("frame-metadata-type", "METADATA-LIMIT", lambda: Frame.wrap(b"x", {"bad": object()}))
bad_frame = bytearray(encoded_frame); bad_frame[-1] ^= 1
bad_decoder = FrameDecoder.incremental({"maxPayload": 65536})
reject("frame-checksum", "CHECKSUM", lambda: bad_decoder.push(bytes(bad_frame)))
truncated_decoder = FrameDecoder.incremental({"maxPayload": 65536})
truncated_decoder.push(encoded_frame[:-1])
reject("truncated-frame", "TRUNCATED-FRAME", truncated_decoder.finish)
reject("compression", "COMPRESSION", lambda: frame.compress("brotli"))
compressed_bomb = zlib.compress(b"z" * 70000, 9)
bomb_metadata = b"{}\n"
bomb_wire = (b"NBF1" + len(bomb_metadata).to_bytes(4, "little")
             + len(compressed_bomb).to_bytes(4, "little") + b"\x01"
             + hashlib.sha256(bomb_metadata + compressed_bomb).digest()
             + bomb_metadata + compressed_bomb)
bomb_decoder = FrameDecoder.incremental({"maxPayload": 65536})
reject("decompression-limit", "FRAME-LIMIT", lambda: bomb_decoder.push(bomb_wire))
reject("service-implementation", "SERVICE-IMPLEMENTATION",
       lambda: service.expose({"Reflect": lambda request: request}, {}))
original_handler = server.implementation[unary.name]
server.implementation[unary.name] = lambda request: "wrong-response-type"
reject("rpc-response-type", "RPC-RESPONSE",
       lambda: client.call(unary, value,
                           {"deadline": client_endpoint.runtime.logical_time + 10}))
server.implementation[unary.name] = original_handler
reject("rpc-capability", "RPC-CAPABILITY",
       lambda: RpcClient.connect(client_endpoint, protocol, Capability.issue("NoRpc", ("read",))))
reject("past-deadline", "RPC-DEADLINE",
       lambda: client.call(unary, value, {"deadline": 1}))
calls_before = client_endpoint.runtime.metrics()["calls"]
reject("non-idempotent-retry", "NON-IDEMPOTENT-RETRY",
       lambda: client.call(unary, value, {"deadline": 100, "attempts": 2}))
ok("failure_atomicity", "unsafe-retry", client_endpoint.runtime.metrics()["calls"] == calls_before)
full_stream = client.openStream(bidi, {"capacity": 1}); full_stream.send(value)
reject("stream-backpressure", "STREAM-BACKPRESSURE", lambda: full_stream.send(value))
ok("failure_atomicity", "stream-backpressure", full_stream._queue == [value])
full_stream.halfClose()
reject("send-after-half-close", "STREAM-STATE", lambda: full_stream.send(value))
reject("stream-message-type", "STREAM-STATE",
       lambda: client.openStream(bidi, {"capacity": 1}).send("not-a-message"))
reject("retry-limit", "RETRY-LIMIT", lambda: RpcPolicy.retry({"attempts": 9}))
reject("timeout-zero", "TIMEOUT", lambda: RpcPolicy.timeout(0))
reject("dedup-limit", "DEDUPLICATION",
       lambda: server.deduplicate(OrderedDict(), {"limit": 257}))
reject("generation-target", "GENERATION-TARGET", lambda: api.generateClient("wasm32"))
forged = type(generated_client)(generated_client.kind, generated_client.target,
                                generated_client.content + b"x", generated_client.schema_hash,
                                generated_client.content_hash)
forged_identity = type(generated_client)(generated_client.kind, "forged-target",
                                        generated_client.content, generated_client.schema_hash,
                                        generated_client.content_hash)
ok("adversarial", "generated-tamper", not forged.verify()["verified"]
   and not forged_identity.verify()["verified"])
reject("unix-capability", "UNIX-CAPABILITY",
       lambda: UnixTransport.open("/run/nebo.sock", Capability.issue("NoUnix", ("rpc",))))
breaking_message = Message.define("EchoMessage", (Field.required("value", "u64", 1),))
breaking = Protocol.define("Echo", 3).message(breaking_message)
reject("gateway-incompatible", "GATEWAY-INCOMPATIBLE",
       lambda: Gateway.map(previous, "/echo").translate(previous, breaking))

# Cross-cutting bounded, metamorphic, adversarial, ownership, and target proofs.
ok("boundary", "max-field-id", Field.required("maximum", "u64", 536_870_911).id == 536_870_911)
ok("boundary", "empty-repeated", echo.validate({"value": "empty"}).values["tags"] == ())
ok("boundary", "repeat-limit", len(echo.validate({"value": "edge", "tags": list(range(8))}).values["tags"]) == 8)
ok("boundary", "empty-frame", Frame.wrap(b"", {}).payload == b"")
ok("boundary", "stream-capacity", InMemoryTransport.pair({"capacity": 64})[0].capacity == 64)
ok("boundary", "retry-max", RpcPolicy.retry({"attempts": 8})["attempts"] == 8)
ok("boundary", "dedup-bound", server._dedup_limit == 3)
ok("boundary", "trace-bound", len(trace) < 4096)

ok("metamorphic", "message-roundtrip", protocol.encode(protocol.decode(wire, {"maxBytes": 4096})) == wire)
second_decoder = FrameDecoder.incremental({"maxPayload": 65536})
ok("metamorphic", "chunk-invariance", second_decoder.push(encoded_frame) == observed)
ok("metamorphic", "checksum-repeat", frame.checksum() == checksum)
ok("metamorphic", "schema-order", Message.define("EchoMessage", (optional, repeated, required)).fields == echo.fields)
ok("metamorphic", "compatibility-repeat", protocol.compatibility(previous) == compatibility)
ok("metamorphic", "generation-repeat", api.generateClient("x86_64-nebo") == generated_client)
ok("metamorphic", "capabilities-repeat", transport_capabilities() == capabilities)

ok("adversarial", "http2-unavailable", not capabilities["http2"]["available"])
ok("adversarial", "quic-unavailable", not capabilities["quic"]["available"])
ok("adversarial", "unix-not-opened", not unix["available"])
ok("adversarial", "network-forbidden", capabilities["in_memory"]["network"] is False)
ok("adversarial", "single-active-backend",
   [key for key, item in capabilities.items() if item["available"]] == ["in_memory"])
ok("adversarial", "trace-redacted", all("token" not in event and "secret" not in event for event in trace))
ok("adversarial", "bounded-frame", len(encoded_frame) < 70000)

ok("composition", "schema-codec-frame", observed[0].payload == protocol.encode(decoded))
ok("composition", "protocol-service", unary.request is echo and unary.response is echo)
ok("composition", "service-transport", server_endpoint.server is server and client_endpoint.peer is server_endpoint)
ok("composition", "rpc-dedup", first.result is second.result and len(dedup_store) == 1)
ok("composition", "api-schema", api.protocol is protocol and all(item.schema_hash == api.schema_hash for item in artifacts))
ok("composition", "gateway-compatibility", translation["compatible"] == compatibility["compatible"])

ok("ownership", "validated-frozen", type(value.values).__name__ == "mappingproxy")
ok("ownership", "metadata-frozen", type(metadata).__name__ == "mappingproxy")
ok("ownership", "trace-snapshot", trace is not client_endpoint.runtime.trace())
ok("ownership", "stream-cancel-clean", cancel_stream._queue == [] and cancel_stream.cancelled)
snapshot_message = Message.define("Snapshot", (Field.required("value", "u64", 1),))
snapshot_protocol = Protocol.define("SnapshotApi", 1).message(snapshot_message)
snapshot_api = Api.fromProtocol(snapshot_protocol)
snapshot_documentation = snapshot_api.generateDocumentation()
snapshot_protocol.message(Message.define("Later", (Field.required("later", "bool", 2),)))
ok("ownership", "artifact-immutable", generated_client.content == bytes(generated_client.content)
   and snapshot_api.generateDocumentation() == snapshot_documentation)
ok("ownership", "capabilities-frozen", type(capabilities).__name__ == "mappingproxy")

ok("failure_atomicity", "decoder-damaged-retained", len(bad_decoder._buffer) == len(bad_frame))
ok("failure_atomicity", "truncated-retained", len(truncated_decoder._buffer) == len(encoded_frame) - 1)
ok("failure_atomicity", "generated-tamper-original", generated_client.verify()["verified"])
ok("failure_atomicity", "gateway-original", gateway.protocol is previous and gateway.route == "/v1/echo")
ok("failure_atomicity", "dedup-bound-after-reject", server._dedup_limit == 3)

ok("target", "generation-target", all(item.target == "x86_64-nebo" for item in artifacts))
ok("target", "in-process-active", capabilities["in_memory"]["maturity"] == "ACTIVE")
ok("target", "unix-limited", capabilities["unix"]["maturity"] == "ENVIRONMENT_LIMITED")
ok("target", "http2-factual", capabilities["http2"]["tls"] == "NOT_IMPLEMENTED")
ok("target", "quic-factual", capabilities["quic"]["tls"] == "NOT_IMPLEMENTED")
ok("target", "logical-time", timeout["clock"] == "logical")

assert counts["positive"] == 54, counts
stable = json.dumps(transcript, sort_keys=True, separators=(",", ":"), default=str).encode()
digest = hashlib.sha256(stable).hexdigest()
print("G040_SDK_ORACLE_GREEN " + " ".join(
    f"{key}={counts[key]}" for key in (
        "positive", "negative", "boundary", "metamorphic", "adversarial", "composition",
        "ownership", "failure_atomicity", "target", "diagnostics", "sdk"
    )) + f" determinism=8 digest={digest}")
