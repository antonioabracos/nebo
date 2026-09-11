# for_statement syntax

The for_statement production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:for_statement (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
for_statement = "for" , "(" , identifier , [ "," , identifier ] , "in" , identifier , [ "where" , identifier , ( "==" | "!=" | "<" | "<=" | ">" | ">=" ) , integer ] , ")" , block ;
```

## Context and composition

Source family: control. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### control:for; expected 10

```nebo
(Int.self)work(){Range.exclusive(0,5).indices;0.total.mutable;for(index in indices){total+=index;}total.return;}start(){7.work().return;}
```

Oracle: {"independent_builds": 2, "process_exit": 10, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

## Rejected examples

### control:break-outside; expected NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-030

```nebo
start(){break;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-030"}

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/statements/statements.asm — SHA-256 b853e8c1d2eb9b4c631fe788ce34533db3a39d6928637f7c71e384a5bdd31c3a

- tests/rf204/G170/control_test.py — SHA-256 f957fe13774970b7f71e2678f8b0cc721b8cb8b15891c02552f9129ff2e2e0be

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
