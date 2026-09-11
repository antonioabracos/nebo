#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import random
import struct
import sys
from dataclasses import dataclass

ROOT, ROW, COLUMN, GRID, LABEL, BUTTON, TEXTINPUT = range(1, 8)
VISIBLE = 32
FOCUSABLE = 1
FOCUSED = 4
EDITABLE = 16
EVENT_FOCUS, EVENT_BLUR, EVENT_CLICK, EVENT_CHANGE, EVENT_SUBMIT = range(1, 6)
GOLDEN_MAGIC = 0x4E42554731384637
NONE = (1 << 64) - 1


@dataclass
class Node:
    kind: int
    flags: int
    parent: int
    gap: int = 0
    columns: int = 1
    children: list[int] | None = None
    box: tuple[int, int, int, int] = (0, 0, 0, 0)

    def __post_init__(self) -> None:
        if self.children is None:
            self.children = []


def split_axis(length: int, count: int, gap: int) -> list[tuple[int, int]]:
    if count <= 0:
        return []
    total_gap = gap * (count - 1)
    if total_gap > length:
        raise OverflowError("gap exceeds axis")
    available = length - total_gap
    base, rem = divmod(available, count)
    out: list[tuple[int, int]] = []
    cursor = 0
    for index in range(count):
        size = base + (1 if index < rem else 0)
        out.append((cursor, size))
        cursor += size + gap
    return out


def layout(nodes: list[Node], width: int, height: int) -> None:
    if not nodes or nodes[0].kind != ROOT:
        raise ValueError("missing root")
    candidates = [(0, 0, 0, 0) for _ in nodes]
    candidates[0] = (0, 0, width, height)
    for index, node in enumerate(nodes):
        x, y, w, h = candidates[index]
        children = node.children or []
        if node.kind not in {ROOT, ROW, COLUMN, GRID}:
            if children:
                raise ValueError("leaf has child")
            continue
        if not children:
            continue
        if node.kind in {ROOT, COLUMN}:
            tracks = split_axis(h, len(children), node.gap)
            for child, (offset, size) in zip(children, tracks, strict=True):
                candidates[child] = (x, y + offset, w, size)
        elif node.kind == ROW:
            tracks = split_axis(w, len(children), node.gap)
            for child, (offset, size) in zip(children, tracks, strict=True):
                candidates[child] = (x + offset, y, size, h)
        else:
            columns = node.columns
            if not 1 <= columns <= 64:
                raise ValueError("columns")
            rows = (len(children) + columns - 1) // columns
            xs = split_axis(w, columns, node.gap)
            ys = split_axis(h, rows, node.gap)
            for ordinal, child in enumerate(children):
                row, column = divmod(ordinal, columns)
                xo, cw = xs[column]
                yo, ch = ys[row]
                candidates[child] = (x + xo, y + yo, cw, ch)
    for node, box in zip(nodes, candidates, strict=True):
        node.box = box


def golden_nodes() -> list[Node]:
    nodes = [
        Node(ROOT, VISIBLE, -1, gap=0),
        Node(ROW, VISIBLE, 0, gap=1),
        Node(LABEL, VISIBLE, 1),
        Node(BUTTON, VISIBLE | FOCUSABLE, 1),
        Node(TEXTINPUT, VISIBLE | FOCUSABLE | EDITABLE, 1),
        Node(COLUMN, VISIBLE, 0, gap=1),
        Node(LABEL, VISIBLE, 5),
        Node(GRID, VISIBLE, 5, gap=1, columns=2),
        Node(BUTTON, VISIBLE | FOCUSABLE | FOCUSED, 7),
        Node(BUTTON, VISIBLE | FOCUSABLE, 7),
        Node(LABEL, VISIBLE, 7),
    ]
    nodes[0].children = [1, 5]
    nodes[1].children = [2, 3, 4]
    nodes[5].children = [6, 7]
    nodes[7].children = [8, 9, 10]
    layout(nodes, 64, 48)
    return nodes


