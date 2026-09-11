#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C PYTHONDONTWRITEBYTECODE=1

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$repo_root"
compiler="$repo_root/build/bin/neboc"
work=$(mktemp -d /tmp/nebo-rf204-g007.XXXXXX)
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT INT TERM HUP

ninja -f build.ninja -j2 build/bin/neboc rf204-g007-conformance-tests >/dev/null

native_programs=(
  build/tests/rf27-g07/f02/list_core_test
  build/tests/rf27-g07/f03/list_algorithms_test
  build/tests/rf27-g07/f04/stack_test
  build/tests/rf27-g07/f05/ring_test
  build/tests/rf27-g07/f06/iterator_test
  build/tests/c08/f02/list_construction_test
  build/tests/c08/f03/list_capacity_test
  build/tests/c08/f04/list_access_test
  build/tests/c08/f05/list_mutation_test
  build/tests/c08/f06/list_algorithms_test
  build/tests/c08/f07/iterator_borrow_test
  build/tests/c08/f08/stack_semantics_test
  build/tests/c08/f09/queue_semantics_test
  build/tests/c08/f10/deque_semantics_test
  build/tests/c08/f11/function_boundary_test
  build/tests/c08/f12/failure_safety_test
  build/tests/rf204/G007/native_collection_test
)

for native in "${native_programs[@]}"; do
  "$native"
  "$native"
  file "$native" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$native" | rg -q INTERP
  test -z "$(nm -u "$native")"
done

expect_exit() {
  local executable=$1 expected=$2 actual=0
  "$executable" >"$work/last.stdout" 2>"$work/last.stderr" || actual=$?
  if [[ $actual -ne $expected ]]; then
    return 1
  fi
  test ! -s "$work/last.stdout"
  test ! -s "$work/last.stderr"
}

run_source() {
  local name=$1 source=$2 expected=$3
  "$compiler" check "$source" --message-format json-lines --color never >"$work/$name.check"
  test ! -s "$work/$name.check"
  "$compiler" emit-asm "$source" -o "$work/$name.a.asm"
  "$compiler" emit-asm "$source" -o "$work/$name.b.asm"
  cmp -s "$work/$name.a.asm" "$work/$name.b.asm"
  "$compiler" build "$source" -o "$work/$name.a.elf" --quiet
  "$compiler" build "$source" -o "$work/$name.b.elf" --quiet
  cmp -s "$work/$name.a.elf" "$work/$name.b.elf"
  expect_exit "$work/$name.a.elf" "$expected"
  file "$work/$name.a.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$work/$name.a.elf" | rg -q INTERP
  test -z "$(nm -u "$work/$name.a.elf")"
}

reject_source() {
  local name=$1 source=$2 expected_code=$3 mode status code artifact
  for mode in check emit-asm build; do
    artifact="$work/$name.$mode.artifact"
    set +e
    if [[ $mode == check ]]; then
      "$compiler" check "$source" --message-format json-lines --color never >"$work/$name.$mode.log" 2>&1
    else
      "$compiler" "$mode" "$source" -o "$artifact" >"$work/$name.$mode.log" 2>&1
    fi
    status=$?
    set -e
    test "$status" -eq 1
    test ! -e "$artifact"
    code=$(rg -o 'NEBO[-_A-Z0-9]+' "$work/$name.$mode.log" | sed -n '1p')
    test "$code" = "$expected_code"
  done
}

# One documentation-grade source per subgroup, with independent exit oracles.
run_source s01 examples/rf204/G007/RF204-G007-S01.no 7
run_source s02 examples/rf204/G007/RF204-G007-S02.no 2
run_source s03 examples/rf204/G007/RF204-G007-S03.no 5
run_source s04 examples/rf204/G007/RF204-G007-S04.no 0
run_source s05 examples/rf204/G007/RF204-G007-S05.no 15
run_source s06 examples/rf204/G007/RF204-G007-S06.no 12

