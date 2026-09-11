#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f03-tests >/dev/null
build/tests/rf27-g16/f03/tensor_views_test
file build/tests/rf27-g16/f03/tensor_views_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f03/tensor_views_test)"
! readelf -lW build/tests/rf27-g16/f03/tensor_views_test | rg -q INTERP
printf '%s\n' 'RF27_G16_F03_GREEN native=15 at_set=yes narrow_slice=yes permute=yes reshape=yes contiguous=yes readonly_views=yes static_elf=yes'
