#!/usr/bin/env python3
"""G159 deterministic local documentation over canonical Nebo authorities."""

from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
from html import escape
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import struct
import subprocess
import sys
import tarfile
import tempfile
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "build/bin/neboc"
EXAMPLE_TOOL = ROOT / "tools/rf204-g158.py"
NATIVE = ROOT / "build/bin/nebo-docs"
REQUEST = struct.Struct("<32Q")
RESULT = struct.Struct("<8Q")
MAGIC = 0x39353153434F444E
VERSION = 1
MAX_SOURCE_BYTES = 16_384
MAX_SOURCES = 256
MAX_INDEX_BYTES = 4 * 1024 * 1024
MAX_ARCHIVE_BYTES = 16 * 1024 * 1024
MAX_LINKS = 8192
TARGETS = {"x86_64-linux": 0x34365F363878}

OP_GRAPH, OP_RENDER, OP_SEARCH, OP_LINKS = 1, 2, 3, 4
OP_VIEWS, OP_CLI, OP_ARCHIVE = 5, 6, 7
CMD_BUILD, CMD_VERIFY, CMD_SEARCH, CMD_DIFF, CMD_SERVE, CMD_RESTORE = 1, 2, 3, 4, 5, 6
FLAG_PUBLIC_ONLY = 1
FLAG_OFFLINE_HTML = 2
FLAG_PATHS_REDACTED = 4
FLAG_LOCAL_ONLY = 8
FLAG_INCREMENTAL = 16
FLAG_ARCHIVE = 32
FLAG_VERIFY = 64
CLASSES = {1: "GRAPH", 2: "RENDERED", 3: "INDEXED", 4: "LINKED", 5: "VIEW", 6: "COMMAND", 7: "ARCHIVE"}
LINK = re.compile(r"\{@link\s+([^}]+)\}")
REMOTE = re.compile(r"(?:https?:)?//", re.IGNORECASE)
TOKEN = re.compile(r"[\w]+", re.UNICODE)


class DocsError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def fnv(data: bytes) -> int:
    value = 0xCBF29CE484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001B3) & 0xFFFF_FFFF_FFFF_FFFF
    return value or 1


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_regular(path: Path, limit: int, code: str, *, text: bool = False) -> bytes:
    path = path.absolute()
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    except OSError as error:
        raise DocsError(code, "cannot open a requested regular file") from error
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
            raise DocsError(code, "input must be a bounded regular non-symlink file")
        result = b""
        while len(result) <= limit:
            part = os.read(descriptor, min(8192, limit + 1 - len(result)))
            if not part:
                break
            result += part
        if len(result) > limit:
            raise DocsError(code, "input exceeds its bounded documentation limit")
        if text:
            result.decode("utf-8", "strict")
        return result
    except UnicodeDecodeError as error:
        raise DocsError(code, "input is not valid UTF-8") from error
    finally:
        os.close(descriptor)


def safe_name(path: Path, package_root: Path) -> str:
    try:
        return path.resolve().relative_to(package_root.resolve()).as_posix()
    except ValueError:
        return path.name


def select_sources(values: list[str]) -> tuple[list[Path], Path]:
    selected: list[Path] = []
    roots: list[Path] = []
    for raw in values:
        path = Path(raw).absolute()
        if path.is_symlink():
            raise DocsError("NEBO-RF166-G159-008", "documentation inputs cannot be symlinks")
        if path.is_dir():
            roots.append(path)
            for base, directories, files in os.walk(path, followlinks=False):
                if any((Path(base) / item).is_symlink() for item in directories):
                    raise DocsError("NEBO-RF166-G159-008", "package trees cannot contain directory symlinks")
                for name in files:
                    candidate = Path(base) / name
                    if name.endswith(".no"):
                        if candidate.is_symlink():
                            raise DocsError("NEBO-RF166-G159-008", "package trees cannot contain source symlinks")
                        selected.append(candidate)
        else:
            roots.append(path.parent)
            selected.append(path)
    if not selected or len(selected) > MAX_SOURCES:
        raise DocsError("NEBO-RF166-G159-001", "package must contain 1..256 Nebo documentation sources")
    unique = sorted({item.absolute() for item in selected}, key=lambda item: item.as_posix())
    for path in unique:
        read_regular(path, MAX_SOURCE_BYTES, "NEBO-RF166-G159-IO", text=True)
    package_root = roots[0] if len({item.resolve() for item in roots}) == 1 else Path(os.path.commonpath([str(item) for item in roots]))
    return unique, package_root


