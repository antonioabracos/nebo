#!/usr/bin/env bash
set -euo pipefail
source "${NEBO_REPO_ROOT:?}/scripts/mf062/release-case-lib.sh"
report="$MF062_EVIDENCE/FINDINGS-AUDIT.json"
mf062_require_file "$report"
python3 -B - "$report" <<'PY2'
import json, sys
data=json.load(open(sys.argv[1]))
if data.get('schema')!='NEBO-MF062-FINDINGS-AUDIT-v1.0':
    raise SystemExit('NEBO_RELEASE_RESTORE_009_FAIL schema')
if data.get('verdict')!='OPEN_P0_P1_ZERO_GREEN':
    raise SystemExit('NEBO_RELEASE_RESTORE_009_FAIL verdict')
if data.get('open_p0')!=0 or data.get('open_p1')!=0:
    raise SystemExit('NEBO_RELEASE_RESTORE_009_FAIL open blockers')
if data.get('p0_exceptions')!=0:
    raise SystemExit('NEBO_RELEASE_RESTORE_009_FAIL P0 exceptions')
print('NEBO_RELEASE_RESTORE_009_GREEN open_p0=0 open_p1=0 p0_exceptions=0')
PY2
