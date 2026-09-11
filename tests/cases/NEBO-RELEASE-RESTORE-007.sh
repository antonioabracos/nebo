#!/usr/bin/env bash
set -euo pipefail
source "${NEBO_REPO_ROOT:?}/scripts/mf062/release-case-lib.sh"
report="$MF062_EVIDENCE/COMMON-CONFORMANCE.json"
mf062_require_file "$report"
python3 -B - "$report" <<'PY2'
import json, sys
p=sys.argv[1]; data=json.load(open(p))
expected={
 'schema':'NEBO-MF062-COMMON-CONFORMANCE-v1.0',
 'verdict':'COMMON_CONFORMANCE_GREEN',
 'frozen_suite_pass':316,
 'core_platform_imports':0,
 'semantic_forks':0,
 'product_target_selection':'UNCHANGED',
 'freeze_drift':0,
}
for k,v in expected.items():
    if data.get(k)!=v: raise SystemExit(f'NEBO_RELEASE_RESTORE_007_FAIL {k}={data.get(k)!r}')
print('NEBO_RELEASE_RESTORE_007_GREEN common_conformance=PASS semantic_forks=0')
PY2
