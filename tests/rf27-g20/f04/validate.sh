#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f04.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f04-tests >/dev/null; timeout 15 build/tests/rf27-g20/f04/conv_test
python3 tests/rf27-g20/f04/conv_oracle.py >"$tmp/a"; python3 tests/rf27-g20/f04/conv_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g20/f04/conv_test | rg -q 'ELF 64-bit.*statically linked'; [[ -z "$(nm -u build/tests/rf27-g20/f04/conv_test)" ]]; [[ $(nm -g --defined-only build/obj/rf27_g20_conv.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]]
tests/rf27-g20/f03/validate.sh >/dev/null; cat "$tmp/a"; printf 'RF27_G20_F04_GREEN native_assertions=13 cases=2000 exports=6 conv1d_conv2d_pooling_padding=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
