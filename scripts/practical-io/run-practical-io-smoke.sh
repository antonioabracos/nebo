#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
NEBOC="${NEBOC:-$ROOT/build/bin/neboc}"
DRIVER="$ROOT/build/tests/practical-io/x11_event_driver"
FIXTURE_ROOT="$ROOT/tests/practical-io/fixtures"
WORK="$(mktemp -d /tmp/nebo-practical-io-smoke.XXXXXXXX)"
CURRENT_PID=
CURRENT_XID=
PIO_SOCKET=
PIO_COOKIE=

fail() {
  printf 'PRACTICAL_IO_SMOKE_ERROR step=%s detail=%s\n' "${1:-unknown}" "${2:-unspecified}" >&2
  exit 1
}

cleanup() {
  if [[ -n "$CURRENT_XID" && -n "$PIO_SOCKET" && -n "$PIO_COOKIE" ]]; then
    "$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" c >/dev/null 2>&1 || true
  fi
  if [[ -n "$CURRENT_PID" ]]; then
    wait "$CURRENT_PID" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$WORK"
}
trap cleanup EXIT INT TERM

for tool in "$NEBOC" nasm ld ninja file readelf nm cmp sha256sum awk sed grep timeout xwininfo import convert; do
  if [[ "$tool" == */* ]]; then
    [[ -x "$tool" ]] || fail preflight "missing executable:$tool"
  else
    command -v "$tool" >/dev/null || fail preflight "missing tool:$tool"
  fi
done

ninja -j2 neboc build/tests/practical-io/x11_event_driver >/dev/null
mkdir -p "$WORK/src" "$WORK/build" "$WORK/live"
cp "$FIXTURE_ROOT"/*.no "$WORK/src/"

static_elf() {
  local artifact="$1"
  file "$artifact" | grep -Fq 'ELF 64-bit LSB executable, x86-64' || return 1
  file "$artifact" | grep -Fq 'statically linked' || return 1
  ! readelf -lW "$artifact" | grep -q INTERP || return 1
  ! readelf -dW "$artifact" | grep -q NEEDED || return 1
  [[ -z "$(nm -u "$artifact")" ]] || return 1
  readelf -lW "$artifact" | grep GNU_STACK | grep -Fq ' RW '
}

require_count() {
  local expected="$1" pattern="$2" path="$3" actual
  actual="$(grep -Fc "$pattern" "$path" || true)"
  [[ "$actual" -eq "$expected" ]] || fail assembly "$path:$pattern expected=$expected actual=$actual"
}

cases=(
  pio-001-text-console
  pio-002-int-console
  pio-003-bool-console
  pio-004-binding-console
  pio-005-default-scan
  pio-006-console-scan
  pio-007-two-scans
  pio-008-empty-console-scan
)

for case_id in "${cases[@]}"; do
  source="$WORK/src/$case_id.no"
  "$NEBOC" check "$source" >"$WORK/build/$case_id.check.out" 2>"$WORK/build/$case_id.check.err" || fail check "$case_id"
  "$NEBOC" emit-asm "$source" -o "$WORK/build/$case_id.a.asm" >"$WORK/build/$case_id.emit-a.out" 2>"$WORK/build/$case_id.emit-a.err" || fail emit "$case_id:a"
  "$NEBOC" emit-asm "$source" -o "$WORK/build/$case_id.b.asm" >"$WORK/build/$case_id.emit-b.out" 2>"$WORK/build/$case_id.emit-b.err" || fail emit "$case_id:b"
  cmp -s "$WORK/build/$case_id.a.asm" "$WORK/build/$case_id.b.asm" || fail determinism "$case_id:asm"
  "$NEBOC" build "$source" -o "$WORK/build/$case_id.a.elf" >"$WORK/build/$case_id.build-a.out" 2>"$WORK/build/$case_id.build-a.err" || fail build "$case_id:a"
  "$NEBOC" build "$source" -o "$WORK/build/$case_id.b.elf" >"$WORK/build/$case_id.build-b.out" 2>"$WORK/build/$case_id.build-b.err" || fail build "$case_id:b"
  cmp -s "$WORK/build/$case_id.a.elf" "$WORK/build/$case_id.b.elf" || fail determinism "$case_id:elf"
  static_elf "$WORK/build/$case_id.a.elf" || fail elf "$case_id"
  for log in "$WORK/build/$case_id".*.out "$WORK/build/$case_id".*.err; do
    [[ ! -s "$log" ]] || fail compiler-output "$case_id:$log"
  done
done

require_count 1 'call nebo_runtime_console_publish_text' "$WORK/build/pio-001-text-console.a.asm"
require_count 1 'call nebo_runtime_console_publish_int' "$WORK/build/pio-002-int-console.a.asm"
grep -Fq 'mov rax, 42' "$WORK/build/pio-002-int-console.a.asm" || fail assembly pio-002-typed-int
require_count 1 'call nebo_runtime_console_publish_bool' "$WORK/build/pio-003-bool-console.a.asm"
grep -Fq 'mov eax, 1' "$WORK/build/pio-003-bool-console.a.asm" || fail assembly pio-003-typed-bool
require_count 1 'call nebo_runtime_console_publish_int' "$WORK/build/pio-004-binding-console.a.asm"
require_count 1 'call nebo_runtime_console_publish_bool' "$WORK/build/pio-004-binding-console.a.asm"
require_count 1 'call nebo_runtime_scan_stdin_text' "$WORK/build/pio-005-default-scan.a.asm"
require_count 1 'call nebo_runtime_scan_console_handle' "$WORK/build/pio-006-console-scan.a.asm"
require_count 2 'call nebo_runtime_scan_console_handle' "$WORK/build/pio-007-two-scans.a.asm"
require_count 1 'call nebo_runtime_scan_console_handle' "$WORK/build/pio-008-empty-console-scan.a.asm"
require_count 2 'call nebo_runtime_console_publish_text' "$WORK/build/pio-008-empty-console-scan.a.asm"
mapfile -t scan_ids < <(awk '/mov esi,/{value=$3} /call nebo_runtime_scan_console_handle/{print value}' "$WORK/build/pio-007-two-scans.a.asm")
[[ "${#scan_ids[@]}" -eq 2 && "${scan_ids[0]}" -gt 0 && "${scan_ids[1]}" -gt 0 && "${scan_ids[0]}" != "${scan_ids[1]}" ]] || fail assembly pio-007-independent-ids

negatives=(reject-print reject-unknown-text-method reject-char-console reject-console-argument)
for negative in "${negatives[@]}"; do
  source="$ROOT/tests/post-rc1-coherence/fixtures/$negative.no"
  for mode in check emit-asm build; do
    artifact="$WORK/build/$negative.$mode.artifact"
    set +e
    case "$mode" in
      check) "$NEBOC" check "$source" >"$WORK/build/$negative.$mode.out" 2>"$WORK/build/$negative.$mode.err" ;;
      emit-asm) "$NEBOC" emit-asm "$source" -o "$artifact" >"$WORK/build/$negative.$mode.out" 2>"$WORK/build/$negative.$mode.err" ;;
      build) "$NEBOC" build "$source" -o "$artifact" >"$WORK/build/$negative.$mode.out" 2>"$WORK/build/$negative.$mode.err" ;;
    esac
    rc=$?
    set -e
    [[ "$rc" -eq 1 && ! -e "$artifact" && ! -s "$WORK/build/$negative.$mode.out" ]] || fail negative "$negative:$mode:exit=$rc"
    grep -Fq 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN' "$WORK/build/$negative.$mode.err" || fail negative "$negative:$mode:diagnostic"
  done
done

for case_id in pio-001-text-console pio-002-int-console pio-003-bool-console pio-004-binding-console; do
  env -u DISPLAY -u XAUTHORITY "$WORK/build/$case_id.a.elf" >"$WORK/build/$case_id.headless.out" 2>"$WORK/build/$case_id.headless.err" || fail headless "$case_id"
  [[ ! -s "$WORK/build/$case_id.headless.out" && ! -s "$WORK/build/$case_id.headless.err" ]] || fail headless-output "$case_id"
done
printf 'Antonio\n' >"$WORK/build/default-scan.input"
env -u DISPLAY -u XAUTHORITY "$WORK/build/pio-005-default-scan.a.elf" <"$WORK/build/default-scan.input" >"$WORK/build/pio-005.headless.out" 2>"$WORK/build/pio-005.headless.err" || fail headless pio-005
[[ "$(cat "$WORK/build/pio-005.headless.out")" == 'Nome: ' && ! -s "$WORK/build/pio-005.headless.err" ]] || fail headless-output pio-005
printf 'HEADLESS_PASS cases=5 fallback=historical\n'

ninja -j2 build/tests/mf044/console_layout_test >"$WORK/build/software-build.log" 2>&1 || fail software mf044-build
for scenario in 1 2 3 4 5; do
  env -u DISPLAY -u XAUTHORITY build/tests/mf044/console_layout_test "$scenario" >>"$WORK/build/software.out" 2>>"$WORK/build/software.err" || fail software "mf044-native-scenario=$scenario"
done
[[ ! -s "$WORK/build/software.out" && ! -s "$WORK/build/software.err" ]] || fail software mf044-output
printf 'SOFTWARE_PASS gate=MF044_NATIVE_LAYOUT_DRAW_SURFACE scenarios=5\n'

[[ -n "${DISPLAY-}" ]] || fail live 'DISPLAY is absent'
mapfile -t auth_rows < <(python3 -B scripts/mf051/resolve-x11-auth.py)
PIO_SOCKET="${auth_rows[0]#SOCKET_PATH=}"
PIO_COOKIE="${auth_rows[1]#COOKIE_HEX=}"
[[ -S "$PIO_SOCKET" && -n "$PIO_COOKIE" ]] || fail live x11-auth

window_ids() {
  xwininfo -root -tree 2>/dev/null | awk '/"NEBO CONSOLE"/ {print $1}' | sort -u
}

wait_new_window() {
  local before_file="$1" after_file="$2" attempt
  CURRENT_XID=
  for attempt in $(seq 1 160); do
    window_ids >"$after_file"
    mapfile -t new_ids < <(comm -13 "$before_file" "$after_file")
    if [[ "${#new_ids[@]}" -eq 1 ]]; then
      CURRENT_XID="${new_ids[0]}"
      return 0
    fi
    [[ "${#new_ids[@]}" -eq 0 ]] || fail live 'multiple new Nebo Console windows'
    sleep 0.025
  done
  fail live window-timeout
}

capture_surface() {
  local label="$1" png colors
  png="$WORK/live/$label.png"
  timeout 4s import -window "$CURRENT_XID" "$png" >/dev/null 2>&1 || fail live "$label:capture"
  colors="$(convert "$png" -crop '640x372+0+28' -format '%k' info:)"
  [[ "$colors" -ge 2 ]] || fail live "$label:blank-content"
  convert "$png" -depth 8 BGRA:- | sha256sum | awk '{print $1}'
}

launch_live() {
  local case_id="$1" input_path="${2:-}" before after
  before="$WORK/live/$case_id.before"
  after="$WORK/live/$case_id.after"
  window_ids >"$before"
  if [[ -n "$input_path" ]]; then
    timeout 20s "$WORK/build/$case_id.a.elf" <"$input_path" >"$WORK/live/$case_id.out" 2>"$WORK/live/$case_id.err" &
  else
    timeout 20s "$WORK/build/$case_id.a.elf" >"$WORK/live/$case_id.out" 2>"$WORK/live/$case_id.err" &
  fi
  CURRENT_PID=$!
  wait_new_window "$before" "$after"
  xwininfo -id "$CURRENT_XID" -all | grep -Fq 'Map State: IsViewable' || fail live "$case_id:not-viewable"
}

close_live() {
  local case_id="$1" expected_stdout="${2:-}" rc
  "$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" c || fail live "$case_id:close-send"
  set +e
  wait "$CURRENT_PID"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail live "$case_id:exit=$rc"
  [[ "$(cat "$WORK/live/$case_id.out")" == "$expected_stdout" && ! -s "$WORK/live/$case_id.err" ]] || fail live "$case_id:unexpected-output"
  CURRENT_PID=
  CURRENT_XID=
}

for case_id in pio-001-text-console pio-002-int-console pio-003-bool-console pio-004-binding-console; do
  launch_live "$case_id"
  render_sha="$(capture_surface "$case_id")"
  printf 'LIVE_PASS case=%s xid=%s render_sha256=%s\n' "$case_id" "$CURRENT_XID" "$render_sha"
  close_live "$case_id"
done

launch_live pio-005-default-scan "$WORK/build/default-scan.input"
render_sha="$(capture_surface pio-005-default-scan)"
printf 'LIVE_PASS case=pio-005-default-scan acquisition=stdin binding=Antonio render_sha256=%s\n' "$render_sha"
close_live pio-005-default-scan 'Nome: '
[[ "$(cat "$WORK/live/pio-005-default-scan.out")" == 'Nome: ' ]] || fail live pio-005-stdout-prompt

launch_live pio-006-console-scan
prompt_sha="$(capture_surface pio-006-prompt)"
"$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" t Antonio || fail live pio-006-input
result_sha="$(capture_surface pio-006-result)"
[[ "$prompt_sha" != "$result_sha" ]] || fail live pio-006-render-transition
printf 'LIVE_PASS case=pio-006-console-scan acquisition=console binding=Antonio prompt_sha256=%s result_sha256=%s\n' "$prompt_sha" "$result_sha"
close_live pio-006-console-scan

launch_live pio-007-two-scans
first_prompt_sha="$(capture_surface pio-007-first-prompt)"
"$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" t Alpha || fail live pio-007-first-input
second_prompt_sha="$(capture_surface pio-007-second-prompt)"
[[ "$first_prompt_sha" != "$second_prompt_sha" ]] || fail live pio-007-first-transition
"$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" t Beta || fail live pio-007-second-input
final_sha="$(capture_surface pio-007-final)"
[[ "$second_prompt_sha" != "$final_sha" && "$first_prompt_sha" != "$final_sha" ]] || fail live pio-007-second-transition
printf 'LIVE_PASS case=pio-007-two-scans bindings=Alpha,Beta independent_ids=%s,%s final_sha256=%s\n' "${scan_ids[0]}" "${scan_ids[1]}" "$final_sha"
close_live pio-007-two-scans

launch_live pio-008-empty-console-scan
empty_prompt_sha="$(capture_surface pio-008-empty-prompt)"
"$DRIVER" "$PIO_SOCKET" "$PIO_COOKIE" "$CURRENT_XID" t '' || fail live pio-008-empty-input
empty_result_sha="$(capture_surface pio-008-empty-result)"
[[ "$empty_prompt_sha" != "$empty_result_sha" ]] || fail live pio-008-empty-transition
printf 'LIVE_PASS case=pio-008-empty-console-scan binding_length=0 process_alive=YES prompt_sha256=%s result_sha256=%s\n' "$empty_prompt_sha" "$empty_result_sha"
close_live pio-008-empty-console-scan

printf 'PRACTICAL_IO_SMOKE_GREEN cases=8 negatives=4 headless=PASS software=PASS live=PASS static_elf=PASS determinism=PASS\n'
