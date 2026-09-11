#!/usr/bin/env python3
"""Syntax-aware bounded migration for Nebo while/for control headers."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import stat
import sys
import tempfile

MAX_SOURCE_BYTES = 1_048_576
KEYWORDS = (b"while", b"for")


class MigrationError(Exception):
    pass


def _word_at(data: bytes, offset: int, word: bytes) -> bool:
    def ident(byte: int) -> bool:
        return byte == 95 or 48 <= byte <= 57 or 65 <= byte <= 90 or 97 <= byte <= 122 or byte >= 128
    return (
        data[offset : offset + len(word)] == word
        and (offset == 0 or not ident(data[offset - 1]))
        and (offset + len(word) == len(data) or not ident(data[offset + len(word)]))
    )


def _skip_quoted(data: bytes, offset: int, quote: int) -> int:
    offset += 1
    while offset < len(data):
        if data[offset] == 92:
            offset += 2
        elif data[offset] == quote:
            return offset + 1
        else:
            offset += 1
    return offset


def _skip_header_trivia(data: bytes, offset: int) -> int:
    """Skip only public whitespace and line-comment trivia."""
    while offset < len(data):
        if data[offset] in b" \t\r\n":
            offset += 1
            continue
        if data[offset : offset + 2] == b"//":
            newline = data.find(b"\n", offset + 2)
            offset = len(data) if newline < 0 else newline + 1
            continue
        return offset
    return offset


def control_header_edits(data: bytes) -> list[tuple[int, bytes]]:
    if len(data) > MAX_SOURCE_BYTES:
        raise MigrationError("source exceeds 1 MiB migration budget")
    edits: list[tuple[int, bytes]] = []
    offset = 0
    while offset < len(data):
        if data[offset] in (34, 39):
            offset = _skip_quoted(data, offset, data[offset])
            continue
        if data[offset : offset + 2] == b"//":
            newline = data.find(b"\n", offset + 2)
            offset = len(data) if newline < 0 else newline + 1
            continue
        keyword = next((word for word in KEYWORDS if _word_at(data, offset, word)), None)
        if keyword is None:
            offset += 1
            continue
        cursor = _skip_header_trivia(data, offset + len(keyword))
        if cursor < len(data) and data[cursor] == 40:
            offset = cursor + 1
            continue
        header_start = cursor
        scan = cursor
        depth = 0
        header_end = cursor
        while scan < len(data):
            if data[scan] in (34, 39):
                scan = _skip_quoted(data, scan, data[scan])
                header_end = scan
                continue
            if data[scan : scan + 2] == b"//":
                newline = data.find(b"\n", scan + 2)
                scan = len(data) if newline < 0 else newline + 1
                continue
            if data[scan] == 40:
                depth += 1
            elif data[scan] == 41 and depth:
                depth -= 1
            elif data[scan] == 123 and depth == 0:
                break
            scan += 1
            if data[scan - 1] not in b" \t\r\n":
                header_end = scan
        if scan >= len(data):
            raise MigrationError(f"unterminated {keyword.decode()} header at byte {offset}")
        if header_end == header_start:
            raise MigrationError(f"empty {keyword.decode()} header at byte {offset}")
        edits.extend(((header_start, b"("), (header_end, b")")))
        offset = scan + 1
    return edits


def canonicalize_control_headers(data: bytes) -> bytes:
    edits = control_header_edits(data)
    result = bytearray(data)
    for offset, insertion in sorted(edits, reverse=True):
        result[offset:offset] = insertion
    return bytes(result)


def _atomic_replace(path: Path, content: bytes, mode: int) -> None:
    descriptor, raw = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".control-migrate.tmp", dir=path.parent)
    temporary = Path(raw)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, stat.S_IMODE(mode))
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def _resolve_paths(raw_paths: list[str]) -> list[Path]:
    resolved: set[Path] = set()
    for raw in raw_paths:
        path = Path(raw).resolve()
        if path.is_dir():
            resolved.update(item for item in path.rglob("*.no") if item.is_file() and not item.is_symlink())
        else:
            resolved.add(path)
    return sorted(resolved)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="nebo-control-header-migrate")
    parser.add_argument("--apply", action="store_true", help="atomically apply exact insertions")
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args(argv)
    changed = 0
    edits_total = 0
    try:
        for path in _resolve_paths(args.paths):
            info = path.lstat()
            if not stat.S_ISREG(info.st_mode) or path.is_symlink():
                raise MigrationError(f"not a regular non-symlink file: {path}")
            original = path.read_bytes()
            migrated = canonicalize_control_headers(original)
            if migrated == original:
                continue
            edits = len(control_header_edits(original))
            changed += 1
            edits_total += edits
            print(f"{path}\t{edits}\t{hashlib.sha256(original).hexdigest()}\t{hashlib.sha256(migrated).hexdigest()}")
            if args.apply:
                _atomic_replace(path, migrated, info.st_mode)
    except (MigrationError, OSError) as exc:
        print(f"nebo-control-header-migrate: {exc}", file=sys.stderr)
        return 2
    print(f"CONTROL_HEADER_MIGRATION paths={changed} edits={edits_total} mode={'apply' if args.apply else 'check'}")
    return 0 if args.apply or changed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
