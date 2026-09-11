#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f02.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT

ninja -f build.ninja -j1 build/bin/neboc

declare -A expected=(
  [tuple-of.no]=7
  [singleton.no]=11
  [nested-depth-4.no]=9
)
for name in "${!expected[@]}"; do
  source="tests/c07/f02/positive/$name"
  build/bin/neboc check "$source" >"$tmp/$name.check.out" 2>"$tmp/$name.check.err"
  test ! -s "$tmp/$name.check.out"
  test ! -s "$tmp/$name.check.err"
  build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
  build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
  cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
  TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
  set +e
  "$tmp/$name.elf"
  rc=$?
  set -e
  test "$rc" -eq "${expected[$name]}"
done

build/bin/neboc check tests/c07/f02/positive/empty.no

negative=tests/c07/f02/negative/nested-depth-5.no
for mode in check emit-asm build; do
  artifact="$tmp/depth.$mode.artifact"
  set +e
  if [[ $mode == check ]]; then
    build/bin/neboc check "$negative" >"$tmp/depth.$mode.out" 2>"$tmp/depth.$mode.err"
  else
    TMPDIR="$tmp_parent" build/bin/neboc "$mode" "$negative" -o "$artifact" >"$tmp/depth.$mode.out" 2>"$tmp/depth.$mode.err"
  fi
  rc=$?
  set -e
  test "$rc" -eq 1
  test ! -s "$tmp/depth.$mode.out"
  test ! -e "$artifact"
  test "$(wc -l <"$tmp/depth.$mode.err")" -ge 1
done

nasm -f elf64 -Wall -Werror -I. -o "$tmp/struct-tuple.a.o" compiler/semantic/types/struct_tuple.asm
nasm -f elf64 -Wall -Werror -I. -o "$tmp/struct-tuple.b.o" compiler/semantic/types/struct_tuple.asm
cmp -s "$tmp/struct-tuple.a.o" "$tmp/struct-tuple.b.o"

printf '%s\n' 'C07_F02_GREEN constructor=Tuple.of compatibility=Tuple arity=0..8 nested_depth=4 heterogeneous_type_vector=yes output_atomic=yes deterministic=yes'
