# constraint syntax

The constraint production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:constraint (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
constraint = identifier , { "+" , identifier } ;
```

## Context and composition

Source family: composite. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### composite:alias-size; expected 8

```nebo
type alias Count = Int;
start() {
    Count.sizeOf().return;
}

```

Oracle: {"independent_builds": 2, "process_exit": 8, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### composite:array-map-capture; expected NEBO_PARSE_UNEXPECTED_TOKEN

```nebo
callable addOne(Int.value) capture copy 1 { (value + 1).return; }
start() { Array<Int, 1> [7].a; a.map(addOne).b; b.at(0); }

```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_PARSE_UNEXPECTED_TOKEN"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/generic_parser.asm — SHA-256 e624b1072c46dbc28c8f603c2db1d6d2c9960c79dda3b115a8a868d9af1b4031

- tests/rf204/G170/composite_test.py — SHA-256 55ac93ae5384e68a22489d0b68dbd8acc1cb83ed7fdb2b3b2a1b5c71de6f01f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
