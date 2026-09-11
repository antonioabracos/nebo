#!/usr/bin/env python3
"""Offline RF27 canonical formatter using neboc as the syntax authority."""
from __future__ import annotations

import argparse
import difflib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compiler.sdk.comment_tooling import CommentModel, CommentToolError
from compiler.sdk.token_tooling import TokenModel, TokenToolError, normalize_trivia
from nebo_control_header_migrate import canonicalize_control_headers

MAX_SOURCE = 1_048_576
SYMBOL_STYLES = ("preserve", "ascii", "math")


class FormatError(Exception):
    pass


def parse_range(text: str | None, size: int) -> tuple[int, int] | None:
    if text is None:
        return None
    try:
        left, right = text.split(":", 1)
        start, end = int(left), int(right)
    except (ValueError, TypeError) as exc:
        raise FormatError("range must be START:END byte offsets") from exc
    if not (0 <= start <= end <= size):
        raise FormatError("range is outside the source")
    return start, end


def canonicalize_region(
    data: bytes, start: int, end: int, whole: bool,
    protected: tuple[tuple[int, int], ...] = (),
) -> bytes:
    return normalize_trivia(data, start, end, whole, protected)


def canonicalize(data: bytes, selected: tuple[int, int] | None = None) -> bytes:
    if len(data) > MAX_SOURCE:
        raise FormatError("source exceeds 1 MiB formatter budget")
    model = CommentModel.scan(data)
    tokens = TokenModel.scan(data)
    protected = tuple(sorted((*((item.start, item.end) for item in model.outer_comments), *tokens.literal_ranges)))
    if selected is None:
        # Control-header migration predates trivia spans. Until it consumes the
        # canonical projection itself, do not expose comment bytes to it.
        migrated = data if protected else canonicalize_control_headers(data)
        return canonicalize_region(migrated, 0, len(migrated), True, protected)
    return canonicalize_region(data, selected[0], selected[1], False, protected)


def comment_payloads(model: CommentModel) -> tuple[bytes, ...]:
    return tuple(model.source[item.start:item.end] for item in model.outer_comments)


