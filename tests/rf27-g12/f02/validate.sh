#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f02-tests >/dev/null
build/tests/rf27-g12/f02/time_test
file build/tests/rf27-g12/f02/time_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g12/f02/time_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g12/f02/time_test)"
rg -q 'NEBO_LINUX_X86_64_SYS_CLOCK_GETTIME' runtime/system/time.asm
rg -q 'NEBO_LINUX_X86_64_SYS_CLOCK_NANOSLEEP' runtime/system/time.asm
bash tests/rf27-g12/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F02_GREEN native=30 duration=checked instant=monotonic system_time=civil sleep=bounded_eintr capability=auth_budget failure_atomic=yes static_elf=yes'
