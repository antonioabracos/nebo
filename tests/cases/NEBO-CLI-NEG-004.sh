#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
set +e
build/bin/neboc check "$tmp/missing.no" >"$tmp/out" 2>"$tmp/err"
code=$?
set -e
[ "$code" -eq 3 ]
[ ! -s "$tmp/out" ]
cmp -s "$tmp/err" tests/cli/goldens/io-error.txt
