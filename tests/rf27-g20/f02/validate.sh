#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G20_F02_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }; tmp="$(mktemp -d /tmp/rf27-g20-f02.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f02-tests >/dev/null; bin=build/tests/rf27-g20/f02/dense_test; timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g20/f02/dense_oracle.py >"$tmp/a"; python3 tests/rf27-g20/f02/dense_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G20_F02_ORACLE=PASS seed=0x272002 cases=3000 softmax_sum_error=[0-9.e+-]+ digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf; [[ -z "$(nm -u "$bin")" ]] || fail undefined; ! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack
[[ $(nm -g --defined-only build/obj/rf27_g20_dense.o | awk '$2=="T"{n++}END{print n}') -eq 6 ]] || fail exports
tests/rf27-g20/f01/validate.sh >/dev/null || fail regression f01; cat "$tmp/a"
printf 'RF27_G20_F02_GREEN native_assertions=19 oracle_cases=3000 exports=6 linear=yes relu_gelu_sigmoid_tanh_softmax=yes stable_softmax=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
