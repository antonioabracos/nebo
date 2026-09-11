#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
work="$repo/build/tmp/c08-f07-validate"
mkdir -p "$work"
ninja -f build.ninja -j1 c08-f07-tests
build/tests/c08/f07/iterator_borrow_test
build/tests/rf27-g07/f06/iterator_test
build/tests/c08/f05/list_mutation_test
build/tests/c08/f06/list_algorithms_test
nasm -f elf64 -I. -o "$work/a.o" runtime/collections/iterator.asm
nasm -f elf64 -I. -o "$work/b.o" runtime/collections/iterator.asm
cmp "$work/a.o" "$work/b.o"
if readelf -d build/tests/c08/f07/iterator_borrow_test | grep -q '(NEEDED)'; then
  echo 'hidden dynamic dependency in iterator test' >&2
  exit 1
fi
printf '%s\n' 'C08_F07_GREEN iterator=single_shared borrow_bit=high generation=low63 sizeHint=yes mutation_exclusion=list_ring release=authenticated_once escape=no hidden_allocation=no deterministic_object=yes'