def subprocess_json(arguments: list[str], code: str) -> dict[str, object]:
    result = subprocess.run(
        arguments, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=120, check=False,
        env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode or result.stderr:
        raise DocsError(code, "a canonical compiler/documentation authority rejected the input")
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocsError(code, "a canonical authority returned invalid JSON transport") from error
    if not isinstance(value, dict):
        raise DocsError(code, "a canonical authority returned the wrong transport shape")
    return value


def request(operation: int, graph: dict[str, object] | None = None, **changes: int) -> list[int]:
    words = [0] * 32
    words[:3] = [MAGIC, VERSION, operation]
    if graph is not None:
        words[3:9] = [
            int(graph["graphDigestFNV"], 16), len(graph["symbols"]),
            len(graph["modules"]), 1, int(graph["publicSymbols"]),
            int(graph["privateSymbols"]),
        ]
    offsets = {
        "primary": 9, "secondary": 10, "tertiary": 11,
        "expected": 12, "observed": 13, "flags": 14, "budget": 15,
        "query": 16, "matches": 17, "links": 18, "resolved": 19,
        "edition": 20, "target": 21, "stability": 22, "changed": 23,
        "total": 24, "command": 25, "archive": 26, "restore": 27,
    }
    for name, value in changes.items():
        words[offsets[name]] = value & 0xFFFF_FFFF_FFFF_FFFF
    return words


def native(words: list[int], code: str) -> dict[str, object]:
    if len(words) != 32 or not NATIVE.is_file():
        raise DocsError("NEBO-RF166-G159-IO", "native local-documentation owner is unavailable")
    result = subprocess.run(
        [str(NATIVE)], input=REQUEST.pack(*words), stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=10, check=False, env={},
    )
    if result.returncode or result.stderr or len(result.stdout) != RESULT.size:
        raise DocsError(code, "native local-documentation contract rejected observed facts")
    status, operation, digest, class_id, metric_a, metric_b, metric_c, flags = RESULT.unpack(result.stdout)
    if status or operation != words[2] or class_id != operation or class_id not in CLASSES:
        raise DocsError("NEBO-RF166-G159-IO", "native owner returned invalid transport")
    return {
        "class": CLASSES[class_id], "digest": f"0x{digest:016x}",
        "metrics": [metric_a, metric_b, metric_c], "flags": flags,
    }


def verify_examples(paths: list[Path], budget: int, extra: list[str] | None = None) -> dict[str, object]:
    result = subprocess.run(
        [sys.executable, str(EXAMPLE_TOOL), "docs", "--verify", *map(str, paths),
         "--budget", str(budget), "--report", "json", *(extra or [])],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        timeout=120, check=False, env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode:
        sys.stderr.buffer.write(result.stderr)
        raise SystemExit(result.returncode)
    if result.stderr:
        raise DocsError("NEBO-RF166-G159-001", "executable documentation emitted unexpected diagnostics")
    try:
        value = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocsError("NEBO-RF166-G159-001", "executable documentation returned invalid JSON") from error
    if not isinstance(value, dict):
        raise DocsError("NEBO-RF166-G159-001", "executable documentation returned the wrong transport shape")
    return value


def doc_record(path: Path) -> dict[str, object]:
    value = subprocess_json(
        [str(COMPILER), "dump", "doc-record", str(path)],
        "NEBO-RF166-G159-001",
    )
    if value.get("node") != "DocRecord" or value.get("visibility") not in {"PUBLIC", "PRIVATE"}:
        raise DocsError("NEBO-RF166-G159-001", "canonical DocRecord identity is missing")
    return value


def normalize_target(target: str) -> int:
    if target not in TARGETS:
        raise DocsError("NEBO-RF166-G159-005", "unsupported local documentation target")
    return TARGETS[target]


def build_graph(paths: list[Path], package_root: Path, include_private: bool, edition: int, target: str) -> dict[str, object]:
    if edition != 1:
        raise DocsError("NEBO-RF166-G159-005", "only Edition 1 documentation is available")
    target_id = normalize_target(target)
    nodes: list[dict[str, object]] = []
    seen_symbols: set[int] = set()
    seen_titles: set[str] = set()
    for path in paths:
        record = doc_record(path)
        symbol = int(str(record["symbolId"]), 0)
        texts = record.get("text")
        if not isinstance(texts, dict) or not isinstance(texts.get("title"), str) or not isinstance(texts.get("summary"), str):
            raise DocsError("NEBO-RF166-G159-001", "public reference requires title and summary")
        title = str(texts["title"]).strip().strip('"')
        summary = str(texts["summary"]).strip().strip('"')
        if not title or symbol in seen_symbols or title.casefold() in seen_titles:
            raise DocsError("NEBO-RF166-G159-001", "DocsGraph identities must be unique and non-empty")
        seen_symbols.add(symbol)
        seen_titles.add(title.casefold())
        visibility = str(record["visibility"])
        if visibility == "PRIVATE" and not include_private:
            continue
        if REMOTE.search(title) or REMOTE.search(summary):
            raise DocsError("NEBO-RF166-G159-008", "local documentation cannot depend on remote content")
        span = record.get("sourceSpan")
        if not isinstance(span, list) or len(span) != 2 or any(not isinstance(item, int) for item in span):
            raise DocsError("NEBO-RF166-G159-001", "DocRecord source span is invalid")
        source = safe_name(path, package_root)
        attachment = record.get("attachment")
        if not isinstance(attachment, dict) or not isinstance(attachment.get("kind"), str) or not isinstance(attachment.get("name"), str):
            raise DocsError("NEBO-RF166-G159-001", "DocRecord attachment identity is invalid")
        attachment_kind = str(attachment["kind"])
        attachment_name = str(attachment["name"])
        module_name = attachment_name if attachment_kind == "module" else Path(source).stem
        node = {
            "symbolId": f"0x{symbol:016x}", "title": title, "summary": summary,
            "module": module_name, "package": package_root.name or "package",
            "visibility": visibility, "edition": edition, "target": target,
            "attachmentKind": attachment_kind, "attachmentName": attachment_name,
            "interface": record["interface"],
            "receiverTypes": [attachment_name] if attachment_kind in {"type", "struct", "enum"} else [],
            "stability": "deprecated" if str(texts.get("deprecated", "never")).strip().strip('"').casefold() != "never" else "stable",
            "since": str(texts.get("since", "Edition 1")).strip().strip('"'),
            "source": source, "sourceSpan": span,
            "sourceLink": f"source:{source}#byte={span[0]}..{span[0] + span[1]}",
            "links": [], "relatedSymbols": [],
        }
        nodes.append(node)
    nodes.sort(key=lambda item: int(str(item["symbolId"]), 16))
    if not nodes:
        raise DocsError("NEBO-RF166-G159-001", "visibility policy removed every documentation symbol")
    by_title = {str(item["title"]).casefold(): item for item in nodes}
    by_symbol = {str(item["symbolId"]).casefold(): item for item in nodes}
    link_count = 0
    for node in nodes:
        links: list[dict[str, str]] = []
        for raw in LINK.findall(str(node["summary"])):
            key = raw.strip()
            target_node = by_symbol.get(key.casefold()) or by_title.get(key.casefold())
            if target_node is None:
                raise DocsError("NEBO-RF166-G159-004", f"broken SymbolId cross-link: {key}")
            links.append({"label": key, "symbolId": str(target_node["symbolId"])})
        link_count += len(links)
        if link_count > MAX_LINKS:
            raise DocsError("NEBO-RF166-G159-004", "cross-link budget exceeded")
        node["links"] = links
        related = {link["symbolId"] for link in links}
        related.update(
            str(other["symbolId"]) for other in nodes
            if other["module"] == node["module"] and other["symbolId"] != node["symbolId"]
        )
        node["relatedSymbols"] = sorted(related, key=lambda value: int(value, 16))[:8]
    graph: dict[str, object] = {
        "schema": 1, "node": "DocsGraph", "edition": edition, "target": target,
        "policy": "INCLUDE_PRIVATE" if include_private else "PUBLIC_ONLY",
        "modules": sorted({str(item["module"]) for item in nodes}),
        "symbols": nodes, "publicSymbols": sum(item["visibility"] == "PUBLIC" for item in nodes),
        "privateSymbols": sum(item["visibility"] == "PRIVATE" for item in nodes),
        "linkCount": link_count,
        "owners": {
            "interface": "compiler/interface/doc_serialization.asm",
            "record": "compiler/semantic/docs/doc_record.asm",
            "graph": "compiler/docs/docs_graph.asm",
        },
    }
    graph_bytes = canonical(graph)
    graph["graphDigest"] = sha(graph_bytes)
    graph["graphDigestFNV"] = f"0x{fnv(graph_bytes):016x}"
    flags = FLAG_PATHS_REDACTED | (0 if include_private else FLAG_PUBLIC_ONLY)
    native(request(OP_GRAPH, graph, flags=flags), "NEBO-RF166-G159-001")
    native(request(OP_LINKS, graph, flags=FLAG_PATHS_REDACTED, links=link_count, resolved=link_count), "NEBO-RF166-G159-004")
    native(request(OP_VIEWS, graph, edition=edition, target=target_id, stability=len(nodes)), "NEBO-RF166-G159-005")
    return graph


def words(value: str) -> list[str]:
    return sorted({item.casefold() for item in TOKEN.findall(value) if item})


def replace_links(text: str, links: list[dict[str, str]], html: bool) -> str:
    pending = iter(links)
    def substitute(match: re.Match[str]) -> str:
        link = next(pending)
        symbol = link["symbolId"][2:]
        label = escape(link["label"]) if html else link["label"]
        return f'<a href="symbols/{symbol}.html">{label}</a>' if html else f'[{label}](symbols/{symbol}.md)'
    return LINK.sub(substitute, text)


def render(graph: dict[str, object]) -> tuple[dict[str, bytes], dict[str, object]]:
    symbols = list(graph["symbols"])
    search_documents: list[dict[str, object]] = []
    token_map: dict[str, list[str]] = defaultdict(list)
    files: dict[str, bytes] = {}
    md_index = ["# Local Nebo reference", "", f"Edition {graph['edition']} · target `{graph['target']}`", ""]
    html_links: list[str] = []
    for node in symbols:
        symbol = str(node["symbolId"])
        stem = symbol[2:]
        md_index.append(f"- [{node['title']}](symbols/{stem}.md) — {replace_links(str(node['summary']), list(node['links']), False)}")
        html_links.append(f'<li><a href="symbols/{stem}.html">{escape(str(node["title"]))}</a> — {replace_links(escape(str(node["summary"])), list(node["links"]), True)}</li>')
        markdown = "\n".join([
            f"# {node['title']}", "", replace_links(str(node["summary"]), list(node["links"]), False), "",
            f"- SymbolId: `{symbol}`", f"- Module: `{node['module']}`", f"- Since: `{node['since']}`",
            f"- Stability: `{node['stability']}`", f"- Target: `{node['target']}`",
            f"- Source: `{node['sourceLink']}`", "",
        ])
        html_page = "".join([
            '<!doctype html><html lang="en"><head><meta charset="utf-8">',
            '<meta name="viewport" content="width=device-width,initial-scale=1">',
            f"<title>{escape(str(node['title']))} — Nebo reference</title></head><body>",
            '<nav aria-label="Reference"><a href="../index.html">Reference index</a></nav><main>',
            f"<h1>{escape(str(node['title']))}</h1><p>{replace_links(escape(str(node['summary'])), list(node['links']), True)}</p>",
            f"<dl><dt>SymbolId</dt><dd><code>{symbol}</code></dd><dt>Module</dt><dd><code>{escape(str(node['module']))}</code></dd>",
            f"<dt>Stability</dt><dd>{escape(str(node['stability']))}</dd><dt>Target</dt><dd>{escape(str(node['target']))}</dd></dl>",
            "</main></body></html>\n",
        ])
        files[f"symbols/{stem}.md"] = markdown.encode("utf-8")
        files[f"symbols/{stem}.html"] = html_page.encode("utf-8")
        document = {
            "symbolId": symbol, "title": node["title"], "summary": node["summary"],
            "module": node["module"], "receiverTypes": node["receiverTypes"],
            "tags": [node["attachmentKind"], node["stability"], node["target"]],
        }
        search_documents.append(document)
        for token in words(" ".join([str(node["title"]), str(node["summary"]), str(node["module"]), str(node["stability"]), *map(str, node["receiverTypes"])])):
            token_map[token].append(symbol)
    files["index.md"] = ("\n".join(md_index) + "\n").encode("utf-8")
    files["index.html"] = "".join([
        '<!doctype html><html lang="en"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width,initial-scale=1"><title>Local Nebo reference</title></head><body>',
        '<nav aria-label="Reference">Local reference</nav><main><h1>Local Nebo reference</h1>',
        '<form role="search"><label for="query">Search documentation</label><input id="query" name="query"></form><ul>',
        *html_links, "</ul></main></body></html>\n",
    ]).encode("utf-8")
    public_graph = {key: value for key, value in graph.items() if key != "graphDigestFNV"}
    files["docs-index.json"] = canonical(public_graph) + b"\n"
    search_index: dict[str, object] = {
        "schema": 1, "owner": "NEBO-RF166-G159", "graphDigest": graph["graphDigest"],
        "graphDigestFNV": graph["graphDigestFNV"], "documents": search_documents,
        "tokens": {key: sorted(set(value), key=lambda item: int(item, 16)) for key, value in sorted(token_map.items())},
    }
    files["search-index.json"] = canonical(search_index) + b"\n"
    manifest = {
        "schema": 1, "owner": "NEBO-RF166-G159", "edition": graph["edition"], "target": graph["target"],
        "graphDigest": graph["graphDigest"],
        "files": {name: sha(data) for name, data in sorted(files.items())},
    }
    files["manifest.json"] = canonical(manifest) + b"\n"
    if any(REMOTE.search(data.decode("utf-8", "strict")) for name, data in files.items() if name.endswith((".md", ".html"))):
        raise DocsError("NEBO-RF166-G159-008", "rendered documentation contains a remote dependency")
    md_digest = fnv(b"".join(files[name] for name in sorted(files) if name.endswith(".md")))
    html_digest = fnv(b"".join(files[name] for name in sorted(files) if name.endswith(".html")))
    json_digest = fnv(b"".join(files[name] for name in sorted(files) if name.endswith(".json")))
    native(request(OP_RENDER, graph, primary=md_digest, secondary=html_digest, tertiary=json_digest,
                   expected=len(files), observed=len(files), flags=FLAG_OFFLINE_HTML), "NEBO-RF166-G159-002")
    first_query = words(str(symbols[0]["title"]))[0]
    matches = len(search_results(search_index, first_query, 256))
    native(request(OP_SEARCH, graph, primary=fnv(files["search-index.json"]), query=fnv(first_query.encode()),
                   matches=matches, budget=256), "NEBO-RF166-G159-003")
    return files, search_index


def search_results(index: dict[str, object], query: str, limit: int) -> list[dict[str, object]]:
    terms = words(query)
    if not terms:
        raise DocsError("NEBO-RF166-G159-003", "search query must contain an indexable token")
    documents = index.get("documents")
    if not isinstance(documents, list) or len(documents) > 1024:
        raise DocsError("NEBO-RF166-G159-003", "search index documents are malformed or unbounded")
    ranked: list[tuple[int, int, dict[str, object]]] = []
    for document in documents:
        if not isinstance(document, dict) or not isinstance(document.get("symbolId"), str):
            raise DocsError("NEBO-RF166-G159-003", "search index contains an invalid document")
        title = str(document.get("title", "")).casefold()
        haystack = " ".join([title, str(document.get("summary", "")).casefold(), str(document.get("module", "")).casefold()])
        if all(term in haystack for term in terms):
            score = sum(100 if title == term else 50 if title.startswith(term) else 10 for term in terms)
            ranked.append((-score, int(str(document["symbolId"]), 16), document))
    return [item[2] for item in sorted(ranked)[:limit]]


def tree_digest(files: dict[str, bytes]) -> int:
    return fnv(b"".join(name.encode() + b"\0" + hashlib.sha256(data).digest() for name, data in sorted(files.items())))


def atomic_write(path: Path, data: bytes) -> None:
    if not path.parent.is_dir() or path.parent.is_symlink():
        raise DocsError("NEBO-RF166-G159-IO", "output parent must be a real directory")
    if path.exists() and (path.is_symlink() or not path.is_file()):
        raise DocsError("NEBO-RF166-G159-IO", "output path must be a regular file")
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def prior_manifest(output: Path) -> dict[str, object]:
    data = read_regular(output / "manifest.json", MAX_INDEX_BYTES, "NEBO-RF166-G159-007", text=True)
    try:
        value = json.loads(data)
    except json.JSONDecodeError as error:
        raise DocsError("NEBO-RF166-G159-007", "incremental output manifest is invalid") from error
    if not isinstance(value, dict) or value.get("owner") != "NEBO-RF166-G159" or not isinstance(value.get("files"), dict):
        raise DocsError("NEBO-RF166-G159-007", "incremental output is not owned by G159")
    return value


def output_target(output: Path, name: str) -> Path:
    relative = PurePosixPath(name)
    if relative.is_absolute() or ".." in relative.parts:
        raise DocsError("NEBO-RF166-G159-IO", "generated output path is unsafe")
    current = output
    for part in relative.parts[:-1]:
        current = current / part
        if current.exists() and (current.is_symlink() or not current.is_dir()):
            raise DocsError("NEBO-RF166-G159-IO", "generated output parent is unsafe")
    target = output.joinpath(*relative.parts)
    if target.exists() and (target.is_symlink() or not target.is_file()):
        raise DocsError("NEBO-RF166-G159-IO", "generated output target is unsafe")
    return target


def planned_changes(output: Path, files: dict[str, bytes], incremental: bool) -> int:
    output = output.absolute()
    if output.is_symlink() or (output.exists() and not output.is_dir()):
        raise DocsError("NEBO-RF166-G159-IO", "documentation output must be a real directory")
    if not output.parent.is_dir() or output.parent.is_symlink():
        raise DocsError("NEBO-RF166-G159-IO", "documentation output parent must be a real directory")
    if not output.exists():
        return len(files)
    if not incremental:
        raise DocsError("NEBO-RF166-G159-007", "existing output requires --incremental")
    prior_manifest(output)
    changed = 0
    for name, data in files.items():
        target = output_target(output, name)
        changed += int(not target.is_file() or target.read_bytes() != data)
    return changed


def publish_tree(output: Path, files: dict[str, bytes], incremental: bool) -> int:
    output = output.absolute()
    changed = planned_changes(output, files, incremental)
    if not output.exists():
        temporary = Path(tempfile.mkdtemp(prefix=f".{output.name}.", dir=output.parent))
        try:
            for name, data in sorted(files.items()):
                target = temporary / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            os.replace(temporary, output)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)
        return changed
    old = prior_manifest(output)
    old_files = set(str(name) for name in old["files"])
    for name in sorted(files):
        target = output_target(output, name)
        target.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(target, files[name])
    for name in sorted(old_files - set(files)):
        candidate = output_target(output, name)
        if candidate.is_file() and not candidate.is_symlink():
            candidate.unlink()
    return changed


def tar_bytes(files: dict[str, bytes]) -> bytes:
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode="w", format=tarfile.USTAR_FORMAT) as archive:
        for name, data in sorted(files.items()):
            info = tarfile.TarInfo(name)
            info.size = len(data)
            info.mode = 0o644
            info.uid = info.gid = info.mtime = 0
            info.uname = info.gname = ""
            archive.addfile(info, io.BytesIO(data))
    return stream.getvalue()


