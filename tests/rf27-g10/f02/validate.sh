#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g10-f02
build/tests/rf27-g10/f02/column_test
bash tests/rf27-g10/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F02_GREEN native=12 column=64/8 iterator=40/8 capacity=1..32 dtypes=5 missing=bitmap operations=init_get_set_setMissing_countMissing_sum_min_max_iter overflow=checked borrow=lexical stale=yes failure_atomic=yes f01=yes'
