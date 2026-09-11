#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f06-tests >/dev/null
build/tests/rf27-g12/f06/socket_test
file build/tests/rf27-g12/f06/socket_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g12/f06/socket_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g12/f06/socket_test)"
for syscall in SOCKET BIND LISTEN ACCEPT4 CONNECT SENDTO RECVFROM SHUTDOWN CLOSE; do
  rg -q "${syscall}" runtime/network/socket.asm
done
! rg -qi 'DNS|AF_UNIX|external|pthread' runtime/network/socket.asm
bash tests/rf27-g12/f02/validate.sh >/dev/null
bash tests/rf27-g12/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F06_GREEN native=30 TCP=loopback_bind_connect_accept_write_all_partial_shutdown UDP=loopback_send_receive_origin capability=connections_bytes external=rejected static_elf=yes'
