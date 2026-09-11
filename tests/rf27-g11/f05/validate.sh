#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f05-tests >/dev/null
tmp_root="$(mktemp -d /tmp/nebo-rf27-g11-f05.XXXXXXXX)"
trap 'rm -rf -- "$tmp_root"' EXIT
ln -s /etc "$tmp_root/escape"
build/tests/rf27-g11/f05/directory_test "$tmp_root"
file build/tests/rf27-g11/f05/directory_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f05/directory_test | grep -q 'Type:.*EXEC'
rg -q 'NEBO_LINUX_X86_64_SYS_GETDENTS64' runtime/filesystem/directory.asm
rg -q 'NEBO_OPENAT2_REQUIRED_RESOLVE' runtime/filesystem/directory.asm
bash tests/rf27-g11/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F05_GREEN native=26 createAll=secure entries=bounded walk=explicit removeTree=recursive_bounded symlink_escape=rejected static_elf=yes'
