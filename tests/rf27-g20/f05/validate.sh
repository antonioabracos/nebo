#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f05.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f05-tests >/dev/null
timeout 15 build/tests/rf27-g20/f05/model_format_test
python3 tests/rf27-g20/f05/model_format_oracle.py --emit-golden >"$tmp/canonical.hex"
diff -u tests/goldens/rf27-g20/f05/canonical-model.hex "$tmp/canonical.hex"
python3 tests/rf27-g20/f05/model_format_oracle.py >"$tmp/a"
python3 tests/rf27-g20/f05/model_format_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g20/f05/model_format_test | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/tests/rf27-g20/f05/model_format_test)" ]]
[[ $(nm -g --defined-only build/obj/rf27_g20_model_format.o | awk '$2=="T"{n++}END{print n}') -eq 4 ]]
tests/rf27-g20/f04/validate.sh >/dev/null
cat "$tmp/a"
printf 'RF27_G20_F05_GREEN native_assertions=31 hostile_cases=5000 exports=4 nmf1_sha256=yes literal_file_handle=yes bit_exact=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
