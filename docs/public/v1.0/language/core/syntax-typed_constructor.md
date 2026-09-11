# typed_constructor syntax

The typed_constructor production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:typed_constructor (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
typed_constructor = type , arguments | type , "." , identifier , arguments ;
```

## Context and composition

Source family: dict. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### dict:empty; expected 0

```nebo
start(){Dict<Int,Int>.new().d;d.length().return;}

```

Oracle: {"independent_builds": 2, "process_exit": 0, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### dict:after-return; expected NEBO_PARSE_UNEXPECTED_TOKEN

```nebo
start(){Dict<Int,Int>.new().d;23.return;d.insert(17,53);}

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

- compiler/parser/expression/pratt.asm — SHA-256 547d285f401a8acf03d88f8f331eeadcc43fc28c26e60e93b0afa84fdeb21cc1

- tests/rf204/G170/dict_test.py — SHA-256 a58335130df8bf4893b6505518311aa9fa043eaa04deed5e54e12aaf05c1ea99

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
