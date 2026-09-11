#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f06-tests >/dev/null
build/tests/rf27-g14/f06/distributions_test
file build/tests/rf27-g14/f06/distributions_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g14/f06/distributions_test)"
! readelf -lW build/tests/rf27-g14/f06/distributions_test | rg -q INTERP
bash tests/rf27-g14/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G14_F06_GREEN native=22 prng=explicit_splitmix64 uniform=53bit_unbiased_range normal=box_muller_v1 bernoulli=validated categorical=finite_nonnegative shuffle=fisher_yates sample=without_replacement count_max=4096 deterministic_seed=yes static_elf=yes'
