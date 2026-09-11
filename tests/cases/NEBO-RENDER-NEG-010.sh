#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf045-console-output-tests >/dev/null
build/tests/mf045/console_output_test 5
echo NEBO_RENDER_NEG_010_GREEN
