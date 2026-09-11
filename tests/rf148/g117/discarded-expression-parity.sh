#!/usr/bin/env bash
set -Eeuo pipefail

RF148_REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$RF148_REPO_ROOT"

ninja -f build.ninja mf022-type-tests >/dev/null

# Cases 6-8 are deliberately invalid binary operators wrapped by
# NEBOC_AST_EXPRESSION_STMT.  The native harness succeeds only when the
# canonical typechecker visits the discarded child and emits the exact typed
# diagnostic.  Cases 1/3 and 14/15 protect valid and checked-constant parity.
for RF148_CASE in 1 3 6 7 8 14 15; do
  build/tests/mf022/type_test "$RF148_CASE"
done

# The structural invariant is intentionally checked independently of fixture
# names: ordinary statements must pass their complete child range to the same
# recursive type function used by returned/bound expressions.
grep -q 'ordinary statements type children and are Void' compiler/semantic/types/type_checker.asm
grep -q 'call tc_type_children' compiler/semantic/types/type_checker.asm

printf '%s\n' \
  'RF148_G117_DISCARDED_EXPRESSION_PARITY=PASS' \
  'VALID_DISCARDED_EXPRESSIONS=PASS' \
  'INVALID_DISCARDED_OPERATORS=TYPED_DIAGNOSTIC_PASS' \
  'CONSTANT_OVERFLOW_IN_DISCARDED_EXPRESSION=PASS' \
  'CANONICAL_TYPECHECKER_PATH=PASS'
