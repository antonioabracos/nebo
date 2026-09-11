#!/usr/bin/env python3
"""Generate the finite deterministic C07 Tuple conformance corpus."""
from __future__ import annotations

import argparse
from pathlib import Path


def emit(root: Path, case_id: str, category: str, source: str, expected: int, rows: list[str]) -> None:
    path = root / category.lower() / f"{case_id}.no"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(source.rstrip() + "\n", encoding="utf-8", newline="\n")
    rows.append(f"{case_id}\t{category}\t{path.relative_to(root).as_posix()}\t{expected}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    root = args.output
    if root.exists():
        raise SystemExit("C07_F09_CORPUS_DESTINATION_EXISTS")
    root.mkdir(parents=True)
    rows = ["case_id\tcategory\tsource\texpected_exit"]

    for arity in range(9):
        values = ", ".join(str(index + 1) for index in range(arity))
        for spelling, constructor in (("canonical", f"Tuple.of({values})"), ("compat", f"Tuple({values})")):
            if arity == 0:
                tail = "tuple.length().return;"
            else:
                tail = f"tuple.at<{arity - 1}>().return;" if spelling == "canonical" else f"tuple.{arity - 1}.return;"
            emit(root, f"p-{spelling}-arity-{arity}", "POSITIVE", f"start() {{ {constructor}.tuple; {tail} }}", arity, rows)

    for depth in range(1, 5):
        expression = "9"
        for _ in range(depth):
            expression = f"Tuple.of({expression})"
        projection = ".at<0>()" * depth
        emit(root, f"p-nested-depth-{depth}", "POSITIVE", f"start() {{ {expression}.tuple; tuple{projection}.return; }}", 9, rows)

    values9 = ", ".join(str(index) for index in range(9))
    emit(root, "n-arity-9", "NEGATIVE", f"start() {{ Tuple.of({values9}).tuple; 0.return; }}", 1, rows)
    for arity in range(9):
        values = ", ".join(str(index + 1) for index in range(arity))
        emit(root, f"n-bounds-{arity}", "NEGATIVE", f"start() {{ Tuple.of({values}).tuple; tuple.at<{arity}>().return; }}", 1, rows)

    for index in range(64):
        width = index % 10
        values = ", ".join(str(item) for item in range(width))
        prefix = " " * (index % 4)
        # Every fuzz seed is intentionally truncated after a recognized owner.
        source = f"{prefix}start() {{ Tuple.of({values}"
        emit(root, f"f-truncated-{index:02d}", "FUZZ", source, 1, rows)

    (root / "MANIFEST.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")
    print("C07_F09_CORPUS_GREEN positives=22 negatives=10 fuzz=64 total=96 seed=C07-F09-v1")


if __name__ == "__main__":
    main()
