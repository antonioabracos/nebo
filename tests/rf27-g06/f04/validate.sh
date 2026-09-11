#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"

ninja -f build.ninja -j2 rf27-g06-f04-slice-view-tests >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g06-f04.XXXXXX)

build/tests/rf27-g06-f04/slice_view_native_test >"$tmp_root/native.1.stdout" 2>"$tmp_root/native.1.stderr"
build/tests/rf27-g06-f04/slice_view_native_test >"$tmp_root/native.2.stdout" 2>"$tmp_root/native.2.stderr"
test ! -s "$tmp_root/native.1.stdout"
test ! -s "$tmp_root/native.1.stderr"
test ! -s "$tmp_root/native.2.stdout"
test ! -s "$tmp_root/native.2.stderr"

declare -A exits=(
  [slice-read.no]=6
  [slice-length.no]=4
  [slice-subslice.no]=6
  [slice-sum.no]=20
  [slice-bool-read.no]=1
  [slice-empty.no]=0
  [slice-release.no]=0
  [slice-two-borrows.no]=9
)
for name in "${!exits[@]}"; do
  source="tests/rf27-g06/f04/positive/$name"
  build/bin/neboc check "$source" >"$tmp_root/$name.check.stdout" 2>"$tmp_root/$name.check.stderr"
  test ! -s "$tmp_root/$name.check.stdout"
  test ! -s "$tmp_root/$name.check.stderr"
  build/bin/neboc emit-asm "$source" -o "$tmp_root/$name.a.asm" >"$tmp_root/$name.emit-a.stdout" 2>"$tmp_root/$name.emit-a.stderr"
  build/bin/neboc emit-asm "$source" -o "$tmp_root/$name.b.asm" >"$tmp_root/$name.emit-b.stdout" 2>"$tmp_root/$name.emit-b.stderr"
  test ! -s "$tmp_root/$name.emit-a.stdout"
  test ! -s "$tmp_root/$name.emit-a.stderr"
  test ! -s "$tmp_root/$name.emit-b.stdout"
  test ! -s "$tmp_root/$name.emit-b.stderr"
  cmp -s "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  build/bin/neboc build "$source" -o "$tmp_root/$name.elf" >"$tmp_root/$name.build.stdout" 2>"$tmp_root/$name.build.stderr"
  test ! -s "$tmp_root/$name.build.stdout"
  test ! -s "$tmp_root/$name.build.stderr"
  set +e
  "$tmp_root/$name.elf"
  rc=$?
  set -e
  test "$rc" -eq "${exits[$name]}"
  file "$tmp_root/$name.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$tmp_root/$name.elf" | rg -q INTERP
done

declare -A diagnostics=(
  [mutation-conflict.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-022: live Slice view blocks owner mutation'
  [slice-escape.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-023: borrowed Slice view cannot escape its lexical owner scope'
  [slice-bounds.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-005: Array index is outside the compile-time bounded value'
  [subslice-bounds.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-005: Array index is outside the compile-time bounded value'
  [released-view.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-007: Slice view is released, stale or has an invalid bounded layout'
  [sum-wrong-type.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-019: Array or Range value has the wrong bounded scalar type'
  [dynamic-subslice.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-020: Array index must be a compile-time Int in this bounded profile'
  [mutation-unavailable.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-024: Slice operation is outside the bounded F04 surface'
)
for name in "${!diagnostics[@]}"; do
  source="tests/rf27-g06/f04/negative/$name"
  for mode in check emit-asm build; do
    stdout="$tmp_root/$name.$mode.stdout"
    stderr="$tmp_root/$name.$mode.stderr"
    artifact="$tmp_root/$name.$mode.artifact"
    set +e
    if [[ $mode == check ]]; then
      build/bin/neboc check "$source" >"$stdout" 2>"$stderr"
    elif [[ $mode == emit-asm ]]; then
      build/bin/neboc emit-asm "$source" -o "$artifact" >"$stdout" 2>"$stderr"
    else
      build/bin/neboc build "$source" -o "$artifact" >"$stdout" 2>"$stderr"
    fi
    rc=$?
    set -e
    test "$rc" -eq 1
    test ! -s "$stdout"
    test ! -e "$artifact"
    test "$(sed -n '1p' "$stderr")" = "${diagnostics[$name]}"
    test "$(sed -n '2p' "$stderr")" = 'neboc: source validation failed'
    test "$(wc -l < "$stderr")" -eq 2
  done
done

for unit in \
  compiler/semantic/collections/slice_view.asm \
  compiler/semantic/collections/array_range.asm \
  compiler/lowering/collections/slice_view_plan.asm \
  compiler/lowering/collections/slice_view_layout.asm \
  compiler/codegen/collections/x86_64/slice_view_codegen.asm \
  tests/types/rf27_g06_f04_slice_view_native_test.asm; do
  stem=$(basename "$unit" .asm)
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.a.o" "$unit"
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.b.o" "$unit"
  cmp -s "$tmp_root/$stem.a.o" "$tmp_root/$stem.b.o"
done
ld -z noexecstack -o "$tmp_root/native.a" \
  "$tmp_root/rf27_g06_f04_slice_view_native_test.a.o" \
  "$tmp_root/slice_view_layout.a.o" build/obj/process_exit.o
ld -z noexecstack -o "$tmp_root/native.b" \
  "$tmp_root/rf27_g06_f04_slice_view_native_test.b.o" \
  "$tmp_root/slice_view_layout.b.o" build/obj/process_exit.o
cmp -s "$tmp_root/native.a" "$tmp_root/native.b"
"$tmp_root/native.a"
test -z "$(nm -u "$tmp_root/native.a")"
file "$tmp_root/native.a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW "$tmp_root/native.a" | rg -q INTERP

# Exact descriptor, pointerless plan, lexical cleanup and public-surface fence.
rg -q '%define neboc_option_result_null_externo_e_erros_tipados_SLICE_SIZE 40' compiler/lowering/collections/slice_view_layout.inc
rg -q '%define NEBOC_SLICE_VIEW_LAYOUT_SLICE_GENERATION_OFFSET 24' compiler/lowering/collections/slice_view_layout.inc
rg -q '%define NEBOC_SLICE_TOKEN_OFFSET 32' compiler/lowering/collections/slice_view_layout.inc
rg -q 'neboc_slice_cleanup' compiler/semantic/collections/array_range.asm
rg -q 'NEBOC_SLICE_PLAN_HASHED_BYTES' compiler/lowering/collections/slice_view_plan.asm
! rg -q 'Slice\.from(Buffer|Bytes)' compiler tests/rf27-g06/f04
! rg -q '^profiles:|source_sha|source fingerprint|basename' compiler/semantic/collections/slice_view.asm compiler/lowering/collections/slice_view_plan.asm

# Closed direct dependencies remain green.
tests/rf27-g06/f03/validate.sh >/dev/null
tests/rf27-g04/f03/validate.sh >/dev/null

echo "RF27_G06_F04_GREEN positives=8 negative_fixtures=8 negative_tri_mode=24 native_vectors=13 slice_size=40 array_and_bytes=yes lexical_generation=yes mutation_conflict=yes escape_rejected=yes checked_bounds=yes deterministic_asm=16 deterministic_objects=12 deterministic_elf=1 static_elf=9 g06_f03=yes g04_f03=yes tmp=$tmp_root"
