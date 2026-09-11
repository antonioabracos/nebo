#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f06-tests >/dev/null
build/tests/rf27-g16/f06/tensor_structural_test
python3 tests/rf27-g16/f06/structural_oracle.py >/dev/null
file build/tests/rf27-g16/f06/tensor_structural_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f06/tensor_structural_test)"
! readelf -lW build/tests/rf27-g16/f06/tensor_structural_test | rg -q INTERP
for front in 01 02 03 04 05; do bash "tests/rf27-g16/f${front}/validate.sh" >/dev/null; done
printf '%s\n' 'RF27_G16_F06_GREEN native=19 oracle=12 concatenate0=yes stack0=yes split0=yes pad2d=yes matmul_rank2=yes einsum=rejected_deferred caller_storage=yes static_elf=yes'
