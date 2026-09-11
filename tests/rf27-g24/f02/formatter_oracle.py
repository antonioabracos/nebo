#!/usr/bin/env python3
"""Tracked-corpus idempotence and token-parity oracle."""
from hashlib import sha256
import importlib.util
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("rf27_formatter", ROOT / "tools/rf27-format.py")
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

paths = subprocess.check_output(
    ["git", "ls-files", "*.no"], cwd=ROOT, text=True
).splitlines()
digest = sha256()
changed = 0
for relative in paths:
    original = (ROOT / relative).read_bytes()
    formatted = module.canonicalize(original)
    repeated = module.canonicalize(formatted)
    if formatted != repeated:
        raise SystemExit(f"FORMATTER_IDEMPOTENCE_RED:{relative}")
    # Control-header migration is an intentional syntax rewrite.  After that
    # authenticated transform, the formatter may only normalize whitespace.
    migrated = module.canonicalize_control_headers(original)
    if b"".join(migrated.split()) != b"".join(formatted.split()):
        raise SystemExit(f"FORMATTER_TOKEN_PARITY_RED:{relative}")
    changed += formatted != original
    digest.update(relative.encode())
    digest.update(b"\0")
    digest.update(formatted)
print(
    f"RF27_G24_F02_CORPUS=PASS files={len(paths)} changed={changed} "
    f"idempotent={len(paths)} token_parity={len(paths)} digest={digest.hexdigest()}"
)
