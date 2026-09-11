#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f01-tests >/dev/null
build/tests/rf27-g26/f01/extension_abi_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f01/extension_abi_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f01/extension_abi_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f01/extension_abi_test)"
! readelf -lW build/tests/rf27-g26/f01/extension_abi_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/extension_abi.o
printf 'RF27_G26_F01_GREEN native_assertions=19 cases=40000 schema=1 kinds=plugin_ffi_protocol abi=0 runtime=0 effects_mask=16383 capabilities_mask=127 no_ambient_authority=yes failure_atomicity=yes static_elf=yes no_c_no_libc=yes\n'
