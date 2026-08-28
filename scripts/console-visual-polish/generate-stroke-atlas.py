#!/usr/bin/env python3
"""Generate Candidate B's dependency-free grayscale stroke atlas.

The legacy 5x7 rows are treated as stroke topology/control points. They are
never expanded as square source pixels: adjacent points form continuous
rounded line segments, rasterized directly into an 8x12 target at 8x8 sample
coverage. This keeps provenance internal while avoiding nearest-neighbour or
area-scaled 5x7 blocks.
"""
from __future__ import annotations

import argparse
import math
import re
from pathlib import Path

ATLAS_FIRST = 32
ATLAS_LAST = 126
ATLAS_WIDTH = 9
ATLAS_HEIGHT = 13
SUPERSAMPLE = 8
STROKE_RADIUS = 0.50
CRISP_HALF_WIDTH = 0.47

TABLES = {
    "glyph_upper": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "glyph_lower": "abcdefghijklmnopqrstuvwxyz",
    "glyph_digits": "0123456789",
}
PUNCTUATION = {
    "punctuation_question": "?",
    "punctuation_left_paren": "(",
    "punctuation_right_paren": ")",
    "punctuation_left_bracket": "[",
    "punctuation_right_bracket": "]",
    "punctuation_left_brace": "{",
    "punctuation_right_brace": "}",
    "punctuation_comma": ",",
    "punctuation_semicolon": ";",
    "punctuation_plus": "+",
    "punctuation_star": "*",
    "punctuation_slash": "/",
    "punctuation_exclamation": "!",
    "punctuation_dot": ".",
    "punctuation_colon": ":",
    "punctuation_dash": "-",
    "punctuation_underscore": "_",
    "punctuation_equals": "=",
}


def parse_rows(source: Path) -> dict[str, tuple[int, ...]]:
    text = source.read_text(encoding="utf-8")
    found: dict[str, tuple[int, ...]] = {}
    for label, chars in TABLES.items():
        match = re.search(
            rf"^{label}:\s*\n(?P<body>(?:\s*db\s+[^\n]+\n)+)", text, re.MULTILINE
        )
        if not match:
            raise SystemExit(f"missing source table: {label}")
        values = tuple(
            int(value)
            for line in match.group("body").splitlines()
            for value in re.findall(r"\d+", line)
        )
        if len(values) != len(chars) * 7:
            raise SystemExit(f"invalid {label} rows: {len(values)}")
        for index, char in enumerate(chars):
            found[char] = values[index * 7 : (index + 1) * 7]
    for label, char in PUNCTUATION.items():
        match = re.search(rf"^{label}:\s*db\s+([^\n]+)$", text, re.MULTILINE)
        if not match:
            raise SystemExit(f"missing source glyph: {label}")
        values = tuple(int(value) for value in re.findall(r"\d+", match.group(1)))
        if len(values) != 7:
            raise SystemExit(f"invalid {label} rows: {len(values)}")
        found[char] = values
    found[" "] = (0,) * 7
    return found


def point(column: int, row: int) -> tuple[float, float]:
    # Target-space centers leave a subpixel margin for rounded antialiasing.
    return 0.65 + column * 1.925, 0.65 + row * 1.925


def distance_to_segment(
    px: float, py: float, ax: float, ay: float, bx: float, by: float
) -> float:
    dx = bx - ax
    dy = by - ay
    length_squared = dx * dx + dy * dy
    if length_squared == 0.0:
        return math.hypot(px - ax, py - ay)
    position = ((px - ax) * dx + (py - ay) * dy) / length_squared
    position = min(1.0, max(0.0, position))
    qx = ax + position * dx
    qy = ay + position * dy
    return math.hypot(px - qx, py - qy)


def topology(rows: tuple[int, ...]) -> tuple[
    list[tuple[float, float]], list[tuple[float, float, float, float]]
]:
    active = {
        (column, row)
        for row, bits in enumerate(rows)
        for column in range(5)
        if bits & (16 >> column)
    }
    segments: list[tuple[float, float, float, float]] = []
    # Four forward directions join the topology without duplicating segments.
    for column, row in sorted(active, key=lambda item: (item[1], item[0])):
        for dc, dr in ((1, 0), (0, 1), (1, 1), (-1, 1)):
            neighbour = (column + dc, row + dr)
            if neighbour in active:
                ax, ay = point(column, row)
                bx, by = point(*neighbour)
                segments.append((ax, ay, bx, by))
    # Isolated points (punctuation) are round caps.
    points = [point(column, row) for column, row in active]
    return points, segments


