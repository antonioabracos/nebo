#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
source=tests/e2e/core/control/if-false-else.no
build/bin/neboc check "$source"
build/bin/neboc emit-asm "$source" -o "$tmp/a.asm"
build/bin/neboc emit-asm "$source" -o "$tmp/b.asm"
cmp -s "$tmp/a.asm" "$tmp/b.asm"
grep -q 'jnz \.nebo_bool_true_' "$tmp/a.asm"
build/bin/neboc build "$source" -o "$tmp/a" --keep-temp
build/bin/neboc build "$source" -o "$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
for exe in "$tmp/a" "$tmp/b"; do
  status=0; if timeout 5s "$exe" >"$exe.out" 2>"$exe.err"; then status=0; else status=$?; fi
  printf 'MF039_OR_RUN expected=9 observed=%s\n' "$status"
  test "$status" -eq 9; test ! -s "$exe.out"; test ! -s "$exe.err"
  ./scripts/mf037/verify-no-c-structural.sh "$exe" >/dev/null
done
echo NEBO_CONTROL_E2E_002_GREEN
