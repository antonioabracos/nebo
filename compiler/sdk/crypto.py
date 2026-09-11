"""Bounded, fail-closed advanced-cryptography reference profile for G044.

Only SHA-256 and HMAC-SHA-256 operations already available from the Python
standard library are executable.  Post-quantum, zero-knowledge proof,
cryptographic secret-sharing/MPC, hardware attestation, dynamic leakage, and
persistent vault operations remain gated.  Metadata/state-machine objects make
their contracts testable without pretending that unavailable cryptography or
hardware exists.  All examples and tests use synthetic bytes only.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import dis
import hashlib
import hmac
import json
import re
from types import MappingProxyType
from typing import Any, Callable, Mapping, Sequence


MAX_TEXT_BYTES = 4096
MAX_PARAMETER_SETS = 16
MAX_CIRCUIT_INPUTS = 64
MAX_CONSTRAINTS = 256
MAX_RANGE_BITS = 256
MAX_PARTICIPANTS = 16
MAX_MPC_OPERATIONS = 128
MAX_TRANSCRIPT_EVENTS = 256
MAX_VAULT_KEYS = 64


class CryptoError(ValueError):
    """Stable fail-closed diagnostic that never embeds secret material."""

    def __init__(self, code: str, operation: str, detail: str) -> None:
        super().__init__(f"NEBO-G044-{code}: {operation}: {detail}")
        self.code = code
        self.operation = operation


def _fail(code: str, operation: str, detail: str) -> None:
    raise CryptoError(code, operation, detail)


def _text(value: Any, operation: str, name: str, maximum: int = MAX_TEXT_BYTES) -> str:
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
    if not isinstance(value, Mapping) or not all(isinstance(key, str) for key in value):
        _fail("MAPPING", operation, f"{name} must be a text-keyed mapping")
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
    data = value if isinstance(value, bytes) else _canonical(value)
    return hashlib.sha256(data).hexdigest()


def _freeze(value: Any) -> Any:
    plain = _plain(value)
    if isinstance(plain, dict):
        return MappingProxyType({key: _freeze(item) for key, item in plain.items()})
    if isinstance(plain, list):
        return tuple(_freeze(item) for item in plain)
    return plain


@dataclass
class Capability:
    kind: str
    identity: str
    _material: bytearray = field(default_factory=bytearray, repr=False)
    _used: bool = field(default=False, repr=False)

    @staticmethod
    def issue(kind: str, identity: str, synthetic_material: bytes = b"") -> "Capability":
        operation = "Capability.issue"
        checked_kind = _text(kind, operation, "kind", 64)
        if checked_kind not in {"entropy.synthetic", "secret.declassify", "vault.local"}:
            _fail("CAPABILITY-UNKNOWN", operation, checked_kind)
        checked_identity = _text(identity, operation, "identity", 256)
        if not isinstance(synthetic_material, bytes):
            _fail("BYTES", operation, "synthetic material must be bytes")
        if checked_kind == "entropy.synthetic" and len(synthetic_material) != 32:
            _fail("ENTROPY", operation, "synthetic entropy must contain exactly 32 bytes")
        if checked_kind != "entropy.synthetic" and synthetic_material:
            _fail("CAPABILITY", operation, "only synthetic entropy carries material")
        return Capability(checked_kind, checked_identity, bytearray(synthetic_material))

    def consume_entropy(self, operation: str) -> bytearray:
        if self.kind != "entropy.synthetic" or self._used or len(self._material) != 32:
            _fail("CAPABILITY-DENIED", operation, "fresh entropy.synthetic capability required")
        self._used = True
        material = bytearray(self._material)
        for index in range(len(self._material)):
            self._material[index] = 0
        return material


@dataclass(frozen=True)
class CryptoAlgorithm:
    algorithm_id: str
    version: str
    target_bits: int
    assumptions: tuple[str, ...]
    _status: str
    parameters: Mapping[str, Mapping[str, Any]]
    review: str
    vector: str
    implementation: str

    @staticmethod
    def lookup(identifier: str, version: str) -> "CryptoAlgorithm":
        operation = "CryptoAlgorithm.lookup"
        key = (_text(identifier, operation, "id", 128), _text(version, operation, "version", 64))
        algorithm = _REGISTRY.get(key)
        if algorithm is None:
            _fail("ALGORITHM-FORBIDDEN", operation, "unknown id/version")
        return algorithm

    def securityLevel(self) -> Mapping[str, Any]:
        return _freeze({"targetBits": self.target_bits, "assumptions": self.assumptions,
                        "scope": "reviewed-implementation-only"})

    def parameterSet(self, name: str) -> Mapping[str, Any]:
        operation = "algorithm.parameterSet"
        checked = _text(name, operation, "name", 128)
        value = self.parameters.get(checked)
        if value is None:
            _fail("PARAMETER-SET", operation, "unknown parameter set")
        return _freeze(value)

    def status(self) -> str:
        return self._status


_REGISTRY: dict[tuple[str, str], CryptoAlgorithm] = {}


def _register(identifier: str, version: str, bits: int, assumptions: tuple[str, ...],
              status: str, parameters: Mapping[str, Mapping[str, Any]], review: str,
              vector: str, implementation: str) -> None:
    if status not in {"approved", "experimental", "deprecated", "forbidden"}:
        raise AssertionError(status)
    if len(parameters) > MAX_PARAMETER_SETS:
        raise AssertionError("parameter set limit")
    _REGISTRY[(identifier, version)] = CryptoAlgorithm(
        identifier, version, bits, assumptions, status, _freeze(parameters), review,
        vector, implementation,
    )


_register("SHA-256", "FIPS-180-4", 128, ("collision-resistance",), "approved",
          {"SHA-256": {"digestBytes": 32, "blockBytes": 64}},
          "STANDARD_LIBRARY_REVIEWED_BASE", "FIPS-180-4-ABC", "python.hashlib.sha256")
_register("HMAC-SHA256", "RFC-2104", 128, ("pseudorandom-function",), "approved",
          {"HMAC-SHA256-256": {"tagBytes": 32, "minimumKeyBytes": 16}},
          "STANDARD_LIBRARY_REVIEWED_BASE", "RFC-4231-TC1", "python.hmac")
_register("ML-KEM", "FIPS-203", 192, ("module-lattice",), "experimental",
          {"ML-KEM-768": {"claimedCategory": 3}}, "EXTERNAL_REVIEW_REQUIRED",
          "OFFICIAL_VECTORS_NOT_BUNDLED", "UNAVAILABLE")
_register("ML-DSA", "FIPS-204", 192, ("module-lattice",), "experimental",
          {"ML-DSA-65": {"claimedCategory": 3}}, "EXTERNAL_REVIEW_REQUIRED",
          "OFFICIAL_VECTORS_NOT_BUNDLED", "UNAVAILABLE")
_register("ATTESTATION", "LOCAL-V1", 0, ("hardware-root",), "forbidden",
          {"HARDWARE": {"available": False}}, "HARDWARE_UNAVAILABLE",
          "NONE", "UNAVAILABLE")


class Key:
    def __init__(self, algorithm: CryptoAlgorithm, material: bytearray, identity_source: str) -> None:
        self.algorithm = algorithm
        self._material = material
        self._destroyed = False
        self._owner: str | None = None
        self.identity = _digest({"algorithm": algorithm.algorithm_id, "capability": identity_source})

    @staticmethod
    def generate(algorithm: CryptoAlgorithm, capability: Capability) -> "Key":
        operation = "Key.generate"
        if not isinstance(algorithm, CryptoAlgorithm) or algorithm._status != "approved":
            _fail("ALGORITHM-UNAVAILABLE", operation, "approved algorithm required")
        if algorithm.algorithm_id != "HMAC-SHA256":
            _fail("KEY-TYPE", operation, "algorithm has no key generation surface")
        if not isinstance(capability, Capability):
            _fail("CAPABILITY-DENIED", operation, "entropy capability required")
        identity_source = capability.identity
        return Key(algorithm, capability.consume_entropy(operation), identity_source)

    def _live(self, operation: str) -> None:
        if self._destroyed:
            _fail("KEY-DESTROYED", operation, "key handle is invalid")

    def publicPart(self) -> Mapping[str, Any]:
        self._live("key.publicPart")
        _fail("KEY-TYPE", "key.publicPart", "symmetric key has no public part")

    def destroy(self) -> Mapping[str, Any]:
        operation = "key.destroy"
        self._live(operation)
        if self._owner is not None:
            _fail("KEY-OWNED", operation, "key lifecycle belongs to a vault")
        return self._erase()

    def _erase(self) -> Mapping[str, Any]:
        for index in range(len(self._material)):
            self._material[index] = 0
        self._destroyed = True
        return _freeze({"destroyed": True, "physicalZeroizationGuaranteed": False})

    def _transfer(self, owner: str, operation: str) -> None:
        self._live(operation)
        if self._owner is not None:
            _fail("KEY-OWNED", operation, "key already belongs to a vault")
        self._owner = owner

    def _destroy_owned(self, owner: str, operation: str) -> Mapping[str, Any]:
        self._live(operation)
        if self._owner != owner:
            _fail("KEY-OWNED", operation, "vault does not own key")
        return self._erase()

    def _copy_material(self, operation: str) -> bytes:
        self._live(operation)
        return bytes(self._material)


class _CryptoService:
    def selfTest(self) -> Mapping[str, Any]:
        sha = hashlib.sha256(b"abc").hexdigest()
        tag = hmac.new(bytes.fromhex("0b" * 20), b"Hi There", hashlib.sha256).hexdigest()
        expected_sha = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        expected_tag = "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
        if sha != expected_sha or tag != expected_tag:
            _fail("SELF-TEST", "crypto.selfTest", "reviewed base vector mismatch")
        return _freeze({"vectors": 2, "passed": 2, "algorithms": ("SHA-256", "HMAC-SHA256"),
                        "advanced": "GATED"})


crypto = _CryptoService()


def _advanced_unavailable(operation: str, family: str) -> None:
    _fail("EXTERNAL-REVIEW-REQUIRED", operation,
          f"{family} implementation, official vectors, provenance, and review are unavailable")


class PqcKem:
    def __init__(self, parameter_set: str = "ML-KEM-768") -> None:
        self.parameter_set = _text(parameter_set, "PqcKem.auditHandle", "parameterSet", 128)

    @staticmethod
    def keyPair(parameterSet: str) -> None:
        CryptoAlgorithm.lookup("ML-KEM", "FIPS-203").parameterSet(parameterSet)
        _advanced_unavailable("PqcKem.keyPair", "PQC KEM")

    def encapsulate(self, publicKey: Any, random: Any) -> None:
        _advanced_unavailable("kem.encapsulate", "PQC KEM")

    def decapsulate(self, ciphertext: Any, privateKey: Any) -> None:
        _advanced_unavailable("kem.decapsulate", "PQC KEM")


class PqcSignature:
    def __init__(self, parameter_set: str = "ML-DSA-65") -> None:
        self.parameter_set = _text(parameter_set, "PqcSignature.auditHandle", "parameterSet", 128)

    @staticmethod
    def keyPair(parameterSet: str) -> None:
        CryptoAlgorithm.lookup("ML-DSA", "FIPS-204").parameterSet(parameterSet)
        _advanced_unavailable("PqcSignature.keyPair", "PQC signature")

    def sign(self, message: Any, privateKey: Any, random: Any) -> None:
        _advanced_unavailable("signature.sign", "PQC signature")

    def verify(self, message: Any, signature: Any, publicKey: Any) -> None:
        _advanced_unavailable("signature.verify", "PQC signature")


class HybridKex:
    @staticmethod
    def combine(classical: Any, postQuantum: Any) -> None:
        _advanced_unavailable("HybridKex.combine", "hybrid key exchange")


class _PqcService:
    def vectorReport(self) -> Mapping[str, Any]:
        return _freeze({
            "ML-KEM-768": {"standard": "FIPS-203", "implementation": "UNAVAILABLE",
                           "vectors": "NOT_BUNDLED", "review": "EXTERNAL_REVIEW_REQUIRED"},
            "ML-DSA-65": {"standard": "FIPS-204", "implementation": "UNAVAILABLE",
                          "vectors": "NOT_BUNDLED", "review": "EXTERNAL_REVIEW_REQUIRED"},
            "target": "x86_64-linux-local", "quantumSafeClaim": False,
        })


pqc = _PqcService()


class ProofCircuit:
    def __init__(self, field_name: str, limits: Mapping[str, Any]) -> None:
        operation = "ProofCircuit.new"
        if _text(field_name, operation, "field", 64) not in {"BN254-METADATA", "BLS12-381-METADATA"}:
            _fail("FIELD", operation, "only metadata profiles are recognized")
        values = dict(_mapping(limits, operation, "limits"))
        _fields(values, {"inputs", "constraints", "rangeBits"}, operation)
        self.field = field_name
        self.limits = _freeze({
            "inputs": _integer(values.get("inputs"), operation, "inputs", 1, MAX_CIRCUIT_INPUTS),
            "constraints": _integer(values.get("constraints"), operation, "constraints", 1, MAX_CONSTRAINTS),
            "rangeBits": _integer(values.get("rangeBits"), operation, "rangeBits", 1, MAX_RANGE_BITS),
        })
        self._inputs: dict[str, tuple[str, str]] = {}
        self._constraints: list[Mapping[str, Any]] = []

    @staticmethod
    def new(field: str, limits: Mapping[str, Any]) -> "ProofCircuit":
        return ProofCircuit(field, limits)

    def _input(self, visibility: str, name: str, value_type: str) -> "ProofCircuit":
        operation = f"circuit.{visibility}Input"
        checked = _text(name, operation, "name", 128)
        kind = _text(value_type, operation, "type", 32)
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", checked) or kind not in {"field", "u64", "bool"}:
            _fail("INPUT", operation, "invalid name or type")
        if checked in self._inputs or len(self._inputs) >= self.limits["inputs"]:
            _fail("INPUT-LIMIT", operation, "duplicate input or input limit")
        self._inputs[checked] = (visibility, kind)
        return self

    def publicInput(self, name: str, type: str) -> "ProofCircuit":
        return self._input("public", name, type)

    def privateInput(self, name: str, type: str) -> "ProofCircuit":
        return self._input("private", name, type)

    def _constraint(self, operation: str, value: Mapping[str, Any]) -> "ProofCircuit":
        if len(self._constraints) >= self.limits["constraints"]:
            _fail("CONSTRAINT-LIMIT", operation, "constraint limit reached")
        self._constraints.append(_freeze(value))
        return self

    def assertEqual(self, a: str, b: str) -> "ProofCircuit":
        operation = "circuit.assertEqual"
        left = _text(a, operation, "a", 128)
        right = _text(b, operation, "b", 128)
        if left not in self._inputs or right not in self._inputs:
            _fail("INPUT", operation, "constraint references unknown input")
        return self._constraint(operation, {"kind": "equal", "left": left, "right": right})

    def rangeCheck(self, value: str, bits: int) -> "ProofCircuit":
        operation = "circuit.rangeCheck"
        checked = _text(value, operation, "value", 128)
        if checked not in self._inputs:
            _fail("INPUT", operation, "range check references unknown input")
        width = _integer(bits, operation, "bits", 1, self.limits["rangeBits"])
        return self._constraint(operation, {"kind": "range", "value": checked, "bits": width})

    def compile(self, backend: str) -> Mapping[str, Any]:
        operation = "circuit.compile"
        if _text(backend, operation, "backend", 64) != "CONSTRAINTS-ONLY-V1":
            _advanced_unavailable(operation, "zero-knowledge backend")
        if not self._inputs or not self._constraints:
            _fail("CIRCUIT-STATE", operation, "inputs and constraints are required")
        descriptor = {"field": self.field, "limits": self.limits, "inputs": self._inputs,
                      "constraints": self._constraints, "backend": backend}
        return _freeze({"backend": backend, "digest": _digest(descriptor),
                        "constraints": len(self._constraints), "proofCapable": False,
                        "review": "EXTERNAL_REVIEW_REQUIRED"})

    def prove(self, witness: Any, random: Any) -> None:
        _advanced_unavailable("circuit.prove", "zero-knowledge proof")

    def _statistics(self) -> Mapping[str, Any]:
        return _freeze({"constraints": len(self._constraints), "inputs": len(self._inputs),
                        "bytes": len(_canonical(self._constraints)), "timeNanos": 0,
                        "memoryBytes": 0, "generated": False})


class Proof:
    def __init__(self, circuit: ProofCircuit) -> None:
        if not isinstance(circuit, ProofCircuit):
            _fail("CIRCUIT", "Proof.auditHandle", "circuit required")
        self._circuit = circuit

    def verify(self, publicInputs: Any, verificationKey: Any) -> None:
        _advanced_unavailable("proof.verify", "zero-knowledge proof")

    def statistics(self) -> Mapping[str, Any]:
        return self._circuit._statistics()


class SecretShare:
    @staticmethod
    def split(secret: Any, threshold: int, parties: int, random: Any) -> None:
        checked_threshold = _integer(threshold, "SecretShare.split", "threshold", 2, MAX_PARTICIPANTS)
        checked_parties = _integer(parties, "SecretShare.split", "parties", 2, MAX_PARTICIPANTS)
        if checked_threshold > checked_parties:
            _fail("LIMIT", "SecretShare.split", "threshold cannot exceed parties")
        _advanced_unavailable("SecretShare.split", "cryptographic secret sharing")

    @staticmethod
    def combine(shares: Any) -> None:
        _sequence(shares, "SecretShare.combine", "shares")
        _advanced_unavailable("SecretShare.combine", "cryptographic secret sharing")


class Share:
    def refresh(self, session: Any) -> None:
        _advanced_unavailable("share.refresh", "cryptographic share refresh")


class MpcSession:
    def __init__(self, participants: Sequence[str], protocol: str, policy: Mapping[str, Any]) -> None:
        operation = "MpcSession.new"
        items = tuple(_text(item, operation, "participant", 128)
                      for item in _sequence(participants, operation, "participants"))
        if not 2 <= len(items) <= MAX_PARTICIPANTS or len(set(items)) != len(items):
            _fail("PARTICIPANTS", operation, "participants must be distinct and bounded")
        if _text(protocol, operation, "protocol", 64) != "LOCAL-TRANSCRIPT-V1":
            _fail("PROTOCOL", operation, "only non-cryptographic local transcript profile exists")
        values = dict(_mapping(policy, operation, "policy"))
        _fields(values, {"mode", "maxOperations"}, operation)
        if values.get("mode") != "simulation":
            _fail("POLICY", operation, "mode must be simulation")
        self.participants = items
        self.protocol = protocol
        self.max_operations = _integer(values.get("maxOperations"), operation, "maxOperations", 1,
                                       MAX_MPC_OPERATIONS)
        self._events: list[Mapping[str, Any]] = []
        self._committed = False
        self._aborted = False

    @staticmethod
    def new(participants: Sequence[str], protocol: str, policy: Mapping[str, Any]) -> "MpcSession":
        return MpcSession(participants, protocol, policy)

    def _active(self, operation: str) -> None:
        if self._aborted:
            _fail("SESSION-ABORTED", operation, "session is not active")

    def _event(self, value: Mapping[str, Any], operation: str) -> None:
        if len(self._events) >= min(self.max_operations, MAX_TRANSCRIPT_EVENTS):
            _fail("OPERATION-LIMIT", operation, "session operation limit reached")
        self._events.append(_freeze(value))

    def commitInputs(self, inputs: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "session.commitInputs"
        self._active(operation)
        if self._committed:
            _fail("STATE", operation, "inputs already committed")
        values = _mapping(inputs, operation, "inputs")
        if set(values) != set(self.participants):
            _fail("PARTICIPANTS", operation, "one input per participant is required")
        commitment = _digest({"session": self.protocol, "participants": self.participants,
                              "event": len(self._events)})
        self._event({"event": "inputs-committed", "participants": len(values)}, operation)
        self._committed = True
        return _freeze({"commitment": commitment, "valuesRedacted": True})

    def compute(self, function: str, inputs: Sequence[int]) -> Mapping[str, Any]:
        operation = "session.compute"
        self._active(operation)
        if not self._committed:
            _fail("STATE", operation, "inputs must be committed first")
        if _text(function, operation, "function", 64) != "sum":
            _fail("FUNCTION", operation, "only bounded local sum simulation is allowed")
        values = tuple(_integer(item, operation, "input", -1_000_000, 1_000_000)
                       for item in _sequence(inputs, operation, "inputs"))
        if len(values) != len(self.participants):
            _fail("PARTICIPANTS", operation, "input count must match participants")
        result = sum(values)
        self._event({"event": "computed", "function": "sum", "inputsConsumed": len(values)},
                    operation)
        return _freeze({"result": result, "mode": "LOCAL_SIMULATION", "mpcSecurityClaim": False})

    def abort(self, reason: str) -> Mapping[str, Any]:
        operation = "session.abort"
        self._active(operation)
        checked = _text(reason, operation, "reason", 256)
        if len(self._events) < MAX_TRANSCRIPT_EVENTS:
            self._events.append(_freeze({"event": "aborted", "reasonDigest": _digest(checked)}))
        self._aborted = True
        return _freeze({"aborted": True, "stateCleared": True})

    def transcript(self) -> Mapping[str, Any]:
        events = tuple(_freeze(event) for event in self._events)
        return _freeze({"protocol": self.protocol, "participants": self.participants,
                        "events": events, "digest": _digest(events), "redacted": True,
                        "mpcSecurityClaim": False})


class SecureContext:
    def __init__(self, backend: str, policy: Mapping[str, Any]) -> None:
        self.backend = backend
        self.policy = _freeze(policy)
        self._destroyed = False

    @staticmethod
    def open(backend: str, policy: Mapping[str, Any]) -> "SecureContext":
        operation = "SecureContext.open"
        if _text(backend, operation, "backend", 64) != "SIMULATED-NO-TEE":
            _fail("HARDWARE-UNAVAILABLE", operation, "no factual attestation backend is present")
        values = dict(_mapping(policy, operation, "policy"))
        _fields(values, {"allowSimulation"}, operation)
        if values.get("allowSimulation") is not True:
            _fail("POLICY", operation, "simulation must be explicit")
        return SecureContext(backend, values)

    def _live(self, operation: str) -> None:
        if self._destroyed:
            _fail("CONTEXT-DESTROYED", operation, "context is closed")

    def measurement(self) -> Mapping[str, Any]:
        self._live("context.measurement")
        return _freeze({"digest": _digest({"backend": self.backend, "policy": self.policy}),
                        "hardware": False, "attested": False, "kind": "SIMULATION_IDENTITY"})

    def destroy(self) -> Mapping[str, Any]:
        self._live("context.destroy")
        self._destroyed = True
        return _freeze({"destroyed": True, "secretsInvalidated": True})


class Attestation:
    @staticmethod
    def request(context: SecureContext, nonce: bytes) -> None:
        if not isinstance(context, SecureContext) or not isinstance(nonce, bytes) or not nonce:
            _fail("ATTESTATION-INPUT", "Attestation.request", "live context and nonce required")
        context._live("Attestation.request")
        _fail("HARDWARE-UNAVAILABLE", "Attestation.request", "no hardware report can be issued")

    @staticmethod
    def verify(report: Any, policy: Mapping[str, Any], roots: Sequence[Any]) -> None:
        _mapping(policy, "Attestation.verify", "policy")
        _sequence(roots, "Attestation.verify", "roots")
        _fail("HARDWARE-UNAVAILABLE", "Attestation.verify", "no trusted hardware verifier is present")


class _AttestationService:
    def provenance(self) -> Mapping[str, Any]:
        return _freeze({"hardware": "UNAVAILABLE", "firmware": "UNAVAILABLE",
                        "verifier": "NONE", "trustRoots": 0, "policy": "FAIL_CLOSED",
                        "attestationClaim": False})


attestation = _AttestationService()


class Secret:
    def __init__(self, material: bytes) -> None:
        if not isinstance(material, bytes) or not 1 <= len(material) <= 4096:
            _fail("SECRET", "Secret.synthetic", "bounded synthetic bytes required")
        self._material = bytearray(material)
        self._audit: list[str] = []

    @staticmethod
    def synthetic(material: bytes) -> "Secret":
        return Secret(material)

    def seal(self, context: SecureContext, policy: Mapping[str, Any]) -> None:
        if not isinstance(context, SecureContext):
            _fail("CONTEXT", "secret.seal", "secure context required")
        context._live("secret.seal")
        _mapping(policy, "secret.seal", "policy")
        _fail("HARDWARE-UNAVAILABLE", "secret.seal", "simulation cannot seal secret material")

    def declassify(self, reason: str, capability: Capability) -> bytes:
        operation = "secret.declassify"
        checked = _text(reason, operation, "reason", 256)
        if not isinstance(capability, Capability) or capability.kind != "secret.declassify":
            _fail("CAPABILITY-DENIED", operation, "secret.declassify capability required")
        if capability._used:
            _fail("CAPABILITY-DENIED", operation, "fresh declassification capability required")
        capability._used = True
        self._audit.append(_digest({"reason": checked, "capability": capability.identity}))
        return bytes(self._material)

    def audit(self) -> tuple[str, ...]:
        return tuple(self._audit)


class Sealed:
    def unseal(self, context: SecureContext) -> None:
        if not isinstance(context, SecureContext):
            _fail("CONTEXT", "sealed.unseal", "secure context required")
        _fail("HARDWARE-UNAVAILABLE", "sealed.unseal", "no hardware-sealed value exists")


def constantTime(function: Callable[..., Any]) -> Callable[..., Any]:
    if not callable(function):
        _fail("FUNCTION", "constantTime function", "callable required")
    setattr(function, "__nebo_constant_time_contract__", True)
    return function


class Verify:
    @staticmethod
    def constantTime(function: Callable[..., Any], target: str) -> Mapping[str, Any]:
        operation = "verify.constantTime"
        if not callable(function) or not getattr(function, "__nebo_constant_time_contract__", False):
            _fail("CONSTANT-TIME-CONTRACT", operation, "marked callable required")
        if _text(target, operation, "target", 128) != "x86_64-linux-bounded-static-v1":
            _fail("TARGET", operation, "unsupported analysis target")
        instructions = tuple(dis.get_instructions(function))
        branches = tuple(item.opname for item in instructions if "JUMP" in item.opname)
        indexing = tuple(item.opname for item in instructions if item.opname == "BINARY_SUBSCR")
        return _freeze({"branches": branches, "secretIndexedLoads": indexing,
                        "instructions": len(instructions), "staticPass": not branches and not indexing,
                        "constantTimeProof": False, "target": target})


verify = Verify()


class LeakageTest:
    @staticmethod
    def dudect(function: Callable[..., Any], corpus: Sequence[bytes],
               options: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "LeakageTest.dudect"
        if not callable(function):
            _fail("FUNCTION", operation, "callable required")
        values = _sequence(corpus, operation, "corpus")
        settings = dict(_mapping(options, operation, "options"))
        _fields(settings, {"samples", "confidence"}, operation)
        samples = _integer(settings.get("samples"), operation, "samples", 2, 1_000_000)
        confidence = settings.get("confidence")
        if (isinstance(confidence, bool) or not isinstance(confidence, int)
                or not 5000 <= confidence <= 9999):
            _fail("OPTIONS", operation, "confidence must be integer basis points in [5000, 9999]")
        if not all(isinstance(item, bytes) and item for item in values):
            _fail("CORPUS", operation, "non-empty synthetic byte samples required")
        return _freeze({"executed": False, "requestedSamples": samples, "observedSamples": 0,
                        "confidenceBasisPoints": confidence,
                        "status": "ENVIRONMENT_LIMITED", "leakageProof": False})

    @staticmethod
    def cacheTrace(function: Callable[..., Any], corpus: Sequence[bytes]) -> Mapping[str, Any]:
        operation = "LeakageTest.cacheTrace"
        if not callable(function) or not _sequence(corpus, operation, "corpus"):
            _fail("CORPUS", operation, "callable and non-empty corpus required")
        return _freeze({"executed": False, "traces": 0, "status": "ENVIRONMENT_LIMITED",
                        "cacheIsolationAvailable": False, "leakageProof": False})


class _SecurityService:
    def timingReport(self) -> Mapping[str, Any]:
        return _freeze({"staticRuleset": "x86_64-bounded-v1", "dynamicTests": "NOT_EXECUTED",
                        "confidence": "NONE", "microarchitectures": 0,
                        "constantTimeProof": False, "limitations": "ENVIRONMENT_LIMITED"})

    def compilerBarrier(self) -> Mapping[str, Any]:
        return _freeze({"inserted": False, "targetContract": "UNAVAILABLE",
                        "reason": "REFERENCE_PROFILE_CANNOT_EMIT_COMPILER_BARRIER"})


security = _SecurityService()


class KeyVault:
    def __init__(self, capability: Capability, policy: Mapping[str, Any]) -> None:
        self.capability = capability
        self.policy = _freeze(policy)
        self._owner = _digest({"vault": capability.identity})
        self._records: dict[str, dict[str, Any]] = {}

    @staticmethod
    def local(capability: Capability, policy: Mapping[str, Any]) -> "KeyVault":
        operation = "KeyVault.local"
        if not isinstance(capability, Capability) or capability.kind != "vault.local":
            _fail("CAPABILITY-DENIED", operation, "vault.local capability required")
        values = dict(_mapping(policy, operation, "policy"))
        _fields(values, {"storage", "maxKeys"}, operation)
        if values.get("storage") != "memory-only":
            _fail("PERSISTENCE-UNAVAILABLE", operation, "only memory-only reference vault exists")
        values["maxKeys"] = _integer(values.get("maxKeys"), operation, "maxKeys", 1, MAX_VAULT_KEYS)
        return KeyVault(capability, values)

    def store(self, key: Key, metadata: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "vault.store"
        if not isinstance(key, Key):
            _fail("KEY", operation, "key handle required")
        key._live(operation)
        values = dict(_mapping(metadata, operation, "metadata"))
        _fields(values, {"identity", "purpose"}, operation)
        identity = _text(values.get("identity"), operation, "identity", 128)
        purpose = _text(values.get("purpose"), operation, "purpose", 256)
        if identity in self._records or len(self._records) >= self.policy["maxKeys"]:
            _fail("VAULT-LIMIT", operation, "duplicate identity or key limit")
        key._transfer(self._owner, operation)
        self._records[identity] = {"key": key, "purpose": purpose, "version": 1, "revoked": False}
        return _freeze({"identity": identity, "version": 1, "storage": "OPAQUE_MEMORY_ONLY",
                        "persistent": False})

    def rotate(self, identity: str, schedule: Mapping[str, Any]) -> Mapping[str, Any]:
        operation = "vault.rotate"
        checked = _text(identity, operation, "identity", 128)
        values = dict(_mapping(schedule, operation, "schedule"))
        _fields(values, {"replacement", "effectiveEpoch"}, operation)
        record = self._records.get(checked)
        replacement = values.get("replacement")
        if (record is None or record["revoked"] or not isinstance(replacement, Key)
                or replacement is record["key"]):
            _fail("VAULT-STATE", operation, "live identity and replacement key required")
        replacement._live(operation)
        if replacement._owner is not None:
            _fail("KEY-OWNED", operation, "replacement key already belongs to a vault")
        epoch = _integer(values.get("effectiveEpoch"), operation, "effectiveEpoch", 0, 2**63 - 1)
        record["key"]._destroy_owned(self._owner, operation)
        replacement._transfer(self._owner, operation)
        record["key"] = replacement
        record["version"] += 1
        return _freeze({"identity": checked, "version": record["version"], "effectiveEpoch": epoch,
                        "previousDestroyed": True})

    def revoke(self, identity: str, reason: str) -> Mapping[str, Any]:
        operation = "vault.revoke"
        checked = _text(identity, operation, "identity", 128)
        detail = _text(reason, operation, "reason", 256)
        record = self._records.get(checked)
        if record is None or record["revoked"]:
            _fail("VAULT-STATE", operation, "live identity required")
        record["key"]._destroy_owned(self._owner, operation)
        record["revoked"] = True
        return _freeze({"identity": checked, "revoked": True, "reasonDigest": _digest(detail),
                        "keyDestroyed": True})


class CryptoProtocol:
    _ALLOWLIST = {("SHA-256", "HMAC-SHA256"): "FIPS-180-4+RFC-2104"}

    def __init__(self, steps: tuple[str, ...], review: str) -> None:
        self.steps = steps
        self.review = review

    @staticmethod
    def compose(steps: Sequence[str]) -> "CryptoProtocol":
        operation = "CryptoProtocol.compose"
        checked = tuple(_text(item, operation, "step", 128)
                        for item in _sequence(steps, operation, "steps"))
        review = CryptoProtocol._ALLOWLIST.get(checked)
        if review is None:
            _fail("COMPOSITION-FORBIDDEN", operation, "construction is not allowlisted")
        return CryptoProtocol(checked, review)

    def reviewStatus(self) -> Mapping[str, Any]:
        return _freeze({"status": "approved-base-only", "version": "1",
                        "reviewReferences": self.review, "advancedFamilies": "GATED"})

    def makeTranscript(self, payload: Mapping[str, Any]) -> Mapping[str, Any]:
        values = _mapping(payload, "protocol.makeTranscript", "payload")
        body = {"version": 1, "steps": self.steps, "payloadDigest": _digest(values)}
        return _freeze({**body, "transcriptDigest": _digest(body)})

    def verifyTranscript(self, transcript: Mapping[str, Any]) -> bool:
        operation = "protocol.verifyTranscript"
        value = dict(_mapping(transcript, operation, "transcript"))
        _fields(value, {"version", "steps", "payloadDigest", "transcriptDigest"}, operation)
        supplied = value.pop("transcriptDigest", None)
        if value.get("version") != 1 or tuple(value.get("steps", ())) != self.steps:
            _fail("TRANSCRIPT", operation, "version or step sequence mismatch")
        if not isinstance(value.get("payloadDigest"), str) or not re.fullmatch(r"[0-9a-f]{64}", value["payloadDigest"]):
            _fail("TRANSCRIPT", operation, "payload digest is malformed")
        if not isinstance(supplied, str) or not hmac.compare_digest(supplied, _digest(value)):
            _fail("TRANSCRIPT", operation, "transcript digest mismatch")
        return True


__all__ = [
    "Attestation", "Capability", "CryptoAlgorithm", "CryptoError", "CryptoProtocol",
    "HybridKex", "Key", "KeyVault", "LeakageTest", "MpcSession", "PqcKem",
    "PqcSignature", "Proof", "ProofCircuit", "Sealed", "Secret", "SecretShare",
    "SecureContext", "Share", "constantTime", "crypto", "pqc", "security", "verify",
]
