#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf008-collection-tests >/dev/null
build/tests/mf008/collections_test 5
