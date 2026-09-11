#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf044-console-layout-tests >/dev/null
build/tests/mf044/console_layout_test 1
echo NEBO_LAYOUT_HEADLESS_001_GREEN
