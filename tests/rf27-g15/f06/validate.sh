#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f06-tests >/dev/null
build/tests/rf27-g15/f06/matrix_factor_test
file build/tests/rf27-g15/f06/matrix_factor_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f06/matrix_factor_test)"
! readelf -lW build/tests/rf27-g15/f06/matrix_factor_test | rg -q INTERP
bash tests/rf27-g15/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F06_GREEN native=11 QR=modified_gram_schmidt Cholesky=lower_SPD_checked condition=one_norm_A_times_inverse advisory=yes Float64_Nmax32 workspace=caller_owned residual=bounded static_elf=yes'
