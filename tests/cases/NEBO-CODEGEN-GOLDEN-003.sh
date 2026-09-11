#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
build/bin/neboc emit-asm tests/e2e/core/arithmetic/arithmetic.no -o "$tmp/out.asm"
cmp -s "$tmp/out.asm" tests/codegen/goldens/003-arithmetic.asm
nasm -f elf64 -Wall -Werror -o "$tmp/out.o" "$tmp/out.asm"
echo NEBO_CODEGEN_GOLDEN_003_GREEN
