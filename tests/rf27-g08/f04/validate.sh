#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g08-f04
build/tests/rf27-g08/f04/dict_view_test
bash tests/rf27-g08/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G08_F04_GREEN native=9 view=56/8 kinds=keys_values_entries order=bucket_unspecified end=option borrow=lexical mutation_gate=yes release=yes stale=yes f03=yes'
