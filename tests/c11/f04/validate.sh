#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f04/matrix_i64_index_test >/dev/null
build/tests/c11/f04/matrix_i64_index_test
tests/c11/f03/validate.sh >/dev/null
printf '%s\n' 'C11_F04_GREEN at=yes set=unique-owner bounds=checked address=checked store=exactly-one failure_atomic=yes'
