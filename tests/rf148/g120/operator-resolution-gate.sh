#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root="$(git rev-parse --show-toplevel)"
cd "$rf148_root"
rf148_tmp="$(mktemp -d)"
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_modules=(
  operator_resolution operator_substitution operator_conversion operator_ranking
  operator_known_impls operator_coherence operator_lowering operator_rules
  core_power core_ordering
)
for rf148_run in a b; do
  for rf148_module in "${rf148_modules[@]}"; do
    nasm -f elf64 -Wall -Werror -I./ \
      -o "$rf148_tmp/$rf148_module-$rf148_run.o" \
      "compiler/semantic/operators/$rf148_module.asm"
  done
done
for rf148_module in "${rf148_modules[@]}"; do
  test "$(sha256sum "$rf148_tmp/$rf148_module-a.o" | cut -d' ' -f1)" = \
    "$(sha256sum "$rf148_tmp/$rf148_module-b.o" | cut -d' ' -f1)"
done

nasm -f elf64 -Wall -Werror -I./ \
  -o "$rf148_tmp/conformance.o" tests/rf148/g120/operator_resolution_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/conformance" \
  "$rf148_tmp/conformance.o" \
  "$rf148_tmp/operator_resolution-a.o" \
  "$rf148_tmp/operator_substitution-a.o" \
  "$rf148_tmp/operator_conversion-a.o" \
  "$rf148_tmp/operator_ranking-a.o" \
  "$rf148_tmp/operator_known_impls-a.o" \
  "$rf148_tmp/operator_coherence-a.o" \
  "$rf148_tmp/operator_lowering-a.o" \
  "$rf148_tmp/operator_rules-a.o" \
  "$rf148_tmp/core_power-a.o" \
  "$rf148_tmp/core_ordering-a.o"
"$rf148_tmp/conformance"
test -z "$(readelf -dW "$rf148_tmp/conformance" | awk '/NEEDED/')"
test -z "$(nm -u "$rf148_tmp/conformance")"
readelf -lW "$rf148_tmp/conformance" | \
  awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

scripts/mf022/verify-native.sh
tests/rf148/g118/registry-lexer-gate.sh
tests/rf148/g119/precedence-conformance.sh
tests/rf148/g117/discarded-expression-parity.sh
tests/rf148/g117/operator-metamorphic.sh

ninja -f build.ninja -j2 neboc >/dev/null
for rf148_symbol in \
  neboc_operator_protocol_schema neboc_operator_resolve_exact \
  neboc_operator_substitute_type \
  neboc_operator_conversion_policy neboc_operator_rank_candidates \
  neboc_operator_coherence_validate neboc_operator_lowering_plan; do
  test "$(nm -g --defined-only build/bin/neboc | grep -Ec "[[:space:]]${rf148_symbol}$")" -eq 1
done

printf '%s\n' 'RF148_G120_OPERATOR_RESOLUTION=PASS'
printf '%s\n' 'OPERATOR_KIND_PROTOCOL_SCHEMA=PASS'
printf '%s\n' 'EXACT_TYPE_AND_NO_IMPLICIT_COERCION=PASS'
printf '%s\n' 'RESOLUTION_RANKING=PASS'
printf '%s\n' 'GENERIC_SUBSTITUTION=PASS'
printf '%s\n' 'USER_TYPE_KNOWN_PROTOCOL=PASS'
printf '%s\n' 'COHERENCE_AND_AMBIGUITY=PASS'
printf '%s\n' 'EVALUATION_ORDER_AND_FAILURE_ATOMICITY=PASS'
printf '%s\n' 'CANONICAL_TYPE_CHECKER_INTEGRATION=PASS'
printf '%s\n' 'LIVE_COMPILER_INTEGRATION=PASS'
printf '%s\n' 'PREDECESSOR_REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
