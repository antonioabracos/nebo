#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf034-toolchain-tests >/dev/null
build/tests/mf034/toolchain_test 3

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for n in 1 2; do
  nasm -f elf64 -Wall -Werror -I./ -o "$tmp/runtime$n.o" runtime/core/runtime_core.asm
  nasm -f elf64 -Wall -Werror -I./ -o "$tmp/main$n.o" tests/toolchain/goldens/format-executable.asm
  ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -e _start -o "$tmp/program$n" "$tmp/main$n.o" "$tmp/runtime$n.o"
done
cmp -s "$tmp/program1" "$tmp/program2"
