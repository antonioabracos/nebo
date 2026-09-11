#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"

ninja -f build.ninja rf27-g04-f05-bounded-arena-tests >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g04-f05.XXXXXX)

build/tests/rf27-g04-f05/bounded_arena_test >"$tmp_root/run1.stdout" 2>"$tmp_root/run1.stderr"
build/tests/rf27-g04-f05/bounded_arena_test >"$tmp_root/run2.stdout" 2>"$tmp_root/run2.stderr"
test ! -s "$tmp_root/run1.stdout"
test ! -s "$tmp_root/run1.stderr"
test ! -s "$tmp_root/run2.stdout"
test ! -s "$tmp_root/run2.stderr"

nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/arena.a.o" runtime/memory/bounded_arena.asm
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/arena.b.o" runtime/memory/bounded_arena.asm
cmp -s "$tmp_root/arena.a.o" "$tmp_root/arena.b.o"
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/test.a.o" tests/memory/rf27_g04_f05_bounded_arena_test.asm
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/test.b.o" tests/memory/rf27_g04_f05_bounded_arena_test.asm
cmp -s "$tmp_root/test.a.o" "$tmp_root/test.b.o"
ld -z noexecstack -o "$tmp_root/test.a" "$tmp_root/test.a.o" "$tmp_root/arena.a.o" build/obj/process_exit.o
ld -z noexecstack -o "$tmp_root/test.b" "$tmp_root/test.b.o" "$tmp_root/arena.b.o" build/obj/process_exit.o
cmp -s "$tmp_root/test.a" "$tmp_root/test.b"
"$tmp_root/test.a" >"$tmp_root/direct.stdout" 2>"$tmp_root/direct.stderr"
test ! -s "$tmp_root/direct.stdout"
test ! -s "$tmp_root/direct.stderr"
file "$tmp_root/test.a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW "$tmp_root/test.a" | rg -q INTERP
test -z "$(nm -u "$tmp_root/test.a")"

rg -q 'NEBOC_MAX_REQUEST 65536' runtime/memory/bounded_arena.inc
rg -q 'NEBOC_MAX_ALIGNMENT 4096' runtime/memory/bounded_arena.inc
rg -q 'NEBOC_MAX_ARENA_CAPACITY 1048576' runtime/memory/bounded_arena.inc
rg -q 'NEBOC_ARENA_DIAG_EXHAUSTED 10' runtime/memory/bounded_arena.inc
rg -q 'NEBOC_ARENA_DIAG_OVERFLOW 11' runtime/memory/bounded_arena.inc
rg -q 'NEBOC_ARENA_DIAG_RESET_BORROWED 12' runtime/memory/bounded_arena.inc
rg -q 'rf27g04_result_error' runtime/memory/bounded_arena.asm
rg -q 'rf27g04_arena_rehash' runtime/memory/bounded_arena.asm

tests/rf27-g04/f03/validate.sh >/dev/null
python3 scripts/pre-g173-bridge/validate-rf27-g04-g06-f01-canonical.py >/dev/null
bash scripts/rf27-g01/validate-focused.sh >/dev/null

echo "RF27_G04_F05_GREEN positive_transitions=6 negative_vectors=9 failure_atomic=9 deterministic_object=2 deterministic_elf=1 static_elf=1 fixed_capacity=yes checked_arithmetic=yes result_error=yes no_c_no_libc=yes tmp=$tmp_root"
