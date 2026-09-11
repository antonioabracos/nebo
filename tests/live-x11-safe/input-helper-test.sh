#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
helper="$repo_root/scripts/live-x11-safe/x11-owned-input.py"
work_dir=$(mktemp -d /tmp/nebo-live-x11-input-helper-test.XXXXXXXX)
trap 'rm -rf -- "$work_dir"' EXIT INT TERM HUP

fail() {
    printf 'LIVE_X11_INPUT_HELPER_TEST_ERROR=%s\n' "$1" >&2
    exit 1
}

expect_reject() {
    local label=$1 plan=$2 status=0
    python3 -B "$helper" validate-plan --plan "$plan" >"$work_dir/$label.out" 2>"$work_dir/$label.err" || status=$?
    [[ "$status" -ne 0 ]] || fail "accepted:$label"
}

printf '%s\n' '{"version":1,"operations":[{"op":"TEXT_UTF8","text":"MoveOK"},{"op":"BACKSPACE"},{"op":"WAIT_MILLISECONDS","milliseconds":10},{"op":"ENTER"}]}' >"$work_dir/valid.json"
python3 -B "$helper" validate-plan --plan "$work_dir/valid.json" | rg -q 'SAFE_INPUT_PLAN=PASS' || fail valid-plan

printf '%s\n' '{"version":1,"operations":[{"op":"SHELL","text":"echo unsafe"}]}' >"$work_dir/operation.json"
expect_reject operation "$work_dir/operation.json"
printf '%s\n' '{"version":1,"operations":[{"op":"WAIT_MILLISECONDS","milliseconds":1001}]}' >"$work_dir/wait.json"
expect_reject wait "$work_dir/wait.json"
printf '%s\n' '{"version":1,"operations":[{"op":"TEXT_UTF8","text":""}]}' >"$work_dir/empty-text.json"
expect_reject empty-text "$work_dir/empty-text.json"
printf '\377' >"$work_dir/invalid-utf8.json"
expect_reject invalid-utf8 "$work_dir/invalid-utf8.json"
python3 -B -c 'import json,sys; open(sys.argv[1],"w",encoding="utf-8").write(json.dumps({"version":1,"operations":[{"op":"ENTER"}]*65}))' "$work_dir/count.json"
expect_reject count "$work_dir/count.json"
python3 -B -c 'import json,sys; open(sys.argv[1],"w",encoding="utf-8").write(json.dumps({"version":1,"operations":[{"op":"TEXT_UTF8","text":"x"*257}]}))' "$work_dir/bytes.json"
expect_reject bytes "$work_dir/bytes.json"

active_status=0
DISPLAY=:0 XAUTHORITY="$work_dir/no-authority" python3 -B "$helper" prepare-keymap \
    --display :0 --authority "$work_dir/no-authority" --ledger-record "$work_dir/no-record" \
    --case-nonce invalid --plan "$work_dir/valid.json" >"$work_dir/active.out" 2>"$work_dir/active.err" || active_status=$?
[[ "$active_status" -ne 0 ]] || fail active-display-accepted
rg -q 'ACTIVE_OR_UNBOUNDED_DISPLAY_REJECTED' "$work_dir/active.err" || fail active-display-wrong-rejection

missing_status=0
python3 -B "$helper" send --display :90 --authority "$work_dir/no-authority" \
    --ledger-record "$work_dir/no-record" --case-nonce invalid --plan "$work_dir/valid.json" \
    --pid 1 --xid 0x1 >"$work_dir/missing.out" 2>"$work_dir/missing.err" || missing_status=$?
[[ "$missing_status" -ne 0 ]] || fail missing-context-accepted

printf '%s\n' \
    'STRICT_PLAN_PARSING=PASS' \
    'INVALID_PLAN_ACCEPTED=0' \
    'UTF8_VALIDATION=PASS' \
    'OPERATION_COUNT_LIMIT=PASS' \
    'BYTE_COUNT_LIMIT=PASS' \
    'WAIT_LIMIT=PASS' \
    'ACTIVE_DISPLAY_FAIL_CLOSED=PASS' \
    'UNOWNED_INPUT_SENT=0' \
    'ACTIVE_DISPLAY_INPUT_SENT=0' \
    'INPUT_HELPER_PROTOCOL_TEST=PASS'
