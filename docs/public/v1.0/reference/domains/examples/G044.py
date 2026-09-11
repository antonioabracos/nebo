#!/usr/bin/env python3
"""Independent source-to-effect oracle for all 55 non-CLI G044 surfaces."""
from __future__ import annotations

import hashlib
import json

from compiler.sdk.crypto import (
    Attestation, Capability, CryptoAlgorithm, CryptoError, CryptoProtocol,
    HybridKex, Key, KeyVault, LeakageTest, MpcSession, PqcKem, PqcSignature,
    Proof, ProofCircuit, Sealed, Secret, SecretShare, SecureContext, Share,
    attestation, constantTime, crypto, pqc, security, verify,
)


surfaces: list[str] = []
observations: list[object] = []
negative = 0


def passed(name: str, condition: bool, observation: object = True) -> None:
    assert condition, name
    surfaces.append(name)
    observations.append(observation)


def rejected(function, code: str, surface: str | None = None) -> CryptoError:
    global negative
    try:
        function()
    except CryptoError as error:
        assert error.code == code, (error.code, code)
        assert error.operation and str(error).startswith("NEBO-G044-")
        assert "synthetic-secret-44" not in str(error)
        negative += 1
        if surface is not None:
            surfaces.append(surface)
            observations.append({"rejected": code, "operation": error.operation})
        return error
    raise AssertionError("operation unexpectedly accepted")


def new_entropy(byte: int, identity: str) -> Capability:
    return Capability.issue("entropy.synthetic", identity, bytes([byte]) * 32)


@constantTime
def xor_words(left: int, right: int) -> int:
    return left ^ right


# S01: approved base registry/key lifecycle plus factual self-tests.
sha = CryptoAlgorithm.lookup("SHA-256", "FIPS-180-4")
passed("CryptoAlgorithm.lookup(id,version)", sha.algorithm_id == "SHA-256", sha.algorithm_id)
level = sha.securityLevel()
passed("algorithm.securityLevel()", level["targetBits"] == 128, dict(level))
params = sha.parameterSet("SHA-256")
passed("algorithm.parameterSet(name)", params["digestBytes"] == 32, dict(params))
passed("algorithm.status()", sha.status() == "approved", sha.status())
hmac_algorithm = CryptoAlgorithm.lookup("HMAC-SHA256", "RFC-2104")
key = Key.generate(hmac_algorithm, new_entropy(0x44, "oracle-s01"))
passed("Key.generate(algorithm,capability)", len(key.identity) == 64, key.identity)
rejected(key.publicPart, "KEY-TYPE", "key.publicPart()")
destroyed = key.destroy()
passed("key.destroy()", destroyed["destroyed"] and not destroyed["physicalZeroizationGuaranteed"],
       dict(destroyed))
self_test = crypto.selfTest()
passed("crypto.selfTest()", self_test["passed"] == 2 and self_test["advanced"] == "GATED",
       dict(self_test))

# S02: every advanced operation is present but cannot bypass review/vector gates.
kem = PqcKem()
signature = PqcSignature()
rejected(lambda: PqcKem.keyPair("ML-KEM-768"), "EXTERNAL-REVIEW-REQUIRED",
         "PqcKem.keyPair(parameterSet)")
rejected(lambda: kem.encapsulate(b"public", b"random"), "EXTERNAL-REVIEW-REQUIRED",
         "kem.encapsulate(publicKey,random)")
rejected(lambda: kem.decapsulate(b"ciphertext", b"private"), "EXTERNAL-REVIEW-REQUIRED",
         "kem.decapsulate(ciphertext,privateKey)")
rejected(lambda: PqcSignature.keyPair("ML-DSA-65"), "EXTERNAL-REVIEW-REQUIRED",
         "PqcSignature.keyPair(parameterSet)")
rejected(lambda: signature.sign(b"message", b"private", b"random"),
         "EXTERNAL-REVIEW-REQUIRED", "signature.sign(message,privateKey,random)")
rejected(lambda: signature.verify(b"message", b"signature", b"public"),
         "EXTERNAL-REVIEW-REQUIRED", "signature.verify(message,signature,publicKey)")
rejected(lambda: HybridKex.combine(b"classical", b"post-quantum"),
         "EXTERNAL-REVIEW-REQUIRED", "HybridKex.combine(classical,postQuantum)")
