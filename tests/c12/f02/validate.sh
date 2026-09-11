#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/nebo-c12-f02-python-cache"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"

ninja c12-f02-tests build/bin/neboc >/dev/null
build/tests/c12/f02/tensor_i64_storage_test
build/tests/rf27-g16/f01/tensor_contract_test
tests/c12/f01/validate.sh >/dev/null

test -z "$(nm -u build/tests/c12/f02/tensor_i64_storage_test)"
! readelf -lW build/tests/c12/f02/tensor_i64_storage_test | grep -q INTERP
! readelf -dW build/tests/c12/f02/tensor_i64_storage_test | grep -q '(NEEDED)'
test "$(stat -c %s runtime/tensor/tensor_i64_public.inc)" -gt 0
rg -q '^%define NEBO_TENSOR_I64_PUBLIC_MAX_RANK 3$' runtime/tensor/tensor_i64_public.inc
rg -q '^%define NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS 64$' runtime/tensor/tensor_i64_public.inc
rg -q '^%define NEBO_TENSOR_I64_PUBLIC_MAX_BYTES 512$' runtime/tensor/tensor_i64_public.inc
! nm build/obj/tensor_i64_public.o | rg -q 'malloc|calloc|realloc|free'
rg -qxF 'Nebo.NI.Scientific.v1|Tensor|Int|rank=0..3|shape=Tuple.of|dimensions=0..8|elements=64|constructors=zeros,filled,fromBuffer-explicit-copy|storage=fixed-caller-512-owner-generation-v1|function-abi=deferred|target=linux-x86_64-systemv-static' sdk/interfaces/scientific/tensor-int-v1.ni.identity
git diff --check -- build.ninja runtime/tensor/tensor_i64_public.inc runtime/tensor/tensor_i64_public.asm sdk/interfaces/scientific/tensor-int-v1.ni.identity tests/c12/f02
test -z "$(find compiler runtime sdk tests/c12 -type d -name __pycache__ -print -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print)"
printf '%s\n' 'C12_F02_GREEN descriptor=168 dtype=I64 device=CPU rank=0..3 elements=64 payload=512 storage=caller-fixed owner_id=nonzero generation=logical_cleanup failure_atomic=yes hidden_allocation=no'