# Diagnostics are identical in check/emit/build and never publish artifacts.
# The current typed List owner traps invalid dynamic access/capacity at runtime.
# These are intentional safe failure controls: the invalid access must not be
# optimized away, even when its result is unused (trap family 49 -> exit 177).
run_source bounds tests/rf204/G007/cases/bounds.no 177
run_source capacity tests/rf204/G007/cases/capacity.no 177
reject_source element-type tests/rf204/G007/cases/element-type.no NEBO_TYPE_MISMATCH
reject_source unknown-method tests/rf204/G007/cases/unknown-method.no NEBO_TYPE_MISMATCH
reject_source callback-shape tests/rf204/G007/cases/callback-shape.no NEBO_TYPE_MISMATCH
reject_source borrow-conflict tests/rf204/G007/cases/borrow-conflict.no NEBO_BORROW_CONFLICT
reject_source second-iterator tests/rf204/G007/cases/second-iterator.no NEBO_BORROW_CONFLICT
reject_source deduplicate-arity tests/rf204/G007/cases/deduplicate-arity.no NEBO_TYPE_MISMATCH
reject_source collect-target tests/rf204/G007/cases/collect-target.no NEBO_TYPE_MISMATCH

# Renaming a callback and changing data alter only the mathematically predicted value.
run_source metamorphic-callback tests/rf204/G007/cases/metamorphic-callback.no 9
run_source metamorphic-values tests/rf204/G007/cases/metamorphic-values.no 29
run_source metamorphic-subtract tests/rf204/G007/cases/metamorphic-subtract.no 12
run_source metamorphic-multiply tests/rf204/G007/cases/metamorphic-multiply.no 21
run_source metamorphic-predicate tests/rf204/G007/cases/metamorphic-predicate.no 2

# The oracle must reject a known-wrong observation.
set +e
expect_exit "$work/s01.a.elf" 99
false_green_status=$?
set -e
test "$false_green_status" -ne 0

# The shared Array owner is directly affected by routing; its complete group oracle remains green.
bash tests/rf204/G006/validate.sh >"$work/g006.log"
rg -q 'RF204_G006_GREEN' "$work/g006.log"

# Existing bounded corpus supplies throughput, allocation/memory and SDK regressions.
mkdir -p "$work/pycache"
PYTHONPYCACHEPREFIX="$work/pycache" bash tests/c08/f13/validate.sh >"$work/c08-f13.log"
rg -q 'C08_F13_GREEN positive=16 boundary=16 fuzz=32 traces=64 operations=2048 .*hidden_allocation=no' "$work/c08-f13.log"

python3 -B tests/release/post-g204-remediation/source_suite.py sequential --report "$work/current-source-suite.json"

# A public owner may be group-specific, but never fixture-name/path-specific.
if rg -n 'RF204-G007-S0[1-6]|examples/rf204/G007|tests/rf204/G007' compiler runtime >"$work/fixture-route.log"; then
  cat "$work/fixture-route.log" >&2
  exit 1
fi

test "$(awk -F '\t' 'NR>1 && $4=="PASS" {n++} END {print n+0}' tests/rf204/G007/SURFACE-MAP.tsv)" -eq 41
test "$(awk -F '\t' 'END {print NR-1}' tests/rf204/G007/SURFACE-MAP.tsv)" -eq 41
test "$(cut -f1 tests/rf204/G007/SURFACE-MAP.tsv | tail -n +2 | sort -u | wc -l)" -eq 41
test "$(find examples/rf204/G007 -maxdepth 1 -type f -name 'RF204-G007-S??.no' | wc -l)" -eq 6

echo 'RF204_G007_GREEN SUBGROUPS=6/6 SURFACES=41/41 EXAMPLES=6/6 POSITIVE=23/23 COMPILE_NEGATIVE=7/7 RUNTIME_NEGATIVE=2/2 CURRENT_SOURCE_CASES=149/149 METAMORPHIC=5/5 ADVERSARIAL=11/11 FALSE_GREEN=0 BENCHMARK_TRACES=64 BENCHMARK_OPERATIONS=2048'
