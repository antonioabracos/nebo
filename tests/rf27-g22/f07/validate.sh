#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g22-f07.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g22-f07-tests >/dev/null
timeout 15 build/tests/rf27-g22/f07/gpu_diagnostics_test
python3 tests/rf27-g22/f07/diagnostics_oracle.py >"$tmp/a"
python3 tests/rf27-g22/f07/diagnostics_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g22/f07/gpu_diagnostics_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g22/f07/gpu_diagnostics_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g22_gpu_diagnostics.o | awk '$2=="T"{n++}END{print n}') -eq 5 ]]
timeout 15 build/tests/rf27-g22/f06/gpu_fallback_test
timeout 15 build/tests/rf27-g22/f03/gpu_memory_test
cat "$tmp/a"
printf 'RF27_G22_F07_GREEN native_assertions=24 cases=10000 exports=5 profiling=unsupported budget=unsupported injection=unsupported trace_bytes=0 device_bytes=0 secrets=0 static_elf=yes no_c_no_libc=yes determinism=identical\n'
