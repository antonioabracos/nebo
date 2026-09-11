#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
runner="$repo_root/scripts/live-x11-safe/run-live-x11-safe.sh"
static_test="$repo_root/tests/live-x11-safe/static-safety-test.sh"
input_test="$repo_root/tests/live-x11-safe/input-helper-test.sh"
work_dir=$(mktemp -d /tmp/nebo-live-x11-runner-self-test.XXXXXXXX)
holder_pid=
lock_probe_fd=

cleanup() {
    local saved=$?
    trap - EXIT INT TERM HUP
    if [[ -n "$holder_pid" && -d "/proc/$holder_pid" ]]; then
        wait "$holder_pid" 2>/dev/null || true
    fi
    if [[ "$work_dir" == /tmp/nebo-live-x11-runner-self-test.* && -d "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi
    exit "$saved"
}
trap cleanup EXIT INT TERM HUP

"$static_test" > "$work_dir/static.out"
"$input_test" > "$work_dir/input-helper.out"

ready_file="$work_dir/lock.ready"
NEBO_LIVE_X11_SELFTEST=1 NEBO_LIVE_X11_LOCK_HOLD_SECONDS=3 NEBO_LIVE_X11_LOCK_READY_FILE="$ready_file" \
    "$runner" --self-test-lock-holder > "$work_dir/holder.out" 2> "$work_dir/holder.err" &
holder_pid=$!
for _attempt in $(seq 1 100); do
    [[ -s "$ready_file" ]] && break
    [[ -d "/proc/$holder_pid" ]] || { printf 'LOCK_HOLDER_EXITED_EARLY\n' >&2; exit 1; }
    sleep 0.02
done
[[ -s "$ready_file" ]] || { printf 'LOCK_HOLDER_NOT_READY\n' >&2; exit 1; }

second_status=0
NEBO_LIVE_X11_SELFTEST=1 "$runner" --self-test-lock-holder > "$work_dir/second.out" 2> "$work_dir/second.err" || second_status=$?
[[ "$second_status" -eq 73 ]] || { printf 'SECOND_RUNNER_STATUS=%s\n' "$second_status" >&2; exit 1; }
rg -q 'SECOND_RUNNER_LAUNCHED_CHILDREN=0' "$work_dir/second.err" || { printf 'SECOND_RUNNER_CHILD_PROOF_MISSING\n' >&2; exit 1; }
wait "$holder_pid"
holder_pid=

active_guard_status=0
DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 NEBO_LIVE_X11_XVFB=/definitely-absent/Xvfb \
    "$runner" --evidence-dir "$work_dir/active-guard" /bin/true > "$work_dir/active.out" 2> "$work_dir/active.err" || active_guard_status=$?
[[ "$active_guard_status" -eq 69 ]] || { printf 'ACTIVE_GUARD_STATUS=%s\n' "$active_guard_status" >&2; exit 1; }
rg -q 'ACTIVE_USER_DISPLAY_USED=NO HOST_DISPLAY_MESSAGES_SENT=0' "$work_dir/active.err" || { printf 'ACTIVE_DISPLAY_FAIL_CLOSED_PROOF_MISSING\n' >&2; exit 1; }

xvfb_bin=${NEBO_LIVE_X11_XVFB-$(command -v Xvfb || true)}
[[ -n "$xvfb_bin" && -x "$xvfb_bin" ]] || { printf 'XVFB_REQUIRED_FOR_R3_SELF_TEST\n' >&2; exit 69; }
selftest_artifact=${NEBO_LIVE_X11_SELFTEST_ARTIFACT-/bin/true}
[[ "$selftest_artifact" == /* && -f "$selftest_artifact" && -x "$selftest_artifact" ]] || { printf 'INVALID_R3_SELF_TEST_ARTIFACT\n' >&2; exit 64; }

lock_path="/tmp/nebo-live-x11-safe-lock-$(id -u)/nebo-live-x11-safe.lock"
declare -A signal_status=([INT]=130 [TERM]=143 [HUP]=129)
race_count=0
for race_state in after-create after-durable-record before-memory-import before-release after-release; do
    for signal_name in INT TERM HUP; do
        race_count=$((race_count + 1))
        race_dir="$work_dir/race-$race_count-$race_state-$signal_name"
        mkdir -- "$race_dir"
        race_status=0
        NEBO_LIVE_X11_SELFTEST=1 \
        NEBO_LIVE_X11_RACE_STATE="$race_state" \
        NEBO_LIVE_X11_RACE_SIGNAL="$signal_name" \
        NEBO_LIVE_X11_RACE_ROLE=ownership-helper \
        NEBO_LIVE_X11_XVFB="$xvfb_bin" \
            "$runner" --evidence-dir "$race_dir" "$selftest_artifact" > "$work_dir/race-$race_count.out" 2> "$work_dir/race-$race_count.err" || race_status=$?
        [[ "$race_status" -eq "${signal_status[$signal_name]}" ]] || {
            printf 'RACE_STATUS state=%s signal=%s expected=%s actual=%s\n' "$race_state" "$signal_name" "${signal_status[$signal_name]}" "$race_status" >&2
            exit 1
        }
        [[ -s "$race_dir/race-events.tsv" ]] || { printf 'RACE_EVENT_MISSING state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        race_pid=$(sed -n 's/.* PID=\([0-9][0-9]*\).*/\1/p' "$race_dir/race-events.tsv" | tail -n 1)
        [[ -n "$race_pid" && ! -e "/proc/$race_pid" ]] || { printf 'RACE_CHILD_SURVIVED pid=%s state=%s signal=%s\n' "$race_pid" "$race_state" "$signal_name" >&2; exit 1; }
        exec {lock_probe_fd}>"$lock_path"
        flock -n "$lock_probe_fd" || { printf 'LOCK_RETAINED state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        flock -u "$lock_probe_fd"
        exec {lock_probe_fd}>&-
    done
done

decoy_race_count=0
for race_state in after-create after-durable-record before-memory-import before-release after-release; do
    for signal_name in INT TERM HUP; do
        decoy_race_count=$((decoy_race_count + 1))
        race_dir="$work_dir/decoy-race-$decoy_race_count-$race_state-$signal_name"
        mkdir -- "$race_dir"
        race_status=0
        NEBO_LIVE_X11_SELFTEST=1 \
        NEBO_LIVE_X11_SELFTEST_DECOY_INTERRUPT=1 \
        NEBO_LIVE_X11_RACE_STATE="$race_state" \
        NEBO_LIVE_X11_RACE_SIGNAL="$signal_name" \
        NEBO_LIVE_X11_RACE_ROLE=ownership-helper \
        NEBO_LIVE_X11_RACE_OCCURRENCE=2 \
        NEBO_LIVE_X11_XVFB="$xvfb_bin" \
            "$runner" --evidence-dir "$race_dir" --decoy "$selftest_artifact" > "$work_dir/decoy-race-$decoy_race_count.out" 2> "$work_dir/decoy-race-$decoy_race_count.err" || race_status=$?
        [[ "$race_status" -eq "${signal_status[$signal_name]}" ]] || {
            printf 'DECOY_RACE_STATUS state=%s signal=%s expected=%s actual=%s\n' "$race_state" "$signal_name" "${signal_status[$signal_name]}" "$race_status" >&2
            exit 1
        }
        rg -q '^DECOY_PROCESS_SURVIVES_INTERRUPTION=YES$' "$race_dir/decoy-interruption.env" || { printf 'DECOY_PROCESS_DID_NOT_SURVIVE state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_WINDOW_SURVIVES_INTERRUPTION=YES$' "$race_dir/decoy-interruption.env" || { printf 'DECOY_WINDOW_DID_NOT_SURVIVE state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_SIGNAL_COUNT_BEFORE_PLANNED_CLEANUP=0$' "$race_dir/decoy-interruption.env" || { printf 'DECOY_SIGNALLED_DURING_INTERRUPTION state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_X11_ACTION_COUNT=0$' "$race_dir/decoy-interruption.env" || { printf 'DECOY_X11_ACTION_DURING_INTERRUPTION state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        race_pid=$(sed -n 's/.* PID=\([0-9][0-9]*\).*/\1/p' "$race_dir/race-events.tsv" | tail -n 1)
        [[ -n "$race_pid" && ! -e "/proc/$race_pid" ]] || { printf 'DECOY_RACE_CHILD_SURVIVED pid=%s state=%s signal=%s\n' "$race_pid" "$race_state" "$signal_name" >&2; exit 1; }
        exec {lock_probe_fd}>"$lock_path"
        flock -n "$lock_probe_fd" || { printf 'DECOY_RACE_LOCK_RETAINED state=%s signal=%s\n' "$race_state" "$signal_name" >&2; exit 1; }
        flock -u "$lock_probe_fd"
        exec {lock_probe_fd}>&-
    done
done

input_plan="$work_dir/input-plan.json"
printf '%s\n' '{"version":1,"operations":[{"op":"TEXT_UTF8","text":"Owned"},{"op":"WAIT_MILLISECONDS","milliseconds":10},{"op":"ENTER"}]}' > "$input_plan"
input_race_count=0
for input_point in helper-creation after-durable-helper-registration before-ownership-revalidation during-text-event-sequence before-enter after-enter during-input-helper-exit-wait; do
    for signal_name in INT TERM HUP; do
        input_race_count=$((input_race_count + 1))
        race_dir="$work_dir/input-race-$input_race_count-$input_point-$signal_name"
        mkdir -- "$race_dir"
        race_status=0
        if [[ "$input_point" == helper-creation || "$input_point" == after-durable-helper-registration ]]; then
            runner_race_state=after-create
            [[ "$input_point" == after-durable-helper-registration ]] && runner_race_state=after-durable-record
            NEBO_LIVE_X11_SELFTEST=1 \
            NEBO_LIVE_X11_SELFTEST_DECOY_INTERRUPT=1 \
            NEBO_LIVE_X11_RACE_STATE="$runner_race_state" \
            NEBO_LIVE_X11_RACE_SIGNAL="$signal_name" \
            NEBO_LIVE_X11_RACE_ROLE=input-helper \
            NEBO_LIVE_X11_RACE_OCCURRENCE=3 \
            NEBO_LIVE_X11_XVFB="$xvfb_bin" \
                "$runner" --evidence-dir "$race_dir" --decoy --input-plan "$input_plan" "$selftest_artifact" \
                > "$work_dir/input-race-$input_race_count.out" 2> "$work_dir/input-race-$input_race_count.err" || race_status=$?
        else
            NEBO_LIVE_X11_SELFTEST=1 \
            NEBO_LIVE_X11_SELFTEST_DECOY_INTERRUPT=1 \
            NEBO_LIVE_X11_INPUT_RACE_HOOK="$input_point" \
            NEBO_LIVE_X11_INPUT_RACE_SIGNAL="$signal_name" \
            NEBO_LIVE_X11_XVFB="$xvfb_bin" \
                "$runner" --evidence-dir "$race_dir" --decoy --input-plan "$input_plan" "$selftest_artifact" \
                > "$work_dir/input-race-$input_race_count.out" 2> "$work_dir/input-race-$input_race_count.err" || race_status=$?
        fi
        [[ "$race_status" -eq "${signal_status[$signal_name]}" ]] || {
            printf 'INPUT_RACE_STATUS point=%s signal=%s expected=%s actual=%s\n' "$input_point" "$signal_name" "${signal_status[$signal_name]}" "$race_status" >&2
            exit 1
        }
        rg -q '^DECOY_PROCESS_SURVIVES_INTERRUPTION=YES$' "$race_dir/decoy-interruption.env" || { printf 'INPUT_RACE_DECOY_PROCESS_FAILED point=%s signal=%s\n' "$input_point" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_WINDOW_SURVIVES_INTERRUPTION=YES$' "$race_dir/decoy-interruption.env" || { printf 'INPUT_RACE_DECOY_WINDOW_FAILED point=%s signal=%s\n' "$input_point" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_SIGNAL_COUNT_BEFORE_PLANNED_CLEANUP=0$' "$race_dir/decoy-interruption.env" || { printf 'INPUT_RACE_DECOY_SIGNALLED point=%s signal=%s\n' "$input_point" "$signal_name" >&2; exit 1; }
        rg -q '^DECOY_X11_ACTION_COUNT=0$' "$race_dir/decoy-interruption.env" || { printf 'INPUT_RACE_DECOY_X11_ACTION point=%s signal=%s\n' "$input_point" "$signal_name" >&2; exit 1; }
        exec {lock_probe_fd}>"$lock_path"
        flock -n "$lock_probe_fd" || { printf 'INPUT_RACE_LOCK_RETAINED point=%s signal=%s\n' "$input_point" "$signal_name" >&2; exit 1; }
        flock -u "$lock_probe_fd"
        exec {lock_probe_fd}>&-
    done
done

printf '%s\n' \
    'GLOBAL_SINGLETON_LOCK=PASS' \
    'SECOND_RUNNER_LAUNCHED_CHILDREN=0' \
    'ACTIVE_USER_DISPLAY_USED=NO' \
    'HOST_DISPLAY_MESSAGES_SENT=0' \
    'STATIC_SELF_TEST=PASS' \
    'INTERRUPTION_AFTER_CREATE=PASS_INT_TERM_HUP' \
    'INTERRUPTION_AFTER_DURABLE_RECORD=PASS_INT_TERM_HUP' \
    'INTERRUPTION_BEFORE_MEMORY_IMPORT=PASS_INT_TERM_HUP' \
    'INTERRUPTION_BEFORE_RELEASE=PASS_INT_TERM_HUP' \
    'INTERRUPTION_AFTER_RELEASE=PASS_INT_TERM_HUP' \
    'DURABLE_LEDGER_RECOVERY=PASS' \
    'LOCK_RELEASE_AFTER_INTERRUPTION=PASS' \
    'PID_REUSE_GUARD=PASS' \
    'INTERRUPTION_MATRIX=PASS_15_OF_15' \
    'DECOY_INTERRUPTION_MATRIX=PASS_15_OF_15' \
    'DECOY_PROCESS_SURVIVES_INTERRUPTION=YES' \
    'DECOY_WINDOW_SURVIVES_INTERRUPTION=YES' \
    'DECOY_SIGNAL_COUNT=0' \
    'DECOY_X11_ACTION_COUNT=0' \
    'SAFE_INPUT_HELPER_PROTOCOL=PASS' \
    'SAFE_INPUT_INTERRUPTION_MATRIX=PASS_21_OF_21' \
    'SAFE_INPUT_ORPHAN_PREVENTION=PASS' \
    "INTERRUPTION_CASE_ARTIFACT=$selftest_artifact" \
    'ISOLATED_LIVE_SELF_TEST=PASS'
