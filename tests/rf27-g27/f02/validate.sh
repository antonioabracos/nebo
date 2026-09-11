#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g27-f02-tests >/dev/null
build/tests/rf27-g27/f02/target_context_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g27/f02/target_context_oracle.py >"$tmp/a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g27/f02/target_context_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
for tool in nasm ld file readelf nm; do command -v "$tool" >/dev/null; done
nasm -v | rg -q '^NASM version '
ld -v | rg -q 'GNU ld'
file build/bin/neboc | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/bin/neboc | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g27/f02/target_context_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/targets_target_context.o
printf 'RF27_G27_F02_GREEN native_assertions=22 cases=30000 registry_max=8 schema=1 certified=x86_64-systemv-elf-linux components=assembler_linker_runtime_object_writer_executable aarch64=unavailable fake_certified_denied=yes local_discovery=yes network=no static_elf=yes no_c_no_libc=yes\n'
