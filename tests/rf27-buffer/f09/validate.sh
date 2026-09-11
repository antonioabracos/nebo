#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
tmp_root=$(mktemp -d /tmp/neboc-rf27-g01-f09.XXXXXX)

ninja -f build.ninja -j1 build/bin/neboc >/dev/null

declare -A exits=(
  [at-zero]=0
  [get-some]=42
  [set-at]=42
  [push-at]=42
  [push-length]=1
  [full-push-result]=1
  [full-push-atomic]=4
  [clear-prior]=4
  [clear-length]=0
)

for name in "${!exits[@]}"; do
  src="tests/rf27-buffer/f09/positive/$name.no"
  build/bin/neboc check "$src" >"$tmp_root/$name.check.out" 2>"$tmp_root/$name.check.err"
  test ! -s "$tmp_root/$name.check.out"
  test ! -s "$tmp_root/$name.check.err"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.a.asm"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.b.asm"
  cmp -s "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  rg -q '^global nebo_buffer_descriptor$' "$tmp_root/$name.a.asm"
  rg -q 'mov dword \[rdi \+ 4\], 4' "$tmp_root/$name.a.asm"
  rg -q '^; F09 operations are folded in source order into one 16-byte local descriptor\.$' "$tmp_root/$name.a.asm"
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

rg -q 'mov qword \[rdi \+ 8\], 10752$' "$tmp_root/set-at.a.asm"
rg -q 'mov qword \[rdi \+ 8\], 42$' "$tmp_root/push-at.a.asm"
rg -q 'mov qword \[rdi \+ 8\], 0$' "$tmp_root/clear-length.a.asm"

declare -A diagnostics=(
  [byte-below]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-026: Buffer byte must be at least 0'
  [byte-above]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-027: Buffer byte must be at most 255'
  [index-type]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-028: Buffer index must be an Int literal'
  [index-dynamic]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-029: dynamic Buffer index is deferred'
  [read-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-030: Buffer read index is outside logical length'
  [write-bounds]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-031: Buffer write index is outside logical length'
  [arity]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-034: Buffer method received the wrong number of arguments'
  [alias]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-035: Buffer mutation requires a unique local owner'
  [reserve]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-036: Buffer reserve requires a future allocator profile'
  [growth]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-037: bounded Buffer growth is forbidden'
  [extend]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-038: Buffer extend is deferred to a later bounded phase'
)

for name in "${!diagnostics[@]}"; do
  src="tests/rf27-buffer/f09/negative/$name.no"
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

rg -q '%define NEBOC_BUFFER_PLAN_SIZE 96' compiler/lowering/textual/buffer_plan.inc
rg -q '%define NEBOC_BUFFER_PLAN_F09_SIZE 144' compiler/lowering/textual/buffer_plan.inc
rg -q '%define NEBOC_BUFFER_F09_REQUEST_SIZE 184' compiler/parser/buffer_parser.inc
rg -q 'NEBOC_BUFFER_PLAN_VERSION_A1' compiler/lowering/textual/buffer_plan.inc
rg -q 'NEBOC_BUFFER_PLAN_VERSION_A3' compiler/lowering/textual/buffer_plan.asm
rg -q 'NEBOC_BUFFER_PLAN_EXTENSION_HASH_OFFSET' compiler/codegen/textual/x86_64/buffer_codegen.asm
test "$(build/bin/neboc --version)" = "$(python3 -B scripts/check-version-consistency.py --expected-cli)"

echo "RF27_G01_F09_GREEN positives=9 negative_fixtures=11 negative_tri_mode=33 capacity=4 at=yes get_option=yes set_in_place=yes push_result=yes full_atomic=yes clear_zeroes=yes generation_exact=yes deterministic_asm=9 deterministic_objects=13 deterministic_elf=9 static_elf=9 rc2=yes tmp=$tmp_root"
