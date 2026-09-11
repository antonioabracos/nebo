#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import random
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CANVAS_ORACLE = ROOT / "tests/rf27-g18/f06/raster_oracle.py"
spec = importlib.util.spec_from_file_location("rf27_f06_canvas_oracle", CANVAS_ORACLE)
if spec is None or spec.loader is None:
    raise RuntimeError("unable to load F06 oracle")
canvas_module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = canvas_module
spec.loader.exec_module(canvas_module)
CanvasBase = canvas_module.Canvas

MAX_SERIES = 32
MAX_POINTS = 4096
MAX_BINS = 64
MAX_TICKS = 8
MAX_LEGEND = 8
MIN_WIDTH = 160
MIN_HEIGHT = 120
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211

KIND_LINE = 1
KIND_SCATTER = 2
KIND_BAR = 3
KIND_HISTOGRAM = 4

CMD_CLEAR = 1
CMD_LINE = 2
CMD_RECTANGLE = 3
CMD_CIRCLE = 4
CMD_TEXT = 5
FLAG_ACCEPTED = 1
FLAG_CLIPPED = 2
FLAG_STROKE = 4
FLAG_FILL = 8
MODE_STROKE = 1
MODE_FILL = 2


def fnv1a64(data: bytes) -> int:
    value = FNV_OFFSET
    for byte in data:
        value ^= byte
        value = (value * FNV_PRIME) & ((1 << 64) - 1)
    return value


class TraceCanvas(CanvasBase):
    def __post_init__(self) -> None:
        super().__post_init__()
        self.trace: list[bytes] = []

    def _record(
        self,
        kind: int,
        flags: int,
        x0: int = 0,
        y0: int = 0,
        x1: int = 0,
        y1: int = 0,
        arg0: int = 0,
        color: int = 0,
        aux: int = 0,
    ) -> None:
        sequence = len(self.trace) + 1
        self.trace.append(
            struct.pack(
                "<IIQqqqqQII",
                kind,
                flags,
                sequence,
                x0,
                y0,
                x1,
                y1,
                arg0 & ((1 << 64) - 1),
                color & 0xFFFFFFFF,
                aux & 0xFFFFFFFF,
            )
        )

    def clear(self, color: int) -> None:
        super().clear(color)
        self._record(CMD_CLEAR, FLAG_ACCEPTED | FLAG_FILL, color=color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color: int) -> None:
        before = self.commands
        super().line(x0, y0, x1, y1, color)
        if self.commands != before:
            self._record(
                CMD_LINE,
                FLAG_ACCEPTED | FLAG_CLIPPED | FLAG_STROKE,
                x0,
                y0,
                x1,
                y1,
                color=color,
            )

    def rectangle(self, x: int, y: int, w: int, h: int, color: int, fill: bool) -> None:
        before = self.commands
        super().rectangle(x, y, w, h, color, fill)
        if self.commands != before:
            self._record(
                CMD_RECTANGLE,
                FLAG_ACCEPTED | FLAG_CLIPPED | (FLAG_FILL if fill else FLAG_STROKE),
                x,
                y,
                w,
                h,
                color=color,
                aux=MODE_FILL if fill else MODE_STROKE,
            )

    def circle(self, cx: int, cy: int, radius: int, color: int, fill: bool) -> None:
        before = self.commands
        super().circle(cx, cy, radius, color, fill)
        if self.commands != before:
            self._record(
                CMD_CIRCLE,
                FLAG_ACCEPTED | FLAG_CLIPPED | (FLAG_FILL if fill else FLAG_STROKE),
                cx,
                cy,
                arg0=radius,
                color=color,
                aux=MODE_FILL if fill else MODE_STROKE,
            )

    def text(self, text: str, x: int, y: int, color: int) -> None:
        before = self.commands
        data = text.encode("utf-8")
        super().text(text, x, y, color)
        if self.commands != before:
            self._record(
                CMD_TEXT,
                FLAG_ACCEPTED | FLAG_CLIPPED | FLAG_FILL,
                x,
                y,
                arg0=fnv1a64(data),
                color=color,
                aux=len(data),
            )


