# doc_example syntax

The doc_example production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:doc_example (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
doc_example = ( "example" | "law" ) , plain_text , "{" , ordinary_program , "}" ;
```

## Context and composition

Source family: module. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### edition:documentation-23; expected 23

```nebo
doc { title: "Runtime documentation"; summary: "A material value"; effects { pure; } capabilities { none; } example "exit-23" {start(){23.return;}} law "law-exit-29" {start(){29.return;}} }
// Public imports resolve the original declaration and value.
module app;
import "project.core".values;
start values.token;

```

Oracle: {"independent_builds": 2, "process_exit": 23, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

Provider core.no

```nebo
module core;
export public token = 23;

```

Provider util.no

```nebo
module util;
export public delta = 7;

```

## Additional observations and limits

```text
[
  {
    "case_id": "edition:module-simple-17"
  },
  {
    "case_id": "edition:module-named-43"
  }
]
```

## Related entries

[Index](index.md)

- [syntax-program](syntax-program.md)

- [syntax-ordinary_program](syntax-ordinary_program.md)

- [syntax-declaration](syntax-declaration.md)

- [syntax-entry](syntax-entry.md)

## Provenance

- docs/public/v1.0/language/specification/NEBO-GRAMMAR-1.0.ebnf — SHA-256 693f16bc69211dc326aa7a2d367c263923eba69feddddb609d049328c38d2acc

- compiler/parser/doc_examples.asm — SHA-256 ac0a59851feef06b6de5c4d624b8f67e618cb22d15222ecb8109424c3603a6d7

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
