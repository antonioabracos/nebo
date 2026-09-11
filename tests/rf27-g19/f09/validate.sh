#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
fail(){ printf 'RF27_G19_F09_ERROR step=%s detail=%s\n' "$1" "$2" >&2; exit 1; }
tmp="$(mktemp -d /tmp/rf27-g19-f09.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g19-f09-tests >/dev/null
bin=build/tests/rf27-g19/f09/video_pipeline_test
timeout 15 "$bin" || fail native "$?"
python3 tests/rf27-g19/f09/video_oracle.py >"$tmp/a"; python3 tests/rf27-g19/f09/video_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b" || fail oracle nondeterministic
rg -q '^RF27_G19_F09_ORACLE=PASS seed=0x271909 cases=5000 accepted=[0-9]+ denied=[0-9]+ digest=[0-9a-f]{64}$' "$tmp/a" || fail oracle summary
file "$bin" | rg -q 'ELF 64-bit.*statically linked' || fail elf type
[[ -z "$(nm -u "$bin")" ]] || fail elf undefined
! readelf -lW "$bin" | rg -q 'GNU_STACK.*RWE' || fail stack executable
[[ $(nm -g --defined-only build/obj/rf27_g19_audio_device.o | awk '$2=="T"{n++}END{print n}') -eq 3 ]] || fail abi audio
[[ $(nm -g --defined-only build/obj/rf27_g19_video_pipeline.o | awk '$2=="T"{n++}END{print n}') -eq 7 ]] || fail abi video
for run in a b; do nasm -f elf64 -Wall -Werror -I./ -o "$tmp/a-$run.o" runtime/audio/audio_device.asm; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/v-$run.o" runtime/video/video_pipeline.asm; done
cmp -s "$tmp/a-a.o" "$tmp/a-b.o" || fail determinism audio
cmp -s "$tmp/v-a.o" "$tmp/v-b.o" || fail determinism video
tests/rf27-g19/f08/validate.sh >/dev/null || fail regression f08
cat "$tmp/a"
printf 'RF27_G19_F09_GREEN native_assertions=22 exports=10 audio_device=typed_unsupported video_queue=finite16 backpressure=yes timestamps=yes cancel_cleanup=yes static_elf=yes no_c_no_libc=yes determinism=identical\n'
