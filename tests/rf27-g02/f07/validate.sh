#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
ninja -f build.ninja build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g02-f07.XXXXXX)
positive_count=0
negative_count=0

expected_exit() {
  case "$1" in
    array-forward) echo 7 ;;
    break-range|continue-range) echo 3 ;;
    nested-range-array) echo 9 ;;
    range-empty) echo 0 ;;
    range-forward) echo 2 ;;
    range-reverse) echo 5 ;;
    slice-forward) echo 4 ;;
    *) return 1 ;;
  esac
}

for source in tests/rf27-g02/f07/positive/*.no; do
  name=$(basename "$source" .no)
  asm_a="$tmp_root/$name.a.asm"
  asm_b="$tmp_root/$name.b.asm"
  elf="$tmp_root/$name"
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
  build/bin/neboc build "$source" -o "$elf" >"$tmp_root/$name.build.stdout" 2>"$tmp_root/$name.build.stderr"
  test ! -s "$tmp_root/$name.build.stdout"
  test ! -s "$tmp_root/$name.build.stderr"
  set +e
  timeout 5 "$elf"
  actual=$?
  set -e
  test "$actual" -eq "$(expected_exit "$name")"
  file "$elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$elf" | rg -q INTERP
  test -z "$(nm -u "$elf")"
  positive_count=$((positive_count+1))
done

test "$(rg -c '^\._for_header' "$tmp_root/range-forward.a.asm")" -eq 1
test "$(rg -c '^\._for_latch' "$tmp_root/range-forward.a.asm")" -eq 1
test "$(rg -c '^\._for_exit' "$tmp_root/range-forward.a.asm")" -eq 1
test "$(rg -c '^\._for_header' "$tmp_root/nested-range-array.a.asm")" -eq 2
rg -q 'imul rax, -1' "$tmp_root/range-reverse.a.asm"
rg -q '^\._for_data0:' "$tmp_root/array-forward.a.asm"
rg -q 'jmp \._for_exit0' "$tmp_root/break-range.a.asm"
rg -q 'jmp \._for_latch0' "$tmp_root/continue-range.a.asm"

negative_case() {
  local source=$1 diagnostic=$2 name mode output stderr
  name=$(basename "$source" .no)
  for mode in check emit-asm build; do
    output="$tmp_root/$name.$mode.output"
    stderr="$tmp_root/$name.$mode.stderr"
    if [[ $mode == check ]]; then
      if build/bin/neboc check "$source" >"$output" 2>"$stderr"; then return 1; fi
    elif [[ $mode == emit-asm ]]; then
      if build/bin/neboc emit-asm "$source" -o "$output.artifact" >"$output" 2>"$stderr"; then return 1; fi
    else
      if build/bin/neboc build "$source" -o "$output.artifact" >"$output" 2>"$stderr"; then return 1; fi
    fi
    test ! -s "$output"
    test ! -e "$output.artifact"
    test "$(sed -n '1p' "$stderr")" = "$diagnostic"
    test "$(sed -n '2p' "$stderr")" = 'neboc: source validation failed'
    test "$(wc -l < "$stderr")" -eq 2
  done
  negative_count=$((negative_count+1))
}

negative_case tests/rf27-g02/f07/negative/zero-step.no 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-006: Range step, direction or checked length is invalid'
negative_case tests/rf27-g02/f07/negative/type-mismatch.no 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-037: for iterator source must be a live bounded Range, Array or Slice'
negative_case tests/rf27-g02/f07/negative/stale-slice.no 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-007: Slice view is released, stale or has an invalid bounded layout'
negative_case tests/rf27-g02/f07/negative/iterator-overflow.no 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-039: iterator cardinality exceeds the checked bounded profile'
negative_case tests/rf27-g02/f07/negative/mutation-during-iteration.no 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-038: collection mutation during bounded iteration is forbidden'
negative_case tests/rf27-g02/f07/negative/malformed-for.no 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-040: invalid canonical for iterator syntax or body action'

for source in tests/rf27-g02/f06/positive/*.no; do
  build/bin/neboc check "$source" >/dev/null
done
bash tests/rf27-g06/f03/validate.sh >/dev/null
bash tests/rf27-g06/f04/validate.sh >/dev/null

echo "RF27_G02_F07_GREEN positives=$positive_count negatives=$negative_count tri_mode_negative=$((negative_count*3)) deterministic_asm=$positive_count static_elf=$positive_count range_array_slice=yes nested=yes break_continue=yes rc2=yes tmp=$tmp_root"
