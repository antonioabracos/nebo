#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g25-f01-tests >/dev/null
build/tests/rf27-g25/f01/effects_contract_test
python3 tests/rf27-g25/f01/effects_oracle.py
file build/tests/rf27-g25/f01/effects_contract_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f01/effects_contract_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f01/effects_contract_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f01/effects_contract_test
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F01_GREEN native_assertions=25 atoms=14 lattice=boolean union_meet_subtyping_call=yes unknown_hidden_rejected=yes deterministic=yes static_elf=yes no_c_no_libc=yes'
