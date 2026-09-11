#!/usr/bin/env bash
set -Eeuo pipefail

RF148_REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$RF148_REPO_ROOT"
ninja -f build.ninja neboc >/dev/null

RF148_TMP="$(mktemp -d)"
trap 'rm -rf -- "$RF148_TMP"' EXIT

RF148_CANONICAL="$RF148_TMP/canonical-arithmetic.no"
RF148_RENAMED="$RF148_TMP/renamed-fixture-9f61.no"
RF148_COMMENTED="$RF148_TMP/metamorphic-whitespace.no"
cp tests/e2e/core/arithmetic/arithmetic.no "$RF148_CANONICAL"
cp tests/e2e/core/arithmetic/arithmetic.no "$RF148_RENAMED"
{
  printf '%s\n' '// RF148 semantic-preserving comment'
  sed 's/^/  /' tests/e2e/core/arithmetic/arithmetic.no
  printf '\n'
} >"$RF148_COMMENTED"

for RF148_SOURCE in "$RF148_CANONICAL" "$RF148_RENAMED" "$RF148_COMMENTED"; do
  build/bin/neboc check "$RF148_SOURCE"
  RF148_NAME="$(basename "$RF148_SOURCE" .no)"
  build/bin/neboc emit-asm "$RF148_SOURCE" -o "$RF148_TMP/$RF148_NAME.asm"
  build/bin/neboc build "$RF148_SOURCE" -o "$RF148_TMP/$RF148_NAME.elf"
  "$RF148_TMP/$RF148_NAME.elf"
done

cmp -s "$RF148_TMP/canonical-arithmetic.asm" "$RF148_TMP/renamed-fixture-9f61.asm"
cmp -s "$RF148_TMP/canonical-arithmetic.asm" "$RF148_TMP/metamorphic-whitespace.asm"
cmp -s "$RF148_TMP/canonical-arithmetic.elf" "$RF148_TMP/renamed-fixture-9f61.elf"
cmp -s "$RF148_TMP/canonical-arithmetic.elf" "$RF148_TMP/metamorphic-whitespace.elf"

printf '%s\n' \
  'RF148_G117_OPERATOR_METAMORPHIC=PASS' \
  'FILENAME_INVARIANCE=PASS' \
  'COMMENT_WHITESPACE_INVARIANCE=PASS' \
  'ASSEMBLY_BYTE_DETERMINISM=PASS' \
  'ELF_BYTE_DETERMINISM=PASS' \
  'WHOLE_SOURCE_HASH_DISPATCH=ABSENT_BY_BEHAVIOR'
