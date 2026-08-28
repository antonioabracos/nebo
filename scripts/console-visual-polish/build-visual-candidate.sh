#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
profile="${1:-}"
output="${2:-}"
case "$profile" in
  A|a) profile=A; runtime=build/obj/runtime_practical_io_typography_a.o ;;
  B|b) profile=B; runtime=build/obj/runtime_practical_io_typography_b.o ;;
  C|c) profile=C; runtime=build/obj/runtime_practical_io_typography_c.o ;;
  D|d) profile=D; runtime=build/obj/runtime_practical_io_typography_d.o ;;
  D1|d1) profile=D1; runtime=build/obj/runtime_practical_io_typography_d1.o ;;
  D2|d2) profile=D2; runtime=build/obj/runtime_practical_io_typography_d2.o ;;
  PA|pa) profile=PA; runtime=build/obj/runtime_practical_io_palette_a.o ;;
  PB|pb) profile=PB; runtime=build/obj/runtime_practical_io_palette_b.o ;;
  PC|pc) profile=PC; runtime=build/obj/runtime_practical_io_palette_c.o ;;
  PD|pd) profile=PD; runtime=build/obj/runtime_practical_io_palette_d.o ;;
  U|u) profile=U; runtime=build/obj/runtime_practical_io_visual_unified.o ;;
  *) printf 'usage: %s A|B|C|D|D1|D2|PA|PB|PC|PD|U OUTPUT-DIRECTORY\n' "$0" >&2; exit 64 ;;
esac
[[ -n "$output" && ! -e "$output" ]] || { printf 'candidate output must not exist\n' >&2; exit 65; }

ninja -j2 build/bin/neboc "$runtime" >/dev/null
shadow="$(mktemp -d /tmp/nebo-r4-sdk-shadow.XXXXXXXX)"
trap 'rm -rf -- "$shadow"' EXIT INT TERM
mkdir -p "$shadow/build/bin" "$shadow/build/obj" "$output"
cp build/bin/neboc "$shadow/build/bin/neboc"
cp build/obj/runtime_core.o "$shadow/build/obj/runtime_core.o"
cp "$runtime" "$shadow/build/obj/runtime_practical_io.o"
for owner in compiler docs examples scripts sdk version; do
  ln -s "$ROOT/$owner" "$shadow/$owner"
done
python3 -B compiler/sdk/sdk_builder.py build \
  --repo "$shadow" --neboc "$shadow/build/bin/neboc" \
  --output "$output/sdk" --profile sdk >/dev/null
python3 -B compiler/sdk/sdk_builder.py verify "$output/sdk" >/dev/null
"$output/sdk/bin/neboc" build tests/console-visual-polish/fixtures/visual-polish-scan.no \
  -o "$output/nebo-visual-polish-$profile.elf"

artifact="$output/nebo-visual-polish-$profile.elf"
file "$artifact" | grep -Fq 'ELF 64-bit LSB executable, x86-64'
file "$artifact" | grep -Fq 'statically linked'
! readelf -lW "$artifact" | grep -q INTERP
! readelf -dW "$artifact" 2>/dev/null | grep -q NEEDED
[[ -z "$(nm -u "$artifact")" ]]
{
  printf 'PROFILE=%s\n' "$profile"
  printf 'COMPILER_VERSION=%s\n' "$("$output/sdk/bin/neboc" --version)"
  sha256sum "$output/sdk/bin/neboc" "$output/sdk/obj/runtime_practical_io.o" \
    "$output/sdk/MANIFEST.json" "$artifact"
} >"$output/CANDIDATE.txt"
cat "$output/CANDIDATE.txt"
