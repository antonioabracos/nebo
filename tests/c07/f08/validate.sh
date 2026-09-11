#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f08.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 c07-f08-tests

for name in map-each.no to-struct.no dynamic-index.no named-position.no; do
 source="tests/c07/f08/negative/$name"
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

TMPDIR="$tmp_parent" bash tests/c07/f07/validate.sh >/dev/null
printf '%s\n' 'C07_F08_GREEN mapEach=implemented toStruct=implemented dynamic_index=POST_1_0 named_positions=POST_1_0 silent_fallback=no output_atomic=yes f07=yes'