def unpack_archive(data: bytes) -> dict[str, bytes]:
    files: dict[str, bytes] = {}
    total = 0
    try:
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:") as archive:
            members = archive.getmembers()
            if len(members) > 512:
                raise DocsError("NEBO-RF166-G159-007", "archive file-count bound exceeded")
            for member in members:
                path = PurePosixPath(member.name)
                if not member.isfile() or path.is_absolute() or ".." in path.parts or member.name in files:
                    raise DocsError("NEBO-RF166-G159-007", "archive contains an unsafe entry")
                stream = archive.extractfile(member)
                if stream is None:
                    raise DocsError("NEBO-RF166-G159-007", "archive entry is unreadable")
                payload = stream.read(MAX_ARCHIVE_BYTES + 1)
                total += len(payload)
                if total > MAX_ARCHIVE_BYTES:
                    raise DocsError("NEBO-RF166-G159-007", "archive expanded-size bound exceeded")
                files[member.name] = payload
    except (tarfile.TarError, EOFError) as error:
        raise DocsError("NEBO-RF166-G159-007", "offline documentation archive is malformed") from error
    if "manifest.json" not in files:
        raise DocsError("NEBO-RF166-G159-007", "offline archive has no manifest")
    try:
        manifest = json.loads(files["manifest.json"])
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocsError("NEBO-RF166-G159-007", "offline archive manifest is invalid") from error
    if not isinstance(manifest, dict) or manifest.get("owner") != "NEBO-RF166-G159":
        raise DocsError("NEBO-RF166-G159-007", "offline archive owner is invalid")
    expected = manifest.get("files")
    if not isinstance(expected, dict) or set(expected) != set(files) - {"manifest.json"}:
        raise DocsError("NEBO-RF166-G159-007", "offline archive manifest is incomplete")
    if any(expected[name] != sha(files[name]) for name in expected):
        raise DocsError("NEBO-RF166-G159-007", "offline archive content digest mismatch")
    return files


