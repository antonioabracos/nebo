#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f02-tests >/dev/null
build/tests/rf27-g13/f02/thread_test
file build/tests/rf27-g13/f02/thread_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g13/f02/thread_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g13/f02/thread_test)"
for syscall in CLONE3 FUTEX SCHED_YIELD GETTID; do
  rg -q "NEBO_LINUX_X86_64_SYS_${syscall}" runtime/concurrency/thread.asm
done
! rg -qi 'pthread|detached|libc' runtime/concurrency/thread.asm
bash tests/rf27-g13/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F02_GREEN native=15 thread=join_once clone3=shared_vm_fail_closed futex=child_cleartid send_capture=contract stack=caller_owned budget=count+bytes static_elf=yes'
