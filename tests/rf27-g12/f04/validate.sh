#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f04-tests >/dev/null
build/tests/rf27-g12/f04/process_test
for elf in build/tests/rf27-g12/f04/process_test build/tests/rf27-g12/f04/process_helper; do
  file "$elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$elf" | rg -q INTERP
  test -z "$(nm -u "$elf")"
done
for syscall in GETPID PIPE2 CLONE3 EXECVE WAIT4 KILL; do
  rg -q "NEBO_LINUX_X86_64_SYS_${syscall}" runtime/system/process.asm
done
! rg -qi 'system\(|/bin/sh|SYS_FORK|SYS_VFORK' runtime/system/process.asm
bash tests/rf27-g11/f03/validate.sh >/dev/null
bash tests/rf27-g12/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F04_GREEN native=23 process=exact_allowlist pipe=owned spawn=clone3_fail_closed execve=no_shell wait=reap_once terminate=sigterm static_elf=2'
