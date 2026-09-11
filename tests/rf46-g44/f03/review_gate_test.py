#!/usr/bin/env python3
import csv
from pathlib import Path
root=Path(__file__).resolve().parents[3]
with (root/"compiler/crypto/algorithm_registry_v1.tsv").open(encoding="utf-8",newline="") as stream:
    rows=list(csv.DictReader(stream,delimiter="\t"))
row=next(item for item in rows if int(item["algorithm_id"])==4403)
assert row["status"]=="UNAVAILABLE"
assert row["implementation_identity_digest"].startswith("NONE:")
assert row["official_vector_identity_digest"].startswith("NONE:")
assert row["review_status_reference"] in {"EXTERNAL_REVIEW_REQUIRED","HARDWARE_UNAVAILABLE"}
print("RF46-G44-F03_FAIL_CLOSED status=EXTERNAL_REVIEW_REQUIRED product_promotion=false")
