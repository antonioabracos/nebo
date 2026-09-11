#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
work=$(mktemp -d /tmp/nebo-npt-lang-27-test.XXXXXX)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

write_case() {
  local name=$1 source=$2
  printf '%s\n' "$source" > "$work/$name.no"
}

accept_exit() {
  local name=$1 expected=$2
  "$compiler" check "$work/$name.no" --message-format json --color never > "$work/$name.check"
  "$compiler" emit-asm "$work/$name.no" -o "$work/$name.asm"
  "$compiler" build "$work/$name.no" -o "$work/$name" --quiet
  set +e
  "$work/$name"
  local actual=$?
  set -e
  [[ $actual -eq $expected ]] || { echo "FAIL $name: exit=$actual expected=$expected" >&2; exit 1; }
}

reject_case() {
  local name=$1
  set +e
  "$compiler" check "$work/$name.no" --message-format json --color never > "$work/$name.check" 2>&1
  local check_status=$?
  "$compiler" emit-asm "$work/$name.no" -o "$work/$name.asm" > "$work/$name.emit" 2>&1
  local emit_status=$?
  "$compiler" build "$work/$name.no" -o "$work/$name" --quiet > "$work/$name.build" 2>&1
  local build_status=$?
  set -e
  [[ $check_status -ne 0 && $emit_status -ne 0 && $build_status -ne 0 ]] || {
    echo "FAIL $name: invalid source accepted" >&2
    exit 1
  }
  [[ ! -e "$work/$name.asm" && ! -e "$work/$name" ]] || {
    echo "FAIL $name: rejected output residue" >&2
    exit 1
  }
}

write_case int_const '(Int.self)work(){ Array<Int,2> [4,9].v.mutable; v.at(0)=7; v.at(0).return; } start(){0.work();}'
write_case int_dynamic '(Int.self)work(Int.i){ Array<Int,2> [4,9].v.mutable; v.at(i)=7; v.at(i).return; } start(){0.work(1);}'
write_case bool_const '(Bool.self)work(){ Array<Bool,2> [false,true].v.mutable; v.at(0)=true; v.at(0).return; } start(){true.work();}'
write_case char_const "(Char.self)work(){ Array<Char,2> ['A','B'].v.mutable; v.at(0)='é'; v.at(0).return; } start(){'A'.work();}"
write_case full_alias '(Int.self)work(){ Array<Int,3> [1,2,3].owner.mutable; owner.asSlice().view; owner.at(1)=9; view.at(1).return; } start(){0.work();}'
write_case subslice_alias '(Int.self)work(){ Array<Int,4> [1,2,3,4].owner.mutable; owner.asSlice().full; full.subslice(1,3).mid; owner.at(2)=9; mid.at(1).return; } start(){0.work();}'
write_case loop_write '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; 0.i.mutable; while i<2 { v.at(i)=i+5; i+=1; } v.at(1).return; } start(){0.work();}'
write_case loop_observe '(Int.self)work(){ Array<Int,3> [1,2,3].v.mutable; v.at(1)=9; 0.total.mutable; for item in v { total+=item; } total.return; } start(){0.work();}'
write_case branch_write '(Int.self)work(Bool.c){ Array<Int,2> [1,2].v.mutable; if(c){v.at(0)=7;}else{v.at(0)=8;} v.at(0).return; } start(){0.work(false);}'
write_case branch_local '(Int.self)work(Bool.c){ if(c){ Array<Int,2> [1,2].v.mutable; v.at(1)=9; v.at(1).return; }else{0.return;} } start(){0.work(true);}'
write_case loop_local '(Int.self)work(){ 0.i.mutable; 0.sum.mutable; while i<2 { Array<Int,1> [4].v.mutable; v.at(0)=i+5; sum+=v.at(0); i+=1; } sum.return; } start(){0.work();}'
write_case start_local 'start(){ Array<Int,2> [1,2].v.mutable; v.at(1)=9; v.at(1).return; }'
write_case disjoint_arrays '(Int.self)work(){ Array<Int,2> [1,2].a.mutable; Array<Int,2> [3,4].b.mutable; a.at(1)=8; b.at(0)=9; if(a.at(1)==8){if(b.at(0)==9){17.return;}else{0.return;}}else{0.return;} } start(){0.work();}'
write_case call_isolation '(Int.self)work(Int.x){ Array<Int,1> [4].v.mutable; if(x==0){v.at(0)=9;}else{} v.at(0).return; } (Int.self)run(){ self.work(0); self.work(1).return; } start(){0.run();}'
write_case borrowed_observe '(Int.self)pick(Slice<Int>.s){ s.at(1).return; } (Int.self)work(){ Array<Int,3> [1,2,3].owner.mutable; owner.asSlice().view; owner.at(1)=9; self.pick(view).return; } start(){0.work();}'
write_case dynamic_lower_trap '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; 0.i.mutable; i-=1; v.at(i)=9; 0.return; } start(){0.work();}'
write_case dynamic_upper_trap '(Int.self)work(Int.i){ Array<Int,2> [1,2].v.mutable; v.at(i)=9; 0.return; } start(){0.work(2);}'

