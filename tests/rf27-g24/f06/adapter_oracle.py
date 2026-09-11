#!/usr/bin/env python3
"""Static and protocol oracle for the environment-limited VS Code adapter."""
import hashlib
import json
from pathlib import Path
import random
import re
import struct
import sys

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[3]
source = (root / "editors/vscode/extension.js").read_text()
manifest = json.loads((root / "editors/vscode/package.json").read_text())

assert manifest["private"] is True and manifest["main"] == "./extension.js"
assert manifest.get("dependencies") is None and manifest.get("devDependencies") is None
commands = {entry["command"] for entry in manifest["contributes"]["commands"]}
assert commands == {"nebo.check", "nebo.build", "nebo.emitAsm", "nebo.format"}
for required in (
    "shell: false", "stdio: ['ignore', 'pipe', 'pipe']", "tools/rf27-lsp.py",
    "tools/rf27-format.py", "'nebo.check': ['check']", "'nebo.build': ['build']",
    "'nebo.emitAsm': ['emit-asm']", "telemetry: false", "network: false",
    "isTrusted", "MAX_FRAME = 1_048_576", "[REDACTED]"
):
    assert required in source, required
for forbidden in ("fetch(", "XMLHttpRequest", "WebSocket", "shell: true", "childProcess.exec(", "https://", "http://"):
    assert forbidden not in source, forbidden

def redact(text: str) -> str:
    return "\n".join("[REDACTED]" if re.search(r"secret|token|api[-_]?key|password", line, re.I) else line for line in text.split("\n"))

def frame(value: dict) -> bytes:
    body = json.dumps(value, separators=(",", ":")).encode()
    assert len(body) <= 1_048_576
    return f"Content-Length: {len(body)}\r\n\r\n".encode() + body

rng = random.Random(0x27_24_06)
rows = []
redactions = 0
for case in range(10_000):
    command = rng.choice(sorted(commands))
    payload = f"case={case}" if case % 7 else f"api-key=synthetic-secret-{case}"
    rendered = redact(payload)
    redactions += rendered == "[REDACTED]"
    message = {"jsonrpc": "2.0", "id": case, "method": command, "params": {"path": f"/workspace/{case}.no"}}
    encoded = frame(message)
    marker = encoded.index(b"\r\n\r\n")
    length = int(encoded[:marker].split(b":", 1)[1])
    decoded = json.loads(encoded[marker + 4: marker + 4 + length])
    assert decoded == message and length <= 1_048_576
    argv = {"nebo.check": "check", "nebo.build": "build", "nebo.emitAsm": "emit-asm", "nebo.format": "format"}[command]
    rows.append(f"{case}:{command}:{argv}:{rendered}:{length}")

digest = hashlib.sha256("\n".join(rows).encode()).hexdigest()
print(f"RF27_G24_F06_ORACLE=PASS cases=10000 redactions={redactions} frame_max=1048576 commands=4 shell=false telemetry=false network=false digest={digest}")
