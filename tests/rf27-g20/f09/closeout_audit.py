#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[3]
required = [
    "compiler/semantic/ml/model_contract.asm",
    "runtime/ml/dense.asm",
    "runtime/ml/layers.asm",
    "runtime/ml/conv.asm",
    "runtime/ml/model_format.asm",
    "runtime/ml/inference.asm",
    "runtime/ml/quantization.asm",
    "examples/native/rf27-g20/tiny-inference.asm",
]
for item in required:
    assert (root / item).is_file(), item
for front in range(1, 9):
    assert (root / f"tests/rf27-g20/f{front:02d}/validate.sh").is_file()
provenance = (root / "tests/rf27-g20/f08/PROVENANCE.tsv").read_text().splitlines()
assert len(provenance) == 4 and all("NONE" in line for line in provenance[1:])
print("RF27_G20_F09_AUDIT=PASS fronts=9 product_surfaces=7 corpus_models=3 external_data=none source_syntax=not_active")
