#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f04-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"

ninja c12-f04-tests >/dev/null
build/tests/c12/f04/tensor_i64_layout_test
tests/c12/f03/validate.sh >/dev/null
test -z "$(nm -u build/tests/c12/f04/tensor_i64_layout_test)"
! readelf -lW build/tests/c12/f04/tensor_i64_layout_test | grep -q INTERP
! readelf -dW build/tests/c12/f04/tensor_i64_layout_test | grep -q '(NEEDED)'
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm tests/c12/f04
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F04_GREEN layout=row_major stride_unit=elements rank=0..3 contiguous=computed hidden_copy=no hidden_materialization=no invalid_stride=fail_closed'
