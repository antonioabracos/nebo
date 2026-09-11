#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC
root=$(git rev-parse --show-toplevel)
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT INT TERM HUP

fail() { printf 'G147 multi-target conformance failed: %s\n' "$*" >&2; exit 1; }
check_static_elf() {
  file "$1" | rg -q 'ELF 64-bit.*x86-64.*statically linked' || fail "$2 is not static x86_64 ELF"
  test -z "$(nm -u "$1")" || fail "$2 has undefined symbols"
  test -z "$(readelf -dW "$1" 2>/dev/null | awk '/NEEDED/')" || fail "$2 has dynamic dependencies"
  readelf -lW "$1" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}' || fail "$2 has executable stack"
}

ninja -f build.ninja -j2 build/bin/neboc build/tests/rf204/G147/performance_probe >/dev/null
check_static_elf build/bin/neboc compiler
check_static_elf build/tests/rf204/G147/performance_probe owner-probe

declare -A expected=( [S01]=17 [S02]=29 [S03]=43 [S04]=59 [S05]=71 [S06]=83 [S07]=97 [S08]=109 )
targets=0
for subgroup in S01 S02 S03 S04 S05 S06 S07 S08; do
  source="examples/rf204/G147/RF204-G147-$subgroup.no"
  for pass in a b; do
    rm -f -- "$tmp/current.asm" "$tmp/current.o"
    timeout 30 build/bin/neboc emit-asm "$source" --target-kind executable -o "$tmp/current.asm"
    cp "$tmp/current.asm" "$tmp/$subgroup.$pass.asm"
    nasm -f elf64 -Wall -Werror -o "$tmp/current.o" "$tmp/current.asm"
    cp "$tmp/current.o" "$tmp/$subgroup.$pass.o"
    timeout 30 build/bin/neboc build "$source" -o "$tmp/$subgroup.$pass.elf" --quiet
  done
  cmp -s "$tmp/$subgroup.a.asm" "$tmp/$subgroup.b.asm" || fail "$subgroup Assembly changed"
  cmp -s "$tmp/$subgroup.a.o" "$tmp/$subgroup.b.o" || fail "$subgroup object changed"
  cmp -s "$tmp/$subgroup.a.elf" "$tmp/$subgroup.b.elf" || fail "$subgroup ELF changed"
  readelf -h "$tmp/$subgroup.a.o" | rg -q 'Class:[[:space:]]*ELF64' || fail "$subgroup object class"
  readelf -h "$tmp/$subgroup.a.o" | rg -q 'Machine:[[:space:]]*Advanced Micro Devices X86-64' || fail "$subgroup object machine"
  check_static_elf "$tmp/$subgroup.a.elf" "$subgroup"
  set +e
  timeout 30 "$tmp/$subgroup.a.elf"
  observed=$?
  set -e
  test "$observed" -eq "${expected[$subgroup]}" || fail "$subgroup returned $observed"
  targets=$((targets + 1))
done
test "$targets" -eq 8 || fail "host corpus incomplete"
test -z "$(find compiler/registry/performance -maxdepth 1 -type f -name '*.c' -print)" || fail "C implementation found"

# The internal matrix records i386/aarch64 as contract-only skips. We do not
# promote a NASM-only object into a false Nebo compiler target claim.
build/tests/rf204/G147/performance_probe >"$tmp/target-matrix.bin"
python3 tests/rf204/G147/performance_oracle.py | sed -n '1s/^OBSERVATION_HEX=//p' | xxd -r -p >"$tmp/oracle.bin"
cmp -s "$tmp/target-matrix.bin" "$tmp/oracle.bin" || fail "target matrix diverged from oracle"
test "$(wc -c <"$tmp/target-matrix.bin")" -eq 256 || fail "target record size"

printf '%s\n' \
  'RF148_G147_MULTITARGET_CONFORMANCE=PASS' \
  'X86_64_HARDWARE=PASS' \
  'I386=SKIPPED_UNSUPPORTED_TARGET' \
  'AARCH64=SKIPPED_UNSUPPORTED_TARGET' \
  'NO_C=PASS' \
  'NO_LIBC=PASS' \
  'DOUBLE_CLEAN_DETERMINISM=PASS'
