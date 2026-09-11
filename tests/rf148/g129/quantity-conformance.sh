#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC

rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d /tmp/nebo-rf148-g129.XXXXXX)
trap 'rm -rf "$rf148_tmp"' EXIT INT TERM HUP
rf148_sources=(
  compiler/parser/expression/postfix_percent.asm
  compiler/parser/expression/postfix_ratio_units.asm
  compiler/semantic/quantities/angle.asm
  compiler/semantic/quantities/temperature.asm
  compiler/semantic/quantities/quantity_arithmetic.asm
  compiler/semantic/quantities/typed_quantity_registry.asm
  compiler/format/quantity_format.asm
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

nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/test.o" tests/rf148/g129/quantity_test.asm
ld -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/test" "$rf148_tmp/test.o" "$rf148_tmp"/*-a.o
"$rf148_tmp/test"
test -z "$(nm -u "$rf148_tmp/test")"
test -z "$(readelf -dW "$rf148_tmp/test" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/test" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
for rf148_symbol in \
  neboc_typed_quantity_registry_at neboc_typed_quantity_registry_count \
  nebo_postfix_percent_classify nebo_postfix_ratio_unit \
  nebo_angle_normalize nebo_temperature_f_to_c_exact \
  nebo_quantity_add_checked nebo_quantity_format_plan \
  nebo_quantity_console_label nebo_quantity_serialization_tag; do
  test "$(nm -g --defined-only "$rf148_tmp/test" | awk -v symbol="$rf148_symbol" '$3 == symbol { count++ } END { print count + 0 }')" -eq 1
done

ninja build/bin/neboc rf148-g128-tests >/dev/null
rf148_example=examples/rf204/G129/RF204-G129-S08.no
build/bin/neboc check "$rf148_example" --message-format json-lines --color never >"$rf148_tmp/check.out"
test ! -s "$rf148_tmp/check.out"
for rf148_run in a b; do
  build/bin/neboc emit-asm "$rf148_example" -o "$rf148_tmp/example-$rf148_run.asm"
  build/bin/neboc build "$rf148_example" -o "$rf148_tmp/example-$rf148_run.elf" --quiet
done
cmp "$rf148_tmp/example-a.asm" "$rf148_tmp/example-b.asm"
cmp "$rf148_tmp/example-a.elf" "$rf148_tmp/example-b.elf"
for rf148_symbol in \
  nebo_runtime_quantity_percent nebo_runtime_quantity_per_mille \
  nebo_runtime_quantity_angle nebo_runtime_quantity_celsius \
  nebo_runtime_quantity_fahrenheit nebo_runtime_checked_remainder; do
  rg -q "call ${rf148_symbol}$" "$rf148_tmp/example-a.asm"
done
set +e
"$rf148_tmp/example-a.elf"
rf148_status=$?
set -e
test "$rf148_status" -eq 108

printf 'start() { flow.assert((20°C + 10°C) == 30°C); 1.return; }\n' >"$rf148_tmp/affine-invalid.no"
for rf148_mode in check emit-asm build; do
  set +e
  case "$rf148_mode" in
    check) build/bin/neboc check "$rf148_tmp/affine-invalid.no" --message-format json-lines --color never >"$rf148_tmp/$rf148_mode.out" 2>"$rf148_tmp/$rf148_mode.err" ;;
    emit-asm) build/bin/neboc emit-asm "$rf148_tmp/affine-invalid.no" -o "$rf148_tmp/invalid.asm" >"$rf148_tmp/$rf148_mode.out" 2>"$rf148_tmp/$rf148_mode.err" ;;
    build) build/bin/neboc build "$rf148_tmp/affine-invalid.no" -o "$rf148_tmp/invalid.elf" --quiet >"$rf148_tmp/$rf148_mode.out" 2>"$rf148_tmp/$rf148_mode.err" ;;
  esac
  rf148_status=$?
  set -e
  test "$rf148_status" -ne 0
  test -s "$rf148_tmp/$rf148_mode.err"
done
test ! -e "$rf148_tmp/invalid.elf"

printf '%s\n' \
  'RF148_G129_QUANTITY_CONFORMANCE=PASS' \
  'REGISTRY_CLASSIFICATION=PASS' \
  'TYPE_IDENTITIES=PASS' \
  'POSTFIX_PERCENT_REMAINDER=PASS' \
  'EXACT_RATIO_UNITS=PASS' \
  'ANGLE=PASS' \
  'AFFINE_TEMPERATURE=PASS' \
  'UNIT_SAFE_ARITHMETIC=PASS' \
  'FORMAT_CONSOLE_LOCALE_SERIALIZATION=PASS' \
  'SOURCE_TO_EFFECT=PASS' \
  'NEGATIVE_DIAGNOSTICS=PASS' \
  'FAILURE_ATOMICITY=PASS' \
  'REGRESSIONS=PASS' \
  'DETERMINISM=PASS' \
  'STACK_ALIGNMENT=PASS' \
  'NO_C_NO_LIBC=PASS' \
  'ELF=PASS'
