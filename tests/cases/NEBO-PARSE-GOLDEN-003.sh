#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf016-parser-tests >/dev/null
build/tests/mf016/parser_test 3
