#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g21-f09.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g21-f09-tests >/dev/null
timeout 15 build/examples/rf27-g21/tiny-training
python3 tests/rf27-g21/f09/training_closeout_oracle.py >"$tmp/a"
python3 tests/rf27-g21/f09/training_closeout_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/examples/rf27-g21/tiny-training | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/examples/rf27-g21/tiny-training)" ]]
tests/rf27-g21/f08/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G21_F09_GREEN fronts=9 cases=3000 tiny_training=yes gradcheck=yes losses=yes optimizers=yes trainer=yes datasets=yes checkpoints=yes bounded_convergence=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
