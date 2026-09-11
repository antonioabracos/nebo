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
  compiler/format/symbol_style_profile.asm
  compiler/format/operator_ascii_profile.asm
  compiler/format/operator_math_profile.asm
  compiler/format/operator_spacing.asm
  compiler/format/operator_line_layout.asm
  compiler/format/operator_semantic_equivalence.asm
  compiler/format/operator_atomic_modes.asm
  compiler/format/symbol_formatter_filter.asm
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

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g127/symbol_formatter_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/compiler_tokens_token_kind-a.o" \
  "$rf148_tmp/compiler_lexer_lexer-a.o" \
  "$rf148_tmp/compiler_lexer_numeric_literal_contract-a.o" \
  "$rf148_tmp/compiler_lexer_text_char_literal_contract-a.o" \
  "$rf148_tmp/compiler_format_symbol_style_profile-a.o" \
  "$rf148_tmp/compiler_format_operator_ascii_profile-a.o" \
  "$rf148_tmp/compiler_format_operator_math_profile-a.o" \
  "$rf148_tmp/compiler_format_operator_spacing-a.o" \
  "$rf148_tmp/compiler_format_operator_line_layout-a.o" \
  "$rf148_tmp/compiler_format_operator_semantic_equivalence-a.o" \
  "$rf148_tmp/compiler_format_operator_atomic_modes-a.o"
"$rf148_tmp/test"

ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/filter" \
  "$rf148_tmp/compiler_format_symbol_formatter_filter-a.o" \
  "$rf148_tmp/compiler_tokens_token_kind-a.o" \
  "$rf148_tmp/compiler_lexer_lexer-a.o" \
  "$rf148_tmp/compiler_lexer_numeric_literal_contract-a.o" \
  "$rf148_tmp/compiler_lexer_text_char_literal_contract-a.o" \
  "$rf148_tmp/compiler_format_symbol_style_profile-a.o" \
  "$rf148_tmp/compiler_format_operator_ascii_profile-a.o" \
  "$rf148_tmp/compiler_format_operator_math_profile-a.o"
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/filter-b" \
  "$rf148_tmp/compiler_format_symbol_formatter_filter-b.o" \
  "$rf148_tmp/compiler_tokens_token_kind-b.o" \
  "$rf148_tmp/compiler_lexer_lexer-b.o" \
  "$rf148_tmp/compiler_lexer_numeric_literal_contract-b.o" \
  "$rf148_tmp/compiler_lexer_text_char_literal_contract-b.o" \
  "$rf148_tmp/compiler_format_symbol_style_profile-b.o" \
  "$rf148_tmp/compiler_format_operator_ascii_profile-b.o" \
  "$rf148_tmp/compiler_format_operator_math_profile-b.o"
cmp "$rf148_tmp/filter" "$rf148_tmp/filter-b"

source_math='start() { flow.assert((31 − 7) == 24); flow.assert(¬false); 0.return; }'
source_ascii='start() { flow.assert((31 - 7) == 24); flow.assert(!false); 0.return; }'
test "$(printf '%s' "$source_math" | "$rf148_tmp/filter" ascii)" = "$source_ascii"
test "$(printf '%s' "$source_ascii" | "$rf148_tmp/filter" math)" = "$source_math"
test "$(printf '%s' "$source_math" | "$rf148_tmp/filter" preserve)" = "$source_math"

test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
test -z "$(nm -u "$rf148_tmp/filter")"
test -z "$(readelf -dW "$rf148_tmp/filter" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/filter" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja neboc >/dev/null
tests/rf148/g126/unicode-source-security-conformance.sh >/dev/null

printf '%s\n' 'RF148_G127_SYMBOL_FORMATTER_CONFORMANCE=PASS'
printf '%s\n' 'PRESERVE_DEFAULT=PASS'
printf '%s\n' 'ASCII_PROFILE=PASS'
printf '%s\n' 'MATH_PROFILE=PASS'
printf '%s\n' 'LIVE_LEXER_SPAN_REWRITE=PASS'
printf '%s\n' 'FIXITY_SPACING_LAYOUT=PASS'
printf '%s\n' 'AST_SOURCE_SEMANTIC_EQUIVALENCE=PASS'
printf '%s\n' 'CHECK_DIFF_STDOUT_WRITE=PASS'
printf '%s\n' 'ATOMIC_WRITE_ROLLBACK=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
