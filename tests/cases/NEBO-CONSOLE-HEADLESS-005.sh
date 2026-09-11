#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf041-console-manager-tests >/dev/null
build/tests/mf041/console_manager_test 5
echo NEBO_CONSOLE_HEADLESS_005_GREEN
