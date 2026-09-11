#!/usr/bin/env bash
    set -euo pipefail
    source "${NEBO_REPO_ROOT:?}/scripts/mf063/release-case-lib.sh"
    report="$MF063_PACKAGE_DIR/BINARY-INSPECTION.json"
    mf063_require_file "$report"

    python3 -B - "$report" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
expected={
    "schema":"NEBO-MF063-BINARY-INSPECTION-v1.0",
    "verdict":"PACKAGE_NO_C_LIBC_GREEN",
    "single_root":"nebo-v0.1.0-rc.1",
    "nested_archives":0,
    "symlinks":0,
    "unsafe_paths":0,
    "c_libc_source_or_library_files":0,
    "elf_class":"ELF64",
    "machine":"x86-64",
    "pt_interp":False,
    "dynamic_needed":0,
    "undefined_symbols":0,
    "target":"x86_64-systemv-elf-linux",
}
for key,value in expected.items():
    if data.get(key)!=value:
        raise SystemExit(
            f"NEBO_RELEASE_RESTORE_004_FAIL {key}={data.get(key)!r}"
        )
print("NEBO_RELEASE_RESTORE_004_GREEN package_no_c_libc=PASS")
PY
