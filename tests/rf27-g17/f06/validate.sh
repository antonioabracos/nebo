#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f06-tests >/dev/null
build/tests/rf27-g17/f06/numeric_parallel_test
file build/tests/rf27-g17/f06/numeric_parallel_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f06/numeric_parallel_test)"
! readelf -lW build/tests/rf27-g17/f06/numeric_parallel_test | rg -q INTERP
bash tests/rf27-g17/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F06_GREEN native=22 workers=1_8 chunks=256 max_elements=4096 add_reduce=serial_crosscheck structured_join=before_return cancellation=cooperative failure_atomic=yes oversubscription=0 orphan=0 static_elf=yes'
