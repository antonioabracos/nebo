"""Edition-owned prelude, offline stdlib registry, and import migration.

This module is the single tooling projection of the official SDK manifests.
The native compiler remains the parser, semantic, lowering, and codegen owner;
this projection owns only implicit visibility and source-edit policy.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import tempfile
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
PRELUDE_PATH = ROOT / "sdk/interfaces/prelude/std.prelude.ni"
REGISTRY_PATH = ROOT / "sdk/interfaces/prelude/stdlib-registry.json"
TARGET = "x86_64-systemv-elf-linux"
MAX_MANIFEST_BYTES = 1 << 16
MAX_SOURCE_BYTES = 1 << 20
MASK64 = (1 << 64) - 1
IDENTIFIER = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
MODULE_DECL = re.compile(r"(?m)^(?P<indent>[ \t]*)module\s+[a-z][a-z0-9_.]*\s*;")
IMPORT = re.compile(
    r'(?m)^[ \t]*import\s+"(?P<module>std\.[a-z][a-z0-9_.]*)"\s*'
    r'\{(?P<symbols>[^}\n]*)\}\s*\.[a-z][a-z0-9_]*\s*;'
    r'(?P<owned>[ \t]*//[ \t]*neboc:migrate-imports)?[ \t]*(?P<newline>\n|$)'
)


class PreludeError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def _regular_file(path: Path, maximum: int, code: str) -> tuple[bytes, os.stat_result]:
    try:
        descriptor = os.open(
            path,
            os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK,
        )
    except OSError as error:
        raise PreludeError(code, f"cannot open bounded local input: {path}") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode):
            raise PreludeError(code, f"input must be a regular non-symlink file: {path}")
        if info.st_size > maximum:
            raise PreludeError(code, f"input exceeds the {maximum}-byte budget: {path}")
        data = b""
        while len(data) <= maximum:
            chunk = os.read(descriptor, min(65_536, maximum + 1 - len(data)))
            if not chunk:
                break
            data += chunk
        if len(data) > maximum:
            raise PreludeError(code, f"input exceeds the {maximum}-byte budget: {path}")
        return data, info
    finally:
        os.close(descriptor)


def _regular_bytes(path: Path, maximum: int, code: str) -> bytes:
    return _regular_file(path, maximum, code)[0]


def _json(path: Path) -> tuple[dict[str, object], str]:
    data = _regular_bytes(path, MAX_MANIFEST_BYTES, "NEBO-RF166-G163-001")
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("duplicate manifest field")
            result[key] = value
        return result
    try:
        value = json.loads(data.decode("utf-8", "strict"), object_pairs_hook=unique,
                           parse_constant=lambda _: (_ for _ in ()).throw(ValueError("nonfinite manifest value")))
    except (UnicodeError, ValueError) as error:
        raise PreludeError("NEBO-RF166-G163-001", f"invalid SDK manifest: {path}") from error
    if not isinstance(value, dict) or type(value.get("schema")) is not int or value["schema"] != 1:
        raise PreludeError("NEBO-RF166-G163-001", f"unsupported SDK manifest schema: {path}")
    return value, hashlib.sha256(data).hexdigest()


def _edition(value: str) -> str:
    normalized = value.removeprefix("Edition-").removeprefix("edition-")
    if normalized not in {"1"}:
        raise PreludeError("NEBO-RF166-G163-001", f"unsupported edition: {value}")
    return normalized


def _symbol_id(edition: str, name: str) -> str:
    value = 0xCBF29CE484222325
    for byte in f"std.prelude:{edition}:{name}".encode("utf-8"):
        value = ((value ^ byte) * 0x100000001B3) & MASK64
    return f"0x{value or 1:016x}"


@dataclass(frozen=True)
class PreludeProfile:
    edition: str
    enabled: bool = True
    freestanding: bool = False

    @classmethod
    def forEdition(cls, edition: str) -> "PreludeProfile":
        return cls(_edition(edition))


@dataclass(frozen=True)
class PreludeInterface:
    edition: str
    target: str
    interface_version: int
    interface_hash: str
    dependencies: tuple[str, ...]
    symbol_records: tuple[dict[str, str], ...]
    since: str = "Edition 1"
    stability: str = "stable"

    @classmethod
    def load(cls, profile: PreludeProfile, target: str) -> "PreludeInterface":
        registry = StdlibModuleRegistry.load()
        registry.require_target(target)
        manifest, digest = _json(PRELUDE_PATH)
        if manifest.get("module") != "std.prelude" or not isinstance(manifest.get("editions"), list):
            raise PreludeError("NEBO-RF166-G163-001", "std.prelude manifest identity is invalid")
        matches = [row for row in manifest["editions"]
                   if isinstance(row, dict) and row.get("edition") == profile.edition]
        if len(matches) != 1:
            raise PreludeError("NEBO-RF166-G163-001", "edition has no unique prelude interface")
        row = matches[0]
        if (row.get("since") != "Edition 1" or row.get("stability") != "stable"
                or row.get("targets") != [TARGET] or type(row.get("interfaceVersion")) is not int
                or row["interfaceVersion"] != 1):
            raise PreludeError("NEBO-RF166-G163-001", "prelude edition metadata is incomplete")
        raw_symbols = row.get("symbols")
        dependencies = row.get("dependencies")
        if not isinstance(raw_symbols, list) or not isinstance(dependencies, list):
            raise PreludeError("NEBO-RF166-G163-001", "prelude symbols or dependencies are invalid")
        records: list[dict[str, str]] = []
        names: set[str] = set()
        for raw in raw_symbols:
            if not isinstance(raw, dict) or set(raw) != {"component", "kind", "name", "origin"}:
                raise PreludeError("NEBO-RF166-G163-001", "prelude symbol record is invalid")
            if any(not isinstance(raw[key], str) or not raw[key] for key in raw):
                raise PreludeError("NEBO-RF166-G163-001", "prelude fields must be nonempty strings")
            record = dict(raw)
            name = record["name"]
            if name in names or registry.owner_of(name) != record["origin"]:
                raise PreludeError("NEBO-RF166-G163-001", "prelude symbol identity is duplicate or unowned")
            names.add(name)
            record["symbolId"] = _symbol_id(profile.edition, name)
            record["implicitOrigin"] = "PRELUDE"
            records.append(record)
        if tuple(sorted(dependencies)) != tuple(dependencies):
            raise PreludeError("NEBO-RF166-G163-001", "prelude dependencies must be deterministic")
        if dependencies != sorted({record['origin'] for record in records}):
            raise PreludeError("NEBO-RF166-G163-001", "prelude dependencies must match symbol origins")
        return cls(profile.edition, target, int(row.get("interfaceVersion", 0)), digest,
                   tuple(str(item) for item in dependencies), tuple(records), row['since'], row['stability'])


class Prelude:
    @staticmethod
    def symbols(interface: PreludeInterface) -> list[dict[str, str]]:
        return [dict(record) for record in interface.symbol_records]

    @staticmethod
    def inject(resolver: dict[str, dict[str, str]], interface: PreludeInterface,
               profile: PreludeProfile) -> list[dict[str, str]]:
        if not profile.enabled:
            return []
        staged = dict(resolver)
        injected: list[dict[str, str]] = []
        for record in interface.symbol_records:
            name = record["name"]
            existing = staged.get(name)
            if existing is not None and existing.get("symbolId") != record["symbolId"]:
                raise PreludeError("NEBO-RF166-G163-003", f"prelude collision for {name}")
            if existing is None:
                staged[name] = dict(record)
                injected.append(dict(record))
        resolver.clear()
        resolver.update(staged)
        return injected

    @staticmethod
    def disable(profile: PreludeProfile) -> PreludeProfile:
        return replace(profile, enabled=False, freestanding=True)


@dataclass(frozen=True)
class StdlibModuleRegistry:
    records: tuple[dict[str, object], ...]
    registry_hash: str

    @classmethod
    def load(cls) -> "StdlibModuleRegistry":
        manifest, digest = _json(REGISTRY_PATH)
        raw = manifest.get("modules")
        if not isinstance(raw, list):
            raise PreludeError("NEBO-RF166-G163-005", "stdlib registry has no module list")
        records: list[dict[str, object]] = []
        names: list[str] = []
        for item in raw:
            if not isinstance(item, dict) or not isinstance(item.get("name"), str):
                raise PreludeError("NEBO-RF166-G163-005", "stdlib module record is invalid")
            record = dict(item)
            names.append(str(record["name"]))
            for key in ("capabilities", "exports", "targets", "effects", "editions"):
                values = record.get(key)
                if (not isinstance(values, list) or any(not isinstance(v, str) or not v for v in values)
                        or values != sorted(set(values))):
                    raise PreludeError("NEBO-RF166-G163-005", f"stdlib {key} is invalid")
            if (record.get("since") != "Edition 1" or record['editions'] != ['1']
                    or record['targets'] != [TARGET]
                    or record.get('stability') not in {'stable', 'experimental'}
                    or record.get('layer') not in {'STDLIB', 'DOMAIN_PACK'}
                    or record.get('availability') not in {'BOUNDED_PUBLIC', 'TARGET_GATED', 'EXCLUDED_1_0'}
                    or record.get('importGrantsCapabilities') is not False):
                raise PreludeError("NEBO-RF166-G163-005", "stdlib lifecycle/authority metadata is incomplete")
            records.append(record)
        if names != sorted(set(names)):
            raise PreludeError("NEBO-RF166-G163-005", "stdlib registry order or identity is invalid")
        exports = [symbol for record in records for symbol in record['exports']]
        if len(exports) != len(set(exports)):
            raise PreludeError("NEBO-RF166-G163-005", "stdlib export has conflicting owners")
        return cls(tuple(records), digest)

    def require_target(self, target: str) -> None:
        if target != TARGET:
            raise PreludeError("NEBO-RF166-G163-008", f"unsupported stdlib target: {target}")

    def resolve(self, name: str, edition: str, target: str) -> dict[str, object]:
        _edition(edition)
        self.require_target(target)
        matches = [dict(row) for row in self.records if row["name"] == name]
        if len(matches) != 1 or target not in matches[0]["targets"]:
            raise PreludeError("NEBO-RF166-G163-005", f"stdlib module is unavailable: {name}")
        result = matches[0]
        result["edition"] = _edition(edition)
        result["target"] = target
        result["importGrantsCapabilities"] = False
        return result

    def owner_of(self, symbol: str) -> str | None:
        owners = [str(row["name"]) for row in self.records if symbol in row["exports"]]
        return owners[0] if len(owners) == 1 else None


def _source_text(path: Path) -> tuple[bytes, str, os.stat_result]:
    data, info = _regular_file(path, MAX_SOURCE_BYTES, "NEBO-RF166-G163-007")
    try:
        text = data.decode("utf-8", "strict")
    except UnicodeError as error:
        raise PreludeError("NEBO-RF166-G163-007", f"source is not UTF-8: {path}") from error
    return data, text, info


def _code_without_comments(text: str) -> str:
    result = list(text)
    index = 0
    while index < len(text):
        if text.startswith("//", index):
            end = text.find("\n", index)
            end = len(text) if end < 0 else end
            for cursor in range(index, end):
                result[cursor] = " "
            index = end
        elif text.startswith("/*", index):
            start = index
            depth = 1
            index += 2
            while index < len(text) and depth:
                if text.startswith("/*", index):
                    depth += 1
                    index += 2
                elif text.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            for cursor in range(start, index):
                if text[cursor] != "\n":
                    result[cursor] = " "
        elif text[index] in {'"', "'"}:
            quote = text[index]
            end = index + 1
            while end < len(text):
                if text[end] == quote and text[end - 1] != "\\":
                    end += 1
                    break
                end += 1
            index = end
        else:
            index += 1
    return "".join(result)


def _code_without_comments_strings(text: str) -> str:
    code = _code_without_comments(text)
    result = list(code)
    index = 0
    while index < len(code):
        if code[index] in {'"', "'"}:
            quote = code[index]
            end = index + 1
            while end < len(code):
                if code[end] == quote and code[end - 1] != "\\":
                    end += 1
                    break
                end += 1
            for cursor in range(index, end):
                if code[cursor] != "\n":
                    result[cursor] = " "
            index = end
        else:
            index += 1
    return "".join(result)


SOURCE_IMPORT = re.compile(
    r'\bimport\s+"(?P<module>std\.[a-z][a-z0-9_.]*)"\s*'
    r'\{(?P<symbols>[^{}]*)\}\s*\.[a-z][a-z0-9_]*\s*;'
)


def std_import_matches(text: str):
    """Top-level source imports; comments/literals cannot create visibility."""
    safe = _code_without_comments(text)
    code = _code_without_comments_strings(text)
    for match in SOURCE_IMPORT.finditer(safe):
        at = match.start()
        if code[at:at+6] != 'import':
            continue
        prefix = code[:at]
        if prefix.count('{') != prefix.count('}'):
            continue
        yield match


def without_std_imports(text: str) -> str:
    spans = [(match.start(), match.end()) for match in std_import_matches(text)]
    # Visibility owns these declarations; the native Program owner consumes
    # every remaining statement. Preserve byte offsets and line structure for
    # diagnostics instead of shifting the body when removing an import.
    result=list(text)
    for start,end in spans:
        for index in range(start,end):
            if result[index] not in '\r\n':result[index]=' ' * len(result[index].encode('utf-8'))
    return ''.join(result)


def imported_symbols(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for match in std_import_matches(text):
        names = [item.strip().removesuffix(";").strip()
                 for item in match.group("symbols").split(";") if item.strip()]
        for name in names:
            if not IDENTIFIER.fullmatch(name) or name in result:
                raise PreludeError("NEBO-RF166-G163-006", "invalid or duplicate selective stdlib import")
            result[name] = match.group("module")
    return result


def used_symbols(text: str, candidates: Iterable[str]) -> list[str]:
    without_imports = without_std_imports(text)
    code = _code_without_comments_strings(without_imports)
    present = set(IDENTIFIER.findall(code))
    return sorted(set(candidates) & present)


def verify_visibility(text: str, interface: PreludeInterface, no_prelude: bool) -> dict[str, object]:
    registry = StdlibModuleRegistry.load()
    imports = imported_symbols(text)
    for symbol, module in imports.items():
        resolved = registry.resolve(module, interface.edition, interface.target)
        if symbol not in resolved["exports"]:
            raise PreludeError("NEBO-RF166-G163-005", f"{symbol} is not exported by {module}")
    prelude_names = [record["name"] for record in interface.symbol_records]
    used = used_symbols(text, [*prelude_names, *[str(value) for row in registry.records for value in row["exports"]]])
    advanced = [name for name in used if name not in prelude_names and name not in imports]
    if advanced:
        raise PreludeError("NEBO-RF166-G163-004", f"explicit stdlib import required for {advanced[0]}")
    missing = [name for name in used if name in prelude_names and name not in imports]
    if no_prelude and missing:
        raise PreludeError("NEBO-RF166-G163-002", f"no-prelude hides {missing[0]}; add its explicit stdlib import")
    visible = sorted(set(imports) | (set(prelude_names) if not no_prelude else set()))
    return {"used": used, "visible": visible, "explicit": sorted(imports), "missing": missing if no_prelude else []}


def reachableComponents(program: str, interface: PreludeInterface, no_prelude: bool = False) -> list[str]:
    visibility = verify_visibility(program, interface, no_prelude)
    by_name = {record["name"]: record["component"] for record in interface.symbol_records}
    return sorted({by_name[name] for name in visibility["used"] if name in by_name})


@dataclass(frozen=True)
class MigrationEdit:
    path: Path
    before: bytes
    after: bytes
    before_hash: str
    insertions: tuple[str, ...]
    removals: tuple[str, ...]
    collisions: tuple[str, ...]


class PreludeMigration:
    @staticmethod
    def plan(fromEdition: str, toEdition: str, paths: Iterable[Path], *,
             profile: str, target: str = TARGET) -> list[MigrationEdit]:
        _edition(fromEdition)
        selected = PreludeProfile.forEdition(toEdition)
        interface = PreludeInterface.load(selected, target)
        if profile not in {"default", "no-prelude"}:
            raise PreludeError("NEBO-RF166-G163-006", f"invalid migration profile: {profile}")
        names = [record["name"] for record in interface.symbol_records]
        origins = {record["name"]: record["origin"] for record in interface.symbol_records}
        edits: list[MigrationEdit] = []
        identities: set[tuple[int, int]] = set()
        for raw_path in paths:
            path = Path(os.path.abspath(raw_path))
            before, text, info = _source_text(path)
            identity = (info.st_dev, info.st_ino)
            if identity in identities:
                raise PreludeError("NEBO-RF166-G163-006", "migration paths must have unique identities")
            identities.add(identity)
            safe_text = _code_without_comments(text)
            declaration = MODULE_DECL.search(safe_text)
            collisions = tuple(sorted(name for name in names
                                      if re.search(rf"(?m)^\s*(?:export\s+)?(?:public\s+)?{re.escape(name)}\s*=", safe_text)))
            if collisions:
                edits.append(MigrationEdit(path, before, before, hashlib.sha256(before).hexdigest(), (), (), collisions))
                continue
            imports = imported_symbols(text)
            used = used_symbols(text, names)
            insertions: list[str] = []
            removals: list[str] = []
            after_text = text
            if profile == "no-prelude":
                grouped: dict[str, list[str]] = {}
                for name in used:
                    if name not in imports:
                        grouped.setdefault(origins[name], []).append(name)
                lines = []
                for module in sorted(grouped):
                    symbols = " ".join(f"{name};" for name in sorted(grouped[module]))
                    alias = module.rsplit(".", 1)[-1]
                    line = f'import "{module}" {{ {symbols} }}.{alias}; // neboc:migrate-imports'
                    lines.append(line)
                    insertions.append(line)
                if lines:
                    at = declaration.end() if declaration is not None else 0
                    prefix = "\n" if at else ""
                    after_text = text[:at] + prefix + "\n".join(lines) + "\n" + text[at:].removeprefix("\n")
            else:
                removed_spans: list[tuple[int, int]] = []
                for match in IMPORT.finditer(safe_text):
                    raw_record = text[match.start():match.end()]
                    if not re.search(r"//[ \t]*neboc:migrate-imports", raw_record):
                        continue
                    imported = {item.strip().removesuffix(";").strip()
                                for item in match.group("symbols").split(";") if item.strip()}
                    if imported <= set(names):
                        removals.append(raw_record.strip())
                        removed_spans.append((match.start(), match.end()))
                after_text = "".join(text[cursor:end] for cursor, end in zip(
                    [0, *[right for _, right in removed_spans]],
                    [*[left for left, _ in removed_spans], len(text)],
                ))
                after_text = re.sub(r"\n{3,}", "\n\n", after_text)
            edits.append(MigrationEdit(path, before, after_text.encode(), hashlib.sha256(before).hexdigest(),
                                       tuple(insertions), tuple(removals), ()))
        return edits

    @staticmethod
    def publicApiImpact(edits: Iterable[MigrationEdit]) -> dict[str, object]:
        rows = list(edits)
        collisions = sorted({name for row in rows for name in row.collisions})
        return {"collisions": collisions, "publicApiChanged": bool(collisions),
                "files": len(rows), "safe": not collisions}


def _atomic_replace_bytes(path: Path, data: bytes, mode: int) -> None:
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.g163-", dir=path.parent)
    try:
        os.fchmod(descriptor, mode)
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


def apply_migration(edits: Iterable[MigrationEdit]) -> int:
    rows = list(edits)
    if any(row.collisions for row in rows):
        raise PreludeError("NEBO-RF166-G163-003", "migration has a public prelude collision")
    for row in rows:
        current, _, _ = _source_text(row.path)
        if hashlib.sha256(current).hexdigest() != row.before_hash:
            raise PreludeError("NEBO-RF166-G163-006", f"migration plan is stale: {row.path}")
    changed = 0
    published: list[MigrationEdit] = []
    try:
        for row in rows:
            if row.before == row.after:
                continue
            _atomic_replace_bytes(row.path, row.after, stat.S_IMODE(row.path.stat().st_mode))
            published.append(row)
            changed += 1
    except BaseException:
        for row in reversed(published):
            _atomic_replace_bytes(row.path, row.before, stat.S_IMODE(row.path.stat().st_mode))
        raise
    return changed