write_case immutable_write '(Int.self)work(){ Array<Int,2> [1,2].v; v.at(0)=7; v.at(0).return; } start(){0.work();}'
write_case local_slice_write '(Int.self)work(){ Array<Int,2> [1,2].o.mutable; o.asSlice().v; v.at(0)=7; v.at(0).return; } start(){0.work();}'
write_case borrowed_write '(Int.self)work(Slice<Int>.v){ v.at(0)=7; v.at(0).return; } start(){0.return;}'
write_case wrong_index '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v.at(true)=7; v.at(0).return; } start(){0.work();}'
write_case wrong_rhs '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v.at(0)=true; v.at(0).return; } start(){0.work();}'
write_case constant_oob '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v.at(2)=7; v.at(0).return; } start(){0.work();}'
write_case raw_negative '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v.at(-1)=7; v.at(0).return; } start(){0.work();}'
write_case whole_reassign '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v=Array<Int,2> [3,4]; v.at(0).return; } start(){0.work();}'
write_case bracket_write '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v[0]=7; v.at(0).return; } start(){0.work();}'
write_case compound_write '(Int.self)work(){ Array<Int,2> [1,2].v.mutable; v.at(0)+=7; v.at(0).return; } start(){0.work();}'

accept_exit int_const 7
accept_exit int_dynamic 7
accept_exit bool_const 1
accept_exit char_const 233
accept_exit full_alias 9
accept_exit subslice_alias 9
accept_exit loop_write 6
accept_exit loop_observe 13
accept_exit branch_write 8
accept_exit branch_local 9
accept_exit loop_local 11
accept_exit start_local 9
accept_exit disjoint_arrays 17
accept_exit call_isolation 4
accept_exit borrowed_observe 9
accept_exit dynamic_lower_trap 172
accept_exit dynamic_upper_trap 172

for name in immutable_write local_slice_write borrowed_write wrong_index wrong_rhs constant_oob raw_negative whole_reassign bracket_write compound_write; do
  reject_case "$name"
done

# One authenticated mutation emits one guarded address computation and exactly
# one post-RHS qword store. Its mutable owner is not duplicated in `.rodata`.
[[ $(grep -cF 'mov [r10], rax' "$work/int_const.asm") -eq 1 ]]
! grep -qF 'nebo_array_data_0:' "$work/int_const.asm"
lower=$(grep -nF 'test rcx, rcx' "$work/int_const.asm" | head -1 | cut -d: -f1)
upper=$(grep -nF 'cmp rcx, 2' "$work/int_const.asm" | head -1 | cut -d: -f1)
rhs=$(grep -nF 'mov rax, 7' "$work/int_const.asm" | head -1 | cut -d: -f1)
store=$(grep -nF 'mov [r10], rax' "$work/int_const.asm" | head -1 | cut -d: -f1)
[[ $lower -lt $upper && $upper -lt $rhs && $rhs -lt $store ]]

echo 'NPT_LANG_27_LOCAL_ARRAY_CHECKED_ELEMENT_MUTATION=PASS'
