#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f07-tests >/dev/null
build/tests/rf27-g11/f07/binary_test
file build/tests/rf27-g11/f07/binary_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f07/binary_test | grep -q 'Type:.*EXEC'
! rg -q 'syscall' runtime/serialization/binary.asm
bash tests/rf27-g11/f06/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F07_GREEN native=34 header=NB27 version=explicit endian=both bounds=failure_atomic depth_entries=budgeted trailing=policy static_elf=yes'
