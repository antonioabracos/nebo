#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC

root=$(git rev-parse --show-toplevel)
cd "$root"
registry=compiler/tokens/operator_registry.inc

fail() {
  printf 'RF148 G148 Registry coverage failed: %s\n' "$*" >&2
  exit 1
}

count_ids() {
  local family=$1
  rg -c "^%define NEBOC_OPERATOR_ID_NSR_${family}_[0-9]{3} " "$registry"
}

test "$(count_ids CORE)" -eq 47 || fail "CORE identity count"
test "$(count_ids UA)" -eq 9 || fail "Unicode alias identity count"
test "$(count_ids DOM)" -eq 80 || fail "domain identity count"
test "$(count_ids RES)" -eq 23 || fail "RESERVED identity count"
test "$(count_ids REJ)" -eq 26 || fail "REJECTED identity count"
test "$(rg '^%define NEBOC_OPERATOR_ID_NSR_(CORE|UA|DOM|RES|REJ)_[0-9]{3} ' "$registry" | wc -l)" -eq 185 || fail "complete Registry identity row count"
test "$(rg '^%define NEBOC_OPERATOR_ID_NSR_(CORE|UA|DOM|RES|REJ)_[0-9]{3} ' "$registry" | awk '{print $2}' | sort -u | wc -l)" -eq 185 || fail "unique Registry identity names"
test "$(rg '^%define NEBOC_OPERATOR_ID_NSR_(CORE|UA|DOM|RES|REJ)_[0-9]{3} ' "$registry" | awk '{print $3}' | sort -u | wc -l)" -eq 185 || fail "unique Registry identity values"

for ordinal in $(seq 1 47); do
  suffix=$(printf '%03d' "$ordinal")
  rg -Fxq "%define NEBOC_OPERATOR_ID_NSR_CORE_${suffix} ${ordinal}" "$registry" || fail "CORE identity $suffix"
done
for ordinal in $(seq 1 9); do
  suffix=$(printf '%03d' "$ordinal")
  value=$((47 + ordinal))
  rg -Fxq "%define NEBOC_OPERATOR_ID_NSR_UA_${suffix} ${value}" "$registry" || fail "Unicode alias identity $suffix"
done
for ordinal in $(seq 1 80); do
  suffix=$(printf '%03d' "$ordinal")
  value=$(printf '0x000000010000%04x' "$ordinal")
  rg -Fxq "%define NEBOC_OPERATOR_ID_NSR_DOM_${suffix} ${value}" "$registry" || fail "domain identity $suffix"
done
for ordinal in $(seq 1 23); do
  suffix=$(printf '%03d' "$ordinal")
  value=$((136 + ordinal))
  rg -Fxq "%define NEBOC_OPERATOR_ID_NSR_RES_${suffix} ${value}" "$registry" || fail "RESERVED identity $suffix"
done
for ordinal in $(seq 1 26); do
  suffix=$(printf '%03d' "$ordinal")
  value=$((159 + ordinal))
  rg -Fxq "%define NEBOC_OPERATOR_ID_NSR_REJ_${suffix} ${value}" "$registry" || fail "REJECTED identity $suffix"
done

timeout 30 build/tests/rf204/G148/closeout_probe >/dev/null || fail "native inventory verifier"

printf '%s\n' \
  'RF148_G148_REGISTRY_COVERAGE=PASS' \
  'REGISTRY_UNIVERSE=185/185' \
  'REGISTRY_CLASSES=47+9+80+23+26' \
  'REGISTRY_GAPS=0' \
  'REGISTRY_DUPLICATES=0' \
  'REGISTRY_PUBLIC_ENTRIES_ACTIVATED=0'
