"""Read-only tooling projection of the canonical native lexer tokens."""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROBE = ROOT / 'build/bin/nebo-token-scan'
MAX_SOURCE = 1_048_576
MAX_TOKENS = 32768
HEADER = struct.Struct('<8Q')
TOKEN = struct.Struct('<6Q')
MAGIC = 0x314e4b544f42454e
LITERAL_KINDS = frozenset((4, 6, 192, 195, 196))


class TokenToolError(ValueError):
    pass


@dataclass(frozen=True)
class SourceToken:
    kind: int
    flags: int
    start: int
    end: int
    payload: int


@dataclass(frozen=True)
class TokenModel:
    source: bytes
    tokens: tuple[SourceToken, ...]
    status: int
    errors: int

    @classmethod
    def scan(cls, source: bytes, probe: Path = DEFAULT_PROBE) -> 'TokenModel':
        if len(source) > MAX_SOURCE:
            raise TokenToolError('native source token budget exceeded')
        source.decode('utf-8', 'strict')
        result = subprocess.run([str(probe)], input=source, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=10, check=False)
        if result.returncode or result.stderr or len(result.stdout) < HEADER.size:
            raise TokenToolError('native token transport failed')
        magic, schema, length, count, status, errors, literals, size = HEADER.unpack_from(result.stdout)
        if (magic != MAGIC or schema != 1 or length != len(source) or count > MAX_TOKENS
                or literals > MAX_SOURCE or size != HEADER.size + TOKEN.size * count + literals
                or len(result.stdout) != size or errors > count):
            raise TokenToolError('native token header mismatch')
        rows = []
        previous = 0
        for index in range(count):
            kind, flags, source_id, start, end, payload = TOKEN.unpack_from(result.stdout, HEADER.size + index * TOKEN.size)
            if source_id != 1 or not previous <= start <= end <= len(source):
                raise TokenToolError('native token source span mismatch')
            source[previous:start].decode('utf-8', 'strict')
            source[start:end].decode('utf-8', 'strict')
            if flags & 16 and (payload >> 32) + (payload & 0xffffffff) > literals:
                raise TokenToolError('native literal span mismatch')
            previous = end
            rows.append(SourceToken(kind, flags, start, end, payload))
        return cls(source, tuple(rows), status, errors)

    @property
    def literal_ranges(self) -> tuple[tuple[int, int], ...]:
        return tuple((t.start, t.end) for t in self.tokens if t.kind in LITERAL_KINDS)

    def code_mask(self) -> str:
        # Token gaps are trivia; only committed ordinary tokens remain visible.
        masked = bytearray(10 if byte == 10 else 13 if byte == 13 else 32 for byte in self.source)
        for token in self.tokens:
            if token.kind not in LITERAL_KINDS and token.kind != 1:
                masked[token.start:token.end] = self.source[token.start:token.end]
        # Preserve Python character offsets too, including non-ASCII literals.
        text = self.source.decode('utf-8')
        result = []
        offset = 0
        for char in text:
            size = len(char.encode('utf-8'))
            result.append(char if masked[offset:offset+size] == self.source[offset:offset+size] else ' ')
            offset += size
        return ''.join(result)

    def interpolation_tokens(self) -> list[dict[str, int | str]]:
        """Classify live tokens; brace/argument depth separates profile colons.

        Nesting and escape ownership comes exclusively from lexer token kinds.
        This projection does not parse an expression or resolve an identifier.
        """
        rows = []
        frames = []
        for token in self.tokens:
            kind = token.kind
            category = None
            if kind == 193:
                frames.append([0, False])
                category = 'delimiter'
            elif kind == 194:
                if not frames: raise TokenToolError('unowned interpolation delimiter')
                frames.pop()
                category = 'delimiter'
            elif kind in LITERAL_KINDS:
                category = 'literal'
            elif frames:
                frame = frames[-1]
                if kind in (50, 52, 83): frame[0] += 1
                elif kind in (51, 53, 84): frame[0] -= 1
                elif kind == 81 and frame[0] == 0: frame[1] = True
                category = 'profile' if frame[1] else 'expression'
            if category is not None and token.end > token.start:
                rows.append(dict(kind=category, start=token.start, end=token.end, tokenKind=kind))
        return rows

    def character_fragments(self) -> list[dict[str, int | str]]:
        rows = self.interpolation_tokens()
        requested = {int(row[side]) for row in rows for side in ('start','end')}
        offsets = {}
        byte = 0
        for index,char in enumerate(self.source.decode('utf-8')):
            if byte in requested: offsets[byte] = index
            byte += len(char.encode('utf-8'))
        if byte in requested: offsets[byte] = len(self.source.decode('utf-8'))
        return [{**row,'start':offsets[int(row['start'])],'end':offsets[int(row['end'])]} for row in rows]


def normalize_trivia(
    data: bytes, start: int, end: int, whole: bool,
    protected: tuple[tuple[int, int], ...] | None = None,
    *, trim_trailing: bool = True, final_newline: bool = True,
) -> bytes:
    """Normalize only native trivia gaps, preserving literal/comment payloads."""
    if protected is None:
        from .comment_tooling import CommentModel
        comments = CommentModel.scan(data)
        tokens = TokenModel.scan(data)
        protected = tuple(sorted((*((c.start, c.end) for c in comments.outer_comments), *tokens.literal_ranges)))
    if start and data[start - 1] != 0x0A:
        raise TokenToolError("range start is not a line boundary")
    if end != len(data) and end and data[end - 1] != 0x0A:
        raise TokenToolError("range end is not a line boundary")
    out = bytearray(data[:start])
    i = start
    protected_index = 0
    while i < end:
        while protected_index < len(protected) and protected[protected_index][1] <= i:
            protected_index += 1
        if protected_index < len(protected):
            protected_start, protected_end = protected[protected_index]
            if protected_start <= i < protected_end:
                copied_end = min(protected_end, end)
                out.extend(data[i:copied_end])
                i = copied_end
                continue
        byte = data[i]
        if byte == 0x0D and i + 1 < end and data[i + 1] == 0x0A:
            out.append(0x0A)
            i += 2
            continue
        if trim_trailing and byte in (0x09, 0x20):
            j = i
            while j < end and data[j] in (0x09, 0x20):
                j += 1
            newline = j < end and (
                data[j] == 0x0A
                or (data[j] == 0x0D and j + 1 < end and data[j + 1] == 0x0A)
            )
            if newline or (whole and end == len(data) and j == end):
                i = j
                continue
        out.append(byte)
        i += 1
    out.extend(data[end:])
    if whole and final_newline and (not out or out[-1] != 0x0A):
        out.append(0x0A)
    return bytes(out)