def rasterize_rounded(rows: tuple[int, ...]) -> bytes:
    points, segments = topology(rows)
    samples = SUPERSAMPLE * SUPERSAMPLE
    output = bytearray()
    for y in range(ATLAS_HEIGHT):
        for x in range(ATLAS_WIDTH):
            covered = 0
            for sy in range(SUPERSAMPLE):
                py = y + (sy + 0.5) / SUPERSAMPLE
                for sx in range(SUPERSAMPLE):
                    px = x + (sx + 0.5) / SUPERSAMPLE
                    inside = any(
                        distance_to_segment(px, py, *segment) <= STROKE_RADIUS
                        for segment in segments
                    )
                    if not inside:
                        inside = any(
                            math.hypot(px - qx, py - qy) <= STROKE_RADIUS
                            for qx, qy in points
                        )
                    covered += int(inside)
            output.append((covered * 255 + samples // 2) // samples)
    return bytes(output)


def crisp_point(column: int, row: int) -> tuple[float, float]:
    # Grid centers land on physical pixel centers: straight stems therefore
    # receive fully opaque core pixels instead of two soft fractional edges.
    return 0.5 + column * 2.0, 0.5 + row * 2.0


def inside_square_segment(
    px: float, py: float, ax: float, ay: float, bx: float, by: float
) -> bool:
    dx = bx - ax
    dy = by - ay
    length = math.hypot(dx, dy)
    if length == 0.0:
        return abs(px - ax) <= CRISP_HALF_WIDTH and abs(py - ay) <= CRISP_HALF_WIDTH
    ux = dx / length
    uy = dy / length
    along = (px - ax) * ux + (py - ay) * uy
    across = (px - ax) * -uy + (py - ay) * ux
    return (
        -CRISP_HALF_WIDTH <= along <= length + CRISP_HALF_WIDTH
        and abs(across) <= CRISP_HALF_WIDTH
    )


def rasterize_crisp(rows: tuple[int, ...]) -> bytes:
    active = {
        (column, row)
        for row, bits in enumerate(rows)
        for column in range(5)
        if bits & (16 >> column)
    }
    points = [crisp_point(column, row) for column, row in active]
    segments: list[tuple[float, float, float, float]] = []
    for column, row in sorted(active, key=lambda item: (item[1], item[0])):
        for dc, dr in ((1, 0), (0, 1), (1, 1), (-1, 1)):
            neighbour = (column + dc, row + dr)
            if neighbour in active:
                segments.append((*crisp_point(column, row), *crisp_point(*neighbour)))
    samples = SUPERSAMPLE * SUPERSAMPLE
    output = bytearray()
    for y in range(ATLAS_HEIGHT):
        for x in range(ATLAS_WIDTH):
            covered = 0
            for sy in range(SUPERSAMPLE):
                py = y + (sy + 0.5) / SUPERSAMPLE
                for sx in range(SUPERSAMPLE):
                    px = x + (sx + 0.5) / SUPERSAMPLE
                    inside = any(
                        inside_square_segment(px, py, *segment) for segment in segments
                    )
                    if not inside:
                        inside = any(
                            abs(px - qx) <= CRISP_HALF_WIDTH
                            and abs(py - qy) <= CRISP_HALF_WIDTH
                            for qx, qy in points
                        )
                    covered += int(inside)
            raw = covered / samples
            # Narrow the transition band: grayscale remains on diagonals and
            # fractional joins, while aligned stems gain a crisp opaque core.
            sharpened = min(1.0, max(0.0, (raw - 0.18) / 0.64))
            output.append(round(sharpened * 255))
    return bytes(output)


def render_include(
    glyphs: dict[str, tuple[int, ...]], source: Path, style: str
) -> str:
    fallback = glyphs["?"]
    if style == "rounded":
        rasterizer = rasterize_rounded
        label = "live_glyph_smooth_atlas"
        contract = f"radius={STROKE_RADIUS:.2f}"
    else:
        rasterizer = rasterize_crisp
        label = "live_glyph_crisp_atlas"
        contract = f"square_half_width={CRISP_HALF_WIDTH:.2f}, sharpen=0.18..0.82"
    lines = [
        "; Generated deterministically by generate-stroke-atlas.py.",
        f"; Source topology: {source.as_posix()} (internal 5x7 control points).",
        f"; Raster: {ATLAS_WIDTH}x{ATLAS_HEIGHT}, {SUPERSAMPLE}x{SUPERSAMPLE} coverage, {contract}.",
        f"{label}:",
    ]
    for codepoint in range(ATLAS_FIRST, ATLAS_LAST + 1):
        char = chr(codepoint)
        pixels = rasterizer(glyphs.get(char, fallback))
        display = char if char not in (";", "\\") else f"ASCII {codepoint}"
        lines.append(f" ; {codepoint:3d} {display}")
        for row in range(ATLAS_HEIGHT):
            values = pixels[row * ATLAS_WIDTH : (row + 1) * ATLAS_WIDTH]
            lines.append(" db " + ",".join(str(value) for value in values))
    lines.extend(
        (
            f"{label}_end:",
            f"%if {label}_end-{label} != 95*{ATLAS_WIDTH}*{ATLAS_HEIGHT}",
            ' %error "invalid smooth glyph atlas size"',
            "%endif",
            "",
        )
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--style", choices=("rounded", "crisp"), default="rounded")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = render_include(parse_rows(args.source), args.source, args.style)
    if args.write:
        args.output.write_text(rendered, encoding="utf-8")
        print(f"R4_STROKE_ATLAS_WRITE=PASS bytes={len(rendered.encode('utf-8'))}")
        return
    if not args.output.exists() or args.output.read_text(encoding="utf-8") != rendered:
        raise SystemExit("R4_STROKE_ATLAS_CHECK=FAIL")
    print(
        f"R4_STROKE_ATLAS_CHECK=PASS style={args.style} glyphs=95 "
        f"raster={ATLAS_WIDTH}x{ATLAS_HEIGHT} coverage=8x8"
    )


if __name__ == "__main__":
    main()
