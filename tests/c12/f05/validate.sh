#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f05-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
compiler="$repo/build/bin/neboc"
work="$(mktemp -d "${TMPDIR:-/tmp}/nebo-c12-f05.XXXXXX")"
cd "$repo"

ninja c12-f05-tests build/bin/neboc >/dev/null
build/tests/c12/f05/tensor_i64_constructors_test
for source in tests/c12/f01/positive/rank0-zeros.no tests/c12/f01/positive/filled.no tests/c12/f01/positive/from-buffer.no; do
  "$compiler" check "$source"
  "$compiler" emit-asm "$source" -o "$work/$(basename "$source").asm"
  TMPDIR="$work" "$compiler" build "$source" -o "$work/$(basename "$source").elf"
  "$work/$(basename "$source").elf"
done
tests/c12/f04/validate.sh >/dev/null
test -z "$(nm -u build/tests/c12/f05/tensor_i64_constructors_test)"
! readelf -lW build/tests/c12/f05/tensor_i64_constructors_test | grep -q INTERP
! readelf -dW build/tests/c12/f05/tensor_i64_constructors_test | grep -q '(NEEDED)'
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm tests/c12/f05
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F05_GREEN constructors=zeros,filled,fromBuffer-copy storage=fixed-caller source=check_emit_build_run copy=explicit exact_extent=yes adoption=no hidden_allocation=no failure_atomic=yes'
