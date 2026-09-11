#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g25-f05-tests >/dev/null
build/tests/rf27-g25/f05/privacy_test
python3 tests/rf27-g25/f05/privacy_oracle.py
file build/tests/rf27-g25/f05/privacy_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f05/privacy_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f05/privacy_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/privacy.o
mf056_full="$(python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f05/privacy_test 2>&1 || true)"
test "$(printf '%s\n' "$mf056_full" | rg -c 'MF056_STACK_ALIGNMENT_FAIL')" -eq 6
test -z "$(printf '%s\n' "$mf056_full" | rg 'MF056_STACK_ALIGNMENT_FAIL' | rg -v ' in nebo_sha256_(update|final|hash)$')"
printf '%s\n' 'RF27_G25_F05_DEPENDENCY_MF056=KNOWN_G12_SHA256_6_CALLS FRONT_OBJECT=GREEN'
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F05_GREEN native_assertions=26 flows=15000 Sensitive_classification_purpose=yes RevealCapability_hmac=yes reveal_scope_clearance=yes redaction_before_formatting=yes raw_secret_leaks=0 flow_check=yes stack_front_object_green=yes stack_combined_historical_g12_red=6 static_elf=yes no_c_no_libc=yes'
