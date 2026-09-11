#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf011-source-tests >/dev/null
build/tests/mf011/source_test 2
[ -s "tests/source/goldens/source-bom.txt" ]
! grep -Eq '(^|[=[:space:]])/(home|tmp|Users)/' "tests/source/goldens/source-bom.txt"
cat "tests/source/goldens/source-bom.txt"
