#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f07-tests >/dev/null
build/tests/rf27-g13/f07/sync_test
file build/tests/rf27-g13/f07/sync_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f07/sync_test)"
for insn in 'lock cmpxchg' 'lock xadd' 'xchg'; do rg -q "$insn" runtime/concurrency/sync.asm; done
! rg -qi 'pthread|recursive mutex' runtime/concurrency/sync.asm
bash tests/rf27-g13/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G13_F07_GREEN native=23 mutex=guard_nonrecursive rwlock=readers_writer atomic=load+store+CAS+fetchAdd orders=validated futex_wake=yes guards=release_once static_elf=yes'
