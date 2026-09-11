#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
NEBOC="${NEBOC:-build/bin/neboc}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/nebo-post-rc1-console-XXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT

fail() {
  local step="${1:-unknown}" detail="${2:-unspecified}"
  echo "POST_RC1_CONSOLE_G04_ERROR step=$step detail=$detail" >&2
  exit 1
}

static_elf() {
  local artifact="$1"
  file "$artifact" | grep -Fq 'ELF 64-bit LSB executable, x86-64' || return 1
  file "$artifact" | grep -Fq 'statically linked' || return 1
  ! readelf -lW "$artifact" | grep -q INTERP || return 1
  ! readelf -dW "$artifact" | grep -q NEEDED || return 1
  [[ -z "$(nm -u "$artifact")" ]] || return 1
  readelf -lW "$artifact" | grep GNU_STACK | grep -Fq ' RW '
}

positives=(
  tests/e2e/console-output/fixtures/default.no
  tests/e2e/console-output/fixtures/concat.no
  tests/e2e/console-output/fixtures/named.no
  tests/e2e/console-output/fixtures/newline.no
  tests/post-rc1-coherence/fixtures/console-text.no
  tests/post-rc1-coherence/fixtures/console-int.no
  tests/post-rc1-coherence/fixtures/console-bool.no
  tests/post-rc1-coherence/fixtures/scan-text.no
  tests/post-rc1-coherence/fixtures/scan-console.no
  tests/e2e/console-output/fixtures/red.no
)

positive_count=0
environment_limited_count=0
for source in "${positives[@]}"; do
  id="$(printf '%02d' "$positive_count")"
  "$NEBOC" check "$source" >"$tmp/$id.check.out" 2>"$tmp/$id.check.err" || fail positive "$source:check"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.a.asm" >"$tmp/$id.emit-a.out" 2>"$tmp/$id.emit-a.err" || fail positive "$source:emit-a"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.b.asm" >"$tmp/$id.emit-b.out" 2>"$tmp/$id.emit-b.err" || fail positive "$source:emit-b"
  cmp -s "$tmp/$id.a.asm" "$tmp/$id.b.asm" || fail determinism "$source"
  "$NEBOC" build "$source" -o "$tmp/$id.elf" >"$tmp/$id.build.out" 2>"$tmp/$id.build.err" || fail positive "$source:build"
  [[ ! -s "$tmp/$id.check.out" && ! -s "$tmp/$id.check.err" && ! -s "$tmp/$id.emit-a.out" && ! -s "$tmp/$id.emit-a.err" && ! -s "$tmp/$id.emit-b.out" && ! -s "$tmp/$id.emit-b.err" && ! -s "$tmp/$id.build.out" && ! -s "$tmp/$id.build.err" ]] || fail output "$source"
  static_elf "$tmp/$id.elf" || fail elf "$source"
  if [[ "$source" != *scan-*.no ]]; then
    set +e
    timeout 5 "$tmp/$id.elf" >"$tmp/$id.native.out" 2>"$tmp/$id.native.err"
    rc=$?
    set -e
    case "$rc" in
      0) ;;
      # 128 + NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME (46): the compiler/runtime
      # contract is present, but this headless host cannot provide a console.
      174) environment_limited_count=$((environment_limited_count + 1)) ;;
      *) fail native "$source:exit=$rc" ;;
    esac
    [[ ! -s "$tmp/$id.native.out" && ! -s "$tmp/$id.native.err" ]] || fail native "$source:unexpected-output"
  fi
  positive_count=$((positive_count + 1))
done

negatives=(
  tests/post-rc1-coherence/fixtures/reject-print.no
  tests/post-rc1-coherence/fixtures/reject-unknown-text-method.no
  tests/post-rc1-coherence/fixtures/reject-char-console.no
  tests/post-rc1-coherence/fixtures/reject-console-argument.no
)
declare -A negative_diagnostic=(
  [tests/post-rc1-coherence/fixtures/reject-print.no]=NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN
  [tests/post-rc1-coherence/fixtures/reject-unknown-text-method.no]=NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN
  [tests/post-rc1-coherence/fixtures/reject-char-console.no]=NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN
  [tests/post-rc1-coherence/fixtures/reject-console-argument.no]=NEBO_PARSE_UNEXPECTED_TOKEN
)

negative_count=0
for source in "${negatives[@]}"; do
  id="n$(printf '%02d' "$negative_count")"
  for mode in check emit-asm build; do
    artifact="$tmp/$id.$mode.artifact"
    set +e
    case "$mode" in
      check) "$NEBOC" check "$source" >"$tmp/$id.$mode.out" 2>"$tmp/$id.$mode.err" ;;
      emit-asm) "$NEBOC" emit-asm "$source" -o "$artifact" >"$tmp/$id.$mode.out" 2>"$tmp/$id.$mode.err" ;;
      build) "$NEBOC" build "$source" -o "$artifact" >"$tmp/$id.$mode.out" 2>"$tmp/$id.$mode.err" ;;
    esac
    rc=$?
    set -e
    [[ "$rc" -eq 1 ]] || fail negative "$source:$mode:exit=$rc"
    [[ ! -s "$tmp/$id.$mode.out" && ! -e "$artifact" ]] || fail negative "$source:$mode:residual"
    grep -Fq "${negative_diagnostic[$source]}" "$tmp/$id.$mode.err" || fail negative "$source:$mode:diagnostic"
  done
  cmp -s "$tmp/$id.check.err" "$tmp/$id.emit-asm.err" || fail negative "$source:emit-diagnostic-drift"
  cmp -s "$tmp/$id.check.err" "$tmp/$id.build.err" || fail negative "$source:build-diagnostic-drift"
  negative_count=$((negative_count + 1))
done

for mode in check emit-asm build; do
  case "$mode" in
    check) "$NEBOC" check examples/evolution/g04-text-char-bytes.no >/dev/null ;;
    emit-asm) "$NEBOC" emit-asm examples/evolution/g04-text-char-bytes.no -o "$tmp/g04.asm" >/dev/null ;;
    build) "$NEBOC" build examples/evolution/g04-text-char-bytes.no -o "$tmp/g04.elf" >/dev/null ;;
  esac
done

echo "POST_RC1_CONSOLE_G04_GREEN positives=$positive_count negatives=$negative_count environment_limited=$environment_limited_count print_alias=NO"
