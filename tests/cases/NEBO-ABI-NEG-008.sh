#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf033-abi-tests >/dev/null
build/tests/mf033/abi_test 7
