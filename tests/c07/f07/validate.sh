#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f07.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 c07-f07-tests

build/tests/c07/f07/tuple_function_abi_test
build/tests/c07/f07/tuple_function_abi_test
test -z "$(nm -u build/tests/c07/f07/tuple_function_abi_test)"
file build/tests/c07/f07/tuple_function_abi_test | grep -Eq 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/c07/f07/tuple_function_abi_test | grep -q INTERP

declare -A positives=([canonical-pair.no]=2 [canonical-triple.no]=8)
for name in "${!positives[@]}"; do
 source="tests/c07/f07/positive/$name"
 build/bin/neboc check "$source"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
 cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
 TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
 set +e; "$tmp/$name.elf"; rc=$?; set -e
 test "$rc" -eq "${positives[$name]}"
done

for name in projection-bounds.no unprojected-tuple.no; do
 source="tests/c07/f07/negative/$name"
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

# The legacy spelling remains an exact compatibility route.
for name in tuple-first.no tuple-second.no tuple-named.no; do
 build/bin/neboc check "tests/rf27-g03/f02/positive/$name"
done
TMPDIR="$tmp_parent" bash tests/c07/f06/validate.sh >/dev/null
printf '%s\n' 'C07_F07_GREEN canonical_function_tuple=yes static_at_projection=yes exact_all_path_merge=yes internal_sret=yes overlap_rejected=yes typed_result=yes legacy_compat=yes f06=yes'
