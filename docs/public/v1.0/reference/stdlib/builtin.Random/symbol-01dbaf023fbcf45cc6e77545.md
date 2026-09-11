# builtin.Random — seed

Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report Independent deterministic seeded states; checked intervals and distribution domains; no cryptographic entropy claim

```text
Identity: claim:d2f39b129b1dd314fc858bd1 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
seed
Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report Independent deterministic seeded states; checked intervals and distribution domains; no cryptographic entropy claim
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report Independent deterministic seeded states; checked intervals and distribution domains; no cryptographic entropy claim

## Effects, capabilities and sandbox

Per expression: pure computation plus explicit observed sinks; NO_IMPLICIT_GRANT. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Explicit SplitMix64 v1 state, no entropy capability; native finite-domain distributions and categorical Float Vector weights; nonnegative Int uniform; shuffle of unique local mutable Int Slice at most 64 lanes; lexical creation/release provenance, separate descriptor/payload frames; sample of Int Vector/local Slice returns canonical List with 0..16 entries; independent seed/value/order oracles and rejected effectful interpolation; no whole-source report Independent deterministic seeded states; checked intervals and distribution domains; no cryptographic entropy claim Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

TYPED_AST_NATIVE_RANDOM_OWNER. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### random:ordered-state-17; expected 23

```nebo
start(){Random.seed(17).r;r.uniform(0,1000).a;r.uniform(0,1000).b;r.uniform(0,1000).c;"${a}/${b}/${c}".console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "379/713/356", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "676bf53c381dee25fc9d475d002cf18ad71a6fb0b739997e5803bde4036d309f", "text": {"bytes_hex": "3337392f3731332f333536"}}

## Rejected examples

### random:seed-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Random.seed(true).r;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-f0f2eba2a3a687d5d4618f8c](symbol-f0f2eba2a3a687d5d4618f8c.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/random_test.py — SHA-256 a4d3692d30d6947812089d0ad64318a32a6a9279c567ac96481f207daeb95516
