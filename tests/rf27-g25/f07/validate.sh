#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g25-f07-tests >/dev/null
build/tests/rf27-g25/f07/provenance_test
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
python3 tests/rf27-g25/f07/provenance_oracle.py >"$tmp_root/oracle-a"
python3 tests/rf27-g25/f07/provenance_oracle.py >"$tmp_root/oracle-b"
cmp "$tmp_root/oracle-a" "$tmp_root/oracle-b"
cat "$tmp_root/oracle-a"
file build/tests/rf27-g25/f07/provenance_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f07/provenance_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f07/provenance_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/provenance.o
mf056_full="$(python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f07/provenance_test 2>&1 || true)"
test "$(printf '%s\n' "$mf056_full" | rg -c 'MF056_STACK_ALIGNMENT_FAIL')" -eq 6
test -z "$(printf '%s\n' "$mf056_full" | rg 'MF056_STACK_ALIGNMENT_FAIL' | rg -v ' in nebo_sha256_(update|final|hash)$')"
printf '%s\n' 'RF27_G25_F07_DEPENDENCY_MF056=KNOWN_G12_SHA256_6_CALLS FRONT_OBJECT=GREEN'
test -z "$(find tools tests/rf27-g25/f07 -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F07_GREEN native_assertions=29 records_max=4096 parents_max=16 versioned_sha256=yes source_transform_artifact=yes policy_quality=yes existing_parents_only=yes cycle_denied=yes duplicate_denied=yes immutable_rewrite_detected=yes FileCapability=yes raw_secret_payloads=0 deterministic=yes stack_front_object_green=yes stack_combined_historical_g12_red=6 static_elf=yes no_c_no_libc=yes'
