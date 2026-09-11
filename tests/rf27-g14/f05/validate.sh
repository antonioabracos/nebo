#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f05-tests >/dev/null
build/tests/rf27-g14/f05/statistics_test
file build/tests/rf27-g14/f05/statistics_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g14/f05/statistics_test)"
! readelf -lW build/tests/rf27-g14/f05/statistics_test | rg -q INTERP
bash tests/rf27-g14/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G14_F05_GREEN native=20 int_sum=checked float_sum=kahan mean=explicit variance=population+sample quantile=linear_type7 workspace=caller median=yes correlation=pearson zero_variance=rejected count_max=4096 static_elf=yes'
