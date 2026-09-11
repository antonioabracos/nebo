#!/usr/bin/env bash
set -euo pipefail
source "${NEBO_REPO_ROOT:?}/scripts/mf062/release-case-lib.sh"
summary="$MF062_EVIDENCE/FROZEN-RUN-1-SUMMARY.tsv"
metadata="$MF062_EVIDENCE/FROZEN-RUN-1-METADATA.txt"
mf062_require_tsv_pass "$summary" 316
mf062_require_file "$metadata"
for token in PASS=316 FAIL=0 BLOCKED=0 SKIPPED_NOT_APPLICABLE=0 NOT_EXECUTED_WITH_REASON=0 NOT_IMPLEMENTED=0; do
  grep -Fqx "$token" "$metadata" || {
    echo "NEBO_RELEASE_RESTORE_002_FAIL metadata: $token" >&2
    exit 1
  }
done
echo 'NEBO_RELEASE_RESTORE_002_GREEN frozen_suite=316 pass=316 fail=0'
