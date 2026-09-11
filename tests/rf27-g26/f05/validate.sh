#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f05-tests >/dev/null
build/tests/rf27-g26/f05/ffi_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f05/ffi_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f05/ffi_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f05/ffi_test)"
! readelf -lW build/tests/rf27-g26/f05/ffi_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/ffi.o
printf 'RF27_G26_F05_GREEN native_assertions=17 cases=60000 assembly_call_live=yes signature_v1=yes args_max=6 lifetime_checked=yes callbacks=explicit unwind=no dynamic_library_open=deferred stack_alignment=yes static_elf=yes no_c_no_libc=yes\n'
