#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
tmp_root=$(mktemp -d /tmp/neboc-rf27-g01-f11.XXXXXX)

ninja -f build.ninja -j1 build/bin/neboc >/dev/null

declare -A exits=(
  [view-read]=42
  [view-length]=3
  [subview-read]=99
  [view-sum]=6
  [empty-view]=0
  [release-then-mutate]=42
)

for name in "${!exits[@]}"; do
  src="tests/rf27-buffer/f11/positive/$name.no"
  build/bin/neboc check "$src" >"$tmp_root/$name.check.out" 2>"$tmp_root/$name.check.err"
  test ! -s "$tmp_root/$name.check.out"
  test ! -s "$tmp_root/$name.check.err"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.a.asm"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.b.asm"
  cmp -s "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  rg -q '^global nebo_public_slice_descriptor$' "$tmp_root/$name.a.asm"
  rg -q '^    dq nebo_public_slice_storage$' "$tmp_root/$name.a.asm"
  rg -q '^    dq 1$' "$tmp_root/$name.a.asm"
  rg -q '^    dq 12$' "$tmp_root/$name.a.asm"
  nasm -f elf64 -o "$tmp_root/$name.a.o" "$tmp_root/$name.a.asm"
  nasm -f elf64 -o "$tmp_root/$name.b.o" "$tmp_root/$name.a.asm"
  cmp -s "$tmp_root/$name.a.o" "$tmp_root/$name.b.o"
  build/bin/neboc build "$src" -o "$tmp_root/$name.a.elf"
  build/bin/neboc build "$src" -o "$tmp_root/$name.b.elf"
  cmp -s "$tmp_root/$name.a.elf" "$tmp_root/$name.b.elf"
  set +e
  "$tmp_root/$name.a.elf"
  rc=$?
  set -e
  test "$rc" -eq "${exits[$name]}"
  file "$tmp_root/$name.a.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$tmp_root/$name.a.elf" | rg -q INTERP
  test -z "$(nm -u "$tmp_root/$name.a.elf")"
done

rg -q '^nebo_public_slice_storage: dd 42$' "$tmp_root/view-read.a.asm"
rg -q '^nebo_public_slice_storage: dd 99$' "$tmp_root/subview-read.a.asm"
rg -q '^nebo_public_slice_storage: dd 197121$' "$tmp_root/view-sum.a.asm"

declare -A diagnostics=(
  [view-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-045: bounded Slice range or index is outside owner bounds'
  [view-reversed]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-045: bounded Slice range or index is outside owner bounds'
  [read-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-045: bounded Slice range or index is outside owner bounds'
  [subview-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-045: bounded Slice range or index is outside owner bounds'
  [escape]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-046: bounded Slice cannot escape its lexical owner'
  [mutation-conflict]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-047: Buffer mutation conflicts with a live Slice view'
  [released-view]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-048: bounded Slice view is stale or released'
  [stale-owner]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-048: bounded Slice view is stale or released'
  [view-arity]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-050: bounded Slice method received the wrong number of arguments'
)

for name in "${!diagnostics[@]}"; do
  src="tests/rf27-buffer/f11/negative/$name.no"
  for mode in check emit-asm build; do
    stdout="$tmp_root/$name.$mode.out"
    stderr="$tmp_root/$name.$mode.err"
    artifact="$tmp_root/$name.$mode.artifact"
    set +e
    if [[ $mode == check ]]; then
      build/bin/neboc check "$src" >"$stdout" 2>"$stderr"
    else
      build/bin/neboc "$mode" "$src" -o "$artifact" >"$stdout" 2>"$stderr"
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
  compiler/parser/buffer_parser.asm \
  compiler/semantic/types/buffer_semantic.asm \
  compiler/lowering/textual/buffer_plan.asm \
  compiler/codegen/textual/x86_64/buffer_codegen.asm \
  compiler/semantic/types/type_table.asm; do
  stem=$(basename "$unit" .asm)
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.a.o" "$unit"
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.b.o" "$unit"
  cmp -s "$tmp_root/$stem.a.o" "$tmp_root/$stem.b.o"
done

rg -q '%define NEBOC_TYPE_ID_SLICE 13' compiler/semantic/types/type_table.inc
rg -q '%define NEBOC_PUBLIC_SLICE_LAYOUT_SIZE 40' compiler/semantic/collections/public_slice.inc
rg -q '%define NEBOC_BUFFER_PLAN_F11_SIZE 264' compiler/lowering/textual/buffer_plan.inc
rg -q 'NEBOC_BUFFER_PLAN_VERSION_A3' compiler/lowering/textual/buffer_plan.asm
rg -q 'NEBOC_BUFFER_PLAN_F11_HASH_OFFSET' compiler/codegen/textual/x86_64/buffer_codegen.asm
test "$(git rev-parse 'nebo-v0.2.0-rc.2^{}')" = e055debd358a747f8793015546162e31fe9b3370
test "$(sha256sum release/package/nebo-v0.2.0-rc.2-x86_64-systemv-elf-linux.zip | cut -d' ' -f1)" = \
  1fad420b226eef186179819a2ca2b459cb621b412fb30bf056709388b0762f8d
test "$(build/bin/neboc --version)" = 'neboc 0.2.0-rc.2'

echo "RF27_G01_F11_GREEN positives=6 negative_fixtures=9 negative_tri_mode=27 slice_type_id=13 layout=40/8 buffer_view=yes read=yes subview=yes iterate=yes lexical_release=yes mutation_conflict=yes stale_detection=yes deterministic_asm=6 deterministic_objects=11 deterministic_elf=6 static_elf=6 rc2=yes tmp=$tmp_root"
