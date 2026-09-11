# field_initializer syntax

The field_initializer production in the admitted structural grammar. Its delimiters and ordering are shown below; type, lifetime and profile restrictions apply after parsing.

```text
Identity: grammar:field_initializer (GRAMMAR_PRODUCTION)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED
```

## Syntax or signature

```text
field_initializer = identifier , ":" , expression ;
```

## Context and composition

Source family: composite. Classification: ACTIVE. Expression operators use Registry precedence; a type name resolves a constructor, while a suffix name can bind a value, call a member or return. Every statement must have one semantic owner. The example and linked rejection show the measured composition, not an unrestricted grammar promise.

## Ownership and failure

Parsing this production grants no authority and creates no implicit copy. Typed expressions retain their payloads and lexical effect order; scope exit follows the ownership rules. Invalid syntax or types reject before an executable is published.

## Executed examples

### composite:typed-struct-source; expected 23

```nebo
// Preserve both native struct fields through ordinary interpolation and exit.
struct User { Text.name; Int.age; }
start() {
    User { name: "Nebo", age: 29 }.person;
    "${person.name}:${person.age}".console();
    23.return;
}

```

Oracle: {"console_text_utf8": "Nebo:29", "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_sha256": "e3f552c7eddadd45c37adde99b898639d279a3d8ad30c7da6223311bd92c43ab"}

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

- compiler/parser/expression/struct_constructor.inc — SHA-256 4303ff5144421eb228d6a83046b2526bcee7dfa0d84c10988cee455b8b1de3cf

- tests/rf204/G170/composite_test.py — SHA-256 55ac93ae5384e68a22489d0b68dbd8acc1cb83ed7fdb2b3b2a1b5c71de6f01f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
