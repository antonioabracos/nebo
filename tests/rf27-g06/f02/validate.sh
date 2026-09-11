#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"

ninja -f build.ninja -j2 rf27-g06-f02-product-tests g09-pf005 >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g06-f02.XXXXXX)

build/tests/rf27-g06-f02/product_native_test >"$tmp_root/native.1.stdout" 2>"$tmp_root/native.1.stderr"
build/tests/rf27-g06-f02/product_native_test >"$tmp_root/native.2.stdout" 2>"$tmp_root/native.2.stderr"
test ! -s "$tmp_root/native.1.stdout"
test ! -s "$tmp_root/native.1.stderr"
test ! -s "$tmp_root/native.2.stdout"
test ! -s "$tmp_root/native.2.stderr"

declare -A exits=(
  [named-struct-access.no]=9
  [nested-struct-access.no]=5
  [padding-layout.no]=12
  [text-drop-layout.no]=4
  [tuple-access.no]=7
)
for name in "${!exits[@]}"; do
  source="tests/rf27-g06/f02/positive/$name"
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

# ARRAY-VERTICAL-AUD-001 removes exact-source ownership.  Plain named-struct
# declaration/literal semantics now have one canonical structural owner: G09.
# RF27-G06-F02 remains the canonical owner of Tuple and checked product-layout
# constraints.  The ordered list makes the first failure deterministic.
declare -A diagnostics=(
  [duplicate-field.no]='NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DUPLICATE-FIELD: field is declared or initialized more than once'
  [layout-overflow.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-003: composite layout exceeds the checked bounded profile'
  [recursive-layout.no]='NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-RECURSIVE-BY-VALUE: recursive by-value programmer type is unavailable'
  [tuple-bounds.no]='NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-005: Tuple position is outside the constructed value'
  [type-mismatch.no]='NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-FIELD-TYPE-MISMATCH: field value must have its exact declared type'
  [unknown-field.no]='NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-UNKNOWN-FIELD: field is not declared by this nominal type'
  [wrong-arity.no]='NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-MISSING-FIELD: struct literal must initialize every declared field'
)
diagnostic_order=(
  duplicate-field.no
  recursive-layout.no
  type-mismatch.no
  unknown-field.no
  wrong-arity.no
  layout-overflow.no
  tuple-bounds.no
)
for name in "${diagnostic_order[@]}"; do
  source="tests/rf27-g06/f02/negative/$name"
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
  compiler/semantic/types/struct_tuple.asm \
  compiler/lowering/aggregates/product_layout.asm \
  compiler/lowering/aggregates/struct_tuple_plan.asm \
  compiler/codegen/aggregates/x86_64/struct_tuple_codegen.asm \
  tests/types/rf27_g06_f02_product_native_test.asm; do
  stem=$(basename "$unit" .asm)
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.a.o" "$unit"
  nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/$stem.b.o" "$unit"
  cmp -s "$tmp_root/$stem.a.o" "$tmp_root/$stem.b.o"
done
ld -z noexecstack -o "$tmp_root/native.a" \
  "$tmp_root/rf27_g06_f02_product_native_test.a.o" \
  "$tmp_root/product_layout.a.o" build/obj/process_exit.o
ld -z noexecstack -o "$tmp_root/native.b" \
  "$tmp_root/rf27_g06_f02_product_native_test.b.o" \
  "$tmp_root/product_layout.b.o" build/obj/process_exit.o
cmp -s "$tmp_root/native.a" "$tmp_root/native.b"
"$tmp_root/native.a"
test -z "$(nm -u "$tmp_root/native.a")"
file "$tmp_root/native.a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW "$tmp_root/native.a" | rg -q INTERP

# Closed G09 exact-profile compatibility and direct dependency regressions.
python3 scripts/g09-pf005/validate-model.py >/dev/null
build/tests/g09-pf002/programmer_type_contract_test
build/tests/g09-pf003/programmer_type_semantic_test
build/tests/g09-pf004/programmer_type_native_test
tests/rf27-g04/f06/validate.sh >/dev/null
bash scripts/rf27-g02/validate-f04.sh >/dev/null
bash scripts/rf27-g01/validate-focused.sh >/dev/null
python3 scripts/pre-g173-bridge/validate-rf27-g04-g06-f01-canonical.py >/dev/null

rg -q 'NEBOC_TOKEN_KW_STRUCT' compiler/semantic/types/struct_tuple.asm
rg -q 'NEBOC_TOKEN_RESERVED_COLON' compiler/semantic/types/struct_tuple.asm
rg -q 'neboc_option_result_null_externo_e_erros_tipados_PLAN_HASHED_BYTES' compiler/lowering/aggregates/struct_tuple_plan.asm
! rg -q 'g06.*profiles|source_sha|source fingerprint' compiler/semantic/types/struct_tuple.asm

echo "RF27_G06_F02_GREEN positives=5 negative_fixtures=7 negative_tri_mode=21 native_vectors=8 structural_parser=yes nested_layout=yes reverse_drop_proof=yes pass_return=yes deterministic_asm=10 deterministic_objects=10 deterministic_elf=1 static_elf=6 no_c_no_libc=yes g09_compat=yes plain_struct_diagnostics=G09_CANONICAL product_layout_diagnostics=RF27_G06_CANONICAL tmp=$tmp_root"