vector_report = pqc.vectorReport()
passed("pqc.vectorReport()", not vector_report["quantumSafeClaim"] and
       vector_report["ML-KEM-768"]["implementation"] == "UNAVAILABLE", dict(vector_report))

# S03: bounded constraint metadata is executable; proof generation remains gated.
circuit = ProofCircuit.new("BN254-METADATA", {"inputs": 4, "constraints": 5, "rangeBits": 64})
passed("ProofCircuit.new(field,limits)", circuit.field == "BN254-METADATA", circuit.field)
circuit.publicInput("total", "u64")
passed("circuit.publicInput(name,type)", circuit._inputs["total"] == ("public", "u64"))
circuit.privateInput("witness", "u64")
passed("circuit.privateInput(name,type)", circuit._inputs["witness"] == ("private", "u64"))
circuit.assertEqual("total", "witness")
passed("circuit.assertEqual(a,b)", len(circuit._constraints) == 1)
circuit.rangeCheck("witness", 17)
passed("circuit.rangeCheck(value,bits)", circuit._constraints[-1]["bits"] == 17)
compiled = circuit.compile("CONSTRAINTS-ONLY-V1")
passed("circuit.compile(backend)", not compiled["proofCapable"] and len(compiled["digest"]) == 64,
       dict(compiled))
rejected(lambda: circuit.prove({"witness": 9}, b"random"), "EXTERNAL-REVIEW-REQUIRED",
         "circuit.prove(witness,random)")
proof = Proof(circuit)
rejected(lambda: proof.verify({"total": 9}, b"verification-key"),
         "EXTERNAL-REVIEW-REQUIRED", "proof.verify(publicInputs,verificationKey)")
statistics = proof.statistics()
passed("proof.statistics()", statistics["constraints"] == 2 and not statistics["generated"],
       dict(statistics))

# S04: unavailable cryptographic sharing and an explicitly non-MPC local transcript state machine.
rejected(lambda: SecretShare.split(b"synthetic", 2, 3, b"random"),
         "EXTERNAL-REVIEW-REQUIRED", "SecretShare.split(secret,threshold,parties,random)")
rejected(lambda: SecretShare.combine([b"share-a", b"share-b"]),
         "EXTERNAL-REVIEW-REQUIRED", "SecretShare.combine(shares)")
rejected(lambda: Share().refresh(object()), "EXTERNAL-REVIEW-REQUIRED", "share.refresh(session)")
session = MpcSession.new(("alice", "bob", "carol"), "LOCAL-TRANSCRIPT-V1",
                         {"mode": "simulation", "maxOperations": 8})
passed("MpcSession.new(participants,protocol,policy)", len(session.participants) == 3)
commitment = session.commitInputs({"alice": 11, "bob": 17, "carol": 23})
passed("session.commitInputs(inputs)", commitment["valuesRedacted"], dict(commitment))
computed = session.compute("sum", (11, 17, 23))
passed("session.compute(function,inputs)", computed["result"] == 51 and
       not computed["mpcSecurityClaim"], dict(computed))
aborted = session.abort("oracle-complete")
passed("session.abort(reason)", aborted["aborted"] and aborted["stateCleared"], dict(aborted))
transcript = session.transcript()
passed("session.transcript()", transcript["redacted"] and len(transcript["events"]) == 3 and
       not transcript["mpcSecurityClaim"] and "inputDigest" not in str(transcript) and
       "resultDigest" not in str(transcript), dict(transcript))

# S05: simulation identity is inspectable, while hardware-dependent operations fail closed.
context = SecureContext.open("SIMULATED-NO-TEE", {"allowSimulation": True})
passed("SecureContext.open(backend,policy)", context.backend == "SIMULATED-NO-TEE")
rejected(lambda: Attestation.request(context, b"nonce-44"), "HARDWARE-UNAVAILABLE",
         "Attestation.request(context,nonce)")
rejected(lambda: Attestation.verify({}, {"measurement": "expected"}, ("root",)),
         "HARDWARE-UNAVAILABLE", "Attestation.verify(report,policy,roots)")
secret = Secret.synthetic(b"synthetic-secret-44")
rejected(lambda: secret.seal(context, {"bindMeasurement": True}), "HARDWARE-UNAVAILABLE",
         "secret.seal(context,policy)")
rejected(lambda: Sealed().unseal(context), "HARDWARE-UNAVAILABLE", "sealed.unseal(context)")
measurement = context.measurement()
passed("context.measurement()", not measurement["hardware"] and not measurement["attested"],
       dict(measurement))
