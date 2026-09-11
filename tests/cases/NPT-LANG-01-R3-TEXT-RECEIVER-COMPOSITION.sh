#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TZ=UTC TERM=dumb

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo"
NEBOC="${NEBOC:-build/bin/neboc}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/npt-lang-01-r3.XXXXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT

static_elf() {
  local artifact="$1"
  file "$artifact" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$artifact" | rg -q INTERP
  ! readelf -dW "$artifact" 2>/dev/null | rg -q NEEDED
  [[ -z "$(nm -u "$artifact")" ]]
  readelf -lW "$artifact" | rg -q 'GNU_STACK.*RW[[:space:]]'
  ! readelf -lW "$artifact" | rg -q 'GNU_STACK.*RWE'
}

cases=0
for source in \
  tests/rf27-aud002/positive/text-binding-constructor-console.no \
  tests/rf27-aud002/positive/text-constructor-binding-console.no
do
  id="case-$cases"
  "$NEBOC" check "$source" >"$tmp/$id.check.out" 2>"$tmp/$id.check.err"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.a.asm" >"$tmp/$id.emit-a.out" 2>"$tmp/$id.emit-a.err"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.b.asm" >"$tmp/$id.emit-b.out" 2>"$tmp/$id.emit-b.err"
  cmp -s "$tmp/$id.a.asm" "$tmp/$id.b.asm"
  "$NEBOC" build "$source" -o "$tmp/$id.elf" >"$tmp/$id.build.out" 2>"$tmp/$id.build.err"
  for stream in check.out check.err emit-a.out emit-a.err emit-b.out emit-b.err build.out build.err; do
    [[ ! -s "$tmp/$id.$stream" ]]
  done
  static_elf "$tmp/$id.elf"
  [[ "$(rg -c '^[[:space:]]+call nebo_runtime_console_publish_text$' "$tmp/$id.a.asm")" == 2 ]]
  cases=$((cases + 1))
done

[[ "$cases" == 2 ]]
printf 'NPT_LANG_01_R3_TEXT_RECEIVER_COMPOSITION_GREEN cases=2 modes=check_emit_build deterministic=yes static=yes\n'
