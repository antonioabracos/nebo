#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F04_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f04.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f04-tests >/dev/null
bin=build/tests/rf27-g19/f04/transform_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g19/f04/transform_oracle.py >"$tmp/a"; python3 tests/rf27-g19/f04/transform_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F04_ORACLE=PASS seed=0x271904 cases=3000 digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
! readelf -lW "$bin" | rg -q INTERP || fail elf interp
! readelf -dW "$bin" 2>/dev/null | rg -q NEEDED || fail elf needed
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
readelf -lW "$bin" | rg -q 'GNU_STACK.*RW[[:space:]]' || fail stack missing
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
nm -g --defined-only build/obj/rf27_g19_image_transform.o | awk '$2=="T"{print $3}' | sort >"$tmp/exports"
printf '%s\n' nebo_image_crop_into nebo_image_resize_into nebo_image_flip_horizontal_into nebo_image_flip_vertical_into nebo_image_rotate90_into nebo_image_convert_into nebo_image_composite_over | sort >"$tmp/expected"
cmp -s "$tmp/exports" "$tmp/expected" || fail abi exports
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/t-$run.o" runtime/image/image_transform.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/i-$run.o" runtime/image/image.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/test-$run.o" tests/rf27-g19/f04/transform_test.asm; ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$tmp/test-$run" "$tmp/test-$run.o" "$tmp/t-$run.o" "$tmp/i-$run.o"; done
cmp -s "$tmp/t-a.o" "$tmp/t-b.o" || fail determinism object
cmp -s "$tmp/test-a" "$tmp/test-b" || fail determinism elf
timeout 15 "$tmp/test-a" || fail determinism run
tests/rf27-g19/f03/validate.sh >/dev/null || fail regression f03
cat "$tmp/a"
printf 'RF27_G19_F04_GREEN native_assertions=18 exports=7 nearest=yes bilinear=yes crop_flip_rotate_convert_composite=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
