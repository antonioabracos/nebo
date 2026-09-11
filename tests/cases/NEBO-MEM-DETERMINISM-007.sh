#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf009-string-tests >/dev/null
build/tests/mf009/string_pool_test 7
