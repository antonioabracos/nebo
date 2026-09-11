#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f01-tests >/dev/null
build/tests/rf27-g17/f01/cpu_features_test
file build/tests/rf27-g17/f01/cpu_features_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f01/cpu_features_test)"
! readelf -lW build/tests/rf27-g17/f01/cpu_features_test | rg -q INTERP
printf '%s\n' 'RF27_G17_F01_GREEN native=12 CPUID=local SSE2=baseline AVX2=CPUID_OSXSAVE_XCR0_gated feature_masks=monotonic cache_line=reported static_elf=yes'
