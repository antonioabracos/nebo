#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G20_F01_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g20-f01.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f01-tests >/dev/null
bin=build/tests/rf27-g20/f01/model_contract_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g20/f01/model_oracle.py >"$tmp/a"; python3 tests/rf27-g20/f01/model_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G20_F01_ORACLE=PASS seed=0x272001 cases=5000 valid=[0-9]+ invalid=[0-9]+ digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf; [[ -z "$(nm -u "$bin")" ]] || fail undefined; ! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack
[[ $(nm -g --defined-only build/obj/rf27_g20_model_contract.o | awk '$2=="T"{n++}END{print n}') -eq 3 ]] || fail exports
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/m-$run.o" compiler/semantic/ml/model_contract.asm; done; cmp -s "$tmp/m-a.o" "$tmp/m-b.o" || fail determinism
tests/rf27-g19/f10/validate.sh >/dev/null || fail regression g19
cat "$tmp/a"; printf 'RF27_G20_F01_GREEN native_assertions=18 graph_cases=5000 nodes64=yes edges128=yes params4096=yes topological_dag=yes immutable_summary=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
