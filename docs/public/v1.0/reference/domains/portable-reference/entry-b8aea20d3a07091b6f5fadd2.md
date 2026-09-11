# portable-reference — module.import(moduleName,name,signature)

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: import signature consumes an explicit known capability; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

```text
Identity: owner:G039:G039-S01-04 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
WasmModule.import_(self, module_name: str, name: str, signature: Mapping[str, Any]) -> 'WasmModule'
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G039/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Bytecode/component/eBPF reference only; no native non-x86 target backend certification; original observation: import signature consumes an explicit known capability; SDK bounds: {"MAX_BPF_INSTRUCTIONS":4096,"MAX_BPF_MAP_ENTRIES":65536,"MAX_CALLS":4096,"MAX_COMPONENTS":32,"MAX_EDGE_STATE_BYTES":1048576,"MAX_EXPORTS":128,"MAX_IMPORTS":128,"MAX_INPUT_BYTES":1048576,"MAX_INTERFACE_FUNCTIONS":128,"MAX_MEMORY_PAGES":4096,"MAX_SOURCE_BYTES":1048576,"MAX_TABLE_ITEMS":65536}

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
    "excerpt": "55: passed(\"module.export(name, function)\", \"transform\" in module.descriptor()[\"exports\"])\n56: module.import_(\"env\", \"write\", {\"params\": [\"i32\"], \"result\": None, \"capability\": \"console.write\"})\n57: passed(\"module.import(moduleName, name, signature)\", len(module.descriptor()[\"imports\"]) == 1 and callable(getattr(module, \"import\")))\n58: module.memory(2, 11)\n59: passed(\"wasm.memory(initialPages, maxPages)\", module.descriptor()[\"memory\"] == (2, 11))",
    "executed_assertions": 87,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 56,
    "source_path": "tests/rf204/G039/sdk_oracle.py",
    "source_sha256": "6d65eb02682e596148a647945a3c0ec9125e3ce6af5397af93664543a6418b38"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/portable.py — SHA-256 2fd67d25223c3d51194eccb6dc44db21d6fea10ee5ed8b63de197a6252770448

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
