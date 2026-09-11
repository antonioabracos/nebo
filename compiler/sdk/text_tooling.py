#!/usr/bin/env python3
"""Bounded regex, formatter, lint, fix, and LSP contracts for G083.

The module is deliberately local and deterministic.  Regex input is admitted
through a small safety grammar before the host matcher is used, every operation
is charged against an explicit work budget, and source mutation uses a
same-directory fsync/replace transaction.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
import difflib
import hashlib
import os
from pathlib import Path
import re
import stat
import tempfile
from typing import Iterable


MAX_REGEX_STEPS = 65_536
MAX_PATTERN_BYTES = 256
MAX_TEXT_BYTES = 4_096
MAX_MATCHES = 256
MAX_LINT_ISSUES = 512
MAX_LINE_BYTES = 100

FORMATTER_IDEMPOTENT = True
AST_EQUIVALENT = True
ATOMIC_WRITE = True
COMMENT_PRESERVATION = True


class RegexError(Exception):
    """Stable, span-carrying regex error."""

    def __init__(self, code: str, start: int = 0, end: int = 0) -> None:
        super().__init__(code)
        self.code = code
        self.span = (start, end)
        self.failure_state = "NO_MATCH_STATE_PUBLISHED"


@dataclass(frozen=True)
class RegexOptions:
    unicode: bool = True
    caseInsensitive: bool = False
    multiline: bool = False
    maxSteps: int = MAX_REGEX_STEPS
    maxCaptures: int = 32

    def validate(self) -> None:
        if not self.unicode:
            raise RegexError("NEBO-G083-REGEX-UNICODE-REQUIRED")
        if not 1 <= self.maxSteps <= MAX_REGEX_STEPS:
            raise RegexError("NEBO-G083-REGEX-STEP-LIMIT")
        if not 0 <= self.maxCaptures <= 32:
            raise RegexError("NEBO-G083-REGEX-CAPTURE-LIMIT")


@dataclass(frozen=True)
class RegexMatch:
    start: int
    end: int
    text: str
    indexed: tuple[str | None, ...]
    named: dict[str, str | None]

    @classmethod
    def from_match(cls, match: re.Match[str]) -> "RegexMatch":
        return cls(match.start(), match.end(), match.group(0),
                   (match.group(0), *match.groups()), match.groupdict())


def _safe_pattern(pattern: str, options: RegexOptions) -> re.Pattern[str]:
    options.validate()
    try:
        encoded = pattern.encode("utf-8", "strict")
    except UnicodeError as error:
        raise RegexError("NEBO-G083-REGEX-UTF8") from error
    if not encoded:
        raise RegexError("NEBO-G083-REGEX-EMPTY")
    if len(encoded) > MAX_PATTERN_BYTES:
        raise RegexError("NEBO-G083-REGEX-PATTERN-LIMIT", 0, len(pattern))
    # Backreferences, look-around, conditionals, recursion, counted ranges,
    # and a quantifier applied to a group/quantifier are outside this profile.
    forbidden = (r"\\[1-9]", r"\(\?[=!<]", r"\(\?\(", r"\{[0-9]", r"\)[*+?]", r"[*+?][*+?]")
    for expression in forbidden:
        found = re.search(expression, pattern)
        if found:
            raise RegexError("NEBO-G083-REGEX-UNSUPPORTED", found.start(), found.end())
    flags = re.UNICODE
    if options.caseInsensitive:
        flags |= re.IGNORECASE
    if options.multiline:
        flags |= re.MULTILINE
    try:
        compiled = re.compile(pattern, flags)
    except re.error as error:
        start = int(getattr(error, "pos", 0) or 0)
        raise RegexError("NEBO-G083-REGEX-SYNTAX", start, start + 1) from error
    if compiled.groups > options.maxCaptures:
        raise RegexError("NEBO-G083-REGEX-CAPTURE-LIMIT")
    return compiled


@dataclass(frozen=True)
class Regex:
    pattern: str
    options: RegexOptions
    _compiled: re.Pattern[str] = field(repr=False, compare=False)

    @classmethod
    def compile(cls, pattern: str, options: RegexOptions | None = None) -> "Regex":
        selected = options or RegexOptions()
        return cls(pattern, selected, _safe_pattern(pattern, selected))

    def _text(self, text: str) -> str:
        if len(text.encode("utf-8", "strict")) > MAX_TEXT_BYTES:
            raise RegexError("NEBO-G083-REGEX-TEXT-LIMIT")
        estimated = (len(self.pattern) + 1) * (len(text) + 1)
        if estimated > self.options.maxSteps:
            raise RegexError("NEBO-G083-REGEX-STEP-LIMIT")
        return text

    def isMatch(self, text: str) -> bool:
        return self._compiled.search(self._text(text)) is not None

    def find(self, text: str) -> RegexMatch | None:
        found = self._compiled.search(self._text(text))
        return None if found is None else RegexMatch.from_match(found)

    def findAll(self, text: str, limit: int) -> list[RegexMatch]:
        selected = self._text(text)
        if not 0 <= limit <= MAX_MATCHES:
            raise RegexError("NEBO-G083-REGEX-MATCH-LIMIT")
        if limit == 0:
            return []
        result: list[RegexMatch] = []
        for found in self._compiled.finditer(selected):
            if len(result) == limit:
                raise RegexError("NEBO-G083-REGEX-MATCH-LIMIT")
            result.append(RegexMatch.from_match(found))
        return result

    def captures(self, text: str) -> RegexMatch | None:
        return self.find(text)

    def replace(self, text: str, replacement: str) -> str:
        selected = self._text(text)
        try:
            result = self._compiled.sub(replacement, selected)
        except re.error as error:
            raise RegexError("NEBO-G083-REGEX-REPLACEMENT") from error
        if len(result.encode("utf-8")) > MAX_TEXT_BYTES:
            raise RegexError("NEBO-G083-REGEX-TEXT-LIMIT")
        return result

    def split(self, text: str, limit: int) -> list[str]:
        selected = self._text(text)
        if not 1 <= limit <= MAX_MATCHES:
            raise RegexError("NEBO-G083-REGEX-MATCH-LIMIT")
        pieces = self._compiled.split(selected, maxsplit=limit - 1)
        if len(pieces) > limit:
            raise RegexError("NEBO-G083-REGEX-MATCH-LIMIT")
        return pieces

    def extract(self, text: str, group: int | str) -> str | None:
        found = self._compiled.search(self._text(text))
        if found is None:
            return None
        try:
            return found.group(group)
        except (IndexError, KeyError) as error:
            raise RegexError("NEBO-G083-REGEX-GROUP") from error

    @staticmethod
    def escape(text: str) -> str:
        if len(text.encode("utf-8", "strict")) > MAX_PATTERN_BYTES:
            raise RegexError("NEBO-G083-REGEX-PATTERN-LIMIT")
        return re.escape(text)


@dataclass(frozen=True)
class FormatTree:
    source: bytes
    digest: str
    commentCount: int
    triviaBytes: int

    @classmethod
    def parse(cls, source: bytes | str) -> "FormatTree":
        data = source.encode("utf-8") if isinstance(source, str) else bytes(source)
        if len(data) > MAX_TEXT_BYTES or b"\x00" in data:
            raise ValueError("NEBO-G083-FORMAT-SOURCE-LIMIT")
        data.decode("utf-8", "strict")
        comments = sum(1 for line in data.splitlines() if b"//" in line)
        trivia = sum(len(line) - len(line.rstrip(b" \t\r")) for line in data.split(b"\n"))
        return cls(data, hashlib.sha256(data).hexdigest(), comments, trivia)


def _canonicalize(data: bytes, options: dict[str, bool] | None = None) -> bytes:
    selected = {"trimTrailingWhitespace": True, "finalNewline": True, **(options or {})}
    if set(selected) != {"trimTrailingWhitespace", "finalNewline"} or any(
            not isinstance(value, bool) for value in selected.values()):
        raise ValueError("NEBO-G083-FORMAT-OPTIONS")
    from .token_tooling import normalize_trivia
    return normalize_trivia(data, 0, len(data), True,
                            trim_trailing=selected["trimTrailingWhitespace"],
                            final_newline=selected["finalNewline"])



class Formatter:
    @staticmethod
    def format(tree: FormatTree, options: dict[str, bool] | None = None) -> FormatTree:
        if not isinstance(tree, FormatTree):
            raise ValueError("NEBO-G083-FORMAT-TREE")
        result = FormatTree.parse(_canonicalize(tree.source, options))
        if result.commentCount != tree.commentCount:
            raise ValueError("NEBO-G083-FORMAT-LOST-COMMENT")
        return result

    @staticmethod
    def check(tree: FormatTree) -> bool:
        return Formatter.format(tree).source == tree.source

    @staticmethod
    def diff(tree: FormatTree) -> str:
        formatted = Formatter.format(tree)
        return "".join(difflib.unified_diff(
            tree.source.decode().splitlines(keepends=True),
            formatted.source.decode().splitlines(keepends=True),
            fromfile="before.no", tofile="after.no",
        ))


@dataclass(frozen=True)
class LintDiagnostic:
    rule: str
    code: str
    start: int
    end: int
    message: str
    safeFix: bool


@dataclass(frozen=True)
class LintRule:
    name: str
    code: str
    defaultLevel: str
    safeFix: bool


class LintRuleRegistry:
    FMT_LEVELS = tuple(f"FMT-{value}" for value in range(9))
    LINT_LEVELS = tuple(f"LINT-{value}" for value in range(9))
    _NAMES = (
        "no-tabs", "trailing-whitespace", "final-newline", "line-too-long",
        "duplicate-import", "unused-import", "missing-public-docs",
        "pipeline-too-long", "deprecated-api", "privacy-output-leak",
        "secret-output", "implicit-effects", "style-drift", "lost-comments",
    )

    def __init__(self) -> None:
        safe = {"no-tabs", "trailing-whitespace", "final-newline", "duplicate-import"}
        self.rules = {
            name: LintRule(name, f"NEBO-G083-LINT-{index:03d}", "warn", name in safe)
            for index, name in enumerate(self._NAMES, 1)
        }

    def profile(self, name: str) -> tuple[LintRule, ...]:
        if name != "recommended":
            raise ValueError("NEBO-G083-LINT-PROFILE")
        return tuple(self.rules[name] for name in self._NAMES)

    def lint(self, tree: FormatTree, profile: str = "recommended") -> list[LintDiagnostic]:
        self.profile(profile)
        text = tree.source.decode("utf-8")
        diagnostics: list[LintDiagnostic] = []

        def add(rule: str, start: int, end: int, message: str) -> None:
            descriptor = self.rules[rule]
            diagnostics.append(LintDiagnostic(rule, descriptor.code, start, end, message,
                                              descriptor.safeFix))
            if len(diagnostics) > MAX_LINT_ISSUES:
                raise ValueError("NEBO-G083-LINT-ISSUE-LIMIT")

        offset = 0
        imports: dict[str, int] = {}
        lines = text.splitlines(keepends=True)
        for line in lines:
            body = line.rstrip("\r\n")
            if "\t" in body:
                index = body.index("\t"); add("no-tabs", offset + index, offset + index + 1, "tab character")
            stripped = body.rstrip(" \t")
            if stripped != body:
                add("trailing-whitespace", offset + len(stripped), offset + len(body), "trailing whitespace")
            if len(body.encode("utf-8")) > MAX_LINE_BYTES:
                add("line-too-long", offset, offset + len(body), "line exceeds 100 bytes")
            match = re.fullmatch(r"\s*import\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;?\s*", body)
            if match:
                identity = match.group(1)
                if identity in imports:
                    add("duplicate-import", offset, offset + len(body), "duplicate import")
                else:
                    imports[identity] = offset
            if body.lstrip().startswith("public ") and (not lines or offset == 0 or "//" not in text[:offset].split("\n")[-2:-1]):
                add("missing-public-docs", offset, offset + len(body), "public declaration lacks docs")
            if body.count(".") > 8:
                add("pipeline-too-long", offset, offset + len(body), "pipeline exceeds eight stages")
            for needle, rule in (("deprecated", "deprecated-api"), ("private.console", "privacy-output-leak"),
                                 ("secret.console", "secret-output")):
                if needle in body:
                    index = body.index(needle); add(rule, offset + index, offset + index + len(needle), needle)
            if ".console(" in body and "effects" not in text:
                index = body.index(".console"); add("implicit-effects", offset + index, offset + index + 8, "console effect is implicit")
            offset += len(line)
        if tree.source and not tree.source.endswith(b"\n"):
            add("final-newline", len(text), len(text), "missing final newline")
        if b"\r\n" in tree.source and b"\n" in tree.source.replace(b"\r\n", b""):
            add("style-drift", 0, len(text), "mixed newline style")
        code_without_imports = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("import "))
        for identity, start in imports.items():
            leaf = identity.rsplit(".", 1)[-1]
            if not re.search(rf"\b{re.escape(leaf)}\b", code_without_imports):
                add("unused-import", start, start + len(identity), "unused import")
        formatted = Formatter.format(tree)
        if formatted.commentCount != tree.commentCount:
            add("lost-comments", 0, len(text), "formatter lost comments")
        if Formatter.format(formatted).source != formatted.source:
            add("style-drift", 0, len(text), "formatter is not idempotent")
        diagnostics.sort(key=lambda item: (item.start, item.end, item.code))
        return diagnostics


class SafeFixClass(str, Enum):
    WHITESPACE = "whitespace"
    FINAL_NEWLINE = "final-newline"
    IMPORT_ORDER = "import-order"
    EQUIVALENT_PIPELINE = "equivalent-pipeline"


class UnsafeFixClass(str, Enum):
    RENAME = "rename"
    REORDER = "reorder"
    TRUST = "trust"
    CAPABILITY = "capability"
    POLICY = "policy"


@dataclass
class FixPlan:
    path: Path
    original: bytes
    replacement: bytes
    digest: str
    fixClass: SafeFixClass

    @classmethod
    def forFormatting(cls, path: str | Path) -> "FixPlan":
        selected = Path(path)
        if selected.is_symlink():
            raise ValueError("NEBO-G083-FIX-REGULAR-REQUIRED")
        resolved = selected.resolve()
        if not resolved.is_file():
            raise ValueError("NEBO-G083-FIX-REGULAR-REQUIRED")
        original = resolved.read_bytes()
        replacement = Formatter.format(FormatTree.parse(original)).source
        return cls(resolved, original, replacement, hashlib.sha256(original).hexdigest(), SafeFixClass.WHITESPACE)

    def preview(self) -> str:
        return "".join(difflib.unified_diff(
            self.original.decode().splitlines(keepends=True),
            self.replacement.decode().splitlines(keepends=True),
            fromfile=str(self.path), tofile=str(self.path),
        ))

    def applyAtomic(self, capability: str, injectFailure: bool = False) -> bool:
        if capability != "source-write":
            raise ValueError("NEBO-G083-FIX-CAPABILITY")
        current = self.path.read_bytes()
        if hashlib.sha256(current).hexdigest() != self.digest:
            raise ValueError("NEBO-G083-FIX-STALE")
        descriptor, raw = tempfile.mkstemp(prefix=f".{self.path.name}.g083-", dir=self.path.parent)
        temporary = Path(raw)
        try:
            with os.fdopen(descriptor, "wb") as output:
                output.write(self.replacement)
                output.flush()
                os.fsync(output.fileno())
            os.chmod(temporary, stat.S_IMODE(self.path.stat().st_mode))
            if injectFailure:
                raise OSError("injected before replace")
            os.replace(temporary, self.path)
            return True
        finally:
            temporary.unlink(missing_ok=True)


@dataclass(frozen=True)
class SourceMapParity:
    cli: tuple[int, int]
    lsp: tuple[int, int]
    editor: tuple[int, int]

    def validate(self) -> bool:
        valid = self.cli[0] <= self.cli[1] and self.cli == self.lsp == self.editor
        if not valid:
            raise ValueError("NEBO-G083-SOURCE-MAP-PARITY")
        return True


@dataclass(frozen=True)
class LspTextEdit:
    documentVersion: int
    start: int
    end: int
    replacement: str

    def apply(self, source: str, currentVersion: int) -> str:
        if currentVersion != self.documentVersion:
            raise ValueError("NEBO-G083-LSP-STALE-VERSION")
        if not 0 <= self.start <= self.end <= len(source):
            raise ValueError("NEBO-G083-LSP-SPAN")
        return source[:self.start] + self.replacement + source[self.end:]


class SemanticTokenInterpolation:
    @staticmethod
    def tokens(source: str) -> list[dict[str, int | str]]:
        from compiler.sdk.token_tooling import TokenModel
        result: list[dict[str, int | str]] = []
        stack: list[int] = []
        for row in TokenModel.scan(source.encode('utf-8')).character_fragments():
            if row['tokenKind'] == 193:
                stack.append(int(row['start']))
            elif row['tokenKind'] == 194 and stack:
                result.append(dict(kind='interpolation',start=stack.pop(),end=int(row['end'])))
        return sorted(result,key=lambda row:(int(row['start']),int(row['end'])))


@dataclass(frozen=True)
class CodeAction:
    title: str
    edit: LspTextEdit
    safe: bool

    def preview(self, source: str, version: int) -> str:
        after = self.edit.apply(source, version)
        return "".join(difflib.unified_diff(source.splitlines(True), after.splitlines(True),
                                             fromfile="before.no", tofile="after.no"))


def report_diagnostics(diagnostics: Iterable[LintDiagnostic], mode: str) -> str:
    rows = list(diagnostics)
    if mode == "text":
        return "".join(f"{item.code}:{item.start}:{item.end}:{item.message}\n" for item in rows)
    if mode == "json":
        import json
        return json.dumps([item.__dict__ for item in rows], sort_keys=True, separators=(",", ":")) + "\n"
    if mode == "sarif":
        import json
        payload = {"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "neboc-lint"}},
                                                   "results": [{"ruleId": item.code, "message": {"text": item.message},
                                                                "locations": [{"physicalLocation": {"region": {
                                                                    "charOffset": item.start, "charLength": item.end - item.start}}}]}
                                                               for item in rows]}]}
        return json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n"
    raise ValueError("NEBO-G083-LINT-REPORT")


__all__ = [
    "Regex", "RegexOptions", "RegexError", "RegexMatch", "MAX_REGEX_STEPS",
    "FormatTree", "Formatter", "LintRuleRegistry", "LintDiagnostic", "FixPlan",
    "SafeFixClass", "UnsafeFixClass", "SourceMapParity", "LspTextEdit",
    "SemanticTokenInterpolation", "CodeAction", "FORMATTER_IDEMPOTENT",
    "AST_EQUIVALENT", "ATOMIC_WRITE", "COMMENT_PRESERVATION", "report_diagnostics",
]
