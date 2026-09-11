#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}"
cd "$root"

# MF020 originally also asserted that later-roadmap semantic/codegen directories
# did not exist. That temporal assertion is no longer valid after TR05–TR08.
# The lasting contract is zero unapproved mandatory HIR/MIR/LIR layer.
found="$(
  find compiler -mindepth 1 \( -type d -o -type f \) -print |
    grep -Ei '(^|/)(hir|mir|lir)(/|[.])' || true
)"
[[ -z "$found" ]] || {
  echo MF060_AST_LAYER_AUDIT_FAIL >&2
  printf '%s\n' "$found" >&2
  exit 1
}

if grep -Ei 'compiler/(hir|mir|lir)(/|[.])' build.ninja >/dev/null; then
  echo 'MF060_AST_LAYER_AUDIT_FAIL: unapproved IR build target' >&2
  exit 1
fi

grep -Fq 'No HIR, MIR or LIR' compiler/ast/store/README.md

echo NEBO_AST_DOC_AUDIT_010_GREEN no_unapproved_ir=1 later_roadmap_paths=ALLOWED
