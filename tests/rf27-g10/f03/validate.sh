#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g10-f03
build/tests/rf27-g10/f03/table_test
bash tests/rf27-g10/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F03_GREEN native=8 table=80/8 schema=64/8 rows=32 columns=8 operations=construct_get_select_filter_eq_groupBy_innerJoin order=stable_first_seen_left_major missing=non_matching cardinality=preflight failure_atomic=yes f02=yes'
