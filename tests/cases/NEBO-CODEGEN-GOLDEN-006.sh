#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ninja mf033-abi-tests >/dev/null
build/tests/mf033/abi_test 8
nasm -f elf64 -Wall -Werror -o "$tmp/function-call.o" tests/abi/goldens/006-function-call.asm
readelf -hW "$tmp/function-call.o" | grep -q 'Class:[[:space:]]*ELF64'
[ -z "$(nm -u "$tmp/function-call.o" 2>/dev/null || true)" ]
