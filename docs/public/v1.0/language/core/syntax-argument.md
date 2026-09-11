# argument syntax

The argument production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:argument (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
argument = [ identifier , ":" ] , ( expression | "[" , [ expression , { "," , expression } ] , "]" ) | contextual_option ;
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

- compiler/parser/expression/pratt.asm — SHA-256 547d285f401a8acf03d88f8f331eeadcc43fc28c26e60e93b0afa84fdeb21cc1

- tests/rf204/G170/format_test.py — SHA-256 f4539de327f15036d30b3184af38af88a729bce118650704c350d30f04820318

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
