#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F07_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f07.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f07-tests >/dev/null
bin=build/tests/rf27-g19/f07/image_io_canvas_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g19/f07/image_canvas_oracle.py >"$tmp/a"; python3 tests/rf27-g19/f07/image_canvas_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F07_ORACLE=PASS seed=0x271907 cases=4000 digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
! readelf -lW "$bin" | rg -q INTERP || fail elf interp
! readelf -dW "$bin" 2>/dev/null | rg -q NEEDED || fail elf needed
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
printf '%s\n' nebo_image_load nebo_image_save | sort >"$tmp/expected-io"
nm -g --defined-only build/obj/rf27_g19_image_io.o | awk '$2=="T"{print $3}' | sort >"$tmp/io"
cmp -s "$tmp/io" "$tmp/expected-io" || fail abi image_io
[[ "$(nm -g --defined-only build/obj/rf27_g19_canvas_image.o | awk '$2=="T"{print $3}')" = nebo_canvas_image ]] || fail abi canvas
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/io-$run.o" runtime/image/image_io.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/ci-$run.o" runtime/canvas/canvas_image.asm; done
cmp -s "$tmp/io-a.o" "$tmp/io-b.o" || fail determinism io
cmp -s "$tmp/ci-a.o" "$tmp/ci-b.o" || fail determinism canvas
tests/rf27-g19/f05/validate.sh >/dev/null || fail regression f05
cat "$tmp/a"
printf 'RF27_G19_F07_GREEN native_assertions=18 exports=3 bmp_load_save=yes literal_file=yes canvas_copy=yes premultiplied=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
