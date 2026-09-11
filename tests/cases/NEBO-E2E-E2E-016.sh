#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
source=tests/e2e/core/alpha/invalid-source.no
golden=tests/e2e/core/alpha/invalid-source.stderr
owned=0
if [[ -n ${NEBO_MF040_OUTDIR:-} ]]; then
  work=$NEBO_MF040_OUTDIR
  rm -rf "$work"; mkdir -p "$work"
else
  work=$(mktemp -d); owned=1
fi
cleanup(){ if [[ $owned -eq 1 ]]; then rm -rf "$work"; fi; }
trap cleanup EXIT HUP INT TERM
expect_source_error(){
  local name=$1; shift
  local status=0
  if timeout 10s "$@" >"$work/$name.stdout" 2>"$work/$name.stderr"; then status=0; else status=$?; fi
  printf 'MF040_INVALID_RUN command=%s expected=1 observed=%s\n' "$name" "$status"
  [[ $status -eq 1 ]]
  [[ ! -s "$work/$name.stdout" ]]
  cmp -s "$work/$name.stderr" "$golden"
}
expect_source_error check-a build/bin/neboc check "$source"
expect_source_error check-b build/bin/neboc check "$source"
expect_source_error emit-a build/bin/neboc emit-asm "$source" -o "$work/invalid-a.asm"
expect_source_error emit-b build/bin/neboc emit-asm "$source" -o "$work/invalid-b.asm"
expect_source_error build-a build/bin/neboc build "$source" -o "$work/invalid-a"
expect_source_error build-b build/bin/neboc build "$source" -o "$work/invalid-b" --keep-temp
for absent in \
  "$work/invalid-a.asm" "$work/invalid-b.asm" \
  "$work/invalid-a" "$work/invalid-b" \
  "$work/invalid-a.neboc.asm" "$work/invalid-a.neboc.o" \
  "$work/invalid-b.neboc.asm" "$work/invalid-b.neboc.o"; do
  [[ ! -e "$absent" ]]
done
printf 'PRESERVE-ASM\n' >"$work/preserve.asm"
printf 'PRESERVE-ELF\n' >"$work/preserve.elf"
asm_before=$(sha256sum "$work/preserve.asm" | awk '{print $1}')
elf_before=$(sha256sum "$work/preserve.elf" | awk '{print $1}')
expect_source_error emit-preserve build/bin/neboc emit-asm "$source" -o "$work/preserve.asm"
expect_source_error build-preserve build/bin/neboc build "$source" -o "$work/preserve.elf" --keep-temp
[[ $(sha256sum "$work/preserve.asm" | awk '{print $1}') == "$asm_before" ]]
[[ $(sha256sum "$work/preserve.elf" | awk '{print $1}') == "$elf_before" ]]
[[ ! -e "$work/preserve.elf.neboc.asm" && ! -e "$work/preserve.elf.neboc.o" ]]
cmp -s "$work/check-a.stderr" "$work/check-b.stderr"
cmp -s "$work/check-a.stderr" "$work/emit-a.stderr"
cmp -s "$work/check-a.stderr" "$work/build-a.stderr"
(
  cd "$work"
  sha256sum \
    check-a.stderr check-b.stderr emit-a.stderr emit-b.stderr \
    build-a.stderr build-b.stderr emit-preserve.stderr build-preserve.stderr \
    preserve.asm preserve.elf > filesystem.sha256
)
find "$work" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort >"$work/filesystem.txt"
! grep -Eq '(^|\.)neboc\.(asm|o)$|^invalid-[ab](\.asm)?$' "$work/filesystem.txt"
echo MF040_INVALID_CHECK_GREEN
echo MF040_INVALID_EMIT_NO_ARTIFACT_GREEN
echo MF040_INVALID_BUILD_NO_ARTIFACT_GREEN
echo MF040_INVALID_KEEP_TEMP_NO_RESIDUE_GREEN
echo MF040_PREEXISTING_OUTPUT_PRESERVED_GREEN
echo MF040_INVALID_SOURCE_E2E_GREEN
echo NEBO_E2E_E2E_016_GREEN
