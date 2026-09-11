#!/usr/bin/env bash
    set -euo pipefail
    source "${NEBO_REPO_ROOT:?}/scripts/mf063/release-case-lib.sh"

    mf063_require_file "$MF063_ARTIFACT"
    mf063_require_file "$MF063_ARTIFACT.sha256"
    mf063_require_file "$MF063_PACKAGE_DIR/PACKAGE-MANIFEST.json"
    mf063_require_file "$MF063_PACKAGE_DIR/INTERNAL-SHA256SUMS"
    mf063_require_file "$MF063_PACKAGE_DIR/SHA256SUMS"

    (
      cd "$MF063_PACKAGE_DIR"
      sha256sum -c "$(basename "$MF063_ARTIFACT").sha256" >/dev/null
      sha256sum -c SHA256SUMS >/dev/null
    )

    python3 -B - "$MF063_ARTIFACT" <<'PY'
from pathlib import PurePosixPath
import hashlib
import zipfile
import sys

archive_path=sys.argv[1]
root="nebo-v0.1.0-rc.1"
with zipfile.ZipFile(archive_path) as archive:
    names=archive.namelist()
    sums=archive.read(f"{root}/SHA256SUMS").decode().splitlines()
    for line in sums:
        digest,relative=line.split("  ",1)
        data=archive.read(f"{root}/{relative}")
        if hashlib.sha256(data).hexdigest()!=digest:
            raise SystemExit(
                f"NEBO_RELEASE_RESTORE_003_FAIL internal={relative}"
            )
print("NEBO_RELEASE_RESTORE_003_GREEN internal_external_checksums=PASS")
PY
