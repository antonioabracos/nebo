#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
for front in 01 02 03 04 05 06; do
  bash "tests/rf27-g15/f${front}/validate.sh" >/dev/null
done
python3 tests/rf27-g15/f07/pathological_oracle.py >/dev/null
for pass in 1 2 3; do
  bash tests/rf27-g15/f04/validate.sh >/dev/null
  bash tests/rf27-g15/f05/validate.sh >/dev/null
  bash tests/rf27-g15/f06/validate.sh >/dev/null
done
bash tests/rf27-g14/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G15_F07_GREEN native_fronts=6 oracle_vectors=19 repeats=3 views=green elementwise=green matmul=green LU=green QR=green Cholesky=green conditioning=green precision=bounded benchmark=methodology_only static_elf=yes group=PUBLIC_BOUNDED_NATIVE_GREEN'
