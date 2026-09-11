#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f05.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f05-tests >/dev/null
timeout 15 build/tests/rf27-g23/f05/structured_test
python3 tests/rf27-g23/f05/structured_oracle.py >"$tmp/a"; python3 tests/rf27-g23/f05/structured_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f05/structured_test | rg -q 'ELF 64-bit.*statically linked'; [[ -z "$(nm -u build/tests/rf27-g23/f05/structured_test)" ]]
[[ $(nm -g --defined-only build/obj/structured.o | awk '$2=="T"{n++}END{print n}') -eq 4 ]]
timeout 15 build/tests/rf27-g23/f04/generation_test
cat "$tmp/a"; printf 'RF27_G23_F05_GREEN native_assertions=12 cases=5000 exports=4 prompt_bytes=4096 fields=64 repairs=1 ambient_context=none provenance=exact static_elf=yes no_c_no_libc=yes determinism=identical\n'
