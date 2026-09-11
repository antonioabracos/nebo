#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f03-tests >/dev/null
build/tests/rf27-g15/f03/matrix_ops_test
file build/tests/rf27-g15/f03/matrix_ops_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f03/matrix_ops_test)"
! readelf -lW build/tests/rf27-g15/f03/matrix_ops_test | rg -q INTERP
bash tests/rf27-g15/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F03_GREEN native=18 elementwise=add+sub+mul+div division=preflight_failure_atomic scale=yes map=bounded_callable clamp=yes reductions=sum+mean+min+max order=logical_row_major strided=accepted static_elf=yes'
