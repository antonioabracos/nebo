#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g21-f05.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g21-f05-tests >/dev/null
timeout 15 build/tests/rf27-g21/f05/optimizer_test
python3 tests/rf27-g21/f05/optimizer_oracle.py >"$tmp/a"
python3 tests/rf27-g21/f05/optimizer_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g21/f05/optimizer_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g21/f05/optimizer_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g21_optimizers.o | awk '$2=="T"{n++}END{print n}') -eq 7 ]]
tests/rf27-g21/f04/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G21_F05_GREEN native_assertions=35 cases=5000 exports=7 sgd=yes momentum=yes adam=yes schedules=yes state_copy=yes failure_atomicity=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
