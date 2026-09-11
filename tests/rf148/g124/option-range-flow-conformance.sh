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
  compiler/semantic/operators/core_option_range_flow_registry.asm
  compiler/lowering/operators/result_propagation.asm
  compiler/lowering/operators/option_coalesce.asm
  compiler/lowering/operators/optional_chain.asm
  compiler/lowering/operators/option_coalesce_assignment.asm
  compiler/lowering/operators/mathematical_range.asm
  compiler/lowering/operators/lateral_flow.asm
  compiler/tooling/core_operator_tooling.asm
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

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g124/option_range_flow_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/token_kind-a.o" \
  "$rf148_tmp/lexer-a.o" \
  "$rf148_tmp/numeric_literal_contract-a.o" \
  "$rf148_tmp/text_char_literal_contract-a.o" \
  "$rf148_tmp/operator_precedence-a.o" \
  "$rf148_tmp/core_option_range_flow_registry-a.o" \
  "$rf148_tmp/result_propagation-a.o" \
  "$rf148_tmp/option_coalesce-a.o" \
  "$rf148_tmp/optional_chain-a.o" \
  "$rf148_tmp/option_coalesce_assignment-a.o" \
  "$rf148_tmp/mathematical_range-a.o" \
  "$rf148_tmp/lateral_flow-a.o" \
  "$rf148_tmp/core_operator_tooling-a.o"
"$rf148_tmp/test"

test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

ninja neboc >/dev/null
test -z "$(nm -u build/bin/neboc)"
test -z "$(readelf -dW build/bin/neboc | awk '/NEEDED/')"
readelf -lW build/bin/neboc | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
tests/rf148/g123/power-xor-ordering-conformance.sh >/dev/null

printf '%s\n' 'RF148_G124_OPTION_RANGE_FLOW_CONFORMANCE=PASS'
printf '%s\n' 'QUESTION_FAMILY_MAXIMAL_MUNCH=PASS'
printf '%s\n' 'U2026_RANGE_ASCII_FLOW_SEPARATION=PASS'
printf '%s\n' 'SEMANTIC_REGISTRY=PASS'
printf '%s\n' 'RESULT_OPTION_LAZINESS_ATOMICITY=PASS'
printf '%s\n' 'BOUNDED_RANGE_CARDINALITY=PASS'
printf '%s\n' 'READ_ONLY_LATERAL_FLOW=PASS'
printf '%s\n' 'FORMATTER_LSP_SOURCE_MAP_MIGRATION=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