def load_index(path: Path) -> dict[str, object]:
    if path.is_dir() and not path.is_symlink():
        path = path / "search-index.json"
    data = read_regular(path, MAX_INDEX_BYTES, "NEBO-RF166-G159-003", text=True)
    try:
        value = json.loads(data)
    except json.JSONDecodeError as error:
        raise DocsError("NEBO-RF166-G159-003", "search index is not valid JSON") from error
    if isinstance(value, dict) and value.get("schema") == "nebo.public-docs.v1":
        return value
    if not isinstance(value, dict) or value.get("owner") != "NEBO-RF166-G159" or value.get("schema") != 1:
        raise DocsError("NEBO-RF166-G159-003", "search index schema or owner is invalid")
    return value


def documentation(paths: list[str], include_private: bool, edition: int, target: str, budget: int, verify_args: list[str] | None = None) -> tuple[dict[str, object], dict[str, bytes], dict[str, object], dict[str, object]]:
    selected, root = select_sources(paths)
    verified = verify_examples(selected, budget, verify_args)
    graph = build_graph(selected, root, include_private, edition, target)
    files, index = render(graph)
    return graph, files, index, verified


def build_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc docs")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("--edition", type=int, default=1)
    parser.add_argument("--target", default="x86_64-linux")
    parser.add_argument("--include-private", action="store_true")
    parser.add_argument("--incremental", action="store_true")
    parser.add_argument("--archive")
    parser.add_argument("--budget", type=int, default=2)
    options = parser.parse_args(arguments)
    if not 1 <= options.budget <= 64:
        raise DocsError("NEBO-RF166-G159-006", "example budget must be 1..64")
    graph, files, _index, verified = documentation(options.paths, options.include_private, options.edition, options.target, options.budget)
    output = Path(options.output)
    changed = planned_changes(output, files, options.incremental)
    flags = FLAG_OFFLINE_HTML | FLAG_PATHS_REDACTED | (FLAG_INCREMENTAL if options.incremental else 0)
    native(request(OP_CLI, graph, primary=tree_digest(files), expected=CMD_BUILD, observed=CMD_BUILD,
                   command=CMD_BUILD, flags=flags), "NEBO-RF166-G159-006")
    archive_sha = None
    payload = None
    if options.archive:
        archive_path = Path(options.archive).absolute()
        if archive_path.exists() or not archive_path.parent.is_dir() or archive_path.parent.is_symlink():
            raise DocsError("NEBO-RF166-G159-IO", "archive output must be a new file in a real directory")
        payload = tar_bytes(files)
        restored = unpack_archive(payload)
        rebuilt = tar_bytes(restored)
        if rebuilt != payload:
            raise DocsError("NEBO-RF166-G159-007", "offline archive restore is not byte-identical")
        archive_sha = sha(payload)
        native(request(OP_ARCHIVE, graph, primary=tree_digest(files), secondary=tree_digest(restored),
                       changed=changed, total=len(files), archive=fnv(payload), restore=fnv(rebuilt),
                       flags=FLAG_ARCHIVE | (FLAG_INCREMENTAL if options.incremental else 0)), "NEBO-RF166-G159-007")
    publish_tree(output, files, options.incremental)
    if payload is not None:
        atomic_write(Path(options.archive).absolute(), payload)
    print(json.dumps({
        "schema": 1, "command": "docs build", "output": Path(options.output).name,
        "graphDigest": graph["graphDigest"], "symbols": len(graph["symbols"]),
        "files": len(files), "changedNodes": changed, "archiveSha256": archive_sha,
        "verifiedExamples": verified["summary"], "offline": True,
    }, sort_keys=True, separators=(",", ":")))
    return 0


