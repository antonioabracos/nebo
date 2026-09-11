# material interface

The admitted source-facing binary .ni profile supplies public Int constants with original symbol/type identity; a metadata-only interface cannot manufacture an executable value. Provider-source and material-interface consumers must agree.

```text
Identity: N1-material-interface (NORMATIVE_RULE)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: EDITION_1_BOUNDED_NORMATIVE
```

## Syntax or signature

```text
N1-material-interface — EDITION_1_BOUNDED_NORMATIVE
```

## Scope and constraints

The admitted source-facing binary .ni profile supplies public Int constants with original symbol/type identity; a metadata-only interface cannot manufacture an executable value. Provider-source and material-interface consumers must agree.

## Use and remediation

Follow the admitted forms in the individual syntax and operator references. Keep source order and type identity; make imports and capability grants explicit. A native supplemental contract does not introduce source constructors or widen target support.

## Negative example applicability

No distinct source trigger is asserted for this definition. The associated native/CLI boundary tests below are supplementary evidence, not a fabricated source rejection.

## Executed examples

### interface:consumer-0; expected 0

```nebo
// Public imports resolve the original declaration and value.
module app;
import "project.core".values;
start values.token;

```

Oracle: {"independent_builds": 2, "process_exit": 0, "runtime_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}

Material interface core.ni (write these exact bytes beside the consumer)

```python
from pathlib import Path
Path('core.ni').write_bytes(bytes.fromhex('4e45424f2e4e490001004000010000002f3368b26f2fe005489ea2670fbe9f18b8c1aacb04c0379e1767ffaed2d7f92c0300000070010000ada6fcb5bd5bb0ef0100000000000000a0000000000000004000000000000000fecfeb3b4a9455070200000000000000e000000000000000400000000000000096b7f379be1d016c040000000100000020010000000000005000000000000000ef071a0c02920c6252c1b3507db1c42652c1b3507db1c42603000000010000009ed48dc9191fa9410000000000000000c2fc7781dd1ec150c5391a2832f8c7a8060000000000000052c1b3507db1c426000000000000000000000000000000000100000003000000d04ace473a60da5c31972097b191bd633e4c68570db7c3aa0b1eb52897ae89ad4e45424f4d44433152c1b3507db1c42600000000000000000400000000000000636f72650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'))
```

Provider util.no

```nebo
module util;
export public delta = 7;

```

## Related entries

[Index](index.md)

- [rule-call-order](rule-call-order.md)

- [rule-inference-and-binding](rule-inference-and-binding.md)

- [rule-overload-ranking](rule-overload-ranking.md)

- [rule-import-no-grant](rule-import-no-grant.md)

## Provenance

- docs/public/v1.0/language/specification/NORMATIVE-RULE-REGISTRY.tsv — SHA-256 2d2d4324cf615c0970e3dca2f4197cde9e32b445e0337dd8179967dc0cff2d16

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
