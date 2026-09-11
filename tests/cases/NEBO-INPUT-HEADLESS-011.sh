#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"; cd "$root"
ninja mf048-console-pending-tests
build/tests/mf048/pending_resolution_test 1
echo NEBO_INPUT_HEADLESS_011_GREEN
