#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path
import subprocess
import tempfile

from compiler.api.compiler_api import Compiler, CompilerApiError


ROOT = Path(__file__).resolve().parents[2]
NEBOC = ROOT / "build/bin/neboc"
SOURCE = ROOT / "examples/evolution/g03/numeric-safety-foundation.no"


def session_result() -> tuple[bytes, bytes, str]:
    with Compiler.new({"neboc": NEBOC, "target": Compiler.TARGET}, frozenset({"compile"})) as compiler:
        module = compiler.add_source("numeric.no", SOURCE.read_text(encoding="utf-8"))
        parsed = compiler.parse(module)
        checked = compiler.check(module)
        lowered = compiler.lower(module)
        assert parsed.module == module and parsed.diagnostics == ()
        assert checked.parsed.module == module
        assert lowered.checked.parsed.module == module and lowered.assembly.startswith(b"bits 64")
        assembly = compiler.emit_assembly(module)
        obj = compiler.emit_object(module)
        linked = compiler.link([obj])
        assert linked[:4] == b"\x7fELF"
        artifact = compiler._root / "audit-linked.elf"
        artifact.write_bytes(linked)
        program_headers = subprocess.run(
            ["readelf", "-W", "-l", str(artifact)], check=True,
            stdout=subprocess.PIPE, text=True,
        ).stdout
        assert "INTERP" not in program_headers
        assert "GNU_STACK" in program_headers and "RWE" not in program_headers
        undefined = subprocess.run(
            ["nm", "-u", str(artifact)], check=True,
            stdout=subprocess.PIPE, text=True,
        ).stdout
        assert undefined == ""
        report = compiler.report()
        assert "timing-model=DETERMINISTIC_PHASE_INVOCATION_COUNTS" in report
        assert "memory-source-bytes=" in report
        assert "cache-policy=SESSION_LOCAL_NO_CROSS_SESSION_CACHE" in report
        assert "diagnostic-count=0" in report
        return assembly, obj, report


def main() -> None:
    first = session_result()
    second = session_result()
    assert first == second
    with tempfile.TemporaryDirectory(prefix="rf46-cli-parity.") as tmp:
        expected = Path(tmp) / "expected.asm"
        subprocess.run([str(NEBOC), "emit-asm", str(SOURCE), "-o", str(expected)], check=True)
        assert first[0] == expected.read_bytes()
    with Compiler(NEBOC) as compiler:
        module = compiler.add_source("negative.no", "fn main() -> I32 { missing }\n")
        try:
            compiler.check(module)
        except CompilerApiError as error:
            assert error.diagnostic == "NG46_F0103"
        else:
            raise AssertionError("invalid source accepted")
        with tempfile.TemporaryDirectory(prefix="rf46-self-check.") as source_tree:
            self_source = Path(source_tree) / "compiler-module.no"
            self_source.write_text(SOURCE.read_text(encoding="utf-8"), encoding="utf-8")
            assert len(compiler.selfCheck(Path(source_tree))) == 1
        compiler.cancel()
        try:
            compiler.report()
            compiler.check(module)
        except CompilerApiError as error:
            assert error.diagnostic == "NG46_F0103"
        else:
            raise AssertionError("cancelled session remained active")
    print(f"RF46_G46_F01_ORACLE_GREEN asm={hashlib.sha256(first[0]).hexdigest()} object={hashlib.sha256(first[1]).hexdigest()} parse=yes lower=yes self_check=yes")


if __name__ == "__main__":
    main()
