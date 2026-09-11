# public-scientific — contiguous

Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.

```text
Identity: public:claim:cdd6f35f0cce52bc9393194b (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
contiguous
Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.
```

## Availability and maturity

EXPERIMENTAL; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Actual Bool/Int64/binary64 operands and native rank/shape/stride/root descriptors; Bool storage is packed bytes; CPU rank 0..6 and 4096 elements; Int construction/arithmetic retains C12 rank 0..3, dimensions 0..8 and 64 elements; index tensors from argMax retain full result geometry. Shape inputs are constant Int Tuples or material Int Vectors. fromBuffer copies exact typed Int/Float Vector, live Int Slice or checked 0/1 Bytes for Bool. Float selection uses equal shapes or explicit broadcastTo; map uses a typed noncapturing Float function and preserves ordered effects. Float reductions reject empty/nonfinite inputs and invalid axes; first argMax tie. Structural methods compose native owners; peers are 1..6 immutable Tensor names in a Tuple, split takes 1..6 exact sizes, padding has two entries per axis. Readonly function borrows and caller-owned result copies preserve lifetimes. Every cited oracle executes real source, including negatives and bounded-domain failures.

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### tensor:function-copy-Int-True; expected 23

```nebo
import "std.scientific" { Tensor; }.scientific;
(Tensor<Int>.x)copy(){x.permute(Tuple.of(1,0)).return;}start(){Tensor<Int>.filled(Tuple.of(2,3),17).a;a.copy().b;(a.storageId()!=b.storageId()).console();b.axisSize(0).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "true3", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[5, 4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "de39512cdfbb56fcb869b3b9fd28b97c2de1b45c7af059b34a31255446065344", "text": {"bytes_hex": "7472756533"}}

## Rejected examples

### tensor:method-arity; expected NEBO_TYPE_MISMATCH

```nebo
import "std.scientific" { Tensor; }.scientific;
start(){Tensor<Int>.zeros(Tuple.of(2)).a;a.rank(1);23.return;}
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
