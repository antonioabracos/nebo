#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
work=${TMPDIR:-/tmp}/nebo-c11-f13-cycle1-validation
mkdir -p "$work"
compiler="$repo/build/bin/neboc"

run_case() {
  local name=$1 expected=$2 source="$repo/tests/c11/f13/positive/$1.no"
  "$compiler" check "$source"
  "$compiler" emit-asm "$source" -o "$work/$name.a.asm"
  "$compiler" emit-asm "$source" -o "$work/$name.b.asm"
  cmp "$work/$name.a.asm" "$work/$name.b.asm"
  TMPDIR="$work" "$compiler" build "$source" -o "$work/$name.elf"
  set +e
  "$work/$name.elf"
  local actual=$?
  set -e
  test "$actual" -eq "$expected"
}

run_case filled 42
run_case from-buffer 21
run_case from-rows 21
run_case zeros-add-sum 0

for spec in unsupported-dtype:001 dimension-limit:007 ragged-from-rows:007 deferred-constructor:016; do
  name=${spec%%:*}; code=${spec##*:}
  set +e
  output=$("$compiler" check "$repo/tests/c11/f13/negative/$name.no" --message-format human --color never 2>&1)
  status=$?
  set -e
  test "$status" -ne 0
  case "$output" in *"NEBO-SCIENTIFIC-$code"*) ;; *) exit 1 ;; esac
done

bash "$repo/tests/c11/f13/validate-r2.sh"
bash "$repo/tests/c11/f13/anti-special-case-r2.sh"
