#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

rf148_sources=(
  compiler/parser/expression/operator_precedence.asm
  compiler/diagnostics/operator_diagnostic_schema.asm
  compiler/diagnostics/operator_precedence_explain.asm
  compiler/diagnostics/operator_diagnostic_classifier.asm
  compiler/diagnostics/operator_quick_fix.asm
  compiler/lsp/operator_metadata.asm
  compiler/lsp/operator_code_actions.asm
  compiler/diagnostics/operator_machine_parity.asm
)
for rf148_run in a b; do
  for rf148_source in "${rf148_sources[@]}"; do
    rf148_name=${rf148_source//\//_}
    rf148_name=${rf148_name%.asm}
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name-$rf148_run.o" "$rf148_source"
  done
done
for rf148_source in "${rf148_sources[@]}"; do
  rf148_name=${rf148_source//\//_}
  rf148_name=${rf148_name%.asm}
  cmp "$rf148_tmp/$rf148_name-a.o" "$rf148_tmp/$rf148_name-b.o"
done

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g128/unicode_source_tooling_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/compiler_parser_expression_operator_precedence-a.o" \
  "$rf148_tmp/compiler_diagnostics_operator_diagnostic_schema-a.o" \
  "$rf148_tmp/compiler_diagnostics_operator_precedence_explain-a.o" \
  "$rf148_tmp/compiler_diagnostics_operator_diagnostic_classifier-a.o" \
  "$rf148_tmp/compiler_diagnostics_operator_quick_fix-a.o" \
  "$rf148_tmp/compiler_lsp_operator_metadata-a.o" \
  "$rf148_tmp/compiler_lsp_operator_code_actions-a.o" \
  "$rf148_tmp/compiler_diagnostics_operator_machine_parity-a.o"
"$rf148_tmp/test"

test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja neboc rf148-g127-tests >/dev/null
tests/rf148/g127/symbol-formatter-conformance.sh >/dev/null

for rf148_format in terminal json jsonl lsp sarif; do
  build/bin/neboc operator-info NSR-UA-003 --format "$rf148_format" --source-id 128 --span 10:13 >"$rf148_tmp/$rf148_format.out"
done
jq -e '.registryId == "NSR-UA-003" and .class == "UNICODE_ALIAS" and .action.safe == true' "$rf148_tmp/json.out" >/dev/null
jq -e '.diagnostic.registryId == "NSR-UA-003"' "$rf148_tmp/jsonl.out" >/dev/null
jq -e '.diagnostic.data.operator.registryId == "NSR-UA-003"' "$rf148_tmp/lsp.out" >/dev/null
jq -e '.runs[0].results[0].properties.operator.registryId == "NSR-UA-003"' "$rf148_tmp/sarif.out" >/dev/null
build/bin/neboc operator-info NSR-REJ-003 --format json >"$rf148_tmp/rejected-a.out"
build/bin/neboc operator-info NSR-REJ-003 --format json >"$rf148_tmp/rejected-b.out"
cmp "$rf148_tmp/rejected-a.out" "$rf148_tmp/rejected-b.out"
jq -e '.class == "REJECTED" and .action.safe == false and .action.automatic == false' "$rf148_tmp/rejected-a.out" >/dev/null
if build/bin/neboc operator-info NSR-REJ-999 --format json >"$rf148_tmp/invalid.out" 2>"$rf148_tmp/invalid.err"; then
  exit 1
fi
test ! -s "$rf148_tmp/invalid.out"

printf '%s\n' 'RF148_G128_UNICODE_SOURCE_TOOLING_CONFORMANCE=PASS'
printf '%s\n' 'OPERATOR_DIAGNOSTIC_SCHEMA=PASS'
printf '%s\n' 'PRECEDENCE_PARSE_TREE_EXPLANATION=PASS'
printf '%s\n' 'CONTEXT_DOMAIN_TYPE_EFFECT_CAPABILITY=PASS'
printf '%s\n' 'RESERVED_REJECTED_QUICK_FIXES=PASS'
printf '%s\n' 'HOVER_SIGNATURE_SEMANTIC_GOTO=PASS'
printf '%s\n' 'SAFE_ACTIONS_MIGRATIONS=PASS'
printf '%s\n' 'TERMINAL_JSON_JSONL_LSP_SARIF_PARITY=PASS'
printf '%s\n' 'OFFLINE_DOCUMENTATION=PASS'
printf '%s\n' 'PUBLIC_OPERATOR_INFO=PASS'
printf '%s\n' 'REGISTRY_AUTHORITY=PASS'
printf '%s\n' 'UNSAFE_MIGRATION_NO_APPLY=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
