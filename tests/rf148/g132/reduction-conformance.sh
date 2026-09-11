#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
rf148_sources=(
  compiler/parser/expression/reduction_binder.asm compiler/runtime/math/exact_reduction.asm
  compiler/runtime/math/float_reduction.asm compiler/runtime/math/mapped_reduction.asm
  compiler/runtime/math/structured_reduction.asm compiler/runtime/math/deterministic_parallel_reduction.asm
  compiler/diagnostics/reduction_result.asm
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
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g132/reduction_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" "$rf148_tmp/test.o" "$rf148_tmp"/*-a.o
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
ninja neboc rf148-g131-tests >/dev/null
tests/rf148/g131/uncertainty-symbolic-conformance.sh >/dev/null
printf '%s\n' 'RF148_G132_REDUCTION_CONFORMANCE=PASS' 'FINITE_DOMAIN_BINDING=PASS' 'EXACT_OVERFLOW=PASS' 'FLOAT_STABLE_ORDER=PASS' 'MAPPING_EXACTLY_ONCE=PASS' 'STRUCT_LAYOUT_BOUNDS=PASS' 'PARALLEL_OPT_IN_TREE=PASS' 'DIAGNOSTIC_PARITY=PASS' 'DETERMINISM=PASS' 'STACK_ALIGNMENT=PASS' 'NO_C_NO_LIBC=PASS' 'ELF=PASS'
