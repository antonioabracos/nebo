#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g08-f02
build/tests/rf27-g08/f02/hasher_test
tmp="$(mktemp -d /tmp/neboc-rf27-g08-f02.XXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
nasm -f elf64 -I. -o "$tmp/a.o" runtime/collections/hasher.asm
nasm -f elf64 -I. -o "$tmp/b.o" runtime/collections/hasher.asm
cmp -s "$tmp/a.o" "$tmp/b.o"
printf '%s\n' 'RF27_G08_F02_GREEN native=10 hasher=32/8 modes=deterministic_process_seeded algorithm=fnv1a64_non_crypto max_bytes=4096 deterministic_object=yes f01=yes'
