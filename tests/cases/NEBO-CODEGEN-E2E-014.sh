#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
ninja neboc >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cp tests/e2e/core/start/start-empty.no "$tmp/start.no"

build/bin/neboc emit-asm "$tmp/start.no" -o "$tmp/start.asm" >"$tmp/emit.out" 2>"$tmp/emit.err"
[ ! -s "$tmp/emit.out" ]
[ ! -s "$tmp/emit.err" ]
cmp -s "$tmp/start.asm" tests/cli/goldens/minimal-start.asm

grep -q '^global _start$' "$tmp/start.asm"
grep -q '^extern nebo_runtime_start$' "$tmp/start.asm"
grep -q '^_start:$' "$tmp/start.asm"
grep -q '^[[:space:]]*lea rdi, \[rel nebo_fn_1\]$' "$tmp/start.asm"
grep -q '^[[:space:]]*call nebo_runtime_start$' "$tmp/start.asm"
grep -q '^nebo_fn_1:$' "$tmp/start.asm"

build/bin/neboc build "$tmp/start.no" -o "$tmp/program" >"$tmp/build.out" 2>"$tmp/build.err"
[ ! -s "$tmp/build.out" ]
[ ! -s "$tmp/build.err" ]
[ -x "$tmp/program" ]
[ ! -e "$tmp/program.neboc.asm" ]
[ ! -e "$tmp/program.neboc.o" ]

readelf -hW "$tmp/program" | grep -q 'Class:[[:space:]]*ELF64'
readelf -hW "$tmp/program" | grep -q 'Type:[[:space:]]*EXEC'
readelf -hW "$tmp/program" | grep -q 'Machine:[[:space:]]*Advanced Micro Devices X86-64'
! readelf -lW "$tmp/program" | grep -q 'INTERP'
! readelf -dW "$tmp/program" 2>/dev/null | grep -q '(NEEDED)'
[ -z "$(nm -u "$tmp/program" 2>/dev/null || true)" ]
! readelf -sW "$tmp/program" | grep -q 'program.neboc.asm'
for symbol in _start nebo_fn_1 nebo_runtime_start nebo_runtime_exit; do
  nm -g --defined-only "$tmp/program" | grep -Eq "[[:space:]]${symbol}$"
done

set +e
timeout 5s "$tmp/program" >"$tmp/run.out" 2>"$tmp/run.err"
status=$?
set -e
[ "$status" -eq 0 ]
[ ! -s "$tmp/run.out" ]
[ ! -s "$tmp/run.err" ]
./scripts/mf002/verify-no-c.sh "$tmp/program" >"$tmp/no-c.log"
grep -q '^MF002_NO_C_GREEN$' "$tmp/no-c.log"
