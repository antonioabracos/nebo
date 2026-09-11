#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f05/matrix_i64_views_test >/dev/null
build/tests/c11/f05/matrix_i64_views_test
tests/c11/f04/validate.sh >/dev/null
printf '%s\n' 'C11_F05_GREEN row=yes column=yes slice=yes transposeView=yes readonly=yes owner_generation=yes max_depth=8'
