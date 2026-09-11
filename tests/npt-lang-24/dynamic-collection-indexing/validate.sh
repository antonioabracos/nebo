#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../../.." && pwd)
cc="$root/build/bin/neboc"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM HUP

run_case() {
  local source=$1 expected=$2 name
  name=$(basename "$source" .no)
  "$cc" check "$source" --color never >"$tmp/$name.check.out" 2>"$tmp/$name.check.err"
  "$cc" emit-asm "$source" -o "$tmp/$name.asm"
  "$cc" build "$source" -o "$tmp/$name.elf"
  set +e
  timeout 5s "$tmp/$name.elf" >"$tmp/$name.run.out" 2>"$tmp/$name.run.err"
  local actual=$?
  set -e
  test "$actual" -eq "$expected"
}

reject_case() {
  local source=$1 name
  name=$(basename "$source" .no)
  if "$cc" check "$source" --message-format json --color never >"$tmp/$name.json" 2>&1; then
    return 1
  fi
  if "$cc" emit-asm "$source" -o "$tmp/$name.asm" >/dev/null 2>&1; then
    return 1
  fi
  test ! -e "$tmp/$name.asm"
  if "$cc" build "$source" -o "$tmp/$name.elf" >/dev/null 2>&1; then
    return 1
  fi
  test ! -e "$tmp/$name.elf"
}

positive="$root/tests/npt-lang-24/dynamic-collection-indexing/positive"
negative="$root/tests/npt-lang-24/dynamic-collection-indexing/negative"

run_case "$positive/local_array_int.no" 9
run_case "$positive/local_array_bool.no" 1
run_case "$positive/local_array_char.no" 1
run_case "$positive/local_slice_int.no" 9
run_case "$positive/borrowed_slice_int.no" 11
run_case "$positive/borrowed_slice_bool.no" 1
run_case "$positive/borrowed_slice_char.no" 66
run_case "$positive/iterator_index.no" 13
run_case "$positive/mutable_index.no" 9
run_case "$positive/branch_index.no" 9

# Representation-sensitive controls.  These sources are deliberately created
# outside the repository so the persistent gate owns the oracle without
# widening the public fixture surface.
cat >"$tmp/full-slice-bool.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Bool,3> [false,true,false].a; a.asSlice().s; s.at(i).return; } start() { false.f(1).return; }
SRC
run_case "$tmp/full-slice-bool.no" 1

cat >"$tmp/full-slice-char.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Char,2> ['A','é'].a; a.asSlice().s; (s.at(i) == 'é').return; } start() { false.f(1).return; }
SRC
run_case "$tmp/full-slice-char.no" 1

cat >"$tmp/middle-slice-bool.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Bool,4> [false,true,false,true].a; a.asSlice().s; s.subslice(1,3).p; p.at(i).return; } start() { false.f(0).return; }
SRC
run_case "$tmp/middle-slice-bool.no" 1

cat >"$tmp/middle-slice-char.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Char,4> ['A','B','C','D'].a; a.asSlice().s; s.subslice(1,3).p; (p.at(i) == 'C').return; } start() { false.f(1).return; }
SRC
run_case "$tmp/middle-slice-char.no" 1

cat >"$tmp/nested-slice-bool.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Bool,5> [false,true,false,true,false].a; a.asSlice().s; s.subslice(1,5).p; p.subslice(1,3).q; q.at(i).return; } start() { false.f(1).return; }
SRC
run_case "$tmp/nested-slice-bool.no" 1

cat >"$tmp/two-arrays.no" <<'SRC'
(Int.self)f(Int.i) { Array<Int,2> [4,9].a; Array<Int,2> [13,17].b; (a.at(i) + b.at(i)).return; } start() { 0.f(1).return; }
SRC
run_case "$tmp/two-arrays.no" 26

cat >"$tmp/two-slices-same.no" <<'SRC'
(Int.self)f(Int.i) { Array<Int,4> [4,9,13,17].a; a.asSlice().s; s.subslice(0,2).p; s.subslice(1,3).q; (p.at(i) + q.at(i)).return; } start() { 0.f(1).return; }
SRC
run_case "$tmp/two-slices-same.no" 22

cat >"$tmp/two-slices-different.no" <<'SRC'
(Int.self)f(Int.i) { Array<Int,2> [4,9].a; Array<Int,2> [13,17].b; a.asSlice().p; b.asSlice().q; (p.at(i) + q.at(i)).return; } start() { 0.f(1).return; }
SRC
run_case "$tmp/two-slices-different.no" 26

cat >"$tmp/array-dynamic-iteration.no" <<'SRC'
(Int.self)f(Int.i) { Array<Int,3> [4,9,13].a; 0.sum.mutable; for item in a { sum += item; } (sum + a.at(i)).return; } start() { 0.f(1).return; }
SRC
run_case "$tmp/array-dynamic-iteration.no" 35

cat >"$tmp/slice-dynamic-iteration.no" <<'SRC'
(Int.self)f(Int.i) { Array<Int,4> [4,9,13,17].a; a.asSlice().s; s.subslice(1,3).p; 0.sum.mutable; for item in p { sum += item; } (sum + p.at(i)).return; } start() { 0.f(1).return; }
SRC
run_case "$tmp/slice-dynamic-iteration.no" 35

