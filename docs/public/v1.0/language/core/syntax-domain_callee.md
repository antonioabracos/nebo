# domain_callee syntax

The domain_callee production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:domain_callee (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
domain_callee = identifier | ? exact calculus, reduction or formal quantifier token ?  ;
```

## Context and composition

Source family: boundedoperator. Classification: ACTIVE_BOUNDED. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### boundedoperator:dom-065-0-0-False; expected 1

```nebo
start(){iff(0,0,7).value();}
```

Oracle: {"independent_builds": 2, "process_exit": 1, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### boundedoperator:dom-062-negative; expected NEBO_TYPE_UNSUPPORTED_OPERATOR

```nebo
// Quantifier outcome partitions cannot exceed the finite domain.
start() { ∀(5, 4, 2, 0, 11).status(); }

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_UNSUPPORTED_OPERATOR"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/expression/formal_logic_plan.asm — SHA-256 457bb13e0536b6062fd3a782bc87fd2c95911a25e149f0d0ad760a93f82face4

- tests/rf204/G170/bounded_operator_test.py — SHA-256 a756e75fb059c5f5837b1ab76490c31b8e92762f0400cad0d2545ff0532beaf5

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
