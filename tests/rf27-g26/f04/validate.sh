#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f04-tests >/dev/null
build/tests/rf27-g26/f04/sandbox_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f04/sandbox_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f04/sandbox_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
os_probe=NOT_AVAILABLE
if command -v prlimit >/dev/null && prlimit --pid "$$" --nofile >/dev/null 2>&1; then os_probe=AVAILABLE; fi
test -z "$(nm -u build/tests/rf27-g26/f04/sandbox_test)"
! readelf -lW build/tests/rf27-g26/f04/sandbox_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/sandbox.o
printf 'RF27_G26_F04_GREEN native_assertions=18 cases=60000 memory_max=67108864 calls_max=4096 fds_max=32 root_token=yes network_default=none loopback_attenuated=yes terminate=yes os_limits_probe=%s strong_sandbox_claim=no static_elf=yes no_c_no_libc=yes\n' "$os_probe"
