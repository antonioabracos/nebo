#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g21-f06.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g21-f06-tests >/dev/null
timeout 15 build/tests/rf27-g21/f06/trainer_test
python3 tests/rf27-g21/f06/trainer_oracle.py >"$tmp/a"
python3 tests/rf27-g21/f06/trainer_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g21/f06/trainer_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g21/f06/trainer_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g21_trainer.o | awk '$2=="T"{n++}END{print n}') -eq 7 ]]
tests/rf27-g21/f05/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G21_F06_GREEN native_assertions=32 cases=5000 exports=7 early_stop=yes callback_reentry=yes cancellation=yes progress=yes structured_cleanup=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
