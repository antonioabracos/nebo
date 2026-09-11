#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf034-toolchain-tests >/dev/null
build/tests/mf034/toolchain_test 2

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
nasm -f elf64 -Wall -Werror -I./ -o "$tmp/runtime.o" runtime/core/runtime_core.asm
[ -z "$(nm -u "$tmp/runtime.o" 2>/dev/null || true)" ]
! readelf -lW build/tests/mf034/toolchain_test | grep -q 'GNU_STACK.*E'
! readelf -dW build/tests/mf034/toolchain_test 2>/dev/null | grep -q '(NEEDED)'
