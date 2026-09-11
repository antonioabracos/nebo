#!/usr/bin/env python3
"""Bounded local Nebo LSP over stdio only."""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from compiler.sdk.text_tooling import SemanticTokenInterpolation
from compiler.sdk.token_tooling import TokenModel, TokenToolError
from compiler.sdk.comment_tooling import CommentModel, CommentToolError
from compiler.sdk.operator_tooling import (
    OperatorRegistry,
    OperatorToolError,
    lsp_payload as operator_lsp_payload,
    operator_markdown,
)

MAX_MESSAGE = 1_048_576
MAX_DOCUMENT = 1_048_576
MAX_DOCUMENTS = 64
MAX_RESULTS = 256
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
MODULE_DECL = re.compile(r"(?m)^\s*module\s+[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)*\s*;")
KEYWORDS = {"start", "return", "if", "else", "while", "for", "in", "loop", "break", "continue", "true", "false"}
COMPLETION_OWNER = "NEBO-RF166-G161"
COMPLETION_TOOL = ROOT / "tools/rf204-g161.py"
NAVIGATION_OWNER = "NEBO-RF166-G162"
NAVIGATION_TOOL = ROOT / "tools/rf204-g162.py"


class ProtocolError(Exception):
    pass


@dataclass
class Document:
    uri: str
    text: str
    version: int


def read_frame() -> dict | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline(8193)
        if not line:
            return None if not headers else (_ for _ in ()).throw(ProtocolError("truncated headers"))
        if len(line) > 8192:
            raise ProtocolError("header line too large")
        if line in (b"\r\n", b"\n"):
            break
        try:
            name, value = line.decode("ascii").split(":", 1)
        except (UnicodeDecodeError, ValueError) as exc:
            raise ProtocolError("malformed header") from exc
        name = name.strip().lower()
        if name in headers or len(headers) >= 16:
            raise ProtocolError("duplicate header or header budget exceeded")
        headers[name] = value.strip()
    try:
        length = int(headers["content-length"])
    except (KeyError, ValueError) as exc:
        raise ProtocolError("invalid Content-Length") from exc
    if not (0 <= length <= MAX_MESSAGE):
        raise ProtocolError("message budget exceeded")
    body = sys.stdin.buffer.read(length)
    if len(body) != length:
        raise ProtocolError("truncated body")
    try:
        def unique(pairs):
            result = {}
            for key, value in pairs:
                if key in result: raise ProtocolError("duplicate JSON key")
                result[key] = value
            return result
        value = json.loads(body, object_pairs_hook=unique,
                           parse_constant=lambda _: (_ for _ in ()).throw(ProtocolError("nonfinite JSON")))
    except (UnicodeDecodeError, json.JSONDecodeError, RecursionError) as exc:
        raise ProtocolError("invalid JSON") from exc
    if not isinstance(value, dict) or value.get("jsonrpc") != "2.0":
        raise ProtocolError("JSON-RPC 2.0 object required")
    if not isinstance(value.get("method"), str) or not value["method"]:
        raise ProtocolError("method required")
    if "id" in value and type(value["id"]) not in (str, int):
        raise ProtocolError("request id must be a string or integer")
    if value.get("params") is not None and not isinstance(value["params"], dict):
        raise ProtocolError("object params required")
    return value


def write_frame(value: dict) -> None:
    body = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    if len(body) > MAX_MESSAGE:
        raise ProtocolError("response budget exceeded")
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    sys.stdout.buffer.flush()


def uri_path(uri: str) -> Path:
    if not isinstance(uri, str): raise ProtocolError("file URI must be a string")
    parsed = urlparse(uri)
    if parsed.scheme != "file" or parsed.netloc not in ("", "localhost"):
        raise ProtocolError("only local file URIs are accepted")
    if parsed.query or parsed.fragment or not parsed.path.startswith("/") or "\0" in unquote(parsed.path):
        raise ProtocolError("absolute local file URI required")
    return Path(unquote(parsed.path))


def line_bounds(text: str, line: int) -> tuple[int, int]:
    if line < 0:
        raise ProtocolError("negative line")
    lines = text.splitlines(keepends=True)
    if line >= len(lines):
        if line == 0 and not lines:
            return 0, 0
        raise ProtocolError("line outside document")
    start = sum(len(item) for item in lines[:line])
    return start, start + len(lines[line].rstrip("\r\n"))


