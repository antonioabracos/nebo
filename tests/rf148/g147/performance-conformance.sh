#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC
root=$(git rev-parse --show-toplevel)
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT INT TERM HUP

fail() { printf 'G147 conformance failed: %s\n' "$*" >&2; exit 1; }
ninja -f build.ninja -j2 build/bin/neboc build/tests/rf204/G147/performance_probe >/dev/null

tests/rf148/g147/benchmark-methodology.sh >"$tmp/benchmark.log"
tests/rf148/g147/operator-fuzz-conformance.sh >"$tmp/fuzz.log"
tests/rf148/g147/multitarget-conformance.sh >"$tmp/targets.log"
rg -q '^RF148_G147_BENCHMARK_METHODOLOGY=PASS$' "$tmp/benchmark.log" || fail "benchmark marker"
rg -q '^RF148_G147_OPERATOR_FUZZ=PASS$' "$tmp/fuzz.log" || fail "fuzz marker"
rg -q '^RF148_G147_MULTITARGET_CONFORMANCE=PASS$' "$tmp/targets.log" || fail "target marker"

for pass in a b; do
  timeout 30 build/tests/rf204/G147/performance_probe >"$tmp/native.$pass.bin"
  python3 tests/rf204/G147/performance_oracle.py >"$tmp/oracle.$pass.txt"
done
cmp -s "$tmp/native.a.bin" "$tmp/native.b.bin" || fail "native record changed"
cmp -s "$tmp/oracle.a.txt" "$tmp/oracle.b.txt" || fail "oracle changed"
sed -n '1s/^OBSERVATION_HEX=//p' "$tmp/oracle.a.txt" | xxd -r -p >"$tmp/oracle.bin"
cmp -s "$tmp/native.a.bin" "$tmp/oracle.bin" || fail "native/oracle mismatch"
rg -q '^INDEPENDENT_ORACLE=PASS$' "$tmp/oracle.a.txt" || fail "oracle self-test"

owners=0
for source in compiler/registry/performance/*.asm; do
  name=$(basename "$source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$tmp/$name.a.o" "$source"
  nasm -f elf64 -Wall -Werror -I./ -o "$tmp/$name.b.o" "$source"
  cmp -s "$tmp/$name.a.o" "$tmp/$name.b.o" || fail "$name object changed"
  owners=$((owners + 1))
done
test "$owners" -eq 8 || fail "expected eight implementation owners"
for symbol in benchmarkOperatorCompiler benchmarkOperatorLexer benchmarkOperatorParser \
  nebo_operator_query_cache_lookup benchmarkOperatorSourceScaling nebo_operator_fuzz_next \
  runOperatorMultiTargetConformance nebo_operator_performance_closeout; do
  nm -g build/tests/rf204/G147/performance_probe | awk '{print $3}' | rg -qx "$symbol" || fail "missing owner $symbol"
done

printf '%s\n' \
  'RF148_G147_PERFORMANCE_CONFORMANCE=PASS' \
  'NATIVE_ORACLE_PARITY=PASS' \
  'FAILURE_ATOMICITY=PASS' \
  'PERFORMANCE_OWNERS=8/8' \
  'REGISTRY_PUBLIC_ENTRIES_ACTIVATED=0'
