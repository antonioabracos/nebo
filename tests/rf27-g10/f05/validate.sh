#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g10-f05
build/tests/rf27-g10/f05/dataset_test
bash tests/rf27-g10/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F05_GREEN native=6 dataset=64/8 partitions=1..8 rows=256 bytes=16384 operations=construct_validate_partition_scan_collect budgets=explicit schema=identity finite=yes failure_atomic=yes external_g11=yes f04=yes'
