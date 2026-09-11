#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f07/matrix_i64_elementwise_test >/dev/null
build/tests/c11/f07/matrix_i64_elementwise_test
tests/c11/f06/validate.sh >/dev/null
printf '%s\n' 'C11_F07_GREEN add=yes subtract=yes multiplyElements=yes scale=yes checked_i64=yes shape_checked=yes failure_atomic=yes'
