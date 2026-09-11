#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f05-tests >/dev/null
build/tests/rf27-g13/f05/cancel_test
file build/tests/rf27-g13/f05/cancel_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f05/cancel_test)"
rg -q 'NEBO_LINUX_X86_64_SYS_CLOCK_GETTIME' runtime/concurrency/cancel.asm
! rg -qi 'kill|signal|pthread_cancel' runtime/concurrency/cancel.asm
bash tests/rf27-g13/f04/validate.sh >/dev/null
bash tests/rf27-g12/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F05_GREEN native=19 cancellation=cooperative_idempotent parent=propagated deadline=monotonic cleanup=once budget=descendants+callbacks release=once forced_kill=no static_elf=yes'
