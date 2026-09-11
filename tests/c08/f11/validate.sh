#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 c08-f11-tests
build/tests/c08/f11/function_boundary_test
if readelf -d build/tests/c08/f11/function_boundary_test | grep -q '(NEEDED)'; then
  echo 'hidden dynamic dependency in collection boundary test' >&2
  exit 1
fi
if ! grep -q $'owned_parameter\tDEFERRED' sdk/contracts/collections/FUNCTION-BOUNDARY-CONTRACT.tsv; then
  echo 'unsafe owned parameter was not deferred' >&2
  exit 1
fi
if ! grep -q $'borrowed_return_or_escape\tPROHIBITED' sdk/contracts/collections/FUNCTION-BOUNDARY-CONTRACT.tsv; then
  echo 'borrowed escape was not prohibited' >&2
  exit 1
fi
printf '%s\n' 'C08_F11_GREEN borrowed_read=bounded_nonescaping explicit_distinct_copy=pass owned_parameter_return=deferred borrowed_escape=prohibited closure_capture=prohibited hidden_allocation=no'
