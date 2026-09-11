#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc build --keep-temp -o "$tmp/program" "$tmp/input.no"
[ -x "$tmp/program" ]
[ -f "$tmp/program.neboc.asm" ]
[ -f "$tmp/program.neboc.o" ]
cmp -s "$tmp/program.neboc.asm" tests/cli/goldens/minimal-start.asm
readelf -hW "$tmp/program.neboc.o" | grep -q 'Class:[[:space:]]*ELF64'
