#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f05-tests >/dev/null
build/tests/rf27-g16/f05/tensor_reduce_test
python3 tests/rf27-g16/f05/reduction_oracle.py >/dev/null
file build/tests/rf27-g16/f05/tensor_reduce_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f05/tensor_reduce_test)"
! readelf -lW build/tests/rf27-g16/f05/tensor_reduce_test | rg -q INTERP
for front in 01 02 03 04; do bash "tests/rf27-g16/f${front}/validate.sh" >/dev/null; done
bash tests/rf27-g15/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G16_F05_GREEN native=29 oracle=15 axis_reductions=yes keepDims=yes noncontiguous=yes duplicate_negative_axes=rejected NaN=rejected empty=rejected argMax=first all_any=yes deterministic=yes static_elf=yes'
