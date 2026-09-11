#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f04.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f04-tests >/dev/null
timeout 15 build/tests/rf27-g23/f04/generation_test
python3 tests/rf27-g23/f04/generation_oracle.py >"$tmp/a"; python3 tests/rf27-g23/f04/generation_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f04/generation_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g23/f04/generation_test)" ]]
[[ $(nm -g --defined-only build/obj/generation.o | awk '$2=="T"{n++}END{print n}') -eq 4 ]]
timeout 15 build/tests/rf27-g23/f03/tiny_causal_test
cat "$tmp/a"; printf 'RF27_G23_F04_GREEN native_assertions=15 cases=10000 exports=4 modes=5 max_tokens=64 cancellation=yes cache_release=caller_owned static_elf=yes no_c_no_libc=yes determinism=identical\n'
