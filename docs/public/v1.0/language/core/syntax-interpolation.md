# interpolation syntax

The interpolation production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:interpolation (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
interpolation = ? native INTERPOLATION_HEAD token ? , expression , [ ":" , format_profile ] , { ? native INTERPOLATION_MIDDLE token ? , expression , [ ":" , format_profile ] } , ? native INTERPOLATION_TAIL token ?  ;
```

## Context and composition

Source family: interpolation. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### interpolation:escaped; expected 23

```nebo
start(){"\${value}".console();23.return;}
```

Oracle: {"console_text_utf8": "${value}", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_sha256": "b338f8e71d8727b21df2a635ac488bef9b8eca21843c09d92a5b85d89253a08e"}

## Rejected examples

### interpolation:effect-console; expected NEBO_INTERPOLATION_EFFECT_FORBIDDEN

```nebo
start(){"${17.console()}";23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_INTERPOLATION_EFFECT_FORBIDDEN"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/text/interpolation_plan.asm — SHA-256 bcdd666ec788417ce66d55cc59749ba1f31d4738ca479900529289a401e86e66

- tests/rf204/G170/interpolation_test.py — SHA-256 54716aea543d4dd9d1b212acd63e1819d4e6b54b6bef5a597f0b50fab2d9a68a

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
