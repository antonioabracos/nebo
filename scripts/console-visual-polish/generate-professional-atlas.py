#!/usr/bin/env python3
"""Generate the versioned NeboConsoleMonoAtlas Candidate D asset.

The build-only rasterizer opens the vendored TTF by explicit path.  It does
not query Fontconfig or an installed font set.  Pillow, its linked FreeType,
the source font, the license, all raster geometry and the integer downsample
are pinned so a changed toolchain fails before producing bytes.
"""
from __future__ import annotations

import argparse
import hashlib
import struct
from dataclasses import dataclass
from pathlib import Path

import PIL
from PIL import Image, ImageDraw, ImageFont

EXPECTED_PILLOW = "10.2.0"
EXPECTED_FREETYPE = "2.13.2"
EXPECTED_FONT_SHA256 = "74bd80d3e42a08517cd7e1108ba3d86f2da29ac0f3065be95e0357956ab9db37"
EXPECTED_LICENSE_SHA256 = "7c940e28a5388e9bba866cf0e408edda45fe0899ba98665b8f6ab31dc5e4b8ff"
EXPECTED_UNITS_PER_EM = 1000

TARGET_LEFT_PADDING = 6
TARGET_TOP_PADDING = 6
SUPERSAMPLE = 8


@dataclass(frozen=True)
class RasterProfile:
    profile_id: str
    source_font_size: int
    source_cell_width: int
    source_cell_height: int
    source_baseline: int
    target_pixel_size: str
    atlas_width: int
    atlas_height: int
    target_baseline: int
    target_line_height: int
    contrast_numerator: int = 1
    contrast_denominator: int = 1

    @property
    def target_cell(self) -> tuple[int, int]:
        return self.atlas_width, self.atlas_height


PROFILES = (
    RasterProfile("D", 108, 80, 128, 98, "13.5", 10, 16, 13, 16),
    RasterProfile("D1", 120, 88, 144, 110, "15.0", 11, 18, 14, 18),
    RasterProfile("D2", 128, 88, 152, 116, "16.0", 11, 19, 15, 19),
    RasterProfile("D2R", 128, 88, 152, 116, "16.0", 11, 19, 15, 19, 17, 16),
)

