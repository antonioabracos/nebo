#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ninja mf032-codegen-tests >/dev/null
build/tests/mf032/codegen_test 3
nasm -f elf64 -Wall -Werror -o "$tmp/text.o" tests/codegen/goldens/007-text-data.asm
readelf -sW "$tmp/text.o" | grep -q 'nebo_text_1'
