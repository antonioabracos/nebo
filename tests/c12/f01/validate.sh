#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f01-python-cache"

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
compiler="$repo/build/bin/neboc"
work="$(mktemp -d "${TMPDIR:-/tmp}/nebo-c12-f01-r1-validation.XXXXXX")"
cd "$repo"

ninja build/bin/neboc >/dev/null

positive_count=0
for source in tests/c12/f01/positive/*.no; do
  name="$(basename "$source" .no)"
  "$compiler" check "$source"
  "$compiler" emit-asm "$source" -o "$work/$name.a.asm"
  "$compiler" emit-asm "$source" -o "$work/$name.b.asm"
  cmp "$work/$name.a.asm" "$work/$name.b.asm"
  TMPDIR="$work" "$compiler" build "$source" -o "$work/$name.elf"
  set +e
  "$work/$name.elf"
  status=$?
  set -e
  test "$status" -eq 0
  file "$work/$name.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$work/$name.elf" | rg -q INTERP
  test -z "$(nm -u "$work/$name.elf")"
  positive_count=$((positive_count + 1))
done
test "$positive_count" -eq 8

declare -A expected=(
  [unsupported-dtype]='NEBO-SCIENTIFIC-001: Tensor public dtype must be Int'
  [missing-dtype]='NEBO-SCIENTIFIC-001: Tensor public dtype must be Int'
  [rank4]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [negative-dimension]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [dimension-limit]='NEBO-SCIENTIFIC-007: Tensor rank dimensions or checked element product exceed CPU_I64_SMALL_V1 limits'
  [product-limit]='NEBO-SCIENTIFIC-007: Tensor rank dimensions or checked element product exceed CPU_I64_SMALL_V1 limits'
  [malformed-separator]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [nested-shape]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [non-int-shape]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [zeros-wrong-arity]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [filled-wrong-order]='NEBO-SCIENTIFIC-002: expected Tensor<Int> with bounded Tuple.of shape'
  [from-buffer-wrong-source]='NEBO-SCIENTIFIC-010: Tensor fromBuffer requires a nonoverlapping explicit copy source'
  [from-buffer-length-mismatch]='NEBO-SCIENTIFIC-003: Tensor shape does not match the selected source extent'
  [from-buffer-strides]='NEBO-SCIENTIFIC-010: Tensor fromBuffer requires a nonoverlapping explicit copy source'
  [from-buffer-adopt]='NEBO-SCIENTIFIC-010: Tensor fromBuffer requires a nonoverlapping explicit copy source'
  [from-nested]='NEBO-SCIENTIFIC-016: Tensor constructor or operation is deferred by the current C12 tier'
  [unknown-constructor]='NEBO-SCIENTIFIC-016: Tensor constructor or operation is deferred by the current C12 tier'
)

negative_count=0
for source in tests/c12/f01/negative/*.no; do
  name="$(basename "$source" .no)"
  set +e
  "$compiler" check "$source" >"$work/$name.stdout" 2>"$work/$name.stderr"
  status=$?
  "$compiler" emit-asm "$source" -o "$work/$name.rejected.asm" >"$work/$name.emit.stdout" 2>"$work/$name.emit.stderr"
  emit_status=$?
  "$compiler" build "$source" -o "$work/$name.rejected.elf" >"$work/$name.build.stdout" 2>"$work/$name.build.stderr"
  build_status=$?
  set -e
  test "$status" -eq 1
  test "$emit_status" -eq 1
  test "$build_status" -eq 1
  test ! -s "$work/$name.stdout"
  rg -qF "${expected[$name]}" "$work/$name.stderr"
  test ! -e "$work/$name.rejected.asm"
  test ! -e "$work/$name.rejected.elf"
  negative_count=$((negative_count + 1))
done
test "$negative_count" -eq 17

for format in human json json-lines sarif; do
  for pass in a b; do
    set +e
    "$compiler" check tests/c12/f01/negative/product-limit.no --message-format "$format" \
      >"$work/diagnostic.$format.$pass.stdout" 2>"$work/diagnostic.$format.$pass.stderr"
    status=$?
    set -e
    test "$status" -eq 1
    test ! -s "$work/diagnostic.$format.$pass.stdout"
    rg -q 'NEBO-SCIENTIFIC-007' "$work/diagnostic.$format.$pass.stderr"
  done
  cmp "$work/diagnostic.$format.a.stderr" "$work/diagnostic.$format.b.stderr"
done
rg -q '"start":[1-9][0-9]*' "$work/diagnostic.json.a.stderr"
rg -q '"ruleId":"NEBO-SCIENTIFIC-007"' "$work/diagnostic.sarif.a.stderr"

mkdir -p "$work/moved/root"
cp tests/c12/f01/positive/rank3-product64-zeros.no "$work/moved/root/renamed-tensor-source.no"
"$compiler" check "$work/moved/root/renamed-tensor-source.no"

cp tests/c12/f01/positive/filled.no "$work/formatted.no"
python3 -B tools/rf27-format.py "$work/formatted.no" --compiler "$compiler"
first_format="$(sha256sum "$work/formatted.no" | cut -d' ' -f1)"
python3 -B tools/rf27-format.py "$work/formatted.no" --compiler "$compiler"
second_format="$(sha256sum "$work/formatted.no" | cut -d' ' -f1)"
test "$first_format" = "$second_format"

python3 -B compiler/sdk/sdk_builder.py build --repo "$repo" --neboc "$compiler" --output "$work/sdk" --profile sdk >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$work/sdk" >/dev/null
"$work/sdk/bin/neboc" check "$work/moved/root/renamed-tensor-source.no"

test -f sdk/interfaces/scientific/tensor-int-v1.ni.identity
rg -qxF 'Nebo.NI.Scientific.v1|Tensor|Int|rank=0..3|shape=Tuple.of|dimensions=0..8|elements=64|constructors=zeros,filled,fromBuffer-explicit-copy|storage=fixed-caller-512-owner-generation-v1|function-abi=deferred|target=linux-x86_64-systemv-static' \
  sdk/interfaces/scientific/tensor-int-v1.ni.identity

rg -q 'NEBOC_VECTOR_VERTICAL_TENSOR_TYPE_OFFSET' compiler/semantic/collections/vector_vertical.inc
rg -q 'ls_tensor_parse_shape' compiler/semantic/structural/legacy_source_verticals.asm
rg -q 'cli_tokens_contain_tensor_atom' compiler/driver/cli/linux-x86_64/cli_driver.asm
! rg -n 'rank0-zeros|rank3-product64-zeros|from-buffer-length-mismatch|tests/c12/f01' \
  compiler/semantic/structural/legacy_source_verticals.asm compiler/driver/cli/linux-x86_64/cli_driver.asm

tests/c11/f01/validate.sh >/dev/null
tests/c11/f13/validate-r2.sh

test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F01_R1_GREEN fields=6/6 type=Tensor<Int> rank=0..3 dims=0..8 elements=64 constructors=zeros,filled,fromBuffer-copy deferred=fromNested diagnostics=001,002,003,007,010,016 sdk=clean formatter=deterministic pre_fix_sensitive=yes'
