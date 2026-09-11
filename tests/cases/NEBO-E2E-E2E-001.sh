#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja neboc >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cp examples/minimal/start-empty.no "$tmp/start.no"

build/bin/neboc check "$tmp/start.no" >"$tmp/check.out" 2>"$tmp/check.err"
[ ! -s "$tmp/check.out" ]
[ ! -s "$tmp/check.err" ]

build/bin/neboc emit-asm "$tmp/start.no" -o "$tmp/a.asm"
build/bin/neboc emit-asm -o "$tmp/b.asm" "$tmp/start.no"
cmp -s "$tmp/a.asm" "$tmp/b.asm"
cmp -s "$tmp/a.asm" tests/cli/goldens/minimal-start.asm

build/bin/neboc build "$tmp/start.no" -o "$tmp/program-a"
build/bin/neboc build -o "$tmp/program-b" "$tmp/start.no"
cmp -s "$tmp/program-a" "$tmp/program-b"
[ -x "$tmp/program-a" ]
[ -x "$tmp/program-b" ]
for suffix in .neboc.asm .neboc.o; do
  [ ! -e "$tmp/program-a$suffix" ]
  [ ! -e "$tmp/program-b$suffix" ]
done

for program in "$tmp/program-a" "$tmp/program-b"; do
  ! readelf -sW "$program" | grep -Eq 'program-[ab]\.neboc\.asm'
  for symbol in _start nebo_fn_1 nebo_runtime_start nebo_runtime_exit; do
    nm -g --defined-only "$program" | grep -Eq "[[:space:]]${symbol}$"
  done
  set +e
  timeout 5s "$program" >"$program.stdout" 2>"$program.stderr"
  status=$?
  set -e
  [ "$status" -eq 0 ]
  [ ! -s "$program.stdout" ]
  [ ! -s "$program.stderr" ]
  readelf -hW "$program" | grep -q 'Entry point address:'
  ! readelf -lW "$program" | grep -q 'GNU_STACK.*E'
  [ -z "$(nm -u "$program" 2>/dev/null || true)" ]
done

[ "$(sha256sum "$tmp/a.asm" | awk '{print $1}')" = "$(sha256sum "$tmp/b.asm" | awk '{print $1}')" ]
[ "$(sha256sum "$tmp/program-a" | awk '{print $1}')" = "$(sha256sum "$tmp/program-b" | awk '{print $1}')" ]
