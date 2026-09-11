#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f02/matrix_i64_construction_test rf27-g15-f07-tests >/dev/null
build/tests/c11/f02/matrix_i64_construction_test
bash tests/rf27-g15/f07/validate.sh >/dev/null
test -z "$(find compiler runtime tests/c11 -type d -name __pycache__ -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C11_F02_GREEN constructors=zeros,filled,fromRows,fromBuffer storage=caller-fixed max=8x8x64 failure_atomic=yes cleanup=descriptor-only'
