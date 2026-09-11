#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_sources=(
  compiler/semantic/operators/core_arithmetic_registry.asm
  compiler/semantic/operators/core_checked_arithmetic.asm
  compiler/semantic/operators/core_signed_divrem.asm
  compiler/semantic/operators/core_power.asm
  compiler/parser/expression/core_prefix_power.asm
  compiler/lowering/operators/compound_mul_div.asm
  compiler/lowering/operators/compound_rem_power.asm
  compiler/optimizer/core_operator_fold.asm
)
for rf148_run in a b; do
  for rf148_source in "${rf148_sources[@]}"; do
    rf148_name=$(basename "${rf148_source%.asm}")
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name-$rf148_run.o" "$rf148_source"
  done
done
for rf148_source in "${rf148_sources[@]}"; do
  rf148_name=$(basename "${rf148_source%.asm}")
  cmp "$rf148_tmp/$rf148_name-a.o" "$rf148_tmp/$rf148_name-b.o"
done
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g122/arithmetic_conformance_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/core_arithmetic_registry-a.o" \
  "$rf148_tmp/core_checked_arithmetic-a.o" \
  "$rf148_tmp/core_signed_divrem-a.o" \
  "$rf148_tmp/core_power-a.o" \
  "$rf148_tmp/core_prefix_power-a.o" \
  "$rf148_tmp/compound_mul_div-a.o" \
  "$rf148_tmp/compound_rem_power-a.o" \
  "$rf148_tmp/core_operator_fold-a.o"
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

ninja neboc >/dev/null
tests/rf148/g121/evaluation-conformance.sh >/dev/null
tests/rf148/g120/operator-resolution-gate.sh >/dev/null

for rf148_symbol in \
  neboc_core_arithmetic_registry_table \
  neboc_core_checked_add neboc_core_checked_subtract \
  neboc_core_checked_multiply neboc_core_checked_divide \
  neboc_core_checked_remainder neboc_core_prefix_power_binding \
  neboc_compound_multiply neboc_compound_divide \
  neboc_compound_remainder neboc_compound_power \
  neboc_core_fold_binary neboc_core_fold_prefix; do
  test "$(nm -g --defined-only build/bin/neboc | awk -v name="$rf148_symbol" '$3 == name {count++} END {print count+0}')" -eq 1
done

printf '%s\n' 'RF148_G122_ARITHMETIC_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_ROWS=14'
printf '%s\n' 'CHECKED_ADD_SUB_MUL_DIV_REM=PASS'
printf '%s\n' 'COMPOUND_ASSIGNMENT_ATOMICITY=PASS'
printf '%s\n' 'PREFIX_POWER_PRECEDENCE=PASS'
printf '%s\n' 'CONSTANT_FOLD_PARITY=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
printf '%s\n' 'LIVE_COMPILER_INTEGRATION=PASS'
