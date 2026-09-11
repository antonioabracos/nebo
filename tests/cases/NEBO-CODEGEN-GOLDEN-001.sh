#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ninja mf032-codegen-tests >/dev/null
build/tests/mf032/codegen_test 1
nasm -f elf64 -Wall -Werror -o "$tmp/empty.o" tests/codegen/goldens/001-empty-start.asm
readelf -hW "$tmp/empty.o" | grep -q 'Class:[[:space:]]*ELF64'
