#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f03-tests >/dev/null
build/tests/rf27-g12/f03/random_test
file build/tests/rf27-g12/f03/random_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g12/f03/random_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g12/f03/random_test)"
rg -q '0x9e3779b97f4a7c15' runtime/system/random.asm
rg -q 'NEBO_LINUX_X86_64_SYS_GETRANDOM' runtime/system/random.asm
! rg -qi 'urandom|fallback' runtime/system/random.asm
bash tests/rf27-g12/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F03_GREEN native=25 prng=splitmix64_v1 vectors=3 range=rejection_sampling entropy=getrandom_no_fallback budget=bytes_calls failure=zero_prefix static_elf=yes'
