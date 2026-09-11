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
  compiler/lexer/unicode_arithmetic_aliases.asm
  compiler/lexer/unicode_relational_aliases.asm
  compiler/lexer/unicode_inequality_alias.asm
  compiler/lexer/unicode_logical_aliases.asm
  compiler/lexer/unicode_not_xor_aliases.asm
  compiler/lowering/operators/unicode_alias_provenance.asm
  compiler/semantic/operators/unicode_alias_registry.asm
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

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g125/unicode_alias_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/compiler_tokens_token_kind-a.o" \
  "$rf148_tmp/compiler_lexer_lexer-a.o" \
  "$rf148_tmp/compiler_lexer_numeric_literal_contract-a.o" \
  "$rf148_tmp/compiler_lexer_text_char_literal_contract-a.o" \
  "$rf148_tmp/compiler_lexer_unicode_arithmetic_aliases-a.o" \
  "$rf148_tmp/compiler_lexer_unicode_relational_aliases-a.o" \
  "$rf148_tmp/compiler_lexer_unicode_inequality_alias-a.o" \
  "$rf148_tmp/compiler_lexer_unicode_logical_aliases-a.o" \
  "$rf148_tmp/compiler_lexer_unicode_not_xor_aliases-a.o" \
  "$rf148_tmp/compiler_lowering_operators_unicode_alias_provenance-a.o" \
  "$rf148_tmp/compiler_semantic_operators_unicode_alias_registry-a.o"
"$rf148_tmp/test"

test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja neboc >/dev/null
tests/rf148/g124/option-range-flow-conformance.sh >/dev/null

printf '%s\n' 'RF148_G125_UNICODE_ALIAS_CONFORMANCE=PASS'
printf '%s\n' 'EXACT_NINE_CODEPOINTS=PASS'
printf '%s\n' 'ASCII_UNICODE_SEMANTIC_IDENTITY=PASS'
printf '%s\n' 'SHORT_CIRCUIT_TOKEN_IDENTITY=PASS'
printf '%s\n' 'SOURCE_PROVENANCE=PASS'
printf '%s\n' 'GLOBAL_REGISTRY_IDS=PASS'
printf '%s\n' 'CANONICAL_CORE_RESOLUTION=PASS'
printf '%s\n' 'NO_SILENT_NFKC=PASS'
printf '%s\n' 'POSTFIX_PERCENT_INACTIVE=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
