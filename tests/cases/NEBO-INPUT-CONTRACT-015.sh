#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
ninja mf047-console-focus-tests
"$root/build/tests/mf047/focus_edit_test" 5
echo NEBO_INPUT_CONTRACT_015_GREEN
