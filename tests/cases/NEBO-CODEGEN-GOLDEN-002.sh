#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ninja mf032-codegen-tests >/dev/null
build/tests/mf032/codegen_test 2
nasm -f elf64 -Wall -Werror -o "$tmp/int.o" tests/codegen/goldens/002-int-literal.asm
readelf -sW "$tmp/int.o" | grep -q 'nebo_int_1'
