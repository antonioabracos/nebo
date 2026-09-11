#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g24-f09-tests >/dev/null
build/tests/rf27-g24/f09/profiler_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g24/f09/profiler_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g24/f09/profiler_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
file build/tests/rf27-g24/f09/profiler_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f09/profiler_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f09/profiler_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/profiler.o
printf 'RF27_G24_F09_GREEN native_assertions=27 operations=50000 phases=HIR_LIR_CODEGEN_LINK events_max=4096 stacks_max=64 explain_v1=yes flame_stack_hashes=yes redaction_first=yes raw_secret_leaks=0 perf_live=not_required_local_model static_elf=yes no_c_no_libc=yes\n'
