#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f04-tests >/dev/null
build/tests/rf27-g15/f04/matrix_mul_test
file build/tests/rf27-g15/f04/matrix_mul_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f04/matrix_mul_test)"
! readelf -lW build/tests/rf27-g15/f04/matrix_mul_test | rg -q INTERP
bash tests/rf27-g15/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F04_GREEN native=11 matmul=scalar_triple_loop matvec=yes outer=yes shapes=MxK_KxN strided_inputs=yes output_alias=range_preflight matmulInto=failure_atomic hidden_temporaries=no static_elf=yes'
