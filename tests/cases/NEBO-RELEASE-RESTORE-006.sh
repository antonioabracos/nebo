#!/usr/bin/env bash
    set -euo pipefail
    source "${NEBO_REPO_ROOT:?}/scripts/mf063/release-case-lib.sh"
    report="$MF063_PACKAGE_DIR/RESTORE-REPORT.json"
    mf063_require_file "$report"

    python3 -B - "$report" <<'PY'
import json,re,sys
data=json.load(open(sys.argv[1]))
packaged=data.get("packaged_binary_sha256","")
rebuilt=data.get("rebuilt_binary_sha256","")
if not data.get("binary_hash_equal") or packaged!=rebuilt:
    raise SystemExit("NEBO_RELEASE_RESTORE_006_FAIL hash mismatch")
if not re.fullmatch(r"[0-9a-f]{64}",packaged):
    raise SystemExit("NEBO_RELEASE_RESTORE_006_FAIL invalid hash")
if data.get("cli_version")!="0.1.0":
    raise SystemExit("NEBO_RELEASE_RESTORE_006_FAIL version")
if data.get("target")!="x86_64-systemv-elf-linux":
    raise SystemExit("NEBO_RELEASE_RESTORE_006_FAIL target")
print(
    "NEBO_RELEASE_RESTORE_006_GREEN "
    f"restored_binary_sha256={rebuilt}"
)
PY
