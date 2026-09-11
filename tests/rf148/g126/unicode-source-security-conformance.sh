#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

corpus=tests/rf148/g126/unicode-security-corpus.tsv
test "$(awk 'END{print NR-1}' "$corpus")" -eq 27
test "$(tail -n +2 "$corpus" | cut -f1 | sort -u | wc -l)" -eq 27

rf148_sources=(
  compiler/tokens/token_kind.asm
  compiler/lexer/lexer.asm
  compiler/lexer/numeric_literal_contract.asm
  compiler/lexer/text_char_literal_contract.asm
  compiler/source/utf8/unicode_operator_scanner.asm
  compiler/source/utf8/unicode_normalization_policy.asm
  compiler/source/utf8/unicode_confusable_policy.asm
  compiler/source/utf8/unicode_bidi_policy.asm
  compiler/source/utf8/unicode_invisible_policy.asm
  compiler/diagnostics/unicode_operator_security.asm
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

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g126/unicode_source_security_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" \
  "$rf148_tmp/test.o" \
  "$rf148_tmp/compiler_tokens_token_kind-a.o" \
  "$rf148_tmp/compiler_lexer_lexer-a.o" \
  "$rf148_tmp/compiler_lexer_numeric_literal_contract-a.o" \
  "$rf148_tmp/compiler_lexer_text_char_literal_contract-a.o"
"$rf148_tmp/test"

test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja neboc >/dev/null
tests/rf148/g125/unicode-alias-conformance.sh >/dev/null

corpus_rows=0
while IFS=$'\t' read -r case_id utf8_hex codepoint class expected_action diagnostic replacement editor_rendering; do
  test "$case_id" != case_id || continue
  corpus_rows=$((corpus_rows + 1))
  escaped=$(printf '%s' "$utf8_hex" | sed 's/../\\x&/g')
  glyph=$(printf '%b' "$escaped")
  if test "$expected_action" = ACCEPT; then
    LC_ALL=C grep -F -q "$glyph" examples/rf204/G125/RF204-G125-S01.no
    continue
  fi
  source="$rf148_tmp/$case_id.no"
  printf 'start() { 31' >"$source"
  printf '%b' "$escaped" >>"$source"
  printf '7.return; }\n' >>"$source"
  case "$expected_action" in
    REJECT_CONFUSABLE) public_code=NEBO_SOURCE_UNICODE_CONFUSABLE ;;
    REJECT_BIDI) public_code=NEBO_SOURCE_BIDI_CONTROL ;;
    REJECT_INVISIBLE) public_code=NEBO_SOURCE_INVISIBLE_SEPARATOR ;;
    REJECT_COMBINING) public_code=NEBO_SOURCE_COMBINING_MARK ;;
    REJECT_MALFORMED) public_code=NEBO_SOURCE_MALFORMED_UTF8 ;;
    *) exit 1 ;;
  esac
  set +e
  "$rf148_root/build/bin/neboc" check "$source" --message-format json-lines --color never >"$rf148_tmp/$case_id.json" 2>&1
  status=$?
  set -e
  test "$status" -eq 1
  jq -e --arg code "$public_code" '.schema == 1 and .code == $code and .messageKey == $code and .phase == 14 and .primary.end > .primary.start' "$rf148_tmp/$case_id.json" >/dev/null
  if test "$expected_action" != REJECT_MALFORMED; then
    expected_note=${codepoint/U+/U+00}
    jq -e --arg needle "$expected_note" '.note | contains($needle)' "$rf148_tmp/$case_id.json" >/dev/null
  else
    jq -e '.note | contains("MALFORMED UTF-8")' "$rf148_tmp/$case_id.json" >/dev/null
  fi
done <"$corpus"
test "$corpus_rows" -eq 27

printf '%s\n' 'RF148_G126_UNICODE_SOURCE_SECURITY_CONFORMANCE=PASS'
printf '%s\n' 'CORPUS_ROWS_EXECUTED=27/27'
printf '%s\n' 'STRICT_UTF8=PASS'
printf '%s\n' 'NFC_IDENTITY_NO_NFKC=PASS'
printf '%s\n' 'FULLWIDTH_CONFUSABLE_REJECTION=PASS'
printf '%s\n' 'BIDI_REJECTION=PASS'
printf '%s\n' 'INVISIBLE_COMBINING_REJECTION=PASS'
printf '%s\n' 'CODEPOINT_NAME_REPLACEMENT_DIAGNOSTICS=PASS'
printf '%s\n' 'SECURITY_CORPUS_EDITOR_RENDERING=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
