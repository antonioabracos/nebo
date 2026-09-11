#!/usr/bin/env bash
set -Eeuo pipefail

rf148_root="$(git rev-parse --show-toplevel)"
cd "$rf148_root"
rf148_tmp="$(mktemp -d)"
trap 'rm -rf "$rf148_tmp"' EXIT

PYTHONDONTWRITEBYTECODE=1 python3 scripts/rf148/validate-registry-authority.py --check >"$rf148_tmp/authority-a.log"
PYTHONDONTWRITEBYTECODE=1 python3 scripts/rf148/validate-registry-authority.py --check >"$rf148_tmp/authority-b.log"
cmp -s "$rf148_tmp/authority-a.log" "$rf148_tmp/authority-b.log"
cat "$rf148_tmp/authority-a.log"

for rf148_run in a b; do
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/registry-$rf148_run.o" compiler/tokens/operator_registry_generated.asm
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/metadata-$rf148_run.o" compiler/tokens/operator_token_metadata.asm
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/trie-$rf148_run.o" compiler/lexer/operator_lexeme_trie.asm
done
test "$(sha256sum "$rf148_tmp/registry-a.o" | cut -d' ' -f1)" = "$(sha256sum "$rf148_tmp/registry-b.o" | cut -d' ' -f1)"
test "$(sha256sum "$rf148_tmp/metadata-a.o" | cut -d' ' -f1)" = "$(sha256sum "$rf148_tmp/metadata-b.o" | cut -d' ' -f1)"
test "$(sha256sum "$rf148_tmp/trie-a.o" | cut -d' ' -f1)" = "$(sha256sum "$rf148_tmp/trie-b.o" | cut -d' ' -f1)"

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g118/registry_lexer_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/registry-lexer-test" \
  "$rf148_tmp/test.o" "$rf148_tmp/registry-a.o" "$rf148_tmp/metadata-a.o" "$rf148_tmp/trie-a.o"
"$rf148_tmp/registry-lexer-test"
test -z "$(readelf -dW "$rf148_tmp/registry-lexer-test" | awk '/NEEDED/')"
test -z "$(nm -u "$rf148_tmp/registry-lexer-test")"
readelf -lW "$rf148_tmp/registry-lexer-test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

ninja neboc rf148-g118-tests mf014-lexer-tests mf015-lexer-tests
for rf148_run in a b; do
  build/tests/rf204/G118/registry_live_lexer_test >"$rf148_tmp/live-$rf148_run.stdout" 2>"$rf148_tmp/live-$rf148_run.stderr"
  test ! -s "$rf148_tmp/live-$rf148_run.stdout"
  test ! -s "$rf148_tmp/live-$rf148_run.stderr"
done
cmp -s "$rf148_tmp/live-a.stdout" "$rf148_tmp/live-b.stdout"
cmp -s "$rf148_tmp/live-a.stderr" "$rf148_tmp/live-b.stderr"
for rf148_symbol in neboc_operator_registry_entry_table neboc_operator_registry_lexeme_table neboc_operator_atom_metadata neboc_operator_lexeme_lookup neboc_operator_lexeme_provenance; do
  test "$(nm -g --defined-only build/bin/neboc | rg -c "[[:space:]]${rf148_symbol}$")" -eq 1
done
if rg -n 'extern[[:space:]]+(printf|puts|malloc|free|memcpy|strlen|__libc|dlopen|dlsym|dlclose)|(^|[[:space:]])syscall' \
  compiler/tokens/operator_registry_generated.asm compiler/tokens/operator_token_metadata.asm \
  compiler/lexer/operator_lexeme_trie.asm compiler/lexer/operator_lexeme_trie.inc >"$rf148_tmp/ambient.log"; then
  exit 1
fi
for rf148_case in 1 2 3 4 12 14 98; do build/tests/mf014/lexer_test "$rf148_case"; done
for rf148_case in 5 6 7 8 9 10 11 13 15 99; do build/tests/mf015/lexer_test "$rf148_case"; done

printf '%s\n' 'RF148_G118_REGISTRY_LEXER_GATE=PASS'
printf '%s\n' 'CORE_ROWS=11'
printf '%s\n' 'LEXEME_ATOMS=15'
printf '%s\n' 'MAXIMAL_MUNCH=PASS'
printf '%s\n' 'LEGACY_LEXER_REGRESSIONS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'LIVE_LEXER_REGISTRY_PATH=PASS'
printf '%s\n' 'SOURCE_SPAN_PROVENANCE=PASS'
printf '%s\n' 'REGISTRY_STATE_POLICY=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
