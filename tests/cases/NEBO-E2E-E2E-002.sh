#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

source=tests/e2e/core/functions/soma.no
recursive=tests/e2e/core/functions/recursive.no
expected=tests/e2e/core/functions/soma.expected.asm

build/bin/neboc check "$source" >"$tmp/check.out" 2>"$tmp/check.err"
test ! -s "$tmp/check.out"
test ! -s "$tmp/check.err"

build/bin/neboc emit-asm "$source" -o "$tmp/soma-a.asm"
build/bin/neboc emit-asm "$source" -o "$tmp/soma-b.asm"
cmp -s "$tmp/soma-a.asm" "$tmp/soma-b.asm"
cmp -s "$tmp/soma-a.asm" "$expected"
nasm -f elf64 -Wall -Werror -o "$tmp/soma.o" "$tmp/soma-a.asm"

build/bin/neboc build "$source" -o "$tmp/soma-a" --keep-temp
build/bin/neboc build "$source" -o "$tmp/soma-b"
cmp -s "$tmp/soma-a" "$tmp/soma-b"
cmp -s "$tmp/soma-a.neboc.asm" "$expected"
test -s "$tmp/soma-a.neboc.o"
test ! -e "$tmp/soma-b.neboc.asm"
test ! -e "$tmp/soma-b.neboc.o"

for exe in "$tmp/soma-a" "$tmp/soma-b"; do
  status=0
  if timeout 5s "$exe" >"$exe.stdout" 2>"$exe.stderr"; then status=0; else status=$?; fi
  printf 'MF038_SOMA_RUN executable=%s expected=5 observed=%s\n' "$(basename "$exe")" "$status"
  test "$status" -eq 5
  test ! -s "$exe.stdout"
  test ! -s "$exe.stderr"
  ./scripts/mf037/verify-no-c-structural.sh "$exe" >/dev/null
  test -z "$(nm -u "$exe" 2>/dev/null || true)"
  symbols="$tmp/$(basename "$exe").defined-symbols"
  nm -g --defined-only "$exe" > "$symbols"
  for symbol in _start nebo_fn_1 nebo_fn_2 nebo_runtime_start nebo_runtime_exit; do
    grep -Eq "[[:space:]]${symbol}$" "$symbols"
  done
done

grep -q '^global nebo_fn_2$' "$tmp/soma-a.asm"
grep -q '^    mov \[rbp-8\], rdi$' "$tmp/soma-a.asm"
grep -q '^    mov \[rbp-16\], rsi$' "$tmp/soma-a.asm"
grep -q '^    call nebo_fn_2$' "$tmp/soma-a.asm"
grep -q '^    ret$' "$tmp/soma-a.asm"

set +e
build/bin/neboc emit-asm "$recursive" -o "$tmp/recursive.asm" >"$tmp/recursive.out" 2>"$tmp/recursive.err"
recursive_status=$?
set -e
test "$recursive_status" -eq 1
test ! -e "$tmp/recursive.asm"

echo NEBO_E2E_E2E_002_GREEN
