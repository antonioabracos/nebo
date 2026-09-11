#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g10-f08-tests >/dev/null
build/tests/rf27-g10/f08/file_dataset_bridge_test
file build/tests/rf27-g10/f08/file_dataset_bridge_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g10/f08/file_dataset_bridge_test)"
bash tests/rf27-g11/f09/validate.sh >/dev/null
bash tests/rf27-g10/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F08_GREEN native=16 bridge=FileCapability+Dataset file_roundtrip=CSV finite_scan=yes row_byte_limits=explicit generation=checked capability=read failure_atomic=yes storage_engine=no static_elf=yes'
