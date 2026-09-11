#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
for front in f01 f02 f03 f04 f05 f06 f07 f08 f09; do
  bash "tests/rf27-g12/${front}/validate.sh" >/dev/null
done
for front in f02 f03 f04 f05 f06 f07 f08 f09; do
  bash "tests/rf27-g11/${front}/validate.sh" >/dev/null
done
ninja rf27-g12-f09-tests >/dev/null
for elf in \
  build/tests/rf27-g12/f02/time_test \
  build/tests/rf27-g12/f03/random_test \
  build/tests/rf27-g12/f04/process_test \
  build/tests/rf27-g12/f05/address_test \
  build/tests/rf27-g12/f06/socket_test \
  build/tests/rf27-g12/f07/timeout_test \
  build/tests/rf27-g12/f08/crypto_test \
  build/tests/rf27-g12/f09/http_test; do
  file "$elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  test -z "$(nm -u "$elf")"
done
test "$(build/bin/neboc --version)" = 'neboc 1.0.0'
printf '%s\n' 'RF27_G12_F10_GREEN group=BOUNDED_GREEN G12_ladder=9 G11_regression=yes static_ELF=8 no_libc=yes loopback_only=yes TLS=local_pinned_profile AEAD=AES256_GCM KDF=PBKDF2_HMAC_SHA256'
