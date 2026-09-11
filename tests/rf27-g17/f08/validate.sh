#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f08-tests >/dev/null
build/tests/rf27-g17/f08/cross_kernel_test
file build/tests/rf27-g17/f08/cross_kernel_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f08/cross_kernel_test)"
! readelf -lW build/tests/rf27-g17/f08/cross_kernel_test | rg -q INTERP
! rg -n '\bzmm[0-9]+\b|avx512' runtime/kernel/*kernels.asm
bash tests/rf27-g17/f07/validate.sh >/dev/null
bash tests/rf27-g16/f07/validate.sh >/dev/null
bash tests/rf27-g15/f07/validate.sh >/dev/null
bash tests/rf27-g14/f07/validate.sh >/dev/null
bash tests/rf27-g13/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F08_GREEN native=18 profiles=scalar_SSE2_AVX2 cross_kernel=exact add=all_tiers planner_trace=repeat benchmark_checksum=2080 AVX512=deferred hardware_report=local G13_F01_F09=pass G13_F10_F11=committed_baseline_loopback_not_rerun_network_forbidden static_elf=yes G17=CLOSED_GREEN'
