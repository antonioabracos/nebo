#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f02-tests >/dev/null
build/tests/rf27-g24/f02/formatter_test
python3 tests/rf27-g24/f02/formatter_oracle.py

temp_root="$(mktemp -d /tmp/rf27-g24-f02.XXXXXX)"
trap 'rm -rf "$temp_root"' EXIT
printf 'start() {  \r\n}\t\r\n' > "$temp_root/valid.no"
before="$(sha256sum "$temp_root/valid.no")"
if tools/rf27-format.py --check "$temp_root/valid.no" >/dev/null 2>&1; then
  echo 'FORMAT_CHECK_EXPECTED_CHANGE_RED' >&2
  exit 1
fi
test "$before" = "$(sha256sum "$temp_root/valid.no")"
tools/rf27-format.py "$temp_root/valid.no"
printf 'start() {\n}\n' > "$temp_root/expected.no"
cmp "$temp_root/valid.no" "$temp_root/expected.no"
tools/rf27-format.py --check "$temp_root/valid.no"
build/bin/neboc check "$temp_root/valid.no"

printf 'start( {  \n' > "$temp_root/invalid.no"
before="$(sha256sum "$temp_root/invalid.no")"
if tools/rf27-format.py "$temp_root/invalid.no" >/dev/null 2>&1; then
  echo 'MALFORMED_FORMAT_EXPECTED_REJECTION_RED' >&2
  exit 1
fi
test "$before" = "$(sha256sum "$temp_root/invalid.no")"

printf 'start() {  \n}\t\n' > "$temp_root/range.no"
tools/rf27-format.py --range 0:12 "$temp_root/range.no"
printf 'start() {\n}\t\n' > "$temp_root/range.expected.no"
cmp "$temp_root/range.no" "$temp_root/range.expected.no"

file build/tests/rf27-g24/f02/formatter_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f02/formatter_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f02/formatter_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g24/f02/formatter_test
printf '%s\n' 'RF27_G24_F02_GREEN native_assertions=15 corpus=tracked_no idempotence=yes token_parity=yes check_no_write=yes malformed_no_write=yes range=line_bounded static_elf=yes no_c_no_libc=yes'
