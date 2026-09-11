#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f08-tests >/dev/null
build/tests/rf27-g12/f08/crypto_test
file build/tests/rf27-g12/f08/crypto_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g12/f08/crypto_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g12/f08/crypto_test)"
test -z "$(objdump -d build/obj/crypto.o | rg 'syscall')"
rg -q '0x428a2f98' runtime/crypto/sha256.asm
rg -q 'mfence' runtime/crypto/sha256.asm
! rg -qi 'TLS|AEAD|KDF|OpenSSL' runtime/crypto/sha256.asm
bash tests/rf27-g12/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F08_GREEN native=24 SHA256=FIPS180_vectors_incremental HMAC=RFC4231_two_vectors SecretBytes=explicit_zeroize_best_effort no_syscalls=yes static_elf=yes'
