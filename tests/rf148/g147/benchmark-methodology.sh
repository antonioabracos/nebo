#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC
root=$(git rev-parse --show-toplevel)
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT INT TERM HUP

fail() { printf 'G147 benchmark methodology failed: %s\n' "$*" >&2; exit 1; }
ninja -f build.ninja -j2 build/bin/neboc >/dev/null
compiler=build/bin/neboc

# The gate uses deterministic work units from real compiler stages. Wall time is
# deliberately informational because scheduler noise cannot close conformance.
cases=0
for source in examples/rf204/G147/RF204-G147-S??.no; do
  name=$(basename "$source" .no)
  source_hash=$(sha256sum "$source" | cut -d' ' -f1)
  for pass in a b; do
    timeout 30 "$compiler" profile "$source" >"$tmp/$name.$pass.json"
  done
  cmp -s "$tmp/$name.a.json" "$tmp/$name.b.json" || fail "$name profile changed"
  jq -e --arg hash "$source_hash" '
    .schema == 1 and .command == "profile" and .source_sha256 == $hash
    and .compilerWorkUnits.parseBytes > 0
    and .compilerWorkUnits.loweredLines > 0
    and .compilerWorkUnits.codegenBytes > 0
    and .memoryReport.sourceBytes == .compilerWorkUnits.parseBytes
    and .memoryReport.assemblyBytes == .compilerWorkUnits.codegenBytes
  ' "$tmp/$name.a.json" >/dev/null || fail "$name profile lacks source-bound work"
  parse=$(jq -r '.compilerWorkUnits.parseBytes' "$tmp/$name.a.json")
  codegen=$(jq -r '.compilerWorkUnits.codegenBytes' "$tmp/$name.a.json")
  test "$parse" -le 4194304 || fail "$name exceeds source budget"
  test "$codegen" -le $((parse * 128 + 16384)) || fail "$name exceeds codegen budget"
  cases=$((cases + 1))
done
test "$cases" -eq 8 || fail "expected eight benchmark sources"

# Cold is a fresh output, warm repeats the identical input, and incremental
# changes one comment byte. All three still traverse parser/lowering/codegen.
base=examples/rf204/G147/RF204-G147-S01.no
cp "$base" "$tmp/incremental.no"
printf '%s\n' '// Incremental benchmark edit changes trivia only.' >>"$tmp/incremental.no"
timeout 30 "$compiler" profile "$base" >"$tmp/cold.json"
timeout 30 "$compiler" profile "$base" >"$tmp/warm.json"
timeout 30 "$compiler" profile "$tmp/incremental.no" >"$tmp/incremental.json"
cmp -s "$tmp/cold.json" "$tmp/warm.json" || fail "warm run changed deterministic facts"
jq -e --slurpfile cold "$tmp/cold.json" '
  .compilerWorkUnits.parseBytes > $cold[0].compilerWorkUnits.parseBytes
  and .compilerWorkUnits.loweredLines >= $cold[0].compilerWorkUnits.loweredLines
  and .observed.exit == $cold[0].observed.exit
' "$tmp/incremental.json" >/dev/null || fail "incremental edit did not retain semantics"

printf '%s\n' \
  'RF148_G147_BENCHMARK_METHODOLOGY=PASS' \
  'BENCHMARK_MODES=3/3' \
  'BENCHMARK_CASES=8/8' \
  'PERFORMANCE_GATE=DETERMINISTIC_WORK_UNITS'
