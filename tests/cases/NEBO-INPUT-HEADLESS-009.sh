#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
scenario=3
ninja mf047-console-focus-tests
"$root/build/tests/mf047/focus_edit_test" "$scenario"
echo NEBO_INPUT_HEADLESS_009_GREEN
