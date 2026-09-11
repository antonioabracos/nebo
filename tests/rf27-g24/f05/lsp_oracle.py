#!/usr/bin/env python3
"""Deterministic stdio JSON-RPC/LSP integration oracle."""
from __future__ import annotations
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
URI = "file:///tmp/rf27-g24-lsp-fixture.no"
VALID = "start() {\n  1.value;\n  value;\n}\n"
INVALID = "start( {\n"


def frame(value: dict) -> bytes:
    body = json.dumps(value, separators=(",", ":")).encode()
    return f"Content-Length: {len(body)}\r\n\r\n".encode() + body


def parse_frames(data: bytes) -> list[dict]:
    result = []
    while data:
        header, data = data.split(b"\r\n\r\n", 1)
        length = int(dict(line.split(b": ", 1) for line in header.split(b"\r\n"))[b"Content-Length"])
        body, data = data[:length], data[length:]
        result.append(json.loads(body))
    return result


messages = [
    {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{"general":{"positionEncodings":["utf-8","utf-16"]}}}},
    {"jsonrpc":"2.0","method":"initialized","params":{}},
    {"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":URI,"languageId":"nebo","version":1,"text":VALID}}},
    {"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":URI},"position":{"line":1,"character":4}}},
    {"jsonrpc":"2.0","id":3,"method":"textDocument/hover","params":{"textDocument":{"uri":URI},"position":{"line":1,"character":5}}},
    {"jsonrpc":"2.0","id":4,"method":"textDocument/definition","params":{"textDocument":{"uri":URI},"position":{"line":2,"character":3}}},
    {"jsonrpc":"2.0","id":5,"method":"textDocument/references","params":{"textDocument":{"uri":URI},"position":{"line":2,"character":3},"context":{}}},
    {"jsonrpc":"2.0","id":6,"method":"textDocument/rename","params":{"textDocument":{"uri":URI},"position":{"line":2,"character":3},"newName":"renamed"}},
    {"jsonrpc":"2.0","id":7,"method":"textDocument/semanticTokens/full","params":{"textDocument":{"uri":URI}}},
    {"jsonrpc":"2.0","id":8,"method":"textDocument/formatting","params":{"textDocument":{"uri":URI},"options":{}}},
    {"jsonrpc":"2.0","method":"textDocument/didChange","params":{"textDocument":{"uri":URI,"version":1},"contentChanges":[{"text":INVALID}]}},
    {"jsonrpc":"2.0","method":"$/cancelRequest","params":{"id":9}},
    {"jsonrpc":"2.0","id":9,"method":"textDocument/hover","params":{"textDocument":{"uri":URI},"position":{"line":1,"character":5}}},
    {"jsonrpc":"2.0","method":"textDocument/didChange","params":{"textDocument":{"uri":URI,"version":2},"contentChanges":[{"text":INVALID}]}},
    {"jsonrpc":"2.0","id":10,"method":"shutdown","params":None},
    {"jsonrpc":"2.0","method":"exit","params":None},
]
payload = b"".join(frame(message) for message in messages)


def run() -> tuple[bytes, list[dict]]:
    process = subprocess.run([str(ROOT / "tools/rf27-lsp.py")], input=payload,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=10)
    if process.returncode != 0 or process.stderr:
        raise SystemExit(f"LSP_PROCESS_RED:{process.returncode}:{process.stderr!r}")
    return process.stdout, parse_frames(process.stdout)


raw_a, frames_a = run()
raw_b, frames_b = run()
if raw_a != raw_b:
    raise SystemExit("LSP_DETERMINISM_RED")
by_id = {item.get("id"): item for item in frames_a if "id" in item}
if by_id[1]["result"]["capabilities"]["positionEncoding"] != "utf-8":
    raise SystemExit("LSP_POSITION_ENCODING_RED")
if not by_id[2]["result"]["items"] or "compiler-admitted" not in by_id[3]["result"]["contents"]["value"]:
    raise SystemExit("LSP_COMPLETION_HOVER_RED")
if len(by_id[4]["result"]) != 1 or len(by_id[5]["result"]) != 2:
    raise SystemExit("LSP_NAVIGATION_RED")
if len(by_id[6]["result"]["changes"][URI]) != 2 or not by_id[7]["result"]["data"]:
    raise SystemExit("LSP_RENAME_TOKENS_RED")
if by_id[9]["error"]["code"] != -32800:
    raise SystemExit("LSP_CANCEL_RED")
notifications = [item for item in frames_a if item.get("method") == "textDocument/publishDiagnostics"]
if len(notifications) != 2 or notifications[0]["params"]["diagnostics"]:
    raise SystemExit("LSP_STALE_OR_VALID_DIAGNOSTICS_RED")
diagnostics = notifications[1]["params"]["diagnostics"]
if len(diagnostics) != 1:
    raise SystemExit("LSP_CLI_DIAGNOSTIC_PARITY_RED")
diagnostic = diagnostics[0]
if diagnostic["code"] != "NEBO_PARSE_UNEXPECTED_TOKEN" or diagnostic["severity"] != 1:
    raise SystemExit("LSP_CLI_DIAGNOSTIC_IDENTITY_RED")
if diagnostic["range"] != {"start": {"line": 0, "character": 0},
                            "end": {"line": 0, "character": 1}}:
    raise SystemExit("LSP_CLI_DIAGNOSTIC_SPAN_RED")
if diagnostic["message"] == "source validation failed" or diagnostic["data"]["phase"] != 4:
    raise SystemExit("LSP_CLI_DIAGNOSTIC_PAYLOAD_RED")
print(f"RF27_G24_F05_ORACLE=PASS requests={len(messages)} responses={len(frames_a)} diagnostics=2 references=2 encoding=utf-8 deterministic_bytes={len(raw_a)}")
