#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
work=$(mktemp -d /tmp/nebo-npt-lang-29-test.XXXXXX)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

write_case() {
  local name=$1 source=$2
  printf '%s\n' "$source" >"$work/$name.no"
}

accept_exit() {
  local name=$1 expected=$2 actual
  "$compiler" check "$work/$name.no" --message-format json --color never >"$work/$name.check"
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
  local name=$1 mode status artifact
  for mode in check emit-asm build; do
    artifact="$work/$name.$mode.out"
    set +e
    if [[ $mode == check ]]; then
      "$compiler" check "$work/$name.no" --message-format json --color never >"$work/$name.$mode.log" 2>&1
    else
      "$compiler" "$mode" "$work/$name.no" -o "$artifact" --color never >"$work/$name.$mode.log" 2>&1
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
}

# Exact owned Array return matrix. N=0 still owns one distinct caller-frame
# anchor, while the semantic length and callee copy count remain zero.
write_case int_n0 '(Int.self)make(){ Array<Int,0> [].a; a.return; } start(){ 0.make().result; result.length().return; }'
write_case int_n1 '(Int.self)make(){ Array<Int,1> [7].a; a.return; } start(){ 0.make().result; result.at(0).return; }'
write_case int_n3 '(Int.self)make(){ Array<Int,3> [-4,7,9].a; a.return; } start(){ 0.make().result; result.at(0).return; }'
write_case int_n5 '(Int.self)make(){ Array<Int,5>.filled(7).a; a.return; } start(){ 0.make().result; result.at(4).return; }'
write_case int_n256 '(Int.self)make(){ Array<Int,256>.filled(37).a; a.return; } start(){ 0.make().result; result.at(255).return; }'
write_case bool_n0 '(Bool.self)make(){ Array<Bool,0> [].a; a.return; } start(){ false.make().result; result.length().return; }'
write_case bool_n1 '(Bool.self)make(){ Array<Bool,1> [true].a; a.return; } start(){ false.make().result; result.at(0).return; }'
write_case bool_n3 '(Bool.self)make(){ Array<Bool,3> [false,true,false].a; a.return; } start(){ false.make().result; result.at(1).return; }'
write_case bool_n256 '(Bool.self)make(){ Array<Bool,256>.filled(true).a; a.return; } start(){ false.make().result; result.at(255).return; }'
write_case char_n0 '(Char.self)make(){ Array<Char,0> [].a; a.return; } start(){ '\''A'\''.make().result; result.length().return; }'
write_case char_n1 '(Char.self)make(){ Array<Char,1> ['\''é'\''].a; a.return; } start(){ '\''A'\''.make().result; result.at(0).return; }'
write_case char_n3 '(Char.self)make(){ Array<Char,3> ['\''A'\'','\''B'\'','\''C'\''].a; a.return; } start(){ '\''A'\''.make().result; result.at(2).return; }'
write_case char_n256 '(Char.self)make(){ Array<Char,256>.filled('\''Z'\'').a; a.return; } start(){ '\''A'\''.make().result; result.at(255).return; }'

accept_exit int_n0 0
accept_exit int_n1 7
accept_exit int_n3 252
accept_exit int_n5 7
accept_exit int_n256 37
accept_exit bool_n0 0
accept_exit bool_n1 1
accept_exit bool_n3 1
accept_exit bool_n256 1
accept_exit char_n0 0
accept_exit char_n1 233
accept_exit char_n3 67
accept_exit char_n256 90

