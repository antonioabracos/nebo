#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
source=tests/e2e/core/control/text-binding-equivalence.no
typed_source=tests/e2e/core/control/typed-text-equality.no
invalid=tests/e2e/core/control/type-mismatch.no
build/bin/neboc check "$source" >"$tmp/check.out" 2>"$tmp/check.err"
test ! -s "$tmp/check.out"; test ! -s "$tmp/check.err"
build/bin/neboc emit-asm "$source" -o "$tmp/a.asm"
build/bin/neboc emit-asm "$source" -o "$tmp/b.asm"
cmp -s "$tmp/a.asm" "$tmp/b.asm"
grep -q '^extern nebo_runtime_text_equal$' "$tmp/a.asm"
test "$(grep -c '^nebo_text_desc_[0-9][0-9]*:$' "$tmp/a.asm")" -eq 2
test "$(grep -c '^    call nebo_runtime_text_equal$' "$tmp/a.asm")" -eq 1
grep -q '^    mov \[rbp - 8\], rax$' "$tmp/a.asm"
grep -q '^    mov \[rbp - 16\], rax$' "$tmp/a.asm"
grep -q '^    mov \[rbp - 24\], rax$' "$tmp/a.asm"
grep -q '^    mov \[rbp - 32\], rax$' "$tmp/a.asm"
build/bin/neboc build "$source" -o "$tmp/a" --keep-temp
build/bin/neboc build "$source" -o "$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
for exe in "$tmp/a" "$tmp/b"; do
  status=0; if timeout 5s "$exe" >"$exe.out" 2>"$exe.err"; then status=0; else status=$?; fi
  printf 'MF039_TEXT_BINDING_RUN expected=7 observed=%s\n' "$status"
  test "$status" -eq 7; test ! -s "$exe.out"; test ! -s "$exe.err"
  ./scripts/mf037/verify-no-c-structural.sh "$exe" >/dev/null
  symbols="$tmp/$(basename "$exe").defined-symbols"
  nm -g --defined-only "$exe" > "$symbols"
  grep -Eq '[[:space:]]nebo_runtime_text_equal$' "$symbols"
done
build/bin/neboc check "$typed_source" >"$tmp/typed-check.out" 2>"$tmp/typed-check.err"
test ! -s "$tmp/typed-check.out"; test ! -s "$tmp/typed-check.err"
build/bin/neboc emit-asm "$typed_source" -o "$tmp/typed-a.asm"
build/bin/neboc emit-asm "$typed_source" -o "$tmp/typed-b.asm"
cmp -s "$tmp/typed-a.asm" "$tmp/typed-b.asm"
test "$(grep -c '^extern nebo_runtime_text_equal$' "$tmp/typed-a.asm")" -eq 1
test "$(grep -c '^    call nebo_runtime_text_equal$' "$tmp/typed-a.asm")" -eq 4
test "$(grep -c '^    cmp rax, rcx$' "$tmp/typed-a.asm" || true)" -eq 0
build/bin/neboc build "$typed_source" -o "$tmp/typed-a"
build/bin/neboc build "$typed_source" -o "$tmp/typed-b"
cmp -s "$tmp/typed-a" "$tmp/typed-b"
for exe in "$tmp/typed-a" "$tmp/typed-b"; do
  status=0; if timeout 5s "$exe" >"$exe.out" 2>"$exe.err"; then status=0; else status=$?; fi
  printf 'NPT_LANG_01_TYPED_TEXT_EQUALITY_RUN expected=0 observed=%s\n' "$status"
  test "$status" -eq 0; test ! -s "$exe.out"; test ! -s "$exe.err"
  ./scripts/mf037/verify-no-c-structural.sh "$exe" >/dev/null
done
set +e
build/bin/neboc check "$invalid" >"$tmp/invalid-check.out" 2>"$tmp/invalid-check.err"
check_status=$?
build/bin/neboc emit-asm "$invalid" -o "$tmp/invalid.asm" >"$tmp/invalid.out" 2>"$tmp/invalid.err"
emit_status=$?
set -e
test "$check_status" -eq 1
test "$emit_status" -eq 1
test ! -e "$tmp/invalid.asm"
grep -q 'error NEBO_PARSE_UNEXPECTED_TOKEN:' "$tmp/invalid-check.err"
grep -q 'error NEBO_PARSE_UNEXPECTED_TOKEN:' "$tmp/invalid.err"
echo MF039_CHECK_EXACT_TYPE_VALIDATION_GREEN
echo NEBO_E2E_E2E_003_GREEN
