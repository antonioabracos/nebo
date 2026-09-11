#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf034-toolchain-tests >/dev/null
build/tests/mf034/toolchain_test 1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
nasm -f elf64 -Wall -Werror -I./ -o "$tmp/runtime.o" runtime/core/runtime_core.asm
nasm -f elf64 -Wall -Werror -I./ -o "$tmp/main.o" tests/toolchain/goldens/format-executable.asm
ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -e _start -o "$tmp/program" "$tmp/main.o" "$tmp/runtime.o"
readelf -hW "$tmp/program" | grep -q 'Class:[[:space:]]*ELF64'
readelf -hW "$tmp/program" | grep -q 'Machine:[[:space:]]*Advanced Micro Devices X86-64'
nm -g --defined-only "$tmp/program" | grep -Eq '[[:space:]]_start$'
"$tmp/program"
