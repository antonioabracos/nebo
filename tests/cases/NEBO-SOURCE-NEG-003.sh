#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf011-source-tests >/dev/null
build/tests/mf011/source_test 3
[ -s "tests/source/goldens/source-invalid-utf8.txt" ]
! grep -Eq '(^|[=[:space:]])/(home|tmp|Users)/' "tests/source/goldens/source-invalid-utf8.txt"
cat "tests/source/goldens/source-invalid-utf8.txt"
