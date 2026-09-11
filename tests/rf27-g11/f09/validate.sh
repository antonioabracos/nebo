#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
ninja rf27-g11-f09-tests >/dev/null
tmp_root="$(mktemp -d /tmp/nebo-rf27-g11-f09.XXXXXXXX)"
trap 'rm -rf -- "$tmp_root"' EXIT
build/tests/rf27-g11/f09/csv_dataset_test "$tmp_root"
file build/tests/rf27-g11/f09/csv_dataset_test | grep -q 'statically linked'
readelf -h build/tests/rf27-g11/f09/csv_dataset_test | grep -q 'Type:.*EXEC'
! rg -q 'syscall' runtime/serialization/csv.asm
bash tests/rf27-g11/f05/validate.sh >/dev/null
bash tests/rf27-g11/f06/validate.sh >/dev/null
bash tests/rf27-g10/f03/validate.sh >/dev/null
bash tests/rf27-g10/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G11_F09_GREEN native=28 csv=i64_quoted_crlf missing=explicit failure_atomic=two_pass table_dataset=validated atomic_file=renameat2 static_elf=yes'
