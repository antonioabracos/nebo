#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f07-tests >/dev/null
build/tests/rf27-g26/f07/remote_task_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f07/remote_task_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f07/remote_task_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f07/remote_task_test)"
! readelf -lW build/tests/rf27-g26/f07/remote_task_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/remote_task.o
printf 'RF27_G26_F07_GREEN native_assertions=18 cases=70000 tasks_max=64 functions_max=32 partitions=1024 replicas_max=3 idempotency=yes cancellation=yes provenance=yes code_shipping=no shell=no network_calls=0 static_elf=yes no_c_no_libc=yes\n'
