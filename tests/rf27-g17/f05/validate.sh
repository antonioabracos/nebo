#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f05-tests >/dev/null
build/tests/rf27-g17/f05/kernel_planner_test
file build/tests/rf27-g17/f05/kernel_planner_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f05/kernel_planner_test)"
! readelf -lW build/tests/rf27-g17/f05/kernel_planner_test | rg -q INTERP
bash tests/rf27-g17/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F05_GREEN native=24 registry_tiers=3 scalar_SSE2_AVX2=deterministic workspace_max=65536 elements_max=4096 unsupported_alias_bounds=failure_atomic trace=versioned static_elf=yes'
