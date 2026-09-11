#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
runner="$repo_root/scripts/live-x11-safe/run-live-x11-safe.sh"
helper="$repo_root/scripts/live-x11-safe/x11-owned-window.py"
input_helper="$repo_root/scripts/live-x11-safe/x11-owned-input.py"

fail() {
    printf 'LIVE_X11_STATIC_SAFETY_ERROR=%s\n' "$1" >&2
    exit 1
}

bash -n "$runner" || fail runner-syntax
PYTHONDONTWRITEBYTECODE=1 python3 -B -c 'import pathlib; compile(pathlib.Path(__import__("sys").argv[1]).read_bytes(), __import__("sys").argv[1], "exec")' "$helper" || fail helper-syntax
PYTHONDONTWRITEBYTECODE=1 python3 -B -c 'import pathlib; compile(pathlib.Path(__import__("sys").argv[1]).read_bytes(), __import__("sys").argv[1], "exec")' "$input_helper" || fail input-helper-syntax

for forbidden in xdotool pkill killall 'DISPLAY:-' 'DISPLAY:=' 'sort.*XID' 'newest.*XID' 'title-only'; do
    if rg -ni "$forbidden" "$runner" "$helper" "$input_helper" >/dev/null; then
        fail "forbidden-pattern:$forbidden"
    fi
done

rg -q 'unset DISPLAY WAYLAND_DISPLAY XAUTHORITY' "$runner" || fail active-display-not-masked
rg -q 'lock_fd=9' "$runner" || fail singleton-lock-fd-not-explicit
rg -q 'flock -n "\$lock_fd"' "$runner" || fail singleton-lock-missing
rg -q 'trap cleanup EXIT' "$runner" || fail exit-trap-missing
for signal_name in INT TERM HUP; do
    rg -q "trap 'handle_signal $signal_name " "$runner" || fail "signal-trap-missing:$signal_name"
done
rg -q '_NET_WM_PID' "$helper" || fail ownership-property-missing
rg -q 'require_owned\(display, xid, pid\)' "$helper" || fail close-ownership-gate-missing
rg -q 'kill "-\$signal_name" -- "-\$pgid"' "$runner" || fail exact-pgid-signal-missing
rg -q 'Xvfb-unavailable' "$runner" || fail isolated-display-fail-closed-missing
rg -q 'case-count-must-be-1-to-5' "$runner" || fail batch-bound-missing
rg -q 'SPAWN_INTENT' "$runner" || fail durable-spawn-intent-missing
rg -q 'IDENTITY_DURABLY_RECORDED' "$runner" || fail durable-identity-state-missing
rg -q 'IN_MEMORY_LEDGER_IMPORTED' "$runner" || fail memory-import-state-missing
rg -q 'CHILD_RUNNING' "$runner" || fail child-running-state-missing
rg -q 'pending_spawn_file' "$runner" || fail pending-spawn-slot-missing
rg -q 'mv .*pending_spawn_file.*target.*9>&-' "$runner" || fail atomic-ledger-rename-missing
rg -q 'proc_start_time' "$runner" || fail pid-reuse-start-time-missing
rg -q 'proc_pgid.*record_pgid' "$runner" || fail pid-reuse-pgid-guard-missing
rg -q 'proc_sid.*record_sid' "$runner" || fail pid-reuse-sid-guard-missing
rg -Fq 'eval "exec ${runner_fd}>&-"' "$runner" || fail child-lock-fd-close-missing
rg -q 'verify_child_fd_isolation' "$runner" || fail dynamic-fd-oracle-missing
for role in xserver ownership-helper capture-helper input-helper decoy nebo-elf; do
    rg -q "start_owned_session $role|run_helper .* $role " "$runner" || fail "spawn-role-not-registered:$role"
done
background_count=$(rg -c '&\s*$' "$runner")
[[ "$background_count" -eq 1 ]] || fail "background-operator-count:$background_count"
if rg -n '(for|while).*[;&][[:space:]]*$' "$runner" >/dev/null; then
    fail parallel-loop-detected
