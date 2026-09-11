#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ninja mf032-codegen-tests >/dev/null
build/tests/mf032/codegen_test 5
! grep -q 'global pwned' tests/codegen/goldens/012-source-text-safe.asm
! grep -q 'pwned: syscall' tests/codegen/goldens/012-source-text-safe.asm
nasm -f elf64 -Wall -Werror -o "$tmp/safe.o" tests/codegen/goldens/012-source-text-safe.asm
