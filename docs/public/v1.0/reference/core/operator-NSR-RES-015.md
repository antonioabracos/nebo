# expr\[index\] — general bracket indexing

General indexing remains RESERVED. Derived NSR-RES-015-COMPAT-1.0.1 preserves public bound immutable Array&lt;Int,4&gt; reads with one literal Int index; .at(index) remains canonical.

```text
Identity: NSR-RES-015 (REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: RESERVED
```

## Syntax or signature

```text
lexeme: expr[index]
context: expression suffix
fixity: postfix
arity: 2
precedence: P180_SUFFIX
associativity: left
canonical_ascii: at()/get()
operand_rule: indexable receiver and typed index
result_rule: element or Option<Element>
```

## Evaluation and types

receiver then index once. Short-circuit: NO. Operand rule: indexable receiver and typed index. Result rule: element or Option&lt;Element&gt;.

## Errors and remediation

bounds policy must be explicit. Current native grammar/context only; no implicit activation. Use the exact admitted spelling and operand domain; recognition alone never activates a reserved form.

## Availability and ownership

RESERVED in future.collections. Current native grammar/context only; no implicit activation. The operator itself grants no capability. Owned operands obey the move/borrow rules of their concrete types.

## Execution boundary

This entry defines syntax, metadata or a restricted profile. It does not introduce a callable constructor. The observations below verify its stated boundary; no source execution is inferred from a catalog entry.

## Edition 1.0 compatibility

The public 1.0.1 envelope is active by default without warnings or a separate mode. Indices 0 through 3 use the canonical Array.at bounds and value owner. Other receivers, dynamic indices and slicing remain reserved or rejected. No user-defined index protocol or automatic quick fix is activated.

## Rejected examples

### post-g204:general-indexing-reserved; expected NEBO_LEX_RESERVED_SYMBOL

```nebo
start(){17.value;29.other;value[index];23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_LEX_RESERVED_SYMBOL"}

## Related entries

[Index](index.md)

## Provenance

- docs/specifications/nebo-language/NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json — SHA-256 ce749a1df8c869a391d06c04859b760781396dd4ee16ebb84be7aae36344e312
