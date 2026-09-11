#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_modules=(
  evaluation_plan short_circuit_plan assignment_plan cleanup_plan
  option_result_lazy_plan failure_resource_ledger
)
for rf148_run in a b; do
  for rf148_module in "${rf148_modules[@]}"; do
    nasm -f elf64 -Wall -Werror -I./ \
      -o "$rf148_tmp/$rf148_module-$rf148_run.o" \
      "compiler/lowering/operators/$rf148_module.asm"
  done
done
for rf148_module in "${rf148_modules[@]}"; do
  cmp "$rf148_tmp/$rf148_module-a.o" "$rf148_tmp/$rf148_module-b.o"
done
nasm -f elf64 -Wall -Werror -I./ \
  -o "$rf148_tmp/test.o" tests/rf148/g121/evaluation_conformance_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/evaluation_plan-a.o" \
  "$rf148_tmp/short_circuit_plan-a.o" \
  "$rf148_tmp/assignment_plan-a.o" \
  "$rf148_tmp/cleanup_plan-a.o" \
  "$rf148_tmp/option_result_lazy_plan-a.o" \
  "$rf148_tmp/failure_resource_ledger-a.o"
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

for rf148_symbol in \
  neboc_evaluation_plan_abi \
  neboc_evaluation_plan_from_operator_lowering \
  neboc_evaluation_state_init \
  neboc_materialize_operand_once \
  neboc_evaluation_order_validate \
  neboc_emit_lazy_right_operand \
  neboc_short_circuit_plan \
  neboc_assignment_plan \
  neboc_assignment_commit \
  neboc_cleanup_take_next \
  neboc_failure_ledger_record \
  neboc_verify_failure_atomicity; do
  test "$(nm -g --defined-only build/bin/neboc | rg -c " ${rf148_symbol}$")" -eq 1
done

tests/rf148/g120/operator-resolution-gate.sh >/dev/null

printf '%s\n' 'RF148_G121_EVALUATION_CONFORMANCE=PASS'
printf '%s\n' 'EXACTLY_ONCE_AND_LEFT_TO_RIGHT=PASS'
printf '%s\n' 'MATERIALIZE_OPERAND_ONCE=PASS'
printf '%s\n' 'SHORT_CIRCUIT_AND_CLEANUP=PASS'
printf '%s\n' 'ASSIGNMENT_AND_CLEANUP_ONE_SHOT=PASS'
printf '%s\n' 'FAILURE_ATOMICITY_AND_LEAK_FREEDOM=PASS'
printf '%s\n' 'LIVE_COMPILER_INTEGRATION=PASS'
printf '%s\n' 'PREDECESSOR_REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
