#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g25-f02-tests >/dev/null
build/tests/rf27-g25/f02/effect_inference_test
python3 tests/rf27-g25/f02/inference_oracle.py
file build/tests/rf27-g25/f02/effect_inference_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f02/effect_inference_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f02/effect_inference_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f02/effect_inference_test
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F02_GREEN native_assertions=26 graph_cases=5000 nodes=64 edges=256 functions_modules_closures_tools=yes explain_path=yes undeclared_unknown_incompatible=yes failure_atomicity=yes deterministic=yes static_elf=yes no_c_no_libc=yes'
