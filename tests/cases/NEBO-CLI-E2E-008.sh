#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc build "$tmp/input.no" -o "$tmp/program" >"$tmp/out" 2>"$tmp/err"
[ ! -s "$tmp/out" ]
[ ! -s "$tmp/err" ]
[ -x "$tmp/program" ]
readelf -hW "$tmp/program" | grep -q 'Class:[[:space:]]*ELF64'
readelf -hW "$tmp/program" | grep -q 'Machine:[[:space:]]*Advanced Micro Devices X86-64'
! readelf -dW "$tmp/program" 2>/dev/null | grep -q '(NEEDED)'
[ -z "$(nm -u "$tmp/program" 2>/dev/null || true)" ]
[ ! -e "$tmp/program.neboc.asm" ]
[ ! -e "$tmp/program.neboc.o" ]
