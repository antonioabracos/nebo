#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc build "$tmp/input.no" -o "$tmp/program"
[ -x "$tmp/program" ]
[ ! -e "$tmp/program.neboc.asm" ]
[ ! -e "$tmp/program.neboc.o" ]