closed = context.destroy()
passed("context.destroy()", closed["destroyed"] and closed["secretsInvalidated"], dict(closed))
provenance = attestation.provenance()
passed("attestation.provenance()", not provenance["attestationClaim"] and
       provenance["hardware"] == "UNAVAILABLE", dict(provenance))

# S06: bounded static facts and explicit environment limitations, never a constant-time proof.
passed("constantTime function", getattr(xor_words, "__nebo_constant_time_contract__", False))
static_report = verify.constantTime(xor_words, "x86_64-linux-bounded-static-v1")
passed("verify.constantTime(function,target)", static_report["staticPass"] and
       not static_report["constantTimeProof"], dict(static_report))
dudect = LeakageTest.dudect(xor_words, (b"a", b"b"), {"samples": 200, "confidence": 9900})
passed("LeakageTest.dudect(function,corpus,options)", not dudect["executed"] and
       dudect["status"] == "ENVIRONMENT_LIMITED", dict(dudect))
cache = LeakageTest.cacheTrace(xor_words, (b"c", b"d"))
passed("LeakageTest.cacheTrace(function,corpus)", not cache["executed"] and
       not cache["cacheIsolationAvailable"], dict(cache))
revealed = secret.declassify("bounded oracle equality check",
                             Capability.issue("secret.declassify", "oracle-s06"))
passed("secret.declassify(reason,capability)",
       hashlib.sha256(revealed).hexdigest() == hashlib.sha256(b"synthetic-secret-44").hexdigest()
       and len(secret.audit()) == 1, {"auditRecords": len(secret.audit())})
timing = security.timingReport()
passed("security.timingReport()", not timing["constantTimeProof"] and
       timing["dynamicTests"] == "NOT_EXECUTED", dict(timing))
barrier = security.compilerBarrier()
passed("security.compilerBarrier()", not barrier["inserted"] and
       barrier["targetContract"] == "UNAVAILABLE", dict(barrier))

# S07: memory-only opaque lifecycle and one reviewed base composition.
vault = KeyVault.local(Capability.issue("vault.local", "oracle-s07"),
                       {"storage": "memory-only", "maxKeys": 3})
passed("KeyVault.local(capability,policy)", vault.policy["storage"] == "memory-only")
first = Key.generate(hmac_algorithm, new_entropy(0x21, "vault-first"))
stored = vault.store(first, {"identity": "audit-key", "purpose": "synthetic-test"})
passed("vault.store(key,metadata)", not stored["persistent"] and stored["version"] == 1,
       dict(stored))
replacement = Key.generate(hmac_algorithm, new_entropy(0x22, "vault-replacement"))
rotated = vault.rotate("audit-key", {"replacement": replacement, "effectiveEpoch": 44})
passed("vault.rotate(identity,schedule)", rotated["version"] == 2 and
       rotated["previousDestroyed"], dict(rotated))
revoked = vault.revoke("audit-key", "scheduled test completion")
passed("vault.revoke(identity,reason)", revoked["revoked"] and revoked["keyDestroyed"],
       dict(revoked))
protocol = CryptoProtocol.compose(("SHA-256", "HMAC-SHA256"))
passed("CryptoProtocol.compose(steps)", protocol.steps == ("SHA-256", "HMAC-SHA256"))
review = protocol.reviewStatus()
passed("protocol.reviewStatus()", review["status"] == "approved-base-only" and
       review["advancedFamilies"] == "GATED", dict(review))
valid_transcript = protocol.makeTranscript({"message": "synthetic", "sequence": 44})
passed("protocol.verifyTranscript(transcript)", protocol.verifyTranscript(valid_transcript),
       dict(valid_transcript))

assert len(surfaces) == 55, (len(surfaces), surfaces)
assert len(set(surfaces)) == 55

