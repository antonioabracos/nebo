#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f04.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 build/bin/neboc

declare -A positives=([length.no]=3 [length-boundaries.no]=8)
for name in "${!positives[@]}"; do
 source="tests/c07/f04/positive/$name"
 build/bin/neboc check "$source"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
 cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
 TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
 set +e; "$tmp/$name.elf"; rc=$?; set -e
 test "$rc" -eq "${positives[$name]}"
done

declare -A codes=(
 [arity-over.no]=NEBO_TUPLE_ARITY
 [at-bounds.no]=NEBO_TUPLE_INDEX_OUT_OF_RANGE
 [depth-over.no]=NEBO_TUPLE_NESTING_LIMIT
 [length-invalid-receiver.no]=NEBO_TUPLE_INVALID_RECEIVER
)
for name in "${!codes[@]}"; do
 source="tests/c07/f04/negative/$name"
 for mode in check emit-asm build; do
  artifact="$tmp/$name.$mode.artifact"
  set +e
  if [[ $mode == check ]]; then
   build/bin/neboc check "$source" --message-format human --color never >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err"
  else
   TMPDIR="$tmp_parent" build/bin/neboc "$mode" "$source" -o "$artifact" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err"
  fi
  rc=$?; set -e
  test "$rc" -eq 1
  test ! -s "$tmp/$name.$mode.out"
  test ! -e "$artifact"
  grep -Fq "${codes[$name]}" "$tmp/$name.$mode.err"
 done
 for format in json json-lines sarif; do
  set +e
  build/bin/neboc check "$source" --message-format "$format" --color never >"$tmp/$name.$format.out" 2>"$tmp/$name.$format.err"
  rc=$?; set -e
  test "$rc" -eq 1
  test ! -s "$tmp/$name.$format.out"
  grep -Fq "${codes[$name]}" "$tmp/$name.$format.err"
 done
done

TMPDIR="$tmp_parent" bash tests/c07/f03/validate.sh >/dev/null
printf '%s\n' 'C07_F04_GREEN length=yes arity=0..8 stable_tuple_diagnostics=human_json_jsonl_sarif output_atomic=yes f03=yes'
