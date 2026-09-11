#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F05_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f05.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f05-tests >/dev/null
bin=build/tests/rf27-g19/f05/bmp_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g19/f05/bmp_oracle.py >"$tmp/a"; python3 tests/rf27-g19/f05/bmp_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F05_ORACLE=PASS seed=0x271905 cases=5000 accepted=[0-9]+ rejected=[0-9]+ digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
golden=$(tr -d '\n' < tests/goldens/rf27-g19/f05/bmp-2x2-v1.hex)
[[ ${#golden} -eq 140 ]] || fail golden length
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
! readelf -lW "$bin" | rg -q INTERP || fail elf interp
! readelf -dW "$bin" 2>/dev/null | rg -q NEEDED || fail elf needed
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
readelf -lW "$bin" | rg -q 'GNU_STACK.*RW[[:space:]]' || fail stack missing
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
nm -g --defined-only build/obj/rf27_g19_bmp.o | awk '$2=="T"{print $3}' | sort >"$tmp/exports"
printf '%s\n' nebo_bmp_inspect nebo_bmp_decode nebo_bmp_encode | sort >"$tmp/expected"
cmp -s "$tmp/exports" "$tmp/expected" || fail abi exports
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/bmp-$run.o" runtime/image/bmp.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/test-$run.o" tests/rf27-g19/f05/bmp_test.asm; ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$tmp/test-$run" "$tmp/test-$run.o" "$tmp/bmp-$run.o"; done
cmp -s "$tmp/bmp-a.o" "$tmp/bmp-b.o" || fail determinism object
cmp -s "$tmp/test-a" "$tmp/test-b" || fail determinism elf
timeout 15 "$tmp/test-a" || fail determinism run
tests/rf27-g19/f04/validate.sh >/dev/null || fail regression f04
cat "$tmp/a"
printf 'RF27_G19_F05_GREEN native_assertions=29 exports=3 bmp3=yes bi_rgb_24_32=yes golden=bit_exact hostile_cases=5000 alias_rejection=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