@dataclass(frozen=True)
class Series:
    kind: int
    x: tuple[float, ...]
    y: tuple[float, ...]
    color: int
    label: str
    radius: int = 0
    show_points: bool = False
    categories: tuple[str, ...] = ()
    bins: int = 0


def map_value(value: float, low: float, high: float, start: int, span: int) -> int:
    if low == high:
        return start + span // 2
    scale = max(abs(value), abs(low), abs(high))
    if scale == 0.0:
        return start + span // 2
    normalized = ((value / scale) - (low / scale)) / ((high / scale) - (low / scale))
    normalized = min(1.0, max(0.0, normalized))
    return start + int(normalized * span + 0.5)


def value_to_bin(value: float, low: float, high: float, bins: int) -> int:
    if low == high:
        return 0
    scale = max(abs(value), abs(low), abs(high))
    if scale == 0.0:
        return 0
    normalized = ((value / scale) - (low / scale)) / ((high / scale) - (low / scale))
    normalized = min(1.0, max(0.0, normalized))
    index = int(normalized * bins)
    return min(index, bins - 1)


def validate_series(series: Series) -> None:
    count = len(series.y)
    if not 1 <= count <= MAX_POINTS:
        raise ValueError("empty or excessive series")
    if series.kind == KIND_LINE and count < 2:
        raise ValueError("line requires two points")
    if series.kind in {KIND_LINE, KIND_SCATTER} and len(series.x) != count:
        raise ValueError("x/y count")
    if series.kind in {KIND_BAR, KIND_HISTOGRAM} and series.x:
        raise ValueError("auto-x required")
    if any(not math.isfinite(value) for value in series.x + series.y):
        raise ValueError("nonfinite")
    if not 1 <= len(series.label.encode("utf-8")) <= 64:
        raise ValueError("label")
    if series.kind == KIND_BAR:
        if len(series.categories) != count:
            raise ValueError("categories")
        if any(not 1 <= len(item.encode("utf-8")) <= 64 for item in series.categories):
            raise ValueError("category")
    elif series.categories:
        raise ValueError("unexpected categories")
    if series.kind == KIND_HISTOGRAM:
        if not 1 <= series.bins <= MAX_BINS:
            raise ValueError("bins")
    elif series.bins:
        raise ValueError("unexpected bins")


def golden_series() -> list[Series]:
    return [
        Series(KIND_LINE, (0.0, 1.0, 2.0, 3.0, 4.0), (1.0, 4.0, 2.0, 5.0, 3.0), 0xFF5060FF, "LINE", 2, True),
        Series(KIND_SCATTER, (0.5, 1.5, 2.5, 3.5), (2.0, 3.0, 1.0, 4.0), 0x50FF80FF, "SCATTER", 2),
        Series(KIND_BAR, (), (2.0, 1.0, 3.0, 2.0), 0x5080FFFF, "BAR", categories=("A", "B", "C", "D")),
        Series(KIND_HISTOGRAM, (), (-1.0, -0.5, 0.0, 0.5, 1.0, 1.5), 0xFFC050FF, "HIST", bins=4),
    ]


