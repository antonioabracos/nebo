#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g17-f07-tests build/bin/neboc >/dev/null
build/tests/rf27-g17/f07/numeric_benchmark_test
report="$(build/bin/neboc bench numeric)"
rg -q '^neboc bench numeric$' <<<"$report"
rg -q 'correctness=pass' <<<"$report"
rg -q 'cpu_features=locally_detected' <<<"$report"
rg -Fq 'toolchain=nasm+ld' <<<"$report"
rg -q 'superiority_claim=no' <<<"$report"
test "$(build/bin/neboc --version)" = 'neboc 1.0.0'
file build/tests/rf27-g17/f07/numeric_benchmark_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g17/f07/numeric_benchmark_test)"
! readelf -lW build/tests/rf27-g17/f07/numeric_benchmark_test | rg -q INTERP
bash tests/rf27-g17/f06/validate.sh >/dev/null
printf '%s\n' 'RF27_G17_F07_GREEN native=12 command=neboc_bench_numeric iterations_max=1000 warmup_max=100 checksum=2080 correctness_before_timing=yes clock=monotonic dispersion=aggregate metadata=versioned superiority_claim=no CLI=neboc_1.0.0'
