#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONTRACT="${1:-all}"
BINARY="$ROOT/build/tests/mf057/console_hardening_test"

[[ -x "$BINARY" ]] || { echo "MF057_STRESS_FAIL missing executable: $BINARY" >&2; exit 1; }

run_bounded() {
  local scenario="$1" rc
  set +e
  (
    ulimit -t 5
    ulimit -v 262144
    ulimit -f 2048
    ulimit -n 64
    timeout --signal=KILL 8s "$BINARY" "$scenario"
  )
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    printf 'MF057_NATIVE_SCENARIO_FAIL scenario=%s rc=%s\n' "$scenario" "$rc" >&2
    if [[ "$scenario" == 5 ]]; then
      case "$rc" in
        56) echo 'MF057_QUEUE_DIAGNOSTIC event_count_before_rejection' >&2 ;;
        57) echo 'MF057_QUEUE_DIAGNOSTIC event_queue_sequence_before_rejection' >&2 ;;
        58) echo 'MF057_QUEUE_DIAGNOSTIC platform_sequence_before_rejection' >&2 ;;
        59) echo 'MF057_QUEUE_DIAGNOSTIC event_queue_validate_before_rejection' >&2 ;;
        60) echo 'MF057_QUEUE_DIAGNOSTIC expected_queue_full_status' >&2 ;;
        61) echo 'MF057_QUEUE_DIAGNOSTIC event_count_mutated_by_rejection' >&2 ;;
        62) echo 'MF057_QUEUE_DIAGNOSTIC event_queue_sequence_mutated_by_rejection' >&2 ;;
        63) echo 'MF057_QUEUE_DIAGNOSTIC platform_sequence_mutated_by_rejection' >&2 ;;
        64) echo 'MF057_QUEUE_DIAGNOSTIC event_queue_validate_after_rejection' >&2 ;;
        65) echo 'MF057_QUEUE_DIAGNOSTIC scheduler_drain' >&2 ;;
        66) echo 'MF057_QUEUE_DIAGNOSTIC queues_not_empty_or_invalid_after_drain' >&2 ;;
        67) echo 'MF057_QUEUE_DIAGNOSTIC processed_counts_after_drain' >&2 ;;
        68) echo 'MF057_QUEUE_DIAGNOSTIC post_exhaustion_enqueue_reuse' >&2 ;;
        69) echo 'MF057_QUEUE_DIAGNOSTIC post_exhaustion_scheduler' >&2 ;;
        70) echo 'MF057_QUEUE_DIAGNOSTIC post_exhaustion_counts' >&2 ;;
        71) echo 'MF057_QUEUE_DIAGNOSTIC command_sequence_after_reuse' >&2 ;;
        72) echo 'MF057_QUEUE_DIAGNOSTIC event_queue_sequence_after_reuse' >&2 ;;
        73) echo 'MF057_QUEUE_DIAGNOSTIC platform_sequence_after_reuse' >&2 ;;
      esac
    fi
    return "$rc"
  fi
}

repeat_native() {
  local count="$1" scenario="$2" label="$3" i
  for ((i=1; i<=count; i++)); do
    run_bounded "$scenario"
  done
  printf '%s iterations=%s\n' "$label" "$count"
}

run_006(){ repeat_native 16 1 MF057_EVENT_STREAM_FUZZ_GREEN; }
run_007(){ repeat_native 64 2 MF057_INVALID_UTF8_FUZZ_GREEN; }
run_013(){ python3 -B "$ROOT/scripts/mf057/audit-race-methodology.py"; repeat_native 128 3 MF057_CLOSE_RACE_STALE_CALLBACK_GREEN; }
run_014(){ repeat_native 32 4 MF057_RESOURCE_STORM_LIMIT_GREEN; }
run_015(){ repeat_native 128 5 MF057_QUEUE_EXHAUSTION_CONTROLLED_FAIL_GREEN; }

case "$CONTRACT" in
  006) run_006 ;;
  007) run_007 ;;
  013) run_013 ;;
  014) run_014 ;;
  015) run_015 ;;
  all)
    run_006
    run_007
    run_013
    run_014
    run_015
    echo 'MF057_PRIMARY_CONSOLE_SECURITY_SCENARIOS_GREEN count=5'
    echo 'MF057_DEADLOCK_UAF_LOST_INPUT_ZERO_GREEN'
    ;;
  *) echo "usage: $0 {006|007|013|014|015|all}" >&2; exit 2 ;;
esac
