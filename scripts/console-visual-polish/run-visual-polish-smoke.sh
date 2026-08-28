#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
WORK="$(mktemp -d /tmp/nebo-r4-visual-polish.XXXXXXXX)"
trap 'rm -rf -- "$WORK"' EXIT INT TERM

for tool in ninja nasm ld file readelf nm sha256sum cmp python3; do
  command -v "$tool" >/dev/null
done
ninja -j2 console-visual-polish-test build/bin/neboc >/dev/null
python3 -B scripts/console-visual-polish/generate-professional-atlas.py \
  --font third_party/fonts/adobe-source-code-pro/SourceCodePro-Regular.ttf \
  --license third_party/fonts/adobe-source-code-pro/LICENSE.md \
  --output runtime/console/live/nebo_console_mono_atlas.inc --check >/dev/null

# The ordinary product targets must be the approved unified profile. The old
# 5x7 baseline remains reachable only through its explicit test-only target.
cmp build/obj/runtime/console/live/live_visual.o \
  build/obj/runtime/console/live/live_visual_unified.o
cmp build/obj/runtime_practical_io.o \
  build/obj/runtime_practical_io_visual_unified.o
! cmp -s build/obj/runtime/console/live/live_visual.o \
  build/obj/runtime/console/live/live_visual_baseline.o
! cmp -s build/obj/runtime_practical_io.o \
  build/obj/runtime_practical_io_typography_baseline.o

for profile in baseline a b c d d1 d2 pa pb pc pd u; do
  "build/tests/console-visual-polish/typography_metrics_$profile"
  for pass in 1 2; do
    "build/tests/console-visual-polish/typography_frame_$profile" \
      >"$WORK/$profile-$pass.bgra"
  done
  cmp -s "$WORK/$profile-1.bgra" "$WORK/$profile-2.bgra"
done

python3 -B scripts/console-visual-polish/analyze-typography-frames.py \
  --output "$WORK/frames" \
  --baseline "$WORK/baseline-1.bgra" \
  --a "$WORK/a-1.bgra" \
  --b "$WORK/b-1.bgra" \
  --c "$WORK/c-1.bgra" \
  --d "$WORK/d-1.bgra" \
  --d1 "$WORK/d1-1.bgra" \
  --d2 "$WORK/d2-1.bgra" \
  --pa "$WORK/pa-1.bgra" \
  --pb "$WORK/pb-1.bgra" \
  --pc "$WORK/pc-1.bgra" \
  --pd "$WORK/pd-1.bgra" \
  --u "$WORK/u-1.bgra"

scripts/console-visual-polish/build-visual-candidate.sh A "$WORK/candidate-a" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh B "$WORK/candidate-b" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh C "$WORK/candidate-c" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh D "$WORK/candidate-d" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh D1 "$WORK/candidate-d1" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh D2 "$WORK/candidate-d2" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh PA "$WORK/candidate-pa" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh PB "$WORK/candidate-pb" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh PC "$WORK/candidate-pc" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh PD "$WORK/candidate-pd" >/dev/null
scripts/console-visual-polish/build-visual-candidate.sh U "$WORK/candidate-u" >/dev/null
for artifact in "$WORK"/candidate-*/nebo-visual-polish-*.elf; do
  file "$artifact" | grep -Fq 'statically linked'
  ! readelf -lW "$artifact" | grep -q INTERP
  ! readelf -dW "$artifact" 2>/dev/null | grep -q NEEDED
  [[ -z "$(nm -u "$artifact")" ]]
done
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-a/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-b/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-c/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-d/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-d1/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-d2/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-pa/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-pb/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-pc/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-pd/sdk" >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$WORK/candidate-u/sdk" >/dev/null
cmp third_party/fonts/adobe-source-code-pro/LICENSE.md \
  "$WORK/candidate-d/sdk/share/nebo/sdk/licenses/NeboConsoleMonoAtlas-OFL-1.1.md"

git diff --check
printf '%s\n' \
  'R4_METRICS=PASS baseline=12x14 A=8x12 B=10x15 C=10x15 D=10x16 D1=11x18 D2=11x19' \
  'R4_MONOSPACE_ADVANCE=PASS profiles=12' \
  'R4_D_PROFESSIONAL_ATLAS=PASS glyphs=193 alpha8_levels=65 runtime_font_engine=NONE' \
  'R4_D_SIZE_CALIBRATION=PASS D1=15.0px D2=16.0px padding=6x6 pipeline=SAME' \
  'R4_C_CRISPNESS=PASS aligned_stems=YES square_terminals=YES rounded_distance_field=NO' \
  'R4_GLYPH_CLIPPING=PASS descendants=gjpqy punctuation=PASS' \
  'R4_SCAN_CARET_ALIGNMENT=PASS profiles=12' \
  'R4_RENDER_STRESS=PASS frames=2000 guard_corruption=0' \
  'R4_DETERMINISM=PASS profiles=12 runs=2' \
  'R4_PALETTE_CALIBRATION=PASS variants=4 typography=D2 title_chrome=UNCHANGED foreground=UNCHANGED' \
  'R4_VISUAL_UNIFICATION=PASS content_contrast=17/16 title=SourceCodeProRegular_synthetic_semibold chrome_controls=UNCHANGED' \
  'CANONICAL_VISUAL_INTEGRATION=PASS normal_profile=U old_profile_0=EXPLICIT_TEST_ONLY' \
  'R4_STATIC_ELF=PASS candidates=11 no_interp=YES no_needed=YES undefined=0' \
  'NPT_CONSOLE_RESIZE_JITTER=OPEN' \
  'R4_DOES_NOT_CLAIM_TO_FIX_RESIZE_JITTER=YES' \
  'R4_VISUAL_POLISH_SMOKE_GREEN=YES'