# B01 compositions: direct binding is mandatory and is the only newly public
# result-reuse form. The Array stays caller-owned and supports existing local
# Array operations without exposing a general first-class call expression.
write_case dynamic_index '(Int.self)make(){ Array<Int,3> [4,7,9].a; a.return; } start(){ 0.make().result; result.at(0+1).return; }'
write_case mutable_result '(Int.self)make(){ Array<Int,2> [4,9].a; a.return; } start(){ 0.make().result.mutable; result.at(1)=11; result.at(1).return; }'
write_case mutable_source '(Int.self)make(){ Array<Int,2> [4,9].a.mutable; a.at(1)=12; a.return; } start(){ 0.make().result; result.at(1).return; }'
write_case branch_return '(Int.self)make(Bool.c){ if(c){ Array<Int,2> [4,9].a; a.return; }else{ Array<Int,2> [7,11].b; b.return; } } start(){ 0.make(true).result; result.at(0).return; }'
write_case mixed_scalar_param '(Int.self)make(Int.x){ if(x==1){ Array<Int,1> [11].a; a.return; }else{ Array<Int,1> [22].b; b.return; } } start(){ 0.make(0).result; result.at(0).return; }'
write_case mixed_slice_param '(Int.self)make(Slice<Int>.s, Int.x){ if(x==1){ Array<Int,1> [11].a; a.return; }else{ Array<Int,1> [22].b; b.return; } } start(){ Array<Int,1> [3].source; source.asSlice().view; 0.make(view,0).result; result.at(0).return; }'
write_case repeated_results '(Int.self)left(){ Array<Int,2> [3,3].a; a.return; } (Int.self)right(){ Array<Int,2> [7,7].b; b.return; } start(){ 0.left().first; 0.right().second; (first.at(0)+second.at(1)).return; }'
write_case direct_iteration '(Int.self)make(){ Array<Int,3> [5,7,9].a; a.return; } start(){ 0.make().result; for item in result { item.return; } 0.return; }'
write_case direct_slice '(Int.self)make(){ Array<Int,3> [5,7,9].a; a.return; } start(){ 0.make().result; result.asSlice().view; view.at(2).return; }'
write_case same_name_distinct_scopes '(Int.self)make(){ Array<Int,1> [11].a; a.return; } start(){ 0.make().a; a.at(0).return; }'

accept_exit dynamic_index 7
accept_exit mutable_result 11
accept_exit mutable_source 12
accept_exit branch_return 4
accept_exit mixed_scalar_param 22
accept_exit mixed_slice_param 22
accept_exit repeated_results 10
accept_exit direct_iteration 5
accept_exit direct_slice 9
accept_exit same_name_distinct_scopes 11

# Closed boundaries: no discard, immediate chaining, structural return merge,
# borrowed return, or unbound call-result iteration is made public by B01.
write_case discarded_result '(Int.self)make(){ Array<Int,1> [7].a; a.return; } start(){ 0.make(); 0.return; }'
write_case immediate_chain '(Int.self)make(){ Array<Int,1> [7].a; a.return; } start(){ 0.make().at(0).return; }'
write_case mixed_element_return '(Int.self)make(Bool.c){ if(c){ Array<Int,1> [7].a; a.return; }else{ Array<Bool,1> [true].b; b.return; } } start(){ 0.return; }'
write_case mixed_length_return '(Int.self)make(Bool.c){ if(c){ Array<Int,1> [7].a; a.return; }else{ Array<Int,2> [7,9].b; b.return; } } start(){ 0.return; }'
write_case borrowed_return '(Int.self)make(){ Array<Int,1> [7].a; a.asSlice().s; s.return; } start(){ 0.return; }'
write_case unbound_iteration '(Int.self)make(){ Array<Int,1> [7].a; a.return; } start(){ for item in 0.make() { item.return; } 0.return; }'

for name in discarded_result immediate_chain mixed_element_return mixed_length_return borrowed_return unbound_iteration; do
  reject_case "$name"
done

# ABI and representation audit. Hidden sret is passed in RDI, the callee
# returns it in RAX, N=0 reserves a distinct eight-byte anchor, and N=256 uses
# an exact 2048-byte caller-owned payload without emitting a static result.
rg -q 'lea rdi, \[rbp - 8\]' "$work/int_n0.asm"
rg -q 'mov \[rbp-16\], rdi' "$work/int_n0.asm"
rg -q 'mov rax, r11' "$work/int_n0.asm"
! rg -q 'nebo_array_call_result_data_' "$work/int_n0.asm"
rg -q 'sub rsp, 2048' "$work/int_n256.asm"
[[ $(rg -c 'mov \[r11 \+ [0-9]+\], r10' "$work/int_n256.asm") -eq 256 ]]
! rg -q 'nebo_array_call_result_data_' "$work/int_n256.asm"

echo 'NPT_LANG_29_FUNCTION_OWNED_ARRAY_RETURN=PASS'
