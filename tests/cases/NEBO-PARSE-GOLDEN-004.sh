#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf017-expression-tests >/dev/null
build/tests/mf017/expression_test 4
