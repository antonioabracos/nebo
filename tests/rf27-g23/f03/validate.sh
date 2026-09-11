#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f03.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f03-tests >/dev/null
timeout 15 build/tests/rf27-g23/f03/tiny_causal_test
python3 tests/rf27-g23/f03/causal_oracle.py >"$tmp/a"
python3 tests/rf27-g23/f03/causal_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f03/tiny_causal_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g23/f03/tiny_causal_test)" ]]
[[ $(nm -g --defined-only build/obj/tiny_causal.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]]
timeout 15 build/tests/rf27-g23/f02/tokenizer_test
cat "$tmp/a"
printf 'RF27_G23_F03_GREEN native_assertions=20 cases=5000 exports=6 vocab=16 dim=8 context=32 layers=1 cache_equivalence=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
