#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f02-tests >/dev/null
build/tests/rf27-g15/f02/matrix_core_test
file build/tests/rf27-g15/f02/matrix_core_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f02/matrix_core_test)"
! readelf -lW build/tests/rf27-g15/f02/matrix_core_test | rg -q INTERP
bash tests/rf27-g15/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F02_GREEN native=18 construction=owned identity=yes indexing=bounds_checked row_view=zero_copy column_view=strided slice=zero_copy transpose=zero_copy views=readonly_generation_checked contiguous=explicit_owned static_elf=yes'
