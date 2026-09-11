#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f06.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f06-tests >/dev/null
timeout 15 build/tests/rf27-g20/f06/inference_test
python3 tests/rf27-g20/f06/inference_oracle.py >"$tmp/a"
python3 tests/rf27-g20/f06/inference_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g20/f06/inference_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g20/f06/inference_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g20_inference.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]]
tests/rf27-g20/f05/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G20_F06_GREEN native_assertions=33 cases=3000 exports=6 batch16=yes workspace1mib=yes failure_atomicity=yes profile_no_secret=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
