#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f04-tests >/dev/null
build/tests/rf27-g13/f04/future_test
file build/tests/rf27-g13/f04/future_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f04/future_test)"
! rg -qi 'spin|async function|await expression' runtime/concurrency/future.asm
bash tests/rf27-g13/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F04_GREEN native=18 Future=poll_ready_take waker=bounded map=yes select=deterministic await=method_only hidden_spin=no completion=once static_elf=yes'
