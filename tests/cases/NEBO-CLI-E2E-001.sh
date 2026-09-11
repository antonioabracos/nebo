#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
build/bin/neboc --help >"$tmp/out" 2>"$tmp/err"
cmp -s "$tmp/out" tests/cli/goldens/help.txt
[ ! -s "$tmp/err" ]
