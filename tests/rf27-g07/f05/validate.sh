#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g07-f05
build/tests/rf27-g07/f05/ring_test
tests/rf27-g07/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G07_F05_GREEN native=10 queue=fifo deque=double_ended ring=80/8 wrap=yes full_empty_atomic=yes slot_zero=yes f04=yes'
