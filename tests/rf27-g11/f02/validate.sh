#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g11-f02-tests >/dev/null
build/tests/rf27-g11/f02/path_test
readelf -d build/tests/rf27-g11/f02/path_test | rg -q 'There is no dynamic section'
readelf -h build/tests/rf27-g11/f02/path_test | rg -q 'Type:.*EXEC'
test "$(nm -u build/tests/rf27-g11/f02/path_test | wc -l)" -eq 0
tmp="$(mktemp -d /tmp/nebo-rf27-g11-f02.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
nasm -f elf64 -Wall -Werror -I./ -o "$tmp/a.o" runtime/filesystem/path.asm
nasm -f elf64 -Wall -Werror -I./ -o "$tmp/b.o" runtime/filesystem/path.asm
cmp "$tmp/a.o" "$tmp/b.o"
bash tests/rf27-g11/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F02_GREEN native=23 normalize=dot_slash_parent join=bounded parent=range filename=range extension=range traversal=rejected nul=rejected deterministic=yes static_elf=yes'
