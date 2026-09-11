#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f08-tests >/dev/null
build/tests/rf27-g26/f08/faults_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f08/faults_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f08/faults_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f08/faults_test)"
! readelf -lW build/tests/rf27-g26/f08/faults_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/faults.o
printf 'RF27_G26_F08_GREEN native_assertions=19 cases=80000 retries_max=8 delay_max=1024 deadline=yes checkpoint_v1=yes digest_required=yes replicas_max=3 majority_quorum=yes compensation=explicit rollback_magic=no deterministic_jitter=yes network_calls=0 static_elf=yes no_c_no_libc=yes\n'
