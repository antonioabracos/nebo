#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f07-tests >/dev/null
build/tests/rf27-g14/f07/integration_test
python3 tests/rf27-g14/f07/precision_oracle.py >/dev/null
file build/tests/rf27-g14/f07/integration_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g14/f07/integration_test)"
! readelf -lW build/tests/rf27-g14/f07/integration_test | rg -q INTERP
for f in 01 02 03 04 05 06; do bash "tests/rf27-g14/f${f}/validate.sh" >/dev/null; done
printf '%s\n' 'RF27_G14_F07_GREEN native_integration=6 oracle_vectors=5 simpson=even_steps_2_to_4096 scalar_math=green transcendental=green vector=green statistics=green distributions=green precision=bounded benchmark=methodology_only static_elf=yes group=PUBLIC_BOUNDED_NATIVE_GREEN'
