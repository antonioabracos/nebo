#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f05-tests >/dev/null
build/tests/rf27-g12/f05/address_test
file build/tests/rf27-g12/f05/address_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g12/f05/address_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g12/f05/address_test)"
test -z "$(objdump -d build/obj/address.o | rg 'syscall')"
bash tests/rf27-g12/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F05_GREEN native=31 ipv4=canonical ipv6=loopback_full hostname=ascii_lower socket_address=checked_port DNS=deterministic_local failure_atomic=yes static_elf=yes'
