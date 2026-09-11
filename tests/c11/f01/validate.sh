#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/bin/neboc >/dev/null
root=build/tmp/c11-f01-validation
mkdir -p "$root"
for source in tests/c11/f01/positive/*.no; do
  build/bin/neboc check "$source"
done
build/bin/neboc emit-asm tests/c11/f01/positive/matrix-int-zeros.no -o "$root/a.asm"
build/bin/neboc emit-asm tests/c11/f01/positive/matrix-int-zeros.no -o "$root/b.asm"
cmp "$root/a.asm" "$root/b.asm"
build/bin/neboc build tests/c11/f01/positive/matrix-int-zeros.no -o "$root/matrix-int-zeros"
set +e
"$root/matrix-int-zeros"
status=$?
set -e
test "$status" -eq 6
file "$root/matrix-int-zeros" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW "$root/matrix-int-zeros" | rg -q INTERP
test -z "$(nm -u "$root/matrix-int-zeros")"
declare -A expected=(
  [matrix-float]='NEBO-SCIENTIFIC-001: Matrix public dtype must be Int'
  [matrix-dimension-limit]='NEBO-SCIENTIFIC-007: Matrix rows, columns and checked element product exceed CPU_I64_SMALL_V1 limits'
  [matrix-constructor-deferred]='NEBO-SCIENTIFIC-016: Matrix constructor or operation is deferred by the current C11 tier'
)
for source in tests/c11/f01/negative/*.no; do
  name="$(basename "$source" .no)"
  set +e
  build/bin/neboc check "$source" >"$root/$name.stdout" 2>"$root/$name.stderr"
  status=$?
  set -e
  test "$status" -eq 1
  test ! -s "$root/$name.stdout"
  rg -qF "${expected[$name]}" "$root/$name.stderr"
done
build/bin/neboc check examples/evolution/g11-vector-int4.no
test -z "$(find compiler runtime tests/c11 -type d -name __pycache__ -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C11_F01_GREEN parse_type=Matrix_Int zeros=yes dims=0..8 elements=64 Float=rejected diagnostics=causal emit_deterministic=yes static_elf=yes Tensor=unchanged'