def position_offset(text: str, position: dict, encoding: str) -> int:
    start, end = line_bounds(text, int(position["line"]))
    units = int(position["character"])
    if units < 0:
        raise ProtocolError("negative character")
    if encoding == "utf-8":
        consumed = 0
        for index, char in enumerate(text[start:end]):
            if consumed == units:
                return start + index
            consumed += len(char.encode("utf-8"))
        if consumed == units:
            return end
    else:
        consumed = 0
        for index, char in enumerate(text[start:end]):
            if consumed == units:
                return start + index
            consumed += len(char.encode("utf-16-le")) // 2
        if consumed == units:
            return end
    raise ProtocolError("character splits or exceeds line")


def offset_position(text: str, offset: int, encoding: str) -> dict:
    prefix = text[:offset]
    line = prefix.count("\n")
    column_text = prefix.rsplit("\n", 1)[-1]
    character = len(column_text.encode("utf-8")) if encoding == "utf-8" else len(column_text.encode("utf-16-le")) // 2
    return {"line": line, "character": character}


def byte_offset_position(text: str, offset: int, encoding: str) -> dict:
    """Translate a compiler byte offset without splitting a UTF-8 scalar."""
    encoded = text.encode("utf-8")
    if not (0 <= offset <= len(encoded)):
        raise ProtocolError("compiler span outside document")
    try:
        character_offset = len(encoded[:offset].decode("utf-8"))
    except UnicodeDecodeError as exc:
        raise ProtocolError("compiler span splits UTF-8 scalar") from exc
    return offset_position(text, character_offset, encoding)


def byte_offset_character(text: str, offset: int) -> int:
    encoded = text.encode("utf-8")
    if not (0 <= offset <= len(encoded)):
        raise ProtocolError("compiler span outside document")
    try:
        return len(encoded[:offset].decode("utf-8"))
    except UnicodeDecodeError as exc:
        raise ProtocolError("compiler span splits UTF-8 scalar") from exc


def word_at(document: Document, position: dict, encoding: str) -> tuple[str, int, int]:
    offset = position_offset(document.text, position, encoding)
    for match in IDENT.finditer(document.text):
        if match.start() <= offset <= match.end():
            return match.group(), match.start(), match.end()
    raise ProtocolError("no identifier at position")


