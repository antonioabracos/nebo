#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf014-lexer-tests >/dev/null
build/tests/mf014/lexer_test 1
