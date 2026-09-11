#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g08-f03
build/tests/rf27-g08/f03/dict_test
bash tests/rf27-g08/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G08_F03_GREEN native=12 dict=96/8 slot=32 capacity=8..64 load=3/4 operations=init_insert_update_get_contains_remove_clear_rehash tombstones=yes failure_atomic=yes f02=yes'
