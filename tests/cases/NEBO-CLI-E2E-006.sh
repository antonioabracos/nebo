#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc check "$tmp/input.no" >"$tmp/out" 2>"$tmp/err"
[ ! -s "$tmp/out" ]
[ ! -s "$tmp/err" ]
[ ! -e "$tmp/input.no.neboc.asm" ]
[ ! -e "$tmp/input.no.neboc.o" ]
[ "$(find "$tmp" -maxdepth 1 -type f | wc -l)" -eq 3 ]