def render_golden() -> TraceCanvas:
    series = golden_series()
    for item in series:
        validate_series(item)
    c = TraceCanvas(160, 120)
    background = 0x101820FF
    plot = 0x182430FF
    axis = 0xC0D0E0FF
    grid = 0x405060FF
    text = 0xFFFFFFFF
    legend_color = 0x202830FF
    x_ticks = y_ticks = 5
    left, top = 28, 18
    plot_w = 160 - 40 - 52
    plot_h = 120 - 38

    xs: list[float] = []
    ys: list[float] = []
    for item in series:
        if item.kind in {KIND_LINE, KIND_SCATTER}:
            xs.extend(item.x)
            ys.extend(item.y)
        elif item.kind == KIND_BAR:
            xs.extend((-0.5, len(item.y) - 0.5))
            ys.append(0.0)
            ys.extend(item.y)
        else:
            xs.extend(item.y)
            ys.extend((0.0, float(len(item.y))))
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)

    c.clear(background)
    c.rectangle(left, top, plot_w, plot_h, plot, True)
    for index in range(x_ticks):
        x = left + ((plot_w - 1) * index) // (x_ticks - 1)
        c.line(x, top, x, top + plot_h - 1, grid)
        c.line(x, top + plot_h - 1, x, top + plot_h + 2, axis)
    for index in range(y_ticks):
        y = top + plot_h - 1 - ((plot_h - 1) * index) // (y_ticks - 1)
        c.line(left, y, left + plot_w - 1, y, grid)
        c.line(left - 3, y, left, y, axis)
    c.line(left, top + plot_h - 1, left + plot_w - 1, top + plot_h - 1, axis)
    c.line(left, top, left, top + plot_h - 1, axis)
    c.text("NEBO CHARTS", left, 4, text)
    c.text("X", left, 112, text)
    c.text("Y", 2, top, text)

    for item in series:
        if item.kind == KIND_LINE:
            previous: tuple[int, int] | None = None
            for xv, yv in zip(item.x, item.y, strict=True):
                px = map_value(xv, xmin, xmax, left, plot_w - 1)
                py = top + plot_h - 1 - map_value(yv, ymin, ymax, 0, plot_h - 1)
                if previous is not None:
                    c.line(previous[0], previous[1], px, py, item.color)
                if item.show_points:
                    c.circle(px, py, item.radius, item.color, True)
                previous = (px, py)
        elif item.kind == KIND_SCATTER:
            for xv, yv in zip(item.x, item.y, strict=True):
                px = map_value(xv, xmin, xmax, left, plot_w - 1)
                py = top + plot_h - 1 - map_value(yv, ymin, ymax, 0, plot_h - 1)
                c.circle(px, py, item.radius, item.color, True)
        elif item.kind == KIND_BAR:
            zero = top + plot_h - 1 - map_value(0.0, ymin, ymax, 0, plot_h - 1)
            count = len(item.y)
            for index, value in enumerate(item.y):
                x0 = left + (plot_w * index) // count
                x1 = left + (plot_w * (index + 1)) // count
                width = max(1, x1 - x0 - 1)
                value_y = top + plot_h - 1 - map_value(value, ymin, ymax, 0, plot_h - 1)
                y0, y1 = sorted((zero, value_y))
                c.rectangle(x0, y0, width, y1 - y0 + 1, item.color, True)
            label_count = min(count, x_ticks)
            for ordinal in range(label_count):
                index = 0 if label_count == 1 else ((count - 1) * ordinal) // (label_count - 1)
                x = left + (plot_w * index) // count
                c.text(item.categories[index], x, top + plot_h + 4, text)
        else:
            low, high = min(item.y), max(item.y)
            counts = [0] * item.bins
            for value in item.y:
                counts[value_to_bin(value, low, high, item.bins)] += 1
            for index, count in enumerate(counts):
                x0 = left + (plot_w * index) // item.bins
                x1 = left + (plot_w * (index + 1)) // item.bins
                width = max(1, x1 - x0 - 1)
                y = top + plot_h - 1 - map_value(float(count), ymin, ymax, 0, plot_h - 1)
                c.rectangle(x0, y, width, top + plot_h - y, item.color, True)

    legend_x = 100
    c.rectangle(legend_x, 8, 56, len(series) * 9 + 4, legend_color, True)
    for index, item in enumerate(series):
        c.rectangle(legend_x + 3, index * 9 + 11, 6, 6, item.color, True)
        c.text(item.label, legend_x + 12, index * 9 + 10, text)

    if len(c.trace) != 61 or c.commands != 61:
        raise AssertionError((len(c.trace), c.commands))
    return c


def golden_bytes() -> tuple[bytes, bytes]:
    canvas = render_golden()
    return b"".join(canvas.trace), bytes(canvas.pixels)


