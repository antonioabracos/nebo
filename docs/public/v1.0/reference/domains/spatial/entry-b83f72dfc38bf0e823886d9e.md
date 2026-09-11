# spatial — SpatialDataset.index(options)

Local bounded geometry/GIS; no external maps or global navigation assurance; original observation: point and polygon index and query normally; SDK bounds: {"MAX_CODEC_BYTES":65536,"MAX_FACES":8192,"MAX_INDEX_ITEMS":4096,"MAX_POINTS":4096,"MAX_ROUTE_EDGES":8192,"MAX_ROUTE_NODES":2048}

```text
Identity: owner:G042:G042-S07-06 (DOMAIN_CONTRACT_ID)
Edition: 1
Target: PYTHON_CPU_REFERENCE
Availability: EXPERIMENTAL
```

## Syntax or signature

```text
SpatialDataset.index(self, options: Mapping[str, Any]) -> SpatialIndex
```

## Reference-model API

The signature describes the Python reference model. Parameters and return annotations belong to that model; they are not an admitted Nebo spelling.

## Complete executable Python example

Run python3 -B tests/rf204/G042/sdk_oracle.py from the repository root with only synthetic inputs. Set G020_TMP and G021_TMP to an empty private temporary directory for the two checkpoint suites. This program contains the setup and independent assertions for the model. The line excerpt below is not a standalone program. No native Nebo binding is inferred.

## Availability and maturity

EXPERIMENTAL; evidence SDK_REFERENCE_MODEL. Documentation does not promote this identity to stable. Public and owner namespaces are separate contracts.

## Limits and lifecycle

Local bounded geometry/GIS; no external maps or global navigation assurance; original observation: point and polygon index and query normally; SDK bounds: {"MAX_CODEC_BYTES":65536,"MAX_FACES":8192,"MAX_INDEX_ITEMS":4096,"MAX_POINTS":4096,"MAX_ROUTE_EDGES":8192,"MAX_ROUTE_NODES":2048}

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
    "excerpt": "112: # S04 — deterministic handles and scan-equivalent queries.\n113: index = RTree.new({\"capacity\": 8, \"metric\": \"euclidean\"})\n114: ok(\"positive\", \"RTree.new(options)\", index.capacity == 8 and index.kind == \"rtree\")\n115: kd = KdTree.from_((Point2.of(2, 2), Point2.of(9, 9)), {\"capacity\": 4})\n116: ok(\"positive\", \"KdTree.from(points,options)\", kd.nearest(Point2.of(1, 1), 1)[0] == Point2.of(2, 2))",
    "executed_assertions": 197,
    "execution": "SDK_REFERENCE_MODEL_ONLY",
    "language": "python",
    "line": 113,
    "source_path": "tests/rf204/G042/sdk_oracle.py",
    "source_sha256": "d2891ca097ab51421a0c4a212a7df6f3d15aaf72c905c336258d0b8a4c853c27"
  }
]
```

## Related entries

[Index](index.md)

## Provenance

- compiler/sdk/spatial.py — SHA-256 0e77152354e8c708b2c358dd0f8bdc619f5d954cc2545901359f04c90cbca0f3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
