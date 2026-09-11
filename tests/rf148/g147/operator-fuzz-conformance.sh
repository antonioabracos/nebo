#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC
root=$(git rev-parse --show-toplevel)
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT INT TERM HUP

fail() { printf 'G147 operator fuzz failed: %s\n' "$*" >&2; exit 1; }
ninja -f build.ninja -j2 build/bin/neboc >/dev/null
compiler=build/bin/neboc

replays=0
for source in examples/rf204/G147/RF204-G147-S??.no; do
  name=$(basename "$source" .no)
  timeout 30 "$compiler" fuzz "$source" --cases 32 --seed 147 >"$tmp/$name.a.json"
  timeout 30 "$compiler" fuzz "$source" --cases 32 --seed 147 >"$tmp/$name.b.json"
  timeout 30 "$compiler" fuzz "$source" --cases 32 --seed 148 >"$tmp/$name.other.json"
  cmp -s "$tmp/$name.a.json" "$tmp/$name.b.json" || fail "$name replay changed"
  jq -e '.schema == 1 and .command == "fuzz" and .cases == 32 and .seed == 147 and (.digest | length) == 64' "$tmp/$name.a.json" >/dev/null || fail "$name fuzz report malformed"
  digest_a=$(jq -r .digest "$tmp/$name.a.json")
  digest_other=$(jq -r .digest "$tmp/$name.other.json")
  test "$digest_a" != "$digest_other" || fail "$name ignored the seed"
  replays=$((replays + 1))
done
test "$replays" -eq 8 || fail "expected eight replayable sources"

# Differential/property corpus: generated arithmetic is compiled and its native
# result is checked against a shell-side integer oracle.
properties=0
for row in '3 5 2 15' '7 11 3 52' '13 17 4 117' '19 23 5 207' '29 31 6 235' '37 41 7 222'; do
  read -r left right factor expected <<<"$row"
  source="$tmp/property-$properties.no"
  adjustment=$(((left + right) * factor - expected))
  printf '// Generated deterministic operator property case.\nstart() { ((%s + %s) * %s - %s).return; }\n' \
    "$left" "$right" "$factor" "$adjustment" >"$source"
  timeout 30 "$compiler" build "$source" -o "$tmp/property-$properties" --quiet
  set +e
  timeout 30 "$tmp/property-$properties"
  observed=$?
  set -e
  test "$observed" -eq "$expected" || fail "property $properties returned $observed"
  properties=$((properties + 1))
done

# Reserved/rejected forms must fail in all diagnostic encodings.
printf '%s\n' 'start() { value++; }' >"$tmp/rejected.no"
for format in human json-lines sarif; do
  set +e
  timeout 30 "$compiler" check "$tmp/rejected.no" --message-format "$format" --color never >"$tmp/rejected.$format.out" 2>"$tmp/rejected.$format.err"
  status=$?
  set -e
  test "$status" -eq 1 || fail "rejected form passed in $format"
  rg -q 'NEBO_LEX_(RESERVED_SYMBOL|REJECTED_FORM)' "$tmp/rejected.$format.out" "$tmp/rejected.$format.err" || fail "missing rejected diagnostic in $format"
done

cp examples/rf204/G147/RF204-G147-S06.no "$tmp/renamed-property.no"
printf '%s\n' '// Metamorphic trailing trivia.' >>"$tmp/renamed-property.no"
timeout 30 "$compiler" emit-asm examples/rf204/G147/RF204-G147-S06.no -o "$tmp/original.asm"
timeout 30 "$compiler" emit-asm "$tmp/renamed-property.no" -o "$tmp/renamed.asm"
cmp -s "$tmp/original.asm" "$tmp/renamed.asm" || fail "trivia changed codegen"

printf '%s\n' \
  'RF148_G147_OPERATOR_FUZZ=PASS' \
  'FUZZ_REPLAYS=8/8' \
  'PROPERTY_DIFFERENTIAL=6/6' \
  'NEGATIVE_TRI_MODE=3/3' \
  'METAMORPHIC_TRIVIA=PASS'