def compiler_accepts(compiler: Path, path: Path) -> bool:
    result = subprocess.run(
        [str(compiler), "check", str(path)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=15,
    )
    if result.returncode == 0:
        return True
    return doc_ast(compiler, path) is not None


def doc_ast(compiler: Path, path: Path) -> dict[str, object] | None:
    """Read the canonical G155 AST; this formatter never reparses doc syntax."""
    result = subprocess.run(
        [str(compiler), "dump", "doc-ast", str(path)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=15,
    )
    if result.returncode != 0:
        return None
    try:
        value = json.loads(result.stdout)
    except (TypeError, ValueError):
        return None
    return value if isinstance(value, dict) and value.get("node") == "DocBlockAst" else None


def doc_semantic_projection(value: dict[str, object]) -> tuple[object, ...]:
    attachment = value.get("attachment")
    if not isinstance(attachment, dict):
        raise FormatError("canonical DocBlockAst omitted attachment")
    embedded = value.get("embeddedCode")
    if not isinstance(embedded, list):
        raise FormatError("canonical DocBlockAst omitted embedded code")
    return (
        value.get("astDigest"),
        tuple(value.get("fields", [])),
        value.get("fieldMask"),
        value.get("fieldCount"),
        value.get("examples"),
        value.get("laws"),
        attachment.get("kind"),
        attachment.get("name"),
        attachment.get("symbolId"),
        tuple((item.get("kind"), item.get("compilerAdmission")) for item in embedded if isinstance(item, dict)),
    )


def validate_bytes(compiler: Path, source_path: Path, content: bytes) -> bool:
    handle, raw = tempfile.mkstemp(
        prefix=f".{source_path.stem}.rf27-format-", suffix=".no", dir=source_path.parent
    )
    temp = Path(raw)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        return compiler_accepts(compiler, temp)
    finally:
        temp.unlink(missing_ok=True)


def symbol_profile(helper: Path, content: bytes, profile: str) -> bytes:
    if profile == "preserve":
        return content
    try:
        result = subprocess.run(
            [str(helper), profile],
            input=content,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=15,
        )
    except subprocess.TimeoutExpired as exc:
        raise FormatError("symbol formatter exceeded its execution budget") from exc
    if result.returncode != 0:
        raise FormatError(
            f"symbol formatter rejected source (status {result.returncode})"
        )
    if len(result.stdout) > MAX_SOURCE:
        raise FormatError("symbol formatter output exceeds 1 MiB budget")
    return result.stdout


def emitted_assembly(compiler: Path, source: Path, output: Path) -> bytes:
    result = subprocess.run(
        [str(compiler), "emit-asm", str(source), "-o", str(output)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=15,
    )
    if result.returncode != 0 or not output.is_file():
        raise FormatError(f"compiler could not prove source semantics: {source}")
    return output.read_bytes()


def semantic_identity(compiler: Path, source_path: Path, content: bytes) -> bool:
    handle, raw = tempfile.mkstemp(
        prefix=f".{source_path.stem}.rf127-semantic-", suffix=".no", dir=source_path.parent
    )
    candidate = Path(raw)
    try:
        with tempfile.TemporaryDirectory(prefix="nebo-rf127-semantic-") as raw_dir:
            scratch = Path(raw_dir)
            with os.fdopen(handle, "wb") as stream:
                stream.write(content)
                stream.flush()
                os.fsync(stream.fileno())
            before_doc = doc_ast(compiler, source_path)
            after_doc = doc_ast(compiler, candidate)
            if before_doc is not None or after_doc is not None:
                return (
                    before_doc is not None
                    and after_doc is not None
                    and doc_semantic_projection(before_doc) == doc_semantic_projection(after_doc)
                )
            before = emitted_assembly(compiler, source_path, scratch / "before.asm")
            after = emitted_assembly(compiler, candidate, scratch / "after.asm")
            return before == after
    finally:
        try:
            os.close(handle)
        except OSError:
            pass
        candidate.unlink(missing_ok=True)


def atomic_replace(path: Path, content: bytes, mode: int) -> None:
    handle, raw = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".rf27-format.tmp", dir=path.parent)
    temp = Path(raw)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp, stat.S_IMODE(mode))
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def token_projection(content: bytes) -> tuple[tuple[int, bytes], ...]:
    """Compare native lexical atoms without erasing whitespace inside literals."""
    model = TokenModel.scan(content)
    return tuple((token.kind, content[token.start:token.end]) for token in model.tokens)


def format_path(
    path: Path,
    compiler: Path,
    helper: Path,
    write: bool,
    range_text: str | None,
    symbol_style: str,
) -> tuple[bool, bytes, bytes]:
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or path.is_symlink():
        raise FormatError(f"not a regular non-symlink file: {path}")
    original = path.read_bytes()
    original_comments = CommentModel.scan(original)
    selected = parse_range(range_text, len(original))
    formatted = canonicalize(original, selected)
    formatted = symbol_profile(helper, formatted, symbol_style)
    formatted_comments = CommentModel.scan(formatted)
    if comment_payloads(original_comments) != comment_payloads(formatted_comments):
        raise FormatError("formatter changed preserved comment bytes")
    # The native filter canonicalizes only the registered alias token spans;
    # it copies intervening trivia and literal bytes exactly. Comparing source
    # bytes with whitespace erased used to reject every actual alias rewrite.
    before_projection = original
    after_projection = formatted
    if symbol_style != "preserve":
        before_projection = symbol_profile(helper, original, "ascii")
        after_projection = symbol_profile(helper, formatted, "ascii")
    if token_projection(before_projection) != token_projection(after_projection):
        raise FormatError("formatter changed the native token projection")
    if formatted == original:
        if not compiler_accepts(compiler, path):
            raise FormatError(f"compiler rejected source: {path}")
        return False, original, formatted
    if not validate_bytes(compiler, path, formatted):
        raise FormatError(f"compiler rejected formatted source: {path}")
    if not semantic_identity(compiler, path, formatted):
        raise FormatError(f"formatted source changed observable semantics: {path}")
    if write:
        current = path.lstat()
        identity = (info.st_dev, info.st_ino, info.st_mode, info.st_size, info.st_mtime_ns)
        current_identity = (
            current.st_dev,
            current.st_ino,
            current.st_mode,
            current.st_size,
            current.st_mtime_ns,
        )
        if current_identity != identity or path.read_bytes() != original:
            raise FormatError(f"source changed during formatting: {path}")
        atomic_replace(path, formatted, info.st_mode)
    return True, original, formatted


def main(argv: list[str] | None = None) -> int:
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(prog="neboc format")
    parser.add_argument("paths", nargs="+")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--check", action="store_true", help="report changes without writing")
    modes.add_argument("--diff", action="store_true", help="preview a unified diff without writing")
    modes.add_argument("--stdout", action="store_true", help="write formatted source to stdout")
    modes.add_argument("--write", action="store_true", help="atomically replace the source")
    parser.add_argument("--range", dest="range_text", help="format a complete-line START:END byte range")
    parser.add_argument(
        "--symbol-style",
        choices=SYMBOL_STYLES,
        default="preserve",
        help="preserve source symbols (default), or use exact ASCII/math operator aliases",
    )
    parser.add_argument(
        "--preserve-comments", action="store_true", default=True,
        help="preserve canonical line and nested block-comment bytes (default)",
    )
    parser.add_argument("--compiler", default=str(repo / "build/bin/neboc"))
    args = parser.parse_args(argv)
    if args.range_text and len(args.paths) != 1:
        parser.error("--range accepts exactly one path")
    if args.stdout and len(args.paths) != 1:
        parser.error("--stdout accepts exactly one path")
    if args.range_text and args.symbol_style != "preserve":
        parser.error("--range cannot be combined with a symbol rewrite profile")
    compiler = Path(args.compiler).resolve()
    helper = repo / "build/bin/nebo-symbol-format"
    if not compiler.is_file():
        print(f"neboc format: compiler not found: {compiler}", file=sys.stderr)
        return 2
    if args.symbol_style != "preserve" and not helper.is_file():
        print(f"neboc format: symbol formatter not found: {helper}", file=sys.stderr)
        return 2
    changed = False
    try:
        for raw_path in args.paths:
            # Keep the final path component unresolved so format_path can
            # reject symlinks before a read or transactional replacement.
            path = Path(raw_path).absolute()
            item_changed, original, formatted = format_path(
                path,
                compiler,
                helper,
                args.write or not (args.check or args.diff or args.stdout),
                args.range_text,
                args.symbol_style,
            )
            changed |= item_changed
            if args.diff and item_changed:
                sys.stdout.write("".join(difflib.unified_diff(
                    original.decode("utf-8").splitlines(keepends=True),
                    formatted.decode("utf-8").splitlines(keepends=True),
                    fromfile=str(path), tofile=str(path),
                )))
            if args.stdout:
                sys.stdout.buffer.write(formatted)
    except (FormatError, TokenToolError, CommentToolError, OSError, subprocess.TimeoutExpired) as exc:
        print(f"neboc format: {exc}", file=sys.stderr)
        return 2
    return 1 if args.check and changed else 0


if __name__ == "__main__":
    raise SystemExit(main())
