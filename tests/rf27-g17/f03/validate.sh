#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f03-tests >/dev/null
build/tests/rf27-g17/f03/sse2_kernels_test
file build/tests/rf27-g17/f03/sse2_kernels_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f03/sse2_kernels_test)"
! readelf -lW build/tests/rf27-g17/f03/sse2_kernels_test | rg -q INTERP
bash tests/rf27-g17/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F03_GREEN native=15 SSE2_add_dot_reduce=green i64_convert=scalar_tail exact_scalar_crosscheck=yes unaligned=yes tails=0_1_3_5 alias=preflight static_elf=yes'
