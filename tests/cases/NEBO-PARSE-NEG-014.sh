#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf019-recovery-tests >/dev/null
build/tests/mf019/recovery_test 14
