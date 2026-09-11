#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f10-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja c12-f10-tests >/dev/null
build/tests/c12/f10/tensor_i64_elementwise_test
tests/c12/f09/validate.sh >/dev/null
test -z "$(nm -u build/tests/c12/f10/tensor_i64_elementwise_test)"
! readelf -lW build/tests/c12/f10/tensor_i64_elementwise_test | grep -q INTERP
! readelf -dW build/tests/c12/f10/tensor_i64_elementwise_test | grep -q '(NEEDED)'
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm tests/c12/f10
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F10_GREEN elementwise=add,multiply broadcast=trailing_singleton overflow=full_preflight partial_result=zero output_storage=caller_fixed hidden_allocation=no'
