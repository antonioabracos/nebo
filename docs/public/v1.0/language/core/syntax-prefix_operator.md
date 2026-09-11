# prefix_operator syntax

The prefix_operator production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:prefix_operator (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
prefix_operator = ? registered prefix token, including exact Unicode aliases ?  ;
```

## Context and composition

Source family: operator. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### operator:divisibility-e288a3-0-17; expected 23

```nebo
start(){((0) ∣ (17)).console();23.return;}
```

Oracle: {"console_text_utf8": "false", "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_sha256": "940d3adc4d04ace895143d0978dec24529bd7cd0402dc4546664f9bb6d6f0e22"}

## Rejected examples

### operator:discard-mutable; expected NEBO_PARSE_EXPECTED_TOKEN

```nebo
start(){17.console()._.mutable;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_PARSE_EXPECTED_TOKEN"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/expression/operator_prefix.asm — SHA-256 e2776c133c3374aae1dea2aa7031258b0ec63aef202b4389d5a9364f92d340c3

- tests/rf204/G170/operator_test.py — SHA-256 81d598a23e07578d10b62172278aeda66e8e99d0bf8939e14846db3044a09dfe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
