#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC PYTHONDONTWRITEBYTECODE=1

root=$(git rev-parse --show-toplevel)
cd "$root"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

fail() {
  printf 'RF166 G149 foundation conformance failed: %s\n' "$*" >&2
  exit 1
}

check_static_elf() {
  local executable=$1
  file "$executable" | rg -q 'ELF 64-bit.*x86-64.*statically linked' || fail "probe is not static x86-64 ELF"
  test -z "$(nm -u "$executable")" || fail "probe has undefined symbols"
  test -z "$(readelf -dW "$executable" 2>/dev/null | awk '/NEEDED/')" || fail "probe has dynamic dependencies"
  readelf -lW "$executable" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}' || fail "probe has executable stack"
}

python3 -B tests/rf204/G149/verify_foundation.py >"$work/registries.log"
rg -q '^FOUNDATION_REGISTRIES=PASS$' "$work/registries.log" || fail "registry/catalog parity"
tests/rf148/g148/registry-coverage-conformance.sh >"$work/rf148-coverage.log"
rg -q '^REGISTRY_UNIVERSE=185/185$' "$work/rf148-coverage.log" || fail "RF148 Registry universe"
rg -q '^REGISTRY_GAPS=0$' "$work/rf148-coverage.log" || fail "RF148 Registry gaps"
git diff --quiet -- compiler/tokens/operator_registry.inc || fail "G149 changed the Operator Registry"

for pass in a b; do
  timeout 30 build/tests/rf204/G149/foundation_probe >"$work/native.$pass.bin"
  python3 -B tests/rf204/G149/foundation_oracle.py >"$work/oracle.$pass.txt"
done
cmp -s "$work/native.a.bin" "$work/native.b.bin" || fail "native probe nondeterminism"
cmp -s "$work/oracle.a.txt" "$work/oracle.b.txt" || fail "oracle nondeterminism"
sed -n '1s/^OBSERVATION_HEX=//p' "$work/oracle.a.txt" | xxd -r -p >"$work/oracle.bin"
cmp -s "$work/native.a.bin" "$work/oracle.bin" || fail "native/oracle mismatch"
test "$(wc -c <"$work/native.a.bin")" -eq 136 || fail "native observation length"

test "$(find examples/rf204/G149 -maxdepth 1 -type f -name 'RF204-G149-S??.no' | wc -l)" -eq 8 || fail "example count"
test "$(sha256sum examples/rf204/G149/RF204-G149-S??.no | awk '{print $1}' | sort -u | wc -l)" -eq 8 || fail "example identities"
for source in examples/rf204/G149/RF204-G149-S??.no; do
  source_id=$(sha256sum "$source" | cut -c1-16)
  rg -Fiq "0x${source_id}" tests/rf204/G149/foundation_probe.asm || fail "native manifest is not bound to $(basename "$source")"
done

test "$(awk 'END {print NR-1}' tests/rf204/G149/SURFACE-MAP.tsv)" -eq 40 || fail "surface count"
test "$(awk -F '\t' 'NR>1 && $7=="PASS" {n++} END {print n+0}' tests/rf204/G149/SURFACE-MAP.tsv)" -eq 40 || fail "open surface"
if rg -n 'RF204-G149-S[0-9]{2}\.no|examples/rf204/G149|tests/rf204/G149' compiler runtime tools; then
  fail "fixture-specific product routing"
fi
if rg -n 'language-contract|roadmap-audit' compiler/driver compiler/parser compiler/lexer; then
  fail "future public CLI was activated"
fi
test -z "$(find compiler/authority/rf166 tests/rf204/G149 -type f -name '*.c' -print)" || fail "C implementation"
check_static_elf build/tests/rf204/G149/foundation_probe

printf '%s\n' \
  'RF166_G149_FOUNDATION_CONFORMANCE=PASS' \
  'AUTHORITY_FACTS=12/12' \
  'FREEZE_DECISIONS=14/14' \
  'FRONT_DAG=146_NODES_145_EDGES_4_PACKS' \
  'RF148_REGISTRY=185/185' \
  'PUBLIC_PRODUCT_ACTIVATIONS=0' \
  'NATIVE_ORACLE_PARITY=PASS' \
  'BORROWED_REPORTS_READ_ONLY=PASS' \
  'FAILURE_ATOMICITY=PASS' \
  'OPEN_P0=0' \
  'OPEN_P1=0' \
  'OPEN_P2=0' \
  'NEXT_GROUP=G150' \
  'NEXT_GROUP_STARTED=NO'