ASCII = tuple(range(0x20, 0x7F))
LATIN1_SUPPLEMENT = tuple(range(0x00A0, 0x0100))
EXTRA = (0x20AC, 0xFFFD)
CODEPOINTS = ASCII + LATIN1_SUPPLEMENT + EXTRA
REPLACEMENT_INDEX = len(CODEPOINTS) - 1
TITLE_PROFILE = PROFILES[0]
TITLE_CODEPOINTS = ASCII
TITLE_EMBOLDEN_SOURCE_PIXELS = 2


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def u16(data: bytes, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def font_tables(data: bytes) -> dict[str, tuple[int, int]]:
    count = u16(data, 4)
    result: dict[str, tuple[int, int]] = {}
    for index in range(count):
        offset = 12 + index * 16
        tag = data[offset : offset + 4].decode("ascii")
        table_offset = u32(data, offset + 8)
        table_length = u32(data, offset + 12)
        if table_offset + table_length > len(data):
            raise SystemExit(f"invalid TTF table bounds: {tag}")
        result[tag] = (table_offset, table_length)
    return result


def glyph_id_format4(data: bytes, table: int, codepoint: int) -> int:
    seg_count = u16(data, table + 6) // 2
    end_codes = table + 14
    start_codes = end_codes + seg_count * 2 + 2
    deltas = start_codes + seg_count * 2
    range_offsets = deltas + seg_count * 2
    for index in range(seg_count):
        end = u16(data, end_codes + index * 2)
        if codepoint > end:
            continue
        start = u16(data, start_codes + index * 2)
        if codepoint < start:
            return 0
        delta = u16(data, deltas + index * 2)
        range_offset_position = range_offsets + index * 2
        range_offset = u16(data, range_offset_position)
        if range_offset == 0:
            return (codepoint + delta) & 0xFFFF
        glyph_position = range_offset_position + range_offset + 2 * (codepoint - start)
        glyph = u16(data, glyph_position)
        return ((glyph + delta) & 0xFFFF) if glyph else 0
    return 0


def glyph_id_format12(data: bytes, table: int, codepoint: int) -> int:
    groups = u32(data, table + 12)
    offset = table + 16
    for _ in range(groups):
        start = u32(data, offset)
        end = u32(data, offset + 4)
        first_glyph = u32(data, offset + 8)
        if start <= codepoint <= end:
            return first_glyph + codepoint - start
        if codepoint < start:
            return 0
        offset += 12
    return 0


def cmap_subtables(data: bytes, tables: dict[str, tuple[int, int]]) -> list[tuple[int, int]]:
    cmap, length = tables["cmap"]
    count = u16(data, cmap + 2)
    result: list[tuple[int, int]] = []
    for index in range(count):
        record = cmap + 4 + index * 8
        platform = u16(data, record)
        encoding = u16(data, record + 2)
        table = cmap + u32(data, record + 4)
        if table + 2 > cmap + length or platform not in (0, 3):
            continue
        fmt = u16(data, table)
        if fmt in (4, 12):
            result.append((fmt, table))
    return sorted(set(result), key=lambda item: 0 if item[0] == 12 else 1)


def validate_font(font_path: Path, license_path: Path) -> tuple[bytes, int]:
    if PIL.__version__ != EXPECTED_PILLOW:
        raise SystemExit(f"Pillow version mismatch: {PIL.__version__} != {EXPECTED_PILLOW}")
    freetype = ImageFont.core.freetype2_version
    if freetype != EXPECTED_FREETYPE:
        raise SystemExit(f"FreeType version mismatch: {freetype} != {EXPECTED_FREETYPE}")
    if sha256(font_path) != EXPECTED_FONT_SHA256:
        raise SystemExit("source font SHA-256 mismatch")
    if sha256(license_path) != EXPECTED_LICENSE_SHA256:
        raise SystemExit("font license SHA-256 mismatch")
    data = font_path.read_bytes()
    tables = font_tables(data)
    required = {"cmap", "glyf", "head", "hhea", "hmtx", "loca", "maxp", "name"}
    if not required.issubset(tables):
        raise SystemExit("source font lacks required TrueType tables")
    units_per_em = u16(data, tables["head"][0] + 18)
    if units_per_em != EXPECTED_UNITS_PER_EM:
        raise SystemExit(f"units-per-em mismatch: {units_per_em}")
    subtables = cmap_subtables(data, tables)
    missing: list[int] = []
    for codepoint in CODEPOINTS[:-1]:
        present = any(
            (glyph_id_format12(data, table, codepoint) if fmt == 12 else glyph_id_format4(data, table, codepoint))
            for fmt, table in subtables
        )
        if not present:
            missing.append(codepoint)
    if missing:
        rendered = ",".join(f"U+{value:04X}" for value in missing)
        raise SystemExit(f"source font cmap lacks required coverage: {rendered}")
    replacement_is_mapped = any(
        (glyph_id_format12(data, table, 0xFFFD) if fmt == 12 else glyph_id_format4(data, table, 0xFFFD))
        for fmt, table in subtables
    )
    if replacement_is_mapped:
        raise SystemExit("source replacement mapping changed; re-audit the frozen .notdef policy")
    return data, units_per_em


def exact_area_downsample(source: Image.Image, profile: RasterProfile) -> bytes:
    expected = (profile.source_cell_width, profile.source_cell_height)
    if source.mode != "1" or source.size != expected:
        raise AssertionError("invalid source raster")
    pixels = source.load()
    output = bytearray()
    samples = SUPERSAMPLE * SUPERSAMPLE
    for target_y in range(profile.atlas_height):
        for target_x in range(profile.atlas_width):
            total = 0
            for source_y in range(target_y * SUPERSAMPLE, (target_y + 1) * SUPERSAMPLE):
                for source_x in range(target_x * SUPERSAMPLE, (target_x + 1) * SUPERSAMPLE):
                    total += pixels[source_x, source_y]
            coverage = (total * 255 + samples // 2) // samples
            if profile.contrast_numerator != profile.contrast_denominator and coverage not in (0, 255):
                delta = coverage - 128
                magnitude = (
                    abs(delta) * profile.contrast_numerator + profile.contrast_denominator // 2
                ) // profile.contrast_denominator
                coverage = 128 + (magnitude if delta >= 0 else -magnitude)
                coverage = max(1, min(254, coverage))
            output.append(coverage)
    return bytes(output)


def rasterize(font_path: Path, profile: RasterProfile) -> tuple[bytes, int, int]:
    font = ImageFont.truetype(
        str(font_path), size=profile.source_font_size, layout_engine=ImageFont.Layout.BASIC
    )
    atlas = bytearray()
    clipped: list[int] = []
    for codepoint in CODEPOINTS:
        source = Image.new("1", (profile.source_cell_width, profile.source_cell_height), 0)
        draw = ImageDraw.Draw(source)
        draw.text(
            (profile.source_cell_width // 2, profile.source_baseline),
            chr(codepoint),
            font=font,
            fill=1,
            anchor="ms",
        )
        if codepoint not in (0x20, 0x00A0, 0x00AD):
            boundary = (
                list(source.crop((0, 0, profile.source_cell_width, 1)).getdata())
                + list(source.crop((0, profile.source_cell_height - 1, profile.source_cell_width, profile.source_cell_height)).getdata())
                + list(source.crop((0, 0, 1, profile.source_cell_height)).getdata())
                + list(source.crop((profile.source_cell_width - 1, 0, profile.source_cell_width, profile.source_cell_height)).getdata())
            )
            if any(boundary):
                clipped.append(codepoint)
        atlas.extend(exact_area_downsample(source, profile))
    if clipped:
        rendered = ",".join(f"U+{value:04X}" for value in clipped)
        raise SystemExit(f"source raster touches cell boundary: {rendered}")
    levels = len(set(atlas))
    if levels < 32:
        raise SystemExit(f"insufficient Alpha8 coverage levels: {levels}")
    return bytes(atlas), levels, round(font.getlength("M"))


def rasterize_title(font_path: Path) -> tuple[bytes, int, int]:
    profile = TITLE_PROFILE
    font = ImageFont.truetype(
        str(font_path), size=profile.source_font_size, layout_engine=ImageFont.Layout.BASIC
    )
    atlas = bytearray()
    clipped: list[int] = []
    shifts = range(-(TITLE_EMBOLDEN_SOURCE_PIXELS // 2), TITLE_EMBOLDEN_SOURCE_PIXELS // 2 + 1)
    for codepoint in TITLE_CODEPOINTS:
        source = Image.new("1", (profile.source_cell_width, profile.source_cell_height), 0)
        draw = ImageDraw.Draw(source)
        for shift in shifts:
            draw.text(
                (profile.source_cell_width // 2 + shift, profile.source_baseline),
                chr(codepoint),
                font=font,
                fill=1,
                anchor="ms",
            )
        if codepoint != 0x20:
            boundary = (
                list(source.crop((0, 0, profile.source_cell_width, 1)).getdata())
                + list(source.crop((0, profile.source_cell_height - 1, profile.source_cell_width, profile.source_cell_height)).getdata())
                + list(source.crop((0, 0, 1, profile.source_cell_height)).getdata())
                + list(source.crop((profile.source_cell_width - 1, 0, profile.source_cell_width, profile.source_cell_height)).getdata())
            )
            if any(boundary):
                clipped.append(codepoint)
        atlas.extend(exact_area_downsample(source, profile))
    if clipped:
        rendered = ",".join(f"U+{value:04X}" for value in clipped)
        raise SystemExit(f"title source raster touches cell boundary: {rendered}")
    levels = len(set(atlas))
    if levels < 32:
        raise SystemExit(f"insufficient title Alpha8 coverage levels: {levels}")
    return bytes(atlas), levels, round(font.getlength("M"))


def render_atlas_block(profile: RasterProfile, atlas: bytes, levels: int) -> list[str]:
    raw_hash = hashlib.sha256(atlas).hexdigest()
    lines = [
        f"; SIZE_PROFILE={profile.profile_id}; TARGET_PIXEL_SIZE={profile.target_pixel_size}px",
        f"; RASTERIZATION_SOURCE_SIZE={profile.source_font_size}px; source_cell={profile.source_cell_width}x{profile.source_cell_height}",
        f"; atlas_cell={profile.atlas_width}x{profile.atlas_height}; baseline={profile.target_baseline}; line={profile.target_line_height}",
        f"; ALPHA8_COVERAGE_LEVELS={levels}; ATLAS_SHA256={raw_hash}",
        f"%define NEBO_CONSOLE_MONO_ATLAS_WIDTH {profile.atlas_width}",
        f"%define NEBO_CONSOLE_MONO_ATLAS_HEIGHT {profile.atlas_height}",
        f"%define NEBO_CONSOLE_MONO_ATLAS_COUNT {len(CODEPOINTS)}",
        f"%define NEBO_CONSOLE_MONO_ATLAS_REPLACEMENT_INDEX {REPLACEMENT_INDEX}",
        "nebo_console_mono_atlas_codepoints:",
    ]
    for start in range(0, len(CODEPOINTS), 12):
        values = CODEPOINTS[start : start + 12]
        lines.append(" dd " + ",".join(f"0x{value:04x}" for value in values))
    lines.append("nebo_console_mono_atlas:")
    stride = profile.atlas_width * profile.atlas_height
    for index, codepoint in enumerate(CODEPOINTS):
        lines.append(f" ; index={index} codepoint=U+{codepoint:04X}")
        glyph = atlas[index * stride : (index + 1) * stride]
        for row in range(profile.atlas_height):
            values = glyph[row * profile.atlas_width : (row + 1) * profile.atlas_width]
            lines.append(" db " + ",".join(str(value) for value in values))
    lines.extend(
        (
            "nebo_console_mono_atlas_end:",
            "%if nebo_console_mono_atlas_end-nebo_console_mono_atlas != NEBO_CONSOLE_MONO_ATLAS_COUNT*NEBO_CONSOLE_MONO_ATLAS_WIDTH*NEBO_CONSOLE_MONO_ATLAS_HEIGHT",
            ' %error "invalid NeboConsoleMonoAtlas byte size"',
            "%endif",
            "",
        )
    )
    return lines


def render_title_atlas_block(atlas: bytes, levels: int) -> list[str]:
    profile = TITLE_PROFILE
    raw_hash = hashlib.sha256(atlas).hexdigest()
    lines = [
        "; TITLE_PROFILE=SourceCodeProRegular synthetic_semibold_from_regular",
        f"; RASTERIZATION_SOURCE_SIZE={profile.source_font_size}px; source_cell={profile.source_cell_width}x{profile.source_cell_height}",
        f"; atlas_cell={profile.atlas_width}x{profile.atlas_height}; baseline={profile.target_baseline}; line={profile.target_line_height}",
        f"; SYNTHETIC_EMBOLDEN_X={TITLE_EMBOLDEN_SOURCE_PIXELS}/{SUPERSAMPLE}px; ALPHA8_COVERAGE_LEVELS={levels}; ATLAS_SHA256={raw_hash}",
        f"%define NEBO_CONSOLE_TITLE_ATLAS_WIDTH {profile.atlas_width}",
        f"%define NEBO_CONSOLE_TITLE_ATLAS_HEIGHT {profile.atlas_height}",
        f"%define NEBO_CONSOLE_TITLE_ATLAS_COUNT {len(TITLE_CODEPOINTS)}",
        f"%define NEBO_CONSOLE_TITLE_ATLAS_FALLBACK_INDEX {ord('?') - 0x20}",
        "nebo_console_title_atlas:",
    ]
    stride = profile.atlas_width * profile.atlas_height
    for index, codepoint in enumerate(TITLE_CODEPOINTS):
        lines.append(f" ; index={index} codepoint=U+{codepoint:04X}")
        glyph = atlas[index * stride : (index + 1) * stride]
        for row in range(profile.atlas_height):
            values = glyph[row * profile.atlas_width : (row + 1) * profile.atlas_width]
            lines.append(" db " + ",".join(str(value) for value in values))
    lines.extend(
        (
            "nebo_console_title_atlas_end:",
            "%if nebo_console_title_atlas_end-nebo_console_title_atlas != NEBO_CONSOLE_TITLE_ATLAS_COUNT*NEBO_CONSOLE_TITLE_ATLAS_WIDTH*NEBO_CONSOLE_TITLE_ATLAS_HEIGHT",
            ' %error "invalid Nebo Console title atlas byte size"',
            "%endif",
            "",
        )
    )
    return lines


def render_include(
    generated: list[tuple[RasterProfile, bytes, int]],
    title_atlas: bytes,
    title_levels: int,
    units_per_em: int,
) -> str:
    lines = [
        "; NeboConsoleMonoAtlas — deterministic generated Alpha8 asset.",
        "; DERIVED_FROM=Source Code Pro Regular",
        "; LICENSE=SIL Open Font License 1.1",
        "; ORIGINAL_COPYRIGHT=© 2023 Adobe (http://www.adobe.com/), with Reserved Font Name ‘Source’",
        "; Adobe does not endorse Nebo or this derived asset.",
        "; Complete license: sdk/nebo-1.0/licenses/NeboConsoleMonoAtlas-OFL-1.1.md",
        f"; SOURCE_FONT_SHA256={EXPECTED_FONT_SHA256}",
        f"; SOURCE_UNITS_PER_EM={units_per_em}",
        f"; RASTERIZER=Pillow {EXPECTED_PILLOW}; FreeType {EXPECTED_FREETYPE}; Layout.BASIC",
        f"; DOWNSAMPLE_METHOD=exact integer {SUPERSAMPLE}x{SUPERSAMPLE} area average",
        f"; COVERAGE=ASCII printable + Latin-1 Supplement + Euro + replacement ({len(CODEPOINTS)} glyphs)",
        "; REPLACEMENT_SOURCE=source font .notdef glyph (TTF cmap has no U+FFFD mapping)",
    ]
    for index, (profile, atlas, levels) in enumerate(generated):
        directive = "%if" if index == 0 else "%elif"
        lines.append(
            f"{directive} NEBO_LIVE_PROFESSIONAL_SIZE_PROFILE = NEBO_LIVE_PROFESSIONAL_SIZE_{profile.profile_id}"
        )
        lines.extend(render_atlas_block(profile, atlas, levels))
    lines.extend(("%else", ' %error "unknown professional atlas size profile"', "%endif", ""))
    lines.extend(render_title_atlas_block(title_atlas, title_levels))
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", required=True, type=Path)
    parser.add_argument("--license", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()

    _, units_per_em = validate_font(args.font, args.license)
    generated = []
    advances = {}
    for profile in PROFILES:
        atlas, levels, source_advance = rasterize(args.font, profile)
        generated.append((profile, atlas, levels))
        advances[profile.profile_id] = source_advance
    title_atlas, title_levels, title_advance = rasterize_title(args.font)
    rendered = render_include(generated, title_atlas, title_levels, units_per_em)
    encoded = rendered.encode("utf-8")
    if args.write:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(encoded)
    elif not args.output.is_file() or args.output.read_bytes() != encoded:
        raise SystemExit("generated professional atlas is stale")

    print(f"SOURCE_FONT_SHA256={EXPECTED_FONT_SHA256}")
    print(f"LICENSE_SHA256={EXPECTED_LICENSE_SHA256}")
    print(f"SOURCE_UNITS_PER_EM={units_per_em}")
    print(f"RASTERIZER=Pillow_{EXPECTED_PILLOW}_FreeType_{EXPECTED_FREETYPE}_BASIC")
    print("ALPHA_FORMAT=Alpha8")
    print(f"DOWNSAMPLE_METHOD=exact_integer_{SUPERSAMPLE}x{SUPERSAMPLE}_area_average")
    print(f"GLYPH_COUNT={len(CODEPOINTS)}")
    print("REPLACEMENT_SOURCE=source_font_notdef_glyph")
    for profile, atlas, levels in generated:
        print(f"{profile.profile_id}_RASTERIZATION_SOURCE_SIZE={profile.source_font_size}px")
        print(f"{profile.profile_id}_SOURCE_MONOSPACE_ADVANCE={advances[profile.profile_id]}px")
        print(f"{profile.profile_id}_TARGET_PIXEL_SIZE={profile.target_pixel_size}px")
        print(f"{profile.profile_id}_GLYPH_BITMAP={profile.atlas_width}x{profile.atlas_height}")
        print(f"{profile.profile_id}_CELL={profile.atlas_width}x{profile.atlas_height}")
        print(f"{profile.profile_id}_BASELINE={profile.target_baseline}")
        print(f"{profile.profile_id}_LINE_HEIGHT={profile.target_line_height}")
        print(f"{profile.profile_id}_CONTENT_PADDING={TARGET_LEFT_PADDING}x{TARGET_TOP_PADDING}")
        print(f"{profile.profile_id}_COVERAGE_LEVELS={levels}")
        print(f"{profile.profile_id}_ATLAS_SHA256={hashlib.sha256(atlas).hexdigest()}")
        print(
            f"{profile.profile_id}_COVERAGE_CONTRAST="
            f"{profile.contrast_numerator}/{profile.contrast_denominator}"
        )
    print("TITLE_FONT_SOURCE=Source_Code_Pro_Regular")
    print("TITLE_DERIVED_WEIGHT=synthetic_semibold_from_regular")
    print(f"TITLE_SYNTHETIC_EMBOLDEN_X={TITLE_EMBOLDEN_SOURCE_PIXELS}/{SUPERSAMPLE}px")
    print(f"TITLE_SOURCE_MONOSPACE_ADVANCE={title_advance}px")
    print(f"TITLE_GLYPH_BITMAP={TITLE_PROFILE.atlas_width}x{TITLE_PROFILE.atlas_height}")
    print(f"TITLE_COVERAGE_LEVELS={title_levels}")
    print(f"TITLE_ATLAS_SHA256={hashlib.sha256(title_atlas).hexdigest()}")
    print(f"GENERATED_INCLUDE_SHA256={hashlib.sha256(encoded).hexdigest()}")


if __name__ == "__main__":
    main()
