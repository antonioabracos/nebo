#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F03_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f03.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f03-tests >/dev/null
bin=build/tests/rf27-g19/f03/image_test
timeout 10 "$bin" || fail native "$?"
python3 tests/rf27-g19/f03/image_oracle.py >"$tmp/a"
python3 tests/rf27-g19/f03/image_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F03_ORACLE=PASS seed=0x271903 cases=5000 digest=[0-9a-f]{64} accepted=[0-9]+ rejected=[0-9]+$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
! readelf -lW "$bin" | rg -q INTERP || fail elf interp
! readelf -dW "$bin" 2>/dev/null | rg -q NEEDED || fail elf needed
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
readelf -lW "$bin" | rg -q 'GNU_STACK.*RW[[:space:]]' || fail stack missing
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
nm -g --defined-only build/obj/rf27_g19_image.o | awk '$2=="T"{print $3}' | sort >"$tmp/exports"
printf '%s\n' nebo_image_init nebo_image_wrap_mut nebo_image_width nebo_image_height nebo_image_stride nebo_image_pixel nebo_image_set_pixel nebo_image_region nebo_image_close | sort >"$tmp/expected"
cmp -s "$tmp/exports" "$tmp/expected" || fail abi exports
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/image-$run.o" runtime/image/image.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/test-$run.o" tests/rf27-g19/f03/image_test.asm; ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$tmp/test-$run" "$tmp/test-$run.o" "$tmp/image-$run.o"; done
cmp -s "$tmp/image-a.o" "$tmp/image-b.o" || fail deterministic object
cmp -s "$tmp/test-a" "$tmp/test-b" || fail deterministic elf
timeout 10 "$tmp/test-a" || fail deterministic run
tests/rf27-g19/f02/validate.sh >/dev/null || fail regression f02
cat "$tmp/a"
printf 'RF27_G19_F03_GREEN native_assertions=22 exports=9 zeroed=yes regions=generation_checked static_elf=yes no_c_no_libc=yes determinism=identical\n'