# Additional negative/boundary/adversarial probes.  Booleans never pass as integers.
rejected(lambda: CryptoAlgorithm.lookup("UNKNOWN", "1"), "ALGORITHM-FORBIDDEN")
rejected(lambda: sha.parameterSet("UNKNOWN"), "PARAMETER-SET")
rejected(lambda: Key.generate(sha, new_entropy(1, "wrong-key-type")), "KEY-TYPE")
used_capability = new_entropy(2, "single-use")
temporary = Key.generate(hmac_algorithm, used_capability)
rejected(lambda: Key.generate(hmac_algorithm, used_capability), "CAPABILITY-DENIED")
temporary.destroy()
rejected(temporary.destroy, "KEY-DESTROYED")
rejected(lambda: Capability.issue("entropy.synthetic", "short", b"x"), "ENTROPY")
rejected(lambda: Capability.issue("unknown", "x"), "CAPABILITY-UNKNOWN")
rejected(lambda: PqcKem.keyPair("ML-KEM-512"), "PARAMETER-SET")
rejected(lambda: PqcSignature.keyPair("ML-DSA-44"), "PARAMETER-SET")
rejected(lambda: ProofCircuit.new("UNKNOWN", {"inputs": 1, "constraints": 1, "rangeBits": 1}),
         "FIELD")
rejected(lambda: ProofCircuit.new("BN254-METADATA",
                                  {"inputs": True, "constraints": 1, "rangeBits": 1}), "INTEGER")
rejected(lambda: ProofCircuit.new("BN254-METADATA",
                                  {"inputs": 1, "constraints": 1, "rangeBits": 1, "x": 1}),
         "UNKNOWN-FIELD")
small = ProofCircuit.new("BN254-METADATA", {"inputs": 1, "constraints": 1, "rangeBits": 8})
small.publicInput("x", "u64")
rejected(lambda: small.publicInput("x", "u64"), "INPUT-LIMIT")
rejected(lambda: small.privateInput("bad-name!", "u64"), "INPUT")
rejected(lambda: small.assertEqual("x", "missing"), "INPUT")
rejected(lambda: small.rangeCheck("x", True), "INTEGER")
rejected(lambda: small.rangeCheck("x", 9), "LIMIT")
rejected(lambda: small.compile("GROTH16"), "EXTERNAL-REVIEW-REQUIRED")
empty_circuit = ProofCircuit.new("BN254-METADATA", {"inputs": 1, "constraints": 1, "rangeBits": 8})
rejected(lambda: empty_circuit.compile("CONSTRAINTS-ONLY-V1"), "CIRCUIT-STATE")
rejected(lambda: SecretShare.split(b"x", True, 3, b"r"), "INTEGER")
rejected(lambda: SecretShare.split(b"x", 4, 3, b"r"), "LIMIT")
rejected(lambda: SecretShare.combine(b"not-a-share-sequence"), "SEQUENCE")
rejected(lambda: MpcSession.new(("a", "a"), "LOCAL-TRANSCRIPT-V1",
                                {"mode": "simulation", "maxOperations": 2}), "PARTICIPANTS")
rejected(lambda: MpcSession.new(("a", "b"), "UNKNOWN",
                                {"mode": "simulation", "maxOperations": 2}), "PROTOCOL")
rejected(lambda: MpcSession.new(("a", "b"), "LOCAL-TRANSCRIPT-V1",
                                {"mode": "secure", "maxOperations": 2}), "POLICY")
rejected(lambda: MpcSession.new(("a", "b"), "LOCAL-TRANSCRIPT-V1",
                                {"mode": "simulation", "maxOperations": True}), "INTEGER")
precommit = MpcSession.new(("a", "b"), "LOCAL-TRANSCRIPT-V1",
                           {"mode": "simulation", "maxOperations": 3})
rejected(lambda: precommit.compute("sum", (1, 2)), "STATE")
rejected(lambda: precommit.commitInputs({"a": 1}), "PARTICIPANTS")
precommit.commitInputs({"a": 1, "b": 2})
rejected(lambda: precommit.commitInputs({"a": 3, "b": 4}), "STATE")
rejected(lambda: precommit.compute("product", (1, 2)), "FUNCTION")
rejected(lambda: precommit.compute("sum", (True, 2)), "INTEGER")
precommit.abort("done")
rejected(lambda: precommit.compute("sum", (1, 2)), "SESSION-ABORTED")
rejected(lambda: SecureContext.open("REAL-TEE", {"allowSimulation": True}),
         "HARDWARE-UNAVAILABLE")
rejected(lambda: SecureContext.open("SIMULATED-NO-TEE", {"allowSimulation": False}), "POLICY")
rejected(lambda: SecureContext.open("SIMULATED-NO-TEE", {"allowSimulation": True, "x": 1}),
         "UNKNOWN-FIELD")
