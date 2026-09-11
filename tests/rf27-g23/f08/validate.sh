#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.."&&pwd)";export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f08.XXXXXXXX)";trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g23-f08-tests >/dev/null;timeout 15 build/tests/rf27-g23/f08/evaluation_test
python3 tests/rf27-g23/f08/evaluation_oracle.py >"$tmp/a";python3 tests/rf27-g23/f08/evaluation_oracle.py >"$tmp/b";cmp -s "$tmp/a" "$tmp/b"
file build/tests/rf27-g23/f08/evaluation_test|rg -q 'ELF 64-bit.*statically linked';[[ -z "$(nm -u build/tests/rf27-g23/f08/evaluation_test)" ]];[[ $(nm -g --defined-only build/obj/evaluation.o|awk '$2=="T"{n++}END{print n}') -eq 5 ]]
timeout 15 build/tests/rf27-g23/f07/agent_test;cat "$tmp/a";printf 'RF27_G23_F08_GREEN native_assertions=11 cases=5000 exports=5 suite_cases=256 trace_bytes=65536 provenance=complete secret_trace=denied bypass=denied static_elf=yes no_c_no_libc=yes determinism=identical\n'
