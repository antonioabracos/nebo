# public-scientific — cholesky

Canonical native descriptor, actual Int64 (dimensions 0..8) / binary64 (0..64) operands; independent owned results and root-provenance views; row-major fromBuffer copies live Int Slice or typed Int/Float Vector, exact count/dtype and lexical release gates; native Float LU returns (compact factors, permutation), QR returns (thin Q, R), using existing Tuple projections; finite factorization dimensions at most 32 with singular/domain rejection; readonly Matrix parameter borrows and caller-owned hidden-result copies preserve lifetimes and ordered arguments; scalar calls reclaim temporaries; runtime-shaped axis Vectors reuse native Vector/statistics and Random consumers; checked Int axis sums publish atomically; no whole-source projection or fixed report

```text
Identity: public:claim:6f8f7fcb6bf03e2546e42615 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
cholesky
Canonical native descriptor, actual Int64 (dimensions 0..8) / binary64 (0..64) operands; independent owned results and root-provenance views; row-major fromBuffer copies live Int Slice or typed Int/Float Vector, exact count/dtype and lexical release gates; native Float LU returns (compact factors, permutation), QR returns (thin Q, R), using existing Tuple projections; finite factorization dimensions at most 32 with singular/domain rejection; readonly Matrix parameter borrows and caller-owned hidden-result copies preserve lifetimes and ordered arguments; scalar calls reclaim temporaries; runtime-shaped axis Vectors reuse native Vector/statistics and Random consumers; checked Int axis sums publish atomically; no whole-source projection or fixed report
```

## Availability and maturity

EXPERIMENTAL; evidence FROZEN_PUBLIC_SOURCE. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Canonical native descriptor, actual Int64 (dimensions 0..8) / binary64 (0..64) operands; independent owned results and root-provenance views; row-major fromBuffer copies live Int Slice or typed Int/Float Vector, exact count/dtype and lexical release gates; native Float LU returns (compact factors, permutation), QR returns (thin Q, R), using existing Tuple projections; finite factorization dimensions at most 32 with singular/domain rejection; readonly Matrix parameter borrows and caller-owned hidden-result copies preserve lifetimes and ordered arguments; scalar calls reclaim temporaries; runtime-shaped axis Vectors reuse native Vector/statistics and Random consumers; checked Int axis sums publish atomically; no whole-source projection or fixed report

## Privacy, dependencies and authority

Capability: NONE. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Executed examples

### matrix:cholesky-identity-0-0; expected 23

```nebo
import "std.scientific" { Matrix; }.scientific;
start(){Matrix<Float>.fromRows([[1.0, 0.0], [0.0, 1.0]]).a;a.cholesky().b;b.at(0,0).v;"${v:fixed(3)}".console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "1.000", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "1761a8368e23018e8e825fb65265f3e08e346b4532833274c64a2c09d87aa86d", "text": {"bytes_hex": "312e303030"}}

## Rejected examples

### matrix:cholesky-arity; expected NEBO_TYPE_MISMATCH

```nebo
import "std.scientific" { Matrix; }.scientific;
start(){Matrix<Float>.zeros(2,2).m;m.cholesky(1);23.return;}
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

- tests/rf204/G170/matrix_test.py — SHA-256 16db22787507e790f8112bd06009e39803b9e95d8afc2e82a4a4ed1c16312825

- tests/rf204/G170/random_test.py — SHA-256 a4d3692d30d6947812089d0ad64318a32a6a9279c567ac96481f207daeb95516

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
