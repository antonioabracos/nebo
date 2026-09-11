#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf015-lexer-tests >/dev/null
build/tests/mf015/lexer_test 11
