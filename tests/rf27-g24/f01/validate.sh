#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f01-tests >/dev/null
build/tests/rf27-g24/f01/tooling_contract_test
python3 tests/rf27-g24/f01/contract_oracle.py
file build/tests/rf27-g24/f01/tooling_contract_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f01/tooling_contract_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f01/tooling_contract_test)"
rg -q 'NEBO_TOOLING_REQUIRED_FLAGS[[:space:]]+63' compiler/tooling/tooling_contract.inc
rg -q 'NEBO_TOOLING_MAX_WORKSPACE_BYTES 1048576' compiler/tooling/tooling_contract.inc
printf '%s\n' 'RF27_G24_F01_GREEN native_assertions=20 property_cases=10000 parser=shared typechecker=shared spans=canonical diagnostics=stable workspace=caller_owned deterministic=yes static_elf=yes no_c_no_libc=yes'
