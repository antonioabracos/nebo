#!/usr/bin/env python3
"""Offline, non-root Nebo SDK installer entrypoint.

The implementation is packaged under libexec and remains manifest-driven.
"""
from __future__ import annotations

import sys
from pathlib import Path


SDK_ROOT = Path(__file__).resolve().parent
MODULE_ROOT = SDK_ROOT / "libexec/nebo/modules"
if not MODULE_ROOT.is_dir():
    raise SystemExit("NEBO-INSTALL-0009 packaged lifecycle modules missing")
sys.path.insert(0, str(MODULE_ROOT))

from compiler.sdk.sdk_lifecycle import main  # noqa: E402


if __name__ == "__main__":
    main()
