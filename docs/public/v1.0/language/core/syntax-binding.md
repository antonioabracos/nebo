# binding syntax

The binding production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:binding (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
binding = "." , identifier , [ ".mutable" ] ;
```

## Context and composition

Source family: binding. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### binding:Bool-0-constant; expected 29

```nebo
start(){false.VALUE;VALUE.console();29.return;}
```

Oracle: {"console_text_utf8": "false", "independent_builds": 2, "kinds": \[5\], "process_exit": 29, "runtime_sha256": "940d3adc4d04ace895143d0978dec24529bd7cd0402dc4546664f9bb6d6f0e22"}

## Rejected examples

### binding:constant-bool-write; expected NEBO_CONST_WRITE_FORBIDDEN

```nebo
start(){true.VALUE;VALUE=false;VALUE.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_CONST_WRITE_FORBIDDEN"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/statements/statements.asm — SHA-256 b853e8c1d2eb9b4c631fe788ce34533db3a39d6928637f7c71e384a5bdd31c3a

- tests/rf204/G170/binding_test.py — SHA-256 e030e23aab8fa49674e14b4cf50af041571cb97954f7fbb0873f0bed3b3eab39

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
