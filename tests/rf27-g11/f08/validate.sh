#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f08-tests >/dev/null
build/tests/rf27-g11/f08/json_test
file build/tests/rf27-g11/f08/json_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f08/json_test | grep -q 'Type:.*EXEC'
! rg -q 'syscall' runtime/serialization/json.asm
bash tests/rf27-g11/f07/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F08_GREEN native=16 utf8=strict grammar=bounded keys=sorted_unique numbers=finite_308 depth_entries=budgeted canonical=compact static_elf=yes'
