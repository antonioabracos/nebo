#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"

ninja -f build.ninja build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g04-f04.XXXXXX)
positive_count=0
negative_count=0

expected_exit() {
  case "$1" in
    fallthrough-reverse) echo 11 ;;
    return-cleanup) echo 22 ;;
    branch-cleanup) echo 33 ;;
    break-cleanup) echo 44 ;;
    continue-cleanup) echo 55 ;;
    explicit-drop-close) echo 66 ;;
    *) return 1 ;;
  esac
}

for source in tests/rf27-g04/f04/positive/*.no; do
  name=$(basename "$source" .no)
  asm_a="$tmp_root/$name.a.asm"
  asm_b="$tmp_root/$name.b.asm"
  elf_a="$tmp_root/$name.a"
  elf_b="$tmp_root/$name.b"
  build/bin/neboc check "$source" >"$tmp_root/$name.check.stdout" 2>"$tmp_root/$name.check.stderr"
  test ! -s "$tmp_root/$name.check.stdout"
  test ! -s "$tmp_root/$name.check.stderr"
  build/bin/neboc emit-asm "$source" -o "$asm_a" >"$tmp_root/$name.emit.stdout" 2>"$tmp_root/$name.emit.stderr"
  build/bin/neboc emit-asm "$source" -o "$asm_b" >"$tmp_root/$name.emit2.stdout" 2>"$tmp_root/$name.emit2.stderr"
  test ! -s "$tmp_root/$name.emit.stdout"
  test ! -s "$tmp_root/$name.emit.stderr"
  test ! -s "$tmp_root/$name.emit2.stdout"
  test ! -s "$tmp_root/$name.emit2.stderr"
  cmp -s "$asm_a" "$asm_b"
  build/bin/neboc build "$source" -o "$elf_a" >"$tmp_root/$name.build.stdout" 2>"$tmp_root/$name.build.stderr"
  build/bin/neboc build "$source" -o "$elf_b" >"$tmp_root/$name.build2.stdout" 2>"$tmp_root/$name.build2.stderr"
  test ! -s "$tmp_root/$name.build.stdout"
  test ! -s "$tmp_root/$name.build.stderr"
  test ! -s "$tmp_root/$name.build2.stdout"
  test ! -s "$tmp_root/$name.build2.stderr"
  cmp -s "$elf_a" "$elf_b"
  set +e
  "$elf_a" >"$tmp_root/$name.native.stdout" 2>"$tmp_root/$name.native.stderr"
  native_exit=$?
  set -e
  test "$native_exit" -eq "$(expected_exit "$name")"
  test ! -s "$tmp_root/$name.native.stdout"
  test ! -s "$tmp_root/$name.native.stderr"
  file "$elf_a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$elf_a" | rg -q INTERP
  test -z "$(nm -u "$elf_a")"
  positive_count=$((positive_count+1))
done

negative_case() {
  local source=$1
  local diagnostic=$2
  local name mode stdout stderr artifact
  name=$(basename "$source" .no)
  for mode in check emit-asm build; do
    stdout="$tmp_root/$name.$mode.stdout"
    stderr="$tmp_root/$name.$mode.stderr"
    artifact="$tmp_root/$name.$mode.artifact"
    if [[ $mode == check ]]; then
      if build/bin/neboc check "$source" >"$stdout" 2>"$stderr"; then return 1; fi
    elif [[ $mode == emit-asm ]]; then
      if build/bin/neboc emit-asm "$source" -o "$artifact" >"$stdout" 2>"$stderr"; then return 1; fi
    else
      if build/bin/neboc build "$source" -o "$artifact" >"$stdout" 2>"$stderr"; then return 1; fi
    fi
    test ! -s "$stdout"
    test ! -e "$artifact"
    test "$(wc -l < "$stderr")" -eq 1
    rg -q "^${source}:[1-9][0-9]*:[1-9][0-9]*: error " "$stderr"
    rg -qF ": error $diagnostic" "$stderr"
  done
  negative_count=$((negative_count+1))
}

negative_case tests/rf27-g04/f04/negative/double-drop.no 'NEBO-OWNERSHIP-DOUBLE-DROP: resource cannot be dropped more than once'
negative_case tests/rf27-g04/f04/negative/drop-while-borrowed.no 'NEBO-BORROW-MUTABLE-CONFLICT: value cannot be moved or mutated while borrowed'
negative_case tests/rf27-g04/f04/negative/drop-moved.no 'NEBO-OWNERSHIP-USE-AFTER-MOVE: value cannot be used after it has been moved'
negative_case tests/rf27-g04/f04/negative/defer-copy.no 'NEBO-OWNERSHIP-OPERATION-UNAVAILABLE: ownership operation is unavailable for this value'
negative_case tests/rf27-g04/f04/negative/duplicate-defer.no 'NEBO-OWNERSHIP-OPERATION-UNAVAILABLE: ownership operation is unavailable for this value'
negative_case tests/rf27-g04/f04/negative/break-outside-loop.no 'NEBO-OWNERSHIP-OPERATION-UNAVAILABLE: ownership operation is unavailable for this value'
negative_case tests/rf27-g04/f04/negative/continue-outside-loop.no 'NEBO-OWNERSHIP-OPERATION-UNAVAILABLE: ownership operation is unavailable for this value'

rg -q 'NEBOC_AST_LOOP_STMT' compiler/parser/statements/statements.asm
rg -q 'rf27g04_cleanup_symbol' compiler/semantic/memory/move_copy_clone.asm
rg -q 'NEBOC_PLAN_CLEANUP_COUNT_OFFSET' compiler/lowering/memory/move_copy_clone_plan.asm
rg -q 'neboc_text_char_unicode_e_bytes_PLAN_HASHED_BYTES' compiler/codegen/memory/x86_64/move_copy_clone_codegen.asm

tests/rf27-g04/f03/validate.sh >/dev/null
tests/rf27-g04/f05/validate.sh >/dev/null
bash scripts/rf27-g02/validate-f04.sh >/dev/null
bash scripts/rf27-g01/validate-focused.sh >/dev/null

echo "RF27_G04_F04_GREEN positives=$positive_count negatives=$negative_count tri_mode_negative=$((negative_count*3)) deterministic_asm=$positive_count deterministic_elf=$positive_count static_elf=$positive_count fallthrough=yes return=yes break=yes continue=yes reverse_ledger=yes authenticated_plan=yes panic_unwinding=excluded no_c_no_libc=yes tmp=$tmp_root"
