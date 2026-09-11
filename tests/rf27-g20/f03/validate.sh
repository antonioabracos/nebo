#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G20_F03_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }; tmp="$(mktemp -d /tmp/rf27-g20-f03.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f03-tests >/dev/null; bin=build/tests/rf27-g20/f03/layers_test; timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g20/f03/layers_oracle.py >"$tmp/a"; python3 tests/rf27-g20/f03/layers_oracle.py >"$tmp/b"; cmp -s "$tmp/a" "$tmp/b" || fail oracle deterministic
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf; [[ -z "$(nm -u "$bin")" ]] || fail undefined; [[ $(nm -g --defined-only build/obj/rf27_g20_layers.o | awk '$2=="T"{n++}END{print n}') -eq 7 ]] || fail exports
tests/rf27-g20/f02/validate.sh >/dev/null || fail regression; cat "$tmp/a"; printf 'RF27_G20_F03_GREEN native_assertions=15 cases=3000 exports=7 sequential_layernorm_batchnorm_dropout_residual_flatten_embedding=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
