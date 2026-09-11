# conformance and consumption

Every admitted source statement must be accounted for exactly once. Changed values govern observations; missing rules, unclassified current declarations, dropped statements and altered oracles cannot close conformance.

```text
Identity: N1-conformance-and-consumption (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-conformance-and-consumption — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Every admitted source statement must be accounted for exactly once. Changed values govern observations; missing rules, unclassified current declarations, dropped statements and altered oracles cannot close conformance.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### source:S08; expected 23

```nebo
// Changed input governs data, lookup and a receiver-first calculation.
(Int.x)increment(){(x+11).return;}
start(){"Value".scan(.int(),.mock("37")).value;Dict<Int,Int>.new().data;data.insert(13,value.increment());data.get(13).expect("present").console();data.get(17).isNone().console();23.return;}

```

Oracle: {"console_text_utf8": "48true", "independent_builds": 2, "kinds": \[4, 5\], "process_exit": 23, "runtime_sha256": "5d24df0ae2ad643429152f1e6c893e18cfd7a807ea336733761700c4d06e606c"}

## Rejected examples

### source:reject-extra-statement; expected NEBO_NAME_UNDEFINED

```nebo
start(){Dict<Int,Int>.new().d;unknownValue.console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_NAME_UNDEFINED"}

## Related entries

[Index](index.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
