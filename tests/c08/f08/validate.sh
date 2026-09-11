#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
work="$repo/build/tmp/c08-f08-validate"
mkdir -p "$work"
ninja -f build.ninja -j1 c08-f08-tests
build/tests/c08/f08/stack_semantics_test
build/tests/rf27-g07/f04/stack_test
nasm -f elf64 -I. -o "$work/a.o" runtime/collections/stack.asm
nasm -f elf64 -I. -o "$work/b.o" runtime/collections/stack.asm
cmp "$work/a.o" "$work/b.o"
if readelf -d build/tests/c08/f08/stack_semantics_test | grep -q '(NEEDED)'; then
  echo 'hidden dynamic dependency in Stack test' >&2
  exit 1
fi
printf '%s\n' 'C08_F08_GREEN stack=LIFO operations=push_pop_peek_length_isEmpty_clear storage=caller_bounded removed_slot=zero borrow=shared_read_only hidden_allocation=no deterministic_object=yes'
