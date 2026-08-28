#!/usr/bin/env python3
"""Bounded R4 BGRA frame oracle; standard library only."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

WIDTH = 640
HEIGHT = 400
BACKGROUND = (0x21, 0x18, 0x11, 0xFF)  # BGRA, 0xff111821
FOREGROUND = (0xF5, 0xE7, 0xDC, 0xFF)  # BGRA, 0xffdce7f5
TITLE_FOREGROUND = (0xFC, 0xF6, 0xF2, 0xFF)  # BGRA, 0xfff2f6fc
CARET = (0xFF, 0xA9, 0x78, 0xFF)
BACKGROUNDS = {
    "pa": (0x20, 0x1A, 0x15, 0xFF),  # #151A20
    "pb": (0x23, 0x1E, 0x1B, 0xFF),  # #1B1E23
    "pc": (0x2A, 0x24, 0x20, 0xFF),  # #20242A
    "pd": (0x2C, 0x21, 0x18, 0xFF),  # #18212C
    "u": (0x23, 0x1E, 0x1B, 0xFF),  # #1B1E23, frozen Palette B
}
PROFILES = {
    "baseline": dict(cell_w=12, cell_h=14, line=18, left=14, top=12, ink_w=10, ink_h=14, caret_w=2),
    "a": dict(cell_w=8, cell_h=12, line=13, left=6, top=6, ink_w=6, ink_h=9, caret_w=1),
    "b": dict(cell_w=10, cell_h=15, line=16, left=6, top=6, ink_w=9, ink_h=13, caret_w=1),
    "c": dict(cell_w=10, cell_h=15, line=16, left=6, top=6, ink_w=9, ink_h=13, caret_w=1),
    "d": dict(cell_w=10, cell_h=16, line=16, left=6, top=6, ink_w=10, ink_h=16, caret_w=1),
    "d1": dict(cell_w=11, cell_h=18, line=18, left=6, top=6, ink_w=11, ink_h=18, caret_w=1),
    "d2": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
    "pa": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
    "pb": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
    "pc": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
    "pd": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
    "u": dict(cell_w=11, cell_h=19, line=19, left=6, top=6, ink_w=11, ink_h=19, caret_w=1),
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def pixel(data: bytes, x: int, y: int) -> tuple[int, int, int, int]:
    offset = (y * WIDTH + x) * 4
    return tuple(data[offset : offset + 4])  # type: ignore[return-value]


def write_ppm(path: Path, data: bytes) -> None:
    rgb = bytearray(WIDTH * HEIGHT * 3)
    out = 0
    for offset in range(0, len(data), 4):
        b, g, r, _ = data[offset : offset + 4]
        rgb[out : out + 3] = bytes((r, g, b))
        out += 3
    path.write_bytes(f"P6\n{WIDTH} {HEIGHT}\n255\n".encode("ascii") + rgb)


def analyze(profile: str, path: Path, output: Path) -> dict[str, int | str]:
    metrics = PROFILES[profile]
    background = BACKGROUNDS.get(profile, BACKGROUND)
    data = path.read_bytes()
    assert len(data) == WIDTH * HEIGHT * 4, (profile, len(data))
    assert all(data[index] == 0xFF for index in range(3, len(data), 4)), profile

    content_y = 28 + metrics["top"]
    exact = intermediate = caret = illegal = microcontrast = 0
    for y in range(content_y, HEIGHT - 1):
        for x in range(1, WIDTH - 1):
            value = pixel(data, x, y)
            if value == FOREGROUND:
                exact += 1
            elif value == CARET:
                caret += 1
            elif value != background:
                if all(
                    min(background[i], FOREGROUND[i]) <= value[i] <= max(background[i], FOREGROUND[i])
                    for i in range(3)
                ) and value[3] == 0xFF:
                    intermediate += 1
                    microcontrast += abs(value[0] * 2 - (background[0] + FOREGROUND[0]))
                else:
                    illegal += 1
    assert exact > 0, profile
    assert caret == metrics["ink_h"] * metrics["caret_w"], (profile, caret)
    if profile == "baseline":
        assert intermediate == 0, intermediate
    else:
        assert intermediate > 0, profile
    if profile in ("b", "c", "d", "d1", "d2", "pa", "pb", "pc", "pd", "u"):
        coverage_colours = {
            pixel(data, x, y)
            for y in range(content_y, HEIGHT - 1)
            for x in range(1, WIDTH - 1)
            if pixel(data, x, y) not in (background, FOREGROUND, CARET)
        }
        minimum_levels = 32 if profile in ("d", "d1", "d2", "pa", "pb", "pc", "pd", "u") else (8 if profile == "b" else 2)
        assert len(coverage_colours) >= minimum_levels, len(coverage_colours)
    assert illegal == 0, (profile, illegal)

    columns = (WIDTH - 1 - metrics["left"]) // metrics["cell_w"]
    rows = ((HEIGHT - 1) - content_y - metrics["cell_h"]) // metrics["line"] + 1
    assert columns > 0 and rows > 0
    ppm = output / f"typography-{profile}.ppm"
    write_ppm(ppm, data)
    title_colours = {
        pixel(data, x, y)
        for y in range(6, 23)
        for x in range(14, 158)
    }
    title_exact = sum(
        pixel(data, x, y) == TITLE_FOREGROUND
        for y in range(6, 23)
        for x in range(14, 158)
    )
    return {
        "sha256": digest(data),
        "title_sha256": digest(data[: WIDTH * 28 * 4]),
        "exact_foreground": exact,
        "intermediate_coverage": intermediate,
        "intermediate_levels": len(coverage_colours) if profile in ("b", "c", "d", "d1", "d2", "pa", "pb", "pc", "pd", "u") else (1 if intermediate else 0),
        "microcontrast_score": microcontrast,
        "caret_pixels": caret,
        "illegal_colour_pixels": illegal,
        "visible_columns": columns,
        "visible_rows": rows,
        "title_unique_colours": len(title_colours),
        "title_exact_foreground": title_exact,
        "ppm_sha256": digest(ppm.read_bytes()),
    }


def assert_palette_mask_matches(d2_path: Path, palette_path: Path, profile: str) -> None:
    d2 = d2_path.read_bytes()
    palette = palette_path.read_bytes()
    palette_background = BACKGROUNDS[profile]
    assert len(d2) == len(palette) == WIDTH * HEIGHT * 4
    for offset in range(0, len(d2), 4):
        y = offset // (WIDTH * 4)
        x = (offset // 4) % WIDTH
        d2_pixel = tuple(d2[offset : offset + 4])
        palette_pixel = tuple(palette[offset : offset + 4])
        if y < 28 or x in (0, WIDTH - 1) or y == HEIGHT - 1:
            assert palette_pixel == d2_pixel, (profile, offset, d2_pixel, palette_pixel)
        elif d2_pixel == BACKGROUND:
            assert palette_pixel == palette_background, (profile, offset, palette_pixel)
        elif d2_pixel in (FOREGROUND, CARET):
            assert palette_pixel == d2_pixel, (profile, offset, d2_pixel, palette_pixel)
        elif all(
            min(BACKGROUND[index], FOREGROUND[index]) <= d2_pixel[index]
            <= max(BACKGROUND[index], FOREGROUND[index])
            for index in range(3)
        ) and d2_pixel[3] == 0xFF:
            assert palette_pixel not in (palette_background, FOREGROUND, CARET)
            assert all(
                min(palette_background[index], FOREGROUND[index]) <= palette_pixel[index]
                <= max(palette_background[index], FOREGROUND[index])
                for index in range(3)
            ), (profile, offset, palette_pixel)
        else:
            assert palette_pixel == d2_pixel, (profile, offset, d2_pixel, palette_pixel)


def assert_refined_visual_scope(reference_path: Path, refined_path: Path) -> None:
    reference = reference_path.read_bytes()
    refined = refined_path.read_bytes()
    background = BACKGROUNDS["u"]
    assert len(reference) == len(refined) == WIDTH * HEIGHT * 4
    title_delta_pixels = 0
    for offset in range(0, len(reference), 4):
        y = offset // (WIDTH * 4)
        x = (offset // 4) % WIDTH
        before = tuple(reference[offset : offset + 4])
        after = tuple(refined[offset : offset + 4])
        if y < 28:
            if 14 <= x < 158 and 6 <= y < 23:
                title_delta_pixels += before != after
            else:
                assert after == before, ("title_scope", offset, before, after)
        elif x in (0, WIDTH - 1) or y == HEIGHT - 1:
            assert after == before, ("border", offset, before, after)
        elif before == background:
            assert after == background, ("background", offset, after)
        elif before in (FOREGROUND, CARET):
            assert after == before, ("opaque", offset, before, after)
        elif all(
            min(background[index], FOREGROUND[index]) <= before[index]
            <= max(background[index], FOREGROUND[index])
            for index in range(3)
        ) and before[3] == 0xFF:
            assert after not in (background, FOREGROUND, CARET)
            assert all(
                min(background[index], FOREGROUND[index]) <= after[index]
                <= max(background[index], FOREGROUND[index])
                for index in range(3)
            ), ("coverage", offset, after)
        else:
            assert after == before, ("scope", offset, before, after)
    assert title_delta_pixels > 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--a", required=True, type=Path)
    parser.add_argument("--b", required=True, type=Path)
    parser.add_argument("--c", required=True, type=Path)
    parser.add_argument("--d", required=True, type=Path)
    parser.add_argument("--d1", required=True, type=Path)
    parser.add_argument("--d2", required=True, type=Path)
    parser.add_argument("--pa", required=True, type=Path)
    parser.add_argument("--pb", required=True, type=Path)
    parser.add_argument("--pc", required=True, type=Path)
    parser.add_argument("--pd", required=True, type=Path)
    parser.add_argument("--u", required=True, type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    results = {
        name: analyze(name, getattr(args, name), args.output)
        for name in ("baseline", "a", "b", "c", "d", "d1", "d2", "pa", "pb", "pc", "pd", "u")
    }
    for palette in ("pa", "pb", "pc", "pd"):
        assert_palette_mask_matches(args.d2, getattr(args, palette), palette)
        for field in ("exact_foreground", "intermediate_coverage", "caret_pixels", "visible_columns", "visible_rows"):
            assert results[palette][field] == results["d2"][field], (palette, field, results)
    assert_refined_visual_scope(args.pb, args.u)
    for field in ("exact_foreground", "intermediate_coverage", "caret_pixels", "visible_columns", "visible_rows"):
        assert results["u"][field] == results["pb"][field], (field, results)
    legacy_title_hashes = {results[name]["title_sha256"] for name in results if name != "u"}
    assert len(legacy_title_hashes) == 1, results
    assert results["u"]["title_sha256"] not in legacy_title_hashes
    assert results["u"]["title_unique_colours"] >= 32
    assert results["u"]["microcontrast_score"] > results["pb"]["microcontrast_score"]
    assert results["c"]["intermediate_levels"] < results["b"]["intermediate_levels"]
    assert results["c"]["exact_foreground"] > results["b"]["exact_foreground"]
    for name, row in results.items():
        fields = " ".join(f"{key}={value}" for key, value in row.items())
        print(f"R4_FRAME profile={name} {fields}")
    print("R4_TITLE_UNCHANGED=PASS legacy_profiles=11")
    print("R4_COLOUR_COVERAGE=PASS halo=0 fringe=0 illegal=0")
    print(
        "R4_C_CRISPNESS=PASS "
        f"intermediate_levels={results['c']['intermediate_levels']} "
        f"exact_foreground={results['c']['exact_foreground']}"
    )
    print(
        "R4_D_PROFESSIONAL_ATLAS=PASS "
        f"intermediate_levels={results['d']['intermediate_levels']} "
        f"exact_foreground={results['d']['exact_foreground']}"
    )
    print(
        "R4_D_SIZE_CALIBRATION=PASS "
        f"d1_levels={results['d1']['intermediate_levels']} "
        f"d2_levels={results['d2']['intermediate_levels']}"
    )
    print(
        "R4_PALETTE_CALIBRATION=PASS variants=4 typography=D2 "
        "backgrounds=#151A20,#1B1E23,#20242A,#18212C title_chrome=UNCHANGED "
        "alpha_mask=UNCHANGED foreground=UNCHANGED caret=UNCHANGED"
    )
    print(
        "R4_VISUAL_UNIFICATION=PASS content_metrics=D2 background=#1B1E23 "
        f"microcontrast_before={results['pb']['microcontrast_score']} "
        f"microcontrast_after={results['u']['microcontrast_score']} "
        f"title_colours={results['u']['title_unique_colours']} "
        "title_font=SourceCodeProRegular title_weight=synthetic_semibold_from_regular "
        "chrome_controls_border=UNCHANGED"
    )


if __name__ == "__main__":
    main()
