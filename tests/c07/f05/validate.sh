#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f05.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 build/bin/neboc

declare -A positives=([destructure.no]=6 [destructure-nested.no]=8 [destructure-wildcard.no]=1)
for name in "${!positives[@]}"; do
 source="tests/c07/f05/positive/$name"
 build/bin/neboc check "$source"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
 cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
 TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
 set +e; "$tmp/$name.elf"; rc=$?; set -e
 test "$rc" -eq "${positives[$name]}"
done

declare -A codes=(
 [destructure-arity-short.no]=NEBO_TUPLE_ARITY
 [destructure-arity-long.no]=NEBO_TUPLE_ARITY
 [destructure-duplicate.no]=NEBO_TUPLE_DUPLICATE_BINDING
)
for name in "${!codes[@]}"; do
 source="tests/c07/f05/negative/$name"
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
  grep -Fq "${codes[$name]}" "$tmp/$name.$mode.err"
 done
done

TMPDIR="$tmp_parent" bash tests/c07/f04/validate.sh >/dev/null
printf '%s\n' 'C07_F05_GREEN destructure=yes wildcard=yes exact_arity=yes selected_binding_once=yes bounded_start_scope=yes output_atomic=yes f04=yes'