fi
proof_line=$(rg -n 'pre-close-proof\.txt' "$runner" | cut -d: -f1)
close_line=$(rg -n 'wm-delete\.txt' "$runner" | cut -d: -f1)
[[ "$proof_line" -lt "$close_line" ]] || fail unverified-wm-delete-order
rg -q 'XSendEvent\(display, Window\(xid\), False, 0' "$input_helper" || fail exact-xid-send-event-missing
rg -q 'window_pid\(display, xid\)' "$input_helper" || fail input-net-wm-pid-revalidation-missing
rg -q 'verify_record\(record, "nebo-elf", nonce, pid\)' "$input_helper" || fail input-ledger-identity-gate-missing
rg -q 'MAX_INPUT_OPERATIONS = [0-9]+' "$input_helper" || fail input-operation-limit-missing
rg -q 'MAX_TOTAL_UTF8_BYTES = [0-9]+' "$input_helper" || fail input-byte-limit-missing
rg -q 'ACTIVE_OR_UNBOUNDED_DISPLAY_REJECTED' "$input_helper" || fail active-input-display-rejection-missing
rg -q 'input-plan-requires-one-case' "$runner" || fail input-batch-bound-missing
rg -q 'run_helper .*input-helper' "$runner" || fail input-helper-ledger-routing-missing
rg -q '^window_expectation=EXACTLY_ONE$' "$runner" || fail window-expectation-safe-default-missing
rg -Fq '[[ "$window_expectation" == EXACTLY_ONE || "$window_expectation" == EXACTLY_ZERO ]]' "$runner" || fail exact-window-expectation-enum-missing
rg -q '^expected_child_exit=0$' "$runner" || fail expected-child-exit-default-missing
rg -q 'expected_child_exit <= 255' "$runner" || fail expected-child-exit-upper-bound-missing
rg -q 'duplicate-window-expectation' "$runner" || fail duplicate-window-expectation-rejection-missing
rg -q 'duplicate-expected-child-exit' "$runner" || fail duplicate-child-exit-rejection-missing
rg -q 'EXPECTED_OWNED_WINDOW_NOT_CREATED' "$runner" || fail missing-window-diagnostic-missing
rg -q 'UNEXPECTED_OWNED_WINDOW_CREATED' "$runner" || fail unexpected-window-diagnostic-missing
rg -q 'CHILD_EXIT_MISMATCH' "$runner" || fail child-exit-mismatch-diagnostic-missing
rg -q 'wait_zero_window_exit' "$runner" || fail exactly-zero-state-machine-missing
rg -q 'child_exit_timeout=[0-9]' "$runner" || fail bounded-child-exit-wait-missing
if rg -n '^window_expectation=(AUTO|ZERO_OR_ONE|OPTIONAL|BEST_EFFORT)$' "$runner" >/dev/null; then
    fail forbidden-window-expectation-mode
fi
if rg -ni 'XTest|XTEST|XWarpPointer|XSetInputFocus|ButtonPress|ButtonRelease|xdotool|subprocess|shell=True|os\.system|eval\(' "$input_helper" >/dev/null; then
    fail forbidden-input-primitive
fi

printf '%s\n' \
    'FORBIDDEN_PATTERN_COUNT=0' \
    'BACKGROUND_PROCESS_OPERATORS=1_OWNED_SESSION_LAUNCH_PRIMITIVE_ONLY' \
    'PARALLEL_LOOPS=0' \
    'ACTIVE_DISPLAY_FALLBACK=NO' \
    'GLOBAL_SINGLETON_STATIC=PASS' \
    'ATOMIC_PROCESS_REGISTRATION_STATIC=PASS' \
    'PENDING_SPAWN_SLOT_STATIC=PASS' \
    'DURABLE_LEDGER_STATIC=PASS' \
    'PID_REUSE_GUARD_STATIC=PASS' \
    'CHILD_LOCK_FD_CLOSE_STATIC=PASS' \
    'XID_OWNERSHIP_STATIC=PASS_EXACT_NET_WM_PID' \
    'PROCESS_GROUP_SIGNAL_STATIC=PASS_EXACT_OWNED_PGID' \
    'SAFE_INPUT_STATIC=PASS_EXACT_XID_PID_NET_WM_PID' \
    'FORBIDDEN_INPUT_PATTERN_COUNT=0' \
    'WINDOW_EXPECTATION_MODES=EXACTLY_ONE,EXACTLY_ZERO' \
    'AUTO_WINDOW_EXPECTATION=NO' \
    'ZERO_OR_ONE_MODE=NO' \
    'EXPECTED_CHILD_EXIT_RANGE=0..255' \
    'FORBIDDEN_WINDOW_EXPECTATION_PATTERN_COUNT=0' \
    'TRAPS_STATIC=PASS_EXIT_INT_TERM_HUP' \
    'STATIC_SAFETY=PASS'
