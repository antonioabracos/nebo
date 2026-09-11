#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F08_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f08.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f08-tests >/dev/null
bin=build/tests/rf27-g19/f08/pcm_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g19/f08/pcm_oracle.py >"$tmp/a"; python3 tests/rf27-g19/f08/pcm_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F08_ORACLE=PASS seed=0x271908 cases=5000 digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
nm -g --defined-only build/obj/rf27_g19_pcm.o | awk '$2=="T"{print $3}' | sort >"$tmp/exports"
printf '%s\n' nebo_pcm_init nebo_pcm_duration_us nebo_pcm_mix_into nebo_pcm_resample_linear_into | sort >"$tmp/expected"
cmp -s "$tmp/exports" "$tmp/expected" || fail abi exports
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/pcm-$run.o" runtime/audio/pcm.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/test-$run.o" tests/rf27-g19/f08/pcm_test.asm; ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$tmp/test-$run" "$tmp/test-$run.o" "$tmp/pcm-$run.o"; done
cmp -s "$tmp/pcm-a.o" "$tmp/pcm-b.o" || fail determinism object
cmp -s "$tmp/test-a" "$tmp/test-b" || fail determinism elf
timeout 15 "$tmp/test-a" || fail determinism run
tests/rf27-g19/f07/validate.sh >/dev/null || fail regression f07
cat "$tmp/a"
printf 'RF27_G19_F08_GREEN native_assertions=22 exports=4 s16le=yes mono_stereo=yes mix_saturating=yes resample_linear=yes offline=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