cat >"$tmp/branch-access.no" <<'SRC'
(Int.self)f(Int.i, Bool.choose) { Array<Int,2> [4,9].a; if (choose) { a.at(i).return; } else { 13.return; } } start() { 0.f(1, true).return; }
SRC
run_case "$tmp/branch-access.no" 9

cat >"$tmp/repeated-calls.no" <<'SRC'
(Bool.self)f(Int.i) { Array<Bool,3> [false,true,false].a; a.at(i).return; } start() { false.f(1); false.f(1); false.f(1).return; }
SRC
run_case "$tmp/repeated-calls.no" 1

for source in "$negative"/*.no; do
  reject_case "$source"
done

cat >"$tmp/computed-negative.no" <<'SRC'
(Int.self)work() { Array<Int,2> [4,9].values; 0.index.mutable; index -= 1; values.at(index).return; } start() { 0.work().return; }
SRC
run_case "$tmp/computed-negative.no" 172

cat >"$tmp/empty-slice.no" <<'SRC'
(Int.self)pick(Slice<Int>.values, Int.index) { values.at(index).return; }
(Int.self)work() { Array<Int,0> [].source; source.asSlice().view; self.pick(view, 0).return; }
start() { 0.work().return; }
SRC
run_case "$tmp/empty-slice.no" 172

asm="$tmp/local_array_int.asm"
test "$(rg -c '^nebo_array_data_' "$asm")" -eq 1
test "$(rg -c 'lea r10, \[rel nebo_array_data_' "$asm")" -eq 1
test "$(rg -c 'mov rax, \[rbp - 8\]' "$asm")" -eq 1
rg -q 'test rcx, rcx' "$asm"
rg -q 'cmp rcx, 2' "$asm"
rg -q 'imul rcx, rdx' "$asm"
rg -q 'add rax, rcx' "$asm"
rg -q 'mov rax, \[rax\]' "$asm"

# Every dynamic local Array is one qword payload.  Typed Bool/Char loads may
# read narrower low bits, but the collection address scale remains eight.
for name in local_array_int local_array_bool local_array_char; do
  asm="$tmp/$name.asm"
  test "$(rg -c '^nebo_array_data_' "$asm")" -eq 1
  ! rg -q '^nebo_slice_descriptor_' "$asm"
  rg -q 'mov rdx, 8' "$asm"
  ! rg -q '^    d[bd] ' "$asm"
done

# Full, middle and nested local views carry the exact canonical base, length,
# stride, generation and token in one five-qword descriptor per view.
for name in full-slice-bool full-slice-char middle-slice-bool middle-slice-char nested-slice-bool; do
  asm="$tmp/$name.asm"
  test "$(rg -c '^nebo_array_data_' "$asm")" -eq 1
  ! rg -q '^    d[bd] ' "$asm"
  ! rg -q 'nebo_dynamic_collection_data_' "$asm"
done
rg -Uq 'nebo_slice_descriptor_1:\n    dq nebo_array_data_0\n    dq 3\n    dq 8\n' "$tmp/full-slice-bool.asm"
rg -Uq 'nebo_slice_descriptor_1:\n    dq nebo_array_data_0\n    dq 2\n    dq 8\n' "$tmp/full-slice-char.asm"
rg -Uq 'nebo_slice_descriptor_2:\n    dq nebo_array_data_0 \+ 8\n    dq 2\n    dq 8\n' "$tmp/middle-slice-bool.asm"
rg -Uq 'nebo_slice_descriptor_2:\n    dq nebo_array_data_0 \+ 8\n    dq 2\n    dq 8\n' "$tmp/middle-slice-char.asm"
rg -Uq 'nebo_slice_descriptor_3:\n    dq nebo_array_data_0 \+ 16\n    dq 2\n    dq 8\n' "$tmp/nested-slice-bool.asm"

# Identity and convergence controls: distinct Arrays stay distinct, sibling
# views share their source with exact offsets, and iteration/dynamic access use
# the same canonical symbol.
test "$(rg -c '^nebo_array_data_' "$tmp/two-arrays.asm")" -eq 2
rg -q '^nebo_array_data_0:' "$tmp/two-arrays.asm"
rg -q '^nebo_array_data_1:' "$tmp/two-arrays.asm"
rg -Uq 'nebo_slice_descriptor_2:\n    dq nebo_array_data_0\n' "$tmp/two-slices-same.asm"
rg -Uq 'nebo_slice_descriptor_3:\n    dq nebo_array_data_0 \+ 8\n' "$tmp/two-slices-same.asm"
rg -Uq 'nebo_slice_descriptor_2:\n    dq nebo_array_data_0\n' "$tmp/two-slices-different.asm"
rg -Uq 'nebo_slice_descriptor_3:\n    dq nebo_array_data_1\n' "$tmp/two-slices-different.asm"
test "$(rg -c 'nebo_array_data_0' "$tmp/array-dynamic-iteration.asm")" -eq 3
test "$(rg -c 'nebo_slice_descriptor_2' "$tmp/slice-dynamic-iteration.asm")" -eq 3

! rg -q 'nebo_dynamic_collection_data_' "$tmp"/*.asm

echo NPT_LANG_24_DYNAMIC_COLLECTION_INDEXING=PASS
