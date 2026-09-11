#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja mf012-source-location-tests >/dev/null
build/tests/mf012/line_map_test 6
golden="tests/source/goldens/line-map-offset.txt"
test -s "$golden"
! grep -Eq '(^|[=[:space:]])/(home|tmp|Users)/|[A-Za-z]:\\' "$golden"
cat "$golden"
