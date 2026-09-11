#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g07-f02
build/tests/rf27-g07/f02/list_core_test
tmp="$(mktemp -d /tmp/neboc-rf27-g07-f02.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
nasm -f elf64 -I. -o "$tmp/a.o" runtime/collections/list_core.asm
nasm -f elf64 -I. -o "$tmp/b.o" runtime/collections/list_core.asm
cmp "$tmp/a.o" "$tmp/b.o"
printf '%s\n' 'RF27_G07_F02_GREEN native=12 operations=new_init_reserve_at_get_push_set_pop_clear_state layout=64/8 max_elements=64 max_bytes=4096 failure_atomic=yes deterministic_object=yes'