def verify_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc docs --verify")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--edition", type=int, default=1)
    parser.add_argument("--target", default="x86_64-linux")
    parser.add_argument("--include-private", action="store_true")
    parser.add_argument("--budget", type=int, default=2)
    parser.add_argument("--seed", type=int, default=159)
    parser.add_argument("--timeout-ms", type=int, default=1_000)
    parser.add_argument("--output-limit", type=int, default=1_024)
    parser.add_argument("--baseline")
    parser.add_argument("--refactor-map")
    parser.add_argument("--report", choices=("text", "json"), default="text")
    options = parser.parse_args(arguments)
    if not 1 <= options.budget <= 64:
        raise DocsError("NEBO-RF166-G159-006", "example budget must be 1..64")
    forwarded = ["--seed", str(options.seed), "--timeout-ms", str(options.timeout_ms), "--output-limit", str(options.output_limit)]
    if options.baseline:
        forwarded.extend(["--baseline", options.baseline])
    if options.refactor_map:
        forwarded.extend(["--refactor-map", options.refactor_map])
    graph, files, _index, verified = documentation(
        options.paths, options.include_private, options.edition, options.target,
        options.budget, forwarded,
    )
    native(request(OP_CLI, graph, primary=tree_digest(files), expected=CMD_VERIFY, observed=CMD_VERIFY,
                   command=CMD_VERIFY, flags=FLAG_VERIFY | FLAG_OFFLINE_HTML | FLAG_PATHS_REDACTED), "NEBO-RF166-G159-006")
    report = dict(verified)
    report["reference"] = {
        "graphDigest": graph["graphDigest"], "symbols": len(graph["symbols"]),
        "links": graph["linkCount"], "files": len(files), "brokenLinks": 0,
        "remoteDependencies": 0, "sourceMutation": False,
    }
    if options.report == "json":
        print(json.dumps(report, sort_keys=True, separators=(",", ":")))
    else:
        reference = report["reference"]
        print(f"verified={reference['symbols']} links={reference['links']} files={reference['files']} broken=0 remote=0")
    return 0


