#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f04-tests >/dev/null
build/tests/rf27-g16/f04/tensor_ops_test
file build/tests/rf27-g16/f04/tensor_ops_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f04/tensor_ops_test)"
! readelf -lW build/tests/rf27-g16/f04/tensor_ops_test | rg -q INTERP
printf '%s\n' 'RF27_G16_F04_GREEN native=10 broadcast_zero_stride=yes add_sub_mul_div=yes divisor_preflight=yes clamp=yes static_elf=yes'
