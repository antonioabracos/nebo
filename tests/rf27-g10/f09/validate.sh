#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g10-f09-tests >/dev/null
timeout 5 build/tests/rf27-g10/f09/channel_stream_bridge_test
file build/tests/rf27-g10/f09/channel_stream_bridge_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g10/f09/channel_stream_bridge_test)"
bash tests/rf27-g13/f10/validate.sh >/dev/null
bash tests/rf27-g12/f07/validate.sh >/dev/null
bash tests/rf27-g10/f06/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F09_GREEN native=24 stream=finite channel=bounded preflight_backpressure=failure_atomic sink=ordered cancellation=cooperative deadline=monotonic_timeout cleanup=borrowed_single_owner distributed_stream=no static_elf=yes'
