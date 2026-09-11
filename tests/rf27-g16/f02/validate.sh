#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f02-tests >/dev/null
build/tests/rf27-g16/f02/tensor_core_test
file build/tests/rf27-g16/f02/tensor_core_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f02/tensor_core_test)"
! readelf -lW build/tests/rf27-g16/f02/tensor_core_test | rg -q INTERP
printf '%s\n' 'RF27_G16_F02_GREEN native=10 zeros=yes fromValues=yes rank_shape_count=yes strides_contiguous=yes axis_checked=yes caller_storage=yes static_elf=yes'