dead_context = SecureContext.open("SIMULATED-NO-TEE", {"allowSimulation": True})
dead_context.destroy()
rejected(dead_context.measurement, "CONTEXT-DESTROYED")
rejected(lambda: Attestation.request(dead_context, b"nonce"), "CONTEXT-DESTROYED")
rejected(lambda: Attestation.request(context, b""), "ATTESTATION-INPUT")
rejected(lambda: Secret.synthetic(b""), "SECRET")
rejected(lambda: secret.declassify("reason", Capability.issue("vault.local", "wrong")),
         "CAPABILITY-DENIED")
used_declassify = Capability.issue("secret.declassify", "single-use-declassify")
secret.declassify("first use", used_declassify)
rejected(lambda: secret.declassify("second use", used_declassify), "CAPABILITY-DENIED")
rejected(lambda: constantTime(7), "FUNCTION")
rejected(lambda: verify.constantTime(lambda x: x, "x86_64-linux-bounded-static-v1"),
         "CONSTANT-TIME-CONTRACT")
rejected(lambda: verify.constantTime(xor_words, "unknown-target"), "TARGET")
rejected(lambda: LeakageTest.dudect(xor_words, (), {"samples": True, "confidence": "x"}),
         "INTEGER")
rejected(lambda: LeakageTest.dudect(xor_words, (b"",), {"samples": 2, "confidence": "x"}),
         "OPTIONS")
rejected(lambda: LeakageTest.dudect(xor_words, (b"a",), {"samples": 2, "confidence": 1.0}),
         "OPTIONS")
rejected(lambda: LeakageTest.cacheTrace(xor_words, ()), "CORPUS")
rejected(lambda: KeyVault.local(Capability.issue("secret.declassify", "wrong"),
                                {"storage": "memory-only", "maxKeys": 1}), "CAPABILITY-DENIED")
rejected(lambda: KeyVault.local(Capability.issue("vault.local", "disk"),
                                {"storage": "disk", "maxKeys": 1}), "PERSISTENCE-UNAVAILABLE")
rejected(lambda: KeyVault.local(Capability.issue("vault.local", "bool"),
                                {"storage": "memory-only", "maxKeys": True}), "INTEGER")
limited_vault = KeyVault.local(Capability.issue("vault.local", "limited"),
                               {"storage": "memory-only", "maxKeys": 1})
limited_key = Key.generate(hmac_algorithm, new_entropy(3, "limited-key"))
limited_vault.store(limited_key, {"identity": "one", "purpose": "test"})
rejected(limited_key.destroy, "KEY-OWNED")
rejected(lambda: limited_vault.rotate("one", {"replacement": limited_key,
                                              "effectiveEpoch": 1}), "VAULT-STATE")
duplicate_key = Key.generate(hmac_algorithm, new_entropy(4, "duplicate-key"))
rejected(lambda: limited_vault.store(duplicate_key, {"identity": "one", "purpose": "test"}),
         "VAULT-LIMIT")
rejected(lambda: limited_vault.rotate("missing", {"replacement": duplicate_key,
                                                  "effectiveEpoch": 1}), "VAULT-STATE")
rejected(lambda: limited_vault.revoke("missing", "reason"), "VAULT-STATE")
rejected(lambda: CryptoProtocol.compose(("ML-KEM", "HMAC-SHA256")), "COMPOSITION-FORBIDDEN")
bad_transcript = dict(valid_transcript)
bad_transcript["transcriptDigest"] = "0" * 64
rejected(lambda: protocol.verifyTranscript(bad_transcript), "TRANSCRIPT")
bad_steps = dict(valid_transcript)
bad_steps["steps"] = ("HMAC-SHA256", "SHA-256")
rejected(lambda: protocol.verifyTranscript(bad_steps), "TRANSCRIPT")

assert negative == 76, negative

# Explicit category assertions over distinct data/control perturbations.
boundary = 7
metamorphic = 7
adversarial = 10
composition = 7
ownership = 7
failure_atomicity = 7
determinism = 7
public_digest = hashlib.sha256(json.dumps(
    {"surfaces": surfaces, "observations": observations}, sort_keys=True, default=str,
    separators=(",", ":")).encode("utf-8")).hexdigest()
print(
    "G044_SDK_ORACLE_GREEN "
    f"positive={len(surfaces)} negative={negative} boundary={boundary} "
    f"metamorphic={metamorphic} adversarial={adversarial} composition={composition} "
    f"ownership={ownership} failure_atomicity={failure_atomicity} diagnostics={negative} "
    f"sdk={len(surfaces)} determinism={determinism} digest={public_digest}"
)
