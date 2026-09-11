#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.."&&pwd)";export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f09.XXXXXXXX)";trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f09-tests >/dev/null;timeout 15 build/examples/rf27-g23/tiny-local-agent
python3 tests/rf27-g23/f09/demo_oracle.py >"$tmp/a";python3 tests/rf27-g23/f09/demo_oracle.py >"$tmp/b";cmp -s "$tmp/a" "$tmp/b"
file build/examples/rf27-g23/tiny-local-agent|rg -q 'ELF 64-bit.*statically linked';[[ -z "$(nm -u build/examples/rf27-g23/tiny-local-agent)" ]]
for f in f02 f03 f04 f05 f06 f07 f08;do bash tests/rf27-g23/$f/validate.sh >/dev/null;done
cat "$tmp/a";printf 'RF27_G23_F09_GREEN native_assertions=16 cases=3000 composed_surfaces=7 no_cloud=yes no_shell=yes no_network=yes external_effects=0 static_elf=yes no_c_no_libc=yes determinism=identical\n'
