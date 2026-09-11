#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g15-f05-tests >/dev/null
build/tests/rf27-g15/f05/matrix_lu_test
file build/tests/rf27-g15/f05/matrix_lu_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g15/f05/matrix_lu_test)"
! readelf -lW build/tests/rf27-g15/f05/matrix_lu_test | rg -q INTERP
bash tests/rf27-g15/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F05_GREEN native=12 linear_algebra=Float64 N=1..32 LU=partial_pivot determinant=from_LU solve=forward+back inverse=explicit_repeated_solve singularity=threshold workspace=caller_owned alias=checked static_elf=yes'
