#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.txt"
set +e
build/bin/neboc check "$tmp/input.txt" >"$tmp/out" 2>"$tmp/err"
code=$?
set -e
[ "$code" -eq 2 ]
[ ! -s "$tmp/out" ]
cmp -s "$tmp/err" tests/cli/goldens/extension-error.txt
