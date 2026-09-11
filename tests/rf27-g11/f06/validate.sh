#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f06-tests >/dev/null
tmp_root="$(mktemp -d /tmp/nebo-rf27-g11-f06.XXXXXXXX)"
trap 'rm -rf -- "$tmp_root"' EXIT
build/tests/rf27-g11/f06/text_test "$tmp_root"
file build/tests/rf27-g11/f06/text_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f06/text_test | grep -q 'Type:.*EXEC'
rg -q 'NEBO_LINUX_X86_64_SYS_RENAMEAT2' runtime/filesystem/text.asm
rg -q 'nebo_utf8_validate' runtime/filesystem/text.asm
bash tests/rf27-g11/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F06_GREEN native=35 utf8=strict read_limit=mandatory lines=crlf readLine=incremental atomic=renameat2 append=yes static_elf=yes'
