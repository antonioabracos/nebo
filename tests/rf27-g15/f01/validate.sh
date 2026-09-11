#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f01-tests >/dev/null
build/tests/rf27-g15/f01/matrix_contract_test
file build/tests/rf27-g15/f01/matrix_contract_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f01/matrix_contract_test)"
! readelf -lW build/tests/rf27-g15/f01/matrix_contract_test | rg -q INTERP
bash tests/rf27-g14/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F01_GREEN native=14 dtype=Int64+Float64 rows_max=64 cols_max=64 elements_max=4096 layout=row_major ownership=owned+view lifetime=generation_token alias=validated zero_dims=allowed static_elf=yes'
