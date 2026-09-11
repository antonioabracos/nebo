#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f06-tests >/dev/null
build/tests/rf27-g13/f06/channel_test
file build/tests/rf27-g13/f06/channel_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f06/channel_test)"
rg -q 'NEBO_LINUX_X86_64_SYS_FUTEX' runtime/concurrency/channel.asm
! rg -qi 'malloc|pthread|unbounded' runtime/concurrency/channel.asm
bash tests/rf27-g13/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F06_GREEN native=19 channel=bounded_ring FIFO=yes try=send+receive backpressure=FULL close=wake_all blocking=futex cancellation=cooperative rendezvous=capacity_zero_contract static_elf=yes'
