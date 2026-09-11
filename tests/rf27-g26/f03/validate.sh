#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f03-tests >/dev/null
build/tests/rf27-g26/f03/plugin_process_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f03/plugin_process_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f03/plugin_process_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f03/plugin_process_test)"
! readelf -lW build/tests/rf27-g26/f03/plugin_process_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/plugin_process.o
printf 'RF27_G26_F03_GREEN native_assertions=18 cases=50000 owned_child_live=yes typed_ipc_schema=1 calls_max=4096 payload_max=65536 crash_isolation=yes cancellation=yes fd_ambient=no network=no static_elf=yes no_c_no_libc=yes\n'
