#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_scratch="$rf148_root/build/tests/rf148-g130/scratch"
mkdir -p "$rf148_scratch"
rf148_tmp=$(mktemp -d "$rf148_scratch/run.XXXXXX")
rf148_cleanup() {
  find "$rf148_tmp" -depth -mindepth 1 -delete
  rmdir "$rf148_tmp"
  rmdir "$rf148_scratch" 2>/dev/null || true
}
trap rf148_cleanup EXIT INT TERM HUP
rf148_sources=(
  compiler/runtime/math/typed_roots.asm compiler/runtime/math/checked_factorial.asm
  compiler/semantic/math/contextual_infinity.asm compiler/runtime/math/precision_constants.asm
  compiler/runtime/math/floor_ceil.asm compiler/semantic/math/domain_result_policy.asm
  compiler/lowering/math/constant_fold.asm compiler/semantic/math/typed_math_registry.asm
  compiler/format/math_symbol_format.asm
)
for rf148_run in a b; do
  for rf148_source in "${rf148_sources[@]}"; do
    rf148_name=${rf148_source//\//_}; rf148_name=${rf148_name%.asm}
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name-$rf148_run.o" "$rf148_source"
  done
done
for rf148_source in "${rf148_sources[@]}"; do
  rf148_name=${rf148_source//\//_}; rf148_name=${rf148_name%.asm}
  cmp "$rf148_tmp/$rf148_name-a.o" "$rf148_tmp/$rf148_name-b.o"
done
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g130/math_foundation_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" "$rf148_tmp/test.o" "$rf148_tmp"/*-a.o
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja -f build.ninja -j2 build/bin/neboc rf148-g129-tests >/dev/null
tests/rf148/g129/quantity-conformance.sh >/dev/null
printf '%s\n' \
  'RF148_G130_MATH_FOUNDATION_CONFORMANCE=PASS' \
  'REGISTRY_ROWS=9/9' \
  'EXACT_ROOTS_FACTORIAL=PASS' \
  'CONTEXTUAL_INFINITY=PASS' \
  'CONSTANT_PRECISION=PASS' \
  'FLOOR_CEIL=PASS' \
  'FOLD_RUNTIME_DIFFERENTIAL=PASS' \
  'FORMATTER_REGISTRY_PARITY=PASS' \
  'DOMAIN_ERRORS=PASS' \
  'FAILURE_ATOMICITY=PASS' \
  'AFFECTED_REGRESSIONS=PASS' \
  'DETERMINISM=PASS' \
  'STACK_ALIGNMENT=PASS' \
  'NO_C_NO_LIBC=PASS' \
  'ELF=PASS'
