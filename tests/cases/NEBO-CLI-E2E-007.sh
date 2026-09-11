#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc emit-asm "$tmp/input.no" -o "$tmp/output.asm" >"$tmp/out" 2>"$tmp/err"
[ ! -s "$tmp/out" ]
[ ! -s "$tmp/err" ]
cmp -s "$tmp/output.asm" tests/cli/goldens/minimal-start.asm
nasm -f elf64 -Wall -Werror -o "$tmp/output.o" "$tmp/output.asm"
readelf -hW "$tmp/output.o" | grep -q 'Class:[[:space:]]*ELF64'
