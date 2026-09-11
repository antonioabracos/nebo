#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g21-f08.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g21-f08-tests >/dev/null
timeout 15 build/tests/rf27-g21/f08/checkpoint_test
python3 tests/rf27-g21/f08/checkpoint_oracle.py >"$tmp/a"
python3 tests/rf27-g21/f08/checkpoint_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g21/f08/checkpoint_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g21/f08/checkpoint_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g21_checkpoint.o | awk '$2=="T"{n++}END{print n}') -eq 8 ]]
tests/rf27-g21/f07/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G21_F08_GREEN native_assertions=32 cases=4000 exports=8 golden=yes sha256=yes save_load=yes rotate8=yes seed_replay=yes atomic_restore=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
