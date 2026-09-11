#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf032-codegen-tests >/dev/null
build/tests/mf032/codegen_test 4
grep -q '^unresolved-node-before-codegen$' tests/codegen/goldens/codegen-diagnostics.txt