def search_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc docs search")
    parser.add_argument("query")
    parser.add_argument("--index", required=True)
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--report", choices=("text", "json"), default="text")
    options = parser.parse_args(arguments)
    if not 1 <= options.limit <= 256:
        raise DocsError("NEBO-RF166-G159-003", "search limit must be 1..256")
    index = load_index(Path(options.index))
    if index.get("schema") == "nebo.public-docs.v1":
        sys.path.insert(0, str(ROOT))
        from compiler.sdk.public_docs import search
        results = search(index, options.query, options.limit)
        if options.report == "json":
            print(json.dumps({"schema": "nebo.public-docs.v1", "query": options.query, "results": results}, sort_keys=True))
        else:
            for item in results: print(item["title"] + "\t" + item["path"])
        return 0
    results = search_results(index, options.query, options.limit)
    graph_digest = int(str(index.get("graphDigestFNV", "0")), 0)
    graph = {"graphDigestFNV": f"0x{graph_digest:016x}", "symbols": index["documents"], "modules": ["index"], "publicSymbols": len(index["documents"]), "privateSymbols": 0}
    native(request(OP_SEARCH, graph, primary=fnv(canonical(index)), query=fnv(options.query.casefold().encode()),
                   matches=len(results), budget=options.limit), "NEBO-RF166-G159-003")
    native(request(OP_CLI, graph, primary=fnv(canonical(index)), expected=CMD_SEARCH, observed=CMD_SEARCH,
                   command=CMD_SEARCH), "NEBO-RF166-G159-006")
    envelope = {"schema": 1, "command": "docs search", "query": options.query, "results": results}
    if options.report == "json":
        print(json.dumps(envelope, sort_keys=True, separators=(",", ":")))
    else:
        for item in results:
            print(f"{item['symbolId']}\t{item['title']}\t{item['module']}")
    return 0


