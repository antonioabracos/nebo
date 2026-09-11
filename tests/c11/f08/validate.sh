#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f08/matrix_i64_reduction_test >/dev/null
build/tests/c11/f08/matrix_i64_reduction_test
tests/c11/f07/validate.sh >/dev/null
printf '%s\n' 'C11_F08_GREEN sum=yes min=yes max=yes trace=yes isSquare=yes empty=sum0,trace0,minmax-domain mean=deferred norm=deferred'
