# contextual_option syntax

The contextual_option production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:contextual_option (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
contextual_option = "." , identifier , arguments ;
```

## Context and composition

Source family: scan. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### scan:int-23-return-23; expected 23

```nebo
start(){"Age: ".scan(.int(),.mock("23")).console();23.return;}
```

Oracle: {"console_text_utf8": "23", "independent_builds": 2, "kinds": \[4\], "process_exit": 23, "runtime_sha256": "78067f1881f6b0d063fd8262518ca5706c32ce03063d879e24c9a24380bfa337"}

## Rejected examples

### scan:attempts-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){"Input".scan(.maxAttempts(true));23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/expression/pratt.asm — SHA-256 547d285f401a8acf03d88f8f331eeadcc43fc28c26e60e93b0afa84fdeb21cc1

- tests/rf204/G170/scan_public_test.py — SHA-256 e487ed7a7709494b21d44b475371945fa537edb1ce2850f8719f76381b3e7e35

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
