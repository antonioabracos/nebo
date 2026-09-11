#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g07-f04
build/tests/rf27-g07/f04/stack_test
tests/rf27-g07/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G07_F04_GREEN native=8 stack=push_pop_peek_length_clear lifo=yes full_atomic=yes empty_option=yes slot_zero=yes f03=yes'
