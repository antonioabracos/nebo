#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
work=${TMPDIR:-/tmp}/nebo-c11-f13-r2-selected-surface-validation
mkdir -p "$work/sources"
compiler="$repo/build/bin/neboc"
registry="$repo/tests/c11/f13/selected-surface-cases.tsv"

count=0
while IFS=$'\t' read -r surface expected source; do
  test "$surface" != surface || continue
  file="$work/sources/$surface.no"
  printf '%s\n' "$source" >"$file"
  "$compiler" check "$file"
  "$compiler" emit-asm "$file" -o "$work/$surface.a.asm"
  "$compiler" emit-asm "$file" -o "$work/$surface.b.asm"
  cmp "$work/$surface.a.asm" "$work/$surface.b.asm"
  TMPDIR="$work" "$compiler" build "$file" -o "$work/$surface.elf"
  set +e
  "$work/$surface.elf"
  actual=$?
  set -e
  test "$actual" -eq "$expected"
  count=$((count + 1))
done <"$registry"

test "$count" -eq 30
test "$(tail -n +2 "$registry" | cut -f1 | sort -u | wc -l)" -eq 30
test -f "$repo/sdk/interfaces/scientific/matrix-int-v1.ni.identity"
test "$(head -c -1 "$repo/sdk/interfaces/scientific/matrix-int-v1.ni.identity" | sha256sum | cut -d' ' -f1)" = \
  75db9f8312f19dbb56b31d7f180d7266f8655b03997e5641524bed1019454fd0
rg -q '^%define NEBO_MATRIX_I64_NBM1_MAX_BYTES 560$' "$repo/runtime/matrix/matrix_i64.inc"
rg -q 'call nebo_matrix_i64_serialize' "$work/deserializeNBM1.a.asm"
rg -q 'call nebo_matrix_i64_deserialize' "$work/deserializeNBM1.a.asm"
rg -q 'call nebo_matrix_i64_borrow_sum' "$work/function_parameter.a.asm"
rg -q '^matrix_user_f:$' "$work/function_return.a.asm"
