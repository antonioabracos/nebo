#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f03-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"

ninja c12-f03-tests >/dev/null
build/tests/c12/f03/tensor_i64_shape_rank_test
tests/c12/f02/validate.sh >/dev/null
test -z "$(nm -u build/tests/c12/f03/tensor_i64_shape_rank_test)"
! readelf -lW build/tests/c12/f03/tensor_i64_shape_rank_test | grep -q INTERP
! readelf -dW build/tests/c12/f03/tensor_i64_shape_rank_test | grep -q '(NEEDED)'
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm tests/c12/f03
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F03_GREEN rank=0..3 dimensions=0..8 elements=0..64 rank0_elements=1 zero_dimension_elements=0 product_overflow=reject query_bounds=checked failure_atomic=yes'
