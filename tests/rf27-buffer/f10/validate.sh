#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
tmp_root=$(mktemp -d /tmp/neboc-rf27-g01-f10.XXXXXX)

ninja -f build.ninja -j1 build/bin/neboc >/dev/null

declare -A exits=(
  [freeze-empty]=0
  [freeze-one]=77
  [freeze-four]=4
  [source-unchanged]=42
  [freeze-composition]=99
)

for name in "${!exits[@]}"; do
  src="tests/rf27-buffer/f10/positive/$name.no"
  build/bin/neboc check "$src" >"$tmp_root/$name.check.out" 2>"$tmp_root/$name.check.err"
  test ! -s "$tmp_root/$name.check.out"
  test ! -s "$tmp_root/$name.check.err"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.a.asm"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.b.asm"
  cmp -s "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  rg -q '^global nebo_frozen_bytes_descriptor$' "$tmp_root/$name.a.asm"
  rg -q '^    dq nebo_frozen_bytes_storage$' "$tmp_root/$name.a.asm"
  rg -q '^    dd 3$' "$tmp_root/$name.a.asm"
  rg -q '^    dw 1$' "$tmp_root/$name.a.asm"
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

rg -q '^nebo_frozen_bytes_storage: dd 0$' "$tmp_root/freeze-empty.a.asm"
rg -q '^    dq 0$' "$tmp_root/freeze-empty.a.asm"
rg -q '^nebo_frozen_bytes_storage: dd 77$' "$tmp_root/freeze-one.a.asm"
rg -q '^    dq 1$' "$tmp_root/freeze-one.a.asm"
rg -q '^nebo_frozen_bytes_storage: dd 1660944384$' "$tmp_root/freeze-composition.a.asm"
rg -q '^    dq 4$' "$tmp_root/freeze-composition.a.asm"
rg -q 'mov qword \[rdi \+ 8\], 42$' "$tmp_root/source-unchanged.a.asm"
rg -q '^nebo_frozen_bytes_storage: dd 42$' "$tmp_root/source-unchanged.a.asm"

declare -A diagnostics=(
  [freeze-length-two]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-043: bounded Buffer freeze supports lengths 0 1 and 4'
  [freeze-length-three]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-043: bounded Buffer freeze supports lengths 0 1 and 4'
  [frozen-at-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-030: Buffer read index is outside logical length'
  [freeze-after-drop]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-041: bounded Buffer cannot be copied or moved'
)

for name in "${!diagnostics[@]}"; do
  src="tests/rf27-buffer/f10/negative/$name.no"
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
  compiler/codegen/textual/x86_64/buffer_codegen.asm; do
  stem=$(basename "$unit" .asm)
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.a.o" "$unit"
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.b.o" "$unit"
  cmp -s "$tmp_root/$stem.a.o" "$tmp_root/$stem.b.o"
done

rg -q '%define NEBOC_TYPE_ID_BYTES 11' compiler/semantic/types/type_table.inc
rg -q '%define NEBOC_TYPE_ID_BUFFER 12' compiler/semantic/types/type_table.inc
rg -q '%define NEBOC_BUFFER_F10_REQUEST_SIZE 224' compiler/semantic/types/buffer_freeze.inc
rg -q '%define NEBOC_BUFFER_PLAN_F10_SIZE 184' compiler/lowering/textual/buffer_plan.inc
rg -q 'NEBOC_BUFFER_PLAN_VERSION_A2' compiler/lowering/textual/buffer_plan.inc
rg -q 'NEBOC_BUFFER_PLAN_VERSION_A3' compiler/lowering/textual/buffer_plan.asm
rg -q 'NEBOC_BUFFER_PLAN_F10_HASH_OFFSET' compiler/codegen/textual/x86_64/buffer_codegen.asm
test "$(build/bin/neboc --version)" = "$(python3 -B scripts/check-version-consistency.py --expected-cli)"

echo "RF27_G01_F10_GREEN positives=5 negative_fixtures=4 negative_tri_mode=12 freeze_lengths=0_1_4 copy_visible=yes source_unchanged=yes bytes_type_id=11 buffer_type_id=12 bytes_layout=24/8 zero_copy=no deterministic_asm=5 deterministic_objects=9 deterministic_elf=5 static_elf=5 rc2=yes tmp=$tmp_root"