def diff_command(arguments: list[str]) -> int:
    if len(arguments) != 2 or any(Path(item).suffix != ".ni" for item in arguments):
        raise DocsError("NEBO-RF166-G159-006", "docs diff requires <old.ni> <new.ni>")
    result = subprocess.run([str(COMPILER), "api-diff", *arguments], stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False,
                            env={"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"})
    if result.returncode not in {0, 1} or result.stderr:
        raise DocsError("NEBO-RF166-G159-006", "canonical interface compatibility rejected docs diff")
    try:
        report = json.loads(result.stdout)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocsError("NEBO-RF166-G159-006", "canonical interface diff returned invalid JSON") from error
    digest = fnv(result.stdout)
    native(request(OP_CLI, None, primary=digest, expected=CMD_DIFF, observed=CMD_DIFF, command=CMD_DIFF), "NEBO-RF166-G159-006")
    print(json.dumps({"schema": 1, "command": "docs diff", "interface": report}, sort_keys=True, separators=(",", ":")))
    return result.returncode


def serve_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc docs serve")
    parser.add_argument("directory")
    parser.add_argument("--local-only", action="store_true")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--dry-run", action="store_true")
    options = parser.parse_args(arguments)
    directory = Path(options.directory).absolute()
    if not options.local_only or not directory.is_dir() or directory.is_symlink() or not 0 <= options.port <= 65535:
        raise DocsError("NEBO-RF166-G159-008", "serve requires a real docs directory and --local-only")
    manifest = prior_manifest(directory)
    digest = fnv(canonical(manifest))
    native(request(OP_CLI, None, primary=digest, expected=CMD_SERVE, observed=CMD_SERVE,
                   command=CMD_SERVE, flags=FLAG_LOCAL_ONLY), "NEBO-RF166-G159-006")
    if options.dry_run:
        print(json.dumps({"schema": 1, "command": "docs serve", "bind": "127.0.0.1", "port": options.port, "dryRun": True}, sort_keys=True, separators=(",", ":")))
        return 0
    handler = lambda *values, **keywords: SimpleHTTPRequestHandler(*values, directory=str(directory), **keywords)
    with ThreadingHTTPServer(("127.0.0.1", options.port), handler) as server:
        print(f"serving local documentation on http://127.0.0.1:{server.server_port}", flush=True)
        server.serve_forever()
    return 0


