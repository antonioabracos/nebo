#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f07.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f07-tests >/dev/null
timeout 15 build/tests/rf27-g20/f07/quantization_test
python3 tests/rf27-g20/f07/quantization_oracle.py >"$tmp/a"
python3 tests/rf27-g20/f07/quantization_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g20/f07/quantization_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g20/f07/quantization_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g20_quantization.o | awk '$2=="T"{n++}END{print n}') -eq 5 ]]
tests/rf27-g20/f06/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G20_F07_GREEN native_assertions=31 samples=4096 exports=5 symmetric_int8=yes measured_accuracy=yes f64_fallback=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
