#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f09/matrix_i64_matmul_test >/dev/null
build/tests/c11/f09/matrix_i64_matmul_test
tests/c11/f08/validate.sh >/dev/null
printf '%s\n' 'C11_F09_GREEN matmul=yes matmulInto=yes scalar_reference=yes checked_i64=yes budget=512 failure_atomic=yes'
