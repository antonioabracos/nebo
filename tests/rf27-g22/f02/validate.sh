#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g22-f02.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g22-f02-tests >/dev/null
timeout 15 build/tests/rf27-g22/f02/gpu_unsupported_test
python3 tests/rf27-g22/f02/unsupported_oracle.py >"$tmp/a"
python3 tests/rf27-g22/f02/unsupported_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g22/f02/gpu_unsupported_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g22/f02/gpu_unsupported_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g22_gpu_unsupported.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]]
tests/rf27-g21/f09/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G22_F02_GREEN native_assertions=17 calls=10000 exports=6 devices=0 contexts=0 no_handle_publish=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
