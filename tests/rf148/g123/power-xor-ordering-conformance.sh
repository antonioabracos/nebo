#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_sources=(
  compiler/tokens/token_kind.asm
  compiler/lexer/lexer.asm
  compiler/lexer/numeric_literal_contract.asm
  compiler/lexer/text_char_literal_contract.asm
  compiler/parser/expression/operator_precedence.asm
  compiler/semantic/operators/core_power_xor_ordering_registry.asm
  compiler/semantic/operators/core_power.asm
  compiler/semantic/operators/core_power_bridges.asm
  compiler/semantic/operators/core_bool_xor.asm
  compiler/semantic/operators/core_bit_xor.asm
  compiler/semantic/operators/core_ordering.asm
  compiler/semantic/operators/core_comparison_coherence.asm
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
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g123/power_xor_ordering_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/token_kind-a.o" \
  "$rf148_tmp/lexer-a.o" \
  "$rf148_tmp/numeric_literal_contract-a.o" \
  "$rf148_tmp/text_char_literal_contract-a.o" \
  "$rf148_tmp/operator_precedence-a.o" \
  "$rf148_tmp/core_power_xor_ordering_registry-a.o" \
  "$rf148_tmp/core_power-a.o" \
  "$rf148_tmp/core_power_bridges-a.o" \
  "$rf148_tmp/core_bool_xor-a.o" \
  "$rf148_tmp/core_bit_xor-a.o" \
  "$rf148_tmp/core_ordering-a.o" \
  "$rf148_tmp/core_comparison_coherence-a.o"
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

ninja neboc >/dev/null
tests/rf148/g122/arithmetic-conformance.sh >/dev/null
tests/rf148/g120/operator-resolution-gate.sh >/dev/null

for rf148_symbol in \
  neboc_core_pxo_registry_table \
  neboc_core_pxo_registry_lookup \
  neboc_core_pxo_registry_resolve \
  nebo_runtime_checked_power \
  nebo_runtime_checked_float_power_int \
  nebo_runtime_bytes_xor; do
  test "$(nm -g --defined-only build/bin/neboc | grep -c "[[:space:]]${rf148_symbol}$")" -eq 1
done

printf '%s\n' 'RF148_G123_POWER_XOR_ORDERING_CONFORMANCE=PASS'
printf '%s\n' 'CARET_POWER_ONLY=PASS'
printf '%s\n' 'ASCII_AND_UNICODE_XOR_ACTIVE=PASS'
printf '%s\n' 'CHECKED_POWER_AND_TYPED_XOR=PASS'
printf '%s\n' 'REGISTRY_ROWS=12'
printf '%s\n' 'REGISTRY_DISPATCH=PASS'
printf '%s\n' 'ORDERING_COMPARISON_COHERENCE=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
printf '%s\n' 'LIVE_COMPILER_INTEGRATION=PASS'
