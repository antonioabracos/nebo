#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g07-f06
build/tests/rf27-g07/f06/iterator_test
tests/rf27-g07/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G07_F06_GREEN native=6 iterator=48/8 sources=list_stack_queue_deque_slice order=logical end=option release=yes stale=yes mutation_gate=yes f05=yes'