class Server:
    def __init__(self, compiler: Path):
        self.compiler = compiler
        self.operator_registry = OperatorRegistry()
        self.documents: dict[str, Document] = {}
        self.canceled: set[object] = set()
        self.encoding = "utf-16"
        self.shutdown = False
        self.workspace: Path | None = None
        self.completion_cache: dict[str, dict] = {}

    @staticmethod
    def comment_model(document: Document) -> CommentModel:
        return CommentModel.scan(document.text.encode("utf-8"))

    def comment_character_ranges(self, document: Document) -> tuple[tuple[int, int], ...]:
        return tuple(
            (byte_offset_character(document.text, item.start),
             byte_offset_character(document.text, item.end))
            for item in self.comment_model(document).outer_comments
        )

    def operator_at(self, document: Document, position: dict):
        offset = position_offset(document.text, position, self.encoding)
        byte_offset = len(document.text[:offset].encode("utf-8"))
        if self.comment_model(document).contains(byte_offset) is not None:
            return None
        return self.operator_registry.operator_at(document.text, offset)

    def operator_facts(self, document: Document, position: dict) -> tuple[dict, int, int] | None:
        match = self.operator_at(document, position)
        if match is None:
            return None
        entry, start, end = match
        start_byte = len(document.text[:start].encode("utf-8"))
        end_byte = len(document.text[:end].encode("utf-8"))
        return self.operator_registry.diagnostic(entry["id"], start=start_byte, end=end_byte), start, end

    def active_word_at(self, document: Document, position: dict) -> tuple[str, int, int]:
        character = position_offset(document.text, position, self.encoding)
        byte_offset = len(document.text[:character].encode("utf-8"))
        if self.comment_model(document).contains(byte_offset) is not None:
            raise ProtocolError("comment trivia has no semantic symbol")
        return word_at(document, position, self.encoding)

    def diagnostics(self, document: Document) -> list[dict]:
        encoded = document.text.encode("utf-8")
        if len(encoded) > MAX_DOCUMENT:
            return [{"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 0}},
                     "severity": 1, "code": "NEBO-LSP-LIMIT-001", "source": "neboc",
                     "message": "document exceeds 1 MiB"}]
        with tempfile.TemporaryDirectory(prefix="rf27-g24-lsp-") as temp:
            path = Path(temp) / "snapshot.no"
            path.write_bytes(encoded)
            result = subprocess.run([str(self.compiler), "check", str(path),
                                     "--message-format", "json-lines", "--color", "never",
                                     "--path-style", "workspace"], stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=30)
        if result.returncode == 0:
            return []
        diagnostics: list[dict] = []
        severity_map = {1: 1, 2: 2, 3: 3, 4: 1, 5: 4}
        for raw_line in result.stderr.decode("utf-8", "strict").splitlines():
            if not raw_line.strip():
                continue
            try:
                payload = json.loads(raw_line)
            except json.JSONDecodeError as exc:
                raise ProtocolError("neboc returned malformed diagnostic JSON") from exc
            if isinstance(payload.get("diagnostic"), dict):
                payload = payload["diagnostic"]
            primary = payload.get("primary") or {}
            start_byte = int(primary.get("start", 0))
            end_byte = int(primary.get("end", start_byte))
            start = byte_offset_position(document.text, start_byte, self.encoding)
            end = byte_offset_position(document.text, end_byte, self.encoding)
            severity = int(payload.get("severity", 1))
            code = str(payload.get("code") or "NEBO-LSP-COMPILER-OUTPUT-001")
            message = str(payload.get("message") or payload.get("messageKey") or code)
            diagnostics.append({
                "range": {"start": start, "end": end},
                "severity": severity_map.get(severity, 1),
                "code": code,
                "source": "neboc",
                "message": message[:4096],
                "data": {
                    "schema": int(payload.get("schema", 1)),
                    "category": int(payload.get("category", 0)),
                    "phase": int(payload.get("phase", 0)),
                    "sourceId": int(primary.get("sourceId", 0)),
                    "spanStart": start_byte,
                    "spanEnd": end_byte,
                    "messageKey": str(payload.get("messageKey") or ""),
                },
            })
            if len(diagnostics) >= MAX_RESULTS:
                break
        if diagnostics:
            return diagnostics
        return [{"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 0}},
                 "severity": 1, "code": "NEBO-LSP-COMPILER-OUTPUT-001", "source": "neboc",
                 "message": f"neboc exited with status {result.returncode} without a diagnostic payload"}]

    def publish(self, document: Document) -> dict:
        return {"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
                "params": {"uri": document.uri, "version": document.version,
                           "diagnostics": self.diagnostics(document)}}

    def document(self, params: dict) -> Document:
        uri = params["textDocument"]["uri"]
        if uri not in self.documents:
            raise ProtocolError("document not open")
        return self.documents[uri]

    def completion_report(self, document: Document, position: dict, resolve_id: str | None = None) -> dict:
        character_offset = position_offset(document.text, position, self.encoding)
        path = uri_path(document.uri)
        command = [sys.executable, "-B", "-S", str(COMPLETION_TOOL),
                   "_lsp-resolve" if resolve_id else "_lsp", str(path),
                   str(character_offset), str(path.parent)]
        if resolve_id:
            command.append(resolve_id)
        result = subprocess.run(
            command,
            input=document.text.encode("utf-8"), stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=35,
            env={"LC_ALL": "C", "HOME": os.environ.get("HOME", str(path.parent)), "PYTHONDONTWRITEBYTECODE": "1"},
        )
        try:
            report = json.loads(result.stdout) if result.returncode == 0 and not result.stderr else None
        except (UnicodeError, json.JSONDecodeError):
            report = None
        if not isinstance(report, dict) or report.get("owner") != COMPLETION_OWNER:
            raise ProtocolError("semantic completion was not available for this snapshot")
        return report

    def completion_items(self, document: Document, position: dict) -> dict:
        report = self.completion_report(document, position)
        kinds = {"method": 2, "function": 3, "field": 5, "constant": 21, "keyword": 14}
        items: list[dict] = []
        for ordinal, candidate in enumerate(report.get("candidates", [])[:MAX_RESULTS]):
            item_id = str(candidate["itemId"])
            data = {
                "owner": COMPLETION_OWNER, "itemId": item_id,
                "symbolId": candidate["symbolId"],
                "revision": report["snapshot"]["sha256"],
                "uri": document.uri, "version": document.version,
            }
            item = {
                "label": candidate["name"],
                "kind": kinds.get(str(candidate.get("kind")), 1),
                "sortText": f"{ordinal:04d}:{candidate['name']}",
                "filterText": candidate["name"],
                "insertText": candidate["name"],
                "data": data,
            }
            cache_key = f"{document.uri}\0{item_id}"
            self.completion_cache[cache_key] = {
                "item": item, "data": data, "position": dict(position),
            }
            items.append(item)
        while len(self.completion_cache) > MAX_RESULTS:
            del self.completion_cache[next(iter(self.completion_cache))]
        return {"isIncomplete": False, "items": items}

    def resolve_completion(self, item: dict) -> dict:
        data = item.get("data") if isinstance(item, dict) else None
        if not isinstance(data, dict) or data.get("owner") != COMPLETION_OWNER:
            raise ProtocolError("completion item is not owned by G161")
        cache_key = f"{data.get('uri')}\0{data.get('itemId')}"
        cached = self.completion_cache.get(cache_key)
        document = self.documents.get(str(data.get("uri")))
        if cached is None or document is None or document.version != data.get("version"):
            raise ProtocolError("completion item is stale or unknown")
        revision = hashlib.sha256(document.text.encode("utf-8")).hexdigest()
        if revision != data.get("revision") or cached["data"] != data:
            raise ProtocolError("completion item revision does not match the open snapshot")
        report = self.completion_report(document, cached["position"], str(data["itemId"]))
        candidate = report.get("resolved")
        if not isinstance(candidate, dict) or candidate.get("itemId") != data["itemId"]:
            raise ProtocolError("completion resolve diverged from the cached semantic identity")
        resolved = dict(cached["item"])
        resolved["detail"] = candidate["signature"]
        resolved["documentation"] = {"kind": "markdown", "value": candidate["documentation"]}
        if candidate.get("autoImport") and candidate.get("module"):
            declaration = MODULE_DECL.search(document.text)
            if declaration is not None:
                insertion = offset_position(document.text, declaration.end(), self.encoding)
                module = str(candidate["module"])
                symbol = str(candidate["name"])
                alias = module.rsplit(".", 1)[-1]
                resolved["additionalTextEdits"] = [{
                    "range": {"start": insertion, "end": insertion},
                    "newText": f'\nimport "{module}" {{ {symbol}; }}.{alias};',
                }]
        return resolved

    def locations(self, document: Document, word: str) -> list[dict]:
        result = []
        comments = self.comment_character_ranges(document)
        for match in IDENT.finditer(document.text):
            inside_comment = any(start <= match.start() < end for start, end in comments)
            if match.group() == word and not inside_comment:
                result.append({"uri": document.uri, "range": {"start": offset_position(document.text, match.start(), self.encoding),
                                                               "end": offset_position(document.text, match.end(), self.encoding)}})
                if len(result) >= MAX_RESULTS:
                    break
        return result

    def navigation_report(self, document: Document, position: dict, action: str,
                          new_name: str | None = None) -> dict:
        character = position_offset(document.text, position, self.encoding)
        path = uri_path(document.uri).absolute()
        command = [sys.executable, "-B", "-S", str(NAVIGATION_TOOL), "_lsp", action,
                   str(path), str(character), str(path.parent)]
        if new_name is not None:
            command.append(new_name)
        result = subprocess.run(
            command, input=document.text.encode("utf-8"), stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=35,
            env={"LC_ALL": "C", "HOME": os.environ.get("HOME", str(path.parent)), "PYTHONDONTWRITEBYTECODE": "1"},
        )
        try:
            report = json.loads(result.stdout) if result.returncode == 0 and not result.stderr else None
        except (UnicodeError, json.JSONDecodeError):
            report = None
        if not isinstance(report, dict) or report.get("owner") != NAVIGATION_OWNER:
            detail = result.stderr.decode("utf-8", "replace").strip()[:512]
            raise ProtocolError(detail or "semantic navigation was not available for this snapshot")
        return report

    def navigation_location(self, document: Document, item: dict) -> dict:
        synthetic_uri = item.get("uri")
        if item.get("synthetic") and isinstance(synthetic_uri, str):
            zero = {"line": 0, "character": 0}
            return {"uri": synthetic_uri, "range": {"start": zero, "end": zero}}
        current = uri_path(document.uri).absolute()
        path = (current.parent / str(item["path"])).absolute()
        if path == current:
            text = document.text
        else:
            try:
                text = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as exc:
                raise ProtocolError("semantic location source is unavailable") from exc
        start = byte_offset_position(text, int(item["startByte"]), self.encoding)
        end = byte_offset_position(text, int(item["endByte"]), self.encoding)
        return {"uri": path.as_uri(), "range": {"start": start, "end": end}}

    def formatted(self, document: Document) -> str:
        encoded = document.text.encode("utf-8")
        with tempfile.TemporaryDirectory(prefix="rf27-g164-lsp-format-") as temp:
            path = Path(temp) / "snapshot.no"
            path.write_bytes(encoded)
            result = subprocess.run(
                [str(self.compiler), "format", str(path), "--preserve-comments", "--stdout"],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                check=False, timeout=15,
            )
        if result.returncode != 0:
            raise ProtocolError("canonical formatter rejected document")
        return result.stdout.decode("utf-8", "strict")

    def workspace_symbols(self, query: str) -> list[dict]:
        if self.workspace is None:
            raise ProtocolError("workspace/symbol requires initialize.rootUri")
        if not isinstance(query, str) or len(query.encode()) > 256:
            raise ProtocolError("symbol query budget exceeded")
        if any(doc.text != uri_path(uri).read_text(encoding="utf-8")
               for uri, doc in self.documents.items() if uri_path(uri).is_relative_to(self.workspace)):
            raise ProtocolError("save open documents before querying the project index")
        command = [str(self.compiler), "symbols", str(self.workspace), "--json"]
        if query: command += ["--name", query]
        result = subprocess.run(command, capture_output=True, timeout=35)
        if result.returncode or result.stderr:
            raise ProtocolError("native project symbol index rejected the workspace")
        report = json.loads(result.stdout)
        if report.get("owner") != "NEBO-RF166-G160":
            raise ProtocolError("project index owner mismatch")
        symbols = []
        for item in report["results"][:MAX_RESULTS]:
            source = item.get("source")
            if source is None: continue
            path = (self.workspace / source["path"]).resolve(strict=True)
            if not path.is_relative_to(self.workspace): raise ProtocolError("index location outside workspace")
            raw = path.read_bytes()
            if len(raw) > MAX_DOCUMENT or hashlib.sha256(raw).hexdigest() != source["sha256"]:
                raise ProtocolError("index source changed during query")
            text = raw.decode("utf-8")
            start, end = source["span"]
            symbols.append({"name": item["name"], "kind": {"function": 12, "module": 2, "type": 5}.get(item["kind"], 13),
                "location": {"uri": path.as_uri(), "range": {
                    "start": byte_offset_position(text, start, self.encoding),
                    "end": byte_offset_position(text, end, self.encoding)}},
                "data": {"symbolId": item["symbolId"], "docs": item["docs"], "revision": report["revision"]}})
        return symbols

    def handle(self, message: dict) -> tuple[dict | None, list[dict]]:
        method, params = message.get("method"), message.get("params") or {}
        request_id = message.get("id")
        notifications: list[dict] = []
        if self.shutdown and method != "exit":
            raise ProtocolError("server has shut down")
        if method == "initialize":
            capabilities = params.get("capabilities", {})
            if not isinstance(capabilities, dict): raise ProtocolError("capabilities must be an object")
            general = capabilities.get("general", {})
            if not isinstance(general, dict): raise ProtocolError("general capabilities must be an object")
            encodings = general.get("positionEncodings", [])
            if not isinstance(encodings, list) or any(not isinstance(e, str) for e in encodings):
                raise ProtocolError("position encodings must be an array of strings")
            root_uri = params.get("rootUri")
            workspace = None
            if root_uri is not None:
                workspace = uri_path(root_uri).resolve(strict=True)
                if not workspace.is_dir(): raise ProtocolError("workspace is not a directory")
            self.workspace = workspace
            self.encoding = "utf-8" if "utf-8" in encodings else "utf-16"
            result = {"capabilities": {"positionEncoding": self.encoding, "textDocumentSync": 1,
                      "completionProvider": {"triggerCharacters": ["."], "resolveProvider": True},
                      "workspaceSymbolProvider": True,
                      "hoverProvider": True, "definitionProvider": True,
                      "referencesProvider": True, "renameProvider": True,
                      "signatureHelpProvider": {"triggerCharacters": ["(", ","]},
                      "documentFormattingProvider": True, "codeActionProvider": True,
                      "foldingRangeProvider": True, "selectionRangeProvider": True,
                      "semanticTokensProvider": {"legend": {"tokenTypes": ["keyword", "function", "variable", "interpolation", "operator", "comment", "string", "interpolationDelimiter", "formatProfile", "number"],
                      "tokenModifiers": ["unicodeAlias", "domainGated", "inactive"]}, "full": True},
                      "experimental": {"neboOperatorInfo": {"schema": 1, "registryRows": 185}}}}
        elif method == "initialized":
            return None, notifications
        elif method == "shutdown":
            self.shutdown = True; result = None
        elif method == "exit":
            return None, notifications
        elif method == "$/cancelRequest":
            ident = params.get("id")
            if type(ident) not in (str, int): raise ProtocolError("invalid cancellation id")
            if len(self.canceled) >= MAX_RESULTS: raise ProtocolError("cancellation budget exceeded")
            self.canceled.add(ident); return None, notifications
        elif method == "textDocument/didOpen":
            item = params["textDocument"]; uri_path(item["uri"])
            text = item["text"]
            if not isinstance(text, str) or type(item["version"]) is not int:
                raise ProtocolError("document text must be a string and version an integer")
            if len(self.documents) >= MAX_DOCUMENTS or len(text.encode()) > MAX_DOCUMENT:
                raise ProtocolError("document budget exceeded")
            document = Document(item["uri"], text, int(item["version"]))
            notification = self.publish(document)
            self.completion_cache = {key: value for key, value in self.completion_cache.items()
                                     if value["data"]["uri"] != item["uri"]}
            self.documents[item["uri"]] = document; notifications.append(notification)
            return None, notifications
        elif method == "textDocument/didClose":
            uri = params["textDocument"]["uri"]; uri_path(uri)
            self.documents.pop(uri, None)
            self.completion_cache = {key: value for key, value in self.completion_cache.items()
                                     if value["data"]["uri"] != uri}
            notifications.append({"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
                                  "params": {"uri": uri, "diagnostics": []}})
            return None, notifications
        elif method == "textDocument/didChange":
            document = self.document(params); version = params["textDocument"]["version"]
            if type(version) is not int: raise ProtocolError("document version must be an integer")
            if version <= document.version:
                return None, notifications
            changes = params["contentChanges"]
            if not isinstance(changes, list) or len(changes) != 1 or not isinstance(changes[0], dict) or "range" in changes[0]:
                raise ProtocolError("only bounded full snapshot sync is accepted")
            text = changes[0]["text"]
            if not isinstance(text, str): raise ProtocolError("document text must be a string")
            if len(text.encode()) > MAX_DOCUMENT:
                raise ProtocolError("document budget exceeded")
            replacement = Document(document.uri, text, version)
            notification = self.publish(replacement)
            self.completion_cache = {key: value for key, value in self.completion_cache.items()
                                     if value["data"]["uri"] != document.uri}
            self.documents[document.uri] = replacement; notifications.append(notification)
            return None, notifications
        elif request_id in self.canceled:
            self.canceled.remove(request_id)
            return {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32800, "message": "request cancelled"}}, notifications
        elif method == "textDocument/completion":
            document = self.document(params)
            result = self.completion_items(document, params["position"])
        elif method == "workspace/symbol":
            result = self.workspace_symbols(params.get("query", ""))
        elif method == "completionItem/resolve":
            result = self.resolve_completion(params)
        elif method == "textDocument/hover":
            document = self.document(params)
            operator = self.operator_facts(document, params["position"])
            if operator is None:
                report = self.navigation_report(document, params["position"], "hover")
                hover = report["hover"]
                active = hover.get("activeRange") or [0, 0]
                details = [f"```nebo\n{hover['signature']}\n```"]
                if hover.get("documentation"):
                    details.append(str(hover["documentation"]))
                details.append(f"SymbolId: `{hover['symbolId']}` · origin: `{hover['origin']}`")
                result = {"contents": {"kind": "markdown", "value": "\n\n".join(details)},
                          "range": {"start": offset_position(document.text, int(active[0]), self.encoding),
                                    "end": offset_position(document.text, int(active[1]), self.encoding)},
                          "data": {"owner": NAVIGATION_OWNER, "symbolId": hover["symbolId"],
                                   "effects": hover["effects"], "capabilities": hover["capabilities"],
                                   "risks": hover["risks"], "relatedDocs": hover["relatedDocs"]}}
            else:
                facts, start, end = operator
                result = {"contents": {"kind": "markdown", "value": operator_markdown(facts)},
                          "range": {"start": offset_position(document.text, start, self.encoding),
                                    "end": offset_position(document.text, end, self.encoding)},
                          "data": {"operator": facts}}
        elif method == "textDocument/signatureHelp":
            document = self.document(params)
            operator = self.operator_facts(document, params["position"])
            result = (self.navigation_report(document, params["position"], "signature-help")["signatureHelp"]
                      if operator is None else operator_lsp_payload(operator[0])["signatureHelp"])
        elif method == "nebo/operatorInfo":
            identifier = str(params["registryId"])
            source_id = int(params.get("sourceId", 0))
            start = int(params.get("start", 0))
            end = int(params.get("end", start))
            facts = self.operator_registry.diagnostic(identifier, source_id=source_id, start=start, end=end)
            result = operator_lsp_payload(facts)
        elif method in {"textDocument/definition", "textDocument/references"}:
            document = self.document(params)
            operator = self.operator_facts(document, params["position"])
            if operator is None:
                action = "definition" if method.endswith("definition") else "references"
                report = self.navigation_report(document, params["position"], action)
                raw = [report["definition"]] if action == "definition" else report["references"]
                result = [self.navigation_location(document, item) for item in raw]
            else:
                location = operator_lsp_payload(operator[0])["definition"]
                result = [location]
        elif method == "textDocument/rename":
            document = self.document(params); new = str(params["newName"])
            report = self.navigation_report(document, params["position"], "rename", new)
            changes: dict[str, list[dict]] = {}
            for item in report["plan"]["edits"]:
                target = self.navigation_location(document, item)
                changes.setdefault(target["uri"], []).append({
                    "range": target["range"], "newText": new,
                    "annotationId": "g162-semantic-rename",
                })
            result = {"changes": changes, "changeAnnotations": {
                "g162-semantic-rename": {
                    "label": f"Rename {report['plan']['oldName']} by SymbolId",
                    "needsConfirmation": report["plan"]["apiImpact"] == "BREAKING",
                    "description": f"{report['plan']['apiImpact']} semantic rename; aliases are preserved",
                }
            }}
        elif method == "textDocument/semanticTokens/full":
            document = self.document(params); data = []; previous_line = previous_char = 0
            token_model = TokenModel.scan(document.text.encode("utf-8"))
            fragments = token_model.character_fragments()
            interpolations = [row for row in fragments if row["kind"] == "expression"]
            protected = [row for row in fragments if row["kind"] != "expression"]
            comment_model = self.comment_model(document)
            comment_ranges = tuple(
                (byte_offset_character(document.text, item.start),
                 byte_offset_character(document.text, item.end))
                for item in comment_model.outer_comments
            )
            tokens = []
            for match in IDENT.finditer(token_model.code_mask()):
                if any(int(row["start"]) <= match.start() < int(row["end"]) for row in protected):
                    continue
                if any(start <= match.start() < end for start, end in comment_ranges):
                    continue
                inside_interpolation = any(
                    int(item["start"]) <= match.start() and match.end() <= int(item["end"])
                    for item in interpolations
                )
                token_type = 3 if inside_interpolation else (
                    0 if match.group() in KEYWORDS else (1 if match.group() == "start" else 2)
                )
                tokens.append((match.start(), match.end(), token_type, 0))
            for entry, start, end in self.operator_registry.scan(token_model.code_mask(), MAX_RESULTS):
                if any(int(row["start"]) <= start < int(row["end"]) for row in protected):
                    continue
                if any(left <= start < right for left, right in comment_ranges):
                    continue
                modifier = {"UNICODE_ALIAS": 1, "DOMAIN_GATED": 2 | 4,
                            "RESERVED": 4, "REJECTED": 4}.get(entry["cls"], 0)
                tokens.append((start, end, 4, modifier))
            for row in protected:
                start,end = int(row['start']),int(row['end'])
                token_type = {'literal':6,'delimiter':7,'profile':8}[str(row['kind'])]
                cursor = start
                while cursor < end:
                    newline = document.text.find('\n',cursor,end)
                    line_end = end if newline < 0 else newline
                    if cursor < line_end: tokens.append((cursor,line_end,token_type,0))
                    if newline < 0: break
                    cursor = newline+1
            for row in fragments:
                if row['kind']=='expression' and row['tokenKind'] in (3,5):
                    tokens.append((int(row['start']),int(row['end']),9,0))
            for start, end in comment_ranges:
                cursor = start
                while cursor < end:
                    newline = document.text.find("\n", cursor, end)
                    line_end = end if newline < 0 else newline
                    if cursor < line_end:
                        tokens.append((cursor, line_end, 5, 0))
                    if newline < 0:
                        break
                    cursor = newline + 1
            occupied_end = -1
            for start, end, token_type, modifier in sorted(tokens)[:MAX_RESULTS]:
                if start < occupied_end:
                    continue
                occupied_end = end
                position = offset_position(document.text, start, self.encoding)
                line, char = position["line"], position["character"]
                length = (len(document.text[start:end].encode("utf-8")) if self.encoding == "utf-8"
                          else len(document.text[start:end].encode("utf-16-le")) // 2)
                data.extend([line - previous_line, char - previous_char if line == previous_line else char,
                             length, token_type, modifier])
                previous_line, previous_char = line, char
            result = {"data": data}
        elif method == "textDocument/foldingRange":
            document = self.document(params)
            result = []
            for item in self.comment_model(document).comments:
                if item.kind != "block" or "multiline" not in item.flag_names:
                    continue
                start = byte_offset_position(document.text, item.start, self.encoding)
                end = byte_offset_position(document.text, item.end, self.encoding)
                result.append({"startLine": start["line"], "startCharacter": start["character"],
                               "endLine": end["line"], "endCharacter": end["character"],
                               "kind": "comment"})
        elif method == "textDocument/selectionRange":
            document = self.document(params)
            model = self.comment_model(document)
            result = []
            for position in params.get("positions", []):
                character = position_offset(document.text, position, self.encoding)
                byte_offset = len(document.text[:character].encode("utf-8"))
                item = model.contains(byte_offset)
                chain = []
                while item is not None:
                    chain.append(item)
                    item = model.comments[item.parent] if item.parent is not None else None
                parent = None
                for item in reversed(chain):
                    current = {"range": {
                        "start": byte_offset_position(document.text, item.start, self.encoding),
                        "end": byte_offset_position(document.text, item.end, self.encoding),
                    }}
                    if parent is not None:
                        current["parent"] = parent
                    parent = current
                result.append(parent or {"range": {"start": position, "end": position}})
        elif method == "textDocument/formatting":
            document = self.document(params)
            formatted = self.formatted(document)
            result = [] if formatted == document.text else [{"range": {"start": {"line": 0, "character": 0},
                      "end": offset_position(document.text, len(document.text), self.encoding)}, "newText": formatted}]
        elif method == "textDocument/codeAction":
            document = self.document(params)
            formatted = self.formatted(document)
            result = []
            if formatted != document.text:
                edit = {"range": {"start": {"line": 0, "character": 0},
                                  "end": offset_position(document.text, len(document.text), self.encoding)},
                        "newText": formatted}
                result.append({"title": "Apply safe Nebo formatting", "kind": "source.fixAll.nebo",
                           "isPreferred": True, "edit": {"documentChanges": [{
                               "textDocument": {"uri": document.uri, "version": document.version},
                               "edits": [edit],
                           }]}})
            requested_range = params.get("range") or {}
            operator = self.operator_facts(document, requested_range.get("start", {"line": 0, "character": 0}))
            if operator is not None and operator[0]["action"] is not None:
                facts, start, end = operator
                action = facts["action"]
                item = {"title": f"Use canonical operator {action['replacement']}",
                        "kind": "quickfix.nebo.operator", "isPreferred": bool(action["safe"]),
                        "data": {"operator": facts, "migration": action}}
                if action["safe"]:
                    item["edit"] = {"documentChanges": [{
                        "textDocument": {"uri": document.uri, "version": document.version},
                        "edits": [{"range": {"start": offset_position(document.text, start, self.encoding),
                                            "end": offset_position(document.text, end, self.encoding)},
                                   "newText": action["replacement"]}],
                    }]}
                result.append(item)
        else:
            raise ProtocolError(f"method not supported: {method}")
        return ({"jsonrpc": "2.0", "id": request_id, "result": result} if "id" in message else None), notifications


def main() -> int:
    compiler = Path(__file__).resolve().parents[1] / "build/bin/neboc"
    if not compiler.is_file():
        print("rf27-lsp: compiler unavailable", file=sys.stderr); return 2
    server = Server(compiler)
    try:
        while True:
            message = read_frame()
            if message is None: break
            try:
                response, notifications = server.handle(message)
            except (KeyError, TypeError, ValueError, OSError, subprocess.TimeoutExpired, ProtocolError, OperatorToolError, CommentToolError, TokenToolError) as exc:
                response = ({"jsonrpc": "2.0", "id": message.get("id"),
                             "error": {"code": -32602, "message": str(exc)}} if "id" in message else None)
                notifications = []
            if response is not None: write_frame(response)
            for notification in notifications: write_frame(notification)
            if message.get("method") == "exit": break
    except ProtocolError as exc:
        print(f"rf27-lsp: {exc}", file=sys.stderr); return 2
    return 0 if server.shutdown else 1


if __name__ == "__main__":
    raise SystemExit(main())
