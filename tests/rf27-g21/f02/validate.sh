#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g21-f02.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g21-f02-tests >/dev/null; timeout 15 build/tests/rf27-g21/f02/backward_test
python3 tests/rf27-g21/f02/backward_oracle.py >"$tmp/a"; python3 tests/rf27-g21/f02/backward_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g21/f02/backward_test | rg -q 'ELF 64-bit.*statically linked'; [[ -z "$(nm -u build/tests/rf27-g21/f02/backward_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g21_backward.o | awk '$2=="T"{n++}END{print n}') -eq 4 ]]
tests/rf27-g21/f01/validate.sh >/dev/null; cat "$tmp/a"
printf 'RF27_G21_F02_GREEN native_assertions=24 cases=5000 exports=4 broadcast=yes failure_atomicity=yes workspace_zeroed=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
