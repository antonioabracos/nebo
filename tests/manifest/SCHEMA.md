# Test catalog schema

`TEST-CATALOG.tsv` is the machine-readable registry for all approved Test IDs.

| Column | Contract |
|---|---|
| `test_id` | unique approved ID |
| `domain` | domain encoded in the ID |
| `test_type` | test type encoded in the ID |
| `sequence` | three-digit sequence |
| `scenario` | normative scenario |
| `expected` | normative expected result |
| `evidence_type` | required evidence class |
| `gate` | P0/P1/P2/P3 |
| `primary_front` | unique MF owner from the approved roadmap |
| `implementation_state` | `NOT_IMPLEMENTED`, `READY`, `IMPLEMENTED`, `DEFERRED` or `SUPERSEDED` |
| `case_path` | executable case path reserved by the catalog |

`IMPLEMENTED` requires an executable case and green evidence under its owning
front. Tabs and newlines are forbidden inside field values. The catalog is
UTF-8/LF and its hash is reconciled in `CATALOG-METADATA.txt`.
