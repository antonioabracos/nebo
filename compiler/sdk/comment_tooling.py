"""G164 bindings for the compiler-owned native comment/trivia projection."""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROBE = ROOT / "build/bin/nebo-comment-scan"
MAX_SOURCE = 1_048_576
MAGIC = 0x343631434F42454E
ERROR_MAGIC = 0x2152524534363147
HEADER = struct.Struct("<8Q")
RECORD = struct.Struct("<6Q")

FLAG_NAMES = {
    1: "multiline",
    2: "docLike",
    4: "bidiControl",
    8: "invisible",
    16: "confusableScript",
    32: "detached",
    64: "trailing",
    128: "leading",
}


class CommentToolError(Exception):
    def __init__(self, status: int, offset: int, message: str = "native comment scan failed"):
        super().__init__(f"{message}: status={status} offset={offset}")
        self.status = status
        self.offset = offset


@dataclass(frozen=True)
class CommentTrivia:
    index: int
    kind: str
    start: int
    end: int
    depth: int
    parent: int | None
    flags: int

    @property
    def flag_names(self) -> tuple[str, ...]:
        return tuple(name for bit, name in FLAG_NAMES.items() if self.flags & bit)

    def public(self) -> dict[str, object]:
        return {
            "index": self.index,
            "classification": "COMMENT",
            "kind": self.kind,
            "start": self.start,
            "end": self.end,
            "depth": self.depth,
            "parent": self.parent,
            "flags": list(self.flag_names),
        }


@dataclass(frozen=True)
class CommentModel:
    source: bytes
    comments: tuple[CommentTrivia, ...]
    max_depth: int
    flags: int
    line_count: int

    @classmethod
    def scan(cls, source: bytes, probe: Path = DEFAULT_PROBE) -> "CommentModel":
        if len(source) > MAX_SOURCE:
            raise CommentToolError(2, MAX_SOURCE, "source exceeds 1 MiB")
        if not probe.is_file():
            raise CommentToolError(1, 0, f"native probe unavailable: {probe}")
        result = subprocess.run(
            [str(probe)], input=source, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=10,
        )
        if len(result.stdout) == 24:
            marker, status, offset = struct.unpack("<3Q", result.stdout)
            if marker == ERROR_MAGIC:
                raise CommentToolError(status, offset)
        if result.returncode != 0:
            raise CommentToolError(result.returncode, 0, "native probe process failed")
        if len(result.stdout) < HEADER.size:
            raise CommentToolError(1, 0, "native projection is truncated")
        magic, schema, source_len, count, max_depth, flags, line_count, output_bytes = HEADER.unpack_from(result.stdout)
        if magic != MAGIC or schema != 1 or source_len != len(source):
            raise CommentToolError(1, 0, "native projection header mismatch")
        expected = HEADER.size + count * RECORD.size
        if output_bytes != expected or len(result.stdout) != expected or count > 4096:
            raise CommentToolError(1, 0, "native projection size mismatch")
        records: list[CommentTrivia] = []
        for index in range(count):
            kind, start, end, depth, parent_plus_one, item_flags = RECORD.unpack_from(
                result.stdout, HEADER.size + index * RECORD.size
            )
            parent = None if parent_plus_one == 0 else parent_plus_one - 1
            if kind not in (1, 2) or not (0 <= start < end <= len(source)):
                raise CommentToolError(1, start, "native projection record mismatch")
            if parent is not None and not (0 <= parent < index):
                raise CommentToolError(1, start, "native projection hierarchy mismatch")
            records.append(CommentTrivia(
                index=index, kind="line" if kind == 1 else "block",
                start=start, end=end, depth=depth, parent=parent, flags=item_flags,
            ))
        return cls(source, tuple(records), max_depth, flags, line_count)

    @property
    def outer_comments(self) -> tuple[CommentTrivia, ...]:
        return tuple(item for item in self.comments if item.parent is None)

    def contains(self, byte_offset: int) -> CommentTrivia | None:
        matches = [item for item in self.comments if item.start <= byte_offset < item.end]
        return max(matches, key=lambda item: item.depth) if matches else None

    def semantic_projection(self) -> bytes:
        """Remove outer comments and insignificant ASCII whitespace."""
        chunks: list[bytes] = []
        cursor = 0
        for item in self.outer_comments:
            chunks.append(self.source[cursor:item.start])
            cursor = item.end
        chunks.append(self.source[cursor:])
        return b"".join(chunks).translate(None, b" \t\r\n")

    def public(self) -> dict[str, object]:
        return {
            "schema": 1,
            "owner": "neboc_comment_scan",
            "sourceBytes": len(self.source),
            "sourceSha256": hashlib.sha256(self.source).hexdigest(),
            "semanticTriviaProjectionSha256": hashlib.sha256(self.semantic_projection()).hexdigest(),
            "commentCount": len(self.comments),
            "maxNesting": self.max_depth,
            "lineCount": self.line_count,
            "comments": [item.public() for item in self.comments],
        }
