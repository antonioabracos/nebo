#!/usr/bin/env bash
set -euo pipefail
source "${NEBO_REPO_ROOT:?}/scripts/mf062/release-case-lib.sh"
report="$MF062_EVIDENCE/TARGET-CONFORMANCE.json"
mf062_require_file "$report"
python3 -B - "$report" <<'PY2'
import json, sys
p=sys.argv[1]; data=json.load(open(p))
expected={
 'schema':'NEBO-MF062-TARGET-CONFORMANCE-v1.0',
 'verdict':'TARGET_PLATFORM_CONFORMANCE_GREEN',
 'target':'x86_64-systemv-elf-linux',
 'internal_abi':0,
 'runtime_abi':0,
 'console_runtime_abi':0,
 'platform_tests_pass':12,
 'e2e_tests_pass':16,
 'visual_images_pass':16,
 'native_binaries_pass':3,
 'tag_created':False,
}
for k,v in expected.items():
    if data.get(k)!=v: raise SystemExit(f'NEBO_RELEASE_RESTORE_008_FAIL {k}={data.get(k)!r}')
if data.get('native_windows_support')!='NOT_CERTIFIED':
    raise SystemExit('NEBO_RELEASE_RESTORE_008_FAIL windows claim')
print('NEBO_RELEASE_RESTORE_008_GREEN target_platform=PASS visual_images=16 native_binaries=3')
PY2
