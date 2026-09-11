#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f02-tests >/dev/null
build/tests/rf27-g17/f02/scalar_kernels_test
python3 tests/rf27-g17/f02/scalar_oracle.py >/dev/null
file build/tests/rf27-g17/f02/scalar_kernels_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f02/scalar_kernels_test)"
! readelf -lW build/tests/rf27-g17/f02/scalar_kernels_test | rg -q INTERP
! readelf -dW build/tests/rf27-g17/f02/scalar_kernels_test | rg -q NEEDED
readelf -W -l build/tests/rf27-g17/f02/scalar_kernels_test | rg -q 'GNU_STACK.*RW '
bash tests/rf27-g17/f01/validate.sh >/dev/null
bash tests/rf27-g16/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F02_GREEN native=25 oracle=25 registry=6 add=green dot=green matmul=green reduceSum=green relu=green i64_to_f64=green bounds=4096 alias=preflight deterministic=yes static_elf=yes'
