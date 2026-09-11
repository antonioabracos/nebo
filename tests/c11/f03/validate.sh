#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f03/matrix_i64_metadata_test >/dev/null
build/tests/c11/f03/matrix_i64_metadata_test
tests/c11/f02/validate.sh >/dev/null
printf '%s\n' 'C11_F03_GREEN rows=yes columns=yes elements=yes layout=row-major storage_identity=yes descriptor=88B'
