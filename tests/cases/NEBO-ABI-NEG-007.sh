#!/usr/bin/env sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$root"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf '%s\n' \
  invalid-target-request \
  incomplete-target-tuple \
  unsupported-target-id \
  unsupported-instruction-set \
  unsupported-target-abi \
  unsupported-object-format \
  unsupported-operating-environment \
  unsupported-runtime-profile \
  unsupported-console-runtime-profile \
  unsupported-toolchain-profile \
  unsupported-target-features \
  incompatible-data-layout \
  target-context-not-frozen > "$tmp"
cmp "$tmp" tests/target/goldens/target-diagnostics.txt
build/tests/mf031/target_test 4
