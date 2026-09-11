#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f06.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f06-tests >/dev/null; timeout 15 build/tests/rf27-g23/f06/tools_test
python3 tests/rf27-g23/f06/tools_oracle.py >"$tmp/a";python3 tests/rf27-g23/f06/tools_oracle.py >"$tmp/b";cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f06/tools_test|rg -q 'ELF 64-bit.*statically linked';[[ -z "$(nm -u build/tests/rf27-g23/f06/tools_test)" ]];[[ $(nm -g --defined-only build/obj/tools.o|awk '$2=="T"{n++}END{print n}') -eq 4 ]]
timeout 15 build/tests/rf27-g23/f05/structured_test;cat "$tmp/a";printf 'RF27_G23_F06_GREEN native_assertions=12 cases=5000 exports=4 tools=16 calls=8 args_bytes=4096 deny_default=yes shell=denied network=denied external_effects=0 static_elf=yes no_c_no_libc=yes determinism=identical\n'
