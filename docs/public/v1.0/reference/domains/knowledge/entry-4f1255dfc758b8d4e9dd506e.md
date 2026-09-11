# knowledge — Reasoner.new(ontology,rules,options)

Bounded local graph and retrieval; no external knowledge source or semantic truth guarantee; original observation: monotonic reasoner freezes strategy rounds and fact budgets; SDK bounds: {"MAX_CONTEXT_BYTES":16384,"MAX_DERIVED":4096,"MAX_ENTITIES":512,"MAX_FACTS":4096,"MAX_INDEX_ITEMS":2048,"MAX_PATH_DEPTH":16,"MAX_PROPERTIES":256,"MAX_QUERY_RESULTS":1024,"MAX_ROUNDS":64,"MAX_RULES":256,"MAX_TYPES":128,"MAX_VECTOR_DIMENSION":64}

```text
Identity: owner:G034:G034-S03-05 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
Reasoner.new(cls, ontology: Ontology, rules: Sequence[Rule], options: Mapping[str, Any] | None=None) -> 'Reasoner'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G034/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bounded local graph and retrieval; no external knowledge source or semantic truth guarantee; original observation: monotonic reasoner freezes strategy rounds and fact budgets; SDK bounds: {"MAX_CONTEXT_BYTES":16384,"MAX_DERIVED":4096,"MAX_ENTITIES":512,"MAX_FACTS":4096,"MAX_INDEX_ITEMS":2048,"MAX_PATH_DEPTH":16,"MAX_PROPERTIES":256,"MAX_QUERY_RESULTS":1024,"MAX_ROUNDS":64,"MAX_RULES":256,"MAX_TYPES":128,"MAX_VECTOR_DIMENSION":64}

## Privacy, dependencies and authority

Capability: SYNTHETIC_LOCAL_DATA. Gate: NONE. Import grants capability: NO. Use synthetic local data. Hardware claim: NO. Security assurance: NO. RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE. SDK buffers and handles follow the owner lifecycle and reject invalid/released inputs where specified. No downloaded models, secrets, external network or device access is needed for the documented local proofs.

## Additional observations and limits

```text
[
  {
    "classification": {
      "capability": "SYNTHETIC_LOCAL_DATA",
      "core": "NO",
      "evidence_level": "SDK_REFERENCE_MODEL",
      "external_gate": "NONE",
      "hardware_claim": "NO",
      "import_grants_capability": "NO",
      "legal": "RELEASE-LEGAL_PENDING_SEPARATE_FROM_CORE_FUNCTIONAL_PROFILE",
      "security_assurance": "NO",
      "target": "PYTHON_CPU_REFERENCE",
      "tier": "EXPERIMENTAL"
    }
  },
  {
    "excerpt": "78: def make_ontology(version: int = 2) -> Ontology:\n79:     ontology = Ontology.new(\"places\", version)\n80:     for name in (\"Person\", \"Place\", \"City\"):\n81:         ontology.defineType(name)\n82:     ontology.subtype(\"City\", \"Place\")",
    "executed_assertions": 126,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 79,
    "source_path": "tests/rf204/G034/sdk_oracle.py",
    "source_sha256": "e355163c5dcbf36ac49ca7637255815de041c34dbdeb948720673a11071904ba"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/knowledge.py — SHA-256 697c90255499ded6ba425d7d14832c66163deb4a29ebcb4626587e92f360db12

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
