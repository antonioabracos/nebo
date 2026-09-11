#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f06.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 c07-f06-tests

build/tests/c07/f06/tuple_ownership_test
build/tests/c07/f06/tuple_ownership_test
test -z "$(nm -u build/tests/c07/f06/tuple_ownership_test)"
file build/tests/c07/f06/tuple_ownership_test | grep -Eq 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/c07/f06/tuple_ownership_test | grep -q INTERP

declare -A positives=([nested-text.no]=7 [destructure-text.no]=9)
for name in "${!positives[@]}"; do
 source="tests/c07/f06/positive/$name"
 build/bin/neboc check "$source"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
 cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
 TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
 set +e; "$tmp/$name.elf"; rc=$?; set -e
 test "$rc" -eq "${positives[$name]}"
done

for name in array-element.no slice-element.no resource-element.no; do
 source="tests/c07/f06/negative/$name"
 for mode in check emit-asm build; do
  artifact="$tmp/$name.$mode.artifact"
  set +e
  if [[ $mode == check ]]; then
   build/bin/neboc check "$source" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err"
  else
   TMPDIR="$tmp_parent" build/bin/neboc "$mode" "$source" -o "$artifact" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err"
  fi
  rc=$?; set -e
  test "$rc" -eq 1
  test ! -s "$tmp/$name.$mode.out"
  test ! -e "$artifact"
  test -s "$tmp/$name.$mode.err"
 done
done

TMPDIR="$tmp_parent" bash tests/c07/f05/validate.sh >/dev/null
printf '%s\n' 'C07_F06_GREEN nested_tuple_text=yes caller_storage=yes reverse_cleanup_hash=yes checked_drop_sum=yes no_alias_after_copy=yes array_slice_resource=POST_1_0_FAIL_CLOSED no_double_drop_surface=yes f05=yes'
