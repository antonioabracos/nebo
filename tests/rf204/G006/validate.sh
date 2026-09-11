#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$repo_root"
compiler="$repo_root/build/bin/neboc"
work=$(mktemp -d /tmp/nebo-rf204-g006.XXXXXX)
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT INT TERM HUP

ninja -f build.ninja -j2 \
  rf27-g06-f02-product-tests \
  rf27-g06-f03-array-range-tests \
  rf27-g06-f04-slice-view-tests \
  rf27-g06-f05-generic-tests \
  rf27-g06-f06-nominal-tests \
  c07-f08-tests >/dev/null

for native in \
  build/tests/rf27-g06-f02/product_native_test \
  build/tests/rf27-g06-f03/array_range_native_test \
  build/tests/rf27-g06-f04/slice_view_native_test \
  build/tests/rf27-g06-f05/generic_native_test \
  build/tests/rf27-g06-f06/nominal_native_test; do
  "$native"
  "$native"
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

run_native() {
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

# Each catalog subgroup is represented by one documentation-grade source.
run_native s01 examples/rf204/G006/RF204-G006-S01.no 11
run_native s02 examples/rf204/G006/RF204-G006-S02.no 12
run_native s03 examples/rf204/G006/RF204-G006-S03.no 7
run_native s04 examples/rf204/G006/RF204-G006-S04.no 5
run_native s05 examples/rf204/G006/RF204-G006-S05.no 47
run_native s06 examples/rf204/G006/RF204-G006-S06.no 1

# General structs, immutable updates, layout and independent values.
run_native struct-default tests/rf204/G006/cases/struct-default.no 0
run_native struct-layout tests/rf204/G006/cases/struct-layout.no 24
run_native struct-update-a tests/rf204/G006/cases/struct-update-a.no 11
run_native struct-update-b tests/rf204/G006/cases/struct-update-b.no 11
run_native struct-two-values tests/rf204/G006/cases/struct-two-values.no 13

# Heterogeneous Tuple transformations and explicit nominal conversion.
run_native tuple-map tests/rf204/G006/cases/tuple-map.no 12
run_native tuple-map-identity tests/rf204/G006/cases/tuple-map-identity.no 17

# Array.map covers a literal, a filled source through S03 and the N=0 boundary.
run_native array-map-literal tests/rf204/G006/cases/array-map-literal.no 7
run_native array-map-empty tests/rf204/G006/cases/array-map-empty.no 0

# Range observations are mathematical oracles, not values copied from output.
run_native range-contains-true tests/rf204/G006/cases/range-contains-true.no 1
run_native range-contains-false tests/rf204/G006/cases/range-contains-false.no 0
run_native range-inclusive tests/rf204/G006/cases/range-inclusive-length.no 5
run_native range-exclusive tests/rf204/G006/cases/range-exclusive-length.no 4
run_native range-equivalent tests/rf204/G006/cases/range-exclusive-equivalent.no 5

# Current generic grammar plus the prior inline Scalar/capability profile.
run_native generic-open tests/rf204/G006/cases/generic-unconstrained.no 37
run_native generic-where-copy tests/rf204/G006/cases/generic-where-copy.no 41
run_native generic-where-comparable tests/rf204/G006/cases/generic-where-comparable.no 120
run_native generic-where-hash-eq tests/rf204/G006/cases/generic-where-hash-eq.no 43
run_native generic-const tests/rf204/G006/cases/generic-const.no 47
run_native generic-inline-copy tests/rf204/G006/cases/generic-inline-copy.no 41
run_native generic-scalar examples/evolution/g07-scalar-generics.no 7

# Arbitrary eligible element types, Slice lifetime and nested owned fields.
run_native array-bool tests/rf27-g06/f03/positive/array-bool-access.no 1
run_native slice-release tests/rf27-g06/f04/positive/slice-release.no 0
run_native slice-two-borrows tests/rf27-g06/f04/positive/slice-two-borrows.no 9
run_native struct-text-drop tests/rf27-g06/f02/positive/text-drop-layout.no 4

# Alias identity, newtype identity/layout and closed unit/payload enums.
run_native alias-size tests/rf27-g06/f06/positive/alias-size.no 8
run_native newtype-int tests/rf27-g06/f06/positive/newtype-int.no 42
run_native newtype-char tests/rf27-g06/f06/positive/newtype-char.no 65
run_native newtype-text tests/rf27-g06/f06/positive/newtype-text.no 7
run_native enum-unit-discriminant tests/rf27-g06/f06/positive/enum-unit-discriminant.no 1
run_native enum-unit-size tests/rf27-g06/f06/positive/enum-unit-size.no 4
run_native enum-payload-match tests/rf27-g06/f06/positive/enum-payload-match.no 42
run_native enum-text-discriminant tests/rf27-g06/f06/positive/enum-text-discriminant.no 1

# Comment-only mentions must stay on the ordinary compiler path.
run_native comment-only-canary tests/rf204/G006/cases/comment-only-canary.no 0

# Diagnostics are exact across all three publishing modes; no artifact survives.
reject_source struct-update-unknown tests/rf204/G006/cases/struct-update-unknown.no NEBO_NAME_UNDEFINED
reject_source struct-update-duplicate tests/rf204/G006/cases/struct-update-duplicate.no NEBO_NAME_DUPLICATE
reject_source struct-default-argument tests/rf204/G006/cases/struct-default-argument.no NEBO_PARSE_UNEXPECTED_TOKEN
reject_source tuple-map-wrong-type tests/rf204/G006/cases/tuple-map-wrong-type.no NEBO_TUPLE_INVALID_RECEIVER
reject_source tuple-to-struct-mismatch tests/rf204/G006/cases/tuple-to-struct-mismatch.no NEBO_TUPLE_INVALID_RECEIVER
reject_source array-map-wrong-type tests/rf204/G006/cases/array-map-wrong-type.no NEBO_TYPE_MISMATCH
reject_source array-map-overflow tests/rf204/G006/cases/array-map-overflow.no NEBO_LIMIT_EXCEEDED
reject_source array-map-capture tests/rf204/G006/cases/array-map-capture.no NEBO_PARSE_UNEXPECTED_TOKEN
reject_source array-map-truncated tests/rf204/G006/cases/array-map-truncated.no NEBO_TYPE_MISMATCH
reject_source range-zero-step tests/rf204/G006/cases/range-zero-step.no NEBO_LIMIT_EXCEEDED
reject_source generic-hash-eq-failure tests/rf204/G006/cases/generic-hash-eq-failure.no NEBO_TYPE_MISMATCH
reject_source generic-const-overflow tests/rf204/G006/cases/generic-const-overflow.no NEBO_TYPE_MISMATCH
reject_source generic-const-truncated tests/rf204/G006/cases/generic-const-truncated.no NEBO_TYPE_MISMATCH
reject_source generic-where-malformed tests/rf204/G006/cases/generic-where-malformed.no NEBO_PARSE_UNEXPECTED_TOKEN

# Metamorphic pairs preserve independently specified results.
expect_exit "$work/struct-update-a.a.elf" 11
expect_exit "$work/struct-update-b.a.elf" 11
expect_exit "$work/s03.a.elf" 7
expect_exit "$work/array-map-literal.a.elf" 7
expect_exit "$work/range-inclusive.a.elf" 5
expect_exit "$work/range-equivalent.a.elf" 5
expect_exit "$work/generic-where-copy.a.elf" 41
expect_exit "$work/generic-inline-copy.a.elf" 41

# Prove the oracle rejects a known-wrong expected result.
set +e
expect_exit "$work/s01.a.elf" 99
false_green_status=$?
set -e
test "$false_green_status" -ne 0

# The G002 iterator extension and C07 receiver-function partition still work.
run_native iterator-next tests/rf204/G002/cases/iterator-next.no 2
bash tests/c07/f07/validate.sh >/dev/null
bash tests/c07/f08/validate.sh >/dev/null

test "$(awk -F '\t' 'NR>1 && $4=="PASS" {n++} END {print n+0}' tests/rf204/G006/SURFACE-MAP.tsv)" -eq 36
test "$(awk -F '\t' 'END {print NR-1}' tests/rf204/G006/SURFACE-MAP.tsv)" -eq 36
test "$(find examples/rf204/G006 -maxdepth 1 -type f -name 'RF204-G006-S??.no' | wc -l)" -eq 6

echo 'RF204_G006_GREEN SUBGROUPS=6/6 SURFACES=36/36 EXAMPLES=6/6 POSITIVE=40 NEGATIVE=14 METAMORPHIC=4 ADVERSARIAL=7 FALSE_GREEN=0'
