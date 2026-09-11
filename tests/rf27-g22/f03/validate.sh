#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g22-f03.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g22-f03-tests >/dev/null
timeout 15 build/tests/rf27-g22/f03/gpu_memory_test
python3 tests/rf27-g22/f03/memory_oracle.py >"$tmp/a"
python3 tests/rf27-g22/f03/memory_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g22/f03/gpu_memory_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g22/f03/gpu_memory_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g22_gpu_unsupported.o | awk '$2=="T"{n++}END{print n}') -eq 12 ]]
timeout 15 build/tests/rf27-g22/f02/gpu_unsupported_test
timeout 15 build/examples/rf27-g21/tiny-training
cat "$tmp/a"
printf 'RF27_G22_F03_GREEN native_assertions=15 calls=10000 exports=12 device_bytes=0 host_unchanged=yes no_allocation=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
