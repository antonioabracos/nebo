#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g26-f06-tests >/dev/null
build/tests/rf27-g26/f06/protocol_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f06/protocol_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g26/f06/protocol_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
test -z "$(nm -u build/tests/rf27-g26/f06/protocol_test)"
! readelf -lW build/tests/rf27-g26/f06/protocol_test | rg -q INTERP
python3 scripts/mf056/audit-stack-alignment.py build/obj/protocol.o
printf 'RF27_G26_F06_GREEN native_assertions=19 cases=70000 protocol_v1=yes payload_max=65536 inflight_max=128 handshake=hello_auth_ready health_drain=yes replay_denied=yes backpressure=yes identity=synthetic internet=no live_loopback=NOT_RUN_NETWORK_FORBIDDEN static_elf=yes no_c_no_libc=yes\n'
