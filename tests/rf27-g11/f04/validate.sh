#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f04-tests >/dev/null
tmp_root="$(mktemp -d /tmp/nebo-rf27-g11-f04.XXXXXXXX)"
trap 'rm -rf -- "$tmp_root"' EXIT
build/tests/rf27-g11/f04/file_metadata_test "$tmp_root"
file build/tests/rf27-g11/f04/file_metadata_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f04/file_metadata_test | grep -q 'Type:.*EXEC'
rg -q 'NEBO_LINUX_X86_64_SYS_LSEEK' runtime/filesystem/file.asm
rg -q 'NEBO_LINUX_X86_64_SYS_NEWFSTATAT' runtime/filesystem/file.asm
rg -q 'NEBO_LINUX_X86_64_SYS_FTRUNCATE' runtime/filesystem/file.asm
bash tests/rf27-g11/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F04_GREEN native=26 seek=checked metadata=newfstatat path_type=openat2 setLength=authorized closed=rejected static_elf=yes'
