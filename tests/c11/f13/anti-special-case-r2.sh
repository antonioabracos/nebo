#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
root=${TMPDIR:-/tmp}/nebo-c11-f13-r2-renamed/arbitrary/depth
mkdir -p "$root"
compiler="$repo/build/bin/neboc"

run_source() {
  local name=$1 expected=$2 source=$3 file="$root/$1-renamed.no"
  printf '%s\n' "$source" >"$file"
  "$compiler" check "$file"
  "$compiler" emit-asm "$file" -o "$root/$name.asm"
  TMPDIR="$root" "$compiler" build "$file" -o "$root/$name.elf"
  set +e
  "$root/$name.elf"
  local actual=$?
  set -e
  test "$actual" -eq "$expected"
}

run_source metadata 3 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.rows();}'
run_source indexed 5 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.at(2,1);}'
run_source view 15 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.column(1).renamedView;renamedView.sum();}'
run_source materialize 30 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.transposeView().renamedView;renamedView.contiguous().renamedResult;renamedResult.sum();}'
run_source binary 12 'start(){Matrix<Int>.filled(2,2,5).renamedLeft;Matrix<Int>.filled(2,2,2).renamedRight;renamedLeft.subtract(renamedRight).renamedResult;renamedResult.sum();}'
run_source scale 90 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.scale(3).renamedResult;renamedResult.sum();}'
run_source nbm1 30 'start(){Matrix<Int>.filled(3,2,5).renamedOwner;renamedOwner.serializeNBM1().renamedBytes;renamedBytes.asSlice().renamedSlice;Matrix<Int>.deserializeNBM1(renamedSlice,renamedOwner.serializedSizeNBM1()).renamedResult;renamedResult.sum();}'
run_source parameter 30 '(Int.self)renamedFunction(Matrix<Int>.renamedParameter){renamedParameter.sum().return;}start(){Matrix<Int>.filled(3,2,5).renamedArgument;0.renamedFunction(renamedArgument).return;}'
run_source return 30 '(Matrix<Int>.self)renamedFunction(){Matrix<Int>.filled(3,2,5).renamedLocal;renamedLocal.return;}start(){0.renamedFunction().renamedResult;renamedResult.sum();}'

! rg -q 'selected-surface-cases|arbitrary/depth|renamedOwner|renamedFunction|renamedResult|expected_exit' \
  "$repo/compiler/semantic/structural/legacy_source_verticals.asm" \
  "$repo/compiler/codegen/collections/x86_64/vector_codegen.asm"
