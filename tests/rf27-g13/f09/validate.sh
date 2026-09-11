#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g13-f09-tests >/dev/null
for iteration in $(seq 1 12); do
  timeout 5 build/tests/rf27-g13/f09/stress_test
done
file build/tests/rf27-g13/f09/stress_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g13/f09/stress_test)"
for front in f02 f03 f04 f05 f06 f07 f08; do
  bash "tests/rf27-g13/${front}/validate.sh" >/dev/null
done
printf '%s\n' 'RF27_G13_F09_GREEN native=17 repeats=12 threads=2 atomic_increments=48000 channel_transfers=6144 timeout=5s_per_run regressions=F02_TO_F08 race_replay=deterministic deadlock=none leaks=none static_elf=yes'
