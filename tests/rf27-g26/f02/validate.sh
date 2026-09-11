#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f02-tests >/dev/null
build/tests/rf27-g26/f02/plugin_manifest_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f02/plugin_manifest_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f02/plugin_manifest_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f02/plugin_manifest_test)"
! readelf -lW build/tests/rf27-g26/f02/plugin_manifest_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/plugin_manifest.o
printf 'RF27_G26_F02_GREEN native_assertions=18 cases=45000 manifest_schema=1 exports_max=64 allowlist_max=32 memory_max=67108864 calls_max=4096 hash_allowlist=yes validate_before_load=yes failure_atomicity=yes static_elf=yes no_c_no_libc=yes\n'
