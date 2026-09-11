#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
work=$(mktemp -d /tmp/nebo-npt-lang-32-test.XXXXXX)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

write_case() {
  local name=$1 source=$2
  printf '%s\n' "$source" >"$work/$name.no"
}

accept_exit() {
  local name=$1 expected=$2 actual
  "$compiler" check "$work/$name.no" --message-format json-lines --color never >"$work/$name.check"
  "$compiler" emit-asm "$work/$name.no" -o "$work/$name.asm"
  "$compiler" build "$work/$name.no" -o "$work/$name.elf" --quiet
  set +e
  timeout 5s "$work/$name.elf" >"$work/$name.stdout" 2>"$work/$name.stderr"
  actual=$?
  set -e
  [[ $actual -eq $expected ]] || {
    echo "FAIL $name: exit=$actual expected=$expected" >&2
    exit 1
  }
}

reject_case() {
  local name=$1 mode status artifact check_code emit_code build_code
  for mode in check emit-asm build; do
    artifact="$work/$name.$mode.out"
    set +e
    if [[ $mode == check ]]; then
      "$compiler" check "$work/$name.no" --message-format json-lines --color never >"$work/$name.$mode.log" 2>&1
    else
      "$compiler" "$mode" "$work/$name.no" -o "$artifact" >"$work/$name.$mode.log" 2>&1
    fi
    status=$?
    set -e
    [[ $status -ne 0 ]] || {
      echo "FAIL $name: $mode accepted a closed composition" >&2
      exit 1
    }
    [[ ! -e $artifact ]] || {
      echo "FAIL $name: $mode left rejected output residue" >&2
      exit 1
    }
  done
  check_code=$(rg -o 'NEBO_[A-Z0-9_]+' "$work/$name.check.log" | sed -n '1p')
  emit_code=$(rg -o 'NEBO_[A-Z0-9_]+' "$work/$name.emit-asm.log" | sed -n '1p')
  build_code=$(rg -o 'NEBO_[A-Z0-9_]+' "$work/$name.build.log" | sed -n '1p')
  [[ -n $check_code && $check_code == "$emit_code" && $check_code == "$build_code" ]] || {
    echo "FAIL $name: diagnostic drift check=$check_code emit=$emit_code build=$build_code" >&2
    exit 1
  }
}

