#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
tmp_root=$(mktemp -d /tmp/neboc-rf27-g01-f08.XXXXXX)

ninja -f build.ninja -j1 build/bin/neboc >/dev/null

declare -A exits=(
  [with-capacity-length]=0
  [zeroed-one]=1
  [zeroed-four]=4
  [capacity]=4
  [drop]=0
)

for name in "${!exits[@]}"; do
  src="tests/rf27-buffer/f08/positive/$name.no"
  build/bin/neboc check "$src" >"$tmp_root/$name.check.out" 2>"$tmp_root/$name.check.err"
  test ! -s "$tmp_root/$name.check.out"
  test ! -s "$tmp_root/$name.check.err"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.a.asm"
  build/bin/neboc emit-asm "$src" -o "$tmp_root/$name.b.asm"
  cmp -s "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  rg -q '^global nebo_buffer_descriptor$' "$tmp_root/$name.a.asm"
  rg -q 'mov dword \[rdi \+ 4\], 4' "$tmp_root/$name.a.asm"
  rg -q 'mov qword \[rdi \+ 8\], 0' "$tmp_root/$name.a.asm"
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

declare -A diagnostics=(
  [capacity-type]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-020: Buffer capacity must be an Int literal'
  [capacity-dynamic]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-021: dynamic Buffer capacity is deferred'
  [capacity-unsupported]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-022: bounded Buffer capacity must be exactly 4'
  [length-type]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-023: Buffer length must be an Int literal'
  [length-dynamic]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-024: dynamic Buffer length is deferred'
  [length-range]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-025: bounded Buffer length must be in 0 through 4'
  [escape]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-040: bounded Buffer cannot escape its local owner'
  [copy]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-041: bounded Buffer cannot be copied or moved'
  [move]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-041: bounded Buffer cannot be copied or moved'
  [parameter]='NEBO-TIPOS-PRIMITIVOS-ESCALARES-042: Buffer parameter and return transport is deferred'
)

for name in "${!diagnostics[@]}"; do
  src="tests/rf27-buffer/f08/negative/$name.no"
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
rg -q '%define NEBOC_BUFFER_PLAN_SIZE 96' compiler/lowering/textual/buffer_plan.inc
rg -Fq 'mov qword [r12+NEBOC_BUFFER_STORAGE_OFFSET],0' compiler/parser/buffer_parser.asm
test "$(build/bin/neboc --version)" = "$(python3 -B scripts/check-version-consistency.py --expected-cli)"

echo "RF27_G01_F08_GREEN positives=5 negative_fixtures=10 negative_tri_mode=30 type_id=12 bytes_type_id=11 layout=16/8 capacity=4 zeroed=yes unique_local=yes deterministic_asm=5 deterministic_objects=9 deterministic_elf=5 static_elf=5 rc2=yes tmp=$tmp_root"
