# public-scientific — argMax

Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.

```text
Identity: public:claim:7ab2abd0d6b4b87d828f0c32 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
argMax
Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.
```

## Availability and maturity

EXPERIMENTAL; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### tensor:argmax-\[1_1_1_1_1_3\]-5; expected 23

```nebo
import "std.scientific" { Tensor; }.scientific;
start(){Vector<Float> [0.0, 7.0, 1.0].v;Tensor<Float>.fromBuffer(v,Tuple.of(1,1,1,1,1,3)).a;a.argMax(5).t;t.contiguous().copy;t.dtype().console();t.rank().console();t.elementCount().console();copy.at(Tuple.of(0,0,0,0,0)).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "2511", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[4, 4, 4, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "a0e4e7ba3754135e674fca5173b3b75c0c4fa480541fe7d1ccc135d285fdbaac", "text": {"bytes_hex": "32353131"}}

## Rejected examples

### tensor:argmax-axis-type; expected NEBO_TYPE_MISMATCH

```nebo
import "std.scientific" { Tensor; }.scientific;
start(){Tensor<Float>.zeros(Tuple.of(2)).a;a.argMax(true);23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "NONE",
      "core": "NO",
      "evidence_level": "FROZEN_PUBLIC_SOURCE",
      "external_gate": "NONE",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "x86_64-systemv-elf-linux",
      "tier": "EXPERIMENTAL"
    }
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- tests/rf204/G170/tensor_test.py — SHA-256 6afd1cbf42f0f2333d26e17eb6ed3720393e60ec92ad4e07c359cf2062d6872e

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
