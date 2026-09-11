#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f10-tests >/dev/null
timeout 5 build/tests/rf27-g13/f10/stream_bridge_test
file build/tests/rf27-g13/f10/stream_bridge_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f10/stream_bridge_test)"
bash tests/rf27-g10/f06/validate.sh >/dev/null
bash tests/rf27-g12/f10/validate.sh >/dev/null
bash tests/rf27-g13/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F10_GREEN native=13 stream=finite channel=preflight_backpressure order=preserved sink=bounded socket=owned_partial_checked cancellation=cooperative deadline=G12_F07 cleanup=single_owner integrations=G10_G12_G13 static_elf=yes'
