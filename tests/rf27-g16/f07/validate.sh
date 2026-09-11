#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
python3 tests/rf27-g16/f07/multidimensional_oracle.py >/dev/null
for repeat in 1 2 3; do
  for front in 01 02 03 04 05 06; do bash "tests/rf27-g16/f${front}/validate.sh" >/dev/null; done
done
bash tests/rf27-g15/f07/validate.sh >/dev/null
bash tests/rf27-g14/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G16_F07_GREEN oracle=24 repeats=3 contract=green storage=green views=green broadcast=green reductions=green structural=green matrix_integration=green static_elf=yes group=PUBLIC_BOUNDED_NATIVE_GREEN'
