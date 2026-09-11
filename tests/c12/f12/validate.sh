#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f12-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja c12-f12-tests >/dev/null
build/tests/c12/f12/tensor_i64_alias_failure_test
tests/c12/f11/validate.sh >/dev/null
test -z "$(nm -u build/tests/c12/f12/tensor_i64_alias_failure_test)"
! readelf -lW build/tests/c12/f12/tensor_i64_alias_failure_test | grep -q INTERP
! readelf -dW build/tests/c12/f12/tensor_i64_alias_failure_test | grep -q '(NEEDED)'
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm tests/c12/f12
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F12_GREEN alias=full_ranges owner_mutation=unique stale_view=fail_closed contiguous=explicit_copy fresh_storage=yes hidden_copy=no partial_result=zero'
