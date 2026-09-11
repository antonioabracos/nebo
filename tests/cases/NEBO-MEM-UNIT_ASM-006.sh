#!/usr/bin/env sh
set -eu

root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"

ninja mf007-memory-tests >/dev/null
build/tests/mf007/memory_test 6
