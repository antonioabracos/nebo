#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo"
tmp_parent="$repo/build/tmp"
mkdir -p "$tmp_parent"
tmp=$(mktemp -d "$tmp_parent/c07-f03.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
ninja -f build.ninja -j1 build/bin/neboc

declare -A positives=([at-const.no]=8 [nested-at.no]=9)
for name in "${!positives[@]}"; do
 source="tests/c07/f03/positive/$name"
 build/bin/neboc check "$source"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.a.asm"
 build/bin/neboc emit-asm "$source" -o "$tmp/$name.b.asm"
 cmp -s "$tmp/$name.a.asm" "$tmp/$name.b.asm"
 TMPDIR="$tmp_parent" build/bin/neboc build "$source" -o "$tmp/$name.elf"
 set +e; "$tmp/$name.elf"; rc=$?; set -e
 test "$rc" -eq "${positives[$name]}"
done

for name in at-bounds.no at-dynamic.no; do
 source="tests/c07/f03/negative/$name"
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
# C07-F04 owns stable diagnostic routing. F03 proves only fail-closed,
# tri-mode output atomicity for both constant bounds and dynamic-index syntax.

# All previous F02 source gates remain green.
TMPDIR="$tmp_parent" bash tests/c07/f02/validate.sh >/dev/null
printf '%s\n' 'C07_F03_GREEN construction=exactly_once at_const=yes nested_projection=yes bounds_atomic=yes dynamic_index_rejected=yes f02=yes'
