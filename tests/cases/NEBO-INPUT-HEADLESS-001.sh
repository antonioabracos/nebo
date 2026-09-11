#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
test_bin="$root/build/tests/mf046/input_registry_test"
[[ -x "$test_bin" ]] || { echo "NEBO-INPUT-HEADLESS-001_FAIL: test executable missing" >&2; exit 1; }
timeout 10s "$test_bin" 1
echo NEBO_INPUT_HEADLESS_001_GREEN
