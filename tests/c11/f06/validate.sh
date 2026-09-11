#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f06/matrix_i64_transform_test >/dev/null
build/tests/c11/f06/matrix_i64_transform_test
tests/c11/f05/validate.sh >/dev/null
printf '%s\n' 'C11_F06_GREEN transposeView=metadata-only contiguous=explicit-copy owner_result=yes reshape=deferred hidden_copy=no'
