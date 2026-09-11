#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf034-toolchain-tests >/dev/null
build/tests/mf034/toolchain_test 10

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/path with spaces"
cp tests/toolchain/goldens/format-executable.asm "$tmp/path with spaces/input file.asm"
nasm -f elf64 -Wall -Werror -o "$tmp/path with spaces/output file.o" "$tmp/path with spaces/input file.asm"
test -f "$tmp/path with spaces/output file.o"
