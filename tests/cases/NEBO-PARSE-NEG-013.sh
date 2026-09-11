#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf018-statement-tests >/dev/null
build/tests/mf018/statement_test 13
