#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g11-f03-tests >/dev/null
test_root="$(mktemp -d /tmp/nebo-rf27-g11.XXXXXXXX)"
trap 'rm -rf -- "$test_root"' EXIT
ln -s /etc/passwd "$test_root/escape"
build/tests/rf27-g11/f03/file_test "$test_root"
test -f "$test_root/sample.bin"
test "$(wc -c <"$test_root/sample.bin")" -eq 5
test "$(od -An -tx1 "$test_root/sample.bin" | tr -d ' \n')" = 68656c6c6f
readelf -d build/tests/rf27-g11/f03/file_test | rg -q 'There is no dynamic section'
test "$(nm -u build/tests/rf27-g11/f03/file_test | wc -l)" -eq 0
rg -q 'NEBO_LINUX_X86_64_SYS_OPENAT2' runtime/filesystem/file.asm
rg -q 'NEBO_OPENAT2_REQUIRED_RESOLVE' runtime/filesystem/file.asm
bash tests/rf27-g11/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F03_GREEN native=28 temp_root=yes openat2=required capability=auth readExact=partial_eof writeAll=partial flush=yes close=once symlink_escape=rejected static_elf=yes'
