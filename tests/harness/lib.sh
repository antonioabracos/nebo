#!/usr/bin/env sh

nebo_die() {
    echo "NEBO_TEST_HARNESS_ERROR: $*" >&2
    exit 2
}

nebo_now_utc() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

nebo_valid_test_id() {
    printf '%s\n' "$1" | grep -Eq '^NEBO-[A-Z0-9]+-[A-Z0-9_]+-[0-9]{3}$'
}

nebo_result_for_exit() {
    case "$1" in
        0)  echo PASS ;;
        10) echo FAIL ;;
        20) echo BLOCKED ;;
        30) echo SKIPPED_NOT_APPLICABLE ;;
        40) echo NOT_EXECUTED_WITH_REASON ;;
        *)  echo FAIL ;;
    esac
}

nebo_validate_reason_file() {
    file=$1
    kind=$2
    [ -f "$file" ] || return 1
    grep -q '^Reason: .\+' "$file" || return 1
    grep -q '^Authority: .\+' "$file" || return 1
    grep -q '^ReviewAt: .\+' "$file" || return 1
    grep -q "^Kind: $kind$" "$file" || return 1
}
