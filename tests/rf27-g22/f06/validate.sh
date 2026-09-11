#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g22-f06.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g22-f06-tests >/dev/null
timeout 15 build/tests/rf27-g22/f06/gpu_fallback_test
python3 tests/rf27-g22/f06/fallback_oracle.py >"$tmp/a"
python3 tests/rf27-g22/f06/fallback_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g22/f06/gpu_fallback_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g22/f06/gpu_fallback_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g22_gpu_fallback.o | awk '$2=="T"{n++}END{print n}') -eq 5 ]]
timeout 15 build/tests/rf27-g22/f03/gpu_memory_test
timeout 15 build/examples/rf27-g21/tiny-training
cat "$tmp/a"
printf 'RF27_G22_F06_GREEN native_assertions=21 cases=5000 exports=5 selected=cpu transfers=0 device_bytes=0 gpu_pin=unsupported static_elf=yes no_c_no_libc=yes determinism=identical\n'
