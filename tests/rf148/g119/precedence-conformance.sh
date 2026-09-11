#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root="$(git rev-parse --show-toplevel)"
cd "$rf148_root"
rf148_tmp="$(mktemp -d)"
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_modules=(
  operator_precedence operator_suffix operator_prefix operator_arithmetic
  operator_relation operator_logic binder_grammar
)
for rf148_run in a b; do
  for rf148_module in "${rf148_modules[@]}"; do
    nasm -f elf64 -Wall -Werror -I./ \
      -o "$rf148_tmp/$rf148_module-$rf148_run.o" \
      "compiler/parser/expression/$rf148_module.asm"
  done
done
for rf148_run in a b; do
  nasm -f elf64 -Wall -Werror -I./ \
    -o "$rf148_tmp/diagnostic-catalog-$rf148_run.o" compiler/diagnostics/catalog.asm
  nasm -f elf64 -Wall -Werror -I./ \
    -o "$rf148_tmp/operator-precedence-explain-$rf148_run.o" \
    compiler/diagnostics/operator_precedence_explain.asm
done
test "$(sha256sum "$rf148_tmp/diagnostic-catalog-a.o" | cut -d' ' -f1)" = \
  "$(sha256sum "$rf148_tmp/diagnostic-catalog-b.o" | cut -d' ' -f1)"
test "$(sha256sum "$rf148_tmp/operator-precedence-explain-a.o" | cut -d' ' -f1)" = \
  "$(sha256sum "$rf148_tmp/operator-precedence-explain-b.o" | cut -d' ' -f1)"
for rf148_module in "${rf148_modules[@]}"; do
  test "$(sha256sum "$rf148_tmp/$rf148_module-a.o" | cut -d' ' -f1)" = \
    "$(sha256sum "$rf148_tmp/$rf148_module-b.o" | cut -d' ' -f1)"
done

nasm -f elf64 -Wall -Werror -I./ \
  -o "$rf148_tmp/conformance.o" tests/rf148/g119/precedence_conformance_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/conformance" \
  "$rf148_tmp/conformance.o" \
  "$rf148_tmp/operator_precedence-a.o" "$rf148_tmp/operator_suffix-a.o" \
  "$rf148_tmp/operator_prefix-a.o" "$rf148_tmp/operator_arithmetic-a.o" \
  "$rf148_tmp/operator_relation-a.o" "$rf148_tmp/operator_logic-a.o" \
  "$rf148_tmp/binder_grammar-a.o" "$rf148_tmp/operator-precedence-explain-a.o" \
  "$rf148_tmp/diagnostic-catalog-a.o"
"$rf148_tmp/conformance"
test -z "$(readelf -dW "$rf148_tmp/conformance" | awk '/NEEDED/')"
test -z "$(nm -u "$rf148_tmp/conformance")"
readelf -lW "$rf148_tmp/conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

scripts/mf017/verify-native.sh
build/tests/mf017/expression_test 10

test "$(grep -c 'call neboc_operator_precedence_lookup' compiler/parser/expression/pratt.asm)" = 2
for rf148_symbol in \
  neboc_fixity_spec_lookup neboc_operator_precedence_table \
  neboc_parse_operator_expression neboc_parse_domain_grammar \
  neboc_explain_parse_tree neboc_binder_grammar_limits; do
  nm build/bin/neboc | awk -v symbol="$rf148_symbol" '$3 == symbol { found=1 } END { exit found ? 0 : 1 }'
done

printf '%s\n' 'RF148_G119_PRECEDENCE_CONFORMANCE=PASS'
printf '%s\n' 'CANONICAL_PRATT_INTEGRATION=PASS (94 rows; live prefix/infix/suffix/postfix/binder lookup)'
printf '%s\n' 'NONASSOCIATIVE_CHAIN_DIAGNOSTIC=PASS'
printf '%s\n' 'BINDER_FAILURE_ATOMICITY=PASS'
printf '%s\n' 'PARSE_EXPLANATION=PASS'
printf '%s\n' 'FORMAL_LOGIC_SURFACES_ACTIVE=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
