#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f04-tests >/dev/null
build/tests/rf27-g17/f04/avx2_kernels_test
file build/tests/rf27-g17/f04/avx2_kernels_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f04/avx2_kernels_test)"
! readelf -lW build/tests/rf27-g17/f04/avx2_kernels_test | rg -q INTERP
objdump -d build/obj/avx2_kernels.o | rg -q 'vzeroupper'
bash tests/rf27-g17/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F04_GREEN native=16 AVX2=CPUID_OSXSAVE_XCR0_gated forced_masks=4 scalar_SSE2_fallback=yes illegal_instruction=0 add_dot_reduce_relu=green tails=0_1_3_7 static_elf=yes'
