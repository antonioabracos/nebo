# output capacity

Tagged publication budget 32 and error text pool 4096 are checked before artifacts/output; plus-one rejects.

```text
Identity: N1-output-capacity (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-output-capacity — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

Tagged publication budget 32 and error text pool 4096 are checked before artifacts/output; plus-one rejects.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Executed examples

### optionresult:option-effect-capacity; expected 23

```nebo
start(){Option<Int>(Some(17)).x;x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();23.return;}
```

Oracle: {"console_text_utf8": "1717171717171717171717171717171717171717171717171717171717171717", "independent_builds": 2, "kinds": \[4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4\], "process_exit": 23, "runtime_sha256": "f06e5c59bd4dd68680e1dea7687fc17c2d25d22574b7703f4681b727f7d5d868"}

## Rejected examples

### optionresult:option-effect-capacity-plus-one; expected NEBO_LIMIT_EXCEEDED

```nebo
start(){Option<Int>(Some(17)).x;x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();x.get().console();23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LIMIT_EXCEEDED"}

## Related entries

[Index](index.md)

- [rule-allocation-budget](rule-allocation-budget.md)

- [rule-arithmetic-failures](rule-arithmetic-failures.md)

- [rule-recursion-budget](rule-recursion-budget.md)

- [rule-publication-atomicity](rule-publication-atomicity.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/option_result_test.py — SHA-256 b91cfdcf0a149083e241308f7ced2c95532758131a3b0d9d15297e026cff81fc

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