assert_distinct_first_two_descriptor_slots() {
  local name=$1
  local -a slots=()
  mapfile -t slots < <(rg -o 'lea rax, \[rbp - [0-9]+\]' "$work/$name.asm")
  [[ ${#slots[@]} -ge 2 ]] || {
    echo "FAIL $name: fewer than two material descriptor pointers" >&2
    exit 1
  }
  [[ ${slots[0]} != "${slots[1]}" ]] || {
    echo "FAIL $name: first two live Slice arguments reuse ${slots[0]}" >&2
    exit 1
  }
}

# Exact selected B01 return family and derived-view boundaries.
write_case int_unchanged '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,3>[7,8,9].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case bool_unchanged '(Int.self)view(Slice<Bool>.s){s.return;} start(){Array<Bool,2>[true,false].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case char_unchanged "(Int.self)view(Slice<Char>.s){s.return;} start(){Array<Char,2>['A','B'].a; a.asSlice().s; 0.view(s).r; r.length().return;}"
write_case full '(Int.self)view(Slice<Int>.s){s.subslice(0,4).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case prefix '(Int.self)view(Slice<Int>.s){s.subslice(0,2).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case middle '(Int.self)view(Slice<Int>.s){s.subslice(1,3).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.at(0).return;}'
write_case suffix '(Int.self)view(Slice<Int>.s){s.subslice(2,4).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case single '(Int.self)view(Slice<Int>.s){s.subslice(2,3).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.at(0).return;}'
write_case empty '(Int.self)view(Slice<Int>.s){s.subslice(2,2).r; r.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case nested '(Int.self)view(Slice<Int>.s){s.subslice(1,4).a; a.subslice(1,2).b; b.return;} start(){Array<Int,4>[1,2,3,4].a; a.asSlice().s; 0.view(s).r; r.at(0).return;}'
write_case bool_subslice '(Int.self)view(Slice<Bool>.s){s.subslice(1,2).r; r.return;} start(){Array<Bool,2>[false,true].a; a.asSlice().s; 0.view(s).r; r.at(0).return;}'
write_case char_subslice "(Int.self)view(Slice<Char>.s){s.subslice(1,2).r; r.return;} start(){Array<Char,2>['A','B'].a; a.asSlice().s; 0.view(s).r; r.at(0).return;}"
write_case empty_owner '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,0>[].a; a.asSlice().s; 0.view(s).r; r.length().return;}'

accept_exit int_unchanged 3
accept_exit bool_unchanged 2
accept_exit char_unchanged 2
accept_exit full 4
accept_exit prefix 2
accept_exit middle 2
accept_exit suffix 2
accept_exit single 3
accept_exit empty 0
accept_exit nested 3
accept_exit bool_subslice 1
accept_exit char_subslice 66
accept_exit empty_owner 0

# Exit-flow merge, ABI argument order, named result reads and synchronous S04 forwarding.
write_case if_same '(Int.self)view(Bool.c,Slice<Int>.s){if(c){s.return;}else{s.return;}} start(){Array<Int,2>[1,2].a; a.asSlice().s; 0.view(true,s).r; r.length().return;}'
write_case if_two_true '(Int.self)view(Bool.c,Slice<Int>.a,Slice<Int>.b){if(c){a.return;}else{b.return;}} start(){Array<Int,1>[6].left; Array<Int,1>[13].right; left.asSlice().a; right.asSlice().b; 0.view(true,a,b).r; r.at(0).return;}'
write_case if_two_false '(Int.self)view(Bool.c,Slice<Int>.a,Slice<Int>.b){if(c){a.return;}else{b.return;}} start(){Array<Int,1>[6].left; Array<Int,1>[13].right; left.asSlice().a; right.asSlice().b; 0.view(false,a,b).r; r.at(0).return;}'
write_case same_owner_true '(Int.self)view(Bool.c,Slice<Int>.a,Slice<Int>.b){if(c){a.return;}else{b.return;}} start(){Array<Int,5>[5,6,7,13,17].owner; owner.asSlice().whole; whole.subslice(1,2).a; whole.subslice(3,5).b; 0.view(true,a,b).r; r.at(0).return;}'
write_case same_owner_false '(Int.self)view(Bool.c,Slice<Int>.a,Slice<Int>.b){if(c){a.return;}else{b.return;}} start(){Array<Int,5>[5,6,7,13,17].owner; owner.asSlice().whole; whole.subslice(1,2).a; whole.subslice(3,5).b; 0.view(false,a,b).r; r.at(0).return;}'
write_case nested_if '(Int.self)view(Bool.a,Bool.b,Slice<Int>.s){if(a){if(b){s.return;}else{s.return;}}else{s.return;}} start(){Array<Int,1>[7].a; a.asSlice().s; 0.view(true,false,s).r; r.at(0).return;}'
write_case conditional_final '(Int.self)view(Bool.c,Slice<Int>.s){if(c){s.subslice(0,1).r; r.return;} s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(false,s).r; r.length().return;}'
write_case scalar_first '(Int.self)view(Int.x,Slice<Int>.s){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(9,s).r; r.length().return;}'
write_case slice_first '(Int.self)view(Slice<Int>.s,Int.x){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(s,9).r; r.length().return;}'
write_case register_edge '(Int.self)view(Int.a,Int.b,Int.c,Int.d,Slice<Int>.s){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(1,2,3,4,s).r; r.length().return;}'
write_case constant_at '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(s).r; r.at(1).return;}'
write_case dynamic_at '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(s).r; Int(1).i; r.at(i).return;}'
write_case iteration '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(s).r; for v in r {v.return;} 0.return;}'
write_case forwarding '(Int.self)view(Slice<Int>.s){s.return;} (Int.self)size(Slice<Int>.s){s.length().return;} start(){Array<Int,2>[7,8].a; a.asSlice().s; 0.view(s).r; 0.size(r).return;}'

accept_exit if_same 2
accept_exit if_two_true 6
accept_exit if_two_false 13
accept_exit same_owner_true 6
accept_exit same_owner_false 13
accept_exit nested_if 7
accept_exit conditional_final 2
accept_exit scalar_first 2
accept_exit slice_first 2
accept_exit register_edge 2
accept_exit constant_at 8
accept_exit dynamic_at 8
accept_exit iteration 7
accept_exit forwarding 2

# Runtime bound checks retain the existing deterministic trap contract.
write_case derived_oob '(Int.self)view(Slice<Int>.s){s.subslice(0,3).r; r.return;} start(){Array<Int,2>[1,2].a; a.asSlice().s; 0.view(s).r; r.length().return;}'
write_case empty_dynamic_at '(Int.self)view(Slice<Int>.s){s.subslice(0,0).r; r.return;} start(){Array<Int,0>[].a; a.asSlice().s; 0.view(s).r; Int(0).i; r.at(i).return;}'
accept_exit derived_oob 172
accept_exit empty_dynamic_at 172

# Closed boundaries remain closed in check/emit/build with no output residue.
write_case callee_local '(Int.self)view(){Array<Int,2>[1,2].a; a.asSlice().s; s.return;} start(){0.return;}'
write_case branch_local '(Int.self)view(Bool.c){if(c){Array<Int,1>[1].a; a.asSlice().s; s.return;}else{Array<Int,1>[2].b; b.asSlice().s; s.return;}} start(){0.return;}'
write_case mutate_result '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,1>[1].a.mutable; a.asSlice().s; 0.view(s).r; r.at(0)=9; 0.return;}'
write_case immediate '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,1>[1].a; a.asSlice().s; 0.view(s).length().return;}'
write_case discard '(Int.self)view(Slice<Int>.s){s.return;} start(){Array<Int,1>[1].a; a.asSlice().s; 0.view(s); 0.return;}'
write_case mixed_elements '(Int.self)view(Bool.c,Slice<Int>.a,Slice<Bool>.b){if(c){a.return;}else{b.return;}} start(){0.return;}'
write_case slice_array '(Int.self)view(Bool.c,Slice<Int>.s){Array<Int,1>[1].a; if(c){s.return;}else{a.return;}} start(){0.return;}'
write_case missing_return '(Int.self)view(Bool.c,Slice<Int>.s){if(c){s.return;}} start(){0.return;}'

for name in callee_local branch_local mutate_result immediate discard mixed_elements slice_array missing_return; do
  reject_case "$name"
done

rg -q 'NEBO_TYPE_INCONSISTENT_RETURN' "$work/mixed_elements.check.log"
rg -q 'NEBO_TYPE_MISSING_RETURN' "$work/missing_return.check.log"

# Structural selected-policy assertions: hidden sret in RDI, exact complete
# five-qword callee copy, RAX identity, and a second canonical five-qword
# descriptor copy only when the named result is synchronously forwarded.
[[ $(rg -c 'mov r10, \[rdx \+ (0|8|16|24|32)\]' "$work/int_unchanged.asm") -eq 5 ]]
[[ $(rg -c 'mov \[r11 \+ (0|8|16|24|32)\], r10' "$work/int_unchanged.asm") -eq 5 ]]
rg -q 'lea rdi, \[rbp - [0-9]+\]' "$work/int_unchanged.asm"
rg -q 'mov rax, r11' "$work/int_unchanged.asm"
[[ $(rg -c 'mov rax, \[rdx \+ (0|8|16|24|32)\]' "$work/forwarding.asm") -eq 5 ]]
assert_distinct_first_two_descriptor_slots if_two_true
assert_distinct_first_two_descriptor_slots if_two_false
assert_distinct_first_two_descriptor_slots same_owner_true
assert_distinct_first_two_descriptor_slots same_owner_false
! rg -q 'malloc|free|memcpy|libc' "$work/int_unchanged.asm"

echo 'NPT_LANG_32_FUNCTION_S04_DERIVED_READONLY_SLICE_RETURN=PASS'
