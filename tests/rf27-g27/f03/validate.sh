#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g27-f03-tests >/dev/null
build/tests/rf27-g27/f03/abi_versioning_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g27/f03/abi_versioning_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g27/f03/abi_versioning_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
for tool in nasm ld file readelf nm; do command -v "$tool" >/dev/null; done
file build/tests/rf27-g27/f03/abi_versioning_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g27/f03/abi_versioning_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g27/f03/abi_versioning_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/abi_versioning.o
printf 'RF27_G27_F03_GREEN native_assertions=31 cases=50000 metadata_schema=1 abi=0.0 runtime=0.0 object=1 objects_max=64 features_mask=31 linker_reject=yes failure_atomicity=yes deterministic=yes static_elf=yes no_c_no_libc=yes\n'
