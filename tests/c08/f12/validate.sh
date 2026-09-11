#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 c08-f12-tests
build/tests/c08/f12/failure_safety_test
build/tests/c08/f05/list_mutation_test
build/tests/c08/f07/iterator_borrow_test
build/tests/c08/f09/queue_semantics_test
build/tests/c08/f10/deque_semantics_test
rows="$(awk 'END {print NR-1}' sdk/contracts/collections/DIAGNOSTIC-FAILURE-MATRIX.tsv)"
test "$rows" -eq 12
printf '%s\n' 'C08_F12_GREEN diagnostic_rows=12 invalid_argument=stable invalid_source=stable out_of_memory=stable limit_exceeded=stable error_outputs=unchanged option_empty=found_zero_payload_unchanged mutation_failure=atomic'