def property_model(seed: int, cases: int) -> dict[str, object]:
    rng = random.Random(seed)
    digest = hashlib.sha256()
    counters = {
        "cases": cases,
        "line": 0,
        "scatter": 0,
        "bar": 0,
        "histogram": 0,
        "rejected_nonfinite": 0,
        "rejected_empty": 0,
        "rejected_excess": 0,
        "constant_range": 0,
    }
    for index in range(cases):
        kind = 1 + rng.randrange(4)
        count = rng.randint(1 if kind != KIND_LINE else 2, 64)
        if index % 19 == 0:
            values = [math.nan]
            counters["rejected_nonfinite"] += 1
            outcome = "nonfinite"
        elif index % 23 == 0:
            values = []
            counters["rejected_empty"] += 1
            outcome = "empty"
        elif index % 29 == 0:
            values = [0.0] * (MAX_POINTS + 1)
            counters["rejected_excess"] += 1
            outcome = "excess"
        else:
            base = rng.uniform(-1.0e280, 1.0e280)
            spread = 0.0 if index % 17 == 0 else rng.uniform(1.0, 1.0e270)
            values = [base + spread * rng.uniform(-1.0, 1.0) for _ in range(count)]
            if spread == 0.0:
                counters["constant_range"] += 1
            outcome = "accepted"
            counters[{1: "line", 2: "scatter", 3: "bar", 4: "histogram"}[kind]] += 1
            finite = [v for v in values if math.isfinite(v)]
            if finite:
                low, high = min(finite), max(finite)
                coordinates = [map_value(v, low, high, 28, 511) for v in finite]
                assert all(28 <= value <= 539 for value in coordinates)
                if kind == KIND_HISTOGRAM:
                    bins = 1 + rng.randrange(MAX_BINS)
                    indices = [value_to_bin(v, low, high, bins) for v in finite]
                    assert all(0 <= value < bins for value in indices)
        record = {
            "i": index,
            "kind": kind,
            "count": len(values),
            "outcome": outcome,
            "first": None if not values else repr(values[0]),
            "last": None if not values else repr(values[-1]),
        }
        digest.update(json.dumps(record, sort_keys=True, separators=(",", ":")).encode())
        digest.update(b"\n")
    return {"seed": seed, "cases": cases, "counters": counters, "sha256": digest.hexdigest()}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--golden-command", action="store_true")
    parser.add_argument("--golden-pixels", action="store_true")
    parser.add_argument("--properties", action="store_true")
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x271808)
    parser.add_argument("--cases", type=int, default=5000)
    args = parser.parse_args()
    commands, pixels = golden_bytes()
    if args.golden_command:
        sys.stdout.buffer.write(commands)
        return 0
    if args.golden_pixels:
        sys.stdout.buffer.write(pixels)
        return 0
    if args.properties:
        result = property_model(args.seed, args.cases)
        c = result["counters"]
        print(
            "RF27_G18_F08_CHART_MODEL=PASS "
            f"seed=0x{args.seed:x} cases={args.cases} digest={result['sha256']} "
            f"line={c['line']} scatter={c['scatter']} bar={c['bar']} histogram={c['histogram']} "
            f"rejected_nonfinite={c['rejected_nonfinite']} rejected_empty={c['rejected_empty']} "
            f"rejected_excess={c['rejected_excess']} constant_range={c['constant_range']}"
        )
        print(json.dumps(result, sort_keys=True))
        return 0
    if len(commands) != 3904 or len(pixels) != 76800:
        raise AssertionError((len(commands), len(pixels)))
    if hashlib.sha256(commands).hexdigest() != "603accc15fd120abfc256aa627dcab5fd872413b377b538eeb7c4b20a1c24771":
        raise AssertionError("command golden")
    if hashlib.sha256(pixels).hexdigest() != "acbcf3a340b3c2aaa6ffa835ad66a90a888f0d32315255b8136f0974e38ddbd6":
        raise AssertionError("pixel golden")
    print("RF27_G18_F08_ORACLE_SELFTEST=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
