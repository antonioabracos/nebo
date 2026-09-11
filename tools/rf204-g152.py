#!/usr/bin/python3
"""Bounded offline G152 import editing and public-API inspection host."""

from __future__ import annotations

import hashlib
import json
import os
import re
import stat
import sys
import tempfile
from pathlib import Path

MAX_SOURCE_BYTES = 1 << 20
IDENT = r"[A-Za-z][A-Za-z0-9_]{0,31}"
MODULE = r"[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)*"
SELECTIVE = re.compile(
    rf'(?P<prefix>\b(?:export\s+)?import\s+"(?P<path>{MODULE})"\s*\{{)'
    rf'(?P<body>.*?)(?P<suffix>\}}\s*\.(?P<alias>[a-z][a-z0-9_]*)\s*;)',
    re.DOTALL,
)
MODULE_DECL = re.compile(rf"(?m)^\s*module\s+(?P<name>{MODULE})\s*;")
PUBLIC_EXPORT = re.compile(rf"(?m)^\s*export\s+public\s+(?P<name>{IDENT})\s*=")
ANY_EXPORT = re.compile(
    rf"(?m)^\s*export\s+(?P<visibility>public|internal|private)\s+"
    rf"(?P<name>{IDENT})\s*="
)
ENTRY = re.compile(
    rf"(?P<leading>(?:(?:[ \t\r\n]+)|(?://[^\n]*(?:\n|$)))*)"
    rf"(?P<name>{IDENT})(?P<space>[ \t]*)\s*;"
)


class SourceError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def fail_usage() -> int:
    print(
        "neboc: usage: organize-imports <paths> --check|--apply; "
        "add-import <symbol> --to <module.no>; imports api-impact <module.no>",
        file=sys.stderr,
    )
    return 2


def read_source(path_text: str) -> tuple[Path, bytes, os.stat_result]:
    path = Path(path_text)
    try:
        info = path.lstat()
    except OSError as exc:
        raise SourceError("NEBO-RF166-G152-IO", f"cannot inspect {path}: {exc.strerror}") from exc
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise SourceError("NEBO-RF166-G152-IO", f"source must be a regular non-symlink file: {path}")
    try:
        data = path.read_bytes()
    except OSError as exc:
        raise SourceError("NEBO-RF166-G152-IO", f"cannot read {path}: {exc.strerror}") from exc
    if len(data) > MAX_SOURCE_BYTES:
        raise SourceError("NEBO-RF166-G152-015", f"source exceeds {MAX_SOURCE_BYTES} bytes: {path}")
    try:
        data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise SourceError("NEBO-RF166-G152-001", f"source is not UTF-8: {path}") from exc
    return path, data, info


def parse_entries(body: str) -> tuple[list[tuple[str, str]], str]:
    entries: list[tuple[str, str]] = []
    cursor = 0
    while cursor < len(body):
        match = ENTRY.match(body, cursor)
        if not match:
            if body[cursor:].strip() == "":
                return entries, body[cursor:]
            raise SourceError("NEBO-RF166-G152-001", "invalid selective import member list")
        entries.append((match.group("name"), match.group(0)))
        cursor = match.end()
    if not entries:
        raise SourceError("NEBO-RF166-G152-001", "selective import cannot be empty")
    if len(entries) > 8:
        raise SourceError("NEBO-RF166-G152-015", "selective import exceeds eight members")
    names = [name for name, _ in entries]
    if len(names) != len(set(names)):
        raise SourceError("NEBO-RF166-G152-003", "duplicate selective import member")
    return entries, ""


def organized_text(text: str) -> tuple[str, int]:
    changes = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal changes
        entries, tail = parse_entries(match.group("body"))
        ordered = sorted(entries, key=lambda item: item[0].encode("utf-8"))
        body = "".join(record for _, record in ordered) + tail
        replacement = match.group("prefix") + body + match.group("suffix")
        if replacement != match.group(0):
            changes += 1
        return replacement

    result = SELECTIVE.sub(replace, text)
    if "import" in text and "*" in text:
        raise SourceError("NEBO-RF166-G152-002", "wildcard imports are forbidden")
    return result, changes


def atomic_replace(path: Path, data: bytes, mode: int) -> None:
    descriptor = -1
    temporary = ""
    try:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.g152-", dir=path.parent)
        os.fchmod(descriptor, stat.S_IMODE(mode))
        with os.fdopen(descriptor, "wb", closefd=True) as stream:
            descriptor = -1
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        temporary = ""
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        if temporary:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def emit(payload: dict[str, object]) -> None:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))


def organize(arguments: list[str]) -> int:
    modes = [value for value in arguments if value in ("--check", "--apply")]
    paths = [value for value in arguments if value not in ("--check", "--apply")]
    if len(modes) != 1 or not paths or len(paths) != len(set(paths)):
        return fail_usage()
    prepared: list[tuple[Path, bytes, bytes, os.stat_result, int]] = []
    for value in paths:
        path, before, info = read_source(value)
        after_text, changes = organized_text(before.decode("utf-8"))
        after = after_text.encode("utf-8")
        prepared.append((path, before, after, info, changes))
    total = sum(item[4] for item in prepared)
    if modes[0] == "--apply":
        for path, before, after, info, _ in prepared:
            if before != after:
                atomic_replace(path, after, info.st_mode)
    emit({
        "command": "imports.organize",
        "files": len(prepared),
        "changed": total,
        "mode": modes[0][2:],
        "applied": total if modes[0] == "--apply" else 0,
    })
    return 1 if modes[0] == "--check" and total else 0