def golden_bytes() -> bytes:
    nodes = golden_nodes()
    events = [
        (1, EVENT_FOCUS, 3, 0, 0, 0),
        (2, EVENT_CLICK, 3, 13, 0, 0),
        (3, EVENT_BLUR, 3, 0, 0, 0),
        (4, EVENT_FOCUS, 4, 0, 0, 0),
        (5, EVENT_CHANGE, 4, 1, 1, ord("A")),
        (6, EVENT_SUBMIT, 4, 13, 0, 0),
        (7, EVENT_BLUR, 4, 0, 0, 0),
        (8, EVENT_FOCUS, 8, 0, 0, 0),
        (9, EVENT_CLICK, 8, 13, 0, 0),
    ]
    output = bytearray()
    output += struct.pack("<8Q", GOLDEN_MAGIC, 1, len(nodes), len(events), 64, 48, 1, 8)
    for index, node in enumerate(nodes):
        x, y, w, h = node.box
        parent = NONE if node.parent < 0 else node.parent
        output += struct.pack("<8Q", index, node.kind, node.flags, parent, x, y, w, h)
    for sequence, kind, node, p0, p1, p2 in events:
        output += struct.pack("<QIIQQQQQQ", sequence, kind, 0, node, p0, p1, p2, 0, 0)
    if len(output) != 1344:
        raise AssertionError(len(output))
    return bytes(output)


def property_model(seed: int, cases: int) -> dict[str, object]:
    rng = random.Random(seed)
    counters = {"row": 0, "column": 0, "grid": 0, "expected_overflow": 0}
    digest = hashlib.sha256()
    for index in range(cases):
        if index < 355:
            kind = "row"
        elif index < 731:
            kind = "column"
        elif index < 1199:
            kind = "grid"
        else:
            kind = "overflow"
        width = rng.randint(1, 2048)
        height = rng.randint(1, 2048)
        children = rng.randint(1, 64)
        columns = rng.randint(1, min(64, children))
        if kind == "row":
            max_gap = width // (children - 1) if children > 1 else 256
            gap = rng.randint(0, min(256, max_gap))
        elif kind == "column":
            max_gap = height // (children - 1) if children > 1 else 256
            gap = rng.randint(0, min(256, max_gap))
        elif kind == "grid":
            rows = (children + columns - 1) // columns
            max_x = width // (columns - 1) if columns > 1 else 256
            max_y = height // (rows - 1) if rows > 1 else 256
            gap = rng.randint(0, min(256, max_x, max_y))
        else:
            gap = 256
        record: dict[str, object] = {
            "i": index,
            "kind": kind,
            "width": width,
            "height": height,
            "children": children,
            "gap": gap,
            "columns": columns,
        }
        try:
            if kind == "row":
                tracks = split_axis(width, children, gap)
                assert sum(size for _, size in tracks) + gap * (children - 1) == width
                counters["row"] += 1
                record["tracks"] = tracks[:4]
            elif kind == "column":
                tracks = split_axis(height, children, gap)
                assert sum(size for _, size in tracks) + gap * (children - 1) == height
                counters["column"] += 1
                record["tracks"] = tracks[:4]
            elif kind == "grid":
                rows = (children + columns - 1) // columns
                xs = split_axis(width, columns, gap)
                ys = split_axis(height, rows, gap)
                assert sum(size for _, size in xs) + gap * (columns - 1) == width
                assert sum(size for _, size in ys) + gap * (rows - 1) == height
                counters["grid"] += 1
                record["x"] = xs[:3]
                record["y"] = ys[:3]
            else:
                split_axis(1, 64, 256)
                raise AssertionError("overflow not detected")
        except OverflowError:
            counters["expected_overflow"] += 1
            record["overflow"] = True
        digest.update(json.dumps(record, sort_keys=True, separators=(",", ":")).encode())
        digest.update(b"\n")
    return {
        "seed": seed,
        "cases": cases,
        "counters": counters,
        "sha256": digest.hexdigest(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--golden", action="store_true")
    parser.add_argument("--properties", action="store_true")
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x271807)
    parser.add_argument("--cases", type=int, default=5000)
    args = parser.parse_args()
    if args.golden:
        sys.stdout.buffer.write(golden_bytes())
        return 0
    if args.properties:
        result = property_model(args.seed, args.cases)
        counters = result["counters"]
        print(
            "RF27_G18_F07_LAYOUT_MODEL=PASS "
            f"seed=0x{args.seed:x} cases={args.cases} digest={result['sha256']} "
            f"row={counters['row']} column={counters['column']} "
            f"grid={counters['grid']} expected_overflow={counters['expected_overflow']}"
        )
        print(json.dumps(result, sort_keys=True))
        return 0
    data = golden_bytes()
    nodes = golden_nodes()
    assert len(nodes) == 11
    assert len(data) == 1344
    assert nodes[3].box == (22, 0, 21, 24)
    assert nodes[8].box == (0, 37, 32, 5)
    print("RF27_G18_F07_ORACLE_SELFTEST=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
