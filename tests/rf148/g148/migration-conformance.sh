#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC

root=$(git rev-parse --show-toplevel)
cd "$root"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

fail() {
  printf 'RF148 G148 migration conformance failed: %s\n' "$*" >&2
  exit 1
}

tests/rf148/g144/reserved-symbol-conformance.sh >"$work/reserved.log"
tests/rf148/g145/rejected-syntax-conformance.sh >"$work/rejected.log"
rg -q '^REGISTRY_ROWS=23/23$' "$work/reserved.log" || fail "RESERVED row regression"
rg -q '^EXECUTABLE_SEMANTICS=0$' "$work/reserved.log" || fail "RESERVED execution regression"
rg -q '^REGISTRY_ROWS=26/26$' "$work/rejected.log" || fail "REJECTED row regression"
rg -q '^EXECUTABLE_SEMANTICS=0$' "$work/rejected.log" || fail "REJECTED execution regression"
rg -q '^NO_COMPATIBILITY_MODE=PASS$' "$work/rejected.log" || fail "silent compatibility regression"

printf '%s\n' \
  'RF148_G148_MIGRATION_CONFORMANCE=PASS' \
  'RESERVED_ROWS=23/23' \
  'REJECTED_ROWS=26/26' \
  'EXECUTABLE_SEMANTICS=0' \
  'AUTOMATIC_MIGRATIONS=0'