def locate_public_symbol(destination: Path, symbol: str) -> tuple[str, Path]:
    matches: list[tuple[str, Path]] = []
    for candidate in sorted(destination.parent.glob("*.no"), key=lambda item: item.name.encode()):
        if candidate == destination or candidate.is_symlink() or not candidate.is_file():
            continue
        _, data, _ = read_source(str(candidate))
        text = data.decode("utf-8")
        module = MODULE_DECL.search(text)
        if module and symbol in (item.group("name") for item in PUBLIC_EXPORT.finditer(text)):
            matches.append((module.group("name"), candidate))
    if len(matches) != 1:
        raise SourceError(
            "NEBO-RF166-G152-005",
            f"auto-import candidate for {symbol} must be unique and public; found {len(matches)}",
        )
    return matches[0]


def add_import(arguments: list[str], expected_revision: str | None = None) -> int:
    if len(arguments) != 3 or arguments[1] != "--to" or not re.fullmatch(IDENT, arguments[0]):
        return fail_usage()
    symbol, destination_text = arguments[0], arguments[2]
    destination, before, info = read_source(destination_text)
    text = before.decode("utf-8")
    declaration = MODULE_DECL.search(text)
    if declaration is None:
        raise SourceError("NEBO-RF166-G152-001", "destination has no canonical module declaration")
    revision = hashlib.sha256(before).hexdigest()
    if expected_revision is not None and revision != expected_revision:
        raise SourceError("NEBO-RF166-G152-011", "auto-import plan is stale")
    for match in SELECTIVE.finditer(text):
        entries, _ = parse_entries(match.group("body"))
        names = [name for name, _ in entries]
        if symbol in names:
            emit({"command": "autoImport.edits", "changed": 0, "revision": revision, "symbol": symbol})
            return 0
    source_module, _ = locate_public_symbol(destination, symbol)
    alias = source_module.rsplit(".", 1)[-1]
    insertion = f'\nimport "{source_module}" {{ {symbol}; }}.{alias};'
    offset = declaration.end()
    after_text = text[:offset] + insertion + text[offset:]
    after = after_text.encode("utf-8")
    # The revision is re-read immediately before publication so a stale plan
    # cannot overwrite concurrent changes.
    _, current, current_info = read_source(destination_text)
    if (hashlib.sha256(current).hexdigest() != revision or
            (current_info.st_dev, current_info.st_ino) != (info.st_dev, info.st_ino)):
        raise SourceError("NEBO-RF166-G152-011", "auto-import plan is stale")
    atomic_replace(destination, after, info.st_mode)
    emit({
        "command": "autoImport.edits",
        "changed": 1,
        "destination": str(destination),
        "module": source_module,
        "revision": revision,
        "symbol": symbol,
    })
    return 0


def api_impact(arguments: list[str]) -> int:
    if len(arguments) not in (1, 3) or (len(arguments) == 3 and arguments[1] != "--baseline"):
        return fail_usage()
    path, data, _ = read_source(arguments[0])
    text = data.decode("utf-8")
    module = MODULE_DECL.search(text)
    if module is None:
        raise SourceError("NEBO-RF166-G152-001", "module declaration is required")
    identities: list[str] = []
    for exported in ANY_EXPORT.finditer(text):
        if exported.group("visibility") == "public":
            identities.append(f'value:{exported.group("name")}')
    for imported in SELECTIVE.finditer(text):
        if not imported.group("prefix").lstrip().startswith("export import"):
            continue
        entries, _ = parse_entries(imported.group("body"))
        for name, _ in entries:
            identities.append(f'reexport:{imported.group("path")}:{name}')
    identities.sort(key=str.encode)
    digest = hashlib.sha256("\n".join(identities).encode("utf-8")).hexdigest()
    baseline = arguments[2] if len(arguments) == 3 else None
    if baseline is not None and not re.fullmatch(r"[0-9a-f]{64}", baseline):
        return fail_usage()
    breaking = baseline is not None and baseline != digest
    emit({
        "command": "imports.publicApiImpact",
        "module": module.group("name"),
        "path": str(path),
        "publicIdentities": identities,
        "digest": digest,
        "breaking": breaking,
    })
    return 1 if breaking else 0


def main(arguments: list[str]) -> int:
    try:
        if not arguments:
            return fail_usage()
        if arguments[0] == "organize-imports":
            return organize(arguments[1:])
        if arguments[0] == "add-import":
            return add_import(arguments[1:])
        if arguments[0] == "_add-import-revision" and len(arguments) == 5:
            return add_import(arguments[1:4], arguments[4])
        if len(arguments) >= 2 and arguments[:2] == ["imports", "api-impact"]:
            return api_impact(arguments[2:])
        return fail_usage()
    except SourceError as exc:
        print(f"{exc.code}: {exc.message}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"NEBO-RF166-G152-IO: {exc}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
