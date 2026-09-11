#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f02.XXXXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f02-tests >/dev/null
timeout 15 build/tests/rf27-g23/f02/tokenizer_test
python3 tests/rf27-g23/f02/tokenizer_oracle.py >"$tmp/a"
python3 tests/rf27-g23/f02/tokenizer_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f02/tokenizer_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g23/f02/tokenizer_test)" ]]
[[ $(nm -g --defined-only build/obj/tokenizer.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]]
rg -q '^42544b31000000000100000000000000000100000000000043554b3100000000$' tests/goldens/rf27-g23/f02/tokenizer.btk1.hex
timeout 15 build/examples/rf27-g20/tiny-inference
cat "$tmp/a"
printf 'RF27_G23_F02_GREEN native_assertions=21 cases=5000 exports=6 vocab=256 max_tokens=256 golden=versioned_checksum roundtrip=bit_exact static_elf=yes no_c_no_libc=yes determinism=identical\n'
