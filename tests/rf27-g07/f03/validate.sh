#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g07-f03
build/tests/rf27-g07/f03/list_algorithms_test
tests/rf27-g07/f02/validate.sh >/dev/null
tmp="$(mktemp -d /tmp/neboc-rf27-g07-f03.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
nasm -f elf64 -I. -o "$tmp/a.o" runtime/collections/list_algorithms.asm
nasm -f elf64 -I. -o "$tmp/b.o" runtime/collections/list_algorithms.asm
cmp "$tmp/a.o" "$tmp/b.o"
printf '%s\n' 'RF27_G07_F03_GREEN native=7 algorithms=find_contains_map_filter_stable_sort callbacks=explicit comparator=validated scratch=caller_bounded failure_atomic=yes deterministic_object=yes f02=yes'
