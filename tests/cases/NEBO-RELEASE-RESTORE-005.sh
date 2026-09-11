#!/usr/bin/env bash
    set -euo pipefail
    source "${NEBO_REPO_ROOT:?}/scripts/mf063/release-case-lib.sh"
    report="$MF063_PACKAGE_DIR/RESTORE-REPORT.json"
    mf063_require_file "$report"

    python3 -B - "$report" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
expected={
    "schema":"NEBO-MF063-RESTORE-REPORT-v1.0",
    "verdict":"CLEAN_RESTORE_REPRODUCIBLE_GREEN",
    "single_root":"nebo-v0.1.0-rc.1",
    "clean_extraction":True,
    "unsafe_paths":0,
    "symlinks":0,
    "nested_archives":0,
    "inventory_exact":True,
    "internal_checksums":"PASS",
    "source_mutation_after_build":0,
}
for key,value in expected.items():
    if data.get(key)!=value:
        raise SystemExit(
            f"NEBO_RELEASE_RESTORE_005_FAIL {key}={data.get(key)!r}"
        )
if not isinstance(data.get("content_file_count"),int) or data["content_file_count"]<1:
    raise SystemExit("NEBO_RELEASE_RESTORE_005_FAIL file count")
print(
    "NEBO_RELEASE_RESTORE_005_GREEN "
    f"clean_extraction=PASS files={data['content_file_count']}"
)
PY
