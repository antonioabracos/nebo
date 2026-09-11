#!/usr/bin/env sh
set -eu

root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"

ninja mf006-host-tests >/dev/null
build/tests/mf006/host_contract_test 6
