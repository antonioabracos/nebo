# plain_text syntax

The plain_text production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:plain_text (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
plain_text = ? native quoted Text token with validated escapes ?  ;
```

## Context and composition

Source family: format. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### format:named-29; expected 23

```nebo
start(){"%{nome:s} %{idade:d}".format(idade:29,nome:"Nebo").console();23.return;}
```

Oracle: {"console_text_utf8": "Nebo 29", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_sha256": "24253aa11c0a6b29cceeba77358c8993612e4583acf386028a1da0cb42d43f26"}

## Rejected examples

### format:wrong-type; expected NEBO-FORMAT-003

```nebo
start(){"%d".format("Nebo");23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-FORMAT-003"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/lexer/text_char_literal_contract.asm — SHA-256 8c5c937e8d918441a535bb969853c3792ec49a4e381e6be621a994e26b039e39

- tests/rf204/G170/format_test.py — SHA-256 f4539de327f15036d30b3184af38af88a729bce118650704c350d30f04820318

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
