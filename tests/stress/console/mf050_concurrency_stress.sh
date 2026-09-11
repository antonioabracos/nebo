#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONTRACT="${1:-all}"
DOMAIN="$ROOT/build/tests/mf042/console_domain_test"
INPUT="$ROOT/build/tests/mf046/input_registry_test"
PENDING="$ROOT/build/tests/mf048/pending_resolution_test"
LIFECYCLE="$ROOT/build/tests/mf049/lifecycle_test"
COMPOSITE="$ROOT/build/tests/mf050/enter_pressure_test"
require_bin(){ [[ -x "$1" ]] || { echo "MF050_STRESS_FAIL missing executable: $1" >&2; exit 1; }; }
repeat_native(){ local count="$1" binary="$2" scenario="$3" label="$4" i; for ((i=1;i<=count;i++)); do "$binary" "$scenario"; done; echo "$label iterations=$count"; }
run_001(){ require_bin "$DOMAIN"; repeat_native 64 "$DOMAIN" 4 MF050_SINGLE_WRITER_STRESS_GREEN; }
run_002(){ require_bin "$DOMAIN"; repeat_native 128 "$DOMAIN" 2 MF050_FIFO_PER_CONSOLE_STRESS_GREEN; }
run_004(){ require_bin "$INPUT"; repeat_native 64 "$INPUT" 6 MF050_MULTIPLE_SCANS_SHARED_LOOP_STRESS_GREEN; }
run_005(){ python3 -B "$ROOT/scripts/mf050/audit-ordinary-function-domain.py"; }
run_006(){ require_bin "$DOMAIN"; repeat_native 128 "$DOMAIN" 6 MF050_QUEUE_BACKPRESSURE_STRESS_GREEN; }
run_007(){ require_bin "$COMPOSITE"; require_bin "$PENDING"; repeat_native 128 "$COMPOSITE" 1 MF050_ENTER_QUEUE_PRESSURE_STRESS_GREEN; repeat_native 64 "$PENDING" 5 MF050_ENTER_DEPENDENCY_ORDER_REGRESSION_GREEN; }
run_008(){ require_bin "$COMPOSITE"; require_bin "$LIFECYCLE"; repeat_native 64 "$COMPOSITE" 2 MF050_CLOSE_QUEUE_RACE_STRESS_GREEN; repeat_native 64 "$LIFECYCLE" 8 MF050_CLOSE_STALE_GENERATION_STRESS_GREEN; repeat_native 64 "$LIFECYCLE" 9 MF050_CLOSE_RECLAIM_BARRIER_STRESS_GREEN; }
run_009(){ require_bin "$DOMAIN"; repeat_native 64 "$DOMAIN" 7 MF050_DETERMINISTIC_TRACE_STRESS_GREEN; }
run_010(){ require_bin "$DOMAIN"; repeat_native 128 "$DOMAIN" 5 MF050_FAIRNESS_NO_STARVATION_STRESS_GREEN; }
case "$CONTRACT" in
  001) run_001;; 002) run_002;; 004) run_004;; 005) run_005;; 006) run_006;; 007) run_007;; 008) run_008;; 009) run_009;; 010) run_010;;
  all) run_001; run_002; run_004; run_005; run_006; run_007; run_008; run_009; run_010; echo 'MF050_PRIMARY_CONCURRENCY_SCENARIOS_GREEN count=9';;
  *) echo "usage: $0 {001|002|004|005|006|007|008|009|010|all}" >&2; exit 2;;
esac
