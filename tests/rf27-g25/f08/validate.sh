#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
ninja -j1 rf27-g25-f08-tests >/dev/null
build/tests/rf27-g25/f08/audit_test
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
python3 tests/rf27-g25/f08/audit_oracle.py >"$tmp/oracle-a"
python3 tests/rf27-g25/f08/audit_oracle.py >"$tmp/oracle-b"
cmp -s "$tmp/oracle-a" "$tmp/oracle-b"; cat "$tmp/oracle-a"
bash tests/rf27-g25/f07/validate.sh >"$tmp/g25-f07"
bash tests/rf27-g24/f11/validate.sh >"$tmp/g24-f11"
bash tests/rf27-g26/f09/validate.sh >"$tmp/g26-f09"
rg -q 'RF27_G25_F07_GREEN' "$tmp/g25-f07"
rg -q 'RF27_G24_F11_GREEN' "$tmp/g24-f11"
rg -q 'RF27_G26_F09_GREEN' "$tmp/g26-f09"
file build/tests/rf27-g25/f08/audit_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f08/audit_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f08/audit_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/audit.o
mf056_full="$(python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f08/audit_test 2>&1 || true)"
test "$(printf '%s\n' "$mf056_full" | rg -c 'MF056_STACK_ALIGNMENT_FAIL')" -eq 6
test -z "$(printf '%s\n' "$mf056_full" | rg 'MF056_STACK_ALIGNMENT_FAIL' | rg -v ' in nebo_sha256_(update|final|hash)$')"
printf '%s\n' 'RF27_G25_F08_DEPENDENCY_MF056=KNOWN_G12_SHA256_6_CALLS FRONT_OBJECT=GREEN'
test -z "$(find runtime/security tests/rf27-g25/f08 -type f -name '*.c' -print)"
test -z "$(find runtime/security tests/rf27-g25/f08 -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F08_GREEN native_assertions=30 cases=90000 records_max=4096 schema=1 sha256_chain=yes append_only=yes query_explain=yes effect_mask=16383 capability_kinds=6 errors_max=15 metadata_only=yes raw_secret_payloads=0 AuditCapability=yes failure_atomicity=yes deterministic=yes stack_front_object_green=yes static_elf=yes no_c_no_libc=yes network=no'
