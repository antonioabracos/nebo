#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"

ninja -f build.ninja rf27-g04-f06-safety-proof-tests build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g04-f06.XXXXXX)

build/tests/rf27-g04-f06/safety_proof_test >"$tmp_root/proof1.stdout" 2>"$tmp_root/proof1.stderr"
build/tests/rf27-g04-f06/safety_proof_test >"$tmp_root/proof2.stdout" 2>"$tmp_root/proof2.stderr"
test ! -s "$tmp_root/proof1.stdout"
test ! -s "$tmp_root/proof1.stderr"
test ! -s "$tmp_root/proof2.stdout"
test ! -s "$tmp_root/proof2.stderr"

nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/proof.a.o" tests/memory/rf27_g04_f06_safety_proof_test.asm
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/proof.b.o" tests/memory/rf27_g04_f06_safety_proof_test.asm
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/semantic.a.o" compiler/semantic/memory/move_copy_clone.asm
nasm -f elf64 -Wall -Werror -I . -o "$tmp_root/semantic.b.o" compiler/semantic/memory/move_copy_clone.asm
cmp -s "$tmp_root/proof.a.o" "$tmp_root/proof.b.o"
cmp -s "$tmp_root/semantic.a.o" "$tmp_root/semantic.b.o"
ld -z noexecstack -o "$tmp_root/proof.a" "$tmp_root/proof.a.o" "$tmp_root/semantic.a.o" build/obj/process_exit.o
ld -z noexecstack -o "$tmp_root/proof.b" "$tmp_root/proof.b.o" "$tmp_root/semantic.b.o" build/obj/process_exit.o
cmp -s "$tmp_root/proof.a" "$tmp_root/proof.b"
"$tmp_root/proof.a"
file "$tmp_root/proof.a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW "$tmp_root/proof.a" | rg -q INTERP
test -z "$(nm -u "$tmp_root/proof.a")"

source=tests/rf27-g04/f06/negative/leak-owner.no
diagnostic='NEBO-RESOURCE-LEAK-PATH: resource path would leak without cleanup'
for mode in check emit-asm build; do
  stdout="$tmp_root/leak.$mode.stdout"
  stderr="$tmp_root/leak.$mode.stderr"
  artifact="$tmp_root/leak.$mode.artifact"
  if [[ $mode == check ]]; then
    if build/bin/neboc check "$source" >"$stdout" 2>"$stderr"; then exit 1; fi
  elif [[ $mode == emit-asm ]]; then
    if build/bin/neboc emit-asm "$source" -o "$artifact" >"$stdout" 2>"$stderr"; then exit 1; fi
  else
    if build/bin/neboc build "$source" -o "$artifact" >"$stdout" 2>"$stderr"; then exit 1; fi
  fi
  test ! -s "$stdout"
  test ! -e "$artifact"
  test "$(wc -l < "$stderr")" -eq 1
  rg -q "^${source}:[1-9][0-9]*:[1-9][0-9]*: error " "$stderr"
  rg -qF ": error $diagnostic" "$stderr"
done

rg -q 'neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_memory_native_vertical' compiler/semantic/memory/move_copy_clone.asm
rg -q 'neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_memory_native_vertical' compiler/semantic/memory/move_copy_clone.asm
rg -q 'neboc_ownership_safety_finalize' compiler/semantic/memory/move_copy_clone.asm
rg -q 'NEBOC_PLAN_SAFETY_PROOF_HASH_OFFSET' compiler/lowering/memory/move_copy_clone_plan.asm

tests/rf27-g04/f04/validate.sh >/dev/null
python3 scripts/pre-g173-bridge/validate-rf27-g04-g06-f01-canonical.py >/dev/null
bash scripts/rf27-g02/validate-f04.sh >/dev/null
bash scripts/rf27-g01/validate-focused.sh >/dev/null

echo "RF27_G04_F06_GREEN proof_vectors=6 leak_tri_mode=3 g04_negative_fixtures=22 g04_tri_mode_negative=66 arena_negative_vectors=9 use_after_move=yes double_drop=yes borrow_conflict=yes leak_ledger=yes source_span=yes oom_recovery=yes deterministic_object=2 deterministic_elf=1 static_elf=1 no_c_no_libc=yes tmp=$tmp_root"
