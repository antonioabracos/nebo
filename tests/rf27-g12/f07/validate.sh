#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f07-tests >/dev/null
timeout 5 build/tests/rf27-g12/f07/timeout_test
file build/tests/rf27-g12/f07/timeout_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g12/f07/timeout_test)"
for syscall in POLL WAIT4; do rg -q "NEBO_LINUX_X86_64_SYS_${syscall}" runtime/system/timeout.asm; done
! rg -qi 'busy.wait|pthread|forced.kill' runtime/system/timeout.asm
bash tests/rf27-g12/f06/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F07_GREEN native=10 fd_wait=poll_sliced timeout=bounded cancellation=cooperative process_wait=wait4_WNOHANG socket=readable+writable cleanup=single_owner hidden_worker=no static_elf=yes'
