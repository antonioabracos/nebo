#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f09.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
for front in 01 02 03 04 05 06 07 08; do
  "tests/rf27-g20/f${front}/validate.sh" >"$tmp/f${front}"
  rg -q "RF27_G20_F${front}_.*(GREEN|PASS)" "$tmp/f${front}"
done
python3 tests/rf27-g20/f09/closeout_audit.py >"$tmp/a"
python3 tests/rf27-g20/f09/closeout_audit.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
for artifact in model_contract dense layers conv model_format inference quantization; do
  file "build/obj/rf27_g20_${artifact}.o" | rg -q 'ELF 64-bit LSB relocatable'
done
file build/examples/rf27-g20/tiny-inference | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/examples/rf27-g20/tiny-inference)" ]]
git diff --check
cat "$tmp/a"
printf 'RF27_G20_F09_GREEN fronts=9 all_oracles=yes all_negatives=yes accuracy=yes methodology=yes ownership=yes static_elf=yes no_c_no_libc=yes maturity=PUBLIC_BOUNDED_NATIVE_GREEN_CPU_INFERENCE\n'
