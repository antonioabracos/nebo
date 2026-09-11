#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f08-tests >/dev/null
build/tests/rf27-g13/f08/scheduler_test
file build/tests/rf27-g13/f08/scheduler_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f08/scheduler_test)"
rg -q 'nebo_scheduler_spawn_blocking' runtime/concurrency/scheduler.asm
! rg -qi 'malloc|pthread|distributed' runtime/concurrency/scheduler.asm
bash tests/rf27-g13/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F08_GREEN native=19 scheduler=bounded_FIFO queueDepth=yes run=budgeted workers=spawnBlocking_joined trace=bounded_deterministic shutdown=structured pending=refused static_elf=yes'
