#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
work="$repo/build/tmp/c08-f09-validate"
mkdir -p "$work"
ninja -f build.ninja -j1 c08-f09-tests
build/tests/c08/f09/queue_semantics_test
build/tests/rf27-g07/f05/ring_test
nasm -f elf64 -I. -o "$work/a.o" runtime/collections/ring.asm
nasm -f elf64 -I. -o "$work/b.o" runtime/collections/ring.asm
cmp "$work/a.o" "$work/b.o"
if readelf -d build/tests/c08/f09/queue_semantics_test | grep -q '(NEEDED)'; then
  echo 'hidden dynamic dependency in Queue test' >&2
  exit 1
fi
printf '%s\n' 'C08_F09_GREEN queue=FIFO operations=enqueue_dequeue_front_back_length_isEmpty_clear wraparound=checked storage=caller_bounded removed_slot=zero borrow=shared_read_only hidden_allocation=no deterministic_object=yes'