def restore_command(arguments: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="neboc docs restore")
    parser.add_argument("archive")
    parser.add_argument("-o", "--output", required=True)
    options = parser.parse_args(arguments)
    payload = read_regular(Path(options.archive), MAX_ARCHIVE_BYTES, "NEBO-RF166-G159-007")
    files = unpack_archive(payload)
    rebuilt = tar_bytes(files)
    try:
        restored_index = json.loads(files["search-index.json"])
    except (KeyError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise DocsError("NEBO-RF166-G159-007", "restored search index is invalid") from error
    if not isinstance(restored_index, dict) or restored_index.get("owner") != "NEBO-RF166-G159":
        raise DocsError("NEBO-RF166-G159-007", "restored search index owner is invalid")
    graph = {
        "graphDigestFNV": str(restored_index["graphDigestFNV"]),
        "symbols": restored_index["documents"], "modules": ["restored"],
        "publicSymbols": len(restored_index["documents"]), "privateSymbols": 0,
    }
    native(request(OP_ARCHIVE, graph, primary=tree_digest(files), secondary=tree_digest(files),
                   changed=len(files), total=len(files), archive=fnv(payload), restore=fnv(rebuilt),
                   flags=FLAG_ARCHIVE), "NEBO-RF166-G159-007")
    native(request(OP_CLI, None, primary=fnv(payload), expected=CMD_RESTORE, observed=CMD_RESTORE,
                   command=CMD_RESTORE), "NEBO-RF166-G159-006")
    publish_tree(Path(options.output), files, False)
    print(json.dumps({"schema": 1, "command": "docs restore", "files": len(files), "archiveSha256": sha(payload)}, sort_keys=True, separators=(",", ":")))
    return 0


def main(arguments: list[str]) -> int:
    if len(arguments) < 2 or arguments[0] != "docs":
        raise DocsError("NEBO-RF166-G159-006", "expected neboc docs command")
    rest = arguments[1:]
    if rest[0] == "portal":
        sys.path.insert(0, str(ROOT))
        from compiler.sdk.public_docs import main as public_main
        return public_main(rest[1:])
    if rest[0] == "factory":
        # One factory owner also serves the existing script entry point.
        sys.path.insert(0, str(ROOT))
        from scripts.rf204.doc_factory import canonical_command
        return canonical_command(rest[1:])
    if rest[0] == "--verify":
        return verify_command(rest[1:])
    if rest[0] == "build":
        return build_command(rest[1:])
    if rest[0] == "search":
        return search_command(rest[1:])
    if rest[0] == "diff":
        return diff_command(rest[1:])
    if rest[0] == "serve":
        return serve_command(rest[1:])
    if rest[0] == "restore":
        return restore_command(rest[1:])
    return build_command(rest)


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (DocsError, OSError, ValueError, subprocess.TimeoutExpired) as error:
        code = getattr(error, "code", "NEBO-RF166-G159-IO")
        print(f"{code}: {error}; note=no local documentation artifact was published", file=sys.stderr)
        raise SystemExit(1)
