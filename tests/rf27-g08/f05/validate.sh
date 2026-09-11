#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g08-f05
build/tests/rf27-g08/f05/set_test
bash tests/rf27-g08/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G08_F05_GREEN native=8 set=dict_substrate operations=init_insert_contains_remove_union_intersection_difference capacity_preflight=yes failure_atomic=yes f04=yes'
