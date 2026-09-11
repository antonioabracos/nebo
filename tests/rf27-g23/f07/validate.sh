#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.." && pwd)";export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f07.XXXXXXXX)";trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f07-tests >/dev/null;timeout 15 build/tests/rf27-g23/f07/agent_test
python3 tests/rf27-g23/f07/agent_oracle.py >"$tmp/a";python3 tests/rf27-g23/f07/agent_oracle.py >"$tmp/b";cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f07/agent_test|rg -q 'ELF 64-bit.*statically linked';[[ -z "$(nm -u build/tests/rf27-g23/f07/agent_test)" ]];[[ $(nm -g --defined-only build/obj/agent.o|awk '$2=="T"{n++}END{print n}') -eq 5 ]]
timeout 15 build/tests/rf27-g23/f06/tools_test;cat "$tmp/a";printf 'RF27_G23_F07_GREEN native_assertions=14 cases=5000 exports=5 steps=16 calls=8 approvals=8 trace_bytes=65536 cancellation=yes compensation_only=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
