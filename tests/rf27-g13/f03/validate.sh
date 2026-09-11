#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f03-tests >/dev/null
build/tests/rf27-g13/f03/task_test
file build/tests/rf27-g13/f03/task_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g13/f03/task_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g13/f03/task_test)"
! rg -qi 'malloc|pthread|orphan|detached' runtime/concurrency/task.asm
bash tests/rf27-g13/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F03_GREEN native=14 TaskGroup=structured storage=caller_owned tasks=bounded child_errors=aggregate joinAll=once scheduler_budget=validated static_elf=yes'
