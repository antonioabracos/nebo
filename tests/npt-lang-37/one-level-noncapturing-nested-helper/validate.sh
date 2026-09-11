#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
suite="$repo_root/tests/npt-lang-37/one-level-noncapturing-nested-helper"
tmp_root=$(mktemp -d /tmp/nebo-npt37-persistent-XXXXXX)

run_positive() {
  local name=$1 expected=$2 source="$suite/positive/$1.no"
  "$compiler" check "$source" --message-format json-lines --color never
  "$compiler" emit-asm "$source" -o "$tmp_root/$name.a.asm"
  "$compiler" emit-asm "$source" -o "$tmp_root/$name.b.asm"
  cmp "$tmp_root/$name.a.asm" "$tmp_root/$name.b.asm"
  "$compiler" build "$source" -o "$tmp_root/$name.elf" --quiet
  set +e
  "$tmp_root/$name.elf"
  local actual=$?
  set -e
  test "$actual" -eq "$expected"
  ! rg -q '^global nebo_nested_fn_' "$tmp_root/$name.a.asm"
}

run_negative() {
  local name=$1 expected=$2 source="$suite/negative/$1.no"
  local phase artifact log
  for phase in check emit-asm build; do
    artifact="$tmp_root/$name.$phase.artifact"
    log="$tmp_root/$name.$phase.log"
    set +e
    if test "$phase" = check; then
      "$compiler" check "$source" --message-format json-lines --color never >"$log" 2>&1
    elif test "$phase" = emit-asm; then
      "$compiler" emit-asm "$source" -o "$artifact" >"$log" 2>&1
    else
      "$compiler" build "$source" -o "$artifact" --quiet >"$log" 2>&1
    fi
    local status=$?
    set -e
    test "$status" -ne 0
    rg -q "$expected" "$log"
    test ! -e "$artifact"
  done
}

run_positive canonical-s28 7
run_positive literal-expression 7
run_positive two-outers-same-helper 3

run_negative call-before NEBO_NESTED_CALL_BEFORE_DECLARATION
run_negative call-outside NEBO_NESTED_SCOPE
run_negative two-helpers NEBO_NESTED_DUPLICATE
run_negative depth-two NEBO_NESTED_CAPACITY
run_negative capture-outer-parameter NEBO_NESTED_CAPTURE_UNSUPPORTED
run_negative nested-in-start NEBO_NESTED_CONTEXT
run_negative nested-in-branch NEBO_NESTED_CONTEXT
run_negative nested-in-loop NEBO_NESTED_CONTEXT
run_negative nested-recursion NEBO_NESTED_RECURSION
run_negative recursive-outer NEBO_NESTED_RECURSIVE_OUTER
run_negative wrong-receiver NEBO_NESTED_RECEIVER_UNSUPPORTED
run_negative explicit-parameter NEBO_NESTED_PARAMETER_UNSUPPORTED
run_negative wrong-return NEBO_NESTED_RETURN_UNSUPPORTED
run_negative function-value-escape NEBO_NESTED_ESCAPE

test "$(rg -c '^nebo_nested_fn_2_1:$' "$tmp_root/canonical-s28.a.asm")" -eq 1
test "$(rg -c 'call nebo_nested_fn_2_1' "$tmp_root/canonical-s28.a.asm")" -eq 1
test "$(rg -c '^nebo_nested_fn_[23]_1:$' "$tmp_root/two-outers-same-helper.a.asm")" -eq 2

printf 'NPT_LANG_37_B01_GREEN positives=3 negatives=14 tri_mode_negative=42 private_symbols=yes deterministic=yes runtime=yes tmp=%s\n' "$tmp_root"
