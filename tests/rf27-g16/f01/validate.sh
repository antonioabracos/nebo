#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g16-f01-tests >/dev/null
build/tests/rf27-g16/f01/tensor_contract_test
file build/tests/rf27-g16/f01/tensor_contract_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g16/f01/tensor_contract_test)"
! readelf -lW build/tests/rf27-g16/f01/tensor_contract_test | rg -q INTERP
printf '%s\n' 'RF27_G16_F01_GREEN native=12 CPU_only=yes dtypes=Bool_Int64_Float64 rank=0_to_6 elements_max=4096 storage_generation=explicit static_elf=yes'
