#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
runner="$repo_root/scripts/live-x11-safe/run-live-x11-safe.sh"
one_window_artifact=${NEBO_LIVE_X11_CARDINALITY_ONE_WINDOW_ARTIFACT-}
one_window_exit=${NEBO_LIVE_X11_CARDINALITY_ONE_WINDOW_EXIT-41}
preserve_work=0
if [[ -n ${NEBO_LIVE_X11_CARDINALITY_TEST_EVIDENCE-} ]]; then
    work_dir=$NEBO_LIVE_X11_CARDINALITY_TEST_EVIDENCE
    [[ "$work_dir" == /tmp/* ]] || { printf 'LIVE_X11_WINDOW_CARDINALITY_TEST_ERROR=evidence-must-be-under-tmp\n' >&2; exit 64; }
    mkdir -- "$work_dir"
    preserve_work=1
else
    work_dir=$(mktemp -d /tmp/nebo-live-x11-window-cardinality-test.XXXXXXXX)
fi

cleanup() {
    local saved=$?
    trap - EXIT INT TERM HUP
    if [[ "$preserve_work" -eq 0 && "$work_dir" == /tmp/nebo-live-x11-window-cardinality-test.* && -d "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi
    exit "$saved"
}
trap cleanup EXIT INT TERM HUP

fail() {
    printf 'LIVE_X11_WINDOW_CARDINALITY_TEST_ERROR=%s\n' "$1" >&2
    exit 1
}

[[ "$one_window_artifact" == /* && -f "$one_window_artifact" && -x "$one_window_artifact" ]] || fail one-window-artifact-required
[[ "$one_window_exit" =~ ^(0|[1-9][0-9]*)$ ]] && (( one_window_exit <= 255 )) || fail invalid-one-window-exit

make_exit_child() {
    local path=$1 delay=$2 status=$3
    printf '#!/usr/bin/python3\nimport time\ntime.sleep(%s)\nraise SystemExit(%s)\n' "$delay" "$status" > "$path"
    chmod +x "$path"
}

run_pass() {
    local label=$1
    shift
    "$runner" --evidence-dir "$work_dir/$label" "$@" > "$work_dir/$label.stdout" 2> "$work_dir/$label.stderr" \
        || fail "unexpected-failure:$label"
}

run_fail() {
    local label=$1 diagnostic=$2 status=0
    shift 2
    "$runner" --evidence-dir "$work_dir/$label" "$@" > "$work_dir/$label.stdout" 2> "$work_dir/$label.stderr" || status=$?
    [[ "$status" -ne 0 ]] || fail "unexpected-success:$label"
    rg -q "$diagnostic" "$work_dir/$label.stderr" || fail "wrong-diagnostic:$label"
}

zero41="$work_dir/zero41.sh"
zero42="$work_dir/zero42.sh"
slow0="$work_dir/slow0.sh"
make_exit_child "$zero41" 0 41
make_exit_child "$zero42" 0 42
make_exit_child "$slow0" 0.20 0

for invalid_case in auto optional negative high duplicate-window duplicate-exit; do
    status=0
    case "$invalid_case" in
        auto) invalid_args=(--window-expectation AUTO) ;;
        optional) invalid_args=(--window-expectation ZERO_OR_ONE) ;;
        negative) invalid_args=(--expected-child-exit -1) ;;
        high) invalid_args=(--expected-child-exit 256) ;;
        duplicate-window) invalid_args=(--window-expectation EXACTLY_ZERO --window-expectation EXACTLY_ONE) ;;
        duplicate-exit) invalid_args=(--expected-child-exit 0 --expected-child-exit 1) ;;
    esac
    "$runner" --evidence-dir "$work_dir/invalid-$invalid_case" "${invalid_args[@]}" "$zero41" \
        > "$work_dir/invalid-$invalid_case.stdout" 2> "$work_dir/invalid-$invalid_case.stderr" || status=$?
    [[ "$status" -eq 64 ]] || fail "invalid-argument-status:$invalid_case:$status"
done

run_pass zero41 --window-expectation EXACTLY_ZERO --expected-child-exit 41 "$zero41"
result="$work_dir/zero41/01-zero41.sh/result.env"
rg -q '^WINDOW_OUTCOME=PASS_EXACTLY_ZERO$' "$result" || fail zero41-outcome
rg -q '^CHILD_EXIT_STATUS=41$' "$result" || fail zero41-status
rg -q '^OWNED_WINDOW_COUNT_OBSERVED=0$' "$result" || fail zero41-window-count
rg -q '^SCREENSHOT_SENT=0$' "$result" || fail zero41-screenshot
rg -q '^INPUT_SENT=0$' "$result" || fail zero41-input
rg -q '^WM_DELETE_SENT=0$' "$result" || fail zero41-close

run_fail mismatch CHILD_EXIT_MISMATCH --window-expectation EXACTLY_ZERO --expected-child-exit 41 "$zero42"
rg -q '^CHILD_EXIT_STATUS=42$' "$work_dir/mismatch/01-zero42.sh/result.env" || fail mismatch-actual-status
run_fail unexpected-window UNEXPECTED_OWNED_WINDOW_CREATED --window-expectation EXACTLY_ZERO --expected-child-exit "$one_window_exit" "$one_window_artifact"
unexpected_result="$work_dir/unexpected-window/01-$(basename -- "$one_window_artifact")/result.env"
rg -q '^SCREENSHOT_SENT=0$' "$unexpected_result" || fail unexpected-window-screenshot
rg -q '^INPUT_SENT=0$' "$unexpected_result" || fail unexpected-window-input
rg -q '^WM_DELETE_SENT=0$' "$unexpected_result" || fail unexpected-window-close

run_pass exactly-one --window-expectation EXACTLY_ONE --expected-child-exit "$one_window_exit" "$one_window_artifact"
rg -q '^WINDOW_OUTCOME=PASS_EXACTLY_ONE$' "$work_dir/exactly-one/01-$(basename -- "$one_window_artifact")/result.env" || fail exactly-one-outcome
run_fail missing-window EXPECTED_OWNED_WINDOW_NOT_CREATED --window-expectation EXACTLY_ONE --expected-child-exit 41 "$zero41"

run_pass decoy-zero --decoy --window-expectation EXACTLY_ZERO --expected-child-exit 0 "$slow0"
rg -q '^DECOY_WINDOW_SURVIVES=YES$' "$work_dir/decoy-zero/run.env" || fail decoy-window
rg -q '^DECOY_PROCESS_SURVIVES=YES$' "$work_dir/decoy-zero/run.env" || fail decoy-process
rg -q '^DECOY_KEY_EVENTS=0$' "$work_dir/decoy-zero/run.env" || fail decoy-key-action
rg -q '^DECOY_FOCUS_EVENTS=0$' "$work_dir/decoy-zero/run.env" || fail decoy-focus-action

fast_count=0
for delay in 0 0.001 0.010 0.100; do
    for expected in 0 41 255; do
        fast_count=$((fast_count + 1))
        artifact="$work_dir/fast-$fast_count.sh"
        make_exit_child "$artifact" "$delay" "$expected"
        run_pass "fast-$fast_count" --window-expectation EXACTLY_ZERO --expected-child-exit "$expected" "$artifact"
        fast_result="$work_dir/fast-$fast_count/01-fast-$fast_count.sh/result.env"
        rg -q "^CHILD_EXIT_STATUS=$expected$" "$fast_result" || fail "fast-exit-status:$fast_count"
        rg -q '^OWNED_WINDOW_COUNT_OBSERVED=0$' "$fast_result" || fail "fast-window-count:$fast_count"
    done
done

declare -A signal_status=([INT]=130 [TERM]=143 [HUP]=129)
interruption_count=0
for mode in EXACTLY_ZERO EXACTLY_ONE; do
    if [[ "$mode" == EXACTLY_ZERO ]]; then
        race_artifact=$slow0
        race_exit=0
    else
        race_artifact=$one_window_artifact
        race_exit=$one_window_exit
    fi
    for race_state in after-create after-durable-record before-memory-import before-release after-release; do
        for signal_name in INT TERM HUP; do
            interruption_count=$((interruption_count + 1))
            race_dir="$work_dir/spawn-race-$interruption_count"
            race_status=0
            NEBO_LIVE_X11_SELFTEST=1 NEBO_LIVE_X11_RACE_STATE="$race_state" \
            NEBO_LIVE_X11_RACE_SIGNAL="$signal_name" NEBO_LIVE_X11_RACE_ROLE=nebo-elf \
                "$runner" --evidence-dir "$race_dir" --window-expectation "$mode" --expected-child-exit "$race_exit" "$race_artifact" \
                > "$race_dir.stdout" 2> "$race_dir.stderr" || race_status=$?
            [[ "$race_status" -eq "${signal_status[$signal_name]}" ]] || fail "spawn-race:$mode:$race_state:$signal_name:$race_status"
        done
    done
    for race_state in cardinality-observation child-exit-wait after-child-exit-before-ledger-cleanup; do
        for signal_name in INT TERM HUP; do
            interruption_count=$((interruption_count + 1))
            race_dir="$work_dir/cardinality-race-$interruption_count"
            race_status=0
            NEBO_LIVE_X11_SELFTEST=1 NEBO_LIVE_X11_CARDINALITY_RACE_STATE="$race_state" \
            NEBO_LIVE_X11_CARDINALITY_RACE_SIGNAL="$signal_name" NEBO_LIVE_X11_CARDINALITY_RACE_MODE="$mode" \
                "$runner" --evidence-dir "$race_dir" --window-expectation "$mode" --expected-child-exit "$race_exit" "$race_artifact" \
                > "$race_dir.stdout" 2> "$race_dir.stderr" || race_status=$?
            [[ "$race_status" -eq "${signal_status[$signal_name]}" ]] || fail "cardinality-race:$mode:$race_state:$signal_name:$race_status"
            [[ -s "$race_dir/cardinality-race-events.tsv" ]] || fail "cardinality-race-event:$mode:$race_state:$signal_name"
        done
    done
done

printf '%s\n' \
    'INVALID_WINDOW_EXPECTATION_ACCEPTED=0' \
    'INVALID_EXPECTED_EXIT_ACCEPTED=0' \
    'ZERO_WINDOW_EXIT_41=PASS' \
    'CHILD_EXIT_MISMATCH=CORRECT_FAILURE' \
    'UNEXPECTED_OWNED_WINDOW_CREATED=CORRECT_FAILURE' \
    'EXACTLY_ONE_WINDOW_CASE=PASS' \
    'EXACTLY_ONE_MISSING_WINDOW=CORRECT_FAILURE' \
    'DECOY_WINDOW_NOT_COUNTED_AS_OWNED=YES' \
    'DECOY_WINDOW_SURVIVES=YES' \
    'DECOY_PROCESS_SURVIVES=YES' \
    "FAST_EXIT_REGRESSION=PASS_${fast_count}_OF_${fast_count}" \
    "WINDOW_CARDINALITY_INTERRUPTION_MATRIX=PASS_${interruption_count}_OF_${interruption_count}" \
    'ORPHAN_PREVENTION=PASS' \
    'WINDOW_CARDINALITY_TEST=PASS'
